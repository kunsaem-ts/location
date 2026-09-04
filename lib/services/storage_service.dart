import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app/constants.dart';
import '../models/measurement.dart';

/// 기기 로컬 저장소. Android는 SharedPreferences, 웹은 localStorage (PRD 6.3).
class StorageService {
  static const _keyPermissionAsked = 'permissionAsked';
  static const _keyPermissionDenyCount = 'permissionDenyCount';
  static const _keyPhoneStateAsked = 'phoneStateAsked';
  static const _keyMeasurements = 'measurements';
  static const _keySchemaVersion = 'schemaVersion';

  // ---- 측정 결과 (FR-09, FR-10) ----

  /// 저장된 결과. 배열 앞쪽이 최신. 손상된 데이터는 빈 목록으로 본다.
  Future<List<Measurement>> loadMeasurements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyMeasurements);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 맨 앞에 추가하고 최대 건수를 넘으면 가장 오래된 것부터 버린다. 저장 후 목록을 돌려준다.
  Future<List<Measurement>> addMeasurement(Measurement m) async {
    final list = [m, ...await loadMeasurements()];
    if (list.length > AppConstants.maxStoredMeasurements) {
      list.removeRange(AppConstants.maxStoredMeasurements, list.length);
    }
    await _saveMeasurements(list);
    return list;
  }

  Future<List<Measurement>> deleteMeasurement(String id) async {
    final list = (await loadMeasurements())..removeWhere((m) => m.id == id);
    await _saveMeasurements(list);
    return list;
  }

  Future<void> clearMeasurements() => _saveMeasurements(const []);

  Future<void> _saveMeasurements(List<Measurement> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySchemaVersion, AppConstants.storageSchemaVersion);
    await prefs.setString(
      _keyMeasurements,
      jsonEncode(list.map((m) => m.toJson()).toList()),
    );
  }

  // ---- 권한 흐름 플래그 (FR-01, FR-11, EX-09) ----

  /// 위치 권한을 한 번이라도 요청한 적이 있는지.
  /// Android는 "요청 전"과 "일시 거부"가 모두 denied로 조회되므로 S1/E2 구분에 쓴다 (FR-01, FR-11).
  Future<bool> wasPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionAsked) ?? false;
  }

  Future<void> markPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionAsked, true);
  }

  /// 웹(iOS PWA) 전용: 거부 횟수를 늘리고 누적값을 돌려준다 (EX-03).
  Future<int> incrementPermissionDenyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_keyPermissionDenyCount) ?? 0) + 1;
    await prefs.setInt(_keyPermissionDenyCount, next);
    return next;
  }

  /// 전화 상태 권한(LTE/5G 구분용)을 요청한 적이 있는지. 재요청은 하지 않는다 (EX-09).
  Future<bool> wasPhoneStateAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPhoneStateAsked) ?? false;
  }

  Future<void> markPhoneStateAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPhoneStateAsked, true);
  }
}
