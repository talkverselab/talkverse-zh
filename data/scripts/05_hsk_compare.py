"""
Compare opus word-set with HSK 3.0 (新HSK 2021) levels and HSKK intermediate
proxy (HSK 4-5 union).

Inputs:
- output/word_freq.tsv
- wordlists/HSK_zispace_2021.txt   (词语\\t词性\\t拼音\\t序号\\t级别)

Outputs:
- output/hsk_word_map.tsv          rank, word, freq, hsk_level (or '')
- output/hsk_coverage.tsv          per-level coverage of opus tokens
- output/hsk_in_segments.tsv       count of HSK-N words per fixed rank segment
- output/hsk_missing_top.tsv       opus top-3000 words NOT in any HSK level
                                   (= words a learner needs but HSK does not teach)
- output/hsk_unseen.tsv            HSK words that DO NOT appear in opus
                                   (or have very low freq) - vocab paid for but unused
"""
import os, csv
from collections import Counter, defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
FREQ = os.path.join(ROOT, "output", "word_freq.tsv")
HSK  = os.path.join(ROOT, "wordlists", "HSK_zispace_2021.txt")
OUT_MAP   = os.path.join(ROOT, "output", "hsk_word_map.tsv")
OUT_COV   = os.path.join(ROOT, "output", "hsk_coverage.tsv")
OUT_SEG   = os.path.join(ROOT, "output", "hsk_in_segments.tsv")
OUT_MISS  = os.path.join(ROOT, "output", "hsk_missing_top.tsv")
OUT_UNSEEN= os.path.join(ROOT, "output", "hsk_unseen.tsv")

# --- 1) load HSK ---
LEVEL_ORDER = ["一级","二级","三级","四级","五级","六级","高等"]
LEVEL_LABEL = {
    "一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4",
    "五级":"HSK5","六级":"HSK6","高等":"HSK7-9"
}
hsk_word2level = {}     # word -> short level label
level_words = defaultdict(set)
with open(HSK, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 5:
            continue
        word_field, pos, pinyin, ordn, level = parts[:5]
        # word_field can be "爸爸∣爸" - alternative forms separated by U+2223
        for word in word_field.split("∣"):
            word = word.strip()
            if not word:
                continue
            if word not in hsk_word2level:
                hsk_word2level[word] = LEVEL_LABEL.get(level, level)
            level_words[LEVEL_LABEL.get(level, level)].add(word)

print(f"[hsk] words: {len(hsk_word2level)}")
for lvl in ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9"]:
    print(f"  {lvl}: {len(level_words[lvl])}")
hskk_proxy = level_words["HSK4"] | level_words["HSK5"]
hsk4_cumul = level_words["HSK1"] | level_words["HSK2"] | level_words["HSK3"] | level_words["HSK4"]
print(f"  HSK4 cumulative: {len(hsk4_cumul)}")
print(f"  HSKK-mid proxy (HSK4∪HSK5): {len(hskk_proxy)}")

# --- 2) join with opus freq ---
opus_words = []
opus_freq = {}
opus_total = 0
with open(FREQ, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        w = row["word"]; fq = int(row["freq"])
        opus_words.append(w)
        opus_freq[w] = (int(row["rank"]), fq)
        opus_total += fq
print(f"[opus] vocab={len(opus_words):,}  tokens={opus_total:,}")

with open(OUT_MAP, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","freq","hsk_level"])
    for word in opus_words:
        rank, fq = opus_freq[word]
        w.writerow([rank, word, fq, hsk_word2level.get(word, "")])

# --- 3) coverage by level ---
level_token = Counter()  # tokens covered by each level
level_typecov = Counter()  # how many opus types appear in this level
for word in opus_words:
    rank, fq = opus_freq[word]
    lvl = hsk_word2level.get(word)
    if lvl:
        level_token[lvl] += fq
        level_typecov[lvl] += 1

with open(OUT_COV, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["bucket","hsk_words_total","opus_types_present","opus_token_coverage_pct"])
    cum_words = 0
    cum_types = 0
    cum_tokens = 0
    for lvl in ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9"]:
        cum_words += len(level_words[lvl])
        cum_types += level_typecov[lvl]
        cum_tokens += level_token[lvl]
        w.writerow([f"≤{lvl}", cum_words, cum_types,
                    f"{cum_tokens/opus_total*100:.4f}"])
        # also a per-level row
    # also report HSK4 cumulative & HSKK proxy explicitly
    hsk4_tokens = sum(opus_freq[wd][1] for wd in hsk4_cumul if wd in opus_freq)
    hsk4_types  = sum(1 for wd in hsk4_cumul if wd in opus_freq)
    hskk_tokens = sum(opus_freq[wd][1] for wd in hskk_proxy if wd in opus_freq)
    hskk_types  = sum(1 for wd in hskk_proxy if wd in opus_freq)
    w.writerow(["HSK4 cumulative (1~4)", len(hsk4_cumul), hsk4_types,
                f"{hsk4_tokens/opus_total*100:.4f}"])
    w.writerow(["HSKK-mid proxy (HSK4∪5)", len(hskk_proxy), hskk_types,
                f"{hskk_tokens/opus_total*100:.4f}"])

# --- 4) HSK levels by fixed segments ---
SEGS = [
    (1, 100), (101, 500), (501, 1000),
    (1001, 2000), (2001, 3000), (3001, 5000),
    (5001, 7000), (7001, 10000),
    (10001, 15000), (15001, 30000), (30001, len(opus_words)),
]

with open(OUT_SEG, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["lo","hi","vocab","HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9","none"])
    for lo, hi in SEGS:
        cnt = Counter()
        for i in range(lo-1, min(hi, len(opus_words))):
            lvl = hsk_word2level.get(opus_words[i], "none")
            cnt[lvl] += 1
        w.writerow([lo, hi, hi-lo+1] + [cnt.get(l, 0) for l in
                    ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9","none"]])

# --- 5) top opus words missing from HSK ---
with open(OUT_MISS, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","freq"])
    n = 0
    for word in opus_words:
        if word not in hsk_word2level:
            rank, fq = opus_freq[word]
            w.writerow([rank, word, fq])
            n += 1
            if n >= 500:
                break

# --- 6) HSK words unseen / rare in opus ---
with open(OUT_UNSEEN, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["hsk_level","word","opus_rank","opus_freq"])
    for word, lvl in hsk_word2level.items():
        if word not in opus_freq:
            w.writerow([lvl, word, "", 0])
        else:
            rank, fq = opus_freq[word]
            if fq < 5:
                w.writerow([lvl, word, rank, fq])

print(f"[done] {OUT_MAP}")
print(f"[done] {OUT_COV}")
print(f"[done] {OUT_SEG}")
print(f"[done] {OUT_MISS}")
print(f"[done] {OUT_UNSEEN}")
