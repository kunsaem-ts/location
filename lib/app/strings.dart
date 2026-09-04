/// UI 문자열(한국어). 화면 코드에 리터럴을 두지 않고 여기에 모은다 (CLAUDE.md 6절 6항).
class AppStrings {
  AppStrings._();

  static const String appName = '위치 측정';

  // 연결망 (PRD 2.2 S2 정보 패널)
  static const String connectionWifi = 'WiFi';
  static const String connectionLte = 'LTE';
  static const String connection5g = '5G';
  static const String connectionMobileOther = '이동통신';
  static const String connectionNone = '없음';
  static const String connectionUnknown = '알 수 없음';

  // 측위 출처 추정 (FR-07). "추정"을 항상 붙인다.
  static const String sourceGps = 'GPS 추정';
  static const String sourceWifi = 'WiFi 추정';
  static const String sourceCell = '기지국 추정';
  static const String sourceUnknown = '추정 불가';

  // S1 권한 안내 (FR-01)
  static const String permissionIntroTitle = '위치 권한이 필요합니다';
  static const String permissionIntroBody =
      '현재 위치의 좌표를 측정하기 위해 위치 권한이 필요합니다.\n'
      '권한은 앱을 사용하는 동안에만 쓰이며, 측정 결과는 이 기기에만 저장됩니다.';
  static const String permissionIntroButton = '권한 허용하기';

  // E1 위치 서비스 OFF (FR-02, EX-04)
  static const String serviceOffTitle = '기기의 위치 서비스가 꺼져 있습니다';
  static const String serviceOffBody = '설정에서 위치를 켠 뒤 다시 시도해 주세요.';
  static const String serviceOffWebGuide =
      'iPhone: 설정 > 개인정보 보호 및 보안 > 위치 서비스를 켜 주세요.';
  static const String openLocationSettings = '위치 설정 열기';
  static const String recheck = '다시 확인';

  // E2 권한 거부 (FR-11, EX-02, EX-03)
  static const String permissionDeniedTitle = '위치 권한이 거부되었습니다';
  static const String permissionDeniedBody = '위치 권한이 없으면 측정할 수 없습니다. 다시 요청하시겠어요?';
  static const String permissionDeniedForeverBody =
      '설정 > 앱 > 위치 측정 > 권한에서 위치를 허용해 주세요.';
  static const String permissionDeniedWebGuide =
      'iPhone: 설정 > 앱 > Safari > 위치에서 "허용"으로 바꾼 뒤 앱을 다시 열어 주세요.';
  static const String requestAgain = '다시 요청';
  static const String openAppSettings = '앱 설정 열기';

  // S2 메인 (FR-03, FR-05)
  static const String measure = '측정';
  static const String remeasure = '다시 측정';
  static const String measuring = '측정 중…';
  static const String noResultYet = '측정 버튼을 눌러 현재 위치를 확인하세요.';
  static const String mapLoading = '지도 불러오는 중…';
  static const String mapLoadError = '지도를 불러오지 못했습니다 (API 키 확인)';
  static const String mapKeyMissing = '지도 API 키가 설정되지 않았습니다';
  static const String labelLatitude = '위도';
  static const String labelLongitude = '경도';
  static const String labelAccuracy = '오차반경';
  static const String labelConnection = '연결망';
  static const String labelSource = '측위 출처 추정';
  static const String labelMeasuredAt = '측정 시각';
  static const String labelDistance = '직전 대비 거리';
  static const String providerPrefix = '제공자 ';
  static const String coordinatesCopied = '좌표를 복사했습니다';
  static const String copyFailed = '복사에 실패했습니다';
  static const String measuringSecondsSuffix = '초';
  static const String badgeTimedOut = '타임아웃, 마지막 수신 위치';
  static const String badgeReducedAccuracy = '대략적 위치 모드, 오차 큼';
  static const String badgeMockLocation = '모의 위치가 감지되었습니다';

  // E3 오프라인 배너 (FR-12, EX-06)
  static const String offlineBanner = '인터넷 연결이 없습니다. 지도는 표시되지 않지만 GPS 측정은 가능합니다.';

  // 웹 HTTPS 아님 (EX-13)
  static const String insecureTitle = '이 앱은 HTTPS 주소에서만 동작합니다';
  static const String insecureBody =
      '브라우저가 HTTP 주소에서는 위치 정보를 제공하지 않습니다.\n'
      '주소가 https:// 로 시작하는 링크로 다시 열어 주세요.';

  // S3 최근 결과 (FR-09, FR-10)
  static const String historyTitle = '최근 결과';
  static const String historyEmpty = '아직 측정 결과가 없습니다';
  static const String deleteAll = '전체 삭제';
  static const String deleteAllConfirmTitle = '모든 결과를 삭제할까요?';
  static const String deleteAllConfirmBody = '삭제한 결과는 되돌릴 수 없습니다.';
  static const String cancel = '취소';
  static const String delete = '삭제';
  static const String saveFailed = '결과를 저장하지 못했습니다';

  // 오류 (EX-07, EX-08)
  static const String errorTimeout = '위치를 찾지 못했습니다. 하늘이 보이는 곳에서 다시 시도해 주세요.';
  static const String errorMeasureFailed = '측정에 실패했습니다';
}
