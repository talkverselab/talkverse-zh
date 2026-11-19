# -*- coding: utf-8 -*-
"""Grok 글 요청 한 건(PC 크롬): 새 챗 또는 기존 챗 → 첨부 → 한 줄(또는 파일) 전송 → 답이 멈출 때까지 기다림 → 마지막 답 글 저장.
grok_req.py(그림용, ~/Hanja/tools)를 글용으로 고친 것(2026-11-09). 크롬은 PC(작업 스케줄러 grok_pc_start.bat), M6 에서 ssh -fN -L 9251:127.0.0.1:9251 pc.
  GROK_CDP_PORT=9251 python3 tools/grok_text.py <보낼 글.txt | "-m 한 줄"> <답.md> [첨부 ...] [--chat <챗 주소 또는 id>] [--wait 400]
첨부는 PC D:\\grok_att\\zh\\ 로 scp 한 뒤 그 경로로 붙인다(크롬이 PC 에서 돌기 때문). 한도 문구면 종료 코드 3. 끝나면 탭을 닫는다.
마지막 줄에 `CHAT <주소>` 를 찍는다 — 같은 방에 이어 보낼 때 --chat 으로 넘긴다."""
import json, os, subprocess, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grok_cdp as G

PC_ATT = 'D:/grok_att/zh/'


def new_tab(url):
    return json.load(urllib.request.urlopen(urllib.request.Request(G.BASE + '/json/new?' + url, method='PUT')))


def close_tab(t):
    try:
        urllib.request.urlopen(G.BASE + '/json/close/' + t['id'])
    except Exception:
        pass


# 답 = 마지막 말풍선 안의 코드 블록(없으면 말풍선 글). 처음엔 「Grok」 같은 짧은 자리표시만 있으니 길이로 거른다.
REPLY = "(()=>{const m=[...document.querySelectorAll('.message-bubble')];if(!m.length)return '';const b=m[m.length-1];const p=b.querySelectorAll('pre, code');return (p.length?p[p.length-1]:b).innerText})()"


def main():
    a = sys.argv[1:]
    opt = {}
    for k in ('--chat', '--wait', '-m', '--fetch'):
        if k in a:
            i = a.index(k); opt[k] = a[i + 1]; del a[i:i + 2]
    if '--fetch' in opt:  # 이미 끝난 방에서 마지막 답만 다시 받기
        text, out, atts = None, opt['--fetch'], []
    elif '-m' in opt:
        text, out, atts = opt['-m'], a[0], a[1:]
    else:
        text, out, atts = open(a[0], encoding='utf-8').read().strip(), a[1], a[2:]
    wait = int(opt.get('--wait', 180))  # 사용자 지시 2026-11-10: Grok 답은 3분까지만
    remote = []
    if atts:
        subprocess.run(['ssh', 'pc', 'cmd /c if not exist D:\\grok_att\\zh mkdir D:\\grok_att\\zh'], check=False, capture_output=True)
        for p in atts:
            subprocess.run(['scp', '-q', p, 'pc:' + PC_ATT], check=True)
            remote.append((PC_ATT + os.path.basename(p)).replace('/', '\\'))
    chat = opt.get('--chat', '')
    url = chat if chat.startswith('http') else ('https://grok.com/c/' + chat if chat else 'https://grok.com/')
    t = new_tab(url)
    try:
        c = G.CDP(t)
        c.call('Page.bringToFront')
        for _ in range(40):
            if c.ev("!!(%s)" % G.FIND):
                break
            time.sleep(1)
        time.sleep(4)
        if remote:
            doc = c.call('DOM.getDocument', depth=-1, pierce=True)
            node = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
            if not node.get('nodeId'):
                raise SystemExit('파일 입력 없음')
            c.call('DOM.setFileInputFiles', nodeId=node['nodeId'], files=remote)
            time.sleep(4 + 2 * len(remote))
        model = c.ev("[...document.querySelectorAll('button')].map(b=>b.getAttribute('aria-label')||'').find(x=>/^모델/.test(x))||''")
        print(model)
        if text is not None and '빠른' not in model:  # 사용자 지시 2026-11-18: Grok 은 「빠른」 모드(일본어앱 전달)
            raise SystemExit('Grok 모델이 빠른이 아님: ' + model)
        if text is None:
            r = c.ev(REPLY) or ''
            open(out, 'w', encoding='utf-8').write(r + '\n'); print('저장', out, len(r), '자'); return
        r0 = c.ev(REPLY) or ''  # 보낸 직전 마지막 답(긴 방은 말풍선이 보이는 것만 그려져 개수로는 판정 불가, 2026-11-18)
        lim0 = c.ev("(document.body.innerText.match(/한도에 도달|limit reached/g)||[]).length")
        c.ev("(()=>{const e=%s;e.focus();return 1})()" % G.FIND)
        c.call('Input.insertText', text=text)
        time.sleep(1)
        for typ in ('keyDown', 'keyUp'):
            c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
        time.sleep(3)
        left = c.ev("(()=>{const e=%s;return e?(e.value||e.innerText||'').trim().length:-1})()" % G.FIND)
        if left and left > 0:
            c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(x=>/제출|보내기|Submit|Send/.test(x.getAttribute('aria-label')||''));if(b){b.click();return 1}return 0})()")
            time.sleep(3)
        t0 = time.time(); last = ''; same = 0; done = False
        while time.time() - t0 < wait:
            time.sleep(8)
            if (c.ev("(document.body.innerText.match(/한도에 도달|limit reached/g)||[]).length") or 0) > lim0:
                print('LIMIT'); sys.exit(3)
            cur = c.ev(REPLY) or ''
            busy = c.ev("/생각 중|Thinking|Generating|생성 중/.test(document.body.innerText.slice(-300))")
            if cur != r0 and len(cur) > 60 and cur == last and not busy:
                same += 1
                if same >= 2:
                    done = True
                    break
            else:
                same = 0
            last = cur
        href = c.ev('location.href')
        if not done:  # 3분 넘김 → 생성 중지(토큰 낭비 방지), 반쪽 답은 저장 안 함
            hit = c.ev("""(()=>{const b=[...document.querySelectorAll('button')].find(e=>/중지|stop/i.test((e.getAttribute('aria-label')||'')+' '+e.innerText));if(b){b.click();return 1}return 0})()""")
            if not hit:
                for typ in ('keyDown', 'keyUp'):
                    c.call('Input.dispatchKeyEvent', type=typ, key='Escape', code='Escape', windowsVirtualKeyCode=27, nativeVirtualKeyCode=27)
            time.sleep(2)
            print('TIMEOUT 3분 — 생성 중지', 'button' if hit else 'escape')
            print('CHAT', href)
            sys.exit(4)
        reply = c.ev(REPLY) or ''
        stem = os.path.basename(out).rsplit('.', 1)[0]
        if reply and '=== ' in reply and ('=== ' + stem) not in reply:  # 앞 편 답을 잘못 집음(2026-11-10 r1_life_a3)
            print('MISMATCH 답의 편 id 가 다름 — 저장 안 함'); print('CHAT', href); sys.exit(5)
        open(out, 'w', encoding='utf-8').write(reply + '\n')
        print('저장', out, len(reply), '자')
        print('CHAT', href)
        if not reply:
            sys.exit(2)
    finally:
        close_tab(t)


if __name__ == '__main__':
    main()
