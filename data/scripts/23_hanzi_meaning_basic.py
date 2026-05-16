"""
Add basic_meaning_ko to core_hanzi_209.json.
Fix surname/지명 오류 from CC-CEDICT.

Input:  ZH/Word/core_hanzi_209.json
Output: ZH/Word/core_hanzi_209.json (in-place, basic_meaning_ko added per char)
"""
import json, os

ZH = r"D:/OneDrive/PROJECT/talkverse-learning/ZH"
PATH = f"{ZH}/Word/core_hanzi_209.json"

# Manual override for problematic chars (앱용 학습자 기본 의미)
BASIC_MEANING_KO = {
    # surname/지명 오류
    "那": "저/그",
    "能": "할 수 있다",
    "都": "모두",
    "还": "아직/또",
    "比": "비교하다/~보다",
    "非": "아니다/비-",
    "嗯": "응/음",
    # 기타 자주 등장 + 학습용 보강
    "我": "나",
    "你": "너",
    "他": "그",
    "她": "그녀",
    "是": "이다",
    "不": "아니다 (부정)",
    "了": "(완료·변화 어조)",
    "的": "(소유·수식)",
    "在": "있다/~에서",
    "有": "있다/가지다",
    "去": "가다",
    "来": "오다",
    "好": "좋다",
    "什": "(什么 = 무엇)",
    "么": "(什么·怎么 등)",
    "怎": "어떻게",
    "这": "이/이것",
    "那": "저/그것",  # 위 surname 정정 다시 (override)
    "个": "(양사) 개",
    "和": "그리고/와",
    "也": "~도",
    "就": "곧/바로",
    "很": "매우",
    "太": "너무",
    "都": "모두",  # 다시
    "啊": "(어기조사) 친근·감정",
    "吧": "(어기조사) 제안·확인",
    "吗": "(어기조사) yes/no 의문",
    "呢": "(어기조사) 되묻기·진행",
    "啦": "(어기조사) 가벼운 완료·동의",
    "哦": "(어기조사) 아~/오~",
    "呀": "(어기조사) 啊의 변형",
    "嘛": "(어기조사) ~잖아",
    "嗯": "(어기조사) 응/음",  # 다시
    "哪": "어느/어떤",
    "喂": "(부르기) 여보세요",
    "嘿": "(부르기) 야",
    "嗨": "(부르기) Hi",
    "想": "~하고 싶다/생각하다",
    "要": "~할 것/필요하다",
    "会": "~할 줄 알다/~할 것이다",
    "可": "(可以 = 할 수 있다)",
    "以": "(可以·以后 등)",
    "应": "(应该 = ~해야)",
    "该": "(应该)",
    "得": "(보어·得到 등)",
    "过": "(경험) ~한 적 있다",
    "没": "없다 (부정)",
    "给": "주다/~에게",
    "让": "~하게 하다",
    "做": "하다/만들다",
    "说": "말하다",
    "看": "보다",
    "听": "듣다",
    "吃": "먹다",
    "喝": "마시다",
    "走": "가다/걷다",
    "到": "도착하다/~까지",
    "对": "맞다/~에 대해",
    "问": "묻다",
    "知": "(知道 = 알다)",
    "道": "(知道·味道)",
    "想": "~하고 싶다",  # 다시
    "时": "(时候 = 때)",
    "候": "(时候)",
    "现": "(现在 = 지금)",
    "年": "년/해",
    "月": "월/달",
    "天": "일/하늘",
    "日": "일/날",
    "今": "(今天 = 오늘)",
    "明": "(明天 = 내일)",
    "昨": "(昨天 = 어제)",
    "上": "위/오르다/지난",
    "下": "아래/내리다/다음",
    "里": "안/속",
    "外": "밖",
    "中": "가운데/안",
    "大": "크다",
    "小": "작다",
    "多": "많다",
    "少": "적다",
    "高": "높다",
    "长": "길다",
    "新": "새롭다",
    "老": "오래된/어르신",
    "好看": "예쁘다 (※ 단자 好+看)",
    # surname 가능성 있는 기타
    "万": "만 (10000)",
    "金": "금/(姓)",
    "白": "흰/(姓)",
    "马": "말/(姓)",
    "高": "높다/(姓)",
}

# Load JSON
with open(PATH, encoding="utf-8") as f:
    data = json.load(f)

# Walk characters
chars = data.get("characters", [])
n_added, n_kept = 0, 0
for c in chars:
    ch = c.get("char")
    if ch in BASIC_MEANING_KO:
        c["basic_meaning_ko"] = BASIC_MEANING_KO[ch]
        n_added += 1
    else:
        # 기본 fallback: korean_reading 또는 meaning_en first phrase
        kor = c.get("korean_reading", "")
        meaning_en = c.get("meaning", "")
        # 영문 의미 첫 phrase만 (slash 분리)
        first_en = meaning_en.split("/")[0].strip() if meaning_en else ""
        c["basic_meaning_ko"] = f"({kor}) {first_en}".strip() if (kor or first_en) else ""
        n_kept += 1

# Save
with open(PATH, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"[done] {PATH}")
print(f"  manual basic_meaning_ko added: {n_added}")
print(f"  fallback (korean_reading + meaning EN): {n_kept}")
print(f"  total chars: {len(chars)}")

# Print 핵심 7자 (surname/지명 오류 정정 확인)
KEY = ["那", "能", "都", "还", "比", "非", "嗯"]
print("\n=== 핵심 7자 정정 확인 ===")
for c in chars:
    if c.get("char") in KEY:
        print(f"  {c['char']}: '{c.get('meaning','?')[:40]}' → '{c['basic_meaning_ko']}'")
