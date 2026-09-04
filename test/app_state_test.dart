import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_check/app/app_state.dart';
import 'package:location_check/models/measurement.dart';
import 'package:location_check/services/location_service.dart';
import 'package:location_check/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeLocationService location;
  late AppState state;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    location = FakeLocationService();
    state = AppState(location, StorageService(), FakeConnectivityService());
  });

  group('권한 흐름 (FR-01, FR-11)', () {
    test('최초 실행: denied이고 요청한 적 없으면 S1 권한 안내', () async {
      await state.init();
      expect(state.stage, AppStage.permissionIntro);
    });

    test('S1에서 허용하면 S2 메인으로 간다', () async {
      await state.init();
      await state.requestPermission();
      expect(state.stage, AppStage.main);
      expect(state.reducedAccuracy, isFalse);
    });

    test('일시 거부면 E2(영구 아님), 재실행 시에도 S1이 아니라 E2', () async {
      location.requestResult = LocationPermission.denied;
      await state.init();
      await state.requestPermission();
      expect(state.stage, AppStage.permissionDenied);
      expect(state.permissionDeniedForever, isFalse);

      // 앱 재실행을 흉내 낸다: 같은 저장소, 새 상태 객체
      final again = AppState(location, StorageService(), FakeConnectivityService());
      await again.init();
      expect(again.stage, AppStage.permissionDenied);
    });

    test('영구 거부면 E2(영구)', () async {
      location.requestResult = LocationPermission.deniedForever;
      await state.init();
      await state.requestPermission();
      expect(state.stage, AppStage.permissionDenied);
      expect(state.permissionDeniedForever, isTrue);
    });

    test('이미 허용된 상태로 시작하면 바로 S2', () async {
      location.permission = LocationPermission.whileInUse;
      await state.init();
      expect(state.stage, AppStage.main);
    });

    test('대략적 위치만 허용되면 reducedAccuracy 배지 (EX-05)', () async {
      location.permission = LocationPermission.whileInUse;
      location.accuracy = LocationAccuracyStatus.reduced;
      await state.init();
      expect(state.stage, AppStage.main);
      expect(state.reducedAccuracy, isTrue);
    });
  });

  group('위치 서비스 (FR-02)', () {
    test('권한은 있지만 위치 서비스 OFF면 E1, 켠 뒤 다시 확인하면 S2', () async {
      location.permission = LocationPermission.whileInUse;
      location.serviceEnabled = false;
      await state.init();
      expect(state.stage, AppStage.serviceOff);

      location.serviceEnabled = true;
      await state.recheck();
      expect(state.stage, AppStage.main);
    });
  });

  group('측정 (FR-03, FR-07, FR-08)', () {
    setUp(() async {
      location.permission = LocationPermission.whileInUse;
      await state.init();
    });

    test('성공하면 current가 채워지고 timedOut=false', () async {
      location.measureResult =
          MeasureResult(position: fakePosition(accuracy: 12), timedOut: false);
      await state.measure();
      expect(state.measuring, isFalse);
      expect(state.lastError, isNull);
      expect(state.current, isNotNull);
      expect(state.current!.latitude, 37.566535);
      expect(state.current!.accuracyM, 12);
      expect(state.current!.timedOut, isFalse);
    });

    test('두 번째 측정에는 직전 대비 거리가, 첫 측정에는 null (FR-08)', () async {
      location.measureResult =
          MeasureResult(position: fakePosition(), timedOut: false);
      await state.measure();
      expect(state.current!.distanceFromPrevM, isNull);

      // 위도 +0.001도 ≈ 111.2 m 이동
      location.measureResult = MeasureResult(
        position: fakePosition(latitude: 37.567535),
        timedOut: false,
      );
      await state.measure();
      expect(state.current!.distanceFromPrevM, closeTo(111.2, 0.5));
    });

    test('제공자와 오차반경으로 출처를 추정하고 제공자를 기록한다 (FR-07)', () async {
      location.measureResult = MeasureResult(
        position: fakePosition(accuracy: 8),
        timedOut: false,
        provider: 'fused',
      );
      await state.measure();
      expect(state.current!.locationProvider, 'fused');
      expect(state.current!.sourceEstimate, SourceEstimate.gps);
      expect(state.measuring, isFalse);
      expect(state.elapsedSeconds, 0);
    });

    test('타임아웃 후 마지막 수신 위치를 쓰면 timedOut=true', () async {
      location.measureResult =
          MeasureResult(position: fakePosition(), timedOut: true);
      await state.measure();
      expect(state.current!.timedOut, isTrue);
      expect(state.lastError, isNull);
    });

    test('타임아웃이고 마지막 수신 위치도 없으면 오류 문구, 이전 결과 유지', () async {
      location.measureResult =
          MeasureResult(position: fakePosition(), timedOut: false);
      await state.measure();
      final previous = state.current;

      location.measureError = const MeasureTimeoutException();
      await state.measure();
      expect(state.lastError, isNotNull);
      expect(state.current, same(previous));
      expect(state.measuring, isFalse);
    });

    test('측정 중 위치 서비스가 꺼지면 E1로 전환', () async {
      location.measureError = const LocationServiceDisabledException();
      await state.measure();
      expect(state.stage, AppStage.serviceOff);
    });
  });

  group('오프라인 (FR-12, EX-06)', () {
    test('시작 시 오프라인이면 offline=true, 연결이 돌아오면 false로 바뀌고 알린다', () async {
      final connectivity = FakeConnectivityService()..offline = true;
      final s = AppState(location, StorageService(), connectivity);
      var notified = 0;
      s.addListener(() => notified++);
      location.permission = LocationPermission.whileInUse;
      await s.init();
      expect(s.offline, isTrue);
      expect(s.stage, AppStage.main, reason: '오프라인이어도 메인 진입·측정 허용');

      connectivity.offlineController.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(s.offline, isFalse);
      expect(notified, greaterThan(1));
    });

    test('오프라인에서도 측정되고 연결망은 없음으로 기록된다', () async {
      final connectivity = FakeConnectivityService()
        ..offline = true
        ..connection = ConnectionType.none;
      final s = AppState(location, StorageService(), connectivity);
      location.permission = LocationPermission.whileInUse;
      location.measureResult =
          MeasureResult(position: fakePosition(), timedOut: false);
      await s.init();
      await s.measure();
      expect(s.current!.connectionType, ConnectionType.none);
    });
  });

  group('저장·복원·목록 (FR-09, FR-10, EX-14)', () {
    setUp(() {
      location.permission = LocationPermission.whileInUse;
      location.measureResult =
          MeasureResult(position: fakePosition(), timedOut: false);
    });

    test('측정 결과가 목록 맨 앞에 저장되고, 재실행 시 마지막 결과가 복원된다', () async {
      await state.init();
      await state.measure();
      await state.measure();
      expect(state.history.length, 2);
      expect(state.history.first.id, state.current!.id);

      final again = AppState(location, StorageService(), FakeConnectivityService());
      await again.init();
      expect(again.history.length, 2);
      expect(again.current!.id, state.current!.id);
    });

    test('저장에 실패해도 화면 결과는 유지되고 saveError가 남는다', () async {
      final failing = AppState(location, FailingStorageService(), FakeConnectivityService());
      await failing.init();
      await failing.measure();
      expect(failing.current, isNotNull);
      expect(failing.saveError, contains('저장하지 못했습니다'));
      expect(failing.lastError, isNull);
      expect(failing.history.length, 1);
    });

    test('목록에서 선택하면 current가 바뀌고, 거리 비교 기준은 여전히 최신 측정이다', () async {
      await state.init();
      await state.measure();
      final first = state.current!;
      location.measureResult =
          MeasureResult(position: fakePosition(latitude: 37.567535), timedOut: false);
      await state.measure();

      state.select(first);
      expect(state.current, same(first));

      location.measureResult =
          MeasureResult(position: fakePosition(latitude: 37.567535), timedOut: false);
      await state.measure();
      // 직전 측정(37.567535)과 같은 자리이므로 거리 0
      expect(state.current!.distanceFromPrevM, closeTo(0, 0.01));
    });

    test('표시 중인 결과를 삭제하면 다음 최신 결과가 표시된다', () async {
      await state.init();
      await state.measure();
      await state.measure();
      final latest = state.current!;
      await state.delete(latest);
      expect(state.history.length, 1);
      expect(state.current!.id, state.history.first.id);
      expect(state.current!.id, isNot(latest.id));
    });

    test('전체 삭제 후 목록과 표시 결과가 비고 저장소에도 반영된다', () async {
      await state.init();
      await state.measure();
      await state.clearHistory();
      expect(state.history, isEmpty);
      expect(state.current, isNull);
      expect(await StorageService().loadMeasurements(), isEmpty);
    });
  });
}
