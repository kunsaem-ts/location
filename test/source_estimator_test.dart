import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/models/measurement.dart';
import 'package:location_check/services/source_estimator.dart';

void main() {
  group('측위 출처 추정 (PRD 6.2)', () {
    SourceEstimate est(AppPlatform p, String? provider, double acc) =>
        SourceEstimator.estimate(platform: p, provider: provider, accuracyM: acc);

    test('Android gps 제공자는 오차와 무관하게 GPS', () {
      expect(est(AppPlatform.android, 'gps', 50), SourceEstimate.gps);
    });

    test('Android network 제공자: ≤100 m WiFi, >100 m 기지국', () {
      expect(est(AppPlatform.android, 'network', 80), SourceEstimate.wifi);
      expect(est(AppPlatform.android, 'network', 150), SourceEstimate.cell);
    });

    test('Android fused 제공자는 오차반경 기준', () {
      expect(est(AppPlatform.android, 'fused', 8), SourceEstimate.gps);
      expect(est(AppPlatform.android, 'fused', 45), SourceEstimate.wifi);
      expect(est(AppPlatform.android, 'fused', 300), SourceEstimate.cell);
    });

    test('iOS(웹)는 오차반경만으로: ≤20 GPS, ≤100 WiFi, >100 기지국', () {
      expect(est(AppPlatform.iosWeb, null, 15), SourceEstimate.gps);
      expect(est(AppPlatform.iosWeb, null, 20), SourceEstimate.gps);
      expect(est(AppPlatform.iosWeb, null, 60), SourceEstimate.wifi);
      expect(est(AppPlatform.iosWeb, null, 100), SourceEstimate.wifi);
      expect(est(AppPlatform.iosWeb, null, 200), SourceEstimate.cell);
    });

    test('오차반경을 모르면(0 이하) 추정 불가', () {
      expect(est(AppPlatform.android, 'fused', 0), SourceEstimate.unknown);
      expect(est(AppPlatform.iosWeb, null, -1), SourceEstimate.unknown);
    });
  });

  group('거리 계산 Haversine (FR-08)', () {
    test('위도 0.001도 차이는 약 111.2 m', () {
      final d = SourceEstimator.distanceM(37.0, 127.0, 37.001, 127.0);
      expect(d, closeTo(111.2, 0.5));
    });

    test('서울시청 ↔ 광화문광장(세종대왕상)은 약 720 m', () {
      // 37.566535,126.977969 ↔ 37.572950,126.976880
      final d = SourceEstimator.distanceM(
        37.566535,
        126.977969,
        37.572950,
        126.976880,
      );
      expect(d, closeTo(720, 30));
    });

    test('같은 좌표는 0, 순서를 바꿔도 같다', () {
      expect(SourceEstimator.distanceM(37.5, 127.0, 37.5, 127.0), 0);
      final a = SourceEstimator.distanceM(37.5, 127.0, 37.6, 127.1);
      final b = SourceEstimator.distanceM(37.6, 127.1, 37.5, 127.0);
      expect(a, closeTo(b, 1e-6));
    });
  });
}
