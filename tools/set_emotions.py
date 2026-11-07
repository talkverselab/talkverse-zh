#!/usr/bin/env python3
"""편의 턴마다 음성용 감정을 넣는다(2026-11-07).  python3 tools/set_emotions.py <편id> <턴1감정> <턴2감정> ...
감정 = 16개 중 하나(neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle),
한 턴에서 바뀌면 `surprised:啊？真的？|gentle:那一起去吧。`(이어 붙이면 zh 와 같아야 함, 이모지·공백 무시). 턴 수가 맞지 않으면 아무것도 바꾸지 않는다.
끝나면 어조사 이모지를 감정에 맞춰 다시 붙이고(add_particle_emoji --redo) 음성 계획을 만든다(plan_from_episode --force)."""
import glob, json, re, subprocess, sys
R = __file__.rsplit('/tools/', 1)[0]
EMO = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
STRIP = re.compile(r'[\U0001F300-\U0001FAFF☀-➿\U0001F000-\U0001F2FF\s]')
ep, specs = sys.argv[1], sys.argv[2:]
p = glob.glob(f'{R}/assets/data/dialogues/R*/*/{ep}.json')[0]
e = json.load(open(p, encoding='utf-8'))
if len(specs) != len(e['turns']):
    sys.exit(f'{ep}: 턴 {len(e["turns"])}개인데 감정 {len(specs)}개')
for t, sp in zip(e['turns'], specs):
    if ':' in sp or '|' in sp:
        segs = [[x.split(':', 1)[0].strip(), x.split(':', 1)[1].strip()] for x in sp.split('|') if ':' in x]
        if STRIP.sub('', ''.join(s[1] for s in segs)) != STRIP.sub('', t['zh']):
            sys.exit(f"{ep} #{t['num']}: segs 이어 붙인 것 ≠ zh\n  {''.join(s[1] for s in segs)}\n  {t['zh']}")
        bad = [s[0] for s in segs if s[0] not in EMO]
        if bad: sys.exit(f"{ep} #{t['num']}: 감정 값 모름 {bad}")
        t['emotion'] = segs[0][0]; t['segs'] = segs
    else:
        if sp not in EMO: sys.exit(f"{ep} #{t['num']}: 감정 값 모름 {sp}")
        t['emotion'] = sp; t.pop('segs', None)
if all(t.get('emotion') == 'neutral' for t in e['turns']): sys.exit(f'{ep}: 전부 neutral — 다시')
with open(p, 'w', encoding='utf-8') as f: json.dump(e, f, ensure_ascii=False, indent=1); f.write('\n')
subprocess.run([sys.executable, f'{R}/tools/add_particle_emoji.py', '--redo', p], check=True, capture_output=True)
r = subprocess.run([sys.executable, f'{R}/tools/tts/plan_from_episode.py', '--force', ep], capture_output=True, text=True)
print(f'{ep}: 감정 {len(specs)}턴 반영 · ' + (r.stdout.strip().splitlines()[-1] if r.stdout else r.stderr.strip()[-200:]))
