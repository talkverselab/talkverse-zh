"""
Build L1 10-day course assets:

  1) Markdown course doc:
     D:/OneDrive/PROJECT/talkverse-learning/ZH/Grammar/L1_10day_course.md

  2) Flutter JSON (10 days × hanzi list + grammar pattern + 10 punchy sentences):
     C:/dev/talkverse_learning/assets/zh_data/l1_10day.json

  3) Edge TTS mp3 generation script outputs to:
     C:/dev/talkverse_learning/assets/zh_data/audio/l1_punchy/d{N}_{M}.mp3
     (100 mp3 total — 10 day × 10 sentence each)
     Plus updates manifest.json under files.l1_punchy.

Inputs:
  - core_hanzi_209.json (for pinyin / meaning lookup of all 216 chars)

Author-provided:
  - Hand-curated 216-char distribution across 10 days
  - Hand-curated KO basic meanings for the 209 phase-1 chars (no KO in JSON)
  - Hand-curated 10 punchy sentences per day (100 total)
  - Hand-curated grammar pattern + day completion criteria + lock copy
"""

from __future__ import annotations
import asyncio, json, sys, io, os, re
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

HANZI_JSON = "C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json"
OUT_MD = "D:/OneDrive/PROJECT/talkverse-learning/ZH/Grammar/L1_10day_course.md"
OUT_JSON = "C:/dev/talkverse_learning/assets/zh_data/l1_10day.json"
TTS_OUT = Path("C:/dev/talkverse_learning/assets/zh_data/audio/l1_punchy")
MANIFEST = Path("C:/dev/talkverse_learning/assets/zh_data/audio/manifest.json")

# ===== Hand-curated KO basic meanings for 209 phase-1 chars =====
# (only the phase-1 chars without KO meaning — phase-2/3/ext-chat already have it)
KO_MEANINGS = {
    # Day 1 - 인칭 + 是·的 + 기본 어기조사
    '我': '나', '你': '너', '他': '그(남)', '她': '그녀', '们': '~들',
    '是': '~이다', '不': '아니다', '的': '~의 (소유)', '在': '~에 있다',
    '吗': '~까? (의문)', '吧': '~지·~자 (제안)', '啊': '~야! (감탄)',
    '呢': '~는? (반문)', '么': '什么 일부 (뭐)', '哪': '어느·어디',
    '对': '맞다·옳다',
    # Day 2 - 어기조사 + 채팅 marker
    '呀': '~야 (啊 변형, 모음 뒤)', '啦': '~네·~다 (了+啊 결합)',
    '嗯': '응·음 (동의·생각)', '嘛': '~잖아·~인데 (당연·투정)',
    '哦': '아~·오~ (깨달음)',
    # Day 3 - 지시·양사·숫자
    '这': '이·이것', '那': '저·저것', '一': '하나·1', '两': '둘 (수량)',
    '些': '약간·여럿', '个': '개 (만능 양사)', '次': '번 (횟수)',
    '样': '모양·종류', '点': '시·점', '里': '안·~리', '子': '아들·접미사',
    '儿': '아이·儿화 음', '上': '위·올라가다', '下': '아래·내려가다',
    '以': '~로써', '把': '~을·잡다', '所': '바·~인 것',
    '其': '그·그것', '和': '그리고·~와', '或': '또는', '中': '중·가운데',
    # Day 4 - 동사
    '有': '있다·가지다', '去': '가다', '来': '오다', '走': '걷다·가다',
    '到': '도착하다·~까지', '说': '말하다', '做': '하다·만들다',
    '看': '보다', '听': '듣다', '问': '묻다', '找': '찾다',
    '起': '일어나다', '开': '열다·시작하다', '回': '돌아가다',
    '吃': '먹다', '拿': '잡다·가지다', '打': '치다·하다', '叫': '부르다·~라고 하다',
    '住': '살다·머물다', '带': '데리고 가다·가져가다', '行': '괜찮다·되다',
    '发': '보내다·발사', '出': '나가다',
    # Day 5 - 시제·부사
    '了': '~했다 (완료)', '过': '~한 적 있다 (경험)', '已': '이미',
    '真': '진짜·정말', '还': '아직·또', '也': '~도', '就': '바로·곧',
    '才': '비로소·겨우', '只': '단지', '很': '매우', '太': '너무',
    '当': '~할 때·当然=당연히', '又': '또·다시', '都': '모두',
    '再': '다시', '最': '가장', '常': '자주·常常',
    '直': '곧·一直=계속', '正': '바로·정확히', '更': '더',
    '必': '반드시', '须': '~해야', '准': '정확히·准备=준비',
    '然': '当然=당연히 / 竟然=뜻밖에',
    # Day 6 - 능원동사·의문사·감각
    '要': '~할 것·필요', '会': '~할 줄·~할 것', '想': '~하고 싶다·생각하다',
    '能': '~할 수 있다 (능력)', '可': '~할 수 있다 (가능)·可以',
    '应': '应该=마땅히', '该': '~해야', '什': '什么=뭐',
    '谁': '누구', '怎': '어떻게·怎么', '为': '~을 위해·因为=왜냐하면',
    '如': '如果=만약', '何': '为何=왜·如何=어떻게',
    '觉': '느끼다·觉得=생각하다', '得': '~해야·de(보조)',
    '知': '知道=알다', '道': '도로·知道=알다', '信': '믿다·편지',
    '意': '뜻·意思', '像': '~같다·닮다', '感': '느끼다·感觉',
    '它': '그것 (사물)', '种': '종류·种类',
    # Day 7 - 부정·형용사·양태
    '没': '없다·~안 했다', '好': '좋다·OK·매우', '大': '크다',
    '小': '작다', '多': '많다', '快': '빠르다',
    '别': '~하지 마라', '着': '~하고 있다 (지속)', '干': '하다·마르다',
    '错': '틀리다·不错=괜찮다', '死': '죽다·~할 정도로',
    '完': '끝나다', '非': '아니다·非常=매우',
    '成': '되다·成为', '定': '정하다·一定=꼭',
    '全': '전부·安全=안전', '切': '一切=모두·자르다',
    '被': '~당하다 (피동)', '但': '但是=하지만',
    '果': '결과·苹果·如果', '生': '살다·태어나다·学生',
    '现': '나타나다·现在=지금', '白': '하얀·明白=알다',
    # Day 8 - 시간·일상 명사·관용
    '谢': '감사하다·谢谢', '时': '시·시간', '候': '时候=때',
    '年': '년', '天': '하늘·날', '明': '밝다·明天=내일',
    '晚': '늦다·저녁', '今': '今天=오늘', '前': '앞·이전',
    '后': '뒤·이후', '间': '사이·房间=방', '西': '서쪽·东西=물건',
    '东': '동쪽', '心': '마음·心里', '事': '일·事情',
    '话': '말·电话', '放': '놓다·放假=방학',
    '面': '面子=체면·~面 (방향)', '地': '땅·地方=장소·de(부사)',
    '方': '방향·方便=편리', '工': '工作=일·工人',
    '之': '~의 (문어)', '而': '그리고·而且',
    '情': '감정·爱情·事情',
    # Day 9 - 호칭·가족·사람·관계
    '爸': '아빠', '妈': '엄마', '人': '사람', '女': '여자',
    '孩': '아이·孩子', '朋': '朋友=친구', '友': '친구',
    '希': '希望=희망하다', '望': '바라보다·希望', '亲': '친한·亲爱=사랑하는',
    '认': '认识=알다', '见': '보다·见面', '请': '청하다·请客=한턱쏘다',
    '告': '告诉=알리다', '诉': '告诉=알리다',
    '帮': '돕다·帮忙', '用': '쓰다·有用',
    '给': '주다·~에게', '让': '~하게 하다',
    '跟': '~와·따라가다', '从': '~부터',
    '作': '하다·作业=숙제', '家': '집·가족',
    # Day 10 - 종합·고급·마무리
    '爱': '사랑하다·~을 좋아하다', '喜': '喜欢=좋아하다',
    '欢': '喜欢·欢迎=환영',
    '先': '먼저·先生=~씨', '等': '기다리다·등등',
    '法': '방법·法语=프랑스어', '钱': '돈',
    '电': '전기·电话·电视', '题': '문제·主题',
    '始': '开始=시작하다', '离': '떠나다·~로부터',
    '将': '~할 것이다 (미래·문어)', '进': '들어가다·进步',
    '比': '비교하다·~보다', '记': '기억하다·记得',
    '思': '思考=생각하다·意思', '因': '因为=왜냐하면',
    '己': '自己=자기', '任': '任何=어떤·责任=책임',
    '备': '准备=준비하다', '关': '关系=관계·关心',
    '杀': '죽이다·绝杀', '许': '也许=아마·允许=허락',
    '需': '需要=필요하다', '自': '自己=자기·自由=자유',
    '相': '서로·相信=믿다', '经': '经历=경험·已经=이미',
}

# ===== Hand-curated 10-day curriculum =====
# Each day: category, list of chars (already in PLAN), grammar_pattern, sentences (10).
# Sentences format: {zh, pinyin, ko, situation}

DAYS = [
    {
        'day': 1,
        'cat': '인칭 + 是·的 + 기본 어기조사',
        'chars': ['我','你','他','她','们','是','不','的','在','吗','吧','啊','呢','么','哪','对'],
        'grammar': {
            'title': 'X는 Y이다 (是 활용)',
            'patterns': [
                ('我是X', '나는 X이다'),
                ('你是X吗?', '너 X야?'),
                ('我不是X', '나는 X 아니야'),
                ('那是我的', '그건 내 거야'),
                ('你呢?', '너는?'),
            ],
            'note': '是 = "이다" (영어 to be). 不 + 是 = 不是 (아니다). 어기조사 啊·吗·吧·呢는 문장 끝에 붙여 어감 만든다.',
        },
        'sentences': [
            ('你好啊!',       'Nǐ hǎo a!',       '안녕!',                    '첫 인사·매칭앱 첫 메시지'),
            ('我是你的!',     'Wǒ shì nǐ de!',   '나는 너의 거!',            '커플·장난·고백'),
            ('你呢?',         'Nǐ ne?',          '너는?',                    '되묻기·관심'),
            ('是吗?',         'Shì ma?',         '그래?',                    '맞장구·놀람'),
            ('我不是!',       'Wǒ bù shì!',      '난 아니야!',               '오해 풀기·부정'),
            ('那是我的!',     'Nà shì wǒ de!',   '그거 내 거!',              '소유 주장'),
            ('好吧.',         'Hǎo ba.',         '알았어.',                  '마지못해 동의'),
            ('对!',           'Duì!',            '맞아!',                    '강한 동의'),
            ('不对!',         'Bù duì!',         '아니야!',                  '강한 부정'),
            ('哪个?',         'Nǎ ge?',          '어느 거?',                 '선택 묻기'),
        ],
        'lock_copy': '14자. 30분. 안 할래?',
    },
    {
        'day': 2,
        'cat': '어기조사 풀세트 + 채팅 marker',
        'chars': ['呀','啦','嗯','嘛','哦','喂','嘿','嗨','啥','呵','哇','咋'],
        'grammar': {
            'title': '감정·반응 어기조사 + 부르기',
            'patterns': [
                ('好啦!',     '됐어! / 좋아! (가벼운 완료)'),
                ('谁呀?',     '누구야? (啊 → 呀 변형)'),
                ('嗯…',       '응… / 음… (생각·동의)'),
                ('喂!',       '여보세요! / 야!'),
                ('哇!',       '와! (감탄)'),
            ],
            'note': '어기조사는 의미 X, 어감 O. 啦=완료/가벼움, 呀=놀람/친근, 嗯=동의/생각, 嘛=당연/투정, 哦=깨달음. 喂는 전화 첫 마디 필수.',
        },
        'sentences': [
            ('嘿!',           'Hēi!',            '야!',                      '친구 부르기'),
            ('喂?',           'Wéi?',            '여보세요?',                '전화 받을 때'),
            ('嗨~',           'Hāi~',            '하이~',                    '캐주얼 인사'),
            ('啥?',           'Shá?',            '뭐?',                      '북방 구어 되묻기'),
            ('哇!',           'Wā!',             '와!',                      '감탄·놀람'),
            ('呵呵.',         'Hē hē.',          '하하 (시큰둥).',           '채팅 비꼬는 웃음'),
            ('好啦好啦!',     'Hǎo la hǎo la!',  '알았어 알았어!',           '귀찮아 마무리'),
            ('哦~',           'Ó~',              '아~ / 오~',                '깨달음·이해'),
            ('嗯,知道了.',    'Ǹg, zhīdào le.',  '응, 알았어.',              '동의·끝'),
            ('咋了?',         'Zǎ le?',          '왜 그래? (북방).',         '北方 말투 친근'),
        ],
        'lock_copy': '12자. 어기조사 = 회화의 영혼. 안 외우면 다 책 같음.',
    },
    {
        'day': 3,
        'cat': '지시·양사·숫자·기본 위치·접속',
        'chars': ['这','那','一','两','些','个','次','样','点','里','子','儿','上','下','以','把','所','其','和','或','中'],
        'grammar': {
            'title': '지시 + 양사 + 숫자',
            'patterns': [
                ('这个 / 那个',           '이거 / 저거'),
                ('一个人',                '한 사람'),
                ('两次',                  '두 번'),
                ('一些朋友',              '친구 몇 명'),
                ('几点了?',               '몇 시야?'),
            ],
            'note': '중국어는 [수사]+[양사]+[명사]. 个는 만능 양사 — 잘 모르겠으면 个 쓰면 된다. 두 명/개는 二가 아니라 两. 上/下는 위치(上面)·시간(上次=지난번)·동사(上车=차에 타다) 다양.',
        },
        'sentences': [
            ('这个!',         'Zhè ge!',         '이거!',                    '주문·선택'),
            ('那个呢?',       'Nà ge ne?',       '저건?',                    '대안 묻기'),
            ('一个人.',       'Yī ge rén.',      '혼자야.',                  '식당·여행'),
            ('两个人.',       'Liǎng ge rén.',   '두 명이요.',               '식당 입장'),
            ('一点点.',       'Yī diǎn diǎn.',   '조금만.',                  '음료·양 조절'),
            ('几点了?',       'Jǐ diǎn le?',     '몇 시야?',                 '시간 묻기 (Day 5에서 了 학습 — 미리 hook)'),
            ('就这样.',       'Jiù zhè yàng.',   '그냥 이대로.',             '결정·마무리'),
            ('再来一个.',     'Zài lái yī ge.',  '하나 더!',                 '추가 주문'),
            ('我和你.',       'Wǒ hé nǐ.',       '나랑 너.',                 '둘이서·관계'),
            ('我或他.',       'Wǒ huò tā.',      '나 아니면 그.',            '선택지'),
        ],
        'lock_copy': '20자. 양사 안 외우면 "三书" 같은 외국인 티 폭발.',
    },
    {
        'day': 4,
        'cat': '동사 (이동·존재·일상)',
        'chars': ['有','去','来','走','到','说','做','看','听','问','找','起','开','回','吃','拿','打','叫','住','带','行','发','出'],
        'grammar': {
            'title': '기본 동사 + 동작 표현',
            'patterns': [
                ('我去X',         '나 X 가'),
                ('你来X',         '너 X 와'),
                ('你说什么?',     '뭐라고?'),
                ('我吃过',        '먹었어 (경험)'),
                ('我们走!',       '우리 가자!'),
            ],
            'note': '동사는 형태 변화 X (영어처럼 -ed, -ing 안 붙음) — 시제는 了·过·着로 표시 (Day 5에서 학습). 走 ≠ "달리다", "걷다·가다" (跑가 달리다). 听·看은 단순 동사로 쓸 수 있고 听话=말 잘 듣다 같은 관용도 많음.',
        },
        'sentences': [
            ('走啊走啊!',     'Zǒu a zǒu a!',    '가자 가자!',               '재촉'),
            ('来吧!',         'Lái ba!',         '와!',                      '초대'),
            ('我去!',         'Wǒ qù!',          '내가 갈게!',               '자원·결정'),
            ('说说看.',       'Shuō shuō kàn.',  '말해봐.',                  '대화 유도'),
            ('听我说.',       'Tīng wǒ shuō.',   '내 말 들어봐.',            '주의 끌기'),
            ('快出来!',       'Kuài chū lái!',   '빨리 나와!',               '재촉 (Day 7 快 사전 hook)'),
            ('你叫什么?',     'Nǐ jiào shénme?', '이름이 뭐야?',             '자기소개'),
            ('我找你!',       'Wǒ zhǎo nǐ!',     '너 찾고 있어!',            '연락·만남'),
            ('做什么?',       'Zuò shénme?',     '뭐 해?',                   '관심·잡담'),
            ('回家了.',       'Huí jiā le.',     '집 갔어.',                 '귀가 보고'),
        ],
        'lock_copy': '23자. 동사 모르면 회화 0%. 무조건 외워.',
    },
    {
        'day': 5,
        'cat': '시제 + 부사',
        'chars': ['了','过','已','真','还','也','就','才','只','很','太','当','又','都','再','最','常','直','正','更','必','须','准','然'],
        'grammar': {
            'title': '시제 (了·过) + 핵심 부사',
            'patterns': [
                ('我吃了',        '먹었다 (완료)'),
                ('我吃过',        '먹어본 적 있다 (경험)'),
                ('已经X了',       '이미 X했다'),
                ('太X了!',        '너무 X해!'),
                ('当然!',         '당연히!'),
            ],
            'note': '了 = 완료 (방금/막), 过 = 경험 (해본 적). 이 둘이 핵심. 已经~了 결합 자주. 太~了는 감탄 패턴. 부사 위치는 동사 앞 (我也喜欢 ≠ 也我喜欢).',
        },
        'sentences': [
            ('太好了!',       'Tài hǎo le!',     '완전 좋아!',               '기쁨 폭발'),
            ('完了完了!',     'Wán le wán le!',  '망했다 망했다!',           '실수·당황'),
            ('真的吗?!',      'Zhēn de ma?!',    '진짜?!',                   '놀람'),
            ('我也!',         'Wǒ yě!',          '나도!',                    '동의'),
            ('当然啦!',       'Dāng rán la!',    '당연하지!',                '단호한 긍정'),
            ('就是这样.',     'Jiù shì zhè yàng.','바로 그거야.',            '확신·동의 (Day 3 就这样 강조형)'),
            ('再来!',         'Zài lái!',        '한 번 더!',                '재요청'),
            ('已经晚了.',     'Yǐ jīng wǎn le.', '이미 늦었어.',             '시간·체념'),
            ('我吃过.',       'Wǒ chī guò.',     '먹어봤어.',                '경험·식당'),
            ('我准备好了.',   'Wǒ zhǔn bèi hǎo le.','준비됐어.',             '확신·시작'),
        ],
        'lock_copy': 'Day 5. 절반. 평균 70% 여기서 포기. 너는?',
    },
    {
        'day': 6,
        'cat': '능원동사 + 의문사 + 감각',
        'chars': ['要','会','想','能','可','应','该','什','谁','怎','为','如','何','觉','得','知','道','信','意','像','感','它','种'],
        'grammar': {
            'title': '~할 것이다 / ~하고 싶다 / 의문사',
            'patterns': [
                ('我想X',         '나 X 하고 싶어'),
                ('我要X',         '나 X 할게 (의지·필요)'),
                ('你会X吗?',      '너 X 할 줄 알아?'),
                ('为什么?',       '왜?'),
                ('觉得怎么样?',   '어떻게 생각해?'),
            ],
            'note': '想 (욕구) / 要 (의지·필요) / 会 (능력) / 能 (가능) / 可以 (허락) — 다 다름. 想은 부드럽고, 要는 단호. "我要你" = "너 필요해" (강함, 사랑 표현 OK 하지만 식당에서 음식 주문에도 쓰임).',
        },
        'sentences': [
            ('我要你!',       'Wǒ yào nǐ!',      '너 원해!',                 '직설 사랑·매칭앱'),
            ('我想你.',       'Wǒ xiǎng nǐ.',    '보고싶어.',                '연인 그리움'),
            ('什么?!',        'Shénme?!',        '뭐?!',                     '놀람·되묻기'),
            ('怎么办?',       'Zěnme bàn?',      '어떻게 해?',               '곤란·도움 청함'),
            ('为什么?',       'Wèi shénme?',     '왜?',                      '이유 묻기'),
            ('我知道.',       'Wǒ zhī dào.',     '알아.',                    '확신·짜증'),
            ('我觉得…',       'Wǒ jué de…',      '내 생각엔…',               '의견 시작'),
            ('可以吗?',       'Kě yǐ ma?',       '돼?',                      '허락·요청'),
            ('我会的.',       'Wǒ huì de.',      '할게.',                    '약속·확신'),
            ('谁啊?',         'Shéi a?',         '누구야?',                  '문 두드림·전화'),
        ],
        'lock_copy': '23자. 의문사 안 외우면 평생 듣기만 함.',
    },
    {
        'day': 7,
        'cat': '부정 + 형용사 + 양태',
        'chars': ['没','好','大','小','多','快','别','着','干','错','死','完','非','成','定','全','切','被','但','果','生','现','白'],
        'grammar': {
            'title': '不 vs 没 + 好 multi-use + 형용사',
            'patterns': [
                ('我不X',         '나 X 안 해 (현재·습관·미래)'),
                ('我没X',         '나 X 안 했어 (과거 사실 부정)'),
                ('好+형용사',     '好吃 (맛있다) / 好看 (예쁘다)'),
                ('好+동사',       '好的 (OK) / 好啊 (좋아)'),
                ('别X!',          'X하지 마!'),
            ],
            'note': '不 vs 没 핵심: 不去=안 가 / 没去=안 갔어. 好는 만능 — 좋다·OK·매우(强调) 다. 好吃=맛있다. 好可爱=완전 귀여움. 死了=~할 정도로 (累死了=피곤해 죽겠어). 别=Don\'t (금지).',
        },
        'sentences': [
            ('好的.',         'Hǎo de.',         '오케이.',                  '동의·확정'),
            ('好吃!',         'Hǎo chī!',        '맛있어!',                  '식사·칭찬'),
            ('好可爱!',       'Hǎo kě\'ài!',     '완전 귀여워!',             '동물·아기 (Day 9 호칭 hook)'),
            ('不行!',         'Bù xíng!',        '안 돼!',                   '단호한 거절'),
            ('没事.',         'Méi shì.',        '괜찮아.',                  '사과 받기·안심'),
            ('累死了!',       'Lèi sǐ le!',      '피곤해 죽겠어!',           '하소연'),
            ('别走!',         'Bié zǒu!',        '가지 마!',                 '만류'),
            ('快点!',         'Kuài diǎn!',      '빨리!',                    '재촉'),
            ('完了!',         'Wán le!',         '망했어!',                  '실수·당황'),
            ('真不错!',       'Zhēn bú cuò!',    '꽤 괜찮네!',               '칭찬·만족'),
        ],
        'lock_copy': '23자. 好 한 글자에 5가지 뜻. 다 외워. 60% 회화 = 好.',
    },
    {
        'day': 8,
        'cat': '시간 + 일상 명사 + 관용',
        'chars': ['谢','时','候','年','天','明','晚','今','前','后','间','西','东','心','事','话','放','面','地','方','工','之','而','情'],
        'grammar': {
            'title': '시간 표현 + 关系·没事 + 谢谢',
            'patterns': [
                ('今天 / 明天 / 昨天 어제는 phase 2',  '오늘 / 내일 (어제는 L2에서)'),
                ('什么时候?',      '언제?'),
                ('谢谢!',          '고마워!'),
                ('没关系.',        '괜찮아.'),
                ('明白了.',        '알겠어. (Day 7 白 hook)'),
            ],
            'note': '今天=오늘, 明天=내일, 早上=아침, 晚上=저녁. "什么时候" = "언제". 谢谢 (감사) → 不客气 (천만에). 没关系 ≈ 没事 = 괜찮아 (Day 7 没事 복습). 东西=물건 (방향이 아닌 명사로). 心情=기분, 事情=일.',
        },
        'sentences': [
            ('谢谢!',         'Xiè xie!',        '고마워!',                  '감사·기본'),
            ('没关系啦!',     'Méi guān xi la!', '괜찮아 괜찮아!',           '용서·가벼움'),
            ('今天太累了!',   'Jīn tiān tài lèi le!','오늘 너무 피곤!',      '하소연 (Day 5 太~了 복습)'),
            ('明天见!',       'Míng tiān jiàn!', '내일 봐!',                 '헤어짐 (Day 9 见 hook)'),
            ('什么时候?',     'Shénme shíhou?',  '언제?',                    '약속 묻기'),
            ('在哪儿?',       'Zài nǎr?',        '어디야?',                  '위치·전화 (Day 1 哪 + 在 활용)'),
            ('心情不好.',     'Xīn qíng bù hǎo.','기분 안 좋아.',            '감정 표현'),
            ('没事的.',       'Méi shì de.',     '별일 아니야.',             '안심·위로'),
            ('明白了!',       'Míng bái le!',    '알겠어!',                  '이해·확인'),
            ('好久不见!',     'Hǎo jiǔ bú jiàn!','오랜만!',                  '오랜만 인사'),
        ],
        'lock_copy': '24자. 시간 못 말하면 약속도 못 잡음.',
    },
    {
        'day': 9,
        'cat': '호칭·가족·사람·관계',
        'chars': ['爸','妈','人','女','孩','朋','友','希','望','亲','认','见','请','告','诉','帮','用','给','让','跟','从','作','家'],
        'grammar': {
            'title': '호칭 + 부탁·요청 + 给·让·帮',
            'patterns': [
                ('我爸 / 我妈',     '아빠 / 엄마 (我의 X)'),
                ('请X',             'X 해주세요 (정중)'),
                ('给我X',           '나에게 X 줘'),
                ('让我X',           '나 X 하게 해줘'),
                ('帮我X',           '나 X 좀 도와줘'),
            ],
            'note': '중국어 호칭은 한국어보다 단순 (氏 안 붙임). 我爸=우리 아빠, 我妈=우리 엄마. 朋友=친구. 给/让/帮 모두 사역·요청 — 给我=나에게 줘, 让我=나 X하게 해, 帮我=나 도와. 매칭앱·일상에서 폭발적으로 쓰임.',
        },
        'sentences': [
            ('妈呀!',         'Mā ya!',          '엄마야! (놀람).',          '북방 감탄 (Day 2 呀 복습)'),
            ('哥! 等等!',     'Gē! Děng deng!',  '오빠! 기다려!',            '부르기 (哥는 phase 2 — 미리 hook)'),
            ('您好!',         'Nín hǎo!',        '안녕하세요! (정중).',      '존댓말 (您=phase 2 hook)'),
            ('谢谢阿姨!',     'Xiè xie ā yí!',   '아주머니 고마워요!',       '아주머니 호칭'),
            ('给我!',         'Gěi wǒ!',         '나 줘!',                   '직설·친한 사이'),
            ('让我看看.',     'Ràng wǒ kàn kan.','한번 보자.',               '관심·확인'),
            ('帮我一下.',     'Bāng wǒ yī xià.', '잠깐 도와줘.',             '부탁·일상'),
            ('请告诉我.',     'Qǐng gào su wǒ.', '말해주세요.',              '정중 요청'),
            ('我朋友.',       'Wǒ péng yǒu.',    '내 친구야.',               '소개'),
            ('你跟我来.',     'Nǐ gēn wǒ lái.',  '나 따라와.',               '안내·리드'),
        ],
        'lock_copy': '23자. 가족 호칭 모르면 중국 친구 부모 만나도 한 마디도 못 함.',
    },
    {
        'day': 10,
        'cat': '종합·고급 패턴 + 마무리',
        'chars': ['爱','喜','欢','先','等','法','钱','电','题','始','离','将','进','比','记','思','因','己','任','备','关','杀','许','需','自','相','经'],
        'grammar': {
            'title': '喜欢·爱 + 因为·所以 + 比 + 自己',
            'patterns': [
                ('我喜欢X',         '나 X 좋아해'),
                ('我爱X',           '나 X 사랑해'),
                ('因为X 所以Y',     'X 때문에 Y'),
                ('A比B X',          'A는 B보다 X'),
                ('我自己',          '나 자신 (혼자)'),
            ],
            'note': '喜欢 (좋아함, 가벼움) vs 爱 (사랑·강함). "我喜欢你" = 좋아해 (썸·고백 시작), "我爱你" = 사랑해 (관계 확정). 因为~所以 = 왜냐하면~그래서 (1세트 사용 가능, 한쪽만도 OK). 比 = ~보다 (영어 than). 自己 = oneself.',
        },
        'sentences': [
            ('我喜欢你.',     'Wǒ xǐ huan nǐ.',  '너 좋아해.',               '썸·고백 (가볍)'),
            ('我爱你.',       'Wǒ ài nǐ.',       '사랑해.',                  '연인 (강)'),
            ('我自己来.',     'Wǒ zì jǐ lái.',   '내가 할게.',               '자립·거절'),
            ('记得我!',       'Jì de wǒ!',       '날 잊지 마!',              '이별·강조'),
            ('你比我高.',     'Nǐ bǐ wǒ gāo.',   '너 나보다 커.',            '비교 (高=phase 3, hook)'),
            ('因为你.',       'Yīn wèi nǐ.',     '너 때문에.',               '이유·로맨틱'),
            ('我已经准备好了.','Wǒ yǐ jīng zhǔn bèi hǎo le.','난 다 준비됐어.','결심·확신 (Day 5 已经/了 복습)'),
            ('开始吧!',       'Kāi shǐ ba!',     '시작하자!',                '결정·출발'),
            ('我想想.',       'Wǒ xiǎng xiang.', '생각 좀 해볼게.',          '시간 벌기 (Day 6 想 복습)'),
            ('你真好.',       'Nǐ zhēn hǎo.',    '너 진짜 좋다.',            '감동·고마움 (Day 5 真 + Day 7 好 결합)'),
        ],
        'lock_copy': '끝. 너는 진짜 했다. L2 시작 = 진짜 회화.',
    },
]

# ===== Validation =====
def validate():
    with open(HANZI_JSON, encoding='utf-8') as f:
        data = json.load(f)
    chars_meta = {c['char']: c for c in data['characters']}
    target = {c['char'] for c in data['characters'] if c.get('phase_group') in ('1A','1B','1C','ext-chat')}

    assigned = []
    for d in DAYS:
        for ch in d['chars']:
            assigned.append(ch)
    if len(set(assigned)) != len(assigned):
        from collections import Counter
        ctr = Counter(assigned)
        dups = [k for k,v in ctr.items() if v>1]
        raise SystemExit(f'DUP chars: {dups}')
    if set(assigned) != target:
        miss = target - set(assigned)
        extra = set(assigned) - target
        raise SystemExit(f'Mismatch — missing: {sorted(miss)}, extra: {sorted(extra)}')
    # Check sentence count = 10 each
    for d in DAYS:
        if len(d['sentences']) != 10:
            raise SystemExit(f'Day {d["day"]} sentence count = {len(d["sentences"])} ≠ 10')
    # Check sentence uniqueness across all days
    all_zh = []
    for d in DAYS:
        for s in d['sentences']:
            all_zh.append(s[0])
    if len(set(all_zh)) != 100:
        from collections import Counter
        ctr = Counter(all_zh)
        dups = [k for k,v in ctr.items() if v>1]
        raise SystemExit(f'Duplicate sentences across days: {dups}')
    print(f'[validate] OK — {len(assigned)} chars, 100 unique sentences')
    return chars_meta


def get_meta(ch, chars_meta):
    """Return (pinyin, ko_meaning) for a char."""
    m = chars_meta.get(ch, {})
    pinyin = m.get('pinyin', '?')
    ko = KO_MEANINGS.get(ch) or m.get('basic_meaning_ko') or m.get('meaning_en', '?')
    return pinyin, ko


# ===== Markdown generation =====
def gen_md(chars_meta):
    lines = []
    lines.append('# Talkverse ZH L1 — 10일 강제 코스 (무료)')
    lines.append('')
    lines.append('> 매일 약 2시간. 10일. 한자 216자 (1A 100 + 1B 50 + 1C 59 + 채팅 marker 7) + 통통 외움 문장 100개 + 문법 패턴 10.')
    lines.append('> ')
    lines.append('> **약속 X. 결과 O. 못 하면 결제 마.**')
    lines.append('> Day 1 못 끝내면 Day 2 잠금. 재도전은 OK.')
    lines.append('')
    lines.append('---')
    lines.append('')
    lines.append('## Day 별 일정')
    lines.append('')
    lines.append('| Day | 카테고리 | 한자 수 | 문장 수 | 누적 한자 |')
    lines.append('|---:|---|---:|---:|---:|')
    cum = 0
    for d in DAYS:
        cum += len(d['chars'])
        lines.append(f'| {d["day"]} | {d["cat"]} | {len(d["chars"])} | 10 | {cum} |')
    lines.append('')
    lines.append('**총 216자 + 100문장 + 10 문법 패턴.**')
    lines.append('')
    lines.append('---')
    lines.append('')

    for d in DAYS:
        lines.append(f'## Day {d["day"]} — {d["cat"]}')
        lines.append('')
        lines.append(f'### 한자 ({len(d["chars"])}자)')
        lines.append('')
        lines.append('| # | 한자 | pinyin | 뜻 |')
        lines.append('|---:|:---:|---|---|')
        for i, ch in enumerate(d['chars'], 1):
            py, ko = get_meta(ch, chars_meta)
            lines.append(f'| {i} | **{ch}** | {py} | {ko} |')
        lines.append('')
        lines.append(f'### 문법 패턴 — {d["grammar"]["title"]}')
        lines.append('')
        for pat, meaning in d['grammar']['patterns']:
            lines.append(f'- `{pat}` — {meaning}')
        lines.append('')
        lines.append(f'> **노트.** {d["grammar"]["note"]}')
        lines.append('')
        lines.append('### 통통 외움 문장 10개')
        lines.append('')
        lines.append('| # | 中文 | pinyin | 한국어 | 사용 상황 |')
        lines.append('|---:|---|---|---|---|')
        for i, (zh, py, ko, sit) in enumerate(d['sentences'], 1):
            lines.append(f'| {i} | **{zh}** | {py} | {ko} | {sit} |')
        lines.append('')
        lines.append(f'### Day {d["day"]} 종료 조건')
        lines.append('')
        lines.append(f'- [ ] 한자 {len(d["chars"])}자 — 보고 한국어 뜻 80% 이상 답함')
        lines.append('- [ ] 통통 문장 10개 — 모두 한국어만 보고 中文 발화 가능')
        lines.append('- [ ] 문법 패턴 — 새 단어로 1문장 응용 가능')
        lines.append('')
        lines.append(f'### 안 끝나면')
        lines.append('')
        lines.append(f'> **"{d["lock_copy"]}"**')
        lines.append('')
        lines.append('---')
        lines.append('')

    lines.append('## 완주 후')
    lines.append('')
    lines.append('216자 + 100문장 + 10 문법 = **L1 완료**.')
    lines.append('이제 진짜 회화 (L2: 350+ 추가 한자 + 채팅 + 데이트 + 일상). 결제 X — 너는 이미 했음 입증.')
    lines.append('')
    return '\n'.join(lines) + '\n'


# ===== JSON generation (for Flutter loader) =====
def gen_json(chars_meta):
    out = {
        'version': 'v1-l1-10day',
        'created': '2026-05-11',
        'description': 'L1 10일 강제 코스 — 216자 (1A+1B+1C+ext-chat) + 100 통통 문장 + 10 문법 패턴',
        'total_chars': 216,
        'total_sentences': 100,
        'days': [],
    }
    for d in DAYS:
        day_obj = {
            'day': d['day'],
            'category': d['cat'],
            'lock_copy': d['lock_copy'],
            'chars': [],
            'grammar': {
                'title': d['grammar']['title'],
                'patterns': [{'pattern': p, 'meaning': m} for p, m in d['grammar']['patterns']],
                'note': d['grammar']['note'],
            },
            'sentences': [],
        }
        for ch in d['chars']:
            meta = chars_meta.get(ch, {})
            py, ko = get_meta(ch, chars_meta)
            day_obj['chars'].append({
                'char': ch,
                'pinyin': py,
                'meaning_ko': ko,
                'tone': meta.get('tone', 0),
                'rank_opus': meta.get('rank_opus', 9999),
                'phase_group': meta.get('phase_group', '?'),
                'hsk_level': meta.get('hsk_char_level', ''),
            })
        for i, (zh, py, ko, sit) in enumerate(d['sentences'], 1):
            day_obj['sentences'].append({
                'idx': i,
                'zh': zh,
                'pinyin': py,
                'ko': ko,
                'situation': sit,
                'audio': f'assets/zh_data/audio/l1_punchy/d{d["day"]}_{i}.mp3',
            })
        out['days'].append(day_obj)
    return out


# ===== TTS generation =====
async def gen_tts(out_dir: Path, manifest_path: Path):
    try:
        import edge_tts
    except ImportError:
        print('[tts] edge_tts not installed, skipping TTS generation')
        return
    out_dir.mkdir(parents=True, exist_ok=True)
    VOICE = 'zh-CN-XiaoxiaoNeural'
    RATE = '-10%'
    sem = asyncio.Semaphore(8)

    async def synth(text, path):
        if path.exists() and path.stat().st_size > 1000:
            return 'skip'
        try:
            comm = edge_tts.Communicate(text, VOICE, rate=RATE)
            await comm.save(str(path))
            return 'ok'
        except Exception as e:
            print(f'  [err] {path.name}: {e}')
            return 'err'

    async def bounded(coro):
        async with sem:
            return await coro

    tasks = []
    l1_punchy_manifest = {}
    for d in DAYS:
        for i, (zh, py, ko, sit) in enumerate(d['sentences'], 1):
            fname = f'd{d["day"]}_{i}.mp3'
            path = out_dir / fname
            # Key by the zh text — unique across all 100 sentences.
            # ZhTtsAssets.findPath(zh, kind: 'l1_punchy') resolves directly.
            l1_punchy_manifest[zh] = f'assets/zh_data/audio/l1_punchy/{fname}'
            tasks.append(bounded(synth(zh, path)))
    print(f'[tts] {len(tasks)} sentences...')
    results = await asyncio.gather(*tasks, return_exceptions=False)
    n_ok = sum(1 for r in results if r == 'ok')
    n_skip = sum(1 for r in results if r == 'skip')
    n_err = sum(1 for r in results if r == 'err')
    print(f'  ok={n_ok}  skip={n_skip}  err={n_err}')

    # Update manifest.json: add files.l1_punchy
    if manifest_path.exists():
        with open(manifest_path, encoding='utf-8') as f:
            mf = json.load(f)
    else:
        mf = {'version': 'v1-edge-tts', 'voice': VOICE, 'files': {}}
    mf.setdefault('files', {})['l1_punchy'] = l1_punchy_manifest
    mf.setdefault('stats', {})['l1_punchy'] = len(l1_punchy_manifest)
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(mf, f, ensure_ascii=False, indent=2)
    print(f'[manifest] updated {manifest_path}')


def main():
    chars_meta = validate()
    md = gen_md(chars_meta)
    Path(OUT_MD).parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_MD, 'w', encoding='utf-8') as f:
        f.write(md)
    print(f'[md] wrote {OUT_MD} ({len(md)} chars)')

    js = gen_json(chars_meta)
    Path(OUT_JSON).parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(js, f, ensure_ascii=False, indent=2)
    print(f'[json] wrote {OUT_JSON}')

    # Optional TTS — only if --tts flag
    if '--tts' in sys.argv:
        asyncio.run(gen_tts(TTS_OUT, MANIFEST))
    else:
        print('[tts] skipped (pass --tts to generate)')


if __name__ == '__main__':
    main()
