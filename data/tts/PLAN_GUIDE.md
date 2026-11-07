# 회화 음성 감정 계획 작성법 (중국어)

편마다 `data/tts/plan/<편id>.json` 한 파일. 검사 `python3 tools/tts/check_plan.py <편id>...`. 일본어앱·한국어앱 `data/tts/PLAN_GUIDE.md` 와 같은 틀, 중국어 칸 이름만 다르다(text=중국어 `zh`, reading=병음 `pinyin`, rd=한글 독음, ko=한국어 뜻).

```json
{"ep":"r1_x_a1",
 "cast":{"B":"xiaoli","C":"haoran"},
 "turns":{
  "1":{"segs":[["cheerful","小丽，今天干什么？"]]},
  "2":{"segs":[["surprised","啊？真的？"],["gentle","那一起去吧。"]]},
  "3":{"segs":[["shy","我也去。"]],
       "f":{"text":"我也去。","reading":"Wǒ yě qù.","rd":"워 예 취.","ko":"나도 갈게.","segs":[["shy","我也去。"]]}}
 }}
```

- **segs** = 턴을 말하는 순서대로 나눈 조각 `[감정, 본문]` 또는 `[감정, 본문, 읽기]`. 이어 붙이면 그 턴의 `zh` 와 같아야 한다(공백·문장부호·괄호 지문은 검사에서 무시).
- **읽기(세 번째 칸)** = 음성 모델이 읽을 글. 지문 `(门开了)`·`(微信)`, `哈哈`·이모지처럼 소리 내지 않을 것은 뺀다. 숫자는 한자로(`5分钟` → `五分钟`, `800块` → `八百块`). 한자 두 자 미만 조각은 만들지 않는다.
- **감정은 문장마다 대사 맥락으로 정한다.** 감정이 바뀌는 곳에서만 나눈다. neutral 만 쓰지 말 것 — 점원·안내는 polite, 받아치기는 tsukkomi, 심쿵 턴은 gentle·shy.
  감정: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle.
- **cast**: A(학습자)는 쓰지 않는다(자동 am/af). 고정 인물 小丽=xiaoli · 浩然=haoran · 悦=yue · 大叔=dashu · 房东=fangdong · 阿姨=ayi · 店员=dianyuan · 服务员=fuwuyuan · 外卖小哥=xiaoge · 司机=siji · 老板=laoban · 妈妈=mom. 그 밖은 나이·성별로 man_y/man_m/man_o/woman_y/woman_m/woman_o/kid · 안내 방송=announce · 키오스크/단말기=robot.
- **자리 표시**: `{name}`·`{country}`·`{city}`·`{lang}` 은 그대로 둔다(자동: 남성판 马克, 여성판 安娜 · 加拿大 · 多伦多 · 英语; 한국어 뜻의 조사는 받침에 맞춰 바뀐다). 그 밖의 자리는 `fill` 에 `{text, reading, rd, ko}` 로. 실제 작품·가수·회사 이름 금지.
- **남성판·여성판(`m`·`f`)**: 기본 본문이 그 판에 어색할 때만 그 판의 전체 턴(`text`·`reading`·`rd`·`ko`·`segs`)을 넣는다 — 「哥/姐」·「男朋友/女朋友」·「帅哥/美女」처럼 학습자 성별로 달라지는 말, 학습자를 남자·여자로 부르는 말. 옛 R3·R4(`legacy`) 편은 학습자 이름이 「马克」로 본문에 박혀 있으므로 여성판은 그 턴만 `f` 로 「安娜」로 바꾼다. `learner_gender` 가 정해진 편은 그 성별판만 맞고 다른 판은 그대로 둔다.
- **rd(한글 독음)가 없는 편**(옛 R3·R4)은 먼저 `dart run tool/fill_rd.dart <편.json>` 으로 채운다 — 검사가 알려 준다.
