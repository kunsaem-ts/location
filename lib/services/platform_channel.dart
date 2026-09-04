import 'package:flutter/services.dart';

/// Android 전용 MethodChannel 래퍼. 구현은 android/.../MainActivity.kt.
/// 웹에서는 호출하지 않는다 (ConnectivityService가 분기).
class PlatformChannel {
  static const _channel = MethodChannel('com.tsdevel.locationcheck/platform');

  /// TelephonyManager.NETWORK_TYPE_LTE
  static const int networkTypeLte = 13;

  /// TelephonyManager.NETWORK_TYPE_NR
  static const int networkTypeNr = 20;

  /// TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_NSA / NR_NSA_MMWAVE / NR_ADVANCED
  static const Set<int> overrideTypes5g = {3, 4, 5};

  /// 네이티브 콜백이 오지 않을 때를 대비한 상한 (Kotlin 쪽 2초보다 길게)
  static const Duration _overrideTimeout = Duration(seconds: 3);

  Future<bool> hasPhoneStatePermission() async =>
      await _channel.invokeMethod<bool>('hasPhoneStatePermission') ?? false;

  Future<bool> requestPhoneStatePermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestPhoneStatePermission') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// -1이면 권한 없음 또는 조회 실패
  Future<int> dataNetworkType() async =>
      await _channel.invokeMethod<int>('getDataNetworkType') ?? -1;

  /// 방금 측정한 좌표의 위치 제공자(gps / network / fused). 알 수 없으면 null (FR-07).
  Future<String?> lastLocationProvider({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    try {
      return await _channel.invokeMethod<String>('getLastLocationProvider', {
        'latitude': latitude,
        'longitude': longitude,
        'timeMillis': timestamp.millisecondsSinceEpoch,
      });
    } catch (_) {
      return null;
    }
  }

  /// -1이면 미지원(API 31 미만)·권한 없음·타임아웃
  Future<int> displayOverrideNetworkType() async {
    try {
      return await _channel
              .invokeMethod<int>('getDisplayOverrideNetworkType')
              .timeout(_overrideTimeout) ??
          -1;
    } catch (_) {
      return -1;
    }
  }
}
