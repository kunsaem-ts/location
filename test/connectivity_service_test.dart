import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_check/models/measurement.dart';
import 'package:location_check/services/connectivity_service.dart';
import 'package:location_check/services/platform_channel.dart';
import 'package:location_check/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 네이티브 채널을 흉내 내는 가짜. 호출 횟수도 기록한다.
class FakePlatformChannel extends PlatformChannel {
  bool granted = false;
  bool grantOnRequest = false;
  int networkType = -1;
  int overrideType = -1;
  int requestCount = 0;

  @override
  Future<bool> hasPhoneStatePermission() async => granted;

  @override
  Future<bool> requestPhoneStatePermission() async {
    requestCount++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<int> dataNetworkType() async => networkType;

  @override
  Future<int> displayOverrideNetworkType() async => overrideType;
}

void main() {
  late FakePlatformChannel channel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    channel = FakePlatformChannel();
  });

  ConnectivityService make(List<ConnectivityResult> results, {bool isWeb = false}) =>
      ConnectivityService(
        StorageService(),
        channel: channel,
        checkConnectivity: () async => results,
        isWeb: isWeb,
      );

  group('FR-06 연결망 판별', () {
    test('Android WiFi → wifi', () async {
      expect(await make([ConnectivityResult.wifi]).current(), ConnectionType.wifi);
    });

    test('WiFi + VPN → wifi', () async {
      expect(
        await make([ConnectivityResult.wifi, ConnectivityResult.vpn]).current(),
        ConnectionType.wifi,
      );
    });

    test('none → 없음 (비행기 모드)', () async {
      expect(await make([ConnectivityResult.none]).current(), ConnectionType.none);
    });

    test('빈 목록 → 없음', () async {
      expect(await make([]).current(), ConnectionType.none);
    });

    test('ethernet 등 그 외 → unknown', () async {
      expect(await make([ConnectivityResult.ethernet]).current(), ConnectionType.unknown);
    });

    test('조회 예외 → unknown (측정은 계속)', () async {
      final service = ConnectivityService(
        StorageService(),
        channel: channel,
        checkConnectivity: () async => throw Exception('boom'),
        isWeb: false,
      );
      expect(await service.current(), ConnectionType.unknown);
    });
  });

  group('오프라인 감시 (FR-12)', () {
    test('isOffline: none·빈 목록이면 true, 그 외 false', () async {
      expect(await make([ConnectivityResult.none]).isOffline(), isTrue);
      expect(await make([]).isOffline(), isTrue);
      expect(await make([ConnectivityResult.mobile]).isOffline(), isFalse);
    });

    test('offlineChanges는 연결 목록 변화를 오프라인 여부로 바꿔 흘린다', () async {
      final service = ConnectivityService(
        StorageService(),
        channel: channel,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        onChanged: Stream.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
        ]),
        isWeb: false,
      );
      expect(await service.offlineChanges().toList(), [false, true, false]);
    });
  });

  group('C-4 웹(iOS PWA)', () {
    test('온라인이면 플러그인이 wifi를 돌려줘도 unknown으로 표시한다', () async {
      expect(
        await make([ConnectivityResult.wifi], isWeb: true).current(),
        ConnectionType.unknown,
      );
      expect(channel.requestCount, 0, reason: '웹에서는 네이티브 채널을 호출하지 않는다');
    });

    test('오프라인이면 없음', () async {
      expect(
        await make([ConnectivityResult.none], isWeb: true).current(),
        ConnectionType.none,
      );
    });
  });

  group('FR-06a LTE/5G 구분', () {
    test('권한 있음 + LTE(13) + override 없음 → lte', () async {
      channel
        ..granted = true
        ..networkType = PlatformChannel.networkTypeLte
        ..overrideType = 0;
      expect(await make([ConnectivityResult.mobile]).current(), ConnectionType.lte);
    });

    test('권한 있음 + NR(20) → 5G (SA)', () async {
      channel
        ..granted = true
        ..networkType = PlatformChannel.networkTypeNr;
      expect(await make([ConnectivityResult.mobile]).current(), ConnectionType.fiveG);
    });

    test('권한 있음 + LTE(13) + override NR_NSA(3) → 5G (NSA)', () async {
      channel
        ..granted = true
        ..networkType = PlatformChannel.networkTypeLte
        ..overrideType = 3;
      expect(await make([ConnectivityResult.mobile]).current(), ConnectionType.fiveG);
    });

    test('권한 있음 + 3G 등 기타 → 이동통신', () async {
      channel
        ..granted = true
        ..networkType = 3; // UMTS
      expect(await make([ConnectivityResult.mobile]).current(), ConnectionType.mobileOther);
    });

    test('권한 없음 → 최초 1회 요청, 거부되면 이동통신, 두 번째는 재요청하지 않음 (EX-09)', () async {
      channel.grantOnRequest = false;
      final service = make([ConnectivityResult.mobile]);
      expect(await service.current(), ConnectionType.mobileOther);
      expect(channel.requestCount, 1);

      expect(await service.current(), ConnectionType.mobileOther);
      expect(channel.requestCount, 1, reason: '재요청은 1회만');
    });

    test('권한 없음 → 요청해서 허용되면 바로 구분한다', () async {
      channel
        ..grantOnRequest = true
        ..networkType = PlatformChannel.networkTypeLte
        ..overrideType = -1;
      expect(await make([ConnectivityResult.mobile]).current(), ConnectionType.lte);
      expect(channel.requestCount, 1);
    });
  });
}
