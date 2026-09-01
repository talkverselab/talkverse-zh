# chinese_universe 최근 변경 이식 가이드 (2026-08-08 ~ 09-01)

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

### 1-3. co-Trip 여행 어휘 → 주제별 단어·표현 (3551201, b6a33f1)
- 원본: 여행 표현집 MD (|한국어|대상어|독음| 표) → 파서로 두 자산 생성
  - `assets/data/vocab/travel_words.json` — 12테마 1,446단어 (단어성 섹션)
  - `assets/data/vocab/travel_expressions.json` — 11테마 691표현 (문장성 섹션, 첫 테마 '필수 표현')
- 분류 규칙: 섹션 제목 키워드(LOOK/단어/지명…) 우선, 아니면 평균 글자수(≤4.5=단어)
- 스키마: `{themes:[{id,title,emoji,sections:[{title,words:[{ko,zh,rd}]}]}]}`

### 1-4. 한자(문자) 메타 데이터 — 한자권 언어만 해당
- `hanzi_ko.json`: HSK1-5 1,499자 한국 훈음 (计=셀 계) (6f873da)
- `phonetic_ext.json`: 발음부(声旁) 169계열·516자 자동판정+검증 (4b2af15)
- 비한자권(vi/th/ko 앱)은 해당 없음 — 대신 어근/성조 데이터로 대체 검토

---

## 2. 화면·기능

### 2-1. 홈 메뉴 구조 (b6a33f1, f3f7bf5)
- 마스코트 캐릭터 제거 (위젯+감정 이미지 자산 삭제)
- 메뉴: 회화 / **문법(레벨 선택 통합 메뉴)** / **한자**(구 '한자 209') / **단어** / **표현(Expression)** / 발음 / 발음부 / 복습
- 단어 = 주제 그리드 → (세부분류 없이) 바로 단어 목록 + '회화 핵심어휘'(빈도 wordset) 테마 흡수
- 표현 = 같은 UI, expressions 자산 (`TopicVocabScreen(asset:…, title:…)` 파라미터화)
- 기존 '단어(빈도표)'·'회화 어휘' 화면은 삭제

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
6. [ ] TTS speakAs 도입 + 대사 화자 성별 매핑
7. [ ] 진행 탭 실데이터화 — `progress_screen.dart`
8. [ ] CI 릴리스 파이프라인 복사 + 앱별 서명 키 Secrets
