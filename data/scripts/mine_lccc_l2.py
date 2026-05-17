# -*- coding: utf-8 -*-
"""LCCC 실제 챗 데이터에서 L2 문장 채굴.

흐름:
1. 209자 char set 로드 (S1+S2+Stage3, hanzi_stages.json)
2. LCCC dialogue 모두 순회 → 209자 안 문장만 필터
3. 각 token (어기조사/부사/단어) 별로 매칭 문장 인덱싱
4. quality 점수 + 다양성 → 패턴별 top 3 추출
"""
import gzip, json, re, sys, io, random, csv
from collections import defaultdict, Counter
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# === 1. 209-char set ===
with open('assets/data/hanzi/hanzi_stages.json', encoding='utf-8') as f:
    stages = json.load(f)
char_set = set()
for s in stages['stages']:
    for c in s['chars']:
        char_set.add(c['char'])
print(f'209-char set: {len(char_set)}')

# 허용 문장부호 (filter 통과)
PUNCT = set('，。！？、…—-")(《》「」"' + "" + " 　,.!?:;\"'()/")
ALLOWED = char_set | PUNCT

# === 2. LCCC dialogues 처리 ===
SRC_FILES = [
    r'D:/OneDrive/DATA_Raw/languages/zh/chat/silver__lccc/lccc_base_test.jsonl.gz',
    r'D:/OneDrive/DATA_Raw/languages/zh/chat/silver__lccc/lccc_base_valid.jsonl.gz',
]

def strip_spaces(s):
    return re.sub(r'\s+', '', s)

def is_cjk(c):
    if not c: return False
    code = ord(c)
    return 0x4E00 <= code <= 0x9FFF

def in_charset(s):
    """모든 한자가 209 set 안인지"""
    for c in s:
        if is_cjk(c) and c not in char_set:
            return False
    return True

def quality_score(s):
    """문장 quality — 길이 5-15, 특수문자 적음, 반복 없음."""
    n = len(s)
    if n < 4 or n > 18: return 0
    # 특수문자 비율
    cjk_count = sum(1 for c in s if is_cjk(c))
    if cjk_count < 3: return 0
    # 글자 반복 (같은 글자 5+회) 페널티
    cnt = Counter(s)
    if any(v >= 5 for v in cnt.values()): return 0
    # 한자 비율
    cjk_ratio = cjk_count / n
    if cjk_ratio < 0.5: return 0
    # 길이 5-12 가 sweet spot
    if 5 <= n <= 12:
        length_score = 1.0
    elif n <= 15:
        length_score = 0.8
    else:
        length_score = 0.5
    return length_score * cjk_ratio

# 모든 매칭 문장 수집
all_sents = []
for src in SRC_FILES:
    cnt = 0
    with gzip.open(src, 'rt', encoding='utf-8') as f:
        for line in f:
            try:
                turns = json.loads(line)
            except: continue
            for t in turns:
                s = strip_spaces(t)
                if not s or not in_charset(s): continue
                q = quality_score(s)
                if q < 0.6: continue
                all_sents.append((s, q))
            cnt += 1
    print(f'{src.split("/")[-1]}: {cnt:,} dialogues processed')

# dedup
seen = set()
unique = []
for s, q in all_sents:
    if s in seen: continue
    seen.add(s)
    unique.append((s, q))
print(f'unique L2 candidates (209-char filter pass): {len(unique):,}')

# === 3. 토큰별 인덱싱 ===
# 14 어기조사
PARTICLES = ['啊', '吗', '吧', '呀', '呢', '啦', '嗯', '哦', '哪', '嘛', '喂', '嘿', '嗨', '咯']

# 22 부사 (S1+S2+Stage3 안)
ADVERBS = ['很', '真', '太', '最', '都', '也', '还', '又', '再', '已', '先', '常', '更',
          '只', '别', '快', '多', '当然', '马上', '一直', '永远', '从来']

# 50 필수 단어 (단어 단위 — FINAL_wordset 의 A_essential 상위 + 209자 안)
FINAL_words = []
with open('assets/data/freq/FINAL_wordset_for_conversation_app.tsv', encoding='utf-8') as f:
    r = csv.DictReader(f, delimiter='\t')
    for row in r:
        w = row['word']
        tier = row.get('tier', '')
        if not (2 <= len(w) <= 4): continue
        if not all((not is_cjk(c)) or c in char_set for c in w): continue
        if tier.startswith('A_essential'):
            FINAL_words.append((w, int(row.get('opus_rank', 9999))))
FINAL_words.sort(key=lambda x: x[1])
ESSENTIAL = [w for w, _ in FINAL_words[:60]]  # top 60 → 50 select 후

# 추가 idiomatic 단어
EXTRA_WORDS = [
    '知道', '不知道', '喜欢', '想要', '觉得', '认识', '希望',
    '一起', '一定', '马上', '现在', '以后', '一直', '一会',
    '不行', '不用', '不要', '不会', '可以',
    '什么', '怎么', '哪里', '这样', '那样', '怎样',
    '没事', '没问题', '真的', '当然', '应该',
]

# 우선 어떤 단어들이 실제 LCCC 에 자주 등장하는지 측정
word_freq = Counter()
for s, q in unique:
    for w in ESSENTIAL + EXTRA_WORDS:
        if w in s:
            word_freq[w] += 1

# === 4. 패턴 정의 ===
categories = []
# 어기조사 14
for p in PARTICLES:
    categories.append(('particle', p, f'어기조사 {p}'))
# 부사 22
for a in ADVERBS:
    categories.append(('adverb', a, f'부사 {a}'))
# 필수 단어 (LCCC 실측 빈도순)
top_essential = [w for w, c in word_freq.most_common(60) if c >= 10]
print(f'\nLCCC 실측 빈도 상위 필수 단어 (≥10회 등장):')
for w in top_essential[:30]:
    print(f'  {w}: {word_freq[w]}회')

# 50 선정
TARGET_WORDS = top_essential[:50]
for w in TARGET_WORDS:
    categories.append(('word', w, f'필수 단어 {w}'))

print(f'\n총 카테고리: {len(categories)} (어기조사 {len(PARTICLES)} + 부사 {len(ADVERBS)} + 단어 {len(TARGET_WORDS)})')

# === 5. 각 카테고리당 매칭 문장 3개 추출 ===
random.seed(42)
matches_per_cat = {}
for kind, token, label in categories:
    matched = [(s, q) for s, q in unique if token in s]
    # quality 기준 top 30 → 다양성 확보 위해 길이 분산 + length 5-12 우선
    matched.sort(key=lambda x: -x[1])
    pool = matched[:30]
    random.shuffle(pool)
    picked = pool[:3]
    matches_per_cat[(kind, token)] = picked

# === 6. 통계 출력 ===
print('\n=== 매칭 카운트 (각 카테고리 매칭 문장 후보 수) ===')
for kind, token, label in categories[:20]:
    cnt = sum(1 for s, q in unique if token in s)
    print(f'  [{kind:8}] {token:6}  → {cnt:,}개 후보')

# === 7. 출력 ===
out = {
    'lesson': 2,
    'title': 'L2 — 어기조사·부사·필수단어 (실제 챗 기반)',
    'subtitle': f'LCCC 실측 + 209자 필터 / {len(categories)} 카테고리 × 3 = {len(categories)*3} 문장',
    'data_source': 'LCCC test + valid sets (silver), 209-char filter',
    'char_set_size': len(char_set),
    'categories': []
}
for kind, token, label in categories:
    examples = matches_per_cat.get((kind, token), [])
    out['categories'].append({
        'kind': kind,
        'key': token,
        'label': label,
        'examples_raw': [{'zh': s, 'quality': round(q, 3)} for s, q in examples],
    })

with open('assets/data/grammar/lesson2_raw.json', 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print(f'\n→ assets/data/grammar/lesson2_raw.json saved ({len(out["categories"])} categories)')
print(f'   다음: pinyin/ko 추가 + quality review')
