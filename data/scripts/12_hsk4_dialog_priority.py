"""
Targeted analysis for the user's actual product question:

Target = HSK4 cumulative (1~4급, 3,236 단어) as the conversation-learning ceiling.
HSK5+ is out of scope (specialty learning later).

Questions:
  Q1. Where is the cliff inside opus rank 1,000~3,000 ?
  Q2. Of HSK4-cumulative (3,236) words, what % live in
        opus[1..1000] / opus[1001..3000] / opus[3001..] ?
  Q3. Of HSK5-cumulative (4,304) words, the same breakdown.
  Q4. KEY INSIGHT FOR DIALOG DESIGN:
        Which HSK3 / HSK4 words sit very high in opus rank
        (i.e. HSK puts them late but conversation puts them early)?
        These are the words that MUST appear in early dialogues.
  Q5. Of HSK5 words NOT covered by opus[1..3000], what semantic themes
      dominate? (uses POS + manual seed-list categorization)
"""
import os, csv, re, math
from collections import Counter, defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
WMAP   = os.path.join(ROOT, "output", "hsk_word_map_cd.tsv")
HSK    = os.path.join(ROOT, "wordlists", "HSK_zispace_2021.txt")
CLIFF  = os.path.join(ROOT, "output", "cliff_slope_cd.tsv")
OUT_SUM= os.path.join(ROOT, "output", "hsk4_dialog_priority.summary.txt")
OUT_EARLY = os.path.join(ROOT, "output", "hsk_late_but_conversation_early.tsv")
OUT_LATE  = os.path.join(ROOT, "output", "hsk5_uncovered.tsv")

# Load HSK metadata: word -> (level, pos)
LVL = {"一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4","五级":"HSK5","六级":"HSK6","高等":"HSK7-9"}
hsk = {}
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
            hsk[w] = (LVL.get(level, level), pos)

# Load opus rank for HSK words
opus_rank = {}     # word -> opus rank (or None if not in opus)
with open(WMAP, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        opus_rank[row["word"]] = int(row["rank"])

# ----- Q1 cliff inside 1000-3000 -----
slopes = []  # (rank, slope)
with open(CLIFF, "r", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        try:
            rank = int(row["rank"])
            sl = float(row["d_logf_d_logr"]) if row["d_logf_d_logr"] else None
        except (ValueError, KeyError):
            continue
        if sl is None: continue
        slopes.append((rank, sl))

# Find local minima of slope inside [800, 4000] (broader window)
in_window = [(r,s) for (r,s) in slopes if 800 <= r <= 4000]
in_window.sort()
# Group by 0.1 decade buckets, take steepest
buckets = defaultdict(list)
for r, s in in_window:
    b = int(math.log10(r) * 10)
    buckets[b].append((r, s))
cliff_pts = []
for b, items in sorted(buckets.items()):
    items.sort(key=lambda x: x[1])  # most negative first
    cliff_pts.append(items[0])
cliff_pts.sort(key=lambda x: x[0])

# ----- Q2/Q3 HSK level coverage by opus rank bucket -----
def in_bucket(rank, lo, hi):
    return rank is not None and lo <= rank <= hi

LVL_GROUPS = {
    "HSK1": ["HSK1"],
    "HSK2": ["HSK2"],
    "HSK3": ["HSK3"],
    "HSK4": ["HSK4"],
    "HSK5": ["HSK5"],
    "HSK4_cumul (1~4)": ["HSK1","HSK2","HSK3","HSK4"],
    "HSK5_cumul (1~5)": ["HSK1","HSK2","HSK3","HSK4","HSK5"],
}
BUCKETS = [
    ("opus 1-100",    1, 100),
    ("opus 101-500",  101, 500),
    ("opus 501-1000", 501, 1000),
    ("opus 1-1000 ⓢ", 1, 1000),
    ("opus 1001-3000",1001, 3000),
    ("opus 1-3000 ⓢ", 1, 3000),
    ("opus 3001+ ⓢ",  3001, 10**9),
    ("opus 미등장",    None, None),
]

table = {}  # (group, bucket_label) -> count
group_total = {}
for gname, lvls in LVL_GROUPS.items():
    words = [w for w,(l,_) in hsk.items() if l in lvls]
    group_total[gname] = len(words)
    for label, lo, hi in BUCKETS:
        if lo is None:
            n = sum(1 for w in words if w not in opus_rank)
        else:
            n = sum(1 for w in words if in_bucket(opus_rank.get(w), lo, hi))
        table[(gname, label)] = n

# ----- Q4: HSK3/4 words ranked unexpectedly EARLY in opus -----
# "Early" = opus rank within top 500 → these words MUST be in early dialogs.
early_hsk34 = []
for w, (lvl, pos) in hsk.items():
    if lvl not in ("HSK3","HSK4"): continue
    r = opus_rank.get(w)
    if r is None: continue
    if r <= 500:
        early_hsk34.append((r, w, lvl, pos))
early_hsk34.sort()

with open(OUT_EARLY, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["opus_rank","word","hsk_level","pos"])
    for r, wd, lvl, pos in early_hsk34:
        w.writerow([r, wd, lvl, pos])

# Categorize the early HSK3/4 by POS
pos_counter = Counter()
pos_examples = defaultdict(list)
for r, wd, lvl, pos in early_hsk34:
    pos_counter[pos] += 1
    if len(pos_examples[pos]) < 15:
        pos_examples[pos].append(f"{wd}(r{r},{lvl})")

# ----- Q5: HSK5 words NOT covered by opus 1-3000 -----
hsk5_uncov = []
for w, (lvl, pos) in hsk.items():
    if lvl != "HSK5": continue
    r = opus_rank.get(w)
    if r is None or r > 3000:
        hsk5_uncov.append((r if r else 999999, w, pos))
hsk5_uncov.sort()

with open(OUT_LATE, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter="\t", lineterminator="\n")
    w.writerow(["opus_rank","word","pos"])
    for r, wd, pos in hsk5_uncov:
        w.writerow([r if r != 999999 else "—", wd, pos])

# Theme classification for HSK5 uncovered (manual seeds)
THEMES = [
    ("학술/논리",     {"理论","结论","观点","角度","方面","因素","原因","本质","现象","方式","形式","内容","范围","结构","特征","系统","方法","原则","程度","水平","作用","影响","意义","效果","效率","质量","价值","成果","结果","过程","目标","目的","状态","条件","环境","趋势","规律","关系","逻辑","实质"}),
    ("경제/금융",     {"经济","金融","投资","股票","贷款","利息","利润","成本","收入","支出","预算","税","债务","资产","资金","市场","商业","贸易","交易","销售","消费","生产","产业","企业","公司","工厂","品牌","产品","服务"}),
    ("정치/사회",     {"政治","政府","政策","制度","法律","法规","选举","议会","民主","权力","权利","义务","公民","社会","组织","机构","团体","协会","委员会","部门","群众","公共","媒体"}),
    ("학교/교육",     {"教育","学习","课程","专业","学校","大学","学院","学历","学位","研究","学术","知识","技术","能力","训练","培训","技能","学者","教授","学生","教师"}),
    ("의료/건강",     {"医疗","医院","医生","护士","患者","病人","疾病","症状","治疗","手术","药品","药物","健康","身体","心脏","血液","细胞","器官","营养","锻炼"}),
    ("자연/환경",     {"自然","环境","森林","海洋","河流","山","植物","动物","气候","天气","温度","空气","污染","保护","资源","能源","生态"}),
    ("문화/예술",     {"文化","艺术","音乐","美术","文学","历史","传统","节日","仪式","风俗","习俗","建筑","作品","表演","舞台","剧场"}),
    ("기술/과학",     {"科学","技术","工程","机器","设备","工具","电子","电脑","软件","硬件","网络","系统","数据","信息","实验","发明","创新"}),
    ("심리/감정",     {"心理","情感","情绪","压力","紧张","焦虑","担心","恐惧","勇气","信心","希望","想象","记忆","思考","判断","决定","怀疑","信任"}),
    ("형용사/평가",   set()),  # filled by POS
    ("동사/행위",     set()),  # filled by POS
    ("부사/접속어",   set()),  # filled by POS
]

theme_counter = Counter()
theme_examples = defaultdict(list)
for r, wd, pos in hsk5_uncov:
    matched = False
    for tname, seeds in THEMES:
        if seeds and wd in seeds:
            theme_counter[tname] += 1
            if len(theme_examples[tname]) < 12:
                theme_examples[tname].append(wd)
            matched = True
            break
    if matched: continue
    # POS-based bucket
    if "形" in pos:
        theme_counter["형용사/평가"] += 1
        if len(theme_examples["형용사/평가"]) < 12:
            theme_examples["형용사/평가"].append(f"{wd}({pos})")
    elif "副" in pos or "连" in pos:
        theme_counter["부사/접속어"] += 1
        if len(theme_examples["부사/접속어"]) < 12:
            theme_examples["부사/접속어"].append(f"{wd}({pos})")
    elif "动" in pos:
        theme_counter["동사/행위"] += 1
        if len(theme_examples["동사/행위"]) < 12:
            theme_examples["동사/행위"].append(f"{wd}({pos})")
    else:
        theme_counter["기타"] += 1
        if len(theme_examples["기타"]) < 12:
            theme_examples["기타"].append(f"{wd}({pos})")

# ============ Output report ============
lines = []
lines.append("=== Q1) opus 800-4000 구간의 절벽(steepest log-slope) 지점들 ===")
lines.append(f"  {'rank':>6} {'slope':>8}")
for r, s in cliff_pts:
    lines.append(f"  {r:>6d} {s:>8.3f}")

lines.append("")
lines.append("=== Q2/Q3) HSK 등급별 — opus rank bucket 분포 ===")
hdr = ["group(total)"] + [b[0] for b in BUCKETS]
lines.append("  " + "  ".join(f"{h:>16}" for h in hdr))
for gname in LVL_GROUPS:
    tot = group_total[gname]
    row = [f"{gname}({tot})"]
    for label, _, _ in BUCKETS:
        n = table[(gname, label)]
        pct = n / tot * 100 if tot else 0
        row.append(f"{n:>5d}({pct:>4.1f}%)")
    lines.append("  " + "  ".join(f"{x:>16}" for x in row))

lines.append("")
lines.append("=== Q4) HSK3/4 단어인데 opus rank ≤500 ===")
lines.append(f"=== 이 단어들이 \"HSK는 후반에, 회화는 전반에\" — 다이얼로그 앞쪽으로 배치할 후보 ===")
lines.append(f"총 {len(early_hsk34)}개 단어")
lines.append("")
lines.append("POS별 분포:")
for pos, n in pos_counter.most_common():
    ex = "  ".join(pos_examples[pos][:10])
    lines.append(f"  {pos:<14} {n:>3d}건  {ex}")

lines.append("")
lines.append("=== Q5) HSK5 단어 중 opus 1-3000 미수록 ===")
total5 = len([w for w,(l,_) in hsk.items() if l == "HSK5"])
covered5 = total5 - len(hsk5_uncov)
lines.append(f"전체 HSK5: {total5}, opus 1-3000 안: {covered5} ({covered5/total5*100:.1f}%), 미수록: {len(hsk5_uncov)} ({len(hsk5_uncov)/total5*100:.1f}%)")
lines.append("")
lines.append("미수록 HSK5 단어의 테마 분포:")
for theme, n in theme_counter.most_common():
    ex = " ".join(theme_examples[theme][:10])
    lines.append(f"  {theme:<14} {n:>3d}건  {ex}")

with open(OUT_SUM, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("\n".join(lines))
print()
print(f"[done] {OUT_SUM}")
print(f"[done] {OUT_EARLY}")
print(f"[done] {OUT_LATE}")
