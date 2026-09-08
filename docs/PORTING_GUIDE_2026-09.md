# chinese_universe 최근 변경 이식 가이드 (2026-08-08 ~ 09-02)

다른 언어 앱(vietnamese_universe / thai_universe / k_universe)에 같은 기능을 적용하기 위한 요약.
언어 중립적인 구조 변경 중심으로 정리 — 커밋 해시는 이 저장소(chinese-universe) 기준.

---

## 1. 콘텐츠 데이터

### 1-1. 대화 레벨 체계 L1~L4 (커밋 ab01e5a, 7d1c272, b6a33f1)
- `assets/data/dialogues/north/L{1..4}.json`
  - L1: 스토리 5에피소드×40턴 (`episodes` 키) — 남녀 주인공 내러티브
  - L2: 일상 카오스 챗 23편×13턴 (`dialogues` 키)
  - L3: 사랑 내러티브 3막 23편 (`dialogues` 키)
  - **L4: 플러팅 12편×8턴 — 여자(B)가 남자(A)에게 먼저 다가가는 상황** (클럽·바·길거리 등)
- 턴 스키마: `{num, speaker: A|B, zh(→대상어), pinyin(→발음표기), ko, note(문법 포인트), tags[]}`
- 레벨 목록은 `EpisodeCatalog.levels` 상수 한 곳에서 관리 (`lib/screens/episode_screen.dart`)
- 시드: `SeedLoader._seedTurns()`가 레벨 루프로 DB `turns` 적재, 버전 키(`db_seeded_vN`) 범프 시 재시딩

### 1-2. 대화문 품질 검수 절차 (3b5dcb0)
- 5-way 병렬 검수(논리·난이도·자연스러움·오류) → 판정 → 패치 적용 스크립트
- 문장부호 전각 통일(，？！), 병음-표기 일관성(인명 붙여쓰기, 경성 표기)
- 이식 팁: 검수 기준표 = ①레벨 목표 난이도 초과 어휘 ②번역투 ③대화 내 수치·장소 모순

### 1-3. co-Trip 여행 어휘 → 주제별 단어·표현 (3551201, b6a33f1, e51d15c, 2e5c48f)
- 원본: 여행 표현집 MD (|한국어|대상어|독음| 표) → 파서(`tool/parse_cotrip.py`)로 두 자산 생성
  - `assets/data/vocab/travel_words.json` — 11테마 1,065단어 (단어성 섹션)
  - `assets/data/vocab/travel_expressions.json` — 11테마 1,053표현 (문장성 섹션, 첫 테마 '필수 표현')
- 분류 규칙: 섹션 제목 키워드(LOOK/단어/지명…) 우선, 아니면 문장부호 비율 <30% AND 평균 글자수 ≤4.5 = 단어; `~` 템플릿·칼럼 항목은 표현으로
- 스키마: `{themes:[{id,title,emoji,sections:[{title,words:[{ko,zh,rd,ic}]}]}]}` — `ic`는 단어별 아이콘 이모지
- **후속 정리 (2e5c48f, `tool/fix_vocab_20260902.py`) — 이식 시 같은 규칙 적용:**
  - 연예인 등 인명 고유명사 섹션 삭제
  - 문형 채우기 명사(커피·홍차 등 "~주세요" 슬롯 단어)는 단어 메뉴에서 빼서 표현 메뉴의 해당 문형 섹션 바로 뒤로 병합 (단어 메뉴의 '인사·기본 표현' 테마 자체를 제거)
  - **섹션 내 중복 아이콘 차별화**: 요리형태 키워드(죽🥣/그라탕🧀/완자🍢/튀김🍤…) 우선 오버라이드 → 그래도 겹치면 기준 이모지별 변형 풀(🥟→🥠🫓🍡…, 🍵→🫖🍶…, 🦀→🥣🧀🍢…)에서 섹션 내 미사용 이모지 배정, 숫자 단어는 키캡(1️⃣2️⃣…🔟💯)

### 1-4. 한자(문자) 메타 데이터 — 한자권 언어만 해당
- `hanzi_ko.json`: HSK1-5 1,499자 한국 훈음 (计=셀 계) (6f873da)
- `phonetic_ext.json`: 발음부(声旁) 169계열·516자 자동판정+검증 (4b2af15)
- 비한자권(vi/th/ko 앱)은 해당 없음 — 대신 어근/성조 데이터로 대체 검토

---

### 1-5. HSK 1~5급 단어 4,240 + 한자 1,500 (09-08)
- 단어: `complete-hsk-vocabulary`(MIT, HSK 3.0 `new-1..5`) → `tool/build_hsk_words.py` → `assets/data/vocab/hsk_words.json`. 테마=급수, 섹션=빈도순 50개. 한국어 뜻·아이콘은 에이전트 생성(배치 300개, `ko`·`ic`), 앱 기존 여행 어휘 ko 우선.
- 한자: HSK 3.0 급별 300자 × 5 = 1,500 (`hanzi_score_final.tsv` hsk_char_level + `hanzi_ko.json` 훈음). `tool/build_hsk1500.py` → `hanzi_hsk1500.json`: 회화 빈도순 5단계(300자) × 20자 소단계 75개, `phases[]`에 누적 커버율.
- 빈도 절벽: 회화 코퍼스 커버율은 107자 80% · 206자 90% · 359자 95% · 517자 97% · 682자 98% 이후 1,500자까지 완만한 꼬리(급격한 절벽 없음). 그래서 5단계는 등분(300자)으로 두고 커버율만 표기.
- 화면: `HanziHubScreen`(209 / 1500 선택) → `HanziStagesScreen(asset, seal, kicker)`; `phases` 있으면 큰 단계 접기/펼치기. 단어는 `TopicVocabScreen(extraAssets: [...])`.

### 1-6. 회화 8턴 통일 (09-08, `tool/split_dialogues_8.py`)
- 모든 회화 = 8턴. L1 40턴 에피소드 → 8턴 × 5 (`ep1_1`~, 제목 '매칭 ①'). L2/L3 13턴 → ① 1~8, ② 9~13 + 이어쓰기 3턴(에이전트, `tags:["ext"]`, 병음 pypinyin+jieba). L4는 원래 8턴.
- 분할 단위마다 `parent` 필드로 원본 id 보존. DB 시드 키 `db_seeded_v7`로 재시딩.
- 결과: L1 25편 · L2 46편 · L3 46편 · L4 12편 = 129편 1,032턴.

## 2. 화면·기능

### 2-1. 홈 메뉴 구조 (b6a33f1, f3f7bf5)
- 마스코트 캐릭터 제거 (위젯+감정 이미지 자산 삭제)
- 메뉴: 회화 / **문법(레벨 선택 통합 메뉴)** / **한자**(구 '한자 209') / **단어** / **표현(Expression)** / 발음 / 발음부 / 복습
- 단어 = 주제 그리드 → (세부분류 없이) **3열 1×1 아이콘 타일 그리드** (이모지 `ic` + 대상어 + 독음 + 뜻, 탭=TTS+상세 시트) + '회화 핵심어휘'(빈도 wordset) 테마 흡수
- 표현 = 같은 UI, expressions 자산 (`TopicVocabScreen(asset:…, title:…)` 파라미터화, 목록형 행)
- 기존 '단어(빈도표)'·'회화 어휘' 화면은 삭제

### 2-1b. 단어 외우기 모드 (2e5c48f)
- `lib/screens/topic_vocab_screen.dart` — 주제 상세 앱바에 모드 버튼: **전체 → 한자가림 → 뜻가림** 순환 (`enum StudyMode { all, hideZh, hideKo }`)
- 가려진 부분은 `???` 표시, 타일/행 탭 → 공개 + TTS 재생 (모드 전환 시 `ValueKey('${mode.name}_$zh_$i')`로 공개상태 리셋)
- **외운 단어 체크**: `MemorizedStore` — SharedPreferences StringList(`memorized_words`, 대상어 키) + `ValueNotifier` 버전으로 전 위젯 동기화. 외우기 모드에서 타일마다 체크 버튼, 외운 타일은 배경·테두리 강조, 앱바에 'N단어 · 외움 n' 카운트
- 그리드 타일(`_WordTile`)·목록 행(`_WordRow`) 모두 동일 로직 — 언어 중립, 그대로 복사 가능

### 2-1c. 발음 한글표기(독음) 전역 토글 (2e5c48f)
- **비한자권 포함 모든 앱에 동일 패턴 적용 가능** — 로마자 발음표기 → 모국어(한글) 표기 자동 변환 + 전역 on/off
- `lib/services/pinyin_hangul_map.dart` — 병음(성조 제거) 838음절 → 한글 표. 생성 스크립트는 초성 치환 + 유니코드 자모 합성 (다른 언어: 해당 언어 음절표로 교체 — vi/th는 로마자→한글 표기표, ko 앱은 불필요)
- `lib/services/ko_reading.dart`:
  - `KoReading.convert(pinyin)` — 성조 마크·숫자 성조(ni3) 제거 → 공백/어포스트로피 단위 → 최장일치 음절 분절 → 한글 조합. 문장부호는 통과
  - `KoReadingPrefs` — `ValueNotifier<bool>` + SharedPreferences(`show_ko_reading`), 앱 시작 시 `load()` (main.dart)
  - `KoReadingToggleAction` — 앱바용 [한] 토글 버튼 (켜짐=테두리·흰색, 꺼짐=취소선)
  - `KoReadingText(pinyin)` — 발음표기 아래 붙이는 독음 텍스트, off면 SizedBox.shrink
- 적용 위치(전 메뉴): 에피소드 버블, LCCC 회화 버블, 문장 플래시카드(앞면 힌트 포함), 청크 검색 문장, 문법 예문·문법 테스트 카드, 단어·표현 타일/행/상세 시트(책 독음 `rd`는 토글로 숨김, 병음 폴백이면 병음+독음 병기), 한자 시트·청크 시트
- 이식 순서: 음절표 생성 → ko_reading.dart 복사 → 각 화면 발음표기 Text 아래 `KoReadingText` 1줄 + 앱바 actions에 `KoReadingToggleAction()` 추가

### 2-1d. 말하기 연습 (Speaking) — 한국어 보고 목표어 말하기
- 메뉴: 홈 `말하기` 타일 → `speaking_practice_screen.dart`. DB `turns`에서 2~N음절 문장 10개 랜덤 세션.
- 규칙: 한국어 문장 표시 → TEST 즉시 녹음 → 1단계 10초 / 2단계 5초 / 3단계 2초 안에 문장 전체를 말하면 PASS. 3단계 통과 시 다음 문장.
- 힌트(목표어 문장 + 발음) 토글 — `speak_show_hint` 저장. 발음 표기는 `KoReadingText`로 전역 독음 토글과 연동.
- 오픈소스: `speech_to_text` ^7.4 (BSD-3, Android SpeechRecognizer 스트리밍 partial) + `lpinyin` ^2.0 (MIT, 한자→무성조 병음). 오프라인 대안은 sherpa-onnx (Apache-2.0).
- 판정 `speak_match.dart`: 인식 한자→무성조 병음 음절 → 퍼지(zh/ch/sh→z/c/s, n·r→l, ing/eng→in/en) → 목표 대비 LCS ≥ 0.7 PASS(≤3음절은 전부). 성조·권설 무시 = "문장 전체" 기준.
- 속도: 부분 결과마다 즉시 판정해 맞으면 타이머 중 PASS. 시간 종료 시 `stop()` 후 최종 결과 최대 1.2초만 대기 → 인식 지연은 학습자 불이익 없음.
- 저장: `speak_best_<turnId>` = 통과 단계(1~3). 세션 끝에 ★ 요약.
- Android: `RECORD_AUDIO`·`INTERNET`·`BLUETOOTH_CONNECT` 권한 + `<queries>`에 `android.speech.RecognitionService`.
- 이식 시: 병음 변환부만 언어별 교체 (알파벳 언어는 소문자화+발음 퍼지, ja는 가나 정규화). 로케일 `_pickLocale` 선호 목록 수정.

### 2-1e. 성조 연습 (09-08)
- 메뉴 `성조연습`(声调) → `tone_practice_screen.dart`. 8개 음절 세트 × 4성, 듣기(TTS) → 따라 말하기 1.6초 녹음 → 곡선 비교 → PASS/FAIL.
- 오픈소스: `record` ^6 (BSD-3, PCM16 16kHz 스트림) + `pitch_detector_dart` ^0.0.7 (MIT, TarsosDSP YIN). 학습 모델 없음.
- 판정 `tone_analyzer.dart`: YIN f0(1024/256) → 가장 긴 유성 구간 → 반음 변환·중앙값 필터 → 화자 정규화(중앙값 ±span → Chao 1~5도) → 20점 리샘플 → 4성 템플릿(55/35/214/51) RMS 거리 최소. 1성은 범위 벌점.
- 합성 사인파 테스트 `test/tone_analyzer_test.dart` 4성 모두 통과. 실제 음성 임계값은 기기 검증 후 조정.
- 이식: 성조 언어(th·vi)는 템플릿만 교체, 비성조 언어는 미이식.

### 2-2. 에피소드 학습 화면 (ab01e5a, 6f3214a)
- 채팅 버블(화자별 색·아바타) + 병음 + 번역 + 💡문법노트 + 턴별 학습 체크(`user_progress`)
- **버블 탭 → 그 문장부터 플래시카드 진입** (`SentenceFlashcardScreen(initialIndex)`)

### 2-3. 문장 플래시카드 (feb0931, 74cb0d6, aa2696d)
- **기본: 모국어(한국어) 앞면 → 뒤집으면 대상어**, 방향 토글(한→中/中→한, SharedPreferences 저장)
- 앞면에 발음 힌트(💡병음) 표시 + 힌트 on/off 토글(저장)
- 이전/다음 자유 이동, 평가 3단계 **몰라요/공부중/알아요** (DB 매핑: known=learned, studying=reviewCount>0)
- 카드 테두리·칩으로 상태 표시, 문법노트는 정답 면에서만

### 2-4. 청크 검색 (9f64985)
- 전 문장 청크 역인덱스: 사전(최장일치) 분절, 한자·발음·모국어 3방향 검색
- 결과: 청크 카드 → 문장 목록(하이라이트·TTS) → 청크/문자 상세 시트 연쇄 탐색

### 2-5. 문자 정보 시트 연쇄 (6f873da, b6a33f1)
- 청크 시트: 모국어 뜻(여행 gloss 폴백) + 구성 문자마다 훈음·**발음부 배지**
- 배지/발음부 영역 탭 → **발음부 메뉴 화면으로 push** (`PhoneticRootsScreen(focusRoot, fromChar)`)
  - 진입 시 해당 계열 가족 시트 자동 오픈, from 문자 하이라이트, 뒤로가기로 원래 화면 복귀
- 가족 타일마다 🔊 (열지 않고 바로 발음)

### 2-6. TTS 화자별 음성 (feb0931, b6a33f1)
- `TtsService.speakAs(text, gender)`: 기기 보이스에서 male/female 탐색, 없으면 피치(남 0.6/여 1.15)
- 적용: 에피소드·LCCC 버블, 플래시카드, 청크 검색 문장(화자 정보 인덱스에 포함)

### 2-7. 진행 탭 실데이터 (7d1c272)
- 전체 진행률(learned/총턴), 완료 에피소드, 연속 학습(streak), 주간 활동, 레벨별 진행 바

---

## 3. 배포 파이프라인 (83b923b)
- GitHub Actions: master 푸시 → 서명 release APK 빌드 → GitHub Release 게시
- 서명 키는 Secrets(`ANDROID_KEYSTORE_BASE64` 등) → CI에서 `android/key.properties` 복원
- Gradle: `key.properties` 있으면 release 서명, 없으면 debug 폴백
- 폰 설치: `https://github.com/<owner>/<repo>/releases/latest`
- 워크플로 파일: `.github/workflows/android-release.yml` — 그대로 복사 후 Secrets만 등록

## 4. 운영 편의
- `claude-retry.cmd` (PATH의 bin): Claude Code 세션이 API 오류로 죽으면 90초 후 `--continue` 자동 재개

---

## 이식 체크리스트 (다른 앱 1개당)
1. [ ] 대화 JSON 스키마 통일 + `EpisodeCatalog.levels` 도입, 시드 버전 루프화
2. [ ] 플래시카드 화면 교체 (모국어 우선/힌트/3단계) — `sentence_flashcard_screen.dart` 이식
3. [ ] 에피소드 화면 + 버블→카드 점프 — `episode_screen.dart`
4. [ ] 청크(어휘) 검색 — 분절 사전을 해당 언어 사전으로 교체
5. [ ] 단어·표현 메뉴 (`topic_vocab_screen.dart`) + 해당 언어 여행 어휘 자산 생성
   - [ ] 단어별 아이콘(`ic`) 부여 + 섹션 내 중복 아이콘 차별화 (1-3 규칙)
   - [ ] 인명 고유명사 삭제 · 문형 채우기 명사는 표현 메뉴로 (1-3 규칙)
6. [ ] TTS speakAs 도입 + 대사 화자 성별 매핑
7. [ ] 진행 탭 실데이터화 — `progress_screen.dart`
8. [ ] CI 릴리스 파이프라인 복사 + 앱별 서명 키 Secrets
9. [ ] 발음 한글표기 전역 토글 — 해당 언어 음절표 생성 + `ko_reading.dart` 복사, 전 화면 `KoReadingText`/`KoReadingToggleAction` (2-1c)
10. [ ] 단어 외우기 모드 + `MemorizedStore` (2-1b) — 언어 중립, 그대로 복사
11. [ ] 말하기 연습 (2-1d) — `speech_service.dart`·`speak_match.dart`·`speaking_practice_screen.dart` 복사, 로케일·발음 정규화 교체, 매니페스트 권한
