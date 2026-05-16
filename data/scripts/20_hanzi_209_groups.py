"""
Build core_hanzi_209.json — 207 핵심 한자 + 어기조사 신규 2 (嗯·嘛) = 209자.
같은 부수·같은 음절(성조만 다른) 한자 자동 그룹.

Output: D:/OneDrive/PROJECT/talkverse-learning/CH/Word/core_hanzi_209.json
"""
import csv, json, os, re
from datetime import date
from collections import defaultdict, Counter

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
OUT  = r"D:/OneDrive/PROJECT/talkverse-learning/CH/Word/core_hanzi_209.json"

# ----- 1. Top 209 = 207 + 嗯·嘛 -----
hanzi_data = []
with open(f"{ROOT}/output/hanzi_score_final.tsv", encoding="utf-8") as f:
    r = csv.DictReader(f, delimiter="\t")
    for row in r:
        hanzi_data.append(row)

set207 = set(h["char"] for h in hanzi_data[:207])
particles_added = ["嗯", "嘛"]
final_chars = set207 | set(particles_added)
total = len(final_chars)
print(f"Total unique: {total} (207 core + {len(particles_added)} particles)")

# ----- 2. Unihan -----
print("[load] Unihan...")
radical = {}; strokes = {}; mandarin = {}; kkorean = {}; khangul = {}
with open(f"{ROOT}/wordlists/hanzi_meta/Unihan_IRGSources.txt", encoding="utf-8") as f:
    for line in f:
        if line.startswith("#"): continue
        parts = line.rstrip().split("\t")
        if len(parts) < 3: continue
        cp = parts[0]
        try: ch = chr(int(cp[2:], 16))
        except: continue
        if ch not in final_chars: continue
        # IRG sources contain kRSUnicode in some Unihan versions
        if parts[1] == "kRSUnicode":
            rs = parts[2].split()[0]
            radnum, _, rem = rs.partition(".")
            try:
                radical[ch] = (int(radnum.replace("'", "")),
                               int(rem.replace("'", "")) if rem else 0)
            except: pass
        elif parts[1] == "kTotalStrokes":
            try: strokes[ch] = int(parts[2].split()[0])
            except: pass

# Try DictionaryLikeData for kRSUnicode (newer Unihan versions)
for unihan_file in ["Unihan_RadicalStrokeCounts.txt", "Unihan_DictionaryLikeData.txt", "Unihan_IRGSources.txt"]:
    fpath = f"{ROOT}/wordlists/hanzi_meta/{unihan_file}"
    if not os.path.exists(fpath): continue
    with open(fpath, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#"): continue
            parts = line.rstrip().split("\t")
            if len(parts) < 3: continue
            cp = parts[0]
            try: ch = chr(int(cp[2:], 16))
            except: continue
            if ch not in final_chars: continue
            if parts[1] == "kRSUnicode" and ch not in radical:
                rs = parts[2].split()[0]
                radnum, _, rem = rs.partition(".")
                try:
                    radical[ch] = (int(radnum.replace("'", "")),
                                   int(rem.replace("'", "")) if rem else 0)
                except: pass
            elif parts[1] == "kTotalStrokes" and ch not in strokes:
                try: strokes[ch] = int(parts[2].split()[0])
                except: pass

print(f"[debug] radical dict size: {len(radical)}, strokes: {len(strokes)}")

with open(f"{ROOT}/wordlists/hanzi_meta/Unihan_Readings.txt", encoding="utf-8") as f:
    for line in f:
        if line.startswith("#"): continue
        parts = line.rstrip().split("\t")
        if len(parts) < 3: continue
        cp = parts[0]
        try: ch = chr(int(cp[2:], 16))
        except: continue
        if ch not in final_chars: continue
        if parts[1] == "kMandarin":
            mandarin[ch] = parts[2].split()[0]
        elif parts[1] == "kKorean":
            kkorean[ch] = parts[2].split()[0]
        elif parts[1] == "kHangul":
            khangul[ch] = parts[2].split(":")[0]

# ----- 3. CC-CEDICT -----
print("[load] CC-CEDICT...")
cedict_meaning = {}
cedict_pinyin = {}
with open(f"{ROOT}/wordlists/cedict.txt", encoding="utf-8") as f:
    for line in f:
        if line.startswith("#"): continue
        m = re.match(r"(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+?)/$", line.rstrip())
        if m:
            simp = m.group(2)
            if len(simp) == 1 and simp in final_chars:
                cedict_pinyin.setdefault(simp, m.group(3))
                cedict_meaning.setdefault(simp, m.group(4).split("/")[0])

# ----- 4. HSK 한자 등급 -----
hsk_char = {}
for lvl in ["1","2","3","4","5","6","7-9"]:
    with open(f"{ROOT}/wordlists/HSK_hanzi_{lvl}.txt", encoding="utf-8") as f:
        for line in f:
            c = line.strip()
            if c and c not in hsk_char: hsk_char[c] = f"HSK{lvl}"

# ----- 5. 강희자전 214 부수 -----
KANGXI = "一丨丶丿乙亅二亠人儿入八冂冖冫几凵刀力勹匕匚匸十卜卩厂厶又口囗土士夂夊夕大女子宀寸小尢尸屮山巛工己巾干幺广廴廾弋弓彐彡彳心戈戶手支攴文斗斤方无日曰月木欠止歹殳毋比毛氏气水火爪父爻爿片牙牛犬玄玉瓜瓦甘生用田疋疒癶白皮皿目矛矢石示禸禾穴立竹米糸缶网羊羽老而耒耳聿肉臣自至臼舌舛舟艮色艸虍虫血行衣襾見角言谷豆豕豸貝赤走足身車辛辰辵邑酉釆里金長門阜隶隹雨青非面革韋韭音頁風飛食首香馬骨高髟鬥鬯鬲鬼魚鳥鹵鹿麥麻黃黍黑黹黽鼎鼓鼠鼻齊齒龍龜龠"

def radical_char(num):
    return KANGXI[num-1] if 1 <= num <= len(KANGXI) else "?"

# ----- 6. Pinyin 처리 (마크 → 음절·성조) -----
TONE_MAP = {}
for vowels, tone in [("āēīōūǖ", 1), ("áéíóúǘ", 2), ("ǎěǐǒǔǚ", 3), ("àèìòùǜ", 4)]:
    for v in vowels: TONE_MAP[v] = tone
TONE_STRIP = str.maketrans(
    "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ",
    "aaaaeeeeiiiioooouuuuvvvv"
)

def parse_pinyin(py_marked):
    if not py_marked: return ("", 0, "")
    tone = 0
    for ch in py_marked:
        if ch in TONE_MAP:
            tone = TONE_MAP[ch]; break
    syl = py_marked.translate(TONE_STRIP).lower()
    return (py_marked, tone, syl)

# ----- 7. Build characters list -----
opus_rank = {h["char"]: int(h["rank"]) for h in hanzi_data}
opus_score = {h["char"]: int(h["score_token"]) for h in hanzi_data}
opus_cumpct = {h["char"]: float(h["cum_pct"]) for h in hanzi_data}

chars_list = []
for c in sorted(final_chars, key=lambda x: opus_rank.get(x, 99999)):
    py_marked = mandarin.get(c, "")
    py, tone, syl = parse_pinyin(py_marked)
    rad_info = radical.get(c, (0, 0))
    chars_list.append({
        "char": c,
        "pinyin": py_marked,
        "pinyin_syllable": syl,
        "tone": tone,
        "meaning_en": cedict_meaning.get(c, ""),
        "radical_num": rad_info[0],
        "radical": radical_char(rad_info[0]) if rad_info[0] else "",
        "remaining_strokes": rad_info[1],
        "total_strokes": strokes.get(c, 0),
        "korean_reading": kkorean.get(c, ""),
        "korean_hangul": khangul.get(c, ""),
        "hsk_char_level": hsk_char.get(c, "none"),
        "rank_opus": opus_rank.get(c, 99999),
        "cum_pct": round(opus_cumpct.get(c, 0), 2),
        "score": opus_score.get(c, 0),
        "phase": "core_207" if c in set207 else "particle_added",
    })

# ----- 8. Group by radical -----
by_radical = defaultdict(list)
for c in chars_list:
    rn = c["radical_num"]
    if rn: by_radical[rn].append(c["char"])

radical_groups = {}
for rn, chars in by_radical.items():
    if len(chars) >= 2:
        radical_groups[str(rn)] = {
            "radical_num": rn,
            "radical_char": radical_char(rn),
            "chars": chars,
            "count": len(chars),
        }

# ----- 9. Group by syllable (성조만 다른 한자) -----
by_syllable = defaultdict(list)
for c in chars_list:
    syl = c["pinyin_syllable"]
    if syl:
        by_syllable[syl].append({
            "char": c["char"], "pinyin": c["pinyin"], "tone": c["tone"]
        })

syllable_groups = {}
for syl, chars in by_syllable.items():
    if len(chars) >= 2:
        chars.sort(key=lambda x: x["tone"])
        syllable_groups[syl] = {
            "syllable": syl,
            "chars": chars,
            "count": len(chars),
        }

# ----- 10. Stats -----
hsk_dist = Counter(c["hsk_char_level"] for c in chars_list)
tone_dist = Counter(c["tone"] for c in chars_list)

# ----- 11. Final JSON -----
final = {
    "version": "v2",
    "created": str(date.today()),
    "title": "talkverse 중국어 핵심 한자 셋 (Phase 2: 209자, 부수·음 그룹 포함)",
    "description": "회화 토큰 ~89% 커버. opus zh_cn 자막 88M 토큰 분석 (CD 가중·OpenCC·HK 제거 FINAL).",
    "composition": {
        "core_207": len(set207),
        "particles_added": len(particles_added),
        "particles_added_chars": particles_added,
        "total_unique": total,
    },
    "metadata_sources": {
        "pinyin_meaning": "CC-CEDICT (CC-BY-SA)",
        "radical_strokes": "Unihan kRSUnicode + kTotalStrokes",
        "korean_reading": "Unihan kKorean + kHangul",
        "hsk_char_levels": "신HSK 2021 공식 한자 분급 (krmanik HSK-3.0)",
        "opus_rank": "CD-weighted FINAL (opus zh_cn 88M tokens, 6,580 작품)",
    },
    "distribution": {
        "hsk": dict(hsk_dist),
        "tones": {str(k): v for k, v in sorted(tone_dist.items())},
        "unique_radicals": len(by_radical),
        "unique_syllables": len(by_syllable),
        "radical_groups_2plus": len(radical_groups),
        "syllable_groups_2plus": len(syllable_groups),
    },
    "groups": {
        "by_radical": radical_groups,
        "by_syllable_diff_tone": syllable_groups,
    },
    "characters": chars_list,
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(final, f, ensure_ascii=False, indent=2)

print(f"\n=== 저장: {OUT} ({os.path.getsize(OUT):,} bytes) ===")
print(f"  총 한자: {total}")
print(f"  HSK 분포: {dict(hsk_dist)}")
print(f"  성조 분포: {dict(sorted(tone_dist.items()))}")
print(f"  unique 부수: {len(by_radical)}, ≥2한자 부수 그룹: {len(radical_groups)}")
print(f"  unique 음절: {len(by_syllable)}, ≥2한자 음절 그룹: {len(syllable_groups)}")

print("\n=== Top 부수 그룹 (≥3 한자) ===")
for rn, info in sorted(radical_groups.items(), key=lambda x: -x[1]["count"])[:15]:
    if info["count"] >= 3:
        print(f"  부수 {rn} ({info['radical_char']}) — {info['count']}자: {' '.join(info['chars'])}")

print("\n=== Top 음절 그룹 (성조만 다른 한자, ≥3) ===")
for syl, info in sorted(syllable_groups.items(), key=lambda x: -x[1]["count"])[:20]:
    if info["count"] >= 2:
        chars_str = " ".join(f"{c['char']}({c['pinyin']})" for c in info["chars"])
        print(f"  {syl} — {info['count']}자: {chars_str}")
