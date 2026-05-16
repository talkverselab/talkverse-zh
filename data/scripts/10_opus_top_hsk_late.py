"""
Identify words that are HIGH in opus rank but LOW (or absent) in HSK.
Categorize them by:
  - HSK level (none / HSK5 / HSK6 / HSK7-9)
  - Part of speech (from zispace HSK metadata, when available)
  - Manual category buckets via simple substring/seed matching:
      pronoun_combo, adverb, modal, exclamation, address, vulgar,
      negation_combo, name_foreign, traditional_variant, other
"""
import os, csv, re
from collections import Counter, defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
WMAP   = os.path.join(ROOT, "output", "hsk_word_map_cd.tsv")
HSK    = os.path.join(ROOT, "wordlists", "HSK_zispace_2021.txt")
OUT    = os.path.join(ROOT, "output", "opus_top_hsk_late.tsv")
OUT_SUM= os.path.join(ROOT, "output", "opus_top_hsk_late.summary.txt")

# Build word -> (level, pos)
LEVEL_LABEL = {"一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4",
               "五级":"HSK5","六级":"HSK6","高等":"HSK7-9"}
hsk_pos = {}   # word -> "动" / "名" / etc.
hsk_lvl = {}
with open(HSK, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")
        if not line or line.startswith("#"): continue
        parts = line.split("\t")
        if len(parts) < 5: continue
        word_field, pos, _, _, level = parts[:5]
        for w in word_field.split("∣"):
            w = w.strip()
            if not w: continue
            hsk_pos[w] = pos
            hsk_lvl[w] = LEVEL_LABEL.get(level, level)

# Manual category seeds — used when HSK pos is unknown (i.e. word missing from HSK)
CATS = [
    ("traditional", set("們嗎說來對沒為會讓這個樣著裏麽從謝後話現麼還聽請對")),  # 번체 잔존
    ("vulgar",      {"该死","混蛋","他妈的","靠","逼","笨蛋","白痴","畜生","王八蛋"}),
    ("address",     {"爸爸","妈","小姐","母亲","长官","先生","太太","老板","老师","哥","姐","弟","妹","爹","娘","老公","老婆"}),
    ("name_foreign",{"约翰","杰克","汤姆","路易斯","彼得","查理","迈克","大卫","保罗","乔治","詹姆斯","威廉","哈利","史密斯","琼斯","布朗","威尔逊","泰勒","安德森","托马斯","马丁","杰森","克里斯","莱恩","凯文","布鲁斯","本","萨姆","尼克","史蒂夫","卡尔","玛丽","莎拉","凯特","艾米","安娜","莉莉","爱","苏菲"}),
    ("pronoun_combo", {"一个","这个","那个","我们","你们","他们","这是","那是","这种","那种","哪个","哪种","一些","这些","那些"}),
    ("negation_combo",{"不是","不会","不能","不要","不用","不行","不知道","没有","没事","没什么","不想","不对","不好"}),
    ("filler_modal",  {"嗯","哦","啊","呀","哎","哎呀","哇","噢","嘿","唉","哼","欸","咦","呃","哈"}),
    ("question",      {"什么","怎么","怎样","怎么办","怎么样","为什么","哪里","哪儿","几","多少"}),
    ("temporal_adv",  {"现在","刚才","刚刚","马上","立刻","总是","已经","正在","曾经","从来","再","又","还","就","才","快","慢","早","晚","先","然后","最近","以后","以前","当时"}),
    ("intensifier",   {"非常","真","特别","太","好","挺","蛮","相当","完全","绝对","简直","实在","确实","真的","真是"}),
    ("modal_aux",     {"应该","可以","可能","必须","得","要","想","愿意","敢","会","能"}),
    ("connective",    {"因为","所以","但是","不过","然后","如果","虽然","或者","并且","而且","否则","不然"}),
    ("greeting",      {"你好","再见","谢谢","对不起","抱歉","拜拜","早","晚安"}),
    ("violence",      {"死","杀","死亡","杀死","杀人","尸体","监狱","枪","血","刀"}),
]

def classify(word, hsk_level):
    if hsk_level not in ("", None, "none"):
        return "in_HSK_" + hsk_level
    # categorize by manual seeds
    if any(c in word for c in CATS[0][1]):
        # has at least one traditional-only character
        return "traditional"
    for name, seeds in CATS[1:]:
        if word in seeds:
            return name
    # fallback: short heuristics
    if re.fullmatch(r"[一二三四五六七八九十百千万亿]+", word):
        return "number"
    if re.fullmatch(r"[一-鿿]{1}", word):
        return "single_char_unknown"
    return "other"

# Load opus word map (limited to top 3000)
rows = []
with open(WMAP, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        rank = int(row["rank"])
        if rank > 3000: continue
        rows.append((rank, row["word"], int(row["freq"]), row.get("hsk_level","")))

# For words IN HSK, get pos from metadata
records = []
for rank, word, freq, lvl in rows:
    pos = hsk_pos.get(word, "")
    cat = classify(word, lvl)
    records.append((rank, word, freq, lvl, pos, cat))

with open(OUT, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["rank","word","freq","hsk_level","hsk_pos","category"])
    for r in records:
        w.writerow(r)

# Summary: cross-tab of category × hsk_level for top 3000
cat_count = Counter()
cat_examples = defaultdict(list)
for rank, word, freq, lvl, pos, cat in records:
    cat_count[cat] += 1
    if len(cat_examples[cat]) < 12:
        cat_examples[cat].append(f"{word}(r{rank})")

# What pos are HSK words in opus top 3000?
pos_count_for_hsk5 = Counter()  # only count HSK5+ words
pos_examples_late  = defaultdict(list)
for rank, word, freq, lvl, pos, cat in records:
    if lvl in ("HSK5","HSK6","HSK7-9"):
        pos_count_for_hsk5[pos] += 1
        if len(pos_examples_late[pos]) < 12:
            pos_examples_late[pos].append(f"{word}(r{rank},{lvl})")

# What pos are HSK words in opus 1-500 vs 501-3000?
pos_in_top500 = Counter()
pos_in_500_3000 = Counter()
for rank, word, freq, lvl, pos, cat in records:
    if not pos: continue
    if rank <= 500: pos_in_top500[pos] += 1
    else:           pos_in_500_3000[pos] += 1

lines = []
lines.append("=== Category breakdown of opus top 3000 ===")
lines.append(f"{'category':<22} {'count':>6}  examples")
for cat, n in cat_count.most_common():
    ex = " ".join(cat_examples[cat][:8])
    lines.append(f"{cat:<22} {n:>6d}  {ex}")

lines.append("")
lines.append("=== HSK words in opus top 500 — POS distribution ===")
for pos, n in pos_in_top500.most_common(20):
    lines.append(f"  {pos:<12} {n:>4d}")
lines.append("")
lines.append("=== HSK words in opus 501-3000 — POS distribution ===")
for pos, n in pos_in_500_3000.most_common(20):
    lines.append(f"  {pos:<12} {n:>4d}")

lines.append("")
lines.append("=== \"opus 상위 + HSK 후순위 (HSK5/6/7-9)\" 단어 — POS 분포 ===")
for pos, n in pos_count_for_hsk5.most_common():
    ex = " ".join(pos_examples_late[pos][:8])
    lines.append(f"  {pos:<12} {n:>4d}  {ex}")

with open(OUT_SUM, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("\n".join(lines))
print()
print(f"[done] {OUT}")
print(f"[done] {OUT_SUM}")
