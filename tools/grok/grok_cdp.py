# -*- coding: utf-8 -*-
"""맥미니 전용 Chrome(원격 디버깅 127.0.0.1:9222, 프로필 ~/chrome-grok)으로 Grok 챗에 프롬프트를 보낸다.
사용자 지시 2026-10-19: [A..] 프롬프트 → Grok '어른' 챗, [K..] 프롬프트 → '어린이' 챗.

  /usr/bin/python3 tools/grok_cdp.py tabs                 # 열린 탭
  /usr/bin/python3 tools/grok_cdp.py eval "<js>" [url조각]  # 탭에서 JS 실행
  /usr/bin/python3 tools/grok_cdp.py send <파일> <url조각> [--dry]   # 입력창에 넣고 전송
  /usr/bin/python3 tools/grok_cdp.py read <url조각> [n]     # 마지막 응답 n자
Chrome 띄우기: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9222 \
  --remote-debugging-address=127.0.0.1 --user-data-dir=$HOME/chrome-grok --no-first-run https://grok.com
"""
import json, os, sys, time, urllib.request
import websocket

# 2026-11-03 사용자 지시: Grok·Gemini 요청은 M4 Chrome 에서 — M6 에서는 ssh -L 9333:127.0.0.1:9222 macmini4 로 터널, GROK_CDP_PORT=9333
PORT = os.environ.get('GROK_CDP_PORT', '9222')
BASE = 'http://127.0.0.1:' + PORT


def tabs():
    return [t for t in json.load(urllib.request.urlopen(BASE + '/json/list')) if t['type'] == 'page']


def tab(frag):
    for t in tabs():
        if frag in t['url'] or frag in t['title']:
            return t
    raise SystemExit('탭 없음: %s' % frag)


class CDP:
    def __init__(self, t):
        self.ws = websocket.create_connection(t['webSocketDebuggerUrl'].replace(':9222/', ':' + PORT + '/'), timeout=60, suppress_origin=True); self.i = 0

    def call(self, method, **params):
        self.i += 1; self.ws.send(json.dumps({'id': self.i, 'method': method, 'params': params}))
        while True:
            m = json.loads(self.ws.recv())
            if m.get('id') == self.i:
                return m.get('result', m)

    def ev(self, js):
        r = self.call('Runtime.evaluate', expression=js, returnByValue=True, awaitPromise=True)
        return r.get('result', {}).get('value', r)


FIND = r"""(()=>{const c=[...document.querySelectorAll('[contenteditable="true"].ProseMirror,[contenteditable="true"],textarea')].filter(e=>e.offsetParent);return c.length?c[0]:null})()"""


def send(path, frag, dry=False):
    text = open(path, encoding='utf-8').read().strip()
    c = CDP(tab(frag))
    c.call('Page.bringToFront')
    ok = c.ev("(()=>{const e=%s;if(!e)return 'no input';e.focus();return e.tagName})()" % FIND)
    if ok == 'no input':
        raise SystemExit('입력창 없음')
    c.call('Input.insertText', text=text)
    time.sleep(1)
    got = c.ev("(()=>{const e=%s;return (e.value||e.innerText||'').trim().length})()" % FIND)
    print('입력창', ok, '글자수', got, '/', len(text))
    if dry:
        return
    for typ in ('keyDown', 'keyUp'):
        c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
    time.sleep(2)
    left = c.ev("(()=>{const e=%s;return e?(e.value||e.innerText||'').trim().length:-1})()" % FIND)
    if left and left > 0:  # 새 프로젝트 첫 메시지는 Enter 로 안 보내질 때가 있음 → '제출' 버튼 클릭(2026-11-02)
        c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(x=>((x.getAttribute('aria-label')||x.innerText||'').trim())==='제출');if(b){b.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true}));b.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));b.click();return 1}return 0})()")
        time.sleep(2)
        left = c.ev("(()=>{const e=%s;return e?(e.value||e.innerText||'').trim().length:-1})()" % FIND)
    print('전송 뒤 입력창 글자수', left, '(0 이면 전송됨)')


def read(frag, n=1500):
    c = CDP(tab(frag))
    print(c.ev("document.body.innerText.slice(-%d)" % n))


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'tabs':
        for t in tabs(): print(t['url'], '|', t['title'])
    elif a[0] == 'eval':
        print(CDP(tab(a[2] if len(a) > 2 else 'grok.com')).ev(a[1]))
    elif a[0] == 'send':
        send(a[1], a[2], '--dry' in a)
    elif a[0] == 'read':
        read(a[1], int(a[2]) if len(a) > 2 else 1500)


def click(c, js_el):
    """js_el: 요소를 돌려주는 JS 식. 화면 좌표로 실제 마우스 클릭(Radix 메뉴용)."""
    r = c.ev("(()=>{const e=%s;if(!e)return null;e.scrollIntoView({block:'center'});const b=e.getBoundingClientRect();return [b.x+b.width/2,b.y+b.height/2]})()" % js_el)
    if not r:
        return False
    x, y = r
    c.call('Input.dispatchMouseEvent', type='mouseMoved', x=x, y=y)
    for t in ('mousePressed', 'mouseReleased'):
        c.call('Input.dispatchMouseEvent', type=t, x=x, y=y, button='left', clickCount=1)
    return True
