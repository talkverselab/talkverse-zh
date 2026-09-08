"""HSK 3.0 1~5급 단어 → assets/data/vocab/hsk_words.json (topic_vocab 형식).

입력: scratchpad/hsk_prepared.json (단어·병음·레벨), hsk_ko_seed.json (앱 기존 ko),
      hsk_ko_batch_*.json (에이전트 생성 ko·ic)
테마 = 급수, 섹션 = 빈도순 50개 묶음.
"""
import json, glob, sys, io, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
SP = r'C:\Users\Johnjeon\AppData\Local\Temp\claude\C--Users-Johnjeon-talkverse-zh\0f30ac9b-148d-43f6-97b2-e93497af23d0\scratchpad'
OUT = r'C:\Users\Johnjeon\talkverse\zh\assets\data\vocab\hsk_words.json'

prep = json.load(open(f'{SP}\\hsk_prepared.json', encoding='utf-8'))
words = prep['words']
seed = json.load(open(f'{SP}\\hsk_ko_seed.json', encoding='utf-8'))
gen = {}
for f in sorted(glob.glob(f'{SP}\\hsk_ko_batch_*.json')):
    try:
        d = json.load(open(f, encoding='utf-8'))
    except Exception as e:
        print('BAD', f, e)
        continue
    for w, v in d.items():
        if isinstance(v, dict) and v.get('ko'):
            gen[w] = v
print('generated', len(gen), 'seed', len(seed), 'words', len(words))

POS_IC = {'v': '🏃', 'n': '📦', 'a': '✨', 'd': '➡️', 'm': '🔢', 'q': '📏', 'r': '👤', 'c': '🔗', 'p': '📍', 'u': '💬', 'y': '💬', 'e': '❗', 't': '⏰', 'f': '🧭'}
LV_EMOJI = {1: '1️⃣', 2: '2️⃣', 3: '3️⃣', 4: '4️⃣', 5: '5️⃣'}
missing = []
by_lv = {i: [] for i in range(1, 6)}
for w, v in words.items():
    g = gen.get(w, {})
    ko = g.get('ko') or seed.get(w)
    if not ko:
        missing.append(w)
        ko = ' / '.join(v['en'][:2])  # 임시 영어
    ic = g.get('ic') or POS_IC.get((v['pos'] or ['n'])[0][:1], '📚')
    by_lv[v['lv']].append({'ko': ko, 'zh': w, 'rd': v['py'].lower(), 'ic': ic, '_f': v['freq'] or 999999})

themes = []
for lv in range(1, 6):
    lst = sorted(by_lv[lv], key=lambda x: x['_f'])
    for x in lst:
        x.pop('_f')
    sections = []
    for i in range(0, len(lst), 50):
        sections.append({'title': f'{lv}급 {i // 50 + 1:02d} ({i + 1}~{min(i + 50, len(lst))})', 'words': lst[i:i + 50]})
    themes.append({'id': f'hsk{lv}', 'title': f'HSK {lv}급 ({len(lst)})', 'emoji': LV_EMOJI[lv], 'sections': sections})

json.dump({'_meta': 'HSK 3.0 1~5급 단어 — 출처 complete-hsk-vocabulary(MIT), 한국어 뜻 생성 2026-09-08', 'themes': themes},
          open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('written', sum(len(t['sections'][0]['words']) and sum(len(s['words']) for s in t['sections']) for t in themes), 'missing ko', len(missing), ''.join(missing[:30]))
