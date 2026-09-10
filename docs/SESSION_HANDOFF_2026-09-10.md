---
name: session-handoff-2026-09-10
description: 2026-09-10 세션 교체 인수인계 — 새 세션이 첫 턴에 읽을 zh 현황·핵심 파일·명령·금지 사항 요약
metadata:
  type: project
  originSessionId: 0f30ac9b-148d-43f6-97b2-e93497af23d0
  modified: 2026-09-10T11:06:14.113Z
---

# 세션 인수인계 (2026-09-10)

이전 세션(0f30ac9b, 6월 27일~9월 10일)을 닫고 새 세션으로 교체함. 같은 폴더의 다른 세션 파일은 사용자 지시로 모두 삭제됨.

## 1. 현재 상태
- 작업 폴더 `C:\Users\Johnjeon\talkverse\zh` (chinese_universe, 빨간 테마, zh 정본)
- git master `d808b1e` 푸시 완료, 작업 트리 깨끗함, Galaxy S25(`R3CY20HDN2K`) 설치 완료
- **대기 항목 없음.** 사용자 지시 없이는 착수하지 말 것 (후속 후보는 [[pending-app-changes]] 참고)

## 2. 최근 반영 기능 (9월 8일, 커밋 5개)
| 커밋 | 내용 | 핵심 파일 |
|---|---|---|
| b88ca95 | 말하기 연습 v1 (한국어 보고 중국어 말하기, 10s/5s/2s) | `lib/services/speech_service.dart`, `speak_match.dart` |
| 3892514 | HSK 1~5급 단어 4,240 + 한자 1,500 (5단계) · 병음 성조 표기 통일 | `assets/data/vocab/hsk_words.json`, `assets/data/hanzi/hanzi_hsk1500.json`, `lib/screens/hanzi_stages_screen.dart` |
| 2355b80 | 발음 메뉴 → 성조연습 (YIN 피치 → 4성 판정) | `lib/services/tone_analyzer.dart`, `lib/screens/tone_practice_screen.dart` |
| 0acca91 | 모든 회화 8턴 통일 (129편 × 8턴, DB 시드 v7) | `assets/data/dialogues/north/L1~L3.json`, `tool/split_dialogues_8.py` |
| d808b1e | 말하기 연습 v2 (학습한 회화 목록 → 탭 즉시 테스트, 4문장마다 계속) | `lib/screens/speaking_practice_screen.dart` |

상세 설계·이식 절차: `docs/PORTING_GUIDE_2026-09.md` 1-5, 1-6, 2-1d, 2-1e.

## 3. 사용자 피드백 대기 중 (기기 미검증)
- 말하기 판정: `lib/services/speak_match.dart` threshold 0.7, 미리보기 1.2s / 결과 표시 0.9s (`speaking_practice_screen.dart`)
- 성조 판정: `lib/services/tone_analyzer.dart` 템플릿 4종, span 최소 4반음, 1성 범위 벌점 1.6
- 합성 테스트만 통과(`test/speak_match_test.dart` 7, `test/tone_analyzer_test.dart` 5). "안 잡힌다/너무 쉽다" 피드백 오면 이 숫자부터 조정.

## 4. 미검수 생성 콘텐츠
- HSK 단어 한국어 뜻·아이콘 4,037개 (`hsk_words.json`) — sonnet 에이전트 14개 생성
- L2/L3 이어쓴 회화 137턴 (`tags:["ext"]`) — 필요 시 태그로 일괄 제거 가능
- 지적받은 항목만 고치면 됨.

## 5. 자주 쓰는 명령
```
# 설치 (adb PATH 미등록)
flutter build apk --release
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" -s R3CY20HDN2K install -r build\app\outputs\flutter-apk\app-release.apk

# 테스트
flutter test

# gh 계정 확인
gh auth switch --user talkverselab
```
- Python 스크립트는 `tool/` (pypinyin·jieba 설치됨). 한국어 출력은 `PYTHONIOENCODING=utf-8`.
- Dart 파일 작성은 Write 도구 사용 (Bash heredoc은 한글·인용 깨짐).

## 6. 금지·규칙
- **th·en·ko 폴더 절대 손대지 말 것.**
- 17개 앱 런처 아이콘 모양 모두 달라야 함.
- 릴리스 배치 빌드는 순차 1개씩 (병렬 Gradle 충돌).
- 수정 요청은 코드+로컬 커밋+메모, 빌드·설치·푸시는 "반영해줘/설치해줘/푸쉬" 지시에.

관련: [[pending-app-changes]], [[talkverse-sibling-apps]], [[chinese-universe-red-app]]
