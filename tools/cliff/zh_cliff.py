#!/usr/bin/env python3
"""중국어 절벽구간 재산출 — 중화권 원작 영화·드라마 자막(공개 자막 말뭉치 zh_cn) 기준 (2026-11-03).

  python3 tools/cliff/zh_cliff.py <자막.zip> [자막2.zip …] <title.basics.tsv.gz> <title.akas.tsv.gz> <title.episode.tsv.gz> <출력폴더>

- 작품 고르기: 원제(originalTitle)가 한자(가나·한글 없음)이거나, 발매 지역 표기가 중화권(CN·TW·HK·MO·SG·MY)뿐인 작품 = 중화권 원작.
  (작품 메타데이터의 원제가 병음 로마자로 적힌 중국 작품이 많아 지역으로도 판단)
  드라마 회차는 시리즈의 원제로 판단. 작품 하나에 자막 파일이 여럿이면 하나만.
- 문장: 자막 XML 의 <s> 텍스트 → 번체→간체(OpenCC t2s) → jieba 분절(정밀 모드).
- 단위: 단어 = jieba 토큰 중 한자가 하나 이상 든 것(숫자·라틴·문장부호 제외). 한자 = 그 토큰들의 한자 글자.
- 결과: 단어 R1~R4 = 누적 커버리지 55/60/70/80% 에 닿는 순위, 2,500 단어 최대 커버리지.
  한자(2026-11-07 추가): ① 한자 빈도 기준 R1~R4(같은 55/60/70/80%) + 50/90/95/98/99% ② 단어 R1~R4 를 읽는 데 필요한 한자 수(그 구간 단어들의 글자 합집합, 누적).
  출력폴더에 word_freq.tsv(순위·단어·빈도·누적%) · hanzi_freq.tsv(+ 그 글자가 처음 나오는 단어 구간) · summary.json. 말뭉치 이름은 공개 문서에 쓰지 않는다.
"""
import collections, gzip, io, json, re, sys, zipfile
import xml.etree.ElementTree as ET
import jieba, opencc

ALL = '--all' in sys.argv  # 중화권 원작만이 아니라 자막 전체(번역 외화 포함)
args = [a for a in sys.argv[1:] if a != '--all']
*zpaths, basics, akas, episode, out = args  # 자막 zip 여러 개(간체·번체) 가능
HAN = re.compile(r'[一-鿿]'); KANA = re.compile(r'[぀-ヿ]'); HANGUL = re.compile(r'[가-힣]')
TV = {'tvSeries', 'tvMiniSeries', 'tvEpisode', 'tvSpecial', 'tvShort', 'tvMovie'}

def read_tsv(p, cols):
    with gzip.open(p, 'rt', encoding='utf-8') as f:
        head = f.readline().rstrip('\n').split('\t'); idx = [head.index(c) for c in cols]
        for line in f:
            r = line.rstrip('\n').split('\t'); yield [r[i] for i in idx]

zfs = [zipfile.ZipFile(p) for p in zpaths]
by_id = {}
for zf in zfs:
    for n in zf.namelist():
        m = re.search(r'/(\d{4})/(\d+)/[^/]+\.xml(\.gz)?$', n)
        if m: by_id.setdefault('tt%07d' % int(m.group(2)), (zf, n))
print('자막 작품', len(by_id), flush=True)

parent = {}
for t, p in read_tsv(episode, ['tconst', 'parentTconst']):
    if t in by_id: parent[t] = p
need = set(by_id) | set(parent.values())
info = {}
for t, ty, orig in read_tsv(basics, ['tconst', 'titleType', 'originalTitle']):
    if t in need: info[t] = (ty, orig)
regions = collections.defaultdict(set)
for t, reg in read_tsv(akas, ['titleId', 'region']):
    if t in need and reg != '\\N': regions[t].add(reg)

SINO = {'CN', 'TW', 'HK', 'MO', 'SG', 'MY', 'XWW', 'XAS'}  # 중화권 + 세계 공통 표기

def chinese(t):
    """원제가 한자(가나·한글 없음)이거나, 발매 지역이 중화권뿐(CN·TW·HK 중 하나 이상, 그 밖 나라 없음)이면 중화권 원작."""
    src = parent.get(t, t)
    ty, orig = info.get(src, ('', ''))
    if HAN.search(orig) and not KANA.search(orig) and not HANGUL.search(orig):
        return True, ty
    reg = regions.get(src, set())
    return bool(reg & {'CN', 'TW', 'HK'}) and reg <= SINO, ty
keep = {}
for t, n in by_id.items():
    ok, ty = chinese(t)
    ok = ok or ALL
    if ok: keep[t] = (n, 'drama' if (info.get(t, ('',))[0] in TV or t in parent) else 'movie')
kinds = collections.Counter(k for _, k in keep.values())
print('중화권 원작', len(keep), dict(kinds), flush=True)

cc = opencc.OpenCC('t2s'); jieba.setLogLevel(60)
wf = collections.Counter(); hf = collections.Counter(); lines = 0
TAG = re.compile(r'\{[^}]*\}|<[^>]*>')  # 자막 서식 태그({\fn楷体} 등)
for i, (t, ((zf, n), k)) in enumerate(keep.items()):
    raw = zf.read(n)
    if n.endswith('.gz'): raw = gzip.decompress(raw)
    try: root = ET.fromstring(raw)
    except ET.ParseError: continue
    for s in root.iter('s'):
        txt = TAG.sub('', ''.join(s.itertext())).strip()
        if not txt or not HAN.search(txt): continue
        lines += 1
        for w in jieba.lcut(cc.convert(txt)):
            if HAN.search(w):
                w = ''.join(HAN.findall(w)); wf[w] += 1
                for c in w: hf[c] += 1
    if i % 200 == 0: print(f'{i}/{len(keep)} 작품 · 줄 {lines:,} · 토큰 {sum(wf.values()):,}', flush=True)

def cliff(freq, targets):
    tot = sum(freq.values()); cum = 0; res = {}; rows = []; ti = 0
    for r, (w, f) in enumerate(freq.most_common(), 1):
        cum += f; pct = 100 * cum / tot; rows.append((r, w, f, pct))
        while ti < len(targets) and pct >= targets[ti]:
            res[targets[ti]] = r; ti += 1
    return res, rows, tot

PCT = [55, 60, 70, 80]
wres, wrows, wtot = cliff(wf, PCT)
hres, hrows, htot = cliff(hf, [50] + PCT + [90, 95, 98, 99])
# ② 단어 구간을 읽는 데 필요한 한자: R_k 단어(순위 ≤ wres[p]) 의 글자 합집합(누적). 글자마다 처음 나오는 단어 구간을 적는다.
first_region = {}
for i, p in enumerate(PCT):
    for r, w, _, _ in wrows[:wres[p]]:
        for c in w: first_region.setdefault(c, f'R{i+1}')
need_hanzi = {f'R{i+1}': sum(1 for v in first_region.values() if int(v[1]) <= i + 1) for i in range(len(PCT))}
hz_cov_of_need = {}  # 그 글자 집합이 한자 토큰을 얼마나 덮는지
for i in range(len(PCT)):
    chars = {c for c, v in first_region.items() if int(v[1]) <= i + 1}
    hz_cov_of_need[f'R{i+1}'] = round(100 * sum(hf[c] for c in chars) / htot, 2)
import os; os.makedirs(out, exist_ok=True)
with open(f'{out}/word_freq.tsv', 'w', encoding='utf-8') as f:
    f.write('rank\tword\tfreq\tcum_pct\n')
    for r in wrows[:30000]: f.write(f'{r[0]}\t{r[1]}\t{r[2]}\t{r[3]:.4f}\n')
with open(f'{out}/hanzi_freq.tsv', 'w', encoding='utf-8') as f:
    f.write('rank\tchar\tfreq\tcum_pct\tword_region\n')
    for r in hrows: f.write(f'{r[0]}\t{r[1]}\t{r[2]}\t{r[3]:.4f}\t{first_region.get(r[1], "")}\n')
summary = {'works': len(keep), 'works_by_kind': dict(kinds), 'lines': lines, 'tokens': wtot, 'vocab': len(wf), 'hanzi_tokens': htot, 'hanzi_types': len(hf),
           'word_cliff': {f'R{i+1}': wres.get(p) for i, p in enumerate(PCT)}, 'word_cov_2500': round(wrows[2499][3], 2) if len(wrows) >= 2500 else None,
           'hanzi_cliff_freq': {f'R{i+1}': hres.get(p) for i, p in enumerate(PCT)},
           'hanzi_cliff_pct': {str(p): hres.get(p) for p in [50] + PCT + [90, 95, 98, 99]},
           'hanzi_needed_for_word_region': need_hanzi, 'hanzi_needed_cov': hz_cov_of_need,
           'hanzi_cov_at': {str(n): round(hrows[n-1][3], 2) for n in (209, 300, 500, 1000, 1500) if len(hrows) >= n},
           'unit': 'jieba 정밀 모드 토큰 중 한자 포함 토큰(번체→간체 변환 뒤), 한자 = 그 토큰의 한자 글자(토큰 빈도만큼 셈)'}
json.dump(summary, open(f'{out}/summary.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(json.dumps(summary, ensure_ascii=False, indent=1))
