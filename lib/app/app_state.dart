import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/measurement.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/source_estimator.dart';
import '../services/storage_service.dart';
import '../services/web_context.dart';
import 'constants.dart';
import 'strings.dart';

/// PRD 2.1 화면 흐름의 상태.
enum AppStage {
  checking,
  insecureContext, // 웹 HTTP 접속 (EX-13)
  permissionIntro, // S1
  permissionDenied, // E2
  serviceOff, // E1
  main, // S2
}

/// 앱 전체 상태. 화면은 이 객체만 보고 그린다.
class AppState extends ChangeNotifier {
  AppState(this._location, this._storage, this._connectivity);

  final LocationService _location;
  final StorageService _storage;
  final ConnectivityService _connectivity;
  static const _uuid = Uuid();

  AppStage stage = AppStage.checking;

  /// E2에서 영구 거부인지 (영구면 [다시 요청] 대신 [앱 설정 열기]).
  bool permissionDeniedForever = false;

  /// 대략적 위치 권한만 허용된 상태 (EX-05).
  bool reducedAccuracy = false;

  bool measuring = false;

  /// 측정 중 경과 시간 (FR-15)
  int elapsedSeconds = 0;
  Timer? _elapsedTimer;

  /// 지도·정보 패널에 표시 중인 결과. 목록에서 고른 과거 결과일 수도 있다.
  Measurement? current;

  /// 저장된 최근 결과, 앞쪽이 최신 (FR-09)
  List<Measurement> history = [];

  String? lastError;

  /// 마지막 측정의 저장 실패 여부. 화면이 스낵바로 알린다 (EX-14).
  String? saveError;

  /// 인터넷 연결 없음. 메인 화면이 E3 배너를 띄운다 (FR-12).
  bool offline = false;
  StreamSubscription<bool>? _offlineSub;

  bool get canOpenSettings => _location.canOpenSettings;

  /// 앱 시작 시 호출. 웹 보안 컨텍스트 → 저장 결과 복원 → 오프라인 감시 → 권한 → 위치 서비스 순.
  Future<void> init() async {
    if (isInsecureWebContext(Uri.base, isWeb: kIsWeb)) {
      stage = AppStage.insecureContext;
      notifyListeners();
      return;
    }
    history = await _storage.loadMeasurements();
    current = history.firstOrNull;
    offline = await _connectivity.isOffline();
    _offlineSub ??= _connectivity.offlineChanges().listen((value) {
      if (value == offline) return;
      offline = value;
      notifyListeners();
    });
    await recheck();
  }

  Future<void> recheck() async {
    final permission = await _location.checkPermission();
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        await _enterMainIfServiceOn();
      case LocationPermission.deniedForever:
        _setDenied(forever: true);
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        // 요청한 적이 없으면 안내 화면(S1), 있으면 일시 거부(E2).
        // 웹은 브라우저 상태 prompt→denied, denied→deniedForever로 오므로
        // denied는 "아직 안 물어봄"이다. iOS PWA는 세션마다 prompt로 돌아올 수 있다 (Q-6).
        if (!kIsWeb && await _storage.wasPermissionAsked()) {
          _setDenied(forever: false);
        } else {
          stage = AppStage.permissionIntro;
          notifyListeners();
        }
    }
  }

  /// S1/E2의 버튼. "앱 사용 중" 권한을 요청한다.
  Future<void> requestPermission() async {
    await _storage.markPermissionAsked();
    final permission = await _location.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _enterMainIfServiceOn();
      return;
    }
    var forever = permission == LocationPermission.deniedForever;
    if (kIsWeb) {
      // geolocator_web은 모든 거부를 deniedForever로 돌려주므로 횟수로 구분한다 (EX-03).
      final count = await _storage.incrementPermissionDenyCount();
      forever = count >= AppConstants.webDenyCountAsForever;
    }
    _setDenied(forever: forever);
  }

  Future<void> _enterMainIfServiceOn() async {
    if (!await _location.isServiceEnabled()) {
      stage = AppStage.serviceOff;
      notifyListeners();
      return;
    }
    reducedAccuracy =
        await _location.accuracyStatus() == LocationAccuracyStatus.reduced;
    stage = AppStage.main;
    notifyListeners();
  }

  void _setDenied({required bool forever}) {
    permissionDeniedForever = forever;
    stage = AppStage.permissionDenied;
    notifyListeners();
  }

  Future<void> openAppSettings() => _location.openAppSettings();

  Future<void> openLocationSettings() => _location.openLocationSettings();

  /// [측정] / [다시 측정] (FR-03). 측정 중 중복 호출은 무시한다.
  Future<void> measure() async {
    if (measuring) return;
    measuring = true;
    lastError = null;
    saveError = null;
    elapsedSeconds = 0;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
    try {
      // 연결망은 측정 시작 직전에 조회한다 (FR-06).
      final connection = await _connectivity.current();
      final result = await _location.measure();
      // 거리 비교 기준은 화면에 표시 중인 결과가 아니라 직전 측정(목록의 최신)이다 (FR-08).
      final measurement =
          _toMeasurement(result, connection, previous: history.firstOrNull);
      current = measurement;
      await _persist(measurement);
    } on MeasureTimeoutException {
      lastError = AppStrings.errorTimeout;
    } on LocationServiceDisabledException {
      stage = AppStage.serviceOff;
    } on PermissionDeniedException {
      await recheck();
    } catch (e) {
      lastError = '${AppStrings.errorMeasureFailed} ($e)';
    } finally {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      measuring = false;
      notifyListeners();
    }
  }

  /// 저장 실패해도 화면 결과는 유지한다 (EX-14).
  Future<void> _persist(Measurement m) async {
    try {
      history = await _storage.addMeasurement(m);
    } catch (e) {
      saveError = '${AppStrings.saveFailed} ($e)';
      history = [m, ...history];
    }
  }

  /// S3 목록에서 항목 선택 → 지도에 표시 (FR-10)
  void select(Measurement m) {
    current = m;
    notifyListeners();
  }

  Future<void> delete(Measurement m) async {
    history = await _storage.deleteMeasurement(m.id);
    if (current?.id == m.id) current = history.firstOrNull;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storage.clearMeasurements();
    history = [];
    current = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _offlineSub?.cancel();
    super.dispose();
  }

  Measurement _toMeasurement(
    MeasureResult result,
    ConnectionType connection, {
    required Measurement? previous,
  }) {
    final p = result.position;
    final platform = kIsWeb ? AppPlatform.iosWeb : AppPlatform.android;
    return Measurement(
      id: _uuid.v4(),
      measuredAt: DateTime.now(),
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyM: p.accuracy,
      connectionType: connection,
      locationProvider: result.provider,
      sourceEstimate: SourceEstimator.estimate(
        platform: platform,
        provider: result.provider,
        accuracyM: p.accuracy,
      ),
      platform: platform,
      distanceFromPrevM: previous == null
          ? null
          : SourceEstimator.distanceM(
              previous.latitude,
              previous.longitude,
              p.latitude,
              p.longitude,
            ),
      isMock: kIsWeb ? null : p.isMocked,
      timedOut: result.timedOut,
      altitudeM: p.hasAltitude ? p.altitude : null,
      appVersion: AppConstants.appVersion,
    );
  }
}
