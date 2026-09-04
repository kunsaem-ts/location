import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/measurement.dart';
import 'platform_channel.dart';
import 'storage_service.dart';

/// 측정 시점의 연결망 판별 (FR-06, FR-06a)과 오프라인 감시 (FR-12).
class ConnectivityService {
  ConnectivityService(
    this._storage, {
    PlatformChannel? channel,
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
    Stream<List<ConnectivityResult>>? onChanged,
    bool? isWeb,
  })  : _channel = channel ?? PlatformChannel(),
        _checkConnectivity = checkConnectivity ?? Connectivity().checkConnectivity,
        _onChanged = onChanged ?? Connectivity().onConnectivityChanged,
        _isWeb = isWeb ?? kIsWeb;

  final StorageService _storage;
  final PlatformChannel _channel;
  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _onChanged;
  final bool _isWeb;

  static bool _noConnection(List<ConnectivityResult> results) =>
      results.isEmpty || results.contains(ConnectivityResult.none);

  /// 지금 오프라인인지. 권한 요청 없이 연결 유무만 본다 (E3 배너용).
  Future<bool> isOffline() async {
    try {
      return _noConnection(await _checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  /// 연결 유무 변화. true = 오프라인 (EX-06).
  Stream<bool> offlineChanges() => _onChanged.map(_noConnection);

  /// 현재 연결망. 판별에 실패해도 예외 대신 unknown을 돌려준다.
  Future<ConnectionType> current() async {
    final List<ConnectivityResult> results;
    try {
      results = await _checkConnectivity();
    } catch (_) {
      return ConnectionType.unknown;
    }
    if (_noConnection(results)) return ConnectionType.none;
    if (_isWeb) {
      // C-4: iPhone Safari는 네트워크 종류 API가 없다. connectivity_plus 웹 구현은
      // 온라인이면 무조건 wifi를 돌려주므로 믿지 않고 "알 수 없음"으로 표시한다.
      return ConnectionType.unknown;
    }
    if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
    if (results.contains(ConnectivityResult.mobile)) return _classifyMobile();
    return ConnectionType.unknown;
  }

  /// 이동통신일 때 LTE/5G 구분 (FR-06a). 전화 상태 권한은 최초 1회만 요청하고,
  /// 거부되면 '이동통신'으로 통합 표시한다 (EX-09).
  Future<ConnectionType> _classifyMobile() async {
    var granted = await _channel.hasPhoneStatePermission();
    if (!granted && !await _storage.wasPhoneStateAsked()) {
      await _storage.markPhoneStateAsked();
      granted = await _channel.requestPhoneStatePermission();
    }
    if (!granted) return ConnectionType.mobileOther;

    final type = await _channel.dataNetworkType();
    if (type == PlatformChannel.networkTypeNr) return ConnectionType.fiveG;
    if (type == PlatformChannel.networkTypeLte) {
      // NSA 5G는 dataNetworkType이 LTE로 나오므로 표시 정보로 다시 확인한다.
      final override = await _channel.displayOverrideNetworkType();
      return PlatformChannel.overrideTypes5g.contains(override)
          ? ConnectionType.fiveG
          : ConnectionType.lte;
    }
    return ConnectionType.mobileOther;
  }
}
