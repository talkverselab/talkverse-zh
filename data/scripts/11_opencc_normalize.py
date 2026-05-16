"""
Run OpenCC t2s ('Traditional → Simplified') over corpus_kept.txt and produce
corpus_kept_s.txt (간체 통일).

Then re-run per-CD tokenization on the new corpus.

Approach:
- OpenCC t2s.json includes some lexical mappings (軟體→软件 etc) but
  reimplemented package may use t2s only. We use t2s (character-level) which is
  the safest baseline; lexical normalization can be a separate step later.
"""
import os, sys, time
from opencc import OpenCC

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
SRC = os.path.join(ROOT, "text", "corpus_kept.txt")
DST = os.path.join(ROOT, "text", "corpus_kept_s.txt")

cc = OpenCC("t2s")
print(f"[start] {SRC} -> {DST}", flush=True)
t0 = time.time(); last = t0
n = 0
with open(SRC, "r", encoding="utf-8") as fin, \
     open(DST, "w", encoding="utf-8") as fout:
    for line in fin:
        fout.write(cc.convert(line))
        n += 1
        if n % 500_000 == 0:
            now = time.time()
            print(f"  ... lines={n:,}  ({n/(now-t0):.0f} lines/s)", flush=True)

print(f"[done] {n:,} lines  elapsed={time.time()-t0:.1f}s")
