# -*- coding: utf-8 -*-
"""travel_words/expressions의 rd(한글독음) → 성조 병음으로 교체."""
import json, re
from pypinyin import pinyin, Style

def toned(zh):
    # 한자 구간만 병음, 나머지(~, 숫자, 문장부호)는 그대로
    out = []
    buf = ''
    for ch in zh:
        if '一' <= ch <= '鿿':
            buf += ch
        else:
            if buf:
                out.append(' '.join(x[0] for x in pinyin(buf, style=Style.TONE)))
                buf = ''
            out.append(ch)
    if buf:
        out.append(' '.join(x[0] for x in pinyin(buf, style=Style.TONE)))
    s = ''.join(out)
    return re.sub(r'\s+', ' ', s).strip()

for path in ('assets/data/vocab/travel_words.json',
             'assets/data/vocab/travel_expressions.json'):
    d = json.load(open(path, encoding='utf-8'))
    n = 0
    for t in d['themes']:
        for s in t['sections']:
            for w in s['words']:
                if w.get('zh'):
                    w['rd'] = toned(w['zh'])
                    n += 1
    json.dump(d, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(path, n, '항목 변환')
