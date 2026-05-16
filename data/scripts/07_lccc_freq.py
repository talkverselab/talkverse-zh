"""
Read first N dialogues from LCCC-base train.jsonl.gz and produce
a word-frequency table compatible with output/word_freq.tsv.

LCCC tokens are already space-separated (jieba-tokenized at curation time).

Usage:
   python 07_lccc_freq.py 50000        # process first 50K dialogues
   python 07_lccc_freq.py 1000000      # process first 1M
"""
import os, sys, gzip, json, re, time, csv
from collections import Counter

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
SRC = r"D:/OneDrive/DATA_Raw/languages/zh/chat/silver__lccc/lccc_base_train.jsonl.gz"

n = int(sys.argv[1]) if len(sys.argv) > 1 else 50000
OUT = os.path.join(ROOT, "output", f"lccc_freq_{n}.tsv")

ALL_CJK = re.compile(r"^[一-鿿㐀-䶿]+$")

t0 = time.time()
counter = Counter()
total_dialogues = 0
total_utts = 0
total_tokens_raw = 0
total_tokens_kept = 0
last = t0

with gzip.open(SRC, "rt", encoding="utf-8") as f:
    for i, line in enumerate(f):
        if i >= n:
            break
        d = json.loads(line)
        total_dialogues += 1
        for utt in d:
            total_utts += 1
            for tok in utt.split(" "):
                tok = tok.strip()
                if not tok:
                    continue
                total_tokens_raw += 1
                if ALL_CJK.match(tok):
                    counter[tok] += 1
                    total_tokens_kept += 1
        now = time.time()
        if now - last > 5:
            last = now
            print(f"  ... dialogues={total_dialogues:,} kept_tokens={total_tokens_kept:,}"
                  f" vocab={len(counter):,} ({total_dialogues/(now-t0):.0f}/s)", flush=True)

print(f"[done] dialogues={total_dialogues:,}  utts={total_utts:,}  raw={total_tokens_raw:,}  "
      f"kept={total_tokens_kept:,}  vocab={len(counter):,}", flush=True)

items = counter.most_common()
total = total_tokens_kept
with open(OUT, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","freq","cum_freq","cum_pct"])
    cum = 0
    for i, (word, freq) in enumerate(items, 1):
        cum += freq
        w.writerow([i, word, freq, cum, f"{cum/total*100:.4f}"])

print(f"[done] {OUT}  elapsed={time.time()-t0:.1f}s")
