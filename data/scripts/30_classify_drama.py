"""
Re-classify the 공개 말뭉치 zh_cn folders for the romance/drama analysis (L4).

Strategy:
- For tvEpisode rows in movies_classified.tsv, look up the parent series via
  title.episode.tsv.gz and inherit titleType / primaryTitle / startYear /
  genres / regions from the parent series in title.basics.tsv.gz +
  title.akas.tsv.gz.
- For tvSeries / tvMiniSeries rows, just copy through.
- For movie / tvMovie rows, copy through (used as the "movie baseline" corpus).
- Output a new TSV with columns:
    folder_year folder_id tconst content_type series_tconst
    series_title series_year series_genres series_regions
    is_modern_drama  is_romance  is_costume_excluded
  where:
    content_type = "movie" | "tv_drama" | "tv_other" | "skip"
    is_modern_drama = (content_type=="tv_drama") AND startYear>=2000
                      AND no costume/historical genre
    is_romance      = is_modern_drama AND ("Romance" OR
                      title hints at romance keywords)
    is_costume_excluded = genres include History/War or wuxia/古装 keywords

This produces meta/_drama/series_classified.tsv .
"""
import csv
import gzip
import os
import re
import sys
from collections import defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
META_DIR = os.path.join(ROOT, "meta")
DRAMA_DIR = os.path.join(META_DIR, "_drama")
os.makedirs(DRAMA_DIR, exist_ok=True)

INPUT_TSV = os.path.join(META_DIR, "movies_classified.tsv")
EPISODES_GZ = r"D:/OneDrive/DATA_Raw/imdb/title.episode.tsv.gz"
BASICS_GZ = os.path.join(META_DIR, "title.basics.tsv.gz")
AKAS_GZ = os.path.join(META_DIR, "title.akas.tsv.gz")
OUT_TSV = os.path.join(DRAMA_DIR, "series_classified.tsv")

CJK_RE = re.compile(r"[㐀-鿿]")
COSTUME_KEYWORDS = [
    "古装", "古裝", "宫廷", "宮廷", "皇帝", "皇后", "王爷", "王爺", "格格",
    "侠", "俠", "剑", "劍", "鏢", "镖", "江湖", "武林", "少林", "武当", "武當",
    "神雕", "笑傲", "倚天", "射雕", "天龙", "天龍", "鹿鼎", "金庸", "古龙",
    "古龍", "梁羽生", "公主", "太子", "丞相", "尚书", "尚書", "驸马", "駙馬",
]
ROMANCE_KEYWORDS = [
    "爱", "愛", "恋", "戀", "情", "心动", "心動", "心跳", "暗恋", "暗戀",
    "约会", "約會", "婚礼", "婚禮", "结婚", "結婚", "求婚", "失恋", "失戀",
    "kiss", "love", "romance",
]

# 1) Load existing folder/tconst rows
rows = []
with open(INPUT_TSV, "r", encoding="utf-8", newline="") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        rows.append(row)
print(f"[load] {len(rows)} folder rows", flush=True)

# Collect all needed tconsts (incl. parents to be looked up later)
folder_tconsts = set()
ep_tconsts = set()
for row in rows:
    t = row["tconst"]
    folder_tconsts.add(t)
    if row["titleType"] == "tvEpisode":
        ep_tconsts.add(t)

# 2) Look up episode -> parent in title.episode.tsv.gz
# columns: tconst parentTconst seasonNumber episodeNumber
episode_parent = {}  # episode_tconst -> parent_tconst
needed_parents = set()
print(f"[ep] scanning {EPISODES_GZ}", flush=True)
n = 0
with gzip.open(EPISODES_GZ, "rt", encoding="utf-8") as f:
    header = f.readline().rstrip("\n").split("\t")
    idx = {col: i for i, col in enumerate(header)}
    for line in f:
        n += 1
        row = line.rstrip("\n").split("\t")
        if len(row) < len(header):
            continue
        t = row[idx["tconst"]]
        if t not in ep_tconsts:
            continue
        p = row[idx["parentTconst"]]
        if p and p != "\\N":
            episode_parent[t] = p
            needed_parents.add(p)
print(f"[ep] scanned {n:,} rows; matched {len(episode_parent)} eps -> parents; "
      f"{len(needed_parents)} unique parents", flush=True)

# 3) Need basics for folder_tconsts + needed_parents
needed_basics = folder_tconsts | needed_parents
basics = {}
print(f"[basics] reading; need {len(needed_basics)} tconsts", flush=True)
with gzip.open(BASICS_GZ, "rt", encoding="utf-8") as f:
    header = f.readline().rstrip("\n").split("\t")
    idx = {col: i for i, col in enumerate(header)}
    for line in f:
        row = line.rstrip("\n").split("\t")
        if len(row) < len(header):
            continue
        t = row[idx["tconst"]]
        if t not in needed_basics:
            continue
        basics[t] = {
            "titleType":     row[idx["titleType"]],
            "primaryTitle":  row[idx["primaryTitle"]],
            "originalTitle": row[idx["originalTitle"]],
            "startYear":     row[idx["startYear"]],
            "genres":        row[idx["genres"]],
        }
print(f"[basics] matched {len(basics)} / {len(needed_basics)}", flush=True)

# 4) Need akas for parents (regions). Folder-level akas already in input row.
akas_regions = defaultdict(set)
print(f"[akas] reading parent akas", flush=True)
with gzip.open(AKAS_GZ, "rt", encoding="utf-8") as f:
    header = f.readline().rstrip("\n").split("\t")
    idx = {col: i for i, col in enumerate(header)}
    for line in f:
        row = line.rstrip("\n").split("\t")
        if len(row) < len(header):
            continue
        t = row[idx["titleId"]]
        if t not in needed_parents:
            continue
        region = row[idx["region"]]
        if region and region != "\\N":
            akas_regions[t].add(region)
print(f"[akas] regions for {len(akas_regions)} parents", flush=True)


def is_costume(genres, title):
    g_costume = any(g in genres for g in ("History", "War"))
    t = (title or "").lower()
    if any(kw.lower() in t for kw in COSTUME_KEYWORDS):
        return True
    return g_costume


def is_romance_genre(genres, title):
    if "Romance" in genres:
        return True
    t = (title or "").lower()
    return any(kw.lower() in t for kw in ROMANCE_KEYWORDS)


# 5) Emit classification
out_rows = []
for row in rows:
    folder_year = row["folder_year"]
    folder_id = row["folder_id"]
    folder_tconst = row["tconst"]
    folder_type = row["titleType"]
    folder_genres = row["genres"]
    folder_year_meta = row["startYear"]
    folder_title = row["primaryTitle"]

    if folder_type == "tvEpisode":
        # promote to series
        parent = episode_parent.get(folder_tconst)
        b = basics.get(parent) if parent else None
        if b is None:
            content_type = "skip"
            series_tconst = parent or ""
            series_title = ""
            series_year = ""
            series_genres = ""
            series_regions = ""
        else:
            series_tconst = parent
            series_title = b["primaryTitle"]
            series_year = b["startYear"]
            series_genres = b["genres"]
            series_regions = ",".join(sorted(akas_regions.get(parent, set())))
            content_type = "tv_drama" if (b["titleType"] in ("tvSeries", "tvMiniSeries") and "Animation" not in series_genres) else "tv_other"
    elif folder_type in ("tvSeries", "tvMiniSeries"):
        series_tconst = folder_tconst
        series_title = folder_title
        series_year = folder_year_meta
        series_genres = folder_genres
        series_regions = row.get("regions", "")
        content_type = "tv_drama" if "Animation" not in series_genres else "tv_other"
    elif folder_type in ("movie", "tvMovie"):
        # baseline movie corpus (excluding wuxia/foreign/HK as before)
        if row.get("keep") == "1":
            content_type = "movie"
        else:
            content_type = "skip"
        series_tconst = folder_tconst
        series_title = folder_title
        series_year = folder_year_meta
        series_genres = folder_genres
        series_regions = row.get("regions", "")
    else:
        content_type = "skip"
        series_tconst = folder_tconst
        series_title = folder_title
        series_year = folder_year_meta
        series_genres = folder_genres
        series_regions = row.get("regions", "")

    try:
        sy = int(series_year) if series_year and series_year != "\\N" else 0
    except ValueError:
        sy = 0

    is_modern = (content_type == "tv_drama") and sy >= 2000 and not is_costume(series_genres, series_title)
    is_costume_x = (content_type == "tv_drama") and is_costume(series_genres, series_title)
    is_romance = is_modern and is_romance_genre(series_genres, series_title)

    out_rows.append({
        "folder_year": folder_year,
        "folder_id": folder_id,
        "tconst": folder_tconst,
        "folder_type": folder_type,
        "content_type": content_type,
        "series_tconst": series_tconst,
        "series_title": series_title,
        "series_year": series_year,
        "series_genres": series_genres,
        "series_regions": series_regions,
        "is_modern_drama": "1" if is_modern else "0",
        "is_romance": "1" if is_romance else "0",
        "is_costume_excluded": "1" if is_costume_x else "0",
    })

with open(OUT_TSV, "w", encoding="utf-8", newline="") as f:
    fields = list(out_rows[0].keys())
    w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
    w.writeheader()
    w.writerows(out_rows)
print(f"[write] {OUT_TSV}", flush=True)

# Summary
from collections import Counter
type_count = Counter(r["content_type"] for r in out_rows)
print(f"[summary] content_type:")
for k, v in type_count.most_common():
    print(f"  {k:12s}  {v:6d}")
modern = sum(1 for r in out_rows if r["is_modern_drama"] == "1")
romance = sum(1 for r in out_rows if r["is_romance"] == "1")
costume = sum(1 for r in out_rows if r["is_costume_excluded"] == "1")
print(f"[summary] is_modern_drama : {modern}")
print(f"[summary] is_romance      : {romance}")
print(f"[summary] is_costume_x    : {costume}")
