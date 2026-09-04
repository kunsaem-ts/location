import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/models/measurement.dart';

void main() {
  group('Measurement JSON 직렬화 (PRD 6.1)', () {
    final original = Measurement(
      id: '3f2a1b2c-0000-4000-8000-000000000001',
      measuredAt: DateTime(2026, 9, 4, 14, 3, 21),
      latitude: 37.566535,
      longitude: 126.977969,
      accuracyM: 12.0,
      connectionType: ConnectionType.wifi,
      locationProvider: 'fused',
      sourceEstimate: SourceEstimate.gps,
      platform: AppPlatform.android,
      distanceFromPrevM: 3.4,
      isMock: false,
      timedOut: false,
      altitudeM: 38.2,
      appVersion: '0.1.0',
    );

    test('toJson → jsonEncode → jsonDecode → fromJson 왕복이 원본과 같다', () {
      final encoded = jsonEncode(original.toJson());
      final restored = Measurement.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(restored.id, original.id);
      expect(restored.measuredAt, original.measuredAt);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracyM, original.accuracyM);
      expect(restored.connectionType, original.connectionType);
      expect(restored.locationProvider, original.locationProvider);
      expect(restored.sourceEstimate, original.sourceEstimate);
      expect(restored.platform, original.platform);
      expect(restored.distanceFromPrevM, original.distanceFromPrevM);
      expect(restored.isMock, original.isMock);
      expect(restored.timedOut, original.timedOut);
      expect(restored.altitudeM, original.altitudeM);
      expect(restored.appVersion, original.appVersion);
    });

    test('measuredAt은 오프셋이 포함된 ISO 8601 문자열로 저장된다', () {
      final value = original.toJson()['measuredAt'] as String;
      expect(value, startsWith('2026-09-04T14:03:21'));
      expect(value, matches(RegExp(r'[+-]\d{2}:\d{2}$')));
    });

    test('nullable 필드가 null인 경우(iOS PWA 첫 측정)도 왕복된다', () {
      final iosFirst = Measurement(
        id: 'id-2',
        measuredAt: DateTime(2026, 9, 4, 15),
        latitude: 35.1,
        longitude: 129.0,
        accuracyM: 65.0,
        connectionType: ConnectionType.unknown,
        sourceEstimate: SourceEstimate.wifi,
        platform: AppPlatform.iosWeb,
        timedOut: true,
        appVersion: '0.1.0',
      );
      final restored = Measurement.fromJson(
        jsonDecode(jsonEncode(iosFirst.toJson())) as Map<String, dynamic>,
      );
      expect(restored.locationProvider, isNull);
      expect(restored.distanceFromPrevM, isNull);
      expect(restored.isMock, isNull);
      expect(restored.altitudeM, isNull);
      expect(restored.connectionType, ConnectionType.unknown);
      expect(restored.platform, AppPlatform.iosWeb);
      expect(restored.timedOut, isTrue);
    });

    test('enum 라벨은 한국어이며 출처에는 "추정"이 붙는다 (FR-07)', () {
      expect(ConnectionType.unknown.label, '알 수 없음');
      for (final s in SourceEstimate.values) {
        expect(s.label, contains('추정'), reason: s.name);
      }
    });
  });
}
