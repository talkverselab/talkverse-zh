# 중국어유니버스 — 인계 (2026-11-09 15:40 갱신)

규칙의 기준은 `CLAUDE.md`(서명·배포·공개 저장소). 이 파일은 지금 상태와 남은 일만. 옛 내용(2026-10-11 Zealot 설정 메모)은 모두 끝났거나 낡아서 지웠다.

## 지금 상태
- 마지막 앱 커밋 `7f2a34f`(master, 푸시됨). 최신 빌드: **Zealot 중국어유니버스 빌드 21** https://apps.talkverse.uk/vpiwj/432 · **TestFlight 2611091529**. PC `D:\OneDrive\app project\chinese-universe\` 백업.
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
- HSK 1~5급 단어 목록(4,240) `~/talkverse/_shared/zh_hsk1-5_words.csv` 를 uk 에 넘김(그림 대조·공유 표시는 uk 몫, 사용자 지시).

## 남은 일
1. **새벽 음성(uk 순서: 01:00 일본어 → 중국어 → 태국어, uk 의 "지금 시작" 신호 뒤)** — ① 오독 재생성 **20조각**(`~/tts_work/zh/retake_jobs.json`, 다시 쓴 편에 든 2조각은 뺐음, 백업은 세션 임시 폴더) ② **다시 쓴 R1 8편 전체**: 작업 파일 `~/tts_work/zh/rewrite_1109/`(vox 39 · moss 92) → qa → `pack.py <wav> <8편> --upload`(그 편 D1 줄을 지우고 다시 넣음). 그 전까지 앱은 이 8편을 옛 대사·옛 음성으로 보여 준다(음성 쪽 본문 표시). ⚠ 세션이 D1 에서 옛 줄만 미리 지우는 명령은 자동 모드 권한 정책에 막혔다 — 우회하지 말 것. 끝나면 uk 에 "GPU 끝".
1-1. (옛 목록) 오독 조각 목록 `data/tts/qa_fail_zh.tsv`(판정 「오독」), 출력 `out/zh/retake/`. uk 에 "시험 준비됨" 보냄 → **uk 가 PC 차례를 줄 때만**(태국어 전편 뒤), 그리고 **새벽 01:00~07:00 KST 에만**(11/9 지시 — 07:00 까지 못 끝내면 이어받기 지점에서 멈췄다가 다음 새벽 재개). 받은 뒤 qa → 가장 나은 판으로 pack `--upload`(그 편만) → audio_zh.json·리뷰 재생성 → uk 에 "GPU 끝"·"REVIEW_zh 갱신".
2. **Grok R2 재작성**(11/9 재개 — 공지 `~/logs/rc/RELAY_grok_20261109.md`: 자기 크롬을 켜고 `ssh macmini4 /usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <자기 포트>` 로 쿠키 동기화, uk 의 방은 건드리지 말 것, **한자 세션에 대행 요청 금지**) — **프롬프트 최소화**(11/9 지시): 규칙은 문서에 한 번, 방 첫 메시지에서 "파일 이름 한 줄만 보낸다" 약속, 이후 채팅은 한 줄만, 그림이 달라지면 최초 통과 그림 기준(이미 만든 건 그대로) — **PC 에서 Grok 쓰는 절차 `~/talkverse/PC_GROK_GUIDE.md`**(11/9 공지: 포트 등록 `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` → PC 크롬은 작업 스케줄러로 → M4 터널 + 쿠키 동기화 → 전문가 → 첨부는 PC 경로) — **전문가 모드 확인**(`ssh macmini4 /usr/bin/python3 ~/talkverse-uk/tools/grok_mode.py <포트> --check`) — 남은 R2 는 `r2_culture_a1`·`r2_love_a2`·`r2_travel_a2` 3편(나머지는 11/9 세션이 일상 원칙으로 다시 씀; `r2_love_a1` 은 Grok 재작성본 검수 미반영), 한 방에서(`data/review/grok_room.txt`, `tools/grok/room.sh`), 요청 형식 5번째 칸 = 감정. 반영 `tools/grok/apply_final.py`(감정·이모지·음성 계획까지 자동) → `~/.venvs/zh/bin/python tools/add_lemmas.py` → 컷 `scene_prompts.py` + `cuts_one.sh`(LIMIT 처리 `grok_image.py` 에 아직 없음).
3. **출시 전**(지금 심사는 한자앱만): 탐색 탭 「맞춤 회화 만들기 — 준비 중」 줄 제거 또는 완성, 임시 조음 그림 교체, 스토어 상품 등록(사용자), 서버 `/me/purchases` 새 ID(uk).
4. 결정 대기: 한자 절벽 결과(`data/cliff/`)를 uk 사이트에 반영할지.

## 주의
- PC GPU 는 한 세션씩 — uk(또는 그 시각을 정한 세션)의 신호 없이 'TTS job 2060' 을 돌리지 말 것.
- M6 디스크가 한때 꽉 찼다(2026-11-09 오전, 지금 47GB 여유). 큰 산출물(`build/`, `~/tts_work/zh/all/wav`)은 지우기 전에 사용자에게 묻기.
- 공개 저장소: 말뭉치·작품 이름 금지(앱 소개는 "중국어 영화·드라마 자막"까지만).
