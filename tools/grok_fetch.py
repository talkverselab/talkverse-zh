#!/usr/bin/python3
"""Grok 프로젝트 챗의 마지막 답을 그대로 저장(이미 끝난 답 다시 받기).  grok_fetch.py <url조각> <저장파일> [n=-1]
이미지 생성이 포함된 답은 grok_send 가 생성 중간에 저장할 수 있어, 끝난 뒤 이 스크립트로 다시 받는다. 이미지 주소도 뒤에 붙인다."""
import sys
import os
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9227')  # 중국어앱 전용 Chrome — M4 의 ~/chrome-grok-zh(9227), M6 에서는 ssh 터널로(2026-11-03)
frag, dst = sys.argv[1], sys.argv[2]
n = int(sys.argv[3]) if len(sys.argv) > 3 else -1
c = g.CDP(g.tab(frag))
busy = c.ev("document.body.innerText.includes('작업 중') || document.body.innerText.includes('이미지 생성 중') || !![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
els = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>e.innerText)")
imgs = c.ev("[...document.querySelectorAll('.response-content-markdown')].map(e=>[...e.querySelectorAll('img')].map(i=>i.src))")
if not els: print('EMPTY'); sys.exit(1)
txt = els[n]
if imgs and imgs[n]: txt += '\n\n[images]\n' + '\n'.join(imgs[n])
open(dst, 'w', encoding='utf-8').write(txt)
print('BUSY' if busy else 'OK', len(txt), len(imgs[n]) if imgs else 0)
