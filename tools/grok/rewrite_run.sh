#!/bin/bash
# 사용: tools/grok/rewrite_run.sh <편id>...  (M4 Chrome 9227 터널 필요, 요청문 = data/review/<id>_grok_rewrite_prompt.md)
# Grok(전문가) 재작성 — 편마다 새 대화방(답 순서 꼬임 방지), 끝난 탭은 닫는다
cd ~/talkverse/zh
for id in "$@"; do
  curl -s -m 5 http://127.0.0.1:9227/json/version >/dev/null || ssh -fN -o ExitOnForwardFailure=yes -L 9227:127.0.0.1:9227 macmini4
  [ -s data/review/${id}_grok_rewrite.md ] && grep -q '^1 [AB]' data/review/${id}_grok_rewrite.md && continue
  TID=$(curl -s -X PUT "http://127.0.0.1:9227/json/new?https://grok.com/" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])"); sleep 8
  GROK_CDP_PORT=9227 /usr/bin/python3 tools/grok_send.py data/review/${id}_grok_rewrite_prompt.md data/review/${id}_grok_rewrite.md --tab grok.com/ --wait 400 >/dev/null 2>&1
  sleep 30
  cid=$(curl -s http://127.0.0.1:9227/json/list | python3 -c "import json,sys,re;l=[t for t in json.load(sys.stdin) if t['id']=='$TID'];m=re.search(r'/c/([0-9a-f-]{8})',l[0]['url']) if l else None;print(m.group(1) if m else '')")
  [ -n "$cid" ] && GROK_CDP_PORT=9227 /usr/bin/python3 tools/grok_fetch.py $cid data/review/${id}_grok_rewrite.md 1 >/dev/null 2>&1
  echo "$id $(grep -c '^[0-9]* [AB]:' data/review/${id}_grok_rewrite.md)줄"
  curl -s "http://127.0.0.1:9227/json/close/$TID" >/dev/null
done
