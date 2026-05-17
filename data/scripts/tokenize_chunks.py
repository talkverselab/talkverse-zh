# -*- coding: utf-8 -*-
"""문장을 chunk 단위로 토크나이즈 — 知道/喜欢/一个 같은 합성어 보존.

알고리즘: greedy longest-match.
1. cedict 의 multi-char 단어 중 S1+S2 char-set 안에 있는 것 → 청크 vocab
2. 각 문장에 대해 max-match (4→3→2→1 char)
3. 결과: [{chunk: '知道', isCompound: true}, ...]
"""
import csv, json, re, io, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# === S1+S2 char set ===
top = []
with open('assets/data/hanzi/cliff/hanzi_top500_final.txt', encoding='utf-8') as f:
    for line in f:
        parts = line.strip().split('\t')
        if len(parts) >= 2:
            try: top.append((int(parts[0]), parts[1]))
            except: pass
pos_by = {}
with open('assets/data/freq/FINAL_wordset_for_conversation_app.tsv', encoding='utf-8') as f:
    r = csv.DictReader(f, delimiter='\t')
    for row in r:
        if len(row['word']) == 1:
            pos_by.setdefault(row['word'], row['pos'])
FUNC = {'助', '代', '连', '介', '副', '量', '数', '助动', '叹'}
s1a = [c for r, c in top[:50]]
s1b = [c for r, c in top[50:200] if pos_by.get(c, '?') in FUNC]
s2 = [c for r, c in top[50:150] if c not in set(s1b)]
S = set(s1a) | set(s1b) | set(s2)

# === chunk vocab ===
# 1. cedict 에서 multi-char 단어 (S1+S2 한정)
reg = re.compile(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$')
chunk_vocab = {}  # simp → {pinyin, meanings}
with open('assets/data/hsk/cedict.txt', encoding='utf-8') as f:
    for line in f:
        if line.startswith('#') or not line.strip(): continue
        m = reg.match(line.rstrip())
        if not m: continue
        simp = m.group(2)
        if len(simp) < 2 or len(simp) > 4: continue
        if not all(c in S for c in simp): continue
        chunk_vocab.setdefault(simp, {
            'pinyin': m.group(3),
            'meanings': [s.strip() for s in m.group(4).split('/') if s.strip()],
        })

# 2. 일상 회화 청크 보강 (cedict 에 없을 수도)
EXTRA_CHUNKS = {
    '知道': '알다',
    '什么': '무엇',
    '怎么': '어떻게',
    '这样': '이렇게·이런',
    '那样': '저렇게·그렇게',
    '哪里': '어디',
    '这里': '여기',
    '那里': '거기',
    '一下': '잠깐·~좀',
    '一点': '조금',
    '一起': '함께',
    '一样': '같다',
    '一定': '반드시',
    '一次': '한 번',
    '一个': '하나',
    '两个': '둘',
    '这个': '이거',
    '那个': '저거',
    '哪个': '어느 거',
    '没事': '괜찮아',
    '没有': '없다',
    '没问题': '문제없어',
    '真的': '진짜',
    '太多': '너무 많아',
    '太好': '너무 좋아',
    # 不/没/还 + X → 패턴 학습 위해 일부러 분리 (chunk vocab 에서 제외)
    '可以': '가능·OK',
    '可爱': '귀엽다',
    '当然': '당연',
    '因为': '왜냐하면',
    '如果': '만약',
    '所以': '그래서',
    '但是': '그러나',
    '已经': '이미',
    '现在': '지금',
    '自己': '자기',
    '时候': '때',
    '时间': '시간',
    '今天': '오늘',
    '明天': '내일',
    '后天': '모레',
    '前天': '그제',
    '今年': '올해',
    '明年': '내년',
    '昨天': '어제',
    '我们': '우리',
    '你们': '너희',
    '他们': '그들',
    '她们': '그녀들',
    '它们': '그것들',
    '人们': '사람들',
    '孩子': '아이',
    '儿子': '아들',
    '女儿': '딸',
    '妈妈': '엄마',
    '爸爸': '아빠',
    '喜欢': '좋아하다',
    '觉得': '~인 것 같다',
    '告诉': '알리다',
    '看见': '보다·만나다',
    '听见': '듣다',
    '听说': '듣자 하니',
    '说说': '말해봐',
    '看看': '봐봐',
    '想想': '생각해봐',
    '问题': '문제',
    '出来': '나오다',
    '过来': '오다',
    '过去': '지나가다',
    '回来': '돌아오다',
    '回去': '돌아가다',
    '下来': '내려오다',
    '起来': '일어나다',
    '应该': '~해야 한다',
    '需要': '필요하다',
    '关系': '관계',
    '没关系': '괜찮아',
    '一会儿': '잠깐',
    '一点儿': '조금',
    '马上': '곧',
    '是不是': '~지 (확인)',
    '好吗': '좋아?',
    '好的': '좋아',
    '好啊': '오케이',
    '好啦': '됐어',
    '是的': '맞아',
    '是啊': '맞지',
    '是吗': '그래?',
    '行不行': '되니 안 되니',
    '可不可以': '될까',
    '要不要': '할래?',
    '能不能': '될까',
    '为什么': '왜',
    '怎么了': '왜 그래',
    '怎么样': '어때',
    '这就是': '이게 바로',
    '就是': '바로 ~이다',
    '没想到': '생각도 못 했어',
    '想到': '떠올리다',
    '没什么': '별거 아냐',
    '什么的': '~따위',
    '一点点': '아주 조금',
    '一直': '계속',
    # 又 + X 도 분리
    '在哪': '어디',
    '在哪里': '어디에',
    '哪里都': '어디든',
    '谁都': '누구나',
    '什么都': '뭐든',
    # 都/太 + X 도 분리

    '可爱': '귀엽다',
    '看到': '보다',
    '听到': '듣다',
    '想到': '생각나다',
    '回到': '돌아가다',
    '快点': '빨리',
    '快来': '얼른 와',
    '别走': '가지 마',
    '别说': '말하지 마',
    '别看': '보지 마',
    '别想': '꿈도 꾸지 마',
    '说着': '말하면서',
    '看着': '보면서',
    '听着': '들으며',
    '走着': '걸으면서',
    '过着': '지내면서',
    '哪天': '언제',
    '什么时候': '언제',
    '在那里': '거기',
    '到这里': '여기로',
    '到那里': '저기로',
    '为我': '나를 위해',
    '我说啊': '내가 그러잖아',
    '你说啊': '말해봐',
    '哎呀': '아이고',
}
for k, v in EXTRA_CHUNKS.items():
    if len(k) >= 2 and all(c in S for c in k):
        chunk_vocab.setdefault(k, {'pinyin': '', 'meanings': [v]})
        chunk_vocab[k]['ko'] = v

# 부정·범위 부사 + X 분리 정책
# 不/没/还/又/也/都/再/才/就/最/真/太/很 으로 시작하는 합성어는 일반적으로 분리
# (학습자가 부사·부정 기능어를 단독으로 인지하도록)
# 단 강한 idiomatic chunk 는 화이트리스트로 유지
SPLIT_PREFIXES = {'不', '没', '还', '又', '也', '都', '再', '才', '就', '最', '真', '太', '很', '别'}
KEEP_COMPOUND_WHITELIST = {
    '没事', '没问题', '没关系', '没什么', '没想到', '没有',
    '还是',
    '就是', '这就是',
    '当然',  # not 부정·범위지만 ensure 유지
}
to_remove = []
for word in list(chunk_vocab.keys()):
    if len(word) == 1:
        continue
    if word[0] in SPLIT_PREFIXES and word not in KEEP_COMPOUND_WHITELIST:
        to_remove.append(word)
for w in to_remove:
    del chunk_vocab[w]
print(f'split-policy removed: {len(to_remove)} compounds starting with 부사·부정')

# === greedy max-match ===
def tokenize(sentence, max_len=4):
    tokens = []
    i = 0
    n = len(sentence)
    while i < n:
        matched = False
        for L in range(min(max_len, n - i), 1, -1):
            sub = sentence[i:i+L]
            if sub in chunk_vocab:
                tokens.append({'text': sub, 'compound': True})
                i += L
                matched = True
                break
        if not matched:
            tokens.append({'text': sentence[i], 'compound': False})
            i += 1
    return tokens

# === lesson 토크나이즈 (L1 + L2) ===
for lesson_file in ['assets/data/grammar/lesson1.json', 'assets/data/grammar/lesson2.json']:
    try:
        with open(lesson_file, encoding='utf-8') as f:
            lesson = json.load(f)
    except FileNotFoundError:
        print(f'skip {lesson_file} (없음)')
        continue

    for p in lesson['patterns']:
        for e in p['examples']:
            e['tokens'] = tokenize(e['zh'])

    used_chunks = set()
    for p in lesson['patterns']:
        for e in p['examples']:
            for t in e['tokens']:
                if t['compound']:
                    used_chunks.add(t['text'])

    lesson['chunks'] = {
        c: {
            'pinyin': chunk_vocab[c].get('pinyin', ''),
            'meanings': chunk_vocab[c].get('meanings', []),
            'ko': chunk_vocab[c].get('ko'),
        }
        for c in sorted(used_chunks)
    }

    with open(lesson_file, 'w', encoding='utf-8') as f:
        json.dump(lesson, f, ensure_ascii=False, indent=2)

    total_tokens = sum(len(e['tokens']) for p in lesson['patterns'] for e in p['examples'])
    compound_tokens = sum(1 for p in lesson['patterns'] for e in p['examples'] for t in e['tokens'] if t['compound'])
    print(f'\n=== {lesson_file.split("/")[-1]} ===')
    print(f'  used chunks: {len(used_chunks)}')
    print(f'  total tokens: {total_tokens} (compound {compound_tokens}, {compound_tokens/total_tokens*100:.0f}%)')
