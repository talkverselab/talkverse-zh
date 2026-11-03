#!/usr/bin/env python3
"""편 JSON → Grok 재작성 요청문(tools/prompts/rewrite_grok.md 틀).  python3 tools/rewrite_request.py <편.json> → data/review/<편id>_grok_rewrite_prompt.md"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
tpl = re.search(r'```\n(.*?)```', (ROOT / 'tools/prompts/rewrite_grok.md').read_text(encoding='utf-8'), re.S).group(1)
REG = {'casual': '친구·연인 사이 반말', 'chat': '채팅(반말·줄임말·이모지)', 'polite': '처음 보는 사이·가게(존댓말)', 'mixed': '처음엔 존댓말, 가까워지며 반말'}
for p in sys.argv[1:]:
    e = json.load(open(p, encoding='utf-8'))
    roles = ' / '.join(f"{k} = {'학습자(한국인 20대, 이름 {name})' if v == '{name}' else v}" for k, v in e['speakers'].items())
    lines = '\n'.join(f"{t['num']} {t['speaker']}: {t['zh']} / {t['pinyin']} / {t['ko']}" for t in e['turns'])
    txt = (tpl.replace('{code}', f"ZR-{e['id']}").replace('{roles}', roles).replace('{scene}', e['scene'])
           .replace('{register}', REG.get(e.get('register'), e.get('register', ''))).replace('{twist}', str(e.get('twist')))
           .replace('{n}', str(len(e['turns']))).replace('{lines}', lines).replace('{{name}}', '{name}'))
    out = ROOT / f"data/review/{e['id']}_grok_rewrite_prompt.md"
    out.write_text(txt, encoding='utf-8'); print(out)
