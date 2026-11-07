#!/usr/bin/env python3
"""문장 끝 어조사(吧·呢·啊·吗·呀·哦·啦·嘛…)로 감정을 내는 턴에 감정 열과 어울리는 이모지를 붙인다(2026-11-07 사용자 지시, 한·중·일·태·베 공통).

  python3 tools/add_particle_emoji.py <편.json>...   (--dry 로 바꿀 줄만 출력)

- 어조사가 있는 턴만, 이미 이모지가 있으면 그대로. 이모지는 `zh` 끝(문장부호 뒤)에 붙는다. 감정(`emotion`, segs 면 마지막 조각)에 맞춘 표.
- 음성은 이모지를 읽지 않는다 — tools/tts/ttslib(읽기 조각)·앱 TtsService 가 이모지를 뺀다. check_dialogues 의 segs↔zh 비교도 이모지를 무시.
"""
import json, re, sys
PART = re.compile(r'[吧呢啊吗呀哦啦嘛嘞哈呗咯喽哟呐哇诶嘿嗯]\s*[。！？!?~…]*\s*$')
EMOJI = re.compile(r'[\U0001F300-\U0001FAFF☀-➿\U0001F000-\U0001F2FF]')
BY_EMO = {'neutral': '🙂', 'polite': '🙏', 'stiff': '😐', 'cheerful': '😄', 'amused': '😏', 'teasing': '😜', 'excited': '🤩', 'surprised': '😮',
          'shout': '😤', 'tsukkomi': '🙄', 'annoyed': '😒', 'sad': '😢', 'worried': '😟', 'flustered': '😳', 'shy': '😊', 'gentle': '🥰'}
# 중립일 때만 어조사별로: 물음(吗·呢) 🤔 · 권유(吧) 😉 · 감탄(啊·呀·哇) 😮 · 아쉬움(嘛·哦) 😅
BY_PART = {'吗': '🤔', '呢': '🤔', '吧': '😉', '啊': '😮', '呀': '😮', '哇': '😮', '嘛': '😅', '哦': '😅'}

def pick(zh, emotion):
    m = PART.search(zh)
    if not m or EMOJI.search(zh): return None
    emo = emotion or 'neutral'
    if emo == 'neutral':
        return BY_PART.get(m.group(0).strip()[0], BY_EMO['neutral'])
    return BY_EMO.get(emo, '🙂')

def apply(path, dry=False):
    e = json.load(open(path, encoding='utf-8')); n = 0
    for t in e['turns']:
        emo = (t.get('segs') or [[t.get('emotion')]])[-1][0]
        em = pick(t['zh'], emo)
        if not em: continue
        t['zh'] = t['zh'].rstrip() + em; n += 1
        if dry: print(f"{e['id']} #{t['num']} [{emo}] {t['zh']}")
    if n and not dry:
        with open(path, 'w', encoding='utf-8') as f: json.dump(e, f, ensure_ascii=False, indent=1); f.write('\n')
    return n

if __name__ == '__main__':
    dry = '--dry' in sys.argv
    tot = sum(apply(p, dry) for p in sys.argv[1:] if not p.startswith('--'))
    print(f'이모지 {"후보" if dry else "추가"} {tot}턴')
