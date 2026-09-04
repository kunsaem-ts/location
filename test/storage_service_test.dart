import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/app/constants.dart';
import 'package:location_check/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late StorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
  });

  group('측정 결과 저장 (FR-09, PRD 6.3)', () {
    test('추가하면 맨 앞에 오고 새 인스턴스에서도 읽힌다', () async {
      await storage.addMeasurement(fakeMeasurement(id: 'a'));
      final list = await storage.addMeasurement(fakeMeasurement(id: 'b'));
      expect(list.map((m) => m.id), ['b', 'a']);
      expect((await StorageService().loadMeasurements()).map((m) => m.id), ['b', 'a']);
    });

    test('51건째 추가 시 가장 오래된 1건이 삭제되어 정확히 50건', () async {
      for (var i = 1; i <= AppConstants.maxStoredMeasurements + 1; i++) {
        await storage.addMeasurement(fakeMeasurement(id: 'm$i'));
      }
      final list = await storage.loadMeasurements();
      expect(list.length, AppConstants.maxStoredMeasurements);
      expect(list.first.id, 'm51');
      expect(list.last.id, 'm2');
      expect(list.any((m) => m.id == 'm1'), isFalse);
    });

    test('schemaVersion이 함께 저장된다', () async {
      await storage.addMeasurement(fakeMeasurement(id: 'a'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('schemaVersion'), AppConstants.storageSchemaVersion);
    });

    test('손상된 JSON은 빈 목록으로 읽는다', () async {
      SharedPreferences.setMockInitialValues({'measurements': '{not json'});
      expect(await StorageService().loadMeasurements(), isEmpty);
    });
  });

  group('삭제 (FR-10)', () {
    test('단건 삭제', () async {
      await storage.addMeasurement(fakeMeasurement(id: 'a'));
      await storage.addMeasurement(fakeMeasurement(id: 'b'));
      final list = await storage.deleteMeasurement('b');
      expect(list.map((m) => m.id), ['a']);
    });

    test('전체 삭제', () async {
      await storage.addMeasurement(fakeMeasurement(id: 'a'));
      await storage.clearMeasurements();
      expect(await storage.loadMeasurements(), isEmpty);
    });
  });
}
