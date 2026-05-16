"""
Build the FINAL conversation-learning wordset.

Inputs (from the _final cleaned dataset):
  output/word_freq_cd_s_nohk.tsv      (CD + OpenCC + no-HK FINAL dataset)
  output/hsk_word_map_final.tsv       (final word→HSK mapping)
  wordlists/HSK_zispace_2021.txt      (POS metadata)
  output/foreign_names_candidates_s.tsv  (foreign names to soft-flag)
  output/lccc_freq_1000000.tsv        (LCCC reference)

Logic:
  Take the union of:
    A) opus rank 1 ~ 3000 (CD-weighted, post-HK-removal, post-OpenCC)
    B) HSK 1-4 cumulative (3236 words) - even if rank > 3000

  For each word produce:
    word, opus_rank, hsk_level, pos, lccc_rank,
    is_foreign_name, tier, dialog_priority

  Tier definition (for app/curriculum design):
    Tier A (필수, 다이얼로그 1-3회차)
      = opus rank ≤ 500 AND HSK level ≤ HSK4 (or in HSK at all)
      OR ∈ "HSK3/4 + opus≤500" 다이얼로그 우선 99개
    Tier B (핵심, 다이얼로그 4-15회차)
      = opus rank 501-1500 AND HSK level ≤ HSK4
    Tier C (확장, 다이얼로그 16+회차)
      = opus rank 1501-3000 AND HSK level ≤ HSK4
    Tier D (HSK 시험 보충 — opus 빈도 낮지만 시험에 필요)
      = HSK 1-4 누적 BUT opus rank > 3000 (회화 빈도 낮음)
    Tier X (제외 후보)
      = is_foreign_name OR opus rank > 3000 AND not HSK 1-4

  dialog_priority = opus rank-based bucket (1: rank≤100, 2: 101-300, ...)
"""
import os, csv, sys

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
WMAP   = os.path.join(ROOT, "output", "hsk_word_map_final.tsv")
HSK    = os.path.join(ROOT, "wordlists", "HSK_zispace_2021.txt")
LCCC   = os.path.join(ROOT, "output", "lccc_freq_1000000.tsv")
FNAMES = os.path.join(ROOT, "output", "foreign_names_candidates_s.tsv")
OUT    = os.path.join(ROOT, "output", "FINAL_wordset_for_conversation_app.tsv")
OUT_SUM= os.path.join(ROOT, "output", "FINAL_wordset.summary.txt")

# Load HSK pos
LVL = {"一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4","五级":"HSK5","六级":"HSK6","高等":"HSK7-9"}
hsk_pos = {}
hsk_lvl = {}
with open(HSK, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"): continue
        parts = line.split("\t")
        if len(parts) < 5: continue
        wf, pos, _, _, level = parts[:5]
        for w in wf.split("∣"):
            w = w.strip()
            if w:
                hsk_pos[w] = pos
                hsk_lvl[w] = LVL.get(level, level)

# Load opus rank (final)
opus_rank = {}
with open(WMAP, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        opus_rank[row["word"]] = int(row["rank"])
print(f"[opus] vocab={len(opus_rank):,}")

# Load LCCC rank
lccc_rank = {}
with open(LCCC, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        lccc_rank[row["word"]] = int(row["rank"])

# Load foreign names (decision == FOREIGN_NAME only — score≥3 conservatively means
# we exclude names but keep place names like 美国/中国 which got score=3)
# Actually we need to check: per user note, 4점만 자동 제거, 3점은 수동.
foreign_names = set()
foreign_names_score3 = set()
with open(FNAMES, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        if int(row["score"]) >= 4:
            foreign_names.add(row["word"])
        elif int(row["score"]) == 3:
            foreign_names_score3.add(row["word"])

# Build set: opus 1-3000 ∪ HSK1-4 누적
hsk14 = {w for w,(l,_) in zip(hsk_lvl.keys(), [(hsk_lvl[w], hsk_pos.get(w,"")) for w in hsk_lvl])
          if l in ("HSK1","HSK2","HSK3","HSK4")}

candidates = set()
for w, r in opus_rank.items():
    if r <= 3000:
        candidates.add(w)
candidates |= hsk14

# Tier assignment
records = []
for w in sorted(candidates, key=lambda x: opus_rank.get(x, 99999)):
    rank = opus_rank.get(w)
    lvl  = hsk_lvl.get(w, "")
    pos  = hsk_pos.get(w, "")
    rL   = lccc_rank.get(w, "")
    is_fn  = w in foreign_names
    is_fn3 = w in foreign_names_score3

    # Tier
    if is_fn:
        tier = "X_excluded_foreign"
    elif rank is None:
        # HSK 1-4 word that's not even in opus
        tier = "D_hsk_only"
    elif rank <= 500 and lvl in ("HSK1","HSK2","HSK3","HSK4"):
        tier = "A_essential"
    elif rank <= 500:
        tier = "A_essential_extra_HSK"   # HSK 외 회화 핵심 (앱 정책으로 추가/제외)
    elif rank <= 1500 and lvl in ("HSK1","HSK2","HSK3","HSK4"):
        tier = "B_core"
    elif rank <= 1500:
        tier = "B_core_extra_HSK"
    elif rank <= 3000 and lvl in ("HSK1","HSK2","HSK3","HSK4"):
        tier = "C_expansion"
    elif rank <= 3000:
        tier = "C_expansion_extra_HSK"
    else:
        # HSK 1-4 with rank > 3000
        tier = "D_hsk_only"

    # dialog priority bucket (1=earliest exposure, 5=latest)
    if rank is None:
        dp = 5
    elif rank <= 100: dp = 1
    elif rank <= 300: dp = 2
    elif rank <= 700: dp = 3
    elif rank <= 1500: dp = 4
    else: dp = 5

    records.append({
        "word": w,
        "opus_rank": rank if rank else "",
        "hsk_level": lvl,
        "pos": pos,
        "lccc_rank": rL,
        "is_foreign_name": int(is_fn),
        "is_foreign_score3": int(is_fn3),
        "tier": tier,
        "dialog_priority": dp,
    })

# Write final
with open(OUT, "w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["word","opus_rank","hsk_level","pos","lccc_rank",
                                      "is_foreign_name","is_foreign_score3","tier","dialog_priority"],
                       delimiter="\t", lineterminator="\n")
    w.writeheader()
    for r in records:
        w.writerow(r)

# Summary
from collections import Counter
tier_counts = Counter(r["tier"] for r in records)
hsk_counts  = Counter(r["hsk_level"] or "none" for r in records)
dp_counts   = Counter(r["dialog_priority"] for r in records)

lines = []
lines.append(f"=== FINAL conversation wordset summary ===")
lines.append(f"Total words: {len(records):,}")
lines.append("")
lines.append("Tier 분포:")
for t in ["A_essential","A_essential_extra_HSK","B_core","B_core_extra_HSK",
          "C_expansion","C_expansion_extra_HSK","D_hsk_only","X_excluded_foreign"]:
    n = tier_counts.get(t, 0)
    lines.append(f"  {t:<25} {n:>5d}")
lines.append("")
lines.append("HSK 등급 분포:")
for l in ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6","HSK7-9","none"]:
    lines.append(f"  {l:<10} {hsk_counts.get(l,0):>5d}")
lines.append("")
lines.append("dialog_priority 분포 (1=가장 먼저 노출):")
for dp in [1,2,3,4,5]:
    lines.append(f"  priority={dp}: {dp_counts.get(dp,0):>5d}")

print("\n".join(lines))
with open(OUT_SUM, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print()
print(f"[done] {OUT}")
print(f"[done] {OUT_SUM}")
