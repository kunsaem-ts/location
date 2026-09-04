# 작업 체크리스트 — 위치 측정 앱

기준 문서: `docs/PRD.md` v0.2 (승인일 2026-09-04). 각 항목은 **검증** 기준을 통과한 뒤에만 체크합니다.
표기: `[ ]` 미완료 / `[x]` 완료 / `[!]` 선생님 조치 필요 / `[-]` 보류

---

## 0단계. 개발 환경 구축 (이 PC에 Flutter·JDK·Android SDK 없음)

- [x] 0-1. Flutter SDK(stable) 설치 — `C:\src\flutter`, **Flutter 3.47.2 / Dart 3.13.2** (2026-09-04)
  - 검증: 새 PowerShell에서 `flutter --version` 출력, 버전을 `CLAUDE.md` 4절에 기록
- [x] 0-2. Android SDK 설치 — 관리자 권한이 없어 Android Studio 대신 **명령줄 도구 + Microsoft OpenJDK 17(zip)** 사용
  - 경로: JDK `C:\src\jdk-17`, SDK `C:\src\android-sdk` (cmdline-tools, platform-tools, platforms;android-35·36, build-tools;35.0.0·36.0.0 — Flutter 3.47은 SDK 36 요구)
  - 사용자 환경 변수: `JAVA_HOME`, `ANDROID_HOME`, PATH에 flutter/bin·jdk/bin·platform-tools·cmdline-tools/latest/bin 추가
  - 검증: `flutter doctor -v`에서 Android toolchain ✓ (IDE가 필요하면 Android Studio는 나중에 별도 설치 가능)
- [x] 0-3. Android SDK 라이선스 동의 (`sdkmanager --licenses` 및 `flutter doctor --android-licenses`)
  - 검증: `flutter doctor`에 라이선스 경고 없음
- [x] 0-4. Chrome 설치 확인 (Chrome 152) (Flutter 웹 디버깅용)
  - 검증: `flutter doctor -v`에서 Chrome ✓
- [!] 0-5. 삼성 기기 개발자 옵션 → USB 디버깅 켜기, PC 연결 후 승인 (선생님)
  - 검증: `flutter devices`에 기기 표시
- [x] 0-6. `git init`, `.gitignore`(Flutter 기본 + `android/local.properties` + `web/index.html` 치환 결과물)
  - 검증: `git status`에 빌드 산출물·키 파일이 없음

## 1단계. 프로젝트 골격

- [x] 1-1. `flutter create --org com.tsdevel --project-name location_check .` (Android + Web만 활성화, iOS/데스크톱 비활성)
  - 검증: `flutter run -d chrome`으로 기본 앱 실행
- [x] 1-2. `pubspec.yaml` 의존성 추가: `geolocator`, `connectivity_plus`, `google_maps_flutter`, `google_maps_flutter_web`, `shared_preferences`, `provider`, `uuid`, `intl`
  - 검증: `flutter pub get` 성공, `flutter analyze` 경고 0
- [x] 1-3. 폴더 구조 생성 (`CLAUDE.md` 5절), `lib/app/constants.dart`(기준값 20 m / 100 m, 타임아웃 15초, 최대 50건), `lib/app/strings.dart`(한국어 문자열)
  - 검증: 상수가 한 곳에만 존재 (`grep`으로 숫자 리터럴 중복 없음)
- [x] 1-4. 앱 이름 "위치 측정", 패키지명 `com.tsdevel.locationcheck`, `minSdkVersion 29`
  - 검증: 설치 후 런처에 "위치 측정" 표시
- [x] 1-5. `models/measurement.dart` — PRD 6.1 필드 전부, `toJson`/`fromJson`, enum(`ConnectionType`, `SourceEstimate`, `AppPlatform`)
  - 검증: 단위 테스트 — 직렬화 왕복이 원본과 동일

## 2단계. 권한·위치 서비스·측정 (FR-01, FR-02, FR-03, FR-11)

- [ ] 2-1. `location_service.dart` — 권한 상태 조회/요청("앱 사용 중"만), 위치 서비스 ON/OFF 조회 — **구현 완료·단위 테스트 통과, 실기기 검증 대기**
  - 검증: Android 실기기에서 최초 실행 시 S1 → OS 팝업 순서
- [ ] 2-2. 고정밀 단발 측정 + 15초 타임아웃 + 타임아웃 시 마지막 수신 위치 사용 (`timedOut` 플래그) — **구현 완료·단위 테스트 통과, 실기기 검증 대기**
  - 검증: 야외 15초 내 결과 / 지하에서 타임아웃 배지 (T-15)
- [ ] 2-3. 일시 거부 / 영구 거부 구분, `openAppSettings`, `openLocationSettings` 연결 — **구현 완료·단위 테스트 통과, 실기기 검증 대기**
  - 검증: T-11, T-12, T-13
- [ ] 2-4. 대략적 위치 권한만 허용된 경우 배지 (EX-05) — **구현 완료·단위 테스트 통과, 실기기 검증 대기**
  - 검증: Android 12+에서 "대략적 위치" 선택 시 배지 표시

## 3단계. 연결망 판별 (FR-06, FR-06a)

- [ ] 3-1. `connectivity_service.dart` — Android: `connectivity_plus`로 wifi/mobile/none. 웹: `navigator.onLine`만 사용, 온라인이면 `unknown` — **구현 완료·단위 테스트 통과(웹 분기 포함 8건), 실기기 3종(WiFi/데이터/비행기 모드) 검증 대기**
  - 검증: 단위 테스트(웹 분기 → unknown), 실기기 WiFi/데이터/비행기 모드 3종
- [ ] 3-2. Android MethodChannel `dataNetworkType` — LTE(13) / NR(20) / 기타 구분, 전화 상태 권한 요청 1회 — **구현 완료·단위 테스트 통과, 실기기 검증 대기**. NSA 5G(dataNetworkType=LTE)는 TelephonyDisplayInfo override로 판별(API 31+), API 29~30은 LTE로 표시
  - 검증: LTE 강제 시 `LTE`, 5G 지역에서 `5G`, 권한 거부 시 `이동통신` (T-05, T-16)

## 4단계. 지도 표시 (FR-04) — O-1 API 키 필요

- [x] 4-1. 선생님: Google Cloud 프로젝트·API 활성화 — **키 1개 수령(2026-09-04)**. Android/웹 공용으로 사용 중. 활성화된 API가 Maps SDK for Android + Maps JavaScript API인지 확인 필요
- [!] 4-2. 선생님: Android 키 제한 = 패키지 `com.tsdevel.locationcheck` + 디버그 SHA-1 `8A:FB:37:67:5D:28:7E:41:5F:FC:46:D6:CA:63:AB:BC:9E:6B:AB:88` (공용 키를 쓰는 동안은 "Android 앱 + 웹사이트" 두 제한을 동시에 걸 수 없으므로, 제한하려면 키를 2개로 분리)
- [!] 4-3. 선생님: 웹 키 제한 = HTTP 리퍼러 `https://kunsaem-ts.github.io/location/*`, `http://127.0.0.1:*`, `http://localhost:*` (8-1 저장소 확정 후)
- [x] 4-4. Android 키 주입: `android/local.properties`의 `MAPS_API_KEY` → `build.gradle` manifestPlaceholders → `AndroidManifest.xml` meta-data — 검증: git에 키 없음, APK meta-data에 키 주입 확인(aapt2). Android 실기기 타일 표시는 검증 대기
  - 검증: `git status`에 키 없음, 앱에서 지도 타일 표시
- [x] 4-5. 웹 키 주입: `tool/build_web.ps1`이 `android/local.properties`의 키를 `--dart-define=MAPS_API_KEY`로 넘기고, `maps_script_web.dart`가 Maps JS 스크립트를 동적 로드 (index.html에 키 없음) — 검증: Chrome(127.0.0.1:8080)에서 지도 표시 확인
  - 검증: `flutter run -d chrome`에서 지도 표시
- [ ] 4-6. 마커 + 오차반경 원, 연결망별 색(WiFi 파랑 / LTE·5G 주황 / 없음·알 수 없음 회색), 카메라 이동, 기본 줌 17 — **구현 완료, 웹에서 마커·원·줌 17 확인**. Android 실기기 검증 대기
  - 검증: 원 반지름이 accuracyM과 일치(지도 축척으로 육안 확인)
- [ ] 4-7. 지도 로드 실패 시 오류 메시지, 좌표 텍스트는 정상 (EX-12) — **웹: 스크립트 로드 실패·키 미설정 시 오류 문구 구현**. Android SDK는 잘못된 키에 콜백이 없어 빈 지도만 표시됨(로그캣 Authorization failure). T-18은 웹에서만 가능
  - 검증: T-18 (잘못된 키로 빌드)

## 5단계. 정보 패널·측위 출처·거리 (FR-05, FR-07, FR-08, FR-14, FR-15)

- [ ] 5-1. Android MethodChannel `lastLocationProvider` — `Location.provider` 문자열, `isMock`(API 31+) — **구현 완료(getLastLocationProvider: gps/network/fused 마지막 위치와 좌표·시각 대조), 실기기 검증 대기**
  - 검증: 야외에서 `gps` 또는 `fused` 반환
- [x] 5-2. `source_estimator.dart` — PRD 6.2 규칙 구현 — 단위 테스트 5건 통과
  - 검증: 단위 테스트 — (android, gps, 50) → gps / (android, network, 150) → cell / (iosWeb, null, 15) → gps / (iosWeb, null, 60) → wifi / (iosWeb, null, 200) → cell / accuracy null → unknown
- [x] 5-3. Haversine 거리 계산 (`source_estimator.dart` 자체 구현, 지구 반지름 6,371 km), 소수점 1자리 — 단위 테스트 3건 통과
  - 검증: 단위 테스트 — 위도 0.001° 차이 ≈ 111.2 m ±0.5, 서울시청↔광화문광장 약 720 m ±30
- [x] 5-4. 정보 패널 UI — 위경도 6자리, 오차반경 정수, 연결망, "○○ 추정 (제공자 x, ±n m)", 측정 시각, 직전 대비 거리 — 위젯 테스트 4건 + Chrome에서 표시 확인
  - 검증: 5개 항목 + 거리 표시, 첫 측정 시 거리 미표시
- [x] 5-5. 위경도 탭 → 클립보드 복사 + 스낵바 — 위젯 테스트(클립보드 mock, 성공·실패 스낵바) 통과
  - 검증: 붙여넣기 결과 `37.566535, 126.977969` 형식
- [x] 5-6. 측정 중 버튼 비활성 + 경과 초 표시 — Chrome에서 "측정 중… (4초)" 비활성 버튼 확인, 단위 테스트(중복 호출 1회) 통과
  - 검증: T-20 (연타 시 결과 1건)

## 6단계. 저장·목록 (FR-09, FR-10)

- [x] 6-1. `storage_service.dart` — JSON 배열 저장, 최신 우선, 50건 FIFO, `schemaVersion` — 단위 테스트 6건 통과(51건→50건, 최신 우선, schemaVersion, 손상 JSON)
  - 검증: 단위 테스트 — 51건 추가 시 가장 오래된 1건 삭제
- [ ] 6-2. 앱 시작 시 마지막 결과 복원, 지도에 표시 — **구현 완료·단위 테스트 통과(재실행 복원), 실기기 T-08 검증 대기**
  - 검증: T-08
- [ ] 6-3. S3 목록 화면 — 항목 탭 → 지도 이동, 스와이프 단건 삭제, 전체 삭제(확인 다이얼로그), 빈 상태 — **구현 완료·위젯 테스트 4건 통과(빈 상태·탭 선택·스와이프 삭제·전체 삭제 다이얼로그), 실기기 T-09/T-10 검증 대기**
  - 검증: T-09, T-10
- [x] 6-4. 저장 실패 시 스낵바, 화면 결과는 유지 (EX-14) — 단위 테스트(저장 예외 주입) 통과, 메인 화면 스낵바 연결
  - 검증: 저장 예외를 강제 주입한 단위 테스트

## 7단계. 안내 화면·오프라인 (FR-12, E1/E2/E3)

- [ ] 7-1. E1 위치 서비스 OFF 화면, [위치 설정 열기] / [다시 확인], 웹은 경로 안내 텍스트 — **2단계에서 구현·단위 테스트 통과, 실기기 T-11 검증 대기**
  - 검증: T-11
- [ ] 7-2. E2 권한 거부 화면 (일시/영구 분기) — **2단계에서 구현·단위 테스트 통과, Chrome에서 E2 표시 확인, 실기기 T-12/T-13 검증 대기**
  - 검증: T-12, T-13
- [ ] 7-3. E3 오프라인 배너, 측정 허용, 연결망 `없음` 기록, 지도 없어도 좌표 표시 — **구현 완료(연결 변화 스트림 감시, MaterialBanner)·단위 테스트 통과, 실기기 T-14 검증 대기**
  - 검증: T-14 (비행기 모드 + 위치 ON)
- [ ] 7-4. 모의 위치 배지 (FR-13) — **구현 완료·위젯 테스트 통과, 실기기 T-17 검증 대기**
  - 검증: T-17
- [x] 7-5. HTTPS 아닌 웹 접속 시 전체 화면 안내 (EX-13, localhost 제외) — 단위 테스트 4건 통과(https 허용, http 외부 차단, localhost 허용, 비웹 무시)
  - 검증: T-19

## 8단계. 웹/PWA 빌드와 GitHub Pages 배포 — O-2 저장소 필요

- [x] 8-1. GitHub 저장소 `kunsaem-ts/location` (2026-09-04). PWA 주소 `https://kunsaem-ts.github.io/location/`
- [x] 8-2. `web/manifest.json` — 이름 "위치 측정", `display: standalone`, 아이콘 192/512, 한국어 — manifest.json(이름·lang ko·standalone·아이콘 4종)과 index.html 제목·메타 갱신
  - 검증: Chrome DevTools > Application > Manifest 오류 없음
- [x] 8-3. `flutter build web --release --base-href /<repo>/` + `tool/build_web.ps1`(키 치환 포함) — `tool/build_web.ps1 -BaseHref /location/` 빌드 후 `dart run tool/serve_web.dart`로 Chrome에서 확인(base href·manifest 정상)
  - 검증: `build/web`을 로컬 정적 서버로 열어 동작
- [x] 8-4. GitHub Actions 워크플로 — push 시 웹 빌드 후 `gh-pages` 배포, 웹 키는 리포지토리 Secret — 실행 33836896196 성공(analyze·test·build·deploy). Pages 소스=GitHub Actions, 저장소 공개 전환 후 배포. `https://kunsaem-ts.github.io/location/`에서 지도·측정 동작 확인(2026-09-04). 참고: Flutter 3.47 웹 빌드는 서비스 워커를 등록하지 않아 오프라인 셸 캐시는 없음
  - 검증: `https://<id>.github.io/<repo>/`에서 앱 로드, 지도 표시
- [!] 8-5. 선생님: iPhone 12 mini에 홈 화면 추가 — 절차는 `docs/IPHONE.md`. 마클 사전 검증(2026-09-04): 375×731 iframe에서 S1·메인(7행+버튼)·최근 결과·오프라인 배너 레이아웃 정상, 상태 표시줄 스타일 default·페이지 배경색 적용
  - 검증: 홈 화면 아이콘으로 실행, 측정 성공, 연결망 `알 수 없음`

## 9단계. Android 릴리스 빌드

- [x] 9-1. `flutter build apk --release` (디버그 서명 그대로 사용, 개인용) — 2026-09-04 빌드 성공(46.9 MB, 전체 ABI 포함). 패키지·라벨·minSdk 29·targetSdk 36·권한 6종·디버그 서명(SHA-1 8A:FB:…) 확인. 산출물 사본 `dist/location_check-0.1.0-release.apk`(gitignore). 실기기 설치·실행은 9-2 대기
  - 검증: `app-release.apk` 생성, 삼성 기기에 설치·실행
- [!] 9-2. 선생님: 기기에서 "출처를 알 수 없는 앱" 허용 후 APK 설치
  - 검증: 런처에 "위치 측정" 표시

## 10단계. 테스트 (PRD 7절)

- [x] 10-1. 단위 테스트 전체 통과 (`flutter test`) — 1-5, 3-1, 5-2, 5-3, 6-1, 6-4 — 70건 통과(2026-09-04). 목록: measurement 4, app_state 21, connectivity 16, source_estimator 8, colors 1, storage 6, info_panel 7, history_screen 4, web_context 4
- [!] 10-2. 선생님: Android 실기기 시나리오 T-01~T-20 수행, 결과를 `docs/TEST_RESULTS.md` 2절에 기록 (양식 작성 완료)
- [!] 10-3. 선생님: iPhone PWA 시나리오 (T-05, T-13, T-16, T-17 제외) 수행, `docs/TEST_RESULTS.md` 3절에 기록
- [ ] 10-4. 실측 결과로 기준값(20 m / 100 m) 조정 필요 여부 판단 (O-5), 필요 시 `constants.dart`만 수정
  - 검증: PRD 7.3 전체 합격 기준 충족

## 11단계. 마무리

- [x] 11-1. `CLAUDE.md` 4절에 실제 Flutter 버전 기록, 5절 구조가 실제와 일치하는지 확인 — 4절 버전 기록(3.47.2), 5절을 실제 구조로 갱신(2026-09-04)
- [x] 11-2. `docs/PRD.md`에 구현 중 변경된 사항이 있으면 v0.3으로 갱신 — PRD v0.3: 9절 "구현 중 확정·변경 사항" 추가, 1.2·8.3 갱신
- [x] 11-3. 최종 커밋·푸시 (선생님 요청 시) — 2026-09-04 11단계 마무리 커밋·푸시. 이후 실기기 검증 결과에 따라 추가 커밋

---

## 선생님 조치 항목 모음 (`[!]`)
| 항목 | 단계 | 시점 |
|---|---|---|
| 삼성 기기 USB 디버깅 켜기 | 0-5 | 0단계 |
| Google Cloud 프로젝트 + API 키 2종 발급 | 4-1 ~ 4-3 | 4단계 시작 전 |
| GitHub 저장소 이름·공개 여부 | 8-1 | 8단계 시작 전 (4-3 리퍼러에도 필요) |
| iPhone 홈 화면에 추가 | 8-5 | 8단계 배포 후 |
| APK 설치 허용 | 9-2 | 9단계 |
| 실기기 테스트 수행·기록 | 10-2, 10-3 | 10단계 |
