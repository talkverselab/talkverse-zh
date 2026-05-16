"""
Side-by-side comparison: corpus-wide TF (old word_freq.tsv) vs CD-based TFIDF
(new word_freq_cd_legacy.tsv). Highlights what the CD reweighting changed.

Outputs:
  output/old_vs_new_top.tsv          rank-by-rank (top 200): old vs new
  output/old_vs_new_movers.tsv       words that moved most (rank diff)
  output/old_vs_new.summary.txt      summary stats + Spearman
"""
import os, csv, math

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
OLD = os.path.join(ROOT, "output", "word_freq.tsv")
NEW = os.path.join(ROOT, "output", "word_freq_cd_legacy.tsv")
OUT_TOP   = os.path.join(ROOT, "output", "old_vs_new_top.tsv")
OUT_MOVE  = os.path.join(ROOT, "output", "old_vs_new_movers.tsv")
OUT_SUM   = os.path.join(ROOT, "output", "old_vs_new.summary.txt")

def load(path):
    rank = {}
    with open(path, "r", encoding="utf-8") as f:
        r = csv.DictReader(f, delimiter="\t")
        for row in r:
            rank[row["word"]] = int(row["rank"])
    return rank

old = load(OLD)
new = load(NEW)
print(f"old vocab={len(old):,}  new vocab={len(new):,}", flush=True)

# Top 300 side-by-side
old_sorted = sorted(old.items(), key=lambda x: x[1])
new_sorted = sorted(new.items(), key=lambda x: x[1])

with open(OUT_TOP, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","old_word","old_rank_in_new","new_word","new_rank_in_old"])
    for i in range(300):
        ow = old_sorted[i][0] if i < len(old_sorted) else ""
        nw = new_sorted[i][0] if i < len(new_sorted) else ""
        ow_in_new = new.get(ow, "")
        nw_in_old = old.get(nw, "")
        w.writerow([i+1, ow, ow_in_new, nw, nw_in_old])

# Biggest movers within rank<=5000 in old (most penalized) and new (most boosted)
penalized = []   # high in old, much lower in new (proper names, one-CD spikes)
boosted   = []   # higher in new than old (general vocab)
for word, r_old in old.items():
    if r_old > 5000: continue
    r_new = new.get(word, len(new) + 1)
    diff = r_new - r_old   # positive = pushed down in new (penalized)
    if diff >= 1000:
        penalized.append((r_old, r_new, diff, word))
for word, r_new in new.items():
    if r_new > 5000: continue
    r_old = old.get(word, len(old) + 1)
    diff = r_old - r_new
    if diff >= 1000:
        boosted.append((r_new, r_old, diff, word))

penalized.sort(key=lambda x: -x[2])
boosted.sort(key=lambda x: -x[2])

with open(OUT_MOVE, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["direction","rank_old","rank_new","abs_change","word"])
    for r_old, r_new, diff, word in penalized[:150]:
        w.writerow(["penalized(↓)", r_old, r_new, diff, word])
    for r_new, r_old, diff, word in boosted[:150]:
        w.writerow(["boosted(↑)", r_old, r_new, diff, word])

# Spearman on words that are top-K in either ranking
def spearman_topk(K):
    s = set()
    for w, r in old.items():
        if r <= K: s.add(w)
    for w, r in new.items():
        if r <= K: s.add(w)
    pairs = []
    for w in s:
        ro = old.get(w, len(old)+1)
        rn = new.get(w, len(new)+1)
        pairs.append((ro, rn))
    n = len(pairs)
    def rankify(values):
        ind = sorted(range(len(values)), key=lambda i: values[i])
        out = [0]*len(values); i=0
        while i < len(values):
            j = i
            while j+1 < len(values) and values[ind[j+1]] == values[ind[i]]:
                j += 1
            avg = (i+j)/2 + 1
            for k in range(i, j+1):
                out[ind[k]] = avg
            i = j+1
        return out
    a = rankify([p[0] for p in pairs])
    b = rankify([p[1] for p in pairs])
    ma = sum(a)/n; mb = sum(b)/n
    num = sum((ai-ma)*(bi-mb) for ai,bi in zip(a,b))
    den = math.sqrt(sum((x-ma)**2 for x in a) * sum((x-mb)**2 for x in b))
    return num/den if den > 0 else 0.0, n

lines = []
lines.append(f"OLD vocab : {len(old):,}    NEW vocab : {len(new):,}")
lines.append("")
lines.append("Spearman (old rank vs new rank, both top-K union):")
lines.append(f"{'K':>8s} {'spearman':>10s} {'pairs':>10s}")
for K in (100,500,1000,2000,3000,5000,10000):
    rho, n = spearman_topk(K)
    lines.append(f"{K:>8d} {rho:>10.4f} {n:>10d}")
lines.append("")
lines.append("=== TOP-30: OLD vs NEW side by side ===")
lines.append(f"{'#':>4} | {'OLD':<14} | {'NEW':<14}")
for i in range(30):
    a = old_sorted[i][0] if i < len(old_sorted) else ""
    b = new_sorted[i][0] if i < len(new_sorted) else ""
    lines.append(f"{i+1:>4d} | {a:<14} | {b:<14}")
lines.append("")
lines.append("=== Most PENALIZED top-30 (rank dropped by ≥1000 in NEW) ===")
lines.append(f"{'word':<14} {'old':>6} → {'new':>6}")
for r_old, r_new, _, w in penalized[:30]:
    lines.append(f"{w:<14} {r_old:>6} → {r_new:>6}")
lines.append("")
lines.append("=== Most BOOSTED top-30 (rank rose by ≥1000 in NEW) ===")
lines.append(f"{'word':<14} {'old':>6} → {'new':>6}")
for r_new, r_old, _, w in boosted[:30]:
    lines.append(f"{w:<14} {r_old:>6} → {r_new:>6}")

with open(OUT_SUM, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("\n".join(lines))
print()
print(f"[done] {OUT_TOP}")
print(f"[done] {OUT_MOVE}")
print(f"[done] {OUT_SUM}")
