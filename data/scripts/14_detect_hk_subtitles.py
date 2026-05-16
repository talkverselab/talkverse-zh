"""
Per-subtitle (per-XML) detection of Hong Kong (Cantonese) subtitle files.

Procedure:
- Walk corpus_kept.txt (the original, NOT OpenCC-converted, so traditional and
  Cantonese chars survive). We use stats.tsv to bound each XML.
- For each XML, count:
    n_total_chars
    n_traditional_chars (chars that exist in traditional set)
    n_cantonese_only_chars (chars from a Cantonese-specific set)
- Decision:
    n_canto >= 5 OR (n_canto / n_total >= 0.001)  → HK
    OR (n_traditional/n_total > 0.30 AND n_canto >= 1) → HK
    Else if n_traditional/n_total > 0.30 → Taiwan-style (KEEP, will be normalized)
    Else → Mainland (KEEP)

Output:
- output/subtitle_classification.tsv  per-XML: tconst, file, n_lines, n_chars,
                                       n_trad, n_canto, ratio_trad, decision
- output/hk_movies.txt                 list of tconsts to exclude
"""
import os, csv, time, re
from collections import defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
CORPUS = os.path.join(ROOT, "text", "corpus_kept.txt")    # original (not s)
STATS  = os.path.join(ROOT, "text", "corpus_kept.stats.tsv")
OUT    = os.path.join(ROOT, "output", "subtitle_classification.tsv")
OUT_HK = os.path.join(ROOT, "output", "hk_movies.txt")

# STRICT Cantonese-only characters (본토/대만 자막에는 사실상 등장하지 않음).
# 'Loose' set (係·俾·緊·啦) is intentionally REMOVED — those have non-Cantonese
# meanings in standard Mandarin and inflate false positives.
CANTO = set("嘅啲冇唔咗哋嗰嚟喺攰乜嘢咩噃喎嘞囉嚿嗌嬲諗㗎啩")

# Traditional-only characters (간체 사용자 본토 자막에는 등장 빈도 매우 낮음).
# Use a conservative set; we will treat ratio_trad as a SECONDARY signal only.
TRAD = set("們國學來對時後體業機條場開發聲萬議識連區強別復過應遠觀為點義親確戰種員無與東車門間問書馬鳥魚電話語請說讀寫聽見覺愛習動腦頭髮雙親愛長壽風雪雲飛龍鳳麗華實寫劇場員務經濟營業飛機關係統檢驗團體會員號碼興奮樂園歡樂節慶賀禮儀廣場縣鄉鎮邊際團聚別離歸鄉灣漢語譯製樣樂團藝術術士兵團隊隊長將軍勳爵車輛輛數樓層層次次序媽傭人員警察察覺察看見識破壞蛋這個們將開來說對發飛種觀為個體經學習題從業時長馬車內進關係媽會議論幾條間問識見過裡裏雙處組織處員")

print("[scan] reading stats", flush=True)
file_segments = []
with open(STATS, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        file_segments.append((row["tconst"], row["xml_file"], int(row["lines"])))

print(f"[scan] {len(file_segments)} XML files", flush=True)

results = []
seg_iter = iter(file_segments)
cur_tconst, cur_file, cur_remaining = next(seg_iter)
cur_n_lines = 0
cur_n_chars = 0
cur_n_trad = 0
cur_n_canto = 0

t0 = time.time(); last = t0
total_lines = 0

with open(CORPUS, "r", encoding="utf-8") as f:
    for line in f:
        while cur_remaining == 0:
            # finalize current segment
            results.append((cur_tconst, cur_file, cur_n_lines, cur_n_chars, cur_n_trad, cur_n_canto))
            cur_n_lines = cur_n_chars = cur_n_trad = cur_n_canto = 0
            try:
                cur_tconst, cur_file, cur_remaining = next(seg_iter)
            except StopIteration:
                cur_tconst = None
                break
        if cur_tconst is None: break

        cur_remaining -= 1
        cur_n_lines += 1
        for c in line:
            if '一' <= c <= '鿿':
                cur_n_chars += 1
                if c in TRAD:  cur_n_trad += 1
                if c in CANTO: cur_n_canto += 1

        total_lines += 1
        if total_lines % 500000 == 0:
            now = time.time()
            print(f"  ... lines={total_lines:,}  files done={len(results):,}  ({total_lines/(now-t0):.0f} l/s)", flush=True)

# finalize last
if cur_tconst is not None and cur_n_chars > 0:
    results.append((cur_tconst, cur_file, cur_n_lines, cur_n_chars, cur_n_trad, cur_n_canto))

print(f"[done] {len(results)} files processed", flush=True)

# Decision per file
hk_files = []
trad_only_files = []
mainland_files = []
xml_decisions = []
for tconst, fl, n_lines, n_chars, n_trad, n_canto in results:
    if n_chars == 0:
        decision = "empty"
    else:
        ratio_trad = n_trad / n_chars
        ratio_canto = n_canto / n_chars
        # Cantonese-only chars are the PRIMARY signal.
        # ≥10 strict-canto chars OR canto density ≥ 0.0005 → HK
        if n_canto >= 10 or ratio_canto >= 0.0005:
            decision = "HK"
        elif n_canto >= 3 and ratio_trad >= 0.10:
            decision = "HK_likely"
        elif ratio_trad >= 0.10:
            decision = "Trad_TW_likely"   # 대만 번체로 추정 (광동어 신호 없음)
        else:
            decision = "Mainland"
    xml_decisions.append((tconst, fl, n_lines, n_chars, n_trad, n_canto,
                          n_trad/n_chars if n_chars else 0,
                          n_canto/n_chars if n_chars else 0,
                          decision))
    if decision == "HK":
        hk_files.append((tconst, fl))

# Aggregate per-tconst: a movie is HK if ANY of its subtitles is decided HK.
# 'HK_likely' is borderline — also remove. 'Trad_TW_likely' is KEPT (대만 본토 통합 가능).
remove_decisions = {"HK", "HK_likely"}
hk_tconsts = sorted(set(d[0] for d in xml_decisions if d[8] in remove_decisions))

with open(OUT, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["tconst","xml","lines","chars","n_trad","n_canto","ratio_trad","ratio_canto","decision"])
    for row in xml_decisions:
        w.writerow(list(row[:6]) + [f"{row[6]:.4f}", f"{row[7]:.6f}", row[8]])

with open(OUT_HK, "w", encoding="utf-8") as f:
    for t in hk_tconsts:
        f.write(t + "\n")

# Stats
from collections import Counter
dec_counts = Counter(d[8] for d in xml_decisions)
print()
print("=== XML 단위 분류 ===")
for k, n in dec_counts.most_common():
    print(f"  {k}: {n} ({n/len(xml_decisions)*100:.1f}%)")
print(f"\n=== HK 영화 (any HK subtitle) tconsts: {len(hk_tconsts)} 개 ===")
print(f"[done] {OUT}")
print(f"[done] {OUT_HK}")
