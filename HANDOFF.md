# 중국어유니버스 — 인계 (2026-11-10 갱신, M6 디스크 정리 뒤 세션 종료)

규칙의 기준은 `CLAUDE.md`(서명·배포·공개 저장소). 이 파일은 지금 상태와 남은 일만. 옛 내용(2026-10-11 Zealot 설정 메모)은 모두 끝났거나 낡아서 지웠다.

## 지금 상태
- 마지막 앱 커밋 `7f2a34f`(master, 푸시됨). 최신 빌드: **Zealot 중국어유니버스 빌드 23** https://apps.talkverse.uk/vpiwj/462 · **TestFlight 2611111933**(11/11 성조연습 개편). PC `D:\OneDrive\app project\chinese-universe\` 백업.
- 배포 규칙: 고치면 push → CI APK → `ZEALOT_FROM_CI=1 tools/zealot_push.sh "<한 줄>"` + `bash tools/ios_release.sh`, 보고에 둘 다. 맥에는 업로드 키가 없다(CI 빌드만 덮어 설치됨). CI 가 러너 NDK 손상으로 실패하면 `gh run rerun <id> --failed`.
- 작업 트리의 `android/ ios/ assets/data/{north,south,hanzi/cliff...}` 수정 표시는 옛날부터 있던 줄바꿈 차이 — 커밋하지 말 것(내용 변경 없음).

## 2026-11-07~09 에 한 것(커밋 순)
- 일본어앱 개편 이식(§1~§4·§6): 한자 절벽 2,000자(R1 96·R2 129·R3 226·R4 411·R5 2,000, `HanziCliff.regionOf`)·절벽 단어 타일 화면·앱 소개·메뉴 정리·레마 탭 → 단어창·읽기 보조(병음·독음) 전역 토글 기본 꺼짐.
- 회화 음성: 앱 재생(`dialogue_audio.dart`, 매니페스트 `/art/zh/audio/manifest`) + **전편 220편 3,444줄(약 105분) D1·R2 반영**. 도구 `tools/tts/`(PC 출력 `out/ref_zh/`·`out/zh/` 만 — `out/ref/`·`out/<편>/` 금지). 감정 열(`emotion`/`segs`) 전편 1,723턴 → 계획 자동(`tools/tts/plan_from_episode.py`, `tools/set_emotions.py`).
- 어조사 턴 감정 이모지(`tools/add_particle_emoji.py`, 음성·TTS 는 안 읽음).
- 「병음과 발음」(성모 21·운모 36·성조, 배우기 기초 첫 칸). 조음 그림은 임시(출처 표기 없음 — 출시 전 Grok 그림으로 교체).
- 최종 가격표 결제(`lang_zh_1m·3m·1y·life`, `all_1y·all_life`, 정가 취소선·할인가), 약관·방침 링크, `docs/STORE_PRODUCTS.md`·`docs/STORE_LISTING.md`(4.3 대비 설명·심사 메모·스크린샷 순서).
- 통합 앱(Talkverse) 연결 `882a981`: `lib/embed.dart`(embedInit·embedApp), `assetPath`·`fontName`, 설정 키·폴더 `zh_`, clientId `talkverse`(통합 모드), `Purchase.ownStream`/`onPurchaseUpdates`, 「다른 언어 배우기」, drift 2.34.4·drift_flutter 0.3.1. 통합 앱 자체는 uk 가 붙인다(직접 고치지 말 것).

- **11/9 오후 회화 일상 원칙(§9) 점검**: 반전 있는 101편을 읽고 일상과 동떨어진 14편을 다시 씀(`7f2a34f`) — R1 8편(`r1_friends_a1·a5·a12`, `r1_life_a13·a2·c1`, `r1_travel_c2·c4`) · R2 6편(`r2_culture_a2`, `r2_friends_a1·c1`, `r2_life_a1·a2`, `r2_travel_a1`). 반전·설렘은 비율 그대로, 일상 장면 안에서. 나머지 87편은 현실적인 꼬임이라 그대로 둠. 장면 컷 그림은 14편 모두 옛 장면 → uk 그림 차례에 다시.
- **11/10**: R2 남은 4편(`r2_culture_a1`·`r2_love_a1`·`r2_love_a2`·`r2_travel_a2`)을 Grok 없이 세션 검수로 확정(`856f1b0`, Grok 은 주간 한도 11/16 초기화) — 감정 열·음성 계획까지. 이로써 **R1·R2 회화 전편 검수 끝**(음성 없는 편은 R2 10편 + 다시 쓴 R1 8편). 자산 업로드 점검: 장면 컷 549장·음성 3,444줄(220편) 모두 R2·D1 에 있음, 미업로드 없음.
- **11/11 성조연습 개편**(사용자 지시, uk 전달: 「4성 매트릭스를 성조연습으로… 단어 2개 → 3개 → 4개」「그다음엔 문장」 — **낱말 개수**, uk 가 사용자 확인) `775c4a3`: 화면 `lib/screens/tone_drill_screen.dart`(묶음 10개 = 2글자 낱말 4 + R1 문장 1, 2개부터 각자 3연속 통과하면 하나 추가, 잠금 없음, 문장은 겹쳐 보기·참고 점수만, 격자 = 진도 지도), 채점 `lib/services/pitch_coach.dart` + 모듈 `packages/talkverse_pitch`(**uk 담당 원본 `~/talkverse/talkverse-pitch` 의 복사본 — 여기서 고치지 말고 판정 어긋난 사례(낱말·말한 성조·나온 판정)를 uk 에 보낸 뒤 새 원본을 다시 복사**), 자료 `tools/build_tone_drill.py` → `assets/data/tone_drill.json`. 문턱값은 합성음 기준 — 첫 빌드는 사용자가 직접 말해 보고 판정 확인용. 1음절 준비 화면은 아직 옛 ToneAnalyzer 판정(uk 권고: `scoreMandarinTone` 으로 바꾸기 — 남은 일).
- HSK 1~5급 단어 목록(4,240) `~/talkverse/_shared/zh_hsk1-5_words.csv` 를 uk 에 넘김(그림 대조·공유 표시는 uk 몫, 사용자 지시).

## 남은 일
1. **11/12 00:01~10:00 음성(uk 전달 사용자 지시 "사운드 작업은 내일 00:01부터 다음날 오전 10시까지")** — M6 screen `zh-night` 이 `~/tts_work/zh/run_1111/night.py` 실행(00:01 까지 대기 → ① 새 참고 음성·검사 ② 오독 20조각: 새 판이 받아쓰기 0.90 넘으면 교체 → pack ③ R2 10 + R1 8편 6편씩 생성·qa·pack; 09:35 이후 새 PC 작업 안 함, 10:00 PC 작업 강제 중지). 로그 `night.log`, 남은 것 `left.txt`, 끝난 편 `done.txt`, 단계 완료 표시 `*.done` — 다시 돌리면 이어감. PC 의 R1 8편 옛 음성은 `out/zh/_old_1111`. 끝나면 uk 에 "GPU 끝"(또는 남은 양). **11/11 19:08 추가(사용자 지시, uk 전달 — 문법영상 렌더가 먼저)**: 00:01 이후에도 3090 사용량 8GB 미만 3분 연속이거나 `run_1111/GO` 파일이 있을 때만 시작, 10:00 까지 못 하면 다음 밤 00:01 창으로 자동 이월. **재부팅하면 screen 이 사라짐**(11/11 17:00 한 번 겪음 — launchd 등록은 자동 모드 정책에 막힘) → `cd ~/tts_work/zh/run_1111 && screen -dmS zh-night ~/.venvs/tts_zh/bin/python night.py` 로 다시 띄우면 끝난 단계는 건너뛰고 이어감.
1-0. **음성(11/10 지시: 새벽 원칙 폐기, 시간 제한 없음 — 순서 태국어 전편 → 중국어, uk 의 "지금 시작" 신호 뒤)** — ① 오독 재생성 **20조각**(`~/tts_work/zh/retake_jobs.json`; uk 는 22로 앎 — 다시 쓴 편에 든 2조각은 뺐다) ② **음성 없는 R2 10편**(계획 `data/tts/plan/r2_*.json` 준비됨 — `tools/tts/make_jobs.py` 로 작업 파일 만들 것) ③ **다시 쓴 R1 8편 전체**(작업 파일 `~/tts_work/zh/rewrite_1109/` vox 39 · moss 92). 각각 qa → `pack.py <wav> <편들> --upload`(그 편 D1 줄을 지우고 다시 넣음). D1 옛 줄을 미리 지우는 명령은 자동 모드 정책에 막힘(사용자 허용 뒤에도) — 우회 금지, pack 이 처리. 끝나면 uk 에 "GPU 끝".
1-1. (옛 목록) 오독 조각 목록 `data/tts/qa_fail_zh.tsv`(판정 「오독」), 출력 `out/zh/retake/`. uk 에 "시험 준비됨" 보냄 → **uk 가 PC 차례를 줄 때만**(태국어 전편 뒤), 그리고 **새벽 01:00~07:00 KST 에만**(11/9 지시 — 07:00 까지 못 끝내면 이어받기 지점에서 멈췄다가 다음 새벽 재개). 받은 뒤 qa → 가장 나은 판으로 pack `--upload`(그 편만) → audio_zh.json·리뷰 재생성 → uk 에 "GPU 끝"·"REVIEW_zh 갱신".
2. **Grok R2 재작성**(11/9 재개 — 공지 `~/logs/rc/RELAY_grok_20261109.md`: 자기 크롬을 켜고 `ssh macmini4 /usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <자기 포트>` 로 쿠키 동기화, uk 의 방은 건드리지 말 것, **한자 세션에 대행 요청 금지**) — **프롬프트 최소화**(11/9 지시): 규칙은 문서에 한 번, 방 첫 메시지에서 "파일 이름 한 줄만 보낸다" 약속, 이후 채팅은 한 줄만, 그림이 달라지면 최초 통과 그림 기준(이미 만든 건 그대로) — **PC 에서 Grok 쓰는 절차 `~/talkverse/PC_GROK_GUIDE.md`**(11/9 공지: 포트 등록 `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` → PC 크롬은 작업 스케줄러로 → M4 터널 + 쿠키 동기화 → 전문가 → 첨부는 PC 경로) — (R2 는 11/10 세션 검수로 끝 — 아래 Grok 절차는 컷 그림 다시 그릴 때 참고) — **포트 9261**(uk 배정, `D:\chrome-grok-zh`, 예약 작업 `Grok-Chrome-zh-9261` — 세션의 등록은 권한 정책에 막혀 사용자가 PC 에서 실행) — **답은 3분까지만**(11/10 지시: `--wait 180`, 넘으면 생성 중지 — 참고 vi `tools/grok_stop.py`; 우리 rewrite_run.sh 400초·cuts_one.sh 900초는 재개 전에 고칠 것) — **전문가 모드 확인**(`ssh macmini4 /usr/bin/python3 ~/talkverse-uk/tools/grok_mode.py <포트> --check`) — 남은 R2 는 `r2_culture_a1`·`r2_love_a2`·`r2_travel_a2` 3편(나머지는 11/9 세션이 일상 원칙으로 다시 씀; `r2_love_a1` 은 Grok 재작성본 검수 미반영), 한 방에서(`data/review/grok_room.txt`, `tools/grok/room.sh`), 요청 형식 5번째 칸 = 감정. 반영 `tools/grok/apply_final.py`(감정·이모지·음성 계획까지 자동) → `~/.venvs/zh/bin/python tools/add_lemmas.py` → 컷 `scene_prompts.py` + `cuts_one.sh`(LIMIT 처리 `grok_image.py` 에 아직 없음).
3. **출시 전**(지금 심사는 한자앱만): 탐색 탭 「맞춤 회화 만들기 — 준비 중」 줄 제거 또는 완성, 임시 조음 그림 교체, 스토어 상품 등록(사용자), 서버 `/me/purchases` 새 ID(uk).
4. 결정 대기: 한자 절벽 결과(`data/cliff/`)를 uk 사이트에 반영할지.

- 컷 개수 차이(uk 11/10 문의): `data/review/art` 569장 = 공개 컷 549장(D1 `art_scenes` 와 일치) + `_redo/` 20장. `_redo` 는 다시 그리기 전 옛 컷 보관본이라 **공개 안 함** — 푸시하지 말 것.

## 지울 후보(11/10 정리 때 남김 — 사용자 결정)
- `~/tts_work/zh/all`(389MB, 음성 원본 wav — R2 에 올라가 있으나 재생성 기준 자료), 프로젝트 밖이라 손대지 않음.
- 11/10 정리: `flutter clean`(build 2.8GB·.dart_tool 1.1GB), `android/.gradle`, 세션 임시 폴더의 talkversehanja 복제본(239MB) 삭제.

## 주의
- PC GPU 는 한 세션씩 — uk(또는 그 시각을 정한 세션)의 신호 없이 'TTS job 2060' 을 돌리지 말 것.
- M6 디스크가 한때 꽉 찼다(2026-11-09 오전, 지금 47GB 여유). 큰 산출물(`build/`, `~/tts_work/zh/all/wav`)은 지우기 전에 사용자에게 묻기.
- 공개 저장소: 말뭉치·작품 이름 금지(앱 소개는 "중국어 영화·드라마 자막"까지만).
