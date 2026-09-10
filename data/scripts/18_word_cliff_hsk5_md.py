"""Build HackMD-ready 'word cliff + HSK distribution (HSK5 기준)' page."""
import csv, io
from collections import Counter

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
out = io.StringIO()
def p(*a, **kw): print(*a, **kw, file=out)

p("# 단어 절벽구간 + HSK 분포 (FINAL · HSK5 기준)")
p("")
p("> **회화 학습 목표 = HSK5 누적**")
p("> 데이터: zh_cn 공개 말뭉치 2018 → 외국·홍콩·무협 제외 → CD 가중 + OpenCC 간체 통일 → HK 자막 제거")
p("> 6,580 작품 · 88.3M 토큰 · vocab **436,498 단어**")
p("")
p("---")
p("")
p("## 1. 단어 누적 커버리지")
p("")
p("| 토큰 커버 | 필요 단어 수 | 추가 단어당 ROI |")
p("| --: | --: | --: |")
prev_r = 0; prev_p = 0
with open(f"{ROOT}/output/cliff_coverage_final.tsv", encoding="utf-8") as f:
    next(f)
    for line in f:
        t, r, _, pp = line.rstrip().split("\t")
        rr = int(r); ppp = float(pp)
        roi = (ppp - prev_p) / max(1, rr - prev_r)
        p(f"| **{t}%** | **{rr:,}** | {roi:.4f}%/단어 |")
        prev_r, prev_p = rr, ppp

p("")
p("---")
p("")
p("## 2. 절벽구간 단어수·커버·평균빈도·평균길이")
p("")
p("| 구간 (rank) | 단어수 | %corpus | 평균빈도 | 평균길이 |")
p("| --- | --: | --: | --: | --: |")
with open(f"{ROOT}/output/cliff_segments_final.tsv", encoding="utf-8") as f:
    next(f)
    for line in f:
        parts = line.rstrip().split("\t")
        lo, hi, vocab, sf, pct, af, ml, uc = parts
        rng = f"{int(lo):,}–{int(hi):,}" if int(hi) < 999999 else f"{int(lo):,}+"
        p(f"| {rng} | {int(vocab):,} | {float(pct):.2f}% | {float(af):,.0f} | {float(ml):.2f}자 |")

p("")
p("---")
p("")
p("## 3. 절벽구간별 HSK 등급 분포 (개수 + %)")
p("")
p("> **HSK1~5는 회화 학습 범위, HSK6/7-9는 학술·문어 (참고)**")
p("")
p("| 구간 (rank) | 단어수 | %corpus | HSK1 | HSK2 | HSK3 | HSK4 | **HSK5** | HSK6 | HSK7-9 | 미수록 |")
p("| --- | --: | --: | --: | --: | --: | --: | --: | --: | --: | --: |")
seg_pct = {}
with open(f"{ROOT}/output/cliff_segments_final.tsv", encoding="utf-8") as f:
    next(f)
    for line in f:
        parts = line.rstrip().split("\t")
        seg_pct[(int(parts[0]), int(parts[1]))] = float(parts[4])
with open(f"{ROOT}/output/hsk_in_segments_final.tsv", encoding="utf-8") as f:
    next(f)
    for line in f:
        parts = line.rstrip().split("\t")
        lo, hi, vocab = int(parts[0]), int(parts[1]), int(parts[2])
        h = [int(x) for x in parts[3:]]
        pct = seg_pct.get((lo,hi), 0)
        # bold HSK5 column
        cells = []
        for i, v in enumerate(h):
            txt = f"{v} ({v/vocab*100:.1f}%)" if v else "—"
            if i == 4:  # HSK5
                txt = f"**{txt}**"
            cells.append(txt)
        rng = f"{lo:,}–{hi:,}" if hi < 999999 else f"{lo:,}+"
        p(f"| {rng} | {vocab:,} | {pct:.2f}% | " + " | ".join(cells) + " |")

# Section 4: HSK 단어급별 opus 회수율
p("")
p("---")
p("")
p("## 4. HSK 단어급별 opus 회수율 (얼마나 자주 쓰이나)")
p("")
p("> HSK 등급의 단어가 opus 빈도 어디에 분포하는지. 100% = 모든 단어가 그 rank 안에 등장.")
p("")
p("| HSK 단어급 | 단어수 | opus ≤100 | ≤500 | ≤1,000 | ≤3,000 | ≤10,000 | 미등장 |")
p("| --- | --: | --: | --: | --: | --: | --: | --: |")

LVL = {"一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4","五级":"HSK5","六级":"HSK6","高等":"HSK7-9"}
hsk_lvl = {}
with open(f"{ROOT}/wordlists/HSK_zispace_2021.txt", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"): continue
        parts = line.split("\t")
        if len(parts) < 5: continue
        wf, _, _, _, level = parts[:5]
        for w in wf.split("∣"):
            w = w.strip()
            if w: hsk_lvl[w] = LVL.get(level, level)

opus_rank = {}
with open(f"{ROOT}/output/hsk_word_map_final.tsv", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        opus_rank[row["word"]] = int(row["rank"])

for lvl in ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9"]:
    words = [w for w, l in hsk_lvl.items() if l == lvl]
    n = len(words)
    counts = {100:0, 500:0, 1000:0, 3000:0, 10000:0}
    not_in = 0
    for w in words:
        rk = opus_rank.get(w)
        if rk is None: not_in += 1; continue
        for thr in [100, 500, 1000, 3000, 10000]:
            if rk <= thr: counts[thr] += 1
    cells = [f"{counts[t]} ({counts[t]/n*100:.0f}%)" for t in [100,500,1000,3000,10000]]
    line = f"| {lvl} | {n} | " + " | ".join(cells) + f" | {not_in} ({not_in/n*100:.0f}%) |"
    if lvl == "HSK5":
        # bold the row by wrapping each cell
        line = "| **HSK5** | **" + str(n) + "** | " + " | ".join(f"**{c}**" for c in cells) + f" | **{not_in} ({not_in/n*100:.0f}%)** |"
    p(line)

# Section 5: HSK cumulative coverage
p("")
p("---")
p("")
p("## 5. HSK 누적 단어급의 opus 토큰 커버리지 (학습 효율)")
p("")
p('> "HSK n급까지 다 외우면 자막에서 토큰 몇 % 알아듣는가"')
p("")
p("| HSK 누적 | 단어 수 | opus 등장 | **토큰 커버** | 비고 |")
p("| --- | --: | --: | --: | --- |")
with open(f"{ROOT}/output/hsk_coverage_final.tsv", encoding="utf-8") as f:
    next(f)
    for line in f:
        bucket, total, present, cov = line.rstrip().split("\t")
        if "HSKK" in bucket: continue
        note = ""
        if "HSK4" in bucket and "1~4" not in bucket: note = "회화 시작 단계"
        if bucket == "≤HSK5": note = "🎯 회화 학습 목표"
        if bucket == "≤HSK7-9": note = "전 HSK 마스터"
        line_md = f"| {bucket} | {int(total):,} | {int(present):,} | {float(cov):.2f}% | {note} |"
        if bucket == "≤HSK5":
            line_md = f"| **{bucket}** | **{int(total):,}** | **{int(present):,}** | **{float(cov):.2f}%** | **{note}** |"
        p(line_md)

p("")
p("---")
p("")
p("## 6. 핵심 인사이트 (HSK5 학습자 기준)")
p("")
p("1. **단어 100개 = 토큰 72.7%** — 50% 커버는 단어 27개. 매우 가파른 절벽.")
p("2. **단어 162개 = 80% 커버** (생존 회화) / **360개 = 90% 커버** (일상 회화).")
p('3. **🎯 HSK 1-5급 누적(4,304단어) = opus 토큰 91.66%** — **HSK5 학습 = 회화 자막 90% 이상 커버**.')
p("4. **HSK1 단어 절반(51%)이 opus rank ≤100** — 핵심 회화 단어. 나머지 절반은 빈도 낮음.")
p("5. **HSK4 단어 995개 중 9%만 opus rank ≤500** — HSK4 단어 대부분 분산. 회화 빈도는 낮지만 시험 必須.")
p("6. **HSK5 단어 1,068개 중 22%가 opus rank ≤3,000** — HSK5 단어 회화 진입 비율 보통 (HSK4의 32%, HSK3의 48%보다 낮음).")
p("7. **회화 핵심 절벽**: 단어 rank **1,353** (Tier B 끝) / **2,423** (회화 핵심 어휘 끝, log-slope 가장 가파름).")
p("8. **HSK 7-9급 5,621개 중 87%가 opus rank > 3,000** — 학술/문어, 회화 ROI 낮음 (분야별 학습으로).")

OUT = f"{ROOT}/output/HACKMD_word_cliff_hsk5.md"
with open(OUT, "w", encoding="utf-8") as f:
    f.write(out.getvalue())

print(out.getvalue())
print(f"[saved] {OUT} ({len(out.getvalue())} bytes)")
