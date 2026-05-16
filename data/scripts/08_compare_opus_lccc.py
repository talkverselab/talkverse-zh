"""
Compare opus word_freq with an LCCC frequency table.

For ranks 1..K (K in {100, 500, 1000, 2000, 3000, 5000, 10000}), compute:
  - spearman rho on the joint vocabulary (rank in each)
  - kendall tau on the same set
  - top-K opus words: how many are in LCCC top-K, top-2K, top-10K?
  - rank-diff: opus rank - LCCC rank, distribution + outliers

Also produce:
  - opus-only top words at rank<=2000 (subtitle-specific)
  - LCCC-only top words at rank<=2000 (chat-specific)

Usage:
   python 08_compare_opus_lccc.py output/lccc_freq_50000.tsv
"""
import os, sys, csv, math
from collections import defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
OPUS = os.path.join(ROOT, "output", "word_freq.tsv")
LCCC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "output", "lccc_freq_50000.tsv")
TAG  = os.path.basename(LCCC).replace("lccc_freq_", "").replace(".tsv","")

OUT_SUM   = os.path.join(ROOT, "output", f"compare_{TAG}.summary.txt")
OUT_DIFF  = os.path.join(ROOT, "output", f"compare_{TAG}.rank_diff.tsv")
OUT_ONLY  = os.path.join(ROOT, "output", f"compare_{TAG}.opus_only_top.tsv")
OUT_CHAT  = os.path.join(ROOT, "output", f"compare_{TAG}.lccc_only_top.tsv")

def load(path):
    rank = {}
    freq = {}
    total = 0
    with open(path, "r", encoding="utf-8") as f:
        r = csv.DictReader(f, delimiter="\t")
        for row in r:
            w = row["word"]
            rank[w] = int(row["rank"])
            freq[w] = int(row["freq"])
            total += int(row["freq"])
    return rank, freq, total

print(f"[load] opus={OPUS}", flush=True)
opus_rank, opus_freq, opus_total = load(OPUS)
print(f"  opus  vocab={len(opus_rank):,}  tokens={opus_total:,}")
print(f"[load] lccc={LCCC}", flush=True)
lccc_rank, lccc_freq, lccc_total = load(LCCC)
print(f"  lccc  vocab={len(lccc_rank):,}  tokens={lccc_total:,}")

# Spearman: take a top-K set from OPUS, then look up rank in LCCC.
# For words missing in LCCC, assign rank = lccc_max_rank + 1 (penalty).
def spearman(K):
    opus_top_words = sorted([(r, w) for w, r in opus_rank.items() if r <= K])
    n = len(opus_top_words)
    lccc_max = len(lccc_rank)
    pairs = []
    for r_opus, w in opus_top_words:
        r_lccc = lccc_rank.get(w, lccc_max + 1)
        pairs.append((r_opus, r_lccc))
    # Compute Spearman by ranking both columns.
    # opus rank is already a rank (1..K), but we re-rank to handle ties properly.
    def rankify(values):
        ind = sorted(range(len(values)), key=lambda i: values[i])
        out = [0]*len(values)
        i = 0
        while i < len(values):
            j = i
            while j+1 < len(values) and values[ind[j+1]] == values[ind[i]]:
                j += 1
            avg = (i + j) / 2 + 1   # average rank (1-based)
            for k in range(i, j+1):
                out[ind[k]] = avg
            i = j+1
        return out
    a = rankify([p[0] for p in pairs])
    b = rankify([p[1] for p in pairs])
    ma = sum(a)/n; mb = sum(b)/n
    num = sum((ai-ma)*(bi-mb) for ai,bi in zip(a,b))
    den = math.sqrt(sum((x-ma)**2 for x in a) * sum((x-mb)**2 for x in b))
    return num/den if den > 0 else 0.0

# Overlap: how many of opus top-K are in LCCC top-K (and top-2K, top-10K)
def overlap(K):
    opus_set = {w for w, r in opus_rank.items() if r <= K}
    in_lccc_K   = sum(1 for w in opus_set if lccc_rank.get(w, 10**9) <= K)
    in_lccc_2K  = sum(1 for w in opus_set if lccc_rank.get(w, 10**9) <= 2*K)
    in_lccc_10K = sum(1 for w in opus_set if lccc_rank.get(w, 10**9) <= 10*K)
    return len(opus_set), in_lccc_K, in_lccc_2K, in_lccc_10K

lines = []
lines.append(f"opus tokens : {opus_total:,}  vocab : {len(opus_rank):,}")
lines.append(f"lccc tokens : {lccc_total:,}  vocab : {len(lccc_rank):,}")
lines.append("")
lines.append("== Spearman rho on opus top-K (missing in LCCC -> rank = lccc_max+1) ==")
lines.append(f"{'K':>8s} {'spearman':>10s}")
for K in (100, 500, 1000, 2000, 3000, 5000, 10000):
    rho = spearman(K)
    lines.append(f"{K:>8d} {rho:>10.4f}")

lines.append("")
lines.append("== Top-K overlap ==")
lines.append(f"{'K':>8s} {'opus_set':>10s} {'in_lccc_K':>10s} {'in_lccc_2K':>11s} {'in_lccc_10K':>12s}")
for K in (100, 500, 1000, 2000, 3000, 5000, 10000):
    a,b,c,d = overlap(K)
    lines.append(f"{K:>8d} {a:>10d} {b:>10d} {c:>11d} {d:>12d}")

# Domain-specific top words (rank<=2000 here, freq>=20 there)
opus_only = []
lccc_only = []
LCC_RANK_MISSING = len(lccc_rank) + 1
OPS_RANK_MISSING = len(opus_rank) + 1
for w, r in opus_rank.items():
    if r > 3000: continue
    rL = lccc_rank.get(w, LCC_RANK_MISSING)
    if rL == LCC_RANK_MISSING or rL > 30000:
        opus_only.append((r, w, opus_freq[w], rL if rL < LCC_RANK_MISSING else "—"))
for w, r in lccc_rank.items():
    if r > 3000: continue
    rO = opus_rank.get(w, OPS_RANK_MISSING)
    if rO == OPS_RANK_MISSING or rO > 30000:
        lccc_only.append((r, w, lccc_freq[w], rO if rO < OPS_RANK_MISSING else "—"))

opus_only.sort()
lccc_only.sort()

with open(OUT_ONLY, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["opus_rank","word","opus_freq","lccc_rank"])
    for r, wd, fq, rL in opus_only[:200]:
        w.writerow([r, wd, fq, rL])
with open(OUT_CHAT, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["lccc_rank","word","lccc_freq","opus_rank"])
    for r, wd, fq, rO in lccc_only[:200]:
        w.writerow([r, wd, fq, rO])

# Big rank-diff list (for Top-N opus words)
rank_diffs = []
for w, r in opus_rank.items():
    if r > 5000: continue
    rL = lccc_rank.get(w, LCC_RANK_MISSING)
    rank_diffs.append((r, w, opus_freq[w], rL, rL - r))
rank_diffs.sort()
with open(OUT_DIFF, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["opus_rank","word","opus_freq","lccc_rank","rank_diff(LCCC-opus)"])
    for row in rank_diffs:
        w.writerow(row)

with open(OUT_SUM, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print()
print("\n".join(lines))
print()
print(f"[done] summary  -> {OUT_SUM}")
print(f"[done] opus-only top -> {OUT_ONLY}")
print(f"[done] lccc-only top -> {OUT_CHAT}")
print(f"[done] rank diff     -> {OUT_DIFF}")
