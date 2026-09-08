"""HSK 3.0 1~5급 한자 1,500 → 회화 빈도순 5단계(300자) × 15소단계(20자) JSON.

입력
- assets/data/hanzi/hanzi_ko.json           HSK1-5 한자 한국 훈음 (1,499) + 入
- assets/data/hanzi/cliff/hanzi_score_final.tsv  회화 코퍼스 점수·순위·hsk_char_level
- assets/data/hanzi/hanzi_stages.json       기존 209자 뜻(있으면 우선)
- assets/data/hsk/cedict.txt                병음(번호 성조)
출력
- assets/data/hanzi/hanzi_hsk1500.json
"""
import json, re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = r'C:\Users\Johnjeon\talkverse\zh\assets\data'

ko = json.load(open(f'{ROOT}\\hanzi\\hanzi_ko.json', encoding='utf-8'))
ko.pop('_meta', None)

rank, score, level = {}, {}, {}
for i, line in enumerate(open(f'{ROOT}\\hanzi\\cliff\\hanzi_score_final.tsv', encoding='utf-8')):
    if i == 0:
        continue
    p = line.rstrip('\n').split('\t')
    rank[p[1]], score[p[1]], level[p[1]] = int(p[0]), int(p[2]), p[6]

target = {c for c, l in level.items() if l in ('HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5')}
print('score file HSK1-5 chars:', len(target), ' hanzi_ko:', len(ko))
print('  in ko not target:', ''.join(sorted(set(ko) - target)), ' in target not ko:', ''.join(sorted(target - set(ko))))
target |= set(ko)
target = {c for c in target if c in rank}

old = json.load(open(f'{ROOT}\\hanzi\\hanzi_stages.json', encoding='utf-8'))
old_meaning = {c['char']: c['meaning'] for s in old['stages'] for c in s['chars']}

# cedict: 단일 한자 첫 병음
py = {}
for line in open(f'{ROOT}\\hsk\\cedict.txt', encoding='utf-8'):
    if line.startswith('#'):
        continue
    m = re.match(r'^(\S+) (\S+) \[([^\]]+)\] /', line)
    if not m:
        continue
    simp, p = m.group(2), m.group(3)
    if len(simp) == 1 and simp in target and simp not in py and not p[0].isupper():
        py[simp] = p
for c in target:
    py.setdefault(c, '')

ranked = sorted(target, key=lambda c: rank[c])
total = sum(score.values())
PHASE, SUB = 300, 20
phases = []
cum = 0
stages = []
for pi in range(5):
    chunk = ranked[pi * PHASE:(pi + 1) * PHASE]
    for si in range(0, len(chunk), SUB):
        sub = chunk[si:si + SUB]
        cum += sum(score[c] for c in sub)
        stages.append({
            'stage': len(stages) + 1,
            'phase': pi + 1,
            'coverage_pct': round(cum / total * 100, 2),
            'chars': [{'char': c, 'meaning': old_meaning.get(c, ko.get(c, '')),
                       'pinyin_raw': py[c], 'hsk': level.get(c, ''), 'rank': rank[c]} for c in sub],
        })
    phases.append({'phase': pi + 1, 'from': pi * PHASE + 1, 'to': min((pi + 1) * PHASE, len(ranked)),
                   'coverage_pct': round(cum / total * 100, 2)})
    print(f'phase {pi + 1}: chars {pi * PHASE + 1}-{min((pi + 1) * PHASE, len(ranked))}  cum coverage {cum / total * 100:.2f}%')

out = {
    'title': 'HSK 1~5급 한자 1500',
    'subtitle': '회화 빈도순 5단계 × 300자 · 20자 소단계 · 4지선다 (누적)',
    'total': len(ranked),
    'phases': phases,
    'stages': stages,
}
json.dump(out, open(f'{ROOT}\\hanzi\\hanzi_hsk1500.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
empty = [c for c in ranked if not (old_meaning.get(c) or ko.get(c))]
print('stages', len(stages), 'chars', len(ranked), 'no-meaning', len(empty), ''.join(empty), 'no-pinyin', sum(1 for c in ranked if not py[c]))
