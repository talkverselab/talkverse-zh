"""
Classify zh_cn 공개 말뭉치 movies using 작품 메타데이터 metadata.
- folder name -> 작품 메타데이터 tconst (zero-padded to 7 digits, prefixed with 'tt')
- Read title.basics.tsv.gz for genres / originalTitle / startYear
- Read title.akas.tsv.gz for regions (CN/HK/TW/US/etc.) and language codes
- Heuristics:
    is_foreign  = originalTitle has NO CJK chars AND no zh-* language akas
                  AND no CN/HK/TW region akas
    is_hk       = any aka with region=HK and (the originalTitle has CJK or there is a zh-Hant aka)
                  OR a CN/HK/TW region aka whose primary region is HK
    is_wuxia    = heuristic: genres include Action / Adventure / History / Drama / Fantasy
                  AND title or akas contain wuxia keywords
                  (鏢 镖 剑 劍 侠 俠 武 江湖 武林 少林 神雕 笑傲 倚天 射雕 大俠 大侠 ...)
                  AND not foreign

Output: meta/movies_classified.tsv with columns:
    folder_year folder_id tconst titleType primaryTitle originalTitle startYear genres regions akas_langs flags
"""
import gzip
import os
import sys
import csv
import re
import glob
from collections import defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
RAW_DIR = os.path.join(ROOT, "raw", "공개 말뭉치", "raw", "zh_cn")
META_DIR = os.path.join(ROOT, "meta")
OUT_TSV = os.path.join(META_DIR, "movies_classified.tsv")

# ----- 1. enumerate folders we actually have -----
folder_pairs = []   # (year, imdb_id)
tconst_map = {}     # tconst -> (year, id)
for year in sorted(os.listdir(RAW_DIR)):
    yp = os.path.join(RAW_DIR, year)
    if not os.path.isdir(yp):
        continue
    for imdb_id in os.listdir(yp):
        ip = os.path.join(yp, imdb_id)
        if not os.path.isdir(ip):
            continue
        # build tconst: zero-pad to at least 7 digits
        try:
            num = int(imdb_id)
        except ValueError:
            continue
        tconst = "tt" + str(num).zfill(7)
        folder_pairs.append((year, imdb_id, tconst))
        tconst_map[tconst] = (year, imdb_id)

print(f"[scan] folders={len(folder_pairs)} unique_tconst={len(tconst_map)}", flush=True)

needed = set(tconst_map.keys())

# regex used by both akas loop and classification
CJK_RE_GLOBAL = re.compile(r"[一-鿿㐀-䶿]")

# ----- 2. parse title.basics.tsv.gz -----
basics = {}  # tconst -> dict
with gzip.open(os.path.join(META_DIR, "title.basics.tsv.gz"), "rt", encoding="utf-8") as f:
    header = f.readline().rstrip("\n").split("\t")
    idx = {n: i for i, n in enumerate(header)}
    for line in f:
        row = line.rstrip("\n").split("\t")
        if len(row) < len(header):
            continue
        t = row[idx["tconst"]]
        if t not in needed:
            continue
        basics[t] = {
            "titleType":     row[idx["titleType"]],
            "primaryTitle":  row[idx["primaryTitle"]],
            "originalTitle": row[idx["originalTitle"]],
            "startYear":     row[idx["startYear"]],
            "genres":        row[idx["genres"]],
        }
print(f"[basics] matched {len(basics)} / {len(needed)} tconsts", flush=True)

# ----- 3. parse title.akas.tsv.gz, collect regions & languages per tconst -----
akas_regions = defaultdict(set)  # tconst -> set of regions
akas_langs   = defaultdict(set)  # tconst -> set of languages
akas_titles_cjk = defaultdict(list)  # tconst -> list of CJK aka titles
with gzip.open(os.path.join(META_DIR, "title.akas.tsv.gz"), "rt", encoding="utf-8") as f:
    header = f.readline().rstrip("\n").split("\t")
    idx = {n: i for i, n in enumerate(header)}
    for line in f:
        row = line.rstrip("\n").split("\t")
        if len(row) < len(header):
            continue
        t = row[idx["titleId"]]
        if t not in needed:
            continue
        region = row[idx["region"]]
        lang   = row[idx["language"]]
        title  = row[idx["title"]]
        if region and region != "\\N":
            akas_regions[t].add(region)
        if lang and lang != "\\N":
            akas_langs[t].add(lang)
        if title and CJK_RE_GLOBAL.search(title):
            akas_titles_cjk[t].append(title)
print(f"[akas] regions for {len(akas_regions)} tconsts, langs for {len(akas_langs)} tconsts, cjk titles for {len(akas_titles_cjk)}", flush=True)

# ----- 4. classify -----
CJK_RE = CJK_RE_GLOBAL
WUXIA_KEYWORDS = [
    "镖", "鏢", "剑", "劍", "侠", "俠", "武林", "江湖",
    "少林", "武当", "武當", "峨眉", "峨嵋",
    "神雕", "笑傲", "倚天", "射雕", "天龙", "天龍", "鹿鼎",
    "大侠", "大俠", "豪侠", "豪俠", "剑客", "劍客",
    "刀剑", "刀劍", "剑魔", "劍魔", "刀客",
    "侠客", "俠客", "义士", "義士", "壯士", "壮士",
    "武功", "功夫", "拳法", "刀法", "剑法", "劍法",
    "宗师", "宗師", "门派", "門派",
    "武侠", "武俠",
    "金庸", "古龙", "古龍", "梁羽生",
]

def has_cjk(s):
    return bool(CJK_RE.search(s or ""))

def cjk_ratio(s):
    if not s:
        return 0.0
    cjk = len(CJK_RE.findall(s))
    return cjk / max(1, len(s))

# Traditional-only characters (do not appear in simplified Chinese).
# Curated common set; presence implies the title is written in 繁體字 (HK/TW).
TRAD_ONLY = set(
    "個們國學來對時後體業機條場開發聲萬議識連區強別復過應遠觀為點義親確戰種員"
    "無與東車門間問書馬鳥魚電話語請說讀寫聽見覺愛學習動腦頭髮雙親愛長壽"
    "東風雪雲飛龍鳳麗華實寫劇場員務經濟營業飛機關係係統檢驗團體會員號碼"
    "風雲變幻興奮樂園歡樂節慶賀禮儀廣場縣鄉鎮邊際團聚別離歸鄉鄉愁"
    "灣漢語語言譯譯製樣樣式樂團藝術術士兵團隊隊長將軍勳爵爵士士兵"
    "車輛輛數樓層層次次序序幕幕後後續續集集團團員員工工廠廠長長期"
    "媽媽媽傭傭人人員員警警察察覺覺察察看看見見識識破破壞壞蛋"
)

count_total = 0
count_foreign = count_hk = count_wuxia = 0
count_no_basics = 0
count_keep = 0

with open(OUT_TSV, "w", encoding="utf-8", newline="") as out:
    w = csv.writer(out, delimiter="\t", lineterminator="\n")
    w.writerow([
        "folder_year","folder_id","tconst","titleType","primaryTitle","originalTitle",
        "startYear","genres","regions","akas_langs",
        "is_foreign","is_hk","is_wuxia","keep"
    ])
    for year, imdb_id, tconst in folder_pairs:
        count_total += 1
        b = basics.get(tconst)
        regions = sorted(akas_regions.get(tconst, set()))
        langs   = sorted(akas_langs.get(tconst, set()))
        if not b:
            count_no_basics += 1
            # If no 작품 메타데이터 basics, we cannot classify. Keep but flag.
            w.writerow([year, imdb_id, tconst, "", "", "", "", "",
                        ",".join(regions), ",".join(langs),
                        "0", "0", "0", "1"])
            count_keep += 1
            continue

        title = b["originalTitle"] or b["primaryTitle"]
        genres = b["genres"] or ""
        title_cjk = has_cjk(title)
        # zh language signals
        has_zh_lang = any(l.startswith("zh") or l in ("cmn","yue","wuu","nan","hak") for l in langs)
        has_cn_region = any(r in ("CN","HK","TW","SG","MO") for r in regions)

        # Foreign movie heuristic: originalTitle has no CJK
        # AND no zh-* aka language AND no CN/HK/TW/SG region aka
        # AND there is at least one Latin-region aka (US/GB/etc) or any aka with Latin language
        is_foreign = (not title_cjk) and (not has_zh_lang) and (not has_cn_region)

        # Hong Kong heuristic: originalTitle is in CJK AND contains traditional-only character
        # (Taiwan already excluded; in zh_cn corpus, traditional-script titles imply HK origin).
        is_hk = title_cjk and any(c in TRAD_ONLY for c in title)

        # Wuxia heuristic: keyword in any title (incl. CJK akas) + martial-flavor genre + not foreign
        check_titles = [b["originalTitle"] or "", b["primaryTitle"] or ""] + akas_titles_cjk.get(tconst, [])
        check_str = " ".join(check_titles)
        kw_hit = any(kw in check_str for kw in WUXIA_KEYWORDS)
        martial_genre = any(g in genres for g in ("Action","Adventure","History","Fantasy","Drama","War"))
        is_wuxia = kw_hit and martial_genre and not is_foreign

        if is_foreign: count_foreign += 1
        if is_hk:      count_hk += 1
        if is_wuxia:   count_wuxia += 1

        keep = (not is_foreign) and (not is_hk) and (not is_wuxia)
        if keep:
            count_keep += 1

        w.writerow([
            year, imdb_id, tconst,
            b["titleType"], b["primaryTitle"], b["originalTitle"],
            b["startYear"], genres,
            ",".join(regions), ",".join(langs),
            "1" if is_foreign else "0",
            "1" if is_hk      else "0",
            "1" if is_wuxia   else "0",
            "1" if keep       else "0",
        ])

print()
print(f"[summary] total folders     : {count_total}")
print(f"[summary] no 작품 메타데이터 basics    : {count_no_basics} (kept as unknown)")
print(f"[summary] foreign movie     : {count_foreign}")
print(f"[summary] hong kong movie   : {count_hk}")
print(f"[summary] wuxia (heuristic) : {count_wuxia}")
print(f"[summary] kept              : {count_keep}")
print(f"[summary] output            : {OUT_TSV}")
