"""
For each HSK3 hanzi (300 chars), compute:
- frequency in modern_drama corpus
- frequency in romance corpus
- frequency in baseline movie corpus (hanzi_score_s.tsv exists?)
- romance_overrep = (rank in romance) better than (rank in drama) by N
- classify into "romance domain" vs "general domain"

Also handle HSK1 (300) and HSK2 (300) — total HSK1+2+3 = 900 simplified hanzi.

Outputs (output/_drama/):
- hsk3_domain_split.tsv  (per HSK3 hanzi: counts, ranks, classification)
- hsk3_romance_domain.txt  (one hanzi per line)
- hsk3_general_domain.txt
- hsk1_2_3_summary.tsv     (per HSK level: total chars, covered, missing)
"""
import os, csv
from collections import Counter

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
WORDLISTS = os.path.join(ROOT, "wordlists")
OUT_DIR = os.path.join(ROOT, "output", "_drama")

HANZI_DRAMA = os.path.join(OUT_DIR, "hanzi_freq_drama.tsv")
HANZI_ROMANCE = os.path.join(OUT_DIR, "hanzi_freq_romance.tsv")
HANZI_MOVIE_BASE = os.path.join(ROOT, "output", "hanzi_score_s.tsv")  # may exist


def load_hsk_set(path):
    s = set()
    if not os.path.exists(path):
        return s
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            ch = line.strip()
            if ch:
                s.add(ch)
    return s


def load_hanzi_freq(path):
    c = Counter()
    doc = {}
    if not os.path.exists(path):
        return c, doc
    with open(path, "r", encoding="utf-8", newline="") as f:
        r = csv.DictReader(f, delimiter="\t")
        for row in r:
            ch = row["hanzi"]
            c[ch] = int(row["count"])
            if "doc_count" in row:
                try:
                    doc[ch] = int(row["doc_count"])
                except (TypeError, ValueError):
                    doc[ch] = 0
    return c, doc


hsk1 = load_hsk_set(os.path.join(WORDLISTS, "HSK_hanzi_1.txt"))
hsk2 = load_hsk_set(os.path.join(WORDLISTS, "HSK_hanzi_2.txt"))
hsk3 = load_hsk_set(os.path.join(WORDLISTS, "HSK_hanzi_3.txt"))
print(f"[hsk] HSK1={len(hsk1)} HSK2={len(hsk2)} HSK3={len(hsk3)}", flush=True)

drama_freq, drama_doc = load_hanzi_freq(HANZI_DRAMA)
rom_freq, rom_doc = load_hanzi_freq(HANZI_ROMANCE)
print(f"[load] drama hanzi={len(drama_freq)} romance hanzi={len(rom_freq)}", flush=True)

# Compute romance over-representation: ratio of (per-million in romance)/(per-million in drama)
drama_total = sum(drama_freq.values())
rom_total = sum(rom_freq.values())
print(f"[total] drama={drama_total:,} romance={rom_total:,}")


def per_mil(c, total):
    if total <= 0:
        return 0.0
    return c * 1_000_000 / total


# Rank within drama and romance
drama_rank = {ch: i + 1 for i, (ch, _) in enumerate(drama_freq.most_common())}
rom_rank = {ch: i + 1 for i, (ch, _) in enumerate(rom_freq.most_common())}

# Score each HSK3 hanzi
out_path = os.path.join(OUT_DIR, "hsk3_domain_split.tsv")
rows = []
for ch in sorted(hsk3):
    df = drama_freq.get(ch, 0)
    rf = rom_freq.get(ch, 0)
    dpm = per_mil(df, drama_total)
    rpm = per_mil(rf, rom_total)
    overrep = (rpm / dpm) if dpm > 0 else 0.0
    drank = drama_rank.get(ch, 999999)
    rrank = rom_rank.get(ch, 999999)
    rows.append({
        "hanzi": ch,
        "drama_count": df,
        "romance_count": rf,
        "drama_per_mil": round(dpm, 2),
        "romance_per_mil": round(rpm, 2),
        "drama_rank": drank,
        "romance_rank": rrank,
        "romance_overrep": round(overrep, 3),
        "drama_doc": drama_doc.get(ch, 0),
        "romance_doc": rom_doc.get(ch, 0),
    })

with open(out_path, "w", encoding="utf-8", newline="") as f:
    fields = list(rows[0].keys())
    w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
    w.writeheader()
    w.writerows(rows)
print(f"[write] {out_path}")

# Domain classification heuristic:
# - "romance domain" = romance_overrep >= 1.30 AND romance_count >= 50
#   OR rare in drama (drama_rank > 800) but present in romance with rank <= 1500
# - "general domain" = otherwise (including very common like 是/有)
# - "absent / weak" = romance_count < 5

ROMANCE = []
GENERAL = []
WEAK = []
for r in rows:
    ch = r["hanzi"]
    rc = r["romance_count"]
    overrep = r["romance_overrep"]
    drank = r["drama_rank"]
    rrank = r["romance_rank"]
    if rc < 5:
        WEAK.append(ch)
        continue
    if (overrep >= 1.30 and rc >= 50):
        ROMANCE.append(ch)
    elif (drank > 800 and rrank <= 1500 and rc >= 30):
        ROMANCE.append(ch)
    else:
        GENERAL.append(ch)

print(f"\n[classify] HSK3 ({len(rows)}):")
print(f"  romance domain : {len(ROMANCE)}")
print(f"  general domain : {len(GENERAL)}")
print(f"  weak / absent  : {len(WEAK)}")

with open(os.path.join(OUT_DIR, "hsk3_romance_domain.txt"), "w", encoding="utf-8") as f:
    for ch in ROMANCE:
        f.write(ch + "\n")
with open(os.path.join(OUT_DIR, "hsk3_general_domain.txt"), "w", encoding="utf-8") as f:
    for ch in GENERAL:
        f.write(ch + "\n")
with open(os.path.join(OUT_DIR, "hsk3_weak_domain.txt"), "w", encoding="utf-8") as f:
    for ch in WEAK:
        f.write(ch + "\n")

# HSK1+2+3 summary table
def cov(hsk, freq):
    covered = sum(1 for c in hsk if freq.get(c, 0) > 0)
    return covered, len(hsk) - covered

c1d, m1d = cov(hsk1, drama_freq)
c2d, m2d = cov(hsk2, drama_freq)
c3d, m3d = cov(hsk3, drama_freq)
c1r, m1r = cov(hsk1, rom_freq)
c2r, m2r = cov(hsk2, rom_freq)
c3r, m3r = cov(hsk3, rom_freq)
summary = [
    ["level", "total", "drama_covered", "drama_missing", "romance_covered", "romance_missing"],
    ["HSK1", len(hsk1), c1d, m1d, c1r, m1r],
    ["HSK2", len(hsk2), c2d, m2d, c2r, m2r],
    ["HSK3", len(hsk3), c3d, m3d, c3r, m3r],
]
with open(os.path.join(OUT_DIR, "hsk1_2_3_summary.tsv"), "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerows(summary)
print(f"\n[hsk coverage]")
for row in summary:
    print(" ".join(str(x) for x in row))
