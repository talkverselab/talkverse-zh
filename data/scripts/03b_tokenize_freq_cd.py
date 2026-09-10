"""
Re-tokenize corpus per-CD (per-movie/작품 메타데이터-id) and compute multiple frequency
metrics that are robust to document-level concentration (e.g., a character name
appearing 1000× in one movie should NOT rank as a top vocabulary word).

CD = "한 작품" = one 작품 메타데이터 tconst (multiple subtitle XML files for the same
tconst are aggregated together as the same document, since they describe the
same characters/setting and would otherwise inflate names).

Inputs:
  text/corpus_kept.txt          (one subtitle line per row)
  text/corpus_kept.stats.tsv    (per-XML stats; we use this to recover the
                                 tconst boundary by line-counts)

We rebuild line→tconst mapping by walking corpus_kept.stats.tsv (which lists
files in the same order they were appended to corpus_kept.txt).

Outputs:
  output/word_freq_cd.tsv       Per-word: rank, word, total_freq, df, df_pct,
                                 mean_freq_per_cd, median_freq_per_cd,
                                 tfidf_score, cum_tfidf_pct
  output/word_freq_cd.summary.txt
  output/cd_stats.txt           Total CDs, mean tokens/CD, etc.

Selection:
The PRIMARY ranking is by tfidf_score = total_freq × log(N_cd / df).
This penalizes words concentrated in few CDs (proper names) and rewards words
spread across many CDs (general vocabulary).
"""
import os, sys, re, csv, math, time
from collections import Counter, defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
CORPUS = os.path.join(ROOT, "text", "corpus_kept.txt")
STATS  = os.path.join(ROOT, "text", "corpus_kept.stats.tsv")

OUT_FREQ    = os.path.join(ROOT, "output", "word_freq_cd.tsv")
OUT_SUMMARY = os.path.join(ROOT, "output", "word_freq_cd.summary.txt")
OUT_STATS   = os.path.join(ROOT, "output", "cd_stats.txt")

import jieba
jieba.initialize()

ALL_CJK = re.compile(r"^[一-鿿㐀-䶿]+$")

# 1) Build line→tconst mapping from stats file
#    stats columns: tconst, year, folder_id, xml_file, lines, chars
print("[scan] reading stats", flush=True)
file_segments = []  # list of (tconst, n_lines)
with open(STATS, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        file_segments.append((row["tconst"], int(row["lines"])))
total_lines_expected = sum(n for _, n in file_segments)
print(f"[scan] {len(file_segments)} XML files, expected {total_lines_expected:,} lines", flush=True)

# 2) Walk corpus, tokenize each line, accumulate per-CD counters.
#    cd_counters: tconst -> Counter (word -> freq within this CD)
print("[start] per-CD tokenization", flush=True)
t0 = time.time(); last = t0

cd_counters = defaultdict(Counter)
seg_iter = iter(file_segments)
cur_tconst, cur_remaining = next(seg_iter)
total_lines = 0
total_tokens_kept = 0

with open(CORPUS, "r", encoding="utf-8") as f:
    for line in f:
        # advance segment if current XML's lines exhausted
        while cur_remaining == 0:
            try:
                cur_tconst, cur_remaining = next(seg_iter)
            except StopIteration:
                cur_tconst = None
                break
        if cur_tconst is None:
            break
        cur_remaining -= 1
        line = line.strip()
        if not line:
            total_lines += 1
            continue
        total_lines += 1

        c = cd_counters[cur_tconst]
        for tok in jieba.cut(line, HMM=True):
            if ALL_CJK.match(tok):
                c[tok] += 1
                total_tokens_kept += 1

        if total_lines % 200000 == 0:
            now = time.time()
            print(f"  ... lines={total_lines:,}  cds={len(cd_counters):,}  "
                  f"kept={total_tokens_kept:,}  ({total_lines/(now-t0):.0f} lines/s)",
                  flush=True)

print(f"[tokenized] lines={total_lines:,}  CDs={len(cd_counters):,}  "
      f"kept_tokens={total_tokens_kept:,}", flush=True)

# 3) Aggregate global metrics
N_cd = len(cd_counters)
df = Counter()              # word -> # of CDs containing it
total_freq = Counter()      # word -> total token freq
sum_per_cd = defaultdict(list)  # word -> [freq in each CD where it appears]
for tconst, c in cd_counters.items():
    for w, fq in c.items():
        df[w] += 1
        total_freq[w] += fq
        sum_per_cd[w].append(fq)

vocab = list(total_freq.keys())
print(f"[aggregate] vocab={len(vocab):,}", flush=True)

# 4) Compute scores
def median(xs):
    xs = sorted(xs)
    n = len(xs)
    if n == 0: return 0
    if n % 2: return xs[n//2]
    return (xs[n//2-1] + xs[n//2]) / 2

records = []
for w in vocab:
    tf = total_freq[w]
    d  = df[w]
    idf = math.log(N_cd / d) if d > 0 else 0.0
    tfidf = tf * idf
    mean_fq = tf / d if d > 0 else 0.0
    med_fq = median(sum_per_cd[w])
    records.append((w, tf, d, mean_fq, med_fq, tfidf))

# Sort by tfidf descending
records.sort(key=lambda x: -x[5])

total_tfidf = sum(r[5] for r in records)

with open(OUT_FREQ, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","total_freq","df","df_pct","mean_freq_per_cd",
                "median_freq_per_cd","tfidf_score","cum_tfidf_pct"])
    cum = 0
    for i, (wd, tf, d, mf, md, ti) in enumerate(records, 1):
        cum += ti
        w.writerow([i, wd, tf, d, f"{d/N_cd*100:.4f}",
                    f"{mf:.2f}", f"{md:.1f}", f"{ti:.2f}",
                    f"{cum/total_tfidf*100:.4f}"])

# 5) Side-by-side: also save a freq-only ranking for direct comparison
records_by_tf = sorted(records, key=lambda x: -x[1])
records_by_df = sorted(records, key=lambda x: (-x[2], -x[1]))

# 6) Summary lines
key_ranks = [100, 500, 1000, 2000, 3000, 5000, 7000, 10000, 15000, 30000, 50000, 100000]
key_set = set(key_ranks)
lines_out = []
lines_out.append(f"corpus lines     : {total_lines:,}")
lines_out.append(f"kept tokens      : {total_tokens_kept:,}")
lines_out.append(f"vocabulary       : {len(records):,}")
lines_out.append(f"CDs (works)      : {N_cd:,}")
lines_out.append(f"avg tokens/CD    : {total_tokens_kept/N_cd:,.0f}")
lines_out.append("")
lines_out.append("=== TFIDF-ranked (primary) ===")
lines_out.append(f"{'rank':>8} {'cum%':>7} {'word':<10} {'tf':>10} {'df':>8} {'df%':>7} {'tfidf':>12}")
cum = 0
for i, (wd, tf, d, mf, md, ti) in enumerate(records, 1):
    cum += ti
    if i in key_set:
        lines_out.append(f"{i:>8d} {cum/total_tfidf*100:>6.3f}% {wd:<10} {tf:>10d} {d:>8d} {d/N_cd*100:>6.2f}% {ti:>12.0f}")
lines_out.append("")
lines_out.append("=== Compare ===  TFIDF top vs raw-TF top  vs DF top  (top 30)")
lines_out.append(f"{'rank':>4} | {'TFIDF':<14} | {'raw TF':<14} | {'DF':<14}")
for i in range(30):
    a = records[i][0]
    b = records_by_tf[i][0]
    c = records_by_df[i][0]
    lines_out.append(f"{i+1:>4d} | {a:<14} | {b:<14} | {c:<14}")

print()
print("\n".join(lines_out))
with open(OUT_SUMMARY, "w", encoding="utf-8") as f:
    f.write("\n".join(lines_out))

with open(OUT_STATS, "w", encoding="utf-8") as f:
    f.write(f"CDs (works): {N_cd}\n")
    f.write(f"vocab: {len(records)}\n")
    f.write(f"total kept tokens: {total_tokens_kept}\n")
    f.write(f"avg tokens/CD: {total_tokens_kept/N_cd:.1f}\n")

print()
print(f"[done] {OUT_FREQ}")
print(f"[done] {OUT_SUMMARY}")
print(f"[done] {OUT_STATS}")
print(f"[done] elapsed={time.time()-t0:.1f}s")
