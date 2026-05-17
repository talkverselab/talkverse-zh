# -*- coding: utf-8 -*-
"""LCCC 멀티턴 다이얼로그 채굴 — 209자 필터 + quality 점수."""
import gzip, json, re, sys, io
from collections import Counter
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# 1. 209-char set
with open('assets/data/hanzi/hanzi_stages.json', encoding='utf-8') as f:
    stages = json.load(f)
char_set = set()
for s in stages['stages']:
    for c in s['chars']:
        char_set.add(c['char'])

PUNCT = set('，。！？、…—-")(《》「」"' + "" + " 　,.!?:;\"'()/~")

def strip_spaces(s):
    return re.sub(r'\s+', '', s)

def is_cjk(c):
    if not c: return False
    code = ord(c)
    return 0x4E00 <= code <= 0x9FFF

def in_charset(s):
    for c in s:
        if is_cjk(c) and c not in char_set:
            return False
    return True

def turn_quality(s):
    n = len(s)
    if n < 3 or n > 16: return 0
    cjk = sum(1 for c in s if is_cjk(c))
    if cjk < 2: return 0
    cnt = Counter(s)
    if any(v >= 5 for v in cnt.values()): return 0
    cjk_ratio = cjk / n
    if cjk_ratio < 0.5: return 0
    if 4 <= n <= 12:
        return cjk_ratio
    return cjk_ratio * 0.7

SRC_FILES = [
    r'D:/OneDrive/DATA_Raw/languages/zh/chat/silver__lccc/lccc_base_test.jsonl.gz',
    r'D:/OneDrive/DATA_Raw/languages/zh/chat/silver__lccc/lccc_base_valid.jsonl.gz',
]

candidates = []
total_dialogs = 0
for src in SRC_FILES:
    with gzip.open(src, 'rt', encoding='utf-8') as f:
        for line in f:
            try:
                turns_raw = json.loads(line)
            except: continue
            total_dialogs += 1
            # 2-5턴만 사용
            if len(turns_raw) < 2 or len(turns_raw) > 5: continue
            turns = []
            ok = True
            for t in turns_raw:
                s = strip_spaces(t)
                if not s or not in_charset(s):
                    ok = False; break
                q = turn_quality(s)
                if q < 0.55:
                    ok = False; break
                turns.append((s, q))
            if not ok or not turns: continue
            # 다이얼로그 quality = 평균 turn quality
            avg_q = sum(q for _, q in turns) / len(turns)
            if avg_q < 0.65: continue
            # 중복 발화 회피
            seen = set()
            unique_in_dlg = True
            for s, _ in turns:
                if s in seen: unique_in_dlg = False; break
                seen.add(s)
            if not unique_in_dlg: continue
            candidates.append({
                'turns': [s for s, _ in turns],
                'avg_q': avg_q,
                'turn_count': len(turns),
            })

print(f'LCCC dialogue 총 {total_dialogs:,} 처리')
print(f'209자 + quality 필터 통과: {len(candidates):,}')

# 전체 중복 회피
seen_first_turn = set()
unique_candidates = []
for c in candidates:
    first = c['turns'][0]
    if first in seen_first_turn: continue
    seen_first_turn.add(first)
    unique_candidates.append(c)
print(f'first-turn unique: {len(unique_candidates):,}')

# quality 정렬
unique_candidates.sort(key=lambda x: (-x['avg_q'], x['turn_count']))

# 출력
out = {
    'data_source': 'LCCC silver test+valid · 209-char filter · quality≥0.65',
    'total_processed': total_dialogs,
    'total_candidates': len(unique_candidates),
    'char_set_size': len(char_set),
    'top200': unique_candidates[:200],
}
with open('assets/data/dialogues/lccc_top200.json', 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print(f'→ assets/data/dialogues/lccc_top200.json 저장')

# 샘플 출력
print('\n=== top 20 샘플 ===')
for i, c in enumerate(unique_candidates[:20]):
    print(f'\n[{i+1}] turns={c["turn_count"]}, q={c["avg_q"]:.2f}')
    for j, t in enumerate(c['turns']):
        speaker = 'A' if j % 2 == 0 else 'B'
        print(f'   {speaker}: {t}')
