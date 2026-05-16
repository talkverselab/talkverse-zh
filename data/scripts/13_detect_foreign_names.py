"""
Detect probable foreign person/place names that survived in opus rank ≤ 5000
even after CD-weighting + OpenCC normalization.

Heuristic ensemble (a word is flagged as a foreign name if it scores ≥3):
  H1. NOT in HSK 1-9.
  H2. Length 2-4 characters, all CJK.
  H3. Contains ≥1 transliteration-marker hanzi (尔/克/斯/亚/利/拉/罗/兰/纳/塔/玛/莎/丽/卡/特/奇/普/蒙/弗/赫/夫/维/姆/里/达/巴/乔/詹/约/汤/汉).
  H4. Either absent from LCCC top-100,000 OR LCCC rank > 50,000.
  H5. jieba flags it as 'nr' (PER) or 'ns' (LOC).

Output:
  output/foreign_names_candidates_s.tsv
    rank, word, opus_freq, lccc_rank, hsk_level, length, jieba_pos,
    has_translit_marker, score, decision
"""
import os, csv, re

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
WMAP = os.path.join(ROOT, "output", "hsk_word_map_s.tsv")
LCCC = os.path.join(ROOT, "output", "lccc_freq_1000000.tsv")
OUT  = os.path.join(ROOT, "output", "foreign_names_candidates_s.tsv")

import jieba.posseg as pseg
import jieba
jieba.initialize()

TRANSLIT = set("尔克斯亚利拉罗兰纳塔玛莎丽卡特奇普蒙弗赫夫维姆里达巴乔詹约汤汉伊艾安纳娜杰戴莱凯雷茜珊辛悉布卢卢芙菲妮诺娅琳柏夏尼欧洛威迪尤")

# 1) load LCCC ranks
lccc_rank = {}
with open(LCCC, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        lccc_rank[row["word"]] = int(row["rank"])
print(f"[load] lccc vocab={len(lccc_rank):,}")

# 2) iterate opus top 5000
candidates = []
with open(WMAP, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        rank = int(row["rank"])
        if rank > 5000: break
        word = row["word"]
        freq = int(row["freq"])
        hsk = row.get("hsk_level", "")

        # H1
        h1 = (hsk == "" or hsk == "none")
        # H2
        if not (2 <= len(word) <= 4):
            continue
        if not re.fullmatch(r"[一-鿿]+", word):
            continue
        # H3
        h3 = any(c in TRANSLIT for c in word)
        # H4
        rL = lccc_rank.get(word, 10**9)
        h4 = (rL > 50000)
        # H5
        pos_list = [p.flag for p in pseg.cut(word)]
        h5 = any(p.startswith("nr") or p.startswith("ns") for p in pos_list)
        score = sum([h1, h3, h4, h5])
        decision = "FOREIGN_NAME" if score >= 3 else "uncertain"
        if score >= 2:
            candidates.append({
                "rank": rank, "word": word, "opus_freq": freq,
                "lccc_rank": rL if rL < 10**9 else "—",
                "hsk_level": hsk,
                "length": len(word),
                "jieba_pos": "/".join(pos_list),
                "has_translit_marker": int(h3),
                "score": score,
                "decision": decision,
            })

with open(OUT, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["rank","word","opus_freq","lccc_rank","hsk_level",
                                      "length","jieba_pos","has_translit_marker","score","decision"],
                       delimiter="\t", lineterminator="\n")
    w.writeheader()
    for c in candidates:
        w.writerow(c)

n_total = len(candidates)
n_decided = sum(1 for c in candidates if c["decision"] == "FOREIGN_NAME")
print(f"[done] candidates={n_total} (score≥2)  decided FOREIGN={n_decided}  → {OUT}")

# Print examples per score
from collections import defaultdict
buckets = defaultdict(list)
for c in candidates:
    buckets[c["score"]].append(f'{c["word"]}(r{c["rank"]})')
for s in sorted(buckets.keys(), reverse=True):
    ex = " ".join(buckets[s][:20])
    print(f"  score={s} ({len(buckets[s])}건): {ex}")
