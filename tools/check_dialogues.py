#!/usr/bin/env python3
"""중국어 새 회화(편 JSON) 검사기 — 회화 공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/ + docs/DIALOGUE_RULES_zh.md (2026-11-03).

  python3 tools/check_dialogues.py [--vocab] assets/data/dialogues/R1/**/*.json

검사: 턴 수(구간) · 턴 길이(한자 수) · 구간 어휘(참고 — 주의만)(R1 = 회화 빈도 433위 안 단어 + 앞 편에서 나온 단어, 밖은 편당 2개까지·note 에 뜻) ·
새 단어/턴 ≤3 · 반전 twist·twist_type · 한글 독음 rd(한글만) · 병음 음절 수 = 한자 수 · 변수 · 금지어 · 묶음별 chaos 비율 ≥ 30%.
rd 는 `dart run tool/fill_rd.dart <파일>` 로 채운다. 오류가 있으면 종료 코드 1.
"""
import csv, glob, json, re, sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# 구간 어휘 = 회화 단어표(자막 빈도 corpus_rank · 채팅 빈도 chat_rank 중 작은 순위)로 R1 ≤433 · R2 ≤616 · R3 ≤1238 · R4 ≤2500.
# lang_zh_with_regions.csv 는 신문체 단어가 많아(谢谢·茶 가 R1 밖) 회화 작성에는 쓰지 않는다(2026-11-03).
WORDSET = ROOT / 'assets/data/freq/FINAL_wordset_for_conversation_app.tsv'
CUTS = [('R1', 433), ('R2', 616), ('R3', 1238), ('R4', 2500)]
ORDER = ['R1', 'R2', 'R3', 'R4']
TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16), 'R4': (12, 16)}
HAN_LEN = {'R0': (2, 8), 'R1': (2, 12), 'R2': (2, 16), 'R3': (2, 22), 'R4': (2, 26)}  # 턴당 한자 수
OUTSIDE_MAX = {'R0': 2, 'R1': 2, 'R2': 3, 'R3': 4, 'R4': 5}
OUTSIDE_KIND = {'survival': 6}  # 서바이벌 편은 물건·가게 말이 필요해 넉넉히(note 에 뜻)
TWIST_TYPES = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
VARS = re.compile(r'\{[a-z_]+\}')
HAN = re.compile(r'[一-鿿]')
RD_OK = re.compile(r'^[가-힣0-9A-Za-z ,.!?:;…~～·\-—{}_()"\'%]*$')
SYL = re.compile(r"[a-zA-Zāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜü]+")
FORBIDDEN = ['李白', '杜甫']  # 실존 인물 예시(늘려 간다)
NUM = set('零一二三四五六七八九十百千万两几')

REG = {}
for r in csv.DictReader(open(WORDSET, encoding='utf-8'), delimiter='\t'):
    ranks = [int(x) for x in (r['corpus_rank'], r['chat_rank']) if x.strip().isdigit()]
    if not ranks:
        continue
    for reg, cut in CUTS:
        if min(ranks) <= cut:
            REG.setdefault(r['word'], reg)
            break
MAXW = max(len(w) for w in REG)


def cum(region):
    lv = ORDER.index('R1' if region == 'R0' else region)
    return {w for w, r in REG.items() if ORDER.index(r) <= lv}


def known(w, allowed):
    """구간 안 단어이거나, 숫자이거나, 구간 안 단어들로 나뉘면 안다고 본다(一杯 = 一 + 杯 는 杯 가 있어야)."""
    if w in allowed or all(c in NUM for c in w):
        return True
    for i in range(len(w) - 1, 0, -1):
        if (w[:i] in allowed or all(c in NUM for c in w[:i])) and known(w[i:], allowed):
            return True
    return False


def segment(s):
    s = VARS.sub(' ', s)
    out, i = [], 0
    while i < len(s):
        if not HAN.match(s[i]):
            i += 1; continue
        for n in range(min(MAXW, len(s) - i), 0, -1):
            w = s[i:i + n]
            if w in REG or n == 1:
                out.append(w); i += n; break
    return out


def syllables(py):
    return [m for m in SYL.findall(VARS.sub(' ', py))]


def check(path, seen, errs, warns):
    e = json.load(open(path, encoding='utf-8'))
    reg = e.get('region', 'R1')
    names = {c for v in e.get('speakers', {}).values() for c in re.findall(r'[\u4e00-\u9fff]+', v)}
    allowed = cum(reg) | seen | names
    turns = e['turns']
    lo, hi = TURNS[reg]
    tag = Path(path).stem
    if not lo <= len(turns) <= hi:
        errs.append(f'{tag}: 턴 {len(turns)} (구간 {reg} = {lo}~{hi})')
    if e.get('twist_type') not in TWIST_TYPES:
        errs.append(f'{tag}: twist_type 없음/틀림 ({e.get("twist_type")})')
    if not isinstance(e.get('twist'), int):
        errs.append(f'{tag}: twist 턴 번호 없음')
    outside = set()
    for t in turns:
        n = t['num']
        zh, py, rd = t.get('zh', ''), t.get('pinyin', ''), t.get('rd', '')
        hz = len(HAN.findall(VARS.sub('', zh)))
        a, b = HAN_LEN[reg]
        if not a <= hz <= b:
            (errs if hz > b else warns).append(f'{tag} #{n}: 한자 {hz}자 (구간 {a}~{b})')
        py_l = py.lower()
        ps = len(syllables(py_l))
        # 붙여 쓴 병음 단어는 음절 수를 다시 센다
        if ps and ps != hz:
            from_word = sum(len(re.findall(r'[aeiouüāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]+(?:ng|n|r)?', w)) for w in syllables(py_l))
            if from_word != hz:
                warns.append(f'{tag} #{n}: 병음 음절 {from_word} ≠ 한자 {hz}')
        if not rd:
            errs.append(f'{tag} #{n}: rd 없음(dart run tool/fill_rd.dart)')
        elif not RD_OK.match(rd):
            errs.append(f'{tag} #{n}: rd 에 한글 아닌 글자 — {rd}')
        if not t.get('ko'):
            errs.append(f'{tag} #{n}: ko 없음')
        new = []
        for w in segment(zh):
            if not known(w, allowed) and not any(w in nm for nm in names):
                outside.add(w.lstrip(''.join(NUM)) or w)  # 一杯 → 杯 (숫자는 세지 않는다)
            if w not in seen:
                new.append(w)
        if len(set(new)) > 3 + (2 if n == 1 else 0):
            warns.append(f'{tag} #{n}: 새 단어 {len(set(new))}개 {sorted(set(new))}')
        for f in FORBIDDEN:
            if f in zh:
                errs.append(f'{tag} #{n}: 금지어 {f}')
        seen |= set(segment(zh))
    lim = OUTSIDE_KIND.get(e.get('kind'), OUTSIDE_MAX[reg])
    if len(outside) > lim:  # 절벽구간은 참고만(사용자 2026-11-03 "신경은 쓰되 묶일 필요는 없어") — 오류가 아니라 주의
        warns.append(f'{tag}: {reg} 밖 단어 {len(outside)}개(≤{lim}) — {"·".join(sorted(outside))}')
    elif outside:
        warns.append(f'{tag}: {reg} 밖 단어 {"·".join(sorted(outside))} — note 에 뜻')
    return e


def main():
    files = [f for a in sys.argv[1:] if not a.startswith('--') for f in sorted(glob.glob(a, recursive=True))]
    errs, warns, seen = [], [], set()
    groups = defaultdict(Counter)
    for f in files:
        e = check(f, seen, errs, warns)
        groups[(e.get('region'), e.get('island'))][e.get('twist_type')] += 1
    for w in warns:
        print('주의', w)
    for e in errs:
        print('오류', e)
    total = Counter()
    for k, c in sorted(groups.items()):
        total.update(c)
        print(f'{k[0]} {k[1]}: {dict(c)}')
    n = sum(total.values())
    if n:
        print(f'chaos {total["chaos"]}/{n} = {100 * total["chaos"] / n:.0f}% (목표 ≥ 30%)')
    if '--vocab' in sys.argv:
        print('누적 단어', len(seen))
    print(f'{len(files)}편 · 오류 {len(errs)} · 주의 {len(warns)}')
    sys.exit(1 if errs else 0)


if __name__ == '__main__':
    main()
