"""옛 L1~L4 회화(north, 8턴 129편)를 회화 공통 원칙의 R 레벨·주제 구조로 옮긴다 (2026-11-02).

문장은 바꾸지 않는다 — 모양만 일본어앱 형식으로(목표어 `zh`, 읽기 `pinyin`; 한글 독음 `rd` 는 앱이 병음에서 만든다).
레벨 = 편의 단어(빈도표 2,500 안, 최장일치 분절) 90% 를 덮는 가장 낮은 구간(assets/data/freq/lang_zh_with_regions.csv).
  옛 회화는 HSK 기준으로 썼기 때문에 대부분 R3·R4 로 나온다 — R0·R1 은 새 회화로 채운다.
R0 = R1 중 턴당 평균 한자 수가 짧은 편(≤ 6자).

  python3 tool/convert_dialogues_r.py      → assets/data/dialogues/R<n>/<주제>/<id>.json
"""
import csv, json, re, shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets/data/dialogues/north'
OUT = ROOT / 'assets/data/dialogues'
REG = {r['word']: r['region'] for r in csv.DictReader(open(ROOT / 'assets/data/freq/lang_zh_with_regions.csv', encoding='utf-8-sig'))}
MAXW = max(map(len, REG))
ORDER = ['R1', 'R2', 'R3', 'R4']
HAN = re.compile(r'[一-鿿]')

# 옛 레벨 → 주제·종류
LEVEL_MAP = {'L1': ('love', 'long'), 'L2': ('life', 'chat'), 'L3': ('love', 'long'), 'L4': ('love', 'short')}


def segment(s):
    out, i = [], 0
    while i < len(s):
        for n in range(min(MAXW, len(s) - i), 0, -1):
            w = s[i:i + n]
            if w in REG:
                out.append(w); i += n; break
        else:
            i += 1
    return out


def region_of(turns, cover=0.9):
    toks = [w for t in turns for w in segment(t['zh'])]
    if not toks:
        return 'R1'
    cum = 0
    for r in ORDER:
        cum += sum(1 for w in toks if REG[w] == r)
        if cum / len(toks) >= cover:
            return r
    return 'R4'


def main():
    for d in ['R0', 'R1', 'R2', 'R3', 'R4']:
        shutil.rmtree(OUT / d, ignore_errors=True)
    count = {}
    for lv, (island, kind) in LEVEL_MAP.items():
        j = json.load(open(SRC / f'{lv}.json', encoding='utf-8'))
        eps = j.get('episodes') or j.get('dialogues')
        for e in eps:
            turns = e['turns']
            region = region_of(turns)
            avg = sum(len(HAN.findall(t['zh'])) for t in turns) / max(1, len(turns))
            if region == 'R1' and avg <= 6:
                region = 'R0'
            eid = f"{region.lower()}_{island}_{lv.lower()}_{e['id']}"
            # 화자: A = 학습자(Mark), B = 샤오리 — L4(플러팅)의 B 는 먼저 다가가는 여성 위에(悦). 인물 기준 그림 data/review/art/chars_zh01.jpg
            speakers = {'A': 'Mark', 'B': '悦' if lv == 'L4' else '小丽'}
            doc = {
                'id': eid, 'region': region, 'island': island, 'kind': kind,
                'title': e['title'], 'emoji': e.get('emoji', '💬'), 'scene': e.get('scenario', ''),
                'speakers': speakers, 'register': 'casual', 'twist': 0,
                'learner_gender': 'M', 'variant': 'north', 'legacy': f"{lv}/{e['id']}",
                'turns': [{'num': t['num'], 'speaker': t['speaker'], 'zh': t['zh'], 'pinyin': t.get('pinyin', ''),
                           'ko': t.get('ko', ''), 'note': t.get('note', ''), 'tags': t.get('tags', [])} for t in turns],
            }
            p = OUT / region / island / f'{eid}.json'
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(json.dumps(doc, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
            count[(region, island)] = count.get((region, island), 0) + 1
    for k in sorted(count):
        print(*k, count[k])


if __name__ == '__main__':
    main()
