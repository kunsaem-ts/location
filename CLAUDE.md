# CLAUDE.md — 위치 측정 앱 (Location Check)

전역 지침(`~/.claude/CLAUDE.md`)의 언어·호칭·Karpathy 가이드라인을 그대로 따르며, 아래는 이 프로젝트에만 적용되는 규칙입니다.

## 1. 프로젝트 한 줄 요약
현재 위치를 구글맵에 마커+오차반경으로 표시하고, 측정 시점의 연결망(WiFi/LTE/5G)을 함께 기록하는 **개인용** Flutter 앱. Android는 APK 사이드로드, iOS는 같은 코드를 웹으로 빌드해 PWA(GitHub Pages)로 배포.

## 2. 기준 문서 (변경 시 반드시 함께 갱신)
| 문서 | 역할 |
|---|---|
| `docs/PRD.md` (v0.2, 승인됨) | 요구사항의 단일 기준. FR/NFR/EX/T 번호를 코드 주석·커밋 메시지에서 그대로 인용 |
| `docs/TASKS.md` | 단계별 작업 체크리스트. 작업 시작 전 해당 항목 확인, 완료 시 체크 |
| `docs/TEST_RESULTS.md` | 실기기 테스트 기록 양식 (PRD 7절 T-01~T-20) |
| `docs/IPHONE.md` | 아이폰 홈 화면 PWA 설치·실행 안내 (선생님용) |
| `CLAUDE.md` (이 파일) | 프로젝트 규칙 |

PRD와 충돌하는 구현 요청이 오면 먼저 PRD 개정 여부를 선생님께 확인합니다.

## 3. 확정된 결정 (PRD 1.2 요약, 변경 금지)
- 플랫폼: Flutter 단일 코드베이스 / 대상: Android 10+ (API 29), iOS 16.4+ Safari PWA
- 앱 이름 "위치 측정", Android 패키지 `com.tsdevel.locationcheck`
- 지도: `google_maps_flutter`(Android) + `google_maps_flutter_web`(웹). API 키 2종은 선생님이 직접 발급
- 저장: 기기 로컬 `shared_preferences`, 최근 50건
- 1차 범위: Must + Should. Could(FR-16/17/18)는 구현하지 않음
- iOS PWA는 연결망을 `알 수 없음`으로 표시 (거짓 표시 금지)

## 4. 개발 환경 (2026-09-04 0단계 완료 기준)
- Windows 11, PowerShell, 관리자 권한 없음(Android Studio 미설치, 명령줄 도구로 구성)
- **Flutter 3.47.2 stable** (Dart 3.13.2) — `C:\src\flutter`
- **Microsoft OpenJDK 17.0.20.1** — `C:\src\jdk-17` (`JAVA_HOME`)
- **Android SDK** — `C:\src\android-sdk` (`ANDROID_HOME`): cmdline-tools latest, platform-tools, platforms android-35/36, build-tools 35.0.0/36.0.0. 라이선스 동의 완료
- Chrome 152, Visual Studio Build Tools 2026(이미 있었음). `flutter doctor` 전 항목 ✓
- PATH(사용자)에 `C:\src\flutter\bin`, `C:\src\jdk-17\bin`, `C:\src\android-sdk\platform-tools`, `...\cmdline-tools\latest\bin` 등록. **이 세션보다 먼저 열린 터미널은 다시 열어야 적용됨**
- 사용 명령:
  ```powershell
  flutter doctor -v                      # 환경 점검
  flutter pub get
  flutter analyze                        # 경고 0 유지
  flutter test
  flutter run -d <android-device-id>     # 실기기
  flutter build apk --release            # Android 산출물 build/app/outputs/flutter-apk/app-release.apk
  .\tool\build_web.ps1 -BaseHref /location/      # PWA 산출물 build/web (키 주입 포함)
  .\tool\build_web.ps1 -Run                      # Chrome에서 실행 (키 주입 포함)
  dart run tool/serve_web.dart                   # build/web을 http://127.0.0.1:8081/location/ 로 서비스 (검증용)
  ```
- Flutter 업그레이드는 선생님 요청 시에만 `flutter upgrade`로 하고, 이 절의 버전을 함께 갱신합니다.

## 5. 코드 구조 (2026-09-04 11단계 기준, 실제)
```
lib/
  main.dart                    # 앱 진입, Provider, AppStage → 화면 라우팅
  app/
    app_state.dart             # ChangeNotifier. 권한/서비스/측정/저장/오프라인 흐름 전체 (PRD 2.1)
    constants.dart             # 기준값 20 m/100 m, 타임아웃 15초, 50건, 줌 17, 앱 버전, 웹 키(dart-define)
    strings.dart               # 한국어 UI 문자열 전부
    colors.dart                # 연결망별 마커 색 (WiFi 파랑 / 이동통신 주황 / 없음·알 수 없음 회색)
  models/measurement.dart      # PRD 6.1 데이터 모델 + JSON 직렬화, enum 3종
  services/
    location_service.dart      # 권한·위치 서비스·고정밀 단발 측정·15초 타임아웃(Dart 쪽) (FR-01~03)
    connectivity_service.dart  # 연결망 판별(FR-06/06a), 오프라인 감시(FR-12). 웹은 unknown 고정
    platform_channel.dart      # Android MethodChannel 래퍼: 전화 상태 권한, LTE/5G, 위치 제공자
    storage_service.dart       # shared_preferences: 결과 50건 FIFO, 권한 플래그 (FR-09/10)
    source_estimator.dart      # PRD 6.2 출처 추정 + Haversine 거리 (FR-07/08)
    maps_loader.dart           # 웹 Maps JS 스크립트 1회 로드 (stub/web 조건부 import)
    maps_script_stub.dart / maps_script_web.dart
    web_context.dart           # HTTPS 아닌 웹 접속 판정 (EX-13)
  screens/
    permission_intro_screen.dart   # S1
    main_screen.dart               # S2 (지도 + 정보 패널 + 측정 버튼 + 오프라인 배너)
    history_screen.dart            # S3 최근 결과
    service_off_screen.dart        # E1
    permission_denied_screen.dart  # E2
    insecure_context_screen.dart   # 웹 HTTP 접속 안내
  widgets/
    measurement_map.dart       # GoogleMap + 점 마커 + 오차 원 (FR-04)
    info_panel.dart            # 정보 패널, 좌표 복사 (FR-05/07/08/13/14)
    notice_layout.dart         # 안내 화면 공통 레이아웃
android/app/src/main/kotlin/com/tsdevel/locationcheck/MainActivity.kt  # MethodChannel 구현(Kotlin)
web/                           # index.html(키 없음), manifest.json(PWA)
tool/build_web.ps1             # 키 주입 웹 빌드/실행
tool/serve_web.dart            # build/web 로컬 정적 서버 (검증용)
.github/workflows/deploy-pages.yml  # main push → 분석·테스트·웹 빌드 → GitHub Pages
test/                          # 70건: fakes.dart(공용 가짜) + 단위 9파일 + 위젯 2파일
docs/PRD.md, TASKS.md, TEST_RESULTS.md
dist/                          # 릴리스 APK 사본 (gitignore)
```
- 상태 관리는 Flutter 기본 `ChangeNotifier` + `Provider`만 사용. 다른 상태 관리 패키지를 도입하지 않습니다.
- 플랫폼 분기는 `kIsWeb`과 `defaultTargetPlatform`으로만 하며, 서비스 계층 안에서 처리하고 화면 코드에는 분기를 두지 않습니다.

## 6. 반드시 지킬 규칙
1. **API 키를 커밋하지 않습니다.** 키는 `android/local.properties`의 `MAPS_API_KEY` 한 곳에만 둡니다(gitignore). Android는 `build.gradle.kts`가 읽어 manifest placeholder로 주입하고, 웹은 `tool/build_web.ps1`이 읽어 `--dart-define=MAPS_API_KEY`로 넘기며 `lib/services/maps_script_web.dart`가 스크립트를 동적으로 로드합니다. 키를 소스·index.html·대화 로그에 적지 않습니다.
2. **iOS PWA에서 연결망을 추측해 WiFi/LTE로 표시하지 않습니다.** 항상 `unknown` (PRD C-4, FR-06).
3. "측위 출처"는 UI에 항상 "추정"이라는 단어를 붙입니다 (FR-07).
4. 기준값(20 m / 100 m, 타임아웃 15초, 최대 50건)은 `lib/app/constants.dart` 한 곳에만 둡니다.
5. 백그라운드 위치 권한, WiFi 제어 권한은 요청하지 않습니다 (PRD 5.1).
6. UI 문자열은 한국어이며 `lib/app/strings.dart`에 모읍니다.
7. 요청받지 않은 기능(CSV, 이전 마커, 다크 모드 등)은 추가하지 않습니다.
8. 각 작업은 `docs/TASKS.md`의 검증 기준을 통과한 뒤에만 체크합니다. 실기기 검증이 필요한 항목은 선생님께 결과를 요청합니다.

## 7. 커밋 규칙
- 저장소: `https://github.com/kunsaem-ts/location` (main 브랜치). PWA 주소: `https://kunsaem-ts.github.io/location/`
- main에 push하면 `.github/workflows/deploy-pages.yml`이 분석·테스트·웹 빌드 후 GitHub Pages에 배포합니다. 웹 키는 리포지토리 Secret `MAPS_API_KEY`.
- 커밋 메시지: `<단계>: <내용> (FR-xx)` 형식, 한국어. 예: `2단계: 위치 권한 흐름 구현 (FR-01, FR-02)`
- 커밋 전 `flutter analyze`와 `flutter test`가 통과해야 합니다.
- 커밋·푸시는 선생님이 요청할 때만 합니다.
