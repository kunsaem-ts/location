import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:location_check/models/measurement.dart';
import 'package:location_check/services/connectivity_service.dart';
import 'package:location_check/services/location_service.dart';
import 'package:location_check/services/storage_service.dart';

/// 연결망 판별은 connectivity_service_test에서 따로 검증하므로 고정값을 돌려준다.
class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService() : super(StorageService(), isWeb: false);
  ConnectionType connection = ConnectionType.wifi;
  bool offline = false;
  final offlineController = StreamController<bool>.broadcast();

  @override
  Future<ConnectionType> current() async => connection;

  @override
  Future<bool> isOffline() async => offline;

  @override
  Stream<bool> offlineChanges() => offlineController.stream;
}

/// 실기기 없이 흐름을 검증하기 위한 가짜 위치 서비스.
class FakeLocationService extends LocationService {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requestResult = LocationPermission.whileInUse;
  bool serviceEnabled = true;
  LocationAccuracyStatus accuracy = LocationAccuracyStatus.precise;
  MeasureResult? measureResult;
  Object? measureError;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permission = requestResult;
    return requestResult;
  }

  @override
  Future<LocationAccuracyStatus> accuracyStatus() async => accuracy;

  @override
  Future<MeasureResult> measure() async {
    if (measureError != null) throw measureError!;
    return measureResult!;
  }
}

/// 저장 실패(EX-14)를 흉내 낸다.
class FailingStorageService extends StorageService {
  @override
  Future<List<Measurement>> addMeasurement(Measurement m) async =>
      throw Exception('disk full');
}

Position fakePosition({double accuracy = 10, double latitude = 37.566535}) =>
    Position(
      latitude: latitude,
      longitude: 126.977969,
      timestamp: DateTime(2026, 9, 4, 14),
      accuracy: accuracy,
      altitude: 38.2,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Measurement fakeMeasurement({
  required String id,
  double latitude = 37.566535,
  DateTime? measuredAt,
  ConnectionType connection = ConnectionType.wifi,
}) =>
    Measurement(
      id: id,
      measuredAt: measuredAt ?? DateTime(2026, 9, 4, 14, 3, 21),
      latitude: latitude,
      longitude: 126.977969,
      accuracyM: 12,
      connectionType: connection,
      sourceEstimate: SourceEstimate.gps,
      platform: AppPlatform.android,
      timedOut: false,
      appVersion: '0.1.0',
    );
