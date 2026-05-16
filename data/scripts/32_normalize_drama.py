"""
OpenCC t2s normalization for drama and romance corpora.
"""
import os, time
from opencc import OpenCC

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
PAIRS = [
    (os.path.join(ROOT, "text", "_drama", "corpus_modern_drama.txt"),
     os.path.join(ROOT, "text", "_drama", "corpus_modern_drama_s.txt")),
    (os.path.join(ROOT, "text", "_drama", "corpus_romance.txt"),
     os.path.join(ROOT, "text", "_drama", "corpus_romance_s.txt")),
]

cc = OpenCC("t2s")
for src, dst in PAIRS:
    print(f"[start] {src} -> {dst}", flush=True)
    t0 = time.time()
    n = 0
    with open(src, "r", encoding="utf-8") as fin, \
         open(dst, "w", encoding="utf-8") as fout:
        for line in fin:
            fout.write(cc.convert(line))
            n += 1
            if n % 500_000 == 0:
                now = time.time()
                print(f"  ... lines={n:,}  ({n/(now-t0):.0f} l/s)", flush=True)
    print(f"[done] {n:,} lines in {time.time()-t0:.1f}s")
