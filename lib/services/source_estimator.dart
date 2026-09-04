import 'dart:math' as math;

import '../app/constants.dart';
import '../models/measurement.dart';

/// 측위 출처 추정 (PRD 6.2)과 거리 계산 (FR-08). 기준값은 AppConstants에만 둔다.
class SourceEstimator {
  SourceEstimator._();

  static const double _earthRadiusM = 6371000;

  /// [provider]는 Android 위치 제공자(gps / network / fused), 웹은 null.
  /// Android에서 accuracy를 모르면 0으로 오므로 0 이하는 unknown으로 본다.
  static SourceEstimate estimate({
    required AppPlatform platform,
    required String? provider,
    required double accuracyM,
  }) {
    if (accuracyM <= 0) return SourceEstimate.unknown;
    if (platform == AppPlatform.android && provider == 'gps') {
      return SourceEstimate.gps;
    }
    if (platform == AppPlatform.android && provider == 'network') {
      return accuracyM <= AppConstants.wifiMaxAccuracyM
          ? SourceEstimate.wifi
          : SourceEstimate.cell;
    }
    // fused 또는 iOS: 오차반경만으로 추정
    if (accuracyM <= AppConstants.gpsMaxAccuracyM) return SourceEstimate.gps;
    if (accuracyM <= AppConstants.wifiMaxAccuracyM) return SourceEstimate.wifi;
    return SourceEstimate.cell;
  }

  /// 두 좌표 사이 거리(m), Haversine 공식 (FR-08).
  static double distanceM(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusM * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
