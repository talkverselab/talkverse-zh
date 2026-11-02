#!/usr/bin/python3
"""Grok 에 그림 여러 장(최대 4)을 한 요청으로 받는다 — 일본어앱 확인(2026-11-02 밤): 한 메시지 최대 4장.
  /usr/bin/python3 tools/grok_images.py <요청문.md> <저장 접두어> <장수> [--tab 1b47fbcb] [--attach a.jpg,b.jpg] [--wait 600]
저장: <접두어>1.jpg … <접두어>N.jpg (답에 나타난 순서 = 요청문의 컷 순서). 마지막 줄: OK <받은 수> | PARTIAL <받은 수> | TIMEOUT
"""
import base64, os, subprocess, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9227')
a = sys.argv[1:]; src, pre, want = a[0], a[1], int(a[2])
frag = a[a.index('--tab') + 1] if '--tab' in a else '1b47fbcb'
wait = int(a[a.index('--wait') + 1]) if '--wait' in a else 600
here = os.path.dirname(os.path.abspath(__file__))
GEN = "[...document.querySelectorAll('img')].filter(i=>i.src.includes('/generated/')&&i.complete&&i.naturalWidth>0).map(i=>i.src)"
before = set(g.CDP(g.tab(frag)).ev(GEN) or [])
cmd = ['/usr/bin/python3', f'{here}/grok_send.py', src, pre + '.md', '--tab', frag, '--wait', '45']
if '--attach' in a: cmd += ['--attach', a[a.index('--attach') + 1]]
subprocess.run(cmd, capture_output=True, text=True)
t0 = time.time(); got = []
def save(urls):
    c = g.CDP(g.tab(frag))
    for k, u in enumerate(urls, 1):
        r = c.call('Runtime.evaluate', expression=f"fetch('{u}',{{credentials:'include'}}).then(r=>r.blob()).then(b=>new Promise(res=>{{const f=new FileReader();f.onload=()=>res(f.result);f.readAsDataURL(b)}}))", awaitPromise=True, returnByValue=True)
        open(f'{pre}{k}.jpg', 'wb').write(base64.b64decode(r['result']['value'].split(',', 1)[1]))
    open(pre + '.md', 'w', encoding='utf-8').write('[images]\n' + '\n'.join(urls) + '\n')
while time.time() - t0 < wait:
    c = g.CDP(g.tab(frag))
    busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    new = [u for u in (c.ev(GEN) or []) if u not in before]
    if len(new) >= want and not busy:
        save(new[:want]); print('OK', want); sys.exit(0)
    if new and not busy and time.time() - t0 > 150:  # 다 안 왔는데 끝남 → 있는 만큼 저장
        save(new); print('PARTIAL', len(new)); sys.exit(2)
    time.sleep(8)
print('TIMEOUT'); sys.exit(1)
