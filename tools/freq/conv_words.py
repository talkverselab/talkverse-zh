#!/usr/bin/env python3
"""회화 전 편의 레마 중 빈도표(2,500 단어 DB) 밖에 있으면서 앱 사전(HSK 단어장·보충 단어)에 있는 단어 → 「회화 단어 포함」 목록(2026-11-07, 일본어앱 §1).

  python3 tools/freq/conv_words.py  → assets/data/freq/conv_words_zh.json {words:[{word,pinyin,ko,n}]} (등장 횟수순)
빈도표에 있는 레마는 그 순위 구간에서 보이므로 넣지 않는다. 인물 이름·연출 지시어는 사전에 없어 자연히 빠진다.
"""
import collections, csv, glob, json
freq = {r[1] for r in csv.reader(open('assets/data/freq/lang_zh_with_regions.csv', encoding='utf-8-sig')) if r and r[0] != 'rank'}
lex = {}
for t in json.load(open('assets/data/vocab/hsk_words.json', encoding='utf-8'))['themes']:
    for s in t['sections']:
        for w in s['words']: lex.setdefault(w['zh'], (w.get('rd') or '', w.get('ko') or ''))
for w in json.load(open('assets/data/vocab/conv_extra.json', encoding='utf-8'))['words']:
    lex.setdefault(w['zh'], (w.get('pinyin') or '', w.get('ko') or ''))
cnt = collections.Counter(); pin = {}
for f in glob.glob('assets/data/dialogues/R*/*/*.json'):
    for t in json.load(open(f, encoding='utf-8'))['turns']:
        for lm in t.get('lemmas') or []:
            base = lm[1] if len(lm) > 1 else lm[0]
            if base in freq or base not in lex: continue
            cnt[base] += 1; pin.setdefault(base, lm[2] if len(lm) > 2 else '')
words = [{'word': w, 'pinyin': lex[w][0] or pin.get(w, ''), 'ko': lex[w][1], 'n': n} for w, n in cnt.most_common()]
json.dump({'words': words}, open('assets/data/freq/conv_words_zh.json', 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print('회화 단어(빈도표 밖·사전 있음)', len(words), words[:5])
