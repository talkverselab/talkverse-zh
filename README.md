# 중국어유니버스 (ChineseUniverse)

> 한국 화자 대상 중국어 단일 앱. Flutter SDK 로 처음부터 재작성.
> 앱 이름: **중국어유니버스**
> Package: `com.talkverse.zh` (또는 `com.chineseuniverse.app` — 결정 필요)
> Stack: **Flutter** (Material 3) + **Drift** (SQLite). Brand: `#DE2910`.
> Git: **local only** (GitHub 사용 X).

모든 메모: `D:/OneDrive/memo/zh/`

---

## 한 페이지 요약

zh = 고립어. 학습 3축 = **(1) 한자 인지 / (2) 4성+경성 / (3) SVO 어순 + 허사**.

**한자 cliff** (차별화 IP)
- Phase 1 한자 100 → 79% 청취
- Phase 2 한자 209/216 → **89% 청취 + 표현 시작** ⭐ 회화 시작점
- Phase 3 한자 300 → 94% (HSK1)
- Phase 4 한자 387 → 95%
- 자유 회화 단어 727+ / 한자 824+

**단어 cliff** (jieba 토큰) — R1=433 / R2=616 / R3=1238 / R4=2500, Top1k = 59.9%

---

## 진입

```powershell
cd D:\OneDrive\talkverse\zh
claude
```

빌드:
```powershell
flutter pub get
flutter run                                  # 개발 (실기기)
flutter build apk --release                  # release APK
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 폴더

| 위치 | 내용 |
|---|---|
| `lib/main.dart` | 앱 진입점 |
| `lib/core/` | theme(#DE2910), constants, util |
| `lib/data/db/` | **Drift** SQLite schema + DAO (옛 DB 재사용) |
| `lib/data/repositories/` | DialogueRepository, HanziRepository, AnnotationRepository |
| `lib/domain/models/` | Turn, Hanzi, PhoneticRoot, Annotation 등 |
| `lib/screens/` | MainScreen, ConversationScreen, ToneMatrixScreen, HanziCardsScreen, ProfileScreen 등 |
| `lib/widgets/` | AnnotatedText, AnnotationEditor, MemoButton, ToneBadge, HanziCard, TalkyMascot |
| `lib/services/` | AudioPlayer, TTS, UserMemo, AnnotationOverride |
| `assets/data/dialogues/` | L1/L2/L3.json + _meta.json (JSON SOT) |
| `assets/data/hanzi/` | core_209 / hsk_1500 / phonetic_roots_200 / tone_matrix_160 / hanzi_clusters |
| `assets/data/wordsets/` | lang_zh_top2500.csv |
| `assets/data/annotations/` | 빨간펜 자동 추출 JSON |
| `assets/data/db/` | **seed_zh.sql** (Drift seed — 옛 빌드 DB) |
| `assets/audio/{L1,L2,L3,hanzi,tone_matrix}/` | mp3 (.gitignore) |
| `assets/images/` | icon, splash, illustrations |
| `data/` | raw corpus + python scripts + 리포트 (.gitignore) |
| `legacy/` | 옛 빌드 자산 (flutter dart, 노트북 ep1-6, Edge TTS 565 mp3) |
| `test/` | 단위 테스트 |
| `android/` `ios/` | `flutter create` 자동 생성 |
| `pubspec.yaml` | dependencies |

---

## 콘텐츠 schema (v4)

```
L1: 5 ep × 40 turn = 200 turn         매칭 narrative
L2: 23 dial × 5 block ≈ 300 turn      카오스 채팅
L3: 23 dial × 5 block ≈ 304 turn      사랑 narrative
L4: TBD
L5·L6: 폐지
```

Turn JSON:
```json
{
  "num": 1, "speaker": "A",
  "zh": "你好，我叫马克。",
  "pinyin": "Nǐ hǎo, wǒ jiào Mǎkè.",
  "ko": "안녕하세요, 저는 마크예요.",
  "tones": "3-3 3-4 . 3-4 . 4-4 . 3-4",
  "note": "어기조사 啊 / SVO",
  "tags": ["greeting", "particle:啊"]
}
```

---

## 핵심 IP

- **한자 발음부 + 한국 한자음 매핑**: 현대 상용 한자 90% 형성자. L1 80자 실측 한국 한자음↔중국 발음 초성 정합 87.5%. 발음부 200 → HSK1-5 1500자 풀이 (압축률 7.5×)
- **빨간펜 시스템**: AnnotatedText + AnnotationEditor + MemoButton, 자동 추출 (어기조사·양사·把字句·被字句·是…的 rule-based)
- **4성+경성 시각화** (1성=빨/2성=주/3성=초/4성=파/경성=회), tone_matrix 16×10 = 160 단어 별트랙

---

## 옛 DB 재사용

옛 Flutter 빌드의 Drift schema + seed_zh.sql 재사용. 다음 phase 로 가져옴:

| Phase | 출처 | 대상 |
|---|---|---|
| A | `D:/OneDrive/PROJECT/talkverse-lab/zh/north/dialogues/*.json` | `assets/data/dialogues/` |
| B | `apps/zh-lab/assets/conv200_north.json` + `chat_dialogues_north.json` | `assets/data/dialogues/` |
| C | github `talkverse-learning-flavors` (refactor/th-flavor-init): hsk_full_1500 / phonetic_roots_200 / core_hanzi_209 / tone_matrix_160 / hanzi_clusters / l1_10day | `assets/data/hanzi/` |
| D | BOOKS/_assets/data/lang_zh_top2500.csv | `assets/data/wordsets/` |
| E | DATA_Raw/languages/zh/ (LCCC, opensubtitles, kuroneko5943) | `data/corpus/` (.gitignore) |
| F | seed_zh.sql (옛 노트북 빌드 Drift seed) | `assets/data/db/` |

---

## 미결 (`memo/zh/decisions/` 에 결정 로그)

1. dialect 분리 (simp 1-way / simp+trad 2-way / 3-way) — 기본 simp 만 추천
2. 옛 ep1-6 240 라인 통합 방식
3. L4 정의
4. Lily ↔ 小丽 naming 통일
5. TTS 정책 (Edge TTS dev → MiniMax 海螺 release)

---

## 메모 (SOT)

`D:/OneDrive/memo/zh/` 안에 모두 위치:
- `HANDOFF.md` — 룸 진입 + DB 이전 계획
- `architecture.md` — Flutter 코드 구조 + Drift schema
- `content-plan.md` — L1·L2·L3 콘텐츠 로드맵
- `build.md` — 빌드 가이드
- `decisions/` — 결정 로그
