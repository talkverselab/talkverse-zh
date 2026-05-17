# -*- coding: utf-8 -*-
"""LCCC top dialogue → 회화 화면용 JSON (수작업 한국어 번역).

각 dialogue 한국어 의역 + 카테고리 부여.
"""
import json, csv, re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# LCCC 상위 dialogue 에 한국어 번역 + 카테고리 manual 부여
# 형식: (category, [(zh, ko), ...])
DIALOGUES = [
    ('love', [
        ('我知道你又在想我了', '또 내 생각하지?'),
        ('被你发现了', '들켰네.'),
    ]),
    ('love', [
        ('我爱你啊可爱可爱可爱', '사랑해 귀여워 귀여워 귀여워.'),
        ('我也喜欢你哦', '나도 너 좋아해~'),
    ]),
    ('love', [
        ('我想你了', '너 보고 싶어.'),
        ('我想他了很想很想', '나는 걔가 너무너무 보고 싶어.'),
    ]),
    ('daily', [
        ('你怎么还没回家', '왜 아직 집 안 갔어?'),
        ('快了快了', '곧 가 곧 가.'),
    ]),
    ('daily', [
        ('我一直在这里等你', '계속 여기서 기다리고 있어.'),
        ('你在哪里', '너 어디야?'),
    ]),
    ('daily', [
        ('回家了啊你家', '집 갔어? 너네 집?'),
        ('嗯啊回来了', '응 왔어.'),
    ]),
    ('joke', [
        ('你想干嘛', '뭐 하려고?'),
        ('你说我想干嘛', '내가 뭘 하고 싶을까~?'),
    ]),
    ('joke', [
        ('带我一个', '나도 데려가~'),
        ('带你上天', '하늘로 데려가줄게.'),
    ]),
    ('joke', [
        ('我不说话', '나 말 안 해.'),
        ('你已经说话了', '이미 말했잖아.'),
    ]),
    ('joke', [
        ('生一个生一个', '하나 낳자 하나 낳자.'),
        ('你想说什么', '뭔 소리야.'),
    ]),
    ('food', [
        ('上次带我吃的怎么不是这种', '지난번 데려간 데는 이런 거 아니었잖아.'),
        ('好好好下次带你来吃这种', '알았어 다음에 이런 데 데려갈게.'),
    ]),
    ('compliment', [
        ('可爱了你', '너 귀엽잖아.'),
        ('所以不是我的错', '그러니까 내 잘못 아니야.'),
    ]),
    ('compliment', [
        ('你是最好的', '넌 최고야.'),
        ('今天干嘛去了', '오늘 뭐 했어?'),
    ]),
    ('reunion', [
        ('啊两年不见', '아 2년만이네.'),
        ('是不是感觉很快', '엄청 빠르지?'),
    ]),
    ('chat', [
        ('又一个有生之年', '평생만에 또 만나는 친구네.'),
        ('还有哪个吗', '또 누구 있어?'),
    ]),
    ('chat', [
        ('我来了我来了', '왔어 왔어~'),
        ('好啊跟我走', '오케이 따라와.'),
    ]),
    ('chat', [
        ('有没有我', '내 자리 있어?'),
        ('都有都有', '있어 있어.'),
    ]),
    ('chat', [
        ('要记住你', '기억해 둘게.'),
        ('我已经记住你啦', '나는 이미 기억했어~'),
    ]),
    ('miss', [
        ('我该说点什么呢', '뭐라고 말해야 할까?'),
        ('你说什么都爱你', '뭘 말하든 사랑해.'),
    ]),
    ('phone', [
        ('给个电话', '전화 줘.'),
        ('我也还没有', '나도 아직.'),
    ]),
]

# pinyin 자동 (cedict)
reg = re.compile(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$')
cedict = {}
with open('assets/data/hsk/cedict.txt', encoding='utf-8') as f:
    for line in f:
        if line.startswith('#') or not line.strip(): continue
        m = reg.match(line.rstrip())
        if not m: continue
        cedict.setdefault(m.group(2), m.group(3))

# pinyin number → toned
PINYIN_MARKS = {
    'a': ['ā','á','ǎ','à'], 'e': ['ē','é','ě','è'],
    'i': ['ī','í','ǐ','ì'], 'o': ['ō','ó','ǒ','ò'],
    'u': ['ū','ú','ǔ','ù'], 'ü': ['ǖ','ǘ','ǚ','ǜ'],
}
def syl_to_toned(syl):
    syl = syl.replace('u:', 'ü')
    m = re.match(r'^([A-Za-zü]+)(\d)$', syl)
    if not m: return syl
    letters = m.group(1); tone = int(m.group(2))
    if tone < 1 or tone > 4: return letters
    l = letters.lower()
    idx = -1
    for ch in ['a','e','o']:
        if ch in l: idx = l.index(ch); break
    if idx < 0:
        for i in range(len(l)-1, -1, -1):
            if l[i] in 'iouü': idx = i; break
    if idx < 0: return letters
    ch = letters[idx]
    marked = PINYIN_MARKS.get(ch.lower(), [ch]*4)[tone-1]
    if ch.isupper(): marked = marked.upper()
    return letters[:idx] + marked + letters[idx+1:]

def to_pinyin(s):
    # 각 한자 lookup, 단어 단위 매칭 시도
    out = []
    i = 0
    while i < len(s):
        ch = s[i]
        if not (0x4E00 <= ord(ch) <= 0x9FFF):
            i += 1
            continue
        # 2글자, 1글자 lookup
        found = None
        for L in (3, 2, 1):
            if i + L <= len(s) and s[i:i+L] in cedict:
                found = (s[i:i+L], cedict[s[i:i+L]])
                break
        if found:
            word, py = found
            syls = py.split(' ')
            out.append(' '.join(syl_to_toned(p) for p in syls))
            i += len(word)
        else:
            out.append(ch)
            i += 1
    return ' '.join(out)

# 카테고리 라벨 (한국어)
CAT_LABELS = {
    'love': '💕 사랑',
    'daily': '🏠 일상',
    'joke': '😏 농담·티키타카',
    'food': '🍱 음식',
    'compliment': '✨ 칭찬',
    'reunion': '👋 재회',
    'chat': '💬 친구톡',
    'miss': '🥺 그리움',
    'phone': '📞 연락',
}

out_data = {
    'title': '진짜 회화 — LCCC 친구톡',
    'subtitle': '실제 중국인 SNS 챗에서 채굴 · 209자 안',
    'data_source': 'LCCC silver test+valid (Weibo 친구 대화)',
    'categories': sorted(set(c for c, _ in DIALOGUES)),
    'category_labels': CAT_LABELS,
    'dialogues': [],
}

for i, (cat, turns) in enumerate(DIALOGUES):
    out_data['dialogues'].append({
        'id': f'lccc_{i+1:03d}',
        'category': cat,
        'category_label': CAT_LABELS.get(cat, cat),
        'turns': [
            {
                'speaker': 'A' if j % 2 == 0 else 'B',
                'zh': zh,
                'pinyin': to_pinyin(zh),
                'ko': ko,
            }
            for j, (zh, ko) in enumerate(turns)
        ],
    })

with open('assets/data/dialogues/conv_lccc.json', 'w', encoding='utf-8') as f:
    json.dump(out_data, f, ensure_ascii=False, indent=2)

print(f'dialogue 수: {len(out_data["dialogues"])}')
print(f'turn 수: {sum(len(d["turns"]) for d in out_data["dialogues"])}')
print(f'→ assets/data/dialogues/conv_lccc.json saved')

# 카테고리 분포
from collections import Counter
cnt = Counter(d['category'] for d in out_data['dialogues'])
print('\n카테고리 분포:')
for c, n in cnt.most_common():
    print(f'  {CAT_LABELS.get(c, c):12} {n}')
