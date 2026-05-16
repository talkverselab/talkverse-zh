"""
Extract subtitle text for Phase 4 (drama / romance) analysis.

Inputs:
- meta/_drama/series_classified.tsv  (with content_type, is_modern_drama, is_romance)
- raw/OpenSubtitles/raw/zh_cn/{year}/{folder_id}/*.xml

Outputs (in text/_drama/):
- corpus_modern_drama.txt        all modern (non-costume) tv_drama folders
- corpus_modern_drama.stats.tsv  per-file stats (tconst, lines, chars)
- corpus_romance.txt             romance subset (Romance genre or romance keywords)
- corpus_romance.stats.tsv

The "movie baseline" corpus (corpus_kept_s.txt) already exists at text/.

We use OpenCC normalization at extraction time -- but the existing pipeline
already maintains a normalized corpus_kept_s.txt. To keep things consistent,
we leave normalization to a follow-up script (32_normalize.py) and dump raw
text here.
"""
import csv
import glob
import os
import sys
import time
from xml.etree import ElementTree as ET

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
RAW_DIR = os.path.join(ROOT, "raw", "OpenSubtitles", "raw", "zh_cn")
META_TSV = os.path.join(ROOT, "meta", "_drama", "series_classified.tsv")
OUT_DIR = os.path.join(ROOT, "text", "_drama")
os.makedirs(OUT_DIR, exist_ok=True)

OUT_DRAMA_TXT = os.path.join(OUT_DIR, "corpus_modern_drama.txt")
OUT_DRAMA_STATS = os.path.join(OUT_DIR, "corpus_modern_drama.stats.tsv")
OUT_ROMANCE_TXT = os.path.join(OUT_DIR, "corpus_romance.txt")
OUT_ROMANCE_STATS = os.path.join(OUT_DIR, "corpus_romance.stats.tsv")

drama_folders = []   # list of (year, fid, tconst, series_tconst)
romance_folders = []

with open(META_TSV, "r", encoding="utf-8", newline="") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        if row["is_modern_drama"] == "1":
            tup = (row["folder_year"], row["folder_id"], row["tconst"],
                   row["series_tconst"])
            drama_folders.append(tup)
            if row["is_romance"] == "1":
                romance_folders.append(tup)
print(f"[load] modern drama folders: {len(drama_folders)}", flush=True)
print(f"[load] romance folders     : {len(romance_folders)}", flush=True)


def extract_set(folders, txt_path, stats_path, label):
    print(f"\n[{label}] extracting {len(folders)} folders -> {txt_path}", flush=True)
    total_files = total_lines = total_chars = 0
    t0 = time.time(); last = t0
    with open(txt_path, "w", encoding="utf-8") as fout, \
         open(stats_path, "w", encoding="utf-8", newline="") as fstats:
        sw = csv.writer(fstats, delimiter="\t", lineterminator="\n")
        sw.writerow(["tconst", "series_tconst", "year", "folder_id",
                     "xml_file", "lines", "chars"])
        for year, fid, tconst, series_tc in folders:
            d = os.path.join(RAW_DIR, year, fid)
            if not os.path.isdir(d):
                continue
            for xml in glob.glob(os.path.join(d, "*.xml")):
                try:
                    tree = ET.parse(xml)
                except (ET.ParseError, FileNotFoundError):
                    continue
                root = tree.getroot()
                fl = fc = 0
                for s in root.iter("s"):
                    line = "".join(s.itertext())
                    line = " ".join(line.split())
                    if not line:
                        continue
                    fout.write(line + "\n")
                    fl += 1
                    fc += len(line)
                sw.writerow([tconst, series_tc, year, fid,
                             os.path.basename(xml), fl, fc])
                total_files += 1
                total_lines += fl
                total_chars += fc
                now = time.time()
                if now - last > 5:
                    print(f"  ... files={total_files:,} lines={total_lines:,} "
                          f"chars={total_chars:,}", flush=True)
                    last = now
    print(f"[{label}] done: {total_files} files, {total_lines:,} lines, "
          f"{total_chars:,} chars in {time.time()-t0:.1f}s", flush=True)


extract_set(drama_folders, OUT_DRAMA_TXT, OUT_DRAMA_STATS, "drama")
extract_set(romance_folders, OUT_ROMANCE_TXT, OUT_ROMANCE_STATS, "romance")
