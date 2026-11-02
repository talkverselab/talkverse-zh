# 회화(다이얼로그) 규칙 — 중국어유니버스

공통 원칙(19개 언어앱 공용, 2026-11-02 사용자 확정): **https://talkverse.uk/talkverse/dialogue-rules/**
절벽 기준표: https://talkverse.uk/cliff/18/
회화를 만들거나 고칠 때는 위 원칙을 따르고, 이 문서에는 중국어만의 특이점만 둔다.

## 중국어 특이점

- **기본 변이 = 북방 보통화·간체자** (`assets/data/dialogues/north/`). 대만 국어·번체자는 `south/`(별도 파일, 현재 L1 초안만·앱 미사용). 턴 안에 병기하지 않는다.
- **성별판 없음** — 중국어는 화자 성별로 말이 바뀌지 않으므로 한 판.
- **읽기 표기**: 모든 턴에 한글 독음 `rd` 필수(공통 원칙 §7). 병음(`pinyin`, 성조 부호)은 보조. 독음은 병음에서 규칙 변환한다 — 표기표·변환기 = `lib/services/ko_reading.dart`(병음 음절 → 한글), 성조 번호 변환 = `lib/services/pinyin_util.dart`. 인명은 병음 붙여쓰기, 경성은 성조 부호 없이.
- **턴 길이**(검사기 기준, 한자 수): R1 2~10자(1단어 단답 금지) · R2 ≤15자 · R3·R4 ≤22자. 문장부호는 전각(，。？！).
- **구간 어휘**: 회화 어휘는 그 구간까지의 누적 단어 목록 안에서(`assets/data/freq/FINAL_wordset_for_conversation_app.tsv` 의 순위·`region`). 한자는 구간 단어에 든 글자만 — 초기 회화는 한자 209 세트(`hanzi_stages.json`) 안에서 시작.
- **기존 데이터 재태그**: 지금의 L1~L4(`north/L1~L4.json`, 129편 8턴)는 서사 기준이라 R 과 1:1 이 아니다. 어휘 상한으로 R 을 산정해 `region` 태그를 붙이고, 턴 수는 R 기준(R1 6~8 · R2 8~12 · R3·R4 12~16)으로 다시 맞춘다. 연애 서사(L1·L3·L4)는 `domain: love` 로 살린다.
- **스키마**(앱 저장 형식 유지, 공용 내보내기는 변환기): `{num, speaker A|B, zh, pinyin, rd, ko, note, tags[], twist, flags[]}` + 편 메타 `{purpose[], domain[], region, scene, variant: north|south}`.
- 공개 저장소 — 출처명·원문 문장 금지는 `CLAUDE.md` §4.
