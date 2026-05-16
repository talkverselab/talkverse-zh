"""
Score each Chinese character (한자) by aggregating word freq.

Method:
   For every word w with freq f, every character c in w gets +f to its score.
   So a character used in many high-frequency words ranks high.

   Two scores:
     score_uniform : sum_{w containing c} freq(w)             (counts char per word)
     score_token   : sum_{w containing c} freq(w) * count(c in w)
                     (counts char per token-occurrence; identical for words
                      with no repeated characters, slightly higher for words
                      that repeat the char)

We use the FULL opus vocabulary (no cutoff) to compute scores - cutting off
at e.g. rank 30000 would unfairly drop rare words that nevertheless contribute.

Outputs:
- output/hanzi_score.tsv          rank, char, score_token, score_uniform,
                                  uniq_words_using, cum_pct, hsk_char_level
- output/hanzi_segments.tsv       per fixed rank segment of CHARACTERS:
                                  vocab, sum_score, %coverage
- output/hanzi_cliff_coverage.tsv coverage targets for character scores
- output/hanzi_top500.txt         top 500 chars one per line
"""
import os, csv
from collections import Counter, defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
FREQ = os.path.join(ROOT, "output", "word_freq.tsv")
HSK  = os.path.join(ROOT, "wordlists", "HSK_zispace_2021.txt")

OUT_SCORE = os.path.join(ROOT, "output", "hanzi_score.tsv")
OUT_SEG   = os.path.join(ROOT, "output", "hanzi_segments.tsv")
OUT_COV   = os.path.join(ROOT, "output", "hanzi_cliff_coverage.tsv")
OUT_TOP   = os.path.join(ROOT, "output", "hanzi_top500.txt")

# --- HSK character levels (from word lists, take min level a char appears in) ---
LEVEL_LABEL = {"一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4",
               "五级":"HSK5","六级":"HSK6","高等":"HSK7-9"}
LEVEL_RANK = {"HSK1":1,"HSK2":2,"HSK3":3,"HSK4":4,"HSK5":5,"HSK6":6,"HSK7-9":7}
char_min_level = {}  # char -> short level
with open(HSK, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"): continue
        parts = line.split("\t")
        if len(parts) < 5: continue
        word_field, _, _, _, level = parts[:5]
        lvl = LEVEL_LABEL.get(level, level)
        for word in word_field.split("∣"):
            for c in word:
                if c not in char_min_level:
                    char_min_level[c] = lvl
                else:
                    if LEVEL_RANK.get(lvl, 99) < LEVEL_RANK.get(char_min_level[c], 99):
                        char_min_level[c] = lvl

# --- aggregate over opus words ---
score_token   = Counter()  # repetition counted
score_uniform = Counter()  # one per word
uniq_words    = defaultdict(int)
total_token = 0
with open(FREQ, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        word = row["word"]
        fq = int(row["freq"])
        seen = set()
        for c in word:
            score_token[c] += fq
            if c not in seen:
                score_uniform[c] += fq
                uniq_words[c] += 1
                seen.add(c)
        total_token += fq * len(word)  # total char-token impressions

items = sorted(score_token.items(), key=lambda x: -x[1])
total_score = sum(v for _, v in items)

with open(OUT_SCORE, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","char","score_token","score_uniform","uniq_words","cum_pct","hsk_char_level"])
    cum = 0
    for i, (c, s) in enumerate(items, 1):
        cum += s
        w.writerow([i, c, s, score_uniform[c], uniq_words[c],
                    f"{cum/total_score*100:.4f}",
                    char_min_level.get(c, "")])

# coverage targets
targets = [50, 80, 90, 95, 98, 99, 99.5, 99.8, 99.9, 99.99]
target_idx = 0
cum = 0
hits = []
for i, (c, s) in enumerate(items, 1):
    cum += s
    pct = cum / total_score * 100
    while target_idx < len(targets) and pct >= targets[target_idx]:
        hits.append((targets[target_idx], i, cum, pct))
        target_idx += 1
    if target_idx >= len(targets): break

with open(OUT_COV, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["target_pct","rank_to_reach","cum_score","actual_pct"])
    for t, r, c, p in hits:
        w.writerow([t, r, c, f"{p:.4f}"])

# fixed segments
SEGS = [
    (1, 100), (101, 300), (301, 500), (501, 1000),
    (1001, 1500), (1501, 2000), (2001, 3000),
    (3001, 4000), (4001, 5000), (5001, 7000),
    (7001, len(items)),
]
N = len(items)
with open(OUT_SEG, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["lo","hi","vocab","sum_score","pct_total","hsk1","hsk2","hsk3","hsk4","hsk5","hsk6","hsk7-9","none"])
    for lo, hi in SEGS:
        lo = max(1, lo); hi = min(N, hi)
        if lo > hi: continue
        bucket = items[lo-1:hi]
        s = sum(v for _, v in bucket)
        cnt = Counter()
        for c, _ in bucket:
            cnt[char_min_level.get(c, "none")] += 1
        w.writerow([lo, hi, hi-lo+1, s, f"{s/total_score*100:.4f}"]
                   + [cnt.get(l, 0) for l in
                      ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9","none"]])

# top 500 char dump
with open(OUT_TOP, "w", encoding="utf-8") as f:
    for i, (c, s) in enumerate(items[:500], 1):
        f.write(f"{i}\t{c}\t{s}\t{char_min_level.get(c,'')}\n")

print(f"[done] unique chars in opus: {len(items):,}")
print(f"[done] total char-impressions: {total_score:,}")
print(f"[done] {OUT_SCORE}")
print(f"[done] {OUT_COV}")
print(f"[done] {OUT_SEG}")
print(f"[done] {OUT_TOP}")

print()
print("== character coverage ==")
for t, r, c, p in hits:
    print(f"  {t}% reached at rank {r:>5d}  ({p:.3f}%)")
