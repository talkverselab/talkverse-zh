#!/usr/bin/env python3
"""편 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 병음]) 를 채운다 — 문장 레마 ↔ 단어장 연결(사용자 지시 2026-11-04, 일본어앱 tools/add_lemmas.py 의 중국어판).

- 분석기 jieba(품사 태깅) + 읽기 pypinyin(성조 부호 병음). 중국어는 굴절이 없어 표면형 = 기본형이 대부분이고,
  수사+양사(一张)는 표면형 一张 · 기본형 张 으로 둔다.
- 제외: 문장부호·조사(的 了 着 吗 吧 呢 …)·접속사·전치사·감탄사·한 글자 대명사(我 你 这 那 …)·숫자·로마자·화자 이름.
- 멱등: 이미 있어도 다시 계산해 덮어쓴다(다른 세션이 R1 JSON 을 계속 고치므로 마지막에 한 번 더 돌릴 것). `lemmas` 외 필드는 손대지 않는다.
- 단어장(freq CSV + hsk_words.json + 한자 단계표 = 앱 LexiconService ∪ words 표)에 없는 레마는 빈도순으로
  data/review/lemmas_missing.csv 에 내보낸다(uk 세션에 넘겨 단어·그림 제작).

  ~/.venvs/zh/bin/python tools/add_lemmas.py            # 전체(R*/*/*.json)
  ~/.venvs/zh/bin/python tools/add_lemmas.py <편.json>…  # 지정 파일만(CSV 는 그래도 전체 기준으로 다시 씀)
"""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path

import jieba
import jieba.posseg as pseg
from pypinyin import Style, pinyin

jieba.setLogLevel(60)
ROOT = Path(__file__).resolve().parent.parent
VAR = re.compile(r'\{[a-z_]+\}')
HAN = re.compile(r'[一-鿿]')
NUM = set('〇零一二三四五六七八九十两百千万亿几半0123456789')
SKIP_POS = {'x', 'w', 'u', 'uj', 'ul', 'ud', 'uz', 'uv', 'ug', 'y', 'e', 'o', 'c', 'p', 'nr', 'eng'}
SKIP_SURF = {'的', '了', '着', '过', '吗', '吧', '呢', '啊', '呀', '哦', '嗯', '哈', '哎', '诶', '嘛', '啦', '喔', '欸', '呃', '唉', '哇'}
PRON1 = set('我你他她它您咱俺')  # 한 글자 대명사는 뺀다(谁·这·那 같은 지시·의문은 남김)


def load_db():
    db = set()
    with open(ROOT / 'assets/data/freq/lang_zh_with_regions.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            db.add(row['word'].strip())
    try:
        j = json.load(open(ROOT / 'assets/data/vocab/hsk_words.json', encoding='utf-8'))
        for t in j['themes']:
            for s in t['sections']:
                for w in s['words']:
                    db.add(w['zh'])
    except Exception:
        pass
    for a in ('assets/data/hanzi/hanzi_stages.json', 'assets/data/hanzi/hanzi_hsk1500.json'):
        try:
            j = json.load(open(ROOT / a, encoding='utf-8'))
            for st in j['stages']:
                for c in st['chars']:
                    db.add(c['char'])
        except Exception:
            pass
    return db


def rd(word):
    return ' '.join(x[0] for x in pinyin(word, style=Style.TONE))


def keep(w, pos):
    if not HAN.search(w) or pos in SKIP_POS or w in SKIP_SURF:
        return False
    if pos == 'r' and len(w) == 1 and w in PRON1:
        return False
    return not all(c in NUM for c in w)


def split_known(w, db):
    """단어장에 없는 덩어리(吃火锅·太好了·你家)를 단어장 단어로 다시 나눈다(앞에서부터 가장 긴 것). 못 나누면 None."""
    parts, i = [], 0
    while i < len(w):
        for n in range(len(w) - i, 0, -1):
            if w[i:i + n] in db:
                parts.append(w[i:i + n]); i += n; break
        else:
            return None
    return parts if len(parts) > 1 else None


def lemmas_of(text, names, db):
    out = []
    for tok in pseg.lcut(VAR.sub(' ', text)):
        w, pos = tok.word, tok.flag
        if w in names or not keep(w, pos):
            continue
        if w in db:
            out.append([w, w, rd(w)])
            continue
        if pos == 'm':  # 수사+양사(一张) → 양사(张)만 기본형으로
            base = w.lstrip(''.join(NUM))
            if base and HAN.search(base):
                out.append([w, base, rd(base)])
            continue
        stripped = w.rstrip(''.join(SKIP_SURF))  # 好呀 → 好, 走吧 → 走
        if stripped and stripped != w and stripped in db:
            out.append([w, stripped, rd(stripped)])
            continue
        parts = split_known(w, db)
        if parts:
            for p in parts:
                ppos = next((t.flag for t in pseg.lcut(p)), 'n')
                if p not in PRON1 and keep(p, ppos):
                    out.append([p, p, rd(p)])
            continue
        out.append([w, w, rd(w)])
    return out


def main(argv):
    files = argv or sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')))
    db = load_db()
    miss, ex, tot, hit, changed = Counter(), {}, 0, 0, 0
    for f in files:
        d = json.load(open(f, encoding='utf-8'))
        names = {VAR.sub('', v) for v in (d.get('speakers') or {}).values()} - {''}
        for n in names:
            jieba.add_word(n)
        ch = False
        for t in d.get('turns', []):
            out = lemmas_of(t.get('zh', ''), names, db)
            for _, b, _ in out:
                tot += 1
                if b in db:
                    hit += 1
                else:
                    miss[b] += 1
                    ex.setdefault(b, (rd(b), t.get('zh', '')))
            if t.get('lemmas') != out:
                t['lemmas'] = out
                ch = True
        if ch:
            with open(f, 'w', encoding='utf-8') as fo:
                fo.write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
            changed += 1
    if not argv:
        out_csv = ROOT / 'data/review/lemmas_missing.csv'
        out_csv.parent.mkdir(parents=True, exist_ok=True)
        with open(out_csv, 'w', encoding='utf-8', newline='') as fo:
            w = csv.writer(fo)
            w.writerow(['lemma', 'pinyin', 'count', 'example'])
            for b, n in miss.most_common():
                w.writerow([b, ex[b][0], n, ex[b][1]])
    print(f'편 {len(files)}(바뀜 {changed}) · 내용어 {tot} · 단어장 있음 {hit / max(tot, 1):.0%} · 없는 레마 {len(miss)}'
          + ('' if argv else ' → data/review/lemmas_missing.csv'))


if __name__ == '__main__':
    main(sys.argv[1:])
