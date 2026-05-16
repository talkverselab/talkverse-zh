"""
Cliff (segment-boundary) analysis on the rank-frequency distribution.

Two complementary views:

A) Coverage view ("어휘 커버리지가 % 도달하는 rank")
   For each target coverage in [50, 80, 90, 95, 98, 99, 99.5, 99.8, 99.9, 99.99],
   find the smallest rank N such that cumulative_freq(1..N) / total >= target.

B) Slope view ("log(freq) vs log(rank) 1차 미분에서 cliff")
   Bin the rank axis on log scale, smooth log(freq), and compute
   d log f / d log r.  Local minima (most negative slope) of this
   derivative across the rank axis are the "cliffs".

We also report fixed segments commonly used in pedagogy:
   1-100, 101-500, 501-1000, 1001-2000, 2001-3000, 3001-5000,
   5001-7000, 7001-10000, 10001-15000, 15001-30000, 30001-end.
For each segment we compute:
   - vocab_size
   - sum_freq   (segment coverage of the corpus, %)
   - avg_freq   (mean token freq in segment)
   - mean_word_len  (avg #characters per word)
   - char_count_uniq

Inputs : output/word_freq.tsv
Outputs:
   output/cliff_coverage.tsv
   output/cliff_slope.tsv
   output/cliff_segments.tsv
"""
import os, csv, math
from collections import Counter

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
FREQ = os.path.join(ROOT, "output", "word_freq.tsv")
OUT_COV  = os.path.join(ROOT, "output", "cliff_coverage.tsv")
OUT_SLP  = os.path.join(ROOT, "output", "cliff_slope.tsv")
OUT_SEG  = os.path.join(ROOT, "output", "cliff_segments.tsv")

# --- load ---
ranks = []
words = []
freqs = []
total = 0
with open(FREQ, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        ranks.append(int(row["rank"]))
        words.append(row["word"])
        freqs.append(int(row["freq"]))
        total += int(row["freq"])
N = len(ranks)
print(f"[load] vocab={N:,}  total_tokens={total:,}")

# --- A) coverage view ---
targets = [50, 80, 90, 95, 98, 99, 99.5, 99.8, 99.9, 99.99]
target_idx = 0
cum = 0
hits = []
for i, fq in enumerate(freqs, 1):
    cum += fq
    pct = cum / total * 100
    while target_idx < len(targets) and pct >= targets[target_idx]:
        hits.append((targets[target_idx], i, cum, pct))
        target_idx += 1
    if target_idx >= len(targets):
        break

with open(OUT_COV, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["target_pct","rank_to_reach","cum_freq","actual_pct"])
    for t, r, c, p in hits:
        w.writerow([t, r, c, f"{p:.4f}"])

# --- B) slope view ---
# Sample points logarithmically across rank axis
sample_ranks = []
r = 1
while r <= N:
    sample_ranks.append(r)
    r = max(r + 1, int(r * 1.05))
# Add the last rank
if sample_ranks[-1] != N:
    sample_ranks.append(N)
sample_ranks = sorted(set(sample_ranks))

# log smoothing window: average freq in [r/1.1, r*1.1]
def avg_freq(lo, hi):
    lo = max(1, lo); hi = min(N, hi)
    s = sum(freqs[lo-1:hi])
    n = hi - lo + 1
    return s / n if n > 0 else 0.0

slope_rows = []
prev = None
for r in sample_ranks:
    lo = max(1, int(r / 1.1))
    hi = min(N, int(r * 1.1))
    af = avg_freq(lo, hi)
    log_r = math.log10(r)
    log_f = math.log10(af) if af > 0 else 0.0
    slope = None
    if prev is not None:
        dr = log_r - prev[0]
        df = log_f - prev[1]
        if dr > 0:
            slope = df / dr
    slope_rows.append((r, freqs[r-1], af, log_r, log_f, slope))
    prev = (log_r, log_f)

with open(OUT_SLP, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","freq","smoothed_avg_freq","log10_rank","log10_avg_freq","d_logf_d_logr"])
    for r, fq, af, lr, lf, sl in slope_rows:
        w.writerow([r, fq, f"{af:.3f}", f"{lr:.4f}", f"{lf:.4f}",
                    "" if sl is None else f"{sl:.4f}"])

# Identify the steepest cliffs (most negative slope), grouping nearby points.
slope_only = [s for s in slope_rows if s[5] is not None]
slope_only.sort(key=lambda x: x[5])  # most negative first
seen = set()
cliffs = []
for r, fq, af, lr, lf, sl in slope_only:
    bucket = int(math.log10(r) * 5)  # 0.2-decade buckets
    if bucket in seen:
        continue
    seen.add(bucket)
    cliffs.append((r, fq, af, sl))
    if len(cliffs) >= 12:
        break
cliffs.sort(key=lambda x: x[0])
print()
print("[slope cliffs] steepest local slope per ~0.2-decade bucket")
print(f"  {'rank':>10s}  {'freq_at':>10s}  {'avg_freq':>10s}  {'slope':>8s}")
for r, fq, af, sl in cliffs:
    print(f"  {r:>10d}  {fq:>10d}  {af:>10.2f}  {sl:>8.3f}")

# --- C) fixed segments ---
SEGS = [
    (1, 100), (101, 500), (501, 1000),
    (1001, 2000), (2001, 3000), (3001, 5000),
    (5001, 7000), (7001, 10000),
    (10001, 15000), (15001, 30000), (30001, N),
]
def seg_stats(lo, hi):
    lo = max(1, lo); hi = min(N, hi)
    s = freqs[lo-1:hi]
    ws = words[lo-1:hi]
    if not s:
        return None
    sum_f = sum(s)
    chars = Counter()
    for w in ws:
        for c in w:
            chars[c] += 1
    avg_len = sum(len(w) for w in ws) / len(ws)
    return {
        "lo": lo, "hi": hi, "vocab": len(ws),
        "sum_freq": sum_f, "pct_corpus": sum_f / total * 100,
        "avg_freq": sum_f / len(ws),
        "mean_word_len": avg_len,
        "uniq_chars": len(chars),
    }

with open(OUT_SEG, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["lo","hi","vocab","sum_freq","pct_corpus","avg_freq","mean_word_len","uniq_chars"])
    for lo, hi in SEGS:
        st = seg_stats(lo, hi)
        if not st: continue
        w.writerow([st["lo"], st["hi"], st["vocab"], st["sum_freq"],
                    f"{st['pct_corpus']:.4f}",
                    f"{st['avg_freq']:.2f}",
                    f"{st['mean_word_len']:.2f}",
                    st["uniq_chars"]])

print()
print(f"[done] coverage -> {OUT_COV}")
print(f"[done] slope    -> {OUT_SLP}")
print(f"[done] segments -> {OUT_SEG}")

# print quick text summary
print()
print("=== A) coverage ===")
print(f"{'target%':>8} {'rank':>8} {'actual%':>8}")
for t, r, c, p in hits:
    print(f"{t:>8} {r:>8d} {p:>7.3f}%")

print()
print("=== C) fixed segments ===")
print(f"{'range':>14} {'vocab':>7} {'%corpus':>9} {'avg_freq':>10} {'avg_len':>8} {'uniq_ch':>8}")
for lo, hi in SEGS:
    st = seg_stats(lo, hi)
    if not st: continue
    print(f"{st['lo']:>6d}-{st['hi']:>6d} {st['vocab']:>7d} {st['pct_corpus']:>8.3f}% "
          f"{st['avg_freq']:>10.2f} {st['mean_word_len']:>8.2f} {st['uniq_chars']:>8d}")
