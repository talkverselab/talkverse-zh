"""
Re-tokenize corpus_kept_s.txt EXCLUDING any XML whose tconst is in hk_movies.txt
(작품 단위로 HK 자막 보유 영화 모두 제거).
Output: word_freq_cd_s_nohk.tsv (final clean dataset)
"""
import os, sys, re, csv, math, time
from collections import Counter, defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
CORPUS = os.path.join(ROOT, "text", "corpus_kept_s.txt")
STATS  = os.path.join(ROOT, "text", "corpus_kept.stats.tsv")
HK     = os.path.join(ROOT, "output", "hk_movies.txt")

OUT_FREQ    = os.path.join(ROOT, "output", "word_freq_cd_s_nohk.tsv")
OUT_STATS   = os.path.join(ROOT, "output", "cd_stats_s_nohk.txt")

import jieba
jieba.initialize()

ALL_CJK = re.compile(r"^[一-鿿㐀-䶿]+$")

# load HK tconsts to skip
hk_tconsts = set()
with open(HK, "r", encoding="utf-8") as f:
    for line in f:
        t = line.strip()
        if t: hk_tconsts.add(t)
print(f"[load] HK tconsts to skip: {len(hk_tconsts):,}", flush=True)

# load XML segments (tconst, n_lines)
file_segments = []
with open(STATS, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        file_segments.append((row["tconst"], int(row["lines"])))
n_xml_total = len(file_segments)
n_xml_skip  = sum(1 for t,_ in file_segments if t in hk_tconsts)
print(f"[scan] XML files: {n_xml_total}, skip: {n_xml_skip}", flush=True)

print("[start] tokenization (skipping HK)", flush=True)
t0 = time.time(); last = t0

cd_counters = defaultdict(Counter)
seg_iter = iter(file_segments)
cur_tconst, cur_remaining = next(seg_iter)
cur_skip = cur_tconst in hk_tconsts
total_lines = 0
total_tokens_kept = 0

with open(CORPUS, "r", encoding="utf-8") as f:
    for line in f:
        while cur_remaining == 0:
            try:
                cur_tconst, cur_remaining = next(seg_iter)
                cur_skip = cur_tconst in hk_tconsts
            except StopIteration:
                cur_tconst = None
                break
        if cur_tconst is None: break
        cur_remaining -= 1
        total_lines += 1
        if cur_skip: continue
        line = line.strip()
        if not line: continue
        c = cd_counters[cur_tconst]
        for tok in jieba.cut(line, HMM=True):
            if ALL_CJK.match(tok):
                c[tok] += 1
                total_tokens_kept += 1
        if total_lines % 200000 == 0:
            now = time.time()
            print(f"  ... lines={total_lines:,} cds_kept={len(cd_counters):,} kept={total_tokens_kept:,} ({total_lines/(now-t0):.0f} l/s)", flush=True)

print(f"[tokenized] CDs(kept)={len(cd_counters):,} kept_tokens={total_tokens_kept:,}", flush=True)

N_cd = len(cd_counters)
df = Counter(); total_freq = Counter(); sum_per_cd = defaultdict(list)
for tconst, c in cd_counters.items():
    for w, fq in c.items():
        df[w] += 1
        total_freq[w] += fq
        sum_per_cd[w].append(fq)

vocab = list(total_freq.keys())
print(f"[aggregate] vocab={len(vocab):,}", flush=True)

def median(xs):
    xs = sorted(xs); n = len(xs)
    if n == 0: return 0
    if n % 2: return xs[n//2]
    return (xs[n//2-1] + xs[n//2]) / 2

records = []
for w in vocab:
    tf = total_freq[w]; d = df[w]
    idf = math.log(N_cd / d) if d > 0 else 0.0
    tfidf = tf * idf
    records.append((w, tf, d, tf/d, median(sum_per_cd[w]), tfidf))

# CD-weighted score: TF × DF/N_cd
records_score = sorted(records, key=lambda r: -(r[1] * (r[2]/N_cd)))

with open(OUT_FREQ, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","total_freq","df","df_pct","mean_freq_per_cd",
                "median_freq_per_cd","tfidf_score","cd_score"])
    for i, (wd, tf, d, mf, md, ti) in enumerate(records_score, 1):
        sc = tf * (d/N_cd)
        w.writerow([i, wd, tf, d, f"{d/N_cd*100:.4f}", f"{mf:.2f}", f"{md:.1f}",
                    f"{ti:.2f}", f"{sc:.2f}"])

with open(OUT_STATS, "w", encoding="utf-8") as f:
    f.write(f"CDs (kept): {N_cd}\n")
    f.write(f"vocab: {len(records)}\n")
    f.write(f"tokens: {total_tokens_kept}\n")
    f.write(f"HK tconsts skipped: {len(hk_tconsts)}\n")
print(f"[done] {OUT_FREQ}")
print(f"[done] elapsed={time.time()-t0:.1f}s")
