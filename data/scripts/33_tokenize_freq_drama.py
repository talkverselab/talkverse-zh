"""
Tokenize the drama and romance corpora and produce:
- per-corpus word_freq (TSV: word, count, doc_count)
- per-corpus hanzi_freq (TSV: hanzi, count, doc_count)
"""
import os, re, csv, time
from collections import Counter, defaultdict
import jieba

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
DRAMA_TXT = os.path.join(ROOT, "text", "_drama", "corpus_modern_drama_s.txt")
DRAMA_STATS = os.path.join(ROOT, "text", "_drama", "corpus_modern_drama.stats.tsv")
ROM_TXT = os.path.join(ROOT, "text", "_drama", "corpus_romance_s.txt")
ROM_STATS = os.path.join(ROOT, "text", "_drama", "corpus_romance.stats.tsv")

OUT_DIR = os.path.join(ROOT, "output", "_drama")
os.makedirs(OUT_DIR, exist_ok=True)

ALL_CJK = re.compile(r"^[㐀-鿿]+$")
ONE_CJK = re.compile(r"[㐀-鿿]")


def load_segments(stats_path):
    """Return list of (series_tconst, lines_in_file) preserving file order."""
    segs = []
    with open(stats_path, "r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f, delimiter="\t")
        for row in r:
            segs.append((row["series_tconst"], int(row["lines"])))
    return segs


def analyze(corpus_path, stats_path, label):
    print(f"\n[{label}] tokenize {corpus_path}", flush=True)
    segs = load_segments(stats_path)
    print(f"[{label}] {len(segs)} files / {sum(n for _, n in segs):,} lines", flush=True)

    word_total = Counter()
    word_doc = defaultdict(set)   # word -> set of series_tconsts
    hanzi_total = Counter()
    hanzi_doc = defaultdict(set)

    seg_iter = iter(segs)
    cur_series, cur_remaining = next(seg_iter)
    t0 = time.time(); last = t0
    n_lines = n_tokens = 0

    with open(corpus_path, "r", encoding="utf-8") as f:
        for line in f:
            while cur_remaining == 0:
                try:
                    cur_series, cur_remaining = next(seg_iter)
                except StopIteration:
                    cur_series = None
                    break
            if cur_series is None:
                break
            cur_remaining -= 1
            n_lines += 1
            line = line.strip()
            if not line:
                continue
            for tok in jieba.cut(line, HMM=True):
                if not ALL_CJK.match(tok):
                    continue
                word_total[tok] += 1
                word_doc[tok].add(cur_series)
                n_tokens += 1
                # also accumulate hanzi
                for ch in tok:
                    hanzi_total[ch] += 1
                    hanzi_doc[ch].add(cur_series)
            if n_lines % 200000 == 0:
                now = time.time()
                print(f"  ... lines={n_lines:,} tokens={n_tokens:,}  "
                      f"({n_lines/(now-t0):.0f} l/s)", flush=True)

    print(f"[{label}] tokens={n_tokens:,} unique_words={len(word_total):,} "
          f"unique_hanzi={len(hanzi_total):,}", flush=True)

    # write word freq
    out_words = os.path.join(OUT_DIR, f"word_freq_{label}.tsv")
    with open(out_words, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["word", "count", "doc_count"])
        for word, c in word_total.most_common():
            w.writerow([word, c, len(word_doc[word])])
    print(f"[{label}] wrote {out_words}")

    out_hanzi = os.path.join(OUT_DIR, f"hanzi_freq_{label}.tsv")
    with open(out_hanzi, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["hanzi", "count", "doc_count"])
        for ch, c in hanzi_total.most_common():
            w.writerow([ch, c, len(hanzi_doc[ch])])
    print(f"[{label}] wrote {out_hanzi}")


jieba.initialize()
analyze(DRAMA_TXT, DRAMA_STATS, "drama")
analyze(ROM_TXT, ROM_STATS, "romance")
