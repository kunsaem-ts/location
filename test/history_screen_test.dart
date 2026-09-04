import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_check/app/app_state.dart';
import 'package:location_check/app/strings.dart';
import 'package:location_check/screens/history_screen.dart';
import 'package:location_check/services/location_service.dart';
import 'package:location_check/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late FakeLocationService location;
  late AppState state;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    location = FakeLocationService()..permission = LocationPermission.whileInUse;
    state = AppState(location, StorageService(), FakeConnectivityService());
  });

  /// 메인 화면을 흉내 내는 홈에서 S3를 push한 상태로 시작한다.
  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> addMeasurements(int count) async {
    await state.init();
    for (var i = 0; i < count; i++) {
      location.measureResult = MeasureResult(
        position: fakePosition(latitude: 37.5 + i * 0.001),
        timedOut: false,
      );
      await state.measure();
    }
  }

  testWidgets('결과가 없으면 빈 상태 문구, 전체 삭제 버튼 비활성', (tester) async {
    await state.init();
    await pumpHistory(tester);
    expect(find.text(AppStrings.historyEmpty), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_sweep_outlined),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('최신순으로 나열되고 항목을 탭하면 지도 화면으로 돌아가며 선택된다', (tester) async {
    await addMeasurements(2);
    await pumpHistory(tester);
    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(2));

    // 두 번째(오래된) 항목 탭
    await tester.tap(tiles.at(1));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsNothing);
    expect(state.current!.id, state.history[1].id);
  });

  testWidgets('스와이프하면 단건 삭제', (tester) async {
    await addMeasurements(2);
    await pumpHistory(tester);
    await tester.drag(find.byType(ListTile).first, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(state.history.length, 1);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('전체 삭제는 확인 다이얼로그를 거치며, 취소하면 유지된다', (tester) async {
    await addMeasurements(2);
    await pumpHistory(tester);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteAllConfirmTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(state.history.length, 2);

    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.deleteAll));
    await tester.pumpAndSettle();
    expect(state.history, isEmpty);
    expect(find.text(AppStrings.historyEmpty), findsOneWidget);
  });
}
