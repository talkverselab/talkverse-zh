#!/usr/bin/python3
"""Grok 에 그림 1장 요청 → 생성이 끝날 때까지 기다려 jpg 로 저장(로그인된 전용 Chrome 안에서 받아 옴).
  /usr/bin/python3 tools/grok_image.py <요청문.md> <저장.jpg> [--tab 1b47fbcb] [--attach a.jpg,b.jpg] [--wait 600]
출력 마지막 줄: OK <저장.jpg> <답 글자 수> | NOIMAGE | TIMEOUT
"""
import base64, os, subprocess, sys, time
sys.path.insert(0, '/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE = 'http://127.0.0.1:' + os.environ.get('GROK_CDP_PORT', '9227')
a = sys.argv[1:]; src, dst = a[0], a[1]
frag = a[a.index('--tab') + 1] if '--tab' in a else '1b47fbcb'
wait = int(a[a.index('--wait') + 1]) if '--wait' in a else 600
here = os.path.dirname(os.path.abspath(__file__))
GEN = "[...document.querySelectorAll('img')].filter(i=>i.src.includes('/generated/')&&i.complete&&i.naturalWidth>0).map(i=>i.src)"
before = set(g.CDP(g.tab(frag)).ev(GEN) or [])  # 보내기 전에 이미 있던 생성 이미지 — 새로 나타난 것만 받는다(같은 탭을 여러 작업이 써도 안전)
cmd = ['/usr/bin/python3', f'{here}/grok_send.py', src, dst + '.md', '--tab', frag, '--wait', '45']
if '--attach' in a: cmd += ['--attach', a[a.index('--attach') + 1]]
subprocess.run(cmd, capture_output=True, text=True)
t0 = time.time()
while time.time() - t0 < wait:
    c = g.CDP(g.tab(frag))
    busy = c.ev("!![...document.querySelectorAll('button')].find(e=>(e.getAttribute('aria-label')||'')==='응답 중지')")
    new = [u for u in (c.ev(GEN) or []) if u not in before]
    if new and not busy:
        u = new[-1]
        r = c.call('Runtime.evaluate', expression=f"fetch('{u}',{{credentials:'include'}}).then(r=>r.blob()).then(b=>new Promise(res=>{{const f=new FileReader();f.onload=()=>res(f.result);f.readAsDataURL(b)}}))", awaitPromise=True, returnByValue=True)
        open(dst, 'wb').write(base64.b64decode(r['result']['value'].split(',', 1)[1]))
        open(dst + '.md', 'w', encoding='utf-8').write('[images]\n' + u + '\n')
        print('OK', dst, u[-50:]); sys.exit(0)
    time.sleep(8)
print('TIMEOUT'); sys.exit(1)
