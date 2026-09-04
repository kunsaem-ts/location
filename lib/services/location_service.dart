import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../app/constants.dart';
import 'platform_channel.dart';

/// 단발 측정 결과. [timedOut]이 true면 타임아웃 후 마지막 수신 위치를 쓴 것이다 (FR-03).
class MeasureResult {
  const MeasureResult({
    required this.position,
    required this.timedOut,
    this.provider,
  });
  final Position position;
  final bool timedOut;

  /// Android만: gps / network / fused. 웹은 null (C-2).
  final String? provider;
}

/// 타임아웃됐고 마지막 수신 위치도 없을 때 (EX-07)
class MeasureTimeoutException implements Exception {
  const MeasureTimeoutException();
}

/// 위치 권한·서비스 상태·단발 측정을 감싼다 (FR-01~03).
/// 플랫폼 분기는 이 안에서만 처리하고 화면 코드에는 두지 않는다 (CLAUDE.md 5절).
class LocationService {
  LocationService({PlatformChannel? channel})
      : _channel = channel ?? PlatformChannel();

  final PlatformChannel _channel;

  /// 웹에서는 OS 설정 화면을 열 수 없다 (PRD 4절).
  bool get canOpenSettings => !kIsWeb;

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// "앱 사용 중" 권한만 요청한다. 백그라운드 권한은 요청하지 않는다 (FR-01).
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// 정확한/대략적 위치 여부 (EX-05). 지원하지 않는 플랫폼(웹)은 unknown.
  Future<LocationAccuracyStatus> accuracyStatus() async {
    try {
      return await Geolocator.getLocationAccuracy();
    } catch (_) {
      return LocationAccuracyStatus.unknown;
    }
  }

  /// 고정밀 단발 측정. 타임아웃(AppConstants.measureTimeout) 시 마지막 수신 위치를 쓰고,
  /// 그것도 없으면 [MeasureTimeoutException]을 던진다 (FR-03).
  ///
  /// 타임아웃은 플러그인의 timeLimit 대신 Future.timeout으로 건다.
  /// geolocator_web 4.1.4가 timeLimit을 마이크로초로 잘못 넘겨 웹에서 동작하지 않기 때문이다.
  Future<MeasureResult> measure() async {
    final LocationSettings settings = !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(accuracy: LocationAccuracy.best)
        : const LocationSettings(accuracy: LocationAccuracy.best);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(AppConstants.measureTimeout);
      return MeasureResult(
        position: position,
        timedOut: false,
        provider: await _providerOf(position),
      );
    } on TimeoutException {
      // 웹은 마지막 수신 위치 API가 없다 (geolocator_web: UnsupportedError).
      final last = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      if (last != null) {
        return MeasureResult(
          position: last,
          timedOut: true,
          provider: await _providerOf(last),
        );
      }
      throw const MeasureTimeoutException();
    }
  }

  /// Android에서만 위치 제공자를 조회한다. 웹은 제공자 정보가 없다 (C-2).
  Future<String?> _providerOf(Position p) => kIsWeb
      ? Future.value(null)
      : _channel.lastLocationProvider(
          latitude: p.latitude,
          longitude: p.longitude,
          timestamp: p.timestamp,
        );

  Future<bool> openAppSettings() =>
      kIsWeb ? Future.value(false) : Geolocator.openAppSettings();

  Future<bool> openLocationSettings() =>
      kIsWeb ? Future.value(false) : Geolocator.openLocationSettings();
}
