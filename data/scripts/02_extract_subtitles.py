"""
Extract subtitle text from kept movies' XML files into a single text corpus.

Input:
- meta/movies_classified.tsv  (column 'keep' = "1" means include)
- raw/OpenSubtitles/raw/zh_cn/{year}/{imdb_id}/*.xml

Output:
- text/corpus_kept.txt        (one subtitle line per file line, blank lines between files)
- text/corpus_kept.stats.tsv  (per-file: tconst, file, lines, chars)

In zh_cn (v2018) the OPUS XML is NOT pre-tokenized. Structure:
    <document id="...">
      <s id="1">
        <time id="T1S" value="..." />
        他的故事...                <-- text directly inside <s>
        <time id="T1E" value="..." />
      </s>
      ...
    </document>

We use s.itertext() to collect everything except the <time> tags, joined.
"""
import csv
import os
import sys
import glob
import time
from xml.etree import ElementTree as ET

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
RAW_DIR = os.path.join(ROOT, "raw", "OpenSubtitles", "raw", "zh_cn")
META_TSV = os.path.join(ROOT, "meta", "movies_classified.tsv")
OUT_CORPUS = os.path.join(ROOT, "text", "corpus_kept.txt")
OUT_STATS  = os.path.join(ROOT, "text", "corpus_kept.stats.tsv")

# 1) load 'keep' folders
keep = []
with open(META_TSV, "r", encoding="utf-8", newline="") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        if row["keep"] == "1":
            keep.append((row["folder_year"], row["folder_id"], row["tconst"]))
print(f"[load] keep movies: {len(keep)}", flush=True)

# 2) walk and extract
total_files = total_lines = total_chars = 0
t0 = time.time()
last_print = t0

with open(OUT_CORPUS, "w", encoding="utf-8") as fout, \
     open(OUT_STATS,  "w", encoding="utf-8", newline="") as fstats:
    sw = csv.writer(fstats, delimiter="\t", lineterminator="\n")
    sw.writerow(["tconst","year","folder_id","xml_file","lines","chars"])

    for year, fid, tconst in keep:
        d = os.path.join(RAW_DIR, year, fid)
        if not os.path.isdir(d):
            continue
        for xml in glob.glob(os.path.join(d, "*.xml")):
            try:
                tree = ET.parse(xml)
            except ET.ParseError:
                continue
            root = tree.getroot()
            file_lines = 0
            file_chars = 0
            for s in root.iter("s"):
                # collect everything except <time> contents (they have no text anyway,
                # but their tails may carry whitespace). itertext walks children too,
                # but <time> elements are self-closing so they yield nothing.
                line = "".join(s.itertext())
                # collapse whitespace
                line = " ".join(line.split())
                if not line:
                    continue
                fout.write(line + "\n")
                file_lines += 1
                file_chars += len(line)
            sw.writerow([tconst, year, fid, os.path.basename(xml), file_lines, file_chars])
            total_files += 1
            total_lines += file_lines
            total_chars += file_chars

            now = time.time()
            if now - last_print > 5:
                last_print = now
                rate = total_files / max(1e-6, now - t0)
                print(f"  ... files={total_files} lines={total_lines:,} chars={total_chars:,}"
                      f"  ({rate:.1f} files/s)", flush=True)

print()
print(f"[done] files={total_files} lines={total_lines:,} chars={total_chars:,}")
print(f"[done] corpus={OUT_CORPUS}  stats={OUT_STATS}")
print(f"[done] elapsed={time.time()-t0:.1f}s")
