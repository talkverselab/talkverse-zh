#!/usr/bin/env python3
"""편 JSON 의 감정 열(`emotion`·`segs`) → 감정 계획 `data/tts/plan/<편id>.json` 자동 생성(2026-11-07 사용자 지시 "음성 만들 때 본 감정을 고려하도록").

  python3 tools/tts/plan_from_episode.py [편id...]   (없으면 감정 열이 있는 편 전부; --force 로 이미 있는 계획도 덮어씀)

턴 규칙: `segs`([감정, 본문] 또는 [감정, 본문, 읽기])가 있으면 그대로, 없고 `emotion` 만 있으면 [[emotion, zh]]. 둘 다 없는 턴이 있으면 그 편은 만들지 않고 알린다.
판별 본문: 턴에 `m`/`f`({text,reading,rd,ko,segs}) 가 있으면 그대로 옮긴다. cast: speakers 이름 → voices.json `names`(小丽=xiaoli …), 없으면 성별로 man_y/woman_y(검토 필요 표시).
감정 값은 PLAN_GUIDE.md 의 16개. 손으로 쓴 계획이 있으면 --force 없이는 건드리지 않는다(ttslib 은 계획이 없을 때 이 함수를 자동으로 부른다).
"""
import json, os, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EMO = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
NAMES = {'小丽': 'xiaoli', '浩然': 'haoran', '悦': 'yue', '大叔': 'dashu', '房东': 'fangdong', '阿姨': 'ayi', '店员': 'dianyuan', '服务员': 'fuwuyuan',
         '外卖小哥': 'xiaoge', '小哥': 'xiaoge', '司机': 'siji', '老板': 'laoban', '妈妈': 'mom', '妈': 'mom', '广播': 'announce', '机器': 'robot'}

def build(path):
    """편 JSON 경로 → (계획 dict, 문제 목록). 문제가 있으면 계획은 None."""
    d = json.load(open(path, encoding='utf-8')); probs = []
    try:
        V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8')); names = {**NAMES, **(V.get('names') or {})}
    except Exception:
        names = NAMES
    cast = {}
    for sp, nm in (d.get('speakers') or {}).items():
        if sp == 'A': continue
        nm = nm.replace('{', '').replace('}', '')
        v = names.get(nm)
        if v is None:
            v = 'man_y' if sp == 'C' else 'woman_y'; probs.append(f'{sp}={nm} 목소리 미정 → {v}(검토)')
        cast[sp] = v
    turns = {}
    for t in d['turns']:
        T = {}
        segs = t.get('segs')
        if segs:
            T['segs'] = [list(s) for s in segs]
        elif t.get('emotion'):
            T['segs'] = [[t['emotion'], t['zh']]]
        else:
            probs.append(f"턴 {t['num']} 감정 없음"); continue
        for s in T['segs']:
            if s[0] not in EMO: probs.append(f"턴 {t['num']} 감정 값 모름: {s[0]}")
        for g in 'mf':
            if isinstance(t.get(g), dict): T[g] = t[g]
        turns[str(t['num'])] = T
    if any('감정 없음' in p or '모름' in p for p in probs):
        return None, probs
    return {'ep': d['id'], 'cast': cast, 'turns': turns}, probs

def main():
    import glob
    force = '--force' in sys.argv; ids = [a for a in sys.argv[1:] if not a.startswith('--')]
    EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json')}
    if not ids:
        ids = [e for e, p in EP.items() if any(t.get('emotion') or t.get('segs') for t in json.load(open(p, encoding='utf-8'))['turns'])]
    made = 0
    for ep in sorted(ids):
        out = f'{R}/data/tts/plan/{ep}.json'
        if os.path.exists(out) and not force:
            print(f'{ep}: 계획 있음(건너뜀, --force 로 덮어씀)'); continue
        plan, probs = build(EP[ep])
        for p in probs: print(f'{ep}: {p}')
        if plan is None: continue
        os.makedirs(os.path.dirname(out), exist_ok=True)
        json.dump(plan, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1); made += 1
        print(f'{ep}: 계획 생성 — 턴 {len(plan["turns"])} · cast {plan["cast"]}')
    print(f'생성 {made} / 대상 {len(ids)}')

if __name__ == '__main__':
    main()
