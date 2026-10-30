# Supabase → Cloudflare 이관 — 중국어유니버스 (2026-10-26)

지침: `~/cloudflare-migration/GUIDE.md` · `~/cloudflare-migration/LANG_APPS_TASK.md`, 공용 설계: 태국어앱 `docs/CLOUDFLARE_MIGRATION.md` §2.
이 문서는 1단계(조사)·2단계(설계) 결과다.

**요약: 앱 고유 Supabase 사용 없음 — 확인 2026-10-26.** 공용 한자 표 읽기만 있고, 그것은 한자 세션이 `hanja-db` 로 옮긴 뒤 주소만 바꾼다. Supabase 에서 이 앱 때문에 지울 표·파일은 0개.

## 1. 조사 — 이 앱이 Supabase 에서 쓰는 것

| 항목 | 결과 |
|---|---|
| 앱 고유 표 | **없음** |
| 저장소 버킷 | **없음** (음성·데이터는 전부 앱 번들 `assets/`) |
| RPC · 트리거 | **없음** |
| 로그인(Supabase Auth) | **안 씀** — 계정 없이 동작 |
| 학습 기록 | 기기 안 SQLite(Drift, `chinese_universe`)와 SharedPreferences. 서버에 올리지 않는다 |
| 앱 업데이트 | GitHub 릴리스(`latest.json`·APK) — Supabase 와 무관 |
| 공용 한자 데이터 읽기 | `lib/services/shared_hanja_service.dart` 가 `hanja_chars` · `hanja_alias` · `hanja_mnemonic` 를 **읽기만** 한다(공개 키, 2026-10-25 추가, 아직 커밋·배포 전). GIF 는 2026-10-26 부터 R2 `https://gif.talkverse.uk/` |

조사 방법: 저장소 전체(`lib/` `data/` `tool/` `android/` `ios/` `.github/` `pubspec.yaml`)에서 Supabase 주소·패키지·`rest/v1`·`storage/v1`·`rpc/` 검색. `supabase_flutter` 패키지도 쓰지 않는다.

## 2. 설계

- **`zh-db`(D1)·`zh-files`(R2)·앱 전용 Worker 는 만들지 않는다.** 옮길 앱 고유 데이터가 없다.
- 공용 한자 데이터는 한자 세션이 `hanja-db`(D1) + Worker 로 옮긴다. 이 앱이 할 일은 **읽기 주소 교체**뿐이다.
  - 바꿀 곳은 `SharedHanjaService` 한 곳: `_base`(서버 주소)와 `_get`/`_fetchAll`(지금은 PostgREST 질의 문법 — `select`·`order`·`limit`·`offset`·`updated_at=gt.<시각>`).
  - Worker 쪽에 필요한 읽기 기능(한자 세션에 요청할 것):
    1. `hanja_chars` 를 `updated_at` 이후 바뀐 행만, 쪽(1,000행) 단위로 — 앱은 12시간마다 바뀐 행만 받는다.
    2. `hanja_alias` 전체(`ch`, `code`, `langs`).
    3. `hanja_mnemonic` 을 `updated_at` 이후 바뀐 행만.
    - D1 에서 JSON 으로 바뀌는 열(`pinyin`·`components`·`langs`)은 응답에서 **배열로** 돌려주면 앱 코드는 그대로 둘 수 있다. 문자열(JSON 텍스트)로 오면 앱에서 한 번 더 풀어야 한다.
  - 기기에 저장된 캐시 형식(`shared_hanja_v1.json`)은 그대로 쓴다. 서버만 바뀐다.
- 순서: 한자 세션이 읽기 주소를 알려 주면 → 주소·질의 교체 → 테스트(`test/shared_hanja_test.dart`) → 빌드 → 폰에서 확인.
- Supabase 쪽에 이 앱이 지울 것은 없다.

## 2-1. 계정·학습 기록을 넣게 되면 (2026-10-26 사용자 결정)

- Talkverse 언어앱은 언어별로 출시하지만 계정은 하나의 체계다: 계정·로그인·구독 = `talkverse-accounts`(D1) + Worker `talkverse-auth`,
  학습 데이터 = 언어앱 공용 `talkverse-db`(`lang` 열로 구분). 첫 설계는 태국어앱 세션 몫.
- 이 앱은 지금 로그인·서버 저장이 없다. 넣을 때 그 설계(태국어앱 문서 §2-2~2-6, 앱 코드는 §2-8 을 본뜸, client id `zh`, 딥링크 `talkverse.zh://auth`)를 따르고, 기기 안 기록(Drift)은 그대로 둔 채 동기화를 더하는 방식으로 한다.
- 한자 데이터는 계속 `hanja-db` 에서 읽는다.

## 3. 결과 (2026-10-30)

- 공용 한자 표 읽기를 `hanja-db` 읽기 API `https://hanja-api.talkverse-lab.workers.dev/rest/v1/<표>`(PostgREST 와 같은 모양, 공개 읽기·키 없음)로 바꿨다. GIF 는 R2 `https://gif.talkverse.uk/`.
- 확인(2026-10-26): `hanja_chars` 4,163행 · `hanja_alias` · `hanja_mnemonic`(form=kr·cn) 실제 수신, 두 번째 동기화는 바뀐 행 0. 첫 동기화 약 25초, 기기 캐시 약 3.6MB.
- 이 앱이 Supabase 에서 읽는 것은 이제 없다. 지울 Supabase 표·파일 0개.
