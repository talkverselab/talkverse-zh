"""
Tokenize the corpus with jieba and compute word frequencies + cumulative distribution.

Inputs:
- text/corpus_kept.txt           (one line per subtitle line)
- (jieba's built-in dict; no custom dict required)

Outputs:
- output/word_freq.tsv           (rank, word, freq, cum_freq, cum_pct)
- output/word_freq.summary.txt   (totals, vocab size, %-coverage at key ranks)

Filtering rules:
- Skip pure-ASCII tokens (English/numbers/punct), they are not Chinese vocab.
- Skip tokens that are pure punctuation / whitespace.
- Keep tokens that contain at least one CJK character. Tokens like 'AA制', 'CD' are
  filtered (no CJK), but tokens like '中A' would be kept (mixed). We further
  drop tokens that have any non-CJK char to keep the wordlist clean.
"""
import os, sys, re, time, csv
from collections import Counter

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
CORPUS = os.path.join(ROOT, "text", "corpus_kept.txt")
OUT_FREQ    = os.path.join(ROOT, "output", "word_freq.tsv")
OUT_SUMMARY = os.path.join(ROOT, "output", "word_freq.summary.txt")

import jieba
jieba.initialize()

CJK_RE  = re.compile(r"[一-鿿㐀-䶿]")
ALL_CJK = re.compile(r"^[一-鿿㐀-䶿]+$")

print(f"[start] tokenizing {CORPUS}", flush=True)
t0 = time.time(); last = t0
counter = Counter()
total_lines = 0
total_tokens_raw = 0
total_tokens_kept = 0

with open(CORPUS, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        total_lines += 1
        for tok in jieba.cut(line, HMM=True):
            total_tokens_raw += 1
            if not ALL_CJK.match(tok):
                continue
            counter[tok] += 1
            total_tokens_kept += 1
        if total_lines % 200000 == 0:
            now = time.time()
            print(f"  ... lines={total_lines:,} kept_tokens={total_tokens_kept:,}"
                  f"  vocab={len(counter):,}  ({total_lines/(now-t0):.0f} lines/s)", flush=True)

print(f"[tokenized] lines={total_lines:,} raw_tokens={total_tokens_raw:,} "
      f"kept_tokens={total_tokens_kept:,} vocab={len(counter):,}",
      flush=True)

# Sort by frequency desc, then by word for stability
items = counter.most_common()

# Write rank table with cumulative coverage
with open(OUT_FREQ, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","freq","cum_freq","cum_pct"])
    cum = 0
    total = total_tokens_kept
    for i, (word, freq) in enumerate(items, 1):
        cum += freq
        w.writerow([i, word, freq, cum, f"{cum/total*100:.4f}"])

# summary: coverage at key ranks
key_ranks = [100, 500, 1000, 2000, 3000, 5000, 7000, 10000, 15000, 20000, 30000,
             50000, 100000, len(items)]
lines = []
lines.append(f"corpus lines  : {total_lines:,}")
lines.append(f"raw tokens    : {total_tokens_raw:,}")
lines.append(f"CJK tokens    : {total_tokens_kept:,}")
lines.append(f"vocabulary    : {len(items):,}")
lines.append("")
lines.append("rank\tcum_pct\ttop word at this rank")
cum = 0
ranks = set(key_ranks)
for i, (word, freq) in enumerate(items, 1):
    cum += freq
    if i in ranks:
        lines.append(f"{i:>8d}\t{cum/total_tokens_kept*100:7.3f}%\t{word}\t{freq}")
print("\n".join(lines))
with open(OUT_SUMMARY, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print(f"[done] freq table -> {OUT_FREQ}")
print(f"[done] summary    -> {OUT_SUMMARY}")
print(f"[done] elapsed    -> {time.time()-t0:.1f}s")
