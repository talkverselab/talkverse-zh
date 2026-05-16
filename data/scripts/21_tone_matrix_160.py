"""
Build 4×4 tone matrix with 10 words per cell = 160 words.
Use only 209 hanzi. Prioritize ep1-5 dialogue words + opus rank top.

Output: D:/OneDrive/PROJECT/talkverse-learning/CH/Word/tone_matrix_160.json
"""
import csv, json, os, re
from datetime import date
from collections import defaultdict

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
OUT  = r"D:/OneDrive/PROJECT/talkverse-learning/ZH/Word/tone_matrix_160.json"

# === Blacklist: 부적합 단어 (학습 콘텐츠 부적합) ===
BLACKLIST_WORDS = {
    "杀人", "杀死", "该死", "小子", "女人",  # 폭력·비하 톤
}
# === Bad meanings: CEDICT 의미가 학습 부적합한 경우 → 의미 override ===
MEANING_OVERRIDE = {
    "东西": "물건",
    "告诉": "알려주다",
    "不是": "~이/가 아니다",
    "怎么": "어떻게",
    "这么": "이렇게",
    "那么": "그렇게",
    "哪里": "어디",
    "这里": "여기",
    "当时": "그때",
    "什么": "무엇",
    "时候": "때",
    "为什么": "왜",
}

# 1) 209 hanzi set
hanzi_data = []
with open(f"{ROOT}/output/hanzi_score_final.tsv", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        hanzi_data.append(row)
set209 = set(h["char"] for h in hanzi_data[:207]) | {"嗯", "嘛"}

# 2) Load all 2-char words from CC-CEDICT that fit in 209
print("[load] CC-CEDICT...")
cedict = []  # list of (word, pinyin, meaning)
with open(f"{ROOT}/wordlists/cedict.txt", encoding="utf-8") as f:
    for line in f:
        if line.startswith("#"): continue
        m = re.match(r"(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+?)/$", line.rstrip())
        if m:
            simp = m.group(2)
            chars = [c for c in simp if '一' <= c <= '鿿']
            if len(chars) == 2 and all(c in set209 for c in chars):
                cedict.append((simp, m.group(3), m.group(4).split("/")[0]))

print(f"[load] 209-only 2-char words: {len(cedict)}")

# 3) opus rank for prioritization
opus_rank = {}
with open(f"{ROOT}/output/word_freq_cd_s_nohk.tsv", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        opus_rank[row["word"]] = int(row["rank"])

# 4) Parse pinyin → tone + syllable
def parse_tones(py):
    syllables = py.split()
    tones = []
    for syl in syllables:
        m = re.search(r"([1-5])", syl)
        if m:
            t = int(m.group(1))
            if t == 5: t = 0  # 경성
            tones.append(t)
        else:
            tones.append(0)
    return tones

# 5) Group by (t1, t2) — 4x4 + 경성 (블랙리스트·중복 제거)
matrix = defaultdict(list)
seen_words = set()  # 전체 매트릭스에서 단어 중복 방지
for word, py, meaning in cedict:
    if word in BLACKLIST_WORDS: continue
    if word in seen_words: continue
    seen_words.add(word)
    tones = parse_tones(py)
    if len(tones) != 2: continue
    t1, t2 = tones[0], tones[1]
    rank = opus_rank.get(word, 99999)
    final_meaning = MEANING_OVERRIDE.get(word, meaning)
    matrix[(t1, t2)].append({
        "word": word,
        "pinyin": py,
        "meaning": final_meaning,
        "opus_rank": rank,
    })

# 6) ep1 등장 단어 우선 (수동)
EP1_WORDS = set("""
你好 想 认识 当然 可以 哪里 中文 也是 中国 人 上海
也 想 真的 什么 时候 那 早 我们 工作 设计 老师
要不 一起 喝 这个 周末 怎么 周六 几点 下午 两 点
对不 没事 太 可爱 周六 见 谢谢
""".split())

# Sort each cell: ep1 word first, then opus rank
for cell in matrix.values():
    cell.sort(key=lambda x: (0 if x["word"] in EP1_WORDS else 1, x["opus_rank"]))

# 7) Take top 10 per cell — 4×4 = 16 cells only (경성 별도)
final = {}
for t1 in [1, 2, 3, 4]:
    for t2 in [1, 2, 3, 4]:  # 경성 제외 → 16 cells
        cell = matrix.get((t1, t2), [])[:10]
        key = f"{t1}+{t2}"
        final[key] = {
            "tone1": t1,
            "tone2": t2,
            "label": f"{t1}성+{t2}성",
            "word_count": len(cell),
            "words": cell,
        }

# 경성 별도 group (보너스)
neutral_group = {}
for t1 in [1, 2, 3, 4]:
    cell = matrix.get((t1, 0), [])[:10]
    if cell:
        neutral_group[f"{t1}+neutral"] = {
            "tone1": t1, "tone2": "neutral",
            "label": f"{t1}성+경성",
            "word_count": len(cell),
            "words": cell,
        }

total = sum(c["word_count"] for c in final.values())

# 8) Final JSON
output = {
    "version": "v1",
    "created": str(date.today()),
    "title": "talkverse 중국어 성조 4×4 매트릭스 (160단어)",
    "description": "209 한자만 사용. ep1 다이얼로그 등장 단어 우선. 4×4 + 경성 = 20 cell × 10 words = 160.",
    "source": {
        "hanzi_pool": "209 한자 (core_hanzi_209.json)",
        "word_pool": "CC-CEDICT 2-char words filtered to 209-only",
        "priority_1": "ep1 dialogue (40 sentences) words",
        "priority_2": "opus rank (CD-weighted FINAL)",
    },
    "stats": {
        "total_words_in_pool": len(cedict),
        "matrix_cells": 16,
        "words_per_cell_target": 10,
        "total_in_matrix": total,
        "neutral_bonus_words": sum(c["word_count"] for c in neutral_group.values()),
    },
    "matrix_4x4": final,                    # ⭐ 16 cells × 10 = 160
    "neutral_bonus": neutral_group,         # 경성 별도 (학습 후반)
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\n=== 저장: {OUT} ({os.path.getsize(OUT):,} bytes) ===")
print(f"  총 단어 풀: {len(cedict)}")
print(f"  4×4 매트릭스 셀별 단어 수:")
for t1 in [1,2,3,4]:
    line = f"    {t1}성: "
    for t2 in [1,2,3,4]:
        n = final[f"{t1}+{t2}"]["word_count"]
        line += f"{t2}성={n:>2}  "
    print(line)
n_4x4 = sum(c["word_count"] for c in final.values())
n_neutral = sum(c["word_count"] for c in neutral_group.values())
print(f"  4×4 합계: {n_4x4}/160")
print(f"  경성 보너스: {n_neutral}")
