#!/usr/bin/env python3
"""성조연습 자료 → assets/data/tone_drill.json. 2026-11-11 사용자 지시(uk 전달): 「두 낱말만 놓고 반복 → 세 낱말 → 네 낱말」「그다음엔 문장」
  묶음 50개 = 2글자 낱말 4개(성조 칸이 서로 다르게, 기본 10묶음 틀을 5번 — 칸마다 낱말 10개; 11/11 사용자 「연습량이 훨씬 많아야」) + 문장 1줄. 앞 묶음은 뚜렷이 다른 칸, 뒤로 갈수록 헷갈리는 짝·변조·경성.
  ~/.venvs/tts_zh/bin/python tools/build_tone_drill.py
- 낱말: HSK 1~5급 단어 중 글자별 성조(pypinyin, 낱말 문맥)를 뽑아 단어장 rd 와 **병음 철자·성조 둘 다** 맞는 것만. 一·儿·다른 문자 든 낱말은 뺀다
  (一 변조는 채점 모듈이 안 하므로). 不 는 사전 성조(4)로 두면 모듈이 不+4성→2성을 처리한다.
- 2글자: 칸(앞 성조 1~4 × 뒤 성조 1~4·경성 0)마다 쉬운 급부터 10개. 3·4글자: 쉬운 급부터.
- 문장: R1 회화에서 4~10글자 턴 중 음성 조각이 하나(학습자 성별 무관 `_c`)인 것 — 그 wav 에서 기준 곡선(talkverse_pitch:contour 50)을 뽑는다."""
import glob, json, os, re, subprocess, unicodedata
from pypinyin import pinyin, Style

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WAV = os.path.expanduser('~/tts_work/zh/all/wav')
PITCH = os.path.join(ROOT, 'packages', 'talkverse_pitch')
HAN = re.compile(r'^[一-鿿]+$')
MARK = {'̄': 1, '́': 2, '̌': 3, '̀': 4}


def rd_info(rd):
    """rd(성조 표시 병음) → (표시 없는 글자, 표시된 성조 순서)."""
    d = unicodedata.normalize('NFD', rd.lower())
    tones = [MARK[c] for c in d if c in MARK]
    plain = ''.join(c for c in d if c.isalpha() and c not in MARK).replace('ü', 'v')
    plain = unicodedata.normalize('NFC', plain).replace('ü', 'v')
    return re.sub(r'[^a-z]', '', plain.replace('̈', '')), tones


def char_tones(word):
    syl = [s[0] for s in pinyin(word, style=Style.TONE3, neutral_tone_with_five=True, heteronym=False)]
    tones, letters = [], ''
    for s in syl:
        m = re.match(r'^([a-zü]+)([1-5])$', s.replace('v', 'ü'))
        if not m: return None
        letters += m.group(1).replace('ü', 'v'); t = int(m.group(2)); tones.append(0 if t == 5 else t)
    return letters, tones


def words():
    d = json.load(open(f'{ROOT}/assets/data/vocab/hsk_words.json', encoding='utf-8'))
    seen, out, drop = set(), [], 0
    for th in d['themes']:
        lv = int(th['id'][3:]) if th['id'].startswith('hsk') and th['id'][3:].isdigit() else 9
        for sec in th['sections']:
            for w in sec['words']:
                zh = w['zh']
                if zh in seen or not HAN.match(zh) or not 2 <= len(zh) <= 4 or '一' in zh or zh.endswith('儿'): continue
                seen.add(zh)
                ct = char_tones(zh)
                if not ct: drop += 1; continue
                letters, tones = ct; plain, marks = rd_info(w['rd'])
                if letters != plain or [t for t in tones if t] != marks or tones[0] == 0:
                    drop += 1; continue
                out.append({'zh': zh, 'rd': w['rd'], 'ko': w['ko'], 't': tones, 'lv': lv})
    return out, drop


def contour(wav):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', wav, '-f', 's16le', '-ar', '16000', '-ac', '1', '-'], capture_output=True).stdout
    r = subprocess.run(['dart', 'run', 'talkverse_pitch:contour', '50'], input=raw, capture_output=True, cwd=PITCH)
    s = r.stdout.decode().strip().splitlines()[-1] if r.stdout else 'null'
    return json.loads(s)


ROUNDS = [  # (앞 두 칸 = 처음에 번갈아 낼 뚜렷한 짝)
    ['1-1', '4-4', '2-2', '1-4'], ['4-1', '2-4', '1-2', '4-2'], ['2-1', '3-1', '3-4', '4-3'], ['1-3', '2-3', '3-2', '3-3'], ['1-0', '4-0', '2-0', '3-0'],
    ['1-1', '2-2', '2-3', '3-2'], ['4-4', '3-3', '2-1', '3-0'], ['1-2', '2-4', '4-2', '1-0'], ['1-3', '3-1', '4-3', '3-4'], ['1-4', '4-1', '2-0', '4-0'],
] * 5


def candidates():
    """R1 회화에서 4~12글자 턴 중 음성 조각이 하나(_c)인 줄."""
    out = []
    for p in sorted(glob.glob(f'{ROOT}/assets/data/dialogues/R1/*/*.json')):
        e = json.load(open(p, encoding='utf-8')); ep = e['id']
        for t in e['turns']:
            zh = t['zh']; h = re.sub(r'[^\u4e00-\u9fff]', '', zh)
            if '{name}' in zh or re.search(r'[0-9A-Za-z０-９]', zh) or not 4 <= len(h) <= 12: continue
            segs = glob.glob(f'{WAV}/{ep}/{t["num"]:02d}_*.wav')
            if len(segs) != 1 or not segs[0].endswith('_0_c.wav'): continue
            out.append({'ep': ep, 'turn': t['num'], 'zh': zh, 'h': h, 'pinyin': t.get('pinyin', ''), 'ko': t['ko'], 'wav': segs[0]})
    return out


def pick_sentence(words, cellwords, cands, used):
    """그 묶음 낱말이 든 줄 → 같은 칸 낱말이 든 줄 → 아무 줄(짧은 것부터)."""
    for pool in ([w['zh'] for w in words], [w['zh'] for c in cellwords for w in c]):
        for c in sorted(cands, key=lambda c: len(c['h'])):
            if (c['ep'], c['turn']) in used: continue
            if any(z in c['h'] for z in pool):
                r = contour(c['wav'])
                if r and r['dur'] >= 0.5: return c, r
    for c in sorted(cands, key=lambda c: len(c['h'])):
        if (c['ep'], c['turn']) not in used:
            r = contour(c['wav'])
            if r and r['dur'] >= 0.5: return c, r


ORDER = [f'{a}-{b}' for a in (1, 2, 3, 4) for b in (1, 2, 3, 4, 0)]   # 메뉴 = 성조 조합(11/11 사용자 「1성 1성 / 1성 2성 / 이렇게 메뉴를 구성해」)
PER = 12   # 조합마다 낱말 12개 = 묶음 3개(낱말 4 + 문장)


def main():
    ws, drop = words()
    cands = candidates(); text = ''.join(c['h'] for c in cands)
    cells = {}
    for w in sorted([w for w in ws if len(w['zh']) == 2], key=lambda w: (w['zh'] not in text, w['lv'])):   # 회화에 나오는 낱말 먼저, 쉬운 급부터
        cells.setdefault(f"{w['t'][0]}-{w['t'][1]}", []).append({**w, 'cell': f"{w['t'][0]}-{w['t'][1]}"})
    used, combos = set(), []
    for k in ORDER:
        ws_ = cells[k][:PER]; rounds = []
        for j in range(0, len(ws_) - 3, 4):
            g = ws_[j:j + 4]
            c, r = pick_sentence(g, [cells[k]], cands, used); used.add((c['ep'], c['turn']))
            rounds.append({'words': g, 'sentence': {'ep': c['ep'], 'turn': c['turn'], 'zh': c['zh'], 'pinyin': c['pinyin'], 'ko': c['ko'], 'ref': r}})
        combos.append({'cell': k, 'rounds': rounds})
    out = {'_meta': '성조연습 자료 — tools/build_tone_drill.py 가 만든다(손으로 고치지 말 것)', 'combos': combos}
    json.dump(out, open(f'{ROOT}/assets/data/tone_drill.json', 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    print('낱말 통과', len(ws), '뺌', drop, '| 문장 후보', len(cands))
    for cb in combos:
        print(cb['cell'], ' / '.join(' '.join(w['zh'] for w in r['words']) + ' | ' + r['sentence']['zh'] for r in cb['rounds']))


if __name__ == '__main__':
    main()
