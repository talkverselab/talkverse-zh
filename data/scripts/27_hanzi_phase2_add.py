"""
Phase 2 (보너스) — 209 한자 셋에 30자 추가 → 총 239자.

배경
====
talkverse 마케팅 슬로건 = "200자 외우면 시작" → 209 핵심 한자 보존.
HSKK vs talkverse 비교 분석 (`C:/dev/.claude/plans/hskk-vs-talkverse-zh.md` §5-1)
에 따라 다이얼로그 ep1-5 가 실제로 사용하지만 209에 빠진 30자를
**별도 phase_group "2" (Phase 2 보너스)** 로 추가한다.

추가 30자 (모두 209에 없음, 검증 완료):
  가족 호칭/존칭/학습:  学 您 忘 爷 奶 叔 姨 哥 妹 父 母
  시간/장소:            周 末 六 海 韩 国
  명사/동사 단자:       设 计 咖 啡 喝 店 客 气 坐 识 师
  회화 marker:          哎 哈

기존 209 phase_group(1A·1B·1C) 변경 없음. 마케팅 "209" 슬로건 보존.

In-place update — 두 경로 모두 출력:
  - C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json
  - D:/OneDrive/PROJECT/talkverse-learning/ZH/Word/core_hanzi_209.json
"""
import csv
import io
import json
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import date

# Ensure UTF-8 console output on Windows (cp949 default chokes on CJK)
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")
except Exception:
    pass

ROOT = r"D:/OneDrive/DATA_Processed/zh_opus"
PATHS = [
    r"C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json",
    r"D:/OneDrive/PROJECT/talkverse-learning/ZH/Word/core_hanzi_209.json",
]

# ---------------------------------------------------------------------------
# 1) 추가할 30자 (수동 큐레이트된 한국어 학습자 친숙 의미 포함)
#    basic_meaning_ko 는 surname/지명 오류 회피, 학습 1순위 의미만 표기.
# ---------------------------------------------------------------------------
NEW_CHARS_META = {
    # 학습/존칭
    "学": "배우다, 공부",
    "您": "당신 (존칭)",
    "忘": "잊다",
    # 가족 호칭
    "爷": "할아버지",
    "奶": "할머니, 우유",
    "叔": "삼촌, 아저씨",
    "姨": "이모, 아주머니",
    "哥": "형, 오빠",
    "妹": "여동생",
    "父": "아버지",
    "母": "어머니",
    # 시간/장소
    "周": "주(週), 일주일",
    "末": "끝, 주말",
    "六": "여섯, 6",
    "海": "바다",
    "韩": "한국",
    "国": "나라",
    # 명사/동사 단자
    "设": "세우다, 설치 (设计=디자인)",
    "计": "계산하다 (设计=디자인)",
    "咖": "(咖啡=커피)",
    "啡": "(咖啡=커피)",
    "喝": "마시다",
    "店": "가게, 상점",
    "客": "손님",
    "气": "공기, 기분 (客气=사양)",
    "坐": "앉다",
    "识": "알다 (认识=알다)",
    "师": "선생님 (设计师=디자이너)",
    # 회화 marker
    "哎": "어이! 아이고! (감탄)",
    "哈": "하 (웃음·감탄)",
}
NEW_CHARS = list(NEW_CHARS_META.keys())
assert len(NEW_CHARS) == 30, f"expected 30 chars, got {len(NEW_CHARS)}"

PHASE_TAG = "phase2_bonus"
PHASE_GROUP = "2"

# ---------------------------------------------------------------------------
# 2) Unihan / CC-CEDICT / HSK / opus rank 메타 로드 (기존 script 20 과 동일 패턴)
# ---------------------------------------------------------------------------
def load_meta():
    target = set(NEW_CHARS)

    radical = {}
    strokes = {}
    mandarin = {}
    kkorean = {}
    khangul = {}

    # Unihan IRG / RSC / Dict / Readings
    for unihan_file in [
        "Unihan_IRGSources.txt",
        "Unihan_RadicalStrokeCounts.txt",
        "Unihan_DictionaryLikeData.txt",
    ]:
        fpath = f"{ROOT}/wordlists/hanzi_meta/{unihan_file}"
        if not os.path.exists(fpath):
            continue
        with open(fpath, encoding="utf-8") as f:
            for line in f:
                if line.startswith("#"):
                    continue
                parts = line.rstrip().split("\t")
                if len(parts) < 3:
                    continue
                cp = parts[0]
                try:
                    ch = chr(int(cp[2:], 16))
                except Exception:
                    continue
                if ch not in target:
                    continue
                if parts[1] == "kRSUnicode" and ch not in radical:
                    rs = parts[2].split()[0]
                    radnum, _, rem = rs.partition(".")
                    try:
                        radical[ch] = (
                            int(radnum.replace("'", "")),
                            int(rem.replace("'", "")) if rem else 0,
                        )
                    except Exception:
                        pass
                elif parts[1] == "kTotalStrokes" and ch not in strokes:
                    try:
                        strokes[ch] = int(parts[2].split()[0])
                    except Exception:
                        pass

    with open(f"{ROOT}/wordlists/hanzi_meta/Unihan_Readings.txt", encoding="utf-8") as f:
        for line in f:
            if line.startswith("#"):
                continue
            parts = line.rstrip().split("\t")
            if len(parts) < 3:
                continue
            cp = parts[0]
            try:
                ch = chr(int(cp[2:], 16))
            except Exception:
                continue
            if ch not in target:
                continue
            if parts[1] == "kMandarin":
                mandarin[ch] = parts[2].split()[0]
            elif parts[1] == "kKorean":
                kkorean[ch] = parts[2].split()[0]
            elif parts[1] == "kHangul":
                khangul[ch] = parts[2].split(":")[0]

    # CC-CEDICT
    cedict_meaning = {}
    cedict_pinyin = {}
    with open(f"{ROOT}/wordlists/cedict.txt", encoding="utf-8") as f:
        for line in f:
            if line.startswith("#"):
                continue
            m = re.match(r"(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+?)/$", line.rstrip())
            if m:
                simp = m.group(2)
                if len(simp) == 1 and simp in target:
                    cedict_pinyin.setdefault(simp, m.group(3))
                    cedict_meaning.setdefault(simp, m.group(4).split("/")[0])

    # HSK 한자 등급
    hsk_char = {}
    for lvl in ["1", "2", "3", "4", "5", "6", "7-9"]:
        with open(f"{ROOT}/wordlists/HSK_hanzi_{lvl}.txt", encoding="utf-8") as f:
            for line in f:
                c = line.strip()
                if c and c not in hsk_char:
                    hsk_char[c] = f"HSK{lvl}"

    # opus rank · score · cum_pct
    opus_rank = {}
    opus_score = {}
    opus_cumpct = {}
    with open(f"{ROOT}/output/hanzi_score_final.tsv", encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            ch = row["char"]
            if ch in target:
                opus_rank[ch] = int(row["rank"])
                opus_score[ch] = int(row["score_token"])
                opus_cumpct[ch] = float(row["cum_pct"])

    return {
        "radical": radical,
        "strokes": strokes,
        "mandarin": mandarin,
        "kkorean": kkorean,
        "khangul": khangul,
        "cedict_meaning": cedict_meaning,
        "cedict_pinyin": cedict_pinyin,
        "hsk_char": hsk_char,
        "opus_rank": opus_rank,
        "opus_score": opus_score,
        "opus_cumpct": opus_cumpct,
    }


# ---------------------------------------------------------------------------
# 3) Pinyin 마크 처리 (script 20 와 동일)
# ---------------------------------------------------------------------------
TONE_MAP = {}
for vowels, tone in [
    ("āēīōūǖ", 1),
    ("áéíóúǘ", 2),
    ("ǎěǐǒǔǚ", 3),
    ("àèìòùǜ", 4),
]:
    for v in vowels:
        TONE_MAP[v] = tone
TONE_STRIP = str.maketrans(
    "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ",
    "aaaaeeeeiiiioooouuuuvvvv",
)


def parse_pinyin(py_marked: str):
    if not py_marked:
        return ("", 0, "")
    tone = 0
    for ch in py_marked:
        if ch in TONE_MAP:
            tone = TONE_MAP[ch]
            break
    syl = py_marked.translate(TONE_STRIP).lower()
    return (py_marked, tone, syl)


# ---------------------------------------------------------------------------
# 4) 강희 214 부수 → 한자
# ---------------------------------------------------------------------------
KANGXI = (
    "一丨丶丿乙亅二亠人儿入八冂冖冫几凵刀力勹匕匚匸十卜卩厂厶又口囗土士夂夊夕大女子"
    "宀寸小尢尸屮山巛工己巾干幺广廴廾弋弓彐彡彳心戈戶手支攴文斗斤方无日曰月木欠止歹"
    "殳毋比毛氏气水火爪父爻爿片牙牛犬玄玉瓜瓦甘生用田疋疒癶白皮皿目矛矢石示禸禾穴立"
    "竹米糸缶网羊羽老而耒耳聿肉臣自至臼舌舛舟艮色艸虍虫血行衣襾見角言谷豆豕豸貝赤走"
    "足身車辛辰辵邑酉釆里金長門阜隶隹雨青非面革韋韭音頁風飛食首香馬骨高髟鬥鬯鬲鬼魚"
    "鳥鹵鹿麥麻黃黍黑黹黽鼎鼓鼠鼻齊齒龍龜龠"
)


def radical_char(num: int) -> str:
    return KANGXI[num - 1] if 1 <= num <= len(KANGXI) else ""


# ---------------------------------------------------------------------------
# 5) Build new character entries
# ---------------------------------------------------------------------------
def build_new_entries(meta) -> list:
    entries = []
    for c in NEW_CHARS:
        py_marked = meta["mandarin"].get(c, "")
        py, tone, syl = parse_pinyin(py_marked)
        rad_info = meta["radical"].get(c, (0, 0))
        entries.append(
            {
                "char": c,
                "pinyin": py_marked,
                "pinyin_syllable": syl,
                "tone": tone,
                "meaning_en": meta["cedict_meaning"].get(c, ""),
                "basic_meaning_ko": NEW_CHARS_META[c],
                "radical_num": rad_info[0],
                "radical": radical_char(rad_info[0]) if rad_info[0] else "",
                "remaining_strokes": rad_info[1],
                "total_strokes": meta["strokes"].get(c, 0),
                "korean_reading": meta["kkorean"].get(c, ""),
                "korean_hangul": meta["khangul"].get(c, ""),
                "hsk_char_level": meta["hsk_char"].get(c, "none"),
                "rank_opus": meta["opus_rank"].get(c, 99999),
                "cum_pct": round(meta["opus_cumpct"].get(c, 0.0), 2),
                "score": meta["opus_score"].get(c, 0),
                "phase": PHASE_TAG,
                "phase_group": PHASE_GROUP,
            }
        )
    # 빈도(rank_opus) 오름차순 정렬 — Phase 2 안에서도 빈도순 학습
    entries.sort(key=lambda e: e["rank_opus"])
    return entries


# ---------------------------------------------------------------------------
# 6) Recompute groups & distribution over ALL chars
# ---------------------------------------------------------------------------
def recompute(data: dict) -> dict:
    chars_list = data["characters"]

    # by_radical (≥2 한자만 보존 — 기존 script 20 컨벤션 유지)
    by_radical_all = defaultdict(list)
    for c in chars_list:
        rn = c.get("radical_num") or 0
        if rn:
            by_radical_all[rn].append(c["char"])
    radical_groups = {}
    for rn, chars in by_radical_all.items():
        if len(chars) >= 2:
            radical_groups[str(rn)] = {
                "radical_num": rn,
                "radical_char": radical_char(rn),
                "chars": chars,
                "count": len(chars),
            }

    # by_syllable_diff_tone (≥2 한자만, 기존 키 유지)
    by_syllable_all = defaultdict(list)
    for c in chars_list:
        syl = c.get("pinyin_syllable") or ""
        if syl:
            by_syllable_all[syl].append(
                {
                    "char": c["char"],
                    "pinyin": c.get("pinyin", ""),
                    "tone": c.get("tone", 0),
                }
            )
    syllable_groups = {}
    for syl, items in by_syllable_all.items():
        if len(items) >= 2:
            items.sort(key=lambda x: x["tone"])
            syllable_groups[syl] = {
                "syllable": syl,
                "chars": items,
                "count": len(items),
            }

    # distribution
    hsk_dist = Counter(c.get("hsk_char_level", "none") for c in chars_list)
    tone_dist = Counter(c.get("tone", 0) for c in chars_list)

    data["groups"] = {
        "by_radical": radical_groups,
        "by_syllable_diff_tone": syllable_groups,
    }
    data["distribution"] = {
        "hsk": dict(hsk_dist),
        "tones": {str(k): v for k, v in sorted(tone_dist.items())},
        "unique_radicals": len(by_radical_all),
        "unique_syllables": len(by_syllable_all),
        "radical_groups_2plus": len(radical_groups),
        "syllable_groups_2plus": len(syllable_groups),
    }
    return data


# ---------------------------------------------------------------------------
# 7) Main
# ---------------------------------------------------------------------------
def main():
    print(f"[load] meta for {len(NEW_CHARS)} new chars...")
    meta = load_meta()
    print(
        f"  radical: {len(meta['radical'])}, strokes: {len(meta['strokes'])}, "
        f"pinyin: {len(meta['mandarin'])}, hsk: {sum(1 for c in NEW_CHARS if c in meta['hsk_char'])}"
    )

    new_entries = build_new_entries(meta)
    print(f"\n[built] {len(new_entries)} new entries:")
    for e in new_entries:
        print(
            f"  {e['char']} {e['pinyin']:<8} t{e['tone']} "
            f"r{e['radical_num']:>3}({e['radical']}) "
            f"{e['hsk_char_level']:<6} rank={e['rank_opus']:>4}  {e['basic_meaning_ko']}"
        )

    for path in PATHS:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

        existing = {c["char"] for c in data["characters"]}
        to_add = [e for e in new_entries if e["char"] not in existing]
        if len(to_add) != len(new_entries):
            skipped = [e["char"] for e in new_entries if e["char"] in existing]
            print(f"  [warn] {path} 이미 포함된 글자 skip: {skipped}")

        data["characters"].extend(to_add)

        # 메타 갱신
        data["version"] = "v3-phase2"
        data["created"] = str(date.today())
        data["title"] = (
            "talkverse 중국어 핵심 한자 셋 v3 (Phase 1: 209자 + Phase 2 보너스 30자 = 239자)"
        )
        data["description"] = (
            "회화 토큰 ~89% 커버. opus zh_cn 자막 88M 토큰 분석 (CD 가중·OpenCC·HK 제거 FINAL). "
            "Phase 2 (보너스 30자) = 다이얼로그 즉시 등장 — HSKK 초급 보강 (가족 호칭·시간·존칭·marker)."
        )
        data["composition"] = {
            "core_207": 207,
            "particles_added": 2,
            "particles_added_chars": ["嗯", "嘛"],
            "phase2_bonus": len(to_add),
            "phase2_bonus_chars": [e["char"] for e in to_add],
            "total_unique": len(data["characters"]),
        }

        recompute(data)

        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        size = os.path.getsize(path)
        print(f"\n[saved] {path} ({size:,} bytes)")
        print(f"  total chars: {len(data['characters'])}")
        print(f"  hsk dist: {data['distribution']['hsk']}")
        print(f"  tone dist: {data['distribution']['tones']}")
        print(
            f"  radicals: unique={data['distribution']['unique_radicals']}, "
            f"groups≥2={data['distribution']['radical_groups_2plus']}"
        )
        print(
            f"  syllables: unique={data['distribution']['unique_syllables']}, "
            f"groups≥2={data['distribution']['syllable_groups_2plus']}"
        )
        # phase_group counts
        pg = Counter(c.get("phase_group") for c in data["characters"])
        print(f"  phase_group: {dict(pg)}")


if __name__ == "__main__":
    main()
