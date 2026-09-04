import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/app/strings.dart';
import 'package:location_check/models/measurement.dart';
import 'package:location_check/widgets/info_panel.dart';

Measurement _measurement({
  String? provider,
  double? distance,
  bool timedOut = false,
  bool? isMock,
}) =>
    Measurement(
      id: 'id-1',
      measuredAt: DateTime(2026, 9, 4, 14, 3, 21),
      latitude: 37.566535,
      longitude: 126.977969,
      accuracyM: 8.4,
      connectionType: ConnectionType.wifi,
      locationProvider: provider,
      sourceEstimate: SourceEstimate.gps,
      platform: provider == null ? AppPlatform.iosWeb : AppPlatform.android,
      distanceFromPrevM: distance,
      isMock: isMock,
      timedOut: timedOut,
      appVersion: '0.1.0',
    );

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('정보 패널 표시 (FR-05, FR-07, FR-08)', () {
    testWidgets('위경도 6자리, 오차반경 정수, 연결망, 출처(제공자 포함), 시각', (tester) async {
      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(provider: 'fused'),
        reducedAccuracy: false,
        error: null,
      )));
      expect(find.text('37.566535'), findsOneWidget);
      expect(find.text('126.977969'), findsOneWidget);
      expect(find.text('± 8 m'), findsOneWidget);
      expect(find.text('WiFi'), findsOneWidget);
      expect(find.text('GPS 추정 (제공자 fused, ±8 m)'), findsOneWidget);
      expect(find.text('2026-09-04 14:03:21'), findsOneWidget);
      expect(find.text(AppStrings.labelDistance), findsNothing);
    });

    testWidgets('iOS(제공자 없음)는 오차반경만, 두 번째 측정은 거리 행 표시', (tester) async {
      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(distance: 111.23),
        reducedAccuracy: false,
        error: null,
      )));
      expect(find.text('GPS 추정 (±8 m)'), findsOneWidget);
      expect(find.text('111.2 m'), findsOneWidget);
    });

    testWidgets('타임아웃·대략적 위치·오류 배지', (tester) async {
      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(timedOut: true),
        reducedAccuracy: true,
        error: AppStrings.errorTimeout,
      )));
      expect(find.text(AppStrings.badgeTimedOut), findsOneWidget);
      expect(find.text(AppStrings.badgeReducedAccuracy), findsOneWidget);
      expect(find.text(AppStrings.errorTimeout), findsOneWidget);
    });

    testWidgets('모의 위치 배지 (FR-13): isMock=true일 때만 표시', (tester) async {
      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(provider: 'fused', isMock: true),
        reducedAccuracy: false,
        error: null,
      )));
      expect(find.text(AppStrings.badgeMockLocation), findsOneWidget);

      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(provider: 'fused', isMock: false),
        reducedAccuracy: false,
        error: null,
      )));
      expect(find.text(AppStrings.badgeMockLocation), findsNothing);
    });

    testWidgets('결과가 없으면 안내 문구', (tester) async {
      await tester.pumpWidget(_wrap(const InfoPanel(
        current: null,
        reducedAccuracy: false,
        error: null,
      )));
      expect(find.text(AppStrings.noResultYet), findsOneWidget);
    });
  });

  group('좌표 복사 (FR-14)', () {
    testWidgets('위도를 탭하면 "위도, 경도"가 클립보드에 들어가고 스낵바가 뜬다', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(provider: 'gps'),
        reducedAccuracy: false,
        error: null,
      )));
      await tester.tap(find.text('37.566535'));
      await tester.pump();

      expect(copied, '37.566535, 126.977969');
      expect(find.text(AppStrings.coordinatesCopied), findsOneWidget);
    });

    testWidgets('클립보드 실패 시 실패 스낵바', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            throw PlatformException(code: 'denied');
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(_wrap(InfoPanel(
        current: _measurement(provider: 'gps'),
        reducedAccuracy: false,
        error: null,
      )));
      await tester.tap(find.text('126.977969'));
      await tester.pump();

      expect(find.textContaining(AppStrings.copyFailed), findsOneWidget);
    });
  });
}
