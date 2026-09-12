# CLAUDE.md — talkverselab/talkverse-zh

이 폴더에서 작업하는 모든 세션이 먼저 읽는 규칙. **빌드·배포를 건드리기 전에 반드시 확인할 것.**

## 1. 서명 (가장 자주 사고 나는 곳)

이 앱은 GitHub 릴리스로 **앱 안에서 스스로 업데이트**한다.
폰에 이미 깔린 앱과 **서명 키가 같아야만** 덮어쓰기 설치가 된다.

### 쓰는 키 — 새로 만들지 말 것

- 이 앱만 **자체 업로드 키**를 쓴다. 리포 시크릿 `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` /
  `ANDROID_KEY_PASSWORD` / `ANDROID_KEY_ALIAS` 에 들어 있고, CI가 `android/key.properties`로 복원한다.
- 폰에 깔린 앱의 서명 SHA-1 `c2c37b28ce7b9e71fa75957ecaed82fdc1fa7ebd`.
  다른 앱들이 쓰는 디버그 키(`9cc4bc93…`)와 **다르다.** 섞지 말 것.

### 절대 하지 말 것

- **새 키스토어를 만들지 말 것.** 서명이 바뀌면 폰에서 앱을 지웠다 다시 깔아야 하고, **학습 기록이 전부 사라진다.**
- CI의 `Restore signing key` 단계를 지우거나, `build.gradle.kts`의 release 서명을
  `signingConfigs.getByName("debug")` 로 되돌리지 말 것.
  GitHub 러너는 빌드할 때마다 debug 키를 **새로 만들어** 서명이 매번 달라진다.
  (2026-09-10에 실제로 겪은 문제 — 17개 앱 설치가 전부 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`로 실패했다.)
- `android/key.properties`, `android/app/signing-key.jks`를 커밋하지 말 것 (`.gitignore`에 있음).

### 설치가 실패하면

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match
```

→ 앱을 지우지 말고 **서명부터 확인**한다:

```bash
apksigner verify --print-certs <apk> | grep SHA-1   # c2c37b28ce7b9e71fa75957ecaed82fdc1fa7ebd 여야 한다 (9cc4bc93… 이면 디버그 키로 잘못 서명된 것)
```

## 폰에 설치할 때 (PC에서 케이블로)

폰에 **듀얼 메신저 프로필(user 95)** 과 보안 폴더(user 150)가 있다. `adb install` 은 프로필을 지정하지 않으면
**모든 프로필에 설치**해서 앱 아이콘이 두 개(파란 말풍선 배지 달린 복제본)가 생긴다. 반드시 기본 프로필만 지정한다:

```bash
adb -s R3CY20HDN2K install --user 0 -r <apk>
```

(2026-09-11에 24개 앱이 전부 두 개씩 깔려 있던 것을 정리함. 앱 안의 「앱 업데이트」로 설치하면 이 문제는 생기지 않는다.)

## 2. 배포 흐름

- `master`(또는 기본 브랜치) 푸시 → GitHub Actions(`.github/workflows/release.yml`)가
  서명된 APK와 `latest.json`을 `latest` 릴리스에 올린다.
- **빌드 번호 = 워크플로 실행 번호**(`--build-number=${{ github.run_number }}`).
  앱은 자기 빌드 번호와 `latest.json`의 `build`를 견주어 새 빌드를 판단한다.
  로컬 `flutter build apk`로 만든 APK는 pubspec의 작은 번호를 써서 앱이 늘 "새 빌드 있음"으로 보인다 — 정상.
- `**.md`만 고친 푸시는 빌드하지 않는다(`paths-ignore`). 헛된 업데이트 알림 방지.
- **폰 업데이트**: 앱 → 설정(프로필) 화면 → **「앱 업데이트」** → 내려받아 설치. 케이블·adb 불필요.
  첫 설치 때 「출처를 알 수 없는 앱 설치」 허용이 한 번 필요하다(안드로이드 강제).

관련 파일: `lib/services/update_service.dart`, `lib/screens/update_screen.dart`,
`android/app/src/main/kotlin/**/MainActivity.kt`(설치 메서드 채널),
`android/app/src/main/res/xml/file_paths.xml`, `.github/workflows/release.yml`

구현 안내서: https://github.com/talkverselab/talkverse-th/blob/master/docs/in-app-update-via-github.md

## 2-1. iOS (아이폰) — TestFlight 배포

안드로이드의 「푸시 → APK → 앱 내 업데이트」에 해당하는 iOS 경로. 맥 없이 GitHub macOS 러너만 쓴다.
절차·시크릿 목록은 `docs/ios-build-and-testflight.md`.

- `.github/workflows/ios-build.yml` — 무서명 빌드(계정 없이 컴파일 확인). `lib/ ios/ assets/ pubspec` 변경 푸시마다 돈다.
- `.github/workflows/ios-testflight.yml` — 서명 + TestFlight 업로드. 리포 Variables `IOS_TESTFLIGHT_ENABLED=true` 여야 돈다.
  시크릿 6개(`ASC_KEY_ID` `ASC_ISSUER_ID` `ASC_KEY_P8_BASE64` `IOS_DIST_P12_BASE64` `IOS_DIST_P12_PASSWORD` `APPLE_TEAM_ID`).
- 번들 ID `com.talkverse.chineseUniverse`, 홈 화면 이름 「중국어유니버스」(`ios/Runner/Info.plist`).
- **배포 인증서는 팀에 하나** — 다른 앱(th 등)에서 이미 만든 `dist.p12` 를 그대로 쓴다. 새로 만들면 계정 한도(2~3개)에 걸린다.
- iOS 빌드 번호도 `github.run_number`. 아이폰의 「앱 업데이트」 타일은 안내만 하고(APK 설치 불가) TestFlight 가 업데이트를 맡는다.

## 2-2. 갤럭시·아이폰 공통 화면 규칙 (`lib/core/platform_ui.dart`)

- 세로 고정, 글자 배율 0.85~1.15 로 고정(두 폰의 큰 글씨 설정 차이 흡수), 밝은 배경 상태 표시줄은 어두운 아이콘.
- 밀어서 여는 화면(pushed route)의 `Scaffold.body` 는 `SafeArea(top: false, …)` 로 감싼다 — 아이폰 홈 표시줄과
  갤럭시 제스처 바(Android 15+ 는 강제 edge-to-edge) 아래로 버튼이 깔리지 않게. 새 화면을 만들 때도 같게.
- 아이폰 TTS 는 `setSharedInstance` + `playback` 카테고리(`tts_service.dart`) — 무음 스위치가 켜져 있어도 들리게.

## 3. 리포

- 이름은 **`talkverselab/talkverse-<언어코드>`** 로 통일(2026-09-10). 옛 이름(`zh-universe` 등)은 리다이렉트되지만
  remote는 새 이름으로 바꿔 둘 것: `git remote set-url origin https://github.com/talkverselab/talkverse-zh.git`
- **공개(PUBLIC) 저장소**다. 앱이 토큰 없이 APK를 받으려면 공개여야 한다.
- 다운로드 허브: https://github.com/talkverselab/talkverse-releases

## 4. 공개 저장소라서 지킬 것

- **출처를 드러내지 말 것.** 자막·말뭉치 제공처 이름(스트리밍 서비스, 공개 자막 데이터셋 등), 책 이름·쪽수,
  드라마·영화 제목을 코드·에셋·문서·파일명·화면 문구 어디에도 남기지 않는다.
- 저작권 있는 원문(자막 대본, 원서 전사)을 리포에 넣지 않는다. 단어·빈도 통계만 쓰고 문장은 자체 제작한다.
- 새 파일을 추가할 때 위 두 가지를 먼저 확인할 것. 한 번 공개 커밋되면 히스토리에 남는다.

## 5. 표시 언어 (한국어 / English / 日本語 / 中文) — 2026-09-12

- 프로필 · 설정 → 「언어 / Language」 를 탭할 때마다 한국어 → English → 日本語 → 中文 순으로 바뀐다.
  `AppLangPrefs`(`lib/core/l10n.dart`)가 값을 들고 있고, 바뀌면 `main.dart` 의 `MaterialApp` key 가 바뀌어
  앱 전체가 새로 그려진다(홈으로 돌아감).
- **UI 문구는 `tr('한국어')` / `trf('{0}개', [n])` 로 감싼다.** 번역은 `lib/core/l10n_dict.dart` 의
  `kDictEn` / `kDictJa` / `kDictZh` 에서 찾고, 없으면 한국어가 그대로 나온다.
  새 문구를 추가하면 세 사전에 한 줄씩 넣을 것. 키는 코드의 한국어 문자열 그대로(보간은 `{0},{1}` 템플릿).
- `tr()` 은 const 가 아니다 — `const Text(tr(...))` 처럼 쓰면 컴파일 오류. 그 위젯의 `const` 를 뺀다.
  enum 생성자·`static const`·`case` 패턴에는 못 쓴다(한국어를 두고 getter 에서 `tr()`).
- **회화·단어·문법 콘텐츠(뜻·번역·설명)는 번역 대상이 아니다** — 화면 문구(메뉴·버튼·안내)만 바뀐다.
- 사전은 이 앱 전용(`_update_kit/l10n/dict_zh_app.dart` 원본).

