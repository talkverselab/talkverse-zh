"""
Tag each char with phase_group: '1A' | '1B' | '1C' based on rank_opus.

Phase split (마케팅 100→50→50):
  * 1A: rank 1-100   (핵심 100, Day 1-10)
  * 1B: rank 101-150 (추가 50, Day 11-15)
  * 1C: rank 151-209 (마지막 50, Day 16-20) + 어기조사 嗯·嘛 추가

In-place update.
"""
import json

PATH = 'C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json'
SRC  = 'D:/OneDrive/PROJECT/talkverse-learning/ZH/Word/core_hanzi_209.json'

def tag(d):
    chars = d.get('characters', [])
    for c in chars:
        rank = c.get('rank_opus', 9999)
        if rank <= 100:
            c['phase_group'] = '1A'
        elif rank <= 150:
            c['phase_group'] = '1B'
        else:
            c['phase_group'] = '1C'
    # stats
    counts = {}
    for c in chars:
        p = c['phase_group']
        counts[p] = counts.get(p, 0) + 1
    return counts

for p in [PATH, SRC]:
    with open(p, encoding='utf-8') as f:
        d = json.load(f)
    counts = tag(d)
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
    print(f"[done] {p}")
    print(f"  {counts}")
