# 스토어 설명·심사 메모·스크린샷 — 중국어유니버스 (애플 지침 4.3 대비, 2026-11-09)

기준: `~/talkverse/STORE_DIFFERENTIATION.md`. 같은 개발자의 언어앱이 "같은 틀"로 보이면 4.3(스팸)으로 반려될 수 있으므로, 중국어에만 있는 벽과 도구·실측 숫자를 앞에 둔다. 숫자는 2026-11-09 앱·DB 실측.

## 실측 숫자
| 항목 | 값 | 출처 |
|---|---|---|
| 회화 | 220편 · 1,723턴(R1 91 · R3 27 · R4 101 · R2 1) | `assets/data/dialogues/R*` |
| 회화 음성 | 3,444줄 · 약 105분, 남성/여성 학습자판 두 벌, 장면마다 감정 16종 | `/art/zh/audio/manifest` |
| 장면 그림 | 549장(여성 학습자판 포함) | `/art/zh/scene/manifest` |
| 단어 그림 | 1,327장 | `/art/zh/manifest` |
| 한자 절벽 | R1 96자 = 대사 한자의 55% · R4 411자 = 80% · 2,000자 = 98.4% | `data/cliff/zh_cliff_summary.json`(중국어 영화·드라마 자막 15,160편 — 영화 9,200·드라마 5,960) |
| 회화 시작점 한자 | 209자 | `hanzi_stages.json` |
| 절벽 단어 | 2,500어(R1 433 · R2 616 · R3 1,238 · R4 2,500) + 회화 단어 455 | DB `words` · `conv_words_zh.json` |
| 병음 | 성모 21 · 운모 36 · 4성+경성, 글자마다 IPA·소리 나는 곳·한국어 비교 | `pinyin_phonetics.dart` |
| HSK | 단어 HSK1~5 4,240 · 한자 1,500 | `hsk_words.json` · `hanzi_hsk1500.json` |

## 스토어 설명(한국어) — 첫 줄이 가장 중요
> **중국어는 한자 96자만 알아도 드라마 대사 한자의 절반이 읽힙니다 — 중국어유니버스는 한국인이 이미 아는 한자음으로 그 절벽을 먼저 넘게 합니다.**

**중국어에만 있는 학습 도구**
- **한자 절벽 R1~R5**: 중국어 영화·드라마 자막 1억 2천만 글자를 세어, 96자(55%) → 411자(80%) → 2,000자(98.4%) 순서로 배웁니다. 20자 단원, 4지선다.
- **발음부 × 한국 한자음**: 같은 소리 부품을 가진 한자를 가족으로 묶고, 한국 한자음과 병음을 나란히 — 「青·清·情·晴」을 한 번에.
- **4성 색 · 성조 연습**: 1~4성을 색으로 구분하는 4성 매트릭스, 내 목소리 음높이를 그려 주는 성조 연습.
- **병음과 발음**: 성모 21·운모 36·성조를 표로, 글자마다 IPA·소리 나는 곳·「한국어 ㅉ과 무엇이 다른지」.
- **회화 220편 + 원어민 감정 음성**: 채팅·연애·여행·생활의 짧은 반전 회화, 남성/여성 학습자판 음성 3,444줄. 문장을 단어 단위로 누르면 뜻, 길게 누르면 한자.

**숫자로**: 회화 220편 · 음성 105분 · 장면 그림 549장 · 단어 그림 1,327장 · 절벽 단어 2,500 · HSK 1~5급.

공통: Talkverse 계정 하나로 아이폰·아이패드·안드로이드(로그인은 선택), 받아 둔 그림·음성은 오프라인, 결제는 App Store.

## 심사 메모(App Review Notes)
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Chinese app has its own script & pronunciation module (Pinyin: 21 initials, 36 finals, 4 tones + neutral tone, each with IPA, place of articulation and a comparison with Korean sounds; a tone-color matrix and a pitch-tracking tone trainer), its own character tools (a frequency "cliff" of Chinese characters measured from 121 million characters of Chinese film & drama subtitles — 96 characters cover 55%, 411 cover 80% — and phonetic-component families linked to Korean Sino-Korean readings), 220 original conversation episodes with 3,444 recorded audio lines written for this language, and a vocabulary list measured from a Chinese conversation corpus (2,500-word cliff, HSK 1–5). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.
>
> Paid items are optional (1 month / 3 months / 1 year auto-renewing subscriptions, lifetime, and an all-languages bundle); at launch all content is unlocked. Restore Purchases: Profile → Account → Restore purchases. Sign in is optional; a demo email account can be provided on request.

## 스크린샷 순서(첫 두 장은 중국어 고유 화면)
1. 한자 배우기 → **절벽 한자 R1~R5**(구간 표 + 20자 단원)
2. **병음과 발음** 성모 격자 + 발음 시트(IPA·소리 나는 곳·한국어 비교)
3. 회화 재생(장면 그림 + 레마 밑줄 + 단어창)
4. **4성 매트릭스** 또는 성조 연습(음높이 곡선)
5. 발음부 가족(青 가족 + 한국 한자음)
6. 절벽 단어 타일(20어 단원)
- 홈·프로필로 시작하지 않는다. 캡처는 출시 후보 빌드에서(준비 중 줄 제거 뒤).
