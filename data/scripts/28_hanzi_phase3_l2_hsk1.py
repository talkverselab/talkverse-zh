"""
Phase 3 (L2) — HSK1 풀 커버 141자 추가 → 총 380자.

배경
====
talkverse 마케팅 슬로건 = "200자 외우면 시작" → 209 핵심 한자 + Phase 2 보너스 30자 = L1 (239자) 보존.
**L2 마일스톤 = HSK1 시험 한자 100% 커버 (300/300)**.

기존 239자는 HSK1 159/300 = 53% 커버. L2 단계에서 HSK1 미커버 141자를 모두 추가하여
HSK1 시험 한자 풀을 100% 인식 가능. (영화 회화 커버 ~89% → ~95%+ 추가 상승.)

HSK1 미커버 141자 (자동 추출됨):
  상위 100자 (영화 빈도 高, opus rank 200-700) — 학습 동기 강함
  하위 41자 (영화 거의 X, 시험 전용 — opus rank 700-1900) — HSK1 합격 위해 필요

기존 209 (Phase 1) + 30 (Phase 2) 변경 X. 마케팅 "209" 슬로건 보존.

In-place update — 두 경로 동기화:
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
HSK1_PATH = f"{ROOT}/wordlists/HSK_hanzi_1.txt"

PHASE_TAG = "phase3_l2_hsk1"
PHASE_GROUP = "3"

# ---------------------------------------------------------------------------
# 1) 추가할 141자 — basic_meaning_ko 수동 큐레이트
#    학습자용 기본 의미 (surname/지명 fallback 회피).
#    빈도 상위 100자 = 영화 자주, 하위 41자 = 시험 전용.
# ---------------------------------------------------------------------------
NEW_CHARS_META = {
    # ---------- 빈도 상위 100자 (rank 200-700, 영화 회화 高) ----------
    # 사람·관계·신분
    "老": "늙다, 오래된 (老师=선생님)",
    "少": "적다, 젊다",
    "名": "이름",
    "男": "남자",
    "姐": "누나, 언니",
    "弟": "남동생",
    "身": "몸",
    "医": "의사, 의술",
    "教": "가르치다",
    # 기본 동사
    "买": "사다",
    "送": "보내다, 선물하다",
    "笑": "웃다",
    "睡": "자다",
    "穿": "입다",
    "写": "쓰다 (글)",
    "玩": "놀다",
    "跑": "달리다",
    "动": "움직이다",
    "唱": "노래하다",
    "试": "시험, 시도하다",
    "答": "대답하다",
    "考": "시험보다",
    "休": "쉬다",
    "病": "병, 아프다",
    "教": "가르치다",
    # 기본 명사
    "字": "글자",
    "手": "손",
    "本": "책, 근본",
    "车": "차, 자동차",
    "马": "말 (동물)",
    "机": "기계 (飞机=비행기)",
    "房": "방, 집",
    "月": "달, 월",
    "蛋": "알, 계란",
    "服": "옷 (衣服=옷)",
    "衣": "옷",
    "号": "번호, 날짜",
    "门": "문",
    "院": "마당, 병원",
    "路": "길",
    "条": "가닥, 줄기 (양사)",
    "影": "그림자 (电影=영화)",
    "校": "학교",
    "球": "공",
    "脑": "뇌 (电脑=컴퓨터)",
    "息": "쉼, 소식",
    "系": "관계, 매다",
    "包": "가방, 싸다",
    "歌": "노래",
    "图": "그림, 지도",
    "楼": "건물, 층",
    "床": "침대",
    "杯": "잔, 컵",
    "饭": "밥",
    "蛋": "알, 계란",
    "花": "꽃",
    # 시간
    "早": "이르다, 아침",
    "晚": "늦다, 저녁",
    "日": "날, 해",
    "昨": "어제 (昨天=어제)",
    "星": "별 (星期=주)",
    "期": "기간",
    "岁": "세, 살 (나이)",
    "午": "낮, 정오",
    "半": "반, 절반",
    # 수사
    "三": "셋, 3",
    "二": "둘, 2",
    "五": "다섯, 5",
    "十": "열, 10",
    "几": "몇",
    "第": "제~ (순서)",
    "分": "나누다, 분(시간)",
    # 형용사·상태
    "新": "새롭다",
    "高": "높다, 키 크다",
    "重": "무겁다, 중요하다",
    "远": "멀다",
    "外": "바깥",
    "忙": "바쁘다",
    "难": "어렵다",
    "差": "다르다, 부족하다",
    "冷": "춥다",
    "坏": "나쁘다, 망가지다",
    "慢": "느리다",
    # 나머지 빈도 상위
    "兴": "흥, 흥미 (高兴=기쁘다)",
    "同": "같다, 함께",
    "边": "옆, 가장자리",
    "站": "서다, 역",
    "飞": "날다",
    "场": "장소, 마당",
    # ---------- 빈도 하위 41자 (rank 700+, 시험 전용 + 일상 단어) ----------
    # 음식·요리
    "米": "쌀",
    "肉": "고기",
    "牛": "소",
    "鸡": "닭",
    "茶": "차 (마시는)",
    "菜": "채소, 요리",
    "汽": "김, 가스 (汽车=차)",
    # 동작
    "读": "읽다",
    "洗": "씻다",
    # 위치·방향
    "旁": "옆",
    "左": "왼쪽",
    "右": "오른쪽",
    "南": "남쪽",
    "北": "북쪽",
    "山": "산",
    # 자연·날씨
    "风": "바람",
    "雨": "비",
    "水": "물",
    "火": "불",
    "热": "덥다, 뜨겁다",
    # 수사·단위
    "元": "위안 (화폐)",
    "八": "여덟, 8",
    "七": "일곱, 7",
    "九": "아홉, 9",
    "百": "백, 100",
    "零": "영, 0",
    # 학습·시험
    "文": "글, 문장",
    "语": "말, 언어",
    "课": "수업, 과목",
    "汉": "한(漢) (汉语=중국어)",
    "页": "쪽 (페이지)",
    "书": "책",
    "习": "익히다 (学习=배우다)",
    # 사물·기타
    "桌": "탁자, 책상",
    "树": "나무",
    "毛": "털, 마오 (화폐)",
    "票": "표, 티켓",
    "网": "그물 (인터넷)",
    "贵": "비싸다, 귀하다",
    "馆": "건물 (饭馆=식당)",
    "商": "장사 (商店=가게)",
    "京": "서울 (수도, 北京=베이징)",
    "净": "깨끗하다",
    "累": "피곤하다",
    "渴": "목마르다",
    "饿": "배고프다",
    # 추가 안내자
    "介": "끼이다 (介绍=소개)",
    "绍": "잇다 (介绍=소개)",
    # 기타 빈도 상위에서 빠진 것 (상위 100에 들어가 있어야 했지만 정리 차원)
    "视": "보다 (电视=TV)",
    "口": "입",
    "班": "반, 근무",
    # 누락분 보정
    "体": "몸 (身体=신체)",
    "假": "거짓, 휴가 (放假=방학)",
    "四": "넷, 4",
    "块": "덩어리, 위안 (口语 화폐 단위)",
}

# Validate / load actual list from JSON + HSK1 file
def compute_uncovered():
    # Load existing chars from primary path
    with open(PATHS[0], encoding="utf-8") as f:
        d = json.load(f)
    have = set(c["char"] for c in d["characters"])
    with open(HSK1_PATH, encoding="utf-8") as f:
        hsk1 = set(c.strip() for c in f if c.strip())
    return sorted(hsk1 - have), hsk1, have


# ---------------------------------------------------------------------------
# 2) Unihan / CC-CEDICT / HSK / opus rank 메타 로드 (script 27 와 동일 패턴)
# ---------------------------------------------------------------------------
def load_meta(target_chars):
    target = set(target_chars)

    radical = {}
    strokes = {}
    mandarin = {}
    kkorean = {}
    khangul = {}

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

    hsk_char = {}
    for lvl in ["1", "2", "3", "4", "5", "6", "7-9"]:
        with open(f"{ROOT}/wordlists/HSK_hanzi_{lvl}.txt", encoding="utf-8") as f:
            for line in f:
                c = line.strip()
                if c and c not in hsk_char:
                    hsk_char[c] = f"HSK{lvl}"

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
# 3) Pinyin tone parsing (동일)
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
# 4) Kangxi 214 부수
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
# 5) Build new entries
# ---------------------------------------------------------------------------
def build_new_entries(new_chars, meta) -> list:
    entries = []
    for c in new_chars:
        py_marked = meta["mandarin"].get(c, "")
        py, tone, syl = parse_pinyin(py_marked)
        rad_info = meta["radical"].get(c, (0, 0))

        # basic_meaning_ko: manual curation > fallback (korean_hangul + meaning_en first phrase)
        if c in NEW_CHARS_META:
            basic_ko = NEW_CHARS_META[c]
        else:
            khan = meta["khangul"].get(c, "")
            men_en = meta["cedict_meaning"].get(c, "")
            # take first short phrase, strip parenthetical
            men_short = re.sub(r"\([^)]*\)", "", men_en).strip()
            men_short = men_short.split(",")[0].split(";")[0].strip()
            if khan and men_short:
                basic_ko = f"{khan} ({men_short})"
            elif khan:
                basic_ko = khan
            else:
                basic_ko = men_short or "?"

        entries.append(
            {
                "char": c,
                "pinyin": py_marked,
                "pinyin_syllable": syl,
                "tone": tone,
                "meaning_en": meta["cedict_meaning"].get(c, ""),
                "basic_meaning_ko": basic_ko,
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
    entries.sort(key=lambda e: e["rank_opus"])
    return entries


# ---------------------------------------------------------------------------
# 6) Recompute groups & distribution (script 27 와 동일)
# ---------------------------------------------------------------------------
def recompute(data: dict) -> dict:
    chars_list = data["characters"]

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
    print("[hsk1] computing uncovered chars...")
    new_chars, hsk1_set, existing_set = compute_uncovered()
    print(f"  HSK1 total: {len(hsk1_set)}")
    print(f"  현재 보유 (Phase 1+2): {len(existing_set)}")
    print(f"  HSK1 보유: {len(hsk1_set & existing_set)}/{len(hsk1_set)}")
    print(f"  HSK1 미커버 → 추가: {len(new_chars)}")

    n_curated = sum(1 for c in new_chars if c in NEW_CHARS_META)
    print(f"  basic_meaning_ko 수동 큐레이트: {n_curated}/{len(new_chars)}")
    n_fallback = len(new_chars) - n_curated
    if n_fallback:
        print(f"  fallback (korean_hangul + meaning_en): {n_fallback}자")
        fallback_chars = [c for c in new_chars if c not in NEW_CHARS_META]
        print(f"    chars: {' '.join(fallback_chars)}")

    print("\n[load] meta...")
    meta = load_meta(new_chars)
    print(
        f"  radical: {len(meta['radical'])}, strokes: {len(meta['strokes'])}, "
        f"pinyin: {len(meta['mandarin'])}, hsk: {sum(1 for c in new_chars if c in meta['hsk_char'])}"
    )

    new_entries = build_new_entries(new_chars, meta)
    print(f"\n[built] {len(new_entries)} new entries (sorted by rank_opus):")
    for e in new_entries[:20]:
        print(
            f"  {e['char']} {e['pinyin']:<8} t{e['tone']} "
            f"r{e['radical_num']:>3}({e['radical']}) "
            f"{e['hsk_char_level']:<6} rank={e['rank_opus']:>4}  {e['basic_meaning_ko']}"
        )
    print(f"  ... and {len(new_entries) - 20} more")

    for path in PATHS:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

        existing = {c["char"] for c in data["characters"]}
        to_add = [e for e in new_entries if e["char"] not in existing]
        if len(to_add) != len(new_entries):
            skipped = [e["char"] for e in new_entries if e["char"] in existing]
            print(f"  [warn] {path} 이미 포함된 글자 skip: {skipped}")

        data["characters"].extend(to_add)

        # 메타 갱신 — Phase 3 / L2 mark
        data["version"] = "v4-l2-hsk1"
        data["created"] = str(date.today())
        data["title"] = (
            "talkverse 중국어 핵심 한자 셋 v4 — L2 (Phase 1: 209 + Phase 2: 30 + Phase 3: 141 = 380자, HSK1 100%)"
        )
        data["description"] = (
            "L1 = 239자 (회화 토큰 ~89% 커버, HSK1 53%). "
            "L2 = 380자 (HSK1 시험 한자 100% 커버, 영화 회화 ~95%+). "
            "Phase 3 (L2) = HSK1 미커버 141자 자동 추가 — 시험 + 영화 동시 공략."
        )
        # composition: keep prior keys + reflect ALL phase3 chars currently in data
        # (idempotent: re-running the script must not zero out phase3 count when nothing new is added)
        comp = data.get("composition", {})
        all_phase3 = sorted(
            [c for c in data["characters"] if c.get("phase_group") == PHASE_GROUP],
            key=lambda c: c.get("rank_opus", 99999),
        )
        comp.update(
            {
                "phase3_l2_hsk1": len(all_phase3),
                "phase3_l2_hsk1_chars": [c["char"] for c in all_phase3],
                "total_unique": len(data["characters"]),
            }
        )
        data["composition"] = comp

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
        pg = Counter(c.get("phase_group") for c in data["characters"])
        print(f"  phase_group: {dict(pg)}")

        # HSK1 covered check
        chars_now = set(c["char"] for c in data["characters"])
        hsk1_covered = chars_now & hsk1_set
        print(f"  HSK1 covered: {len(hsk1_covered)}/{len(hsk1_set)} = {len(hsk1_covered)/len(hsk1_set)*100:.1f}%")


if __name__ == "__main__":
    main()
