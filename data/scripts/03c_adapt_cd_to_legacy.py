"""
Adapt word_freq_cd.tsv (CD-based, TFIDF-ranked) into a legacy-compatible
word_freq table that the existing 04/05/06/08 scripts can consume without code
changes. The "freq" column is filled with the integer TFIDF score so all
downstream cumulative / coverage / segment math stays valid.

Output: output/word_freq_cd_legacy.tsv
        rank, word, freq, cum_freq, cum_pct
"""
import os, csv

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
SRC = os.path.join(ROOT, "output", "word_freq_cd.tsv")
DST = os.path.join(ROOT, "output", "word_freq_cd_legacy.tsv")

rows = []
N_CD = None
with open(SRC, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        tf = int(row["total_freq"])
        df = int(row["df"])
        df_pct = float(row["df_pct"]) / 100.0   # already pct in source
        # TRUE learning-priority score: how often you encounter the word AND how
        # universal it is across CDs. A name appearing 1000× in 1 movie:
        #   tf=1000, df_pct=0.0001, score=0.1 → ranked very low.
        # 我 appearing in every movie:
        #   tf=huge, df_pct=1.0, score=tf → unchanged top rank.
        score = tf * df_pct
        rows.append((row["word"], score))

# rows already sorted by tfidf desc in source, but re-sort defensively
rows.sort(key=lambda x: -x[1])
total = sum(s for _, s in rows)

with open(DST, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","freq","cum_freq","cum_pct"])
    cum = 0
    for i, (word, score) in enumerate(rows, 1):
        # round score to int for integer-style freq column
        s_int = int(round(score))
        cum += s_int
        w.writerow([i, word, s_int, cum, f"{cum/(total or 1)*100:.4f}"])

print(f"[done] vocab={len(rows):,}  total_tfidf={total:,.0f}")
print(f"[done] {DST}")
