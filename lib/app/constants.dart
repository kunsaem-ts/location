/// 앱 전체에서 쓰는 기준값. PRD 6.2, FR-03, FR-09 참조.
/// 숫자는 이 파일에만 둔다 (CLAUDE.md 6절 4항).
class AppConstants {
  AppConstants._();

  /// 측위 출처 추정: 오차반경이 이 값 이하이면 GPS로 추정 (PRD 6.2)
  static const double gpsMaxAccuracyM = 20;

  /// 측위 출처 추정: 오차반경이 이 값 이하이면 WiFi로 추정, 초과하면 기지국 (PRD 6.2)
  static const double wifiMaxAccuracyM = 100;

  /// 단발 측정 타임아웃 (FR-03)
  static const Duration measureTimeout = Duration(seconds: 15);

  /// 기기에 보관하는 최근 측정 결과 수 (FR-09)
  static const int maxStoredMeasurements = 50;

  /// 저장 스키마 버전 (PRD 6.3)
  static const int storageSchemaVersion = 1;

  /// 지도 기본 줌 (PRD 2.2 S2)
  static const double defaultMapZoom = 17;

  /// 위도·경도 표시 소수점 자리수 (FR-05)
  static const int coordinateDecimals = 6;

  /// 측정 결과에 기록하는 앱 버전 (PRD 6.1). pubspec.yaml의 version과 맞춘다.
  static const String appVersion = '0.1.0';

  /// 웹(iOS PWA)에서는 영구 거부를 구분할 수 없어 이 횟수 이상 거부되면 영구로 간주 (EX-03)
  static const int webDenyCountAsForever = 2;

  /// 웹 전용 Maps JavaScript API 키. 빌드 시 --dart-define=MAPS_API_KEY=... 로 주입한다 (NFR-02).
  /// tool/build_web.ps1이 android/local.properties에서 읽어 넘긴다.
  static const String webMapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  /// 측정 전 지도 초기 위치 (서울시청). 첫 측정 후에는 쓰이지 않는다.
  static const double initialLatitude = 37.566535;
  static const double initialLongitude = 126.977969;
}
