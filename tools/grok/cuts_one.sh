#!/bin/bash
# 사용: tools/grok/cuts_one.sh <편id>...  (조연이 있으면 data/review/art/<id>/attach.txt 의 조연 시트를 더 첨부)
# 편마다 새 대화방 하나, 컷은 한 장씩(전문가 모델은 한 메시지에 그림 1~2장만)
cd ~/talkverse/zh
ATT=/Users/talkverse/talkverse/zh/data/review/art/chars_zh01.jpg,/Users/talkverse/talkverse/zh/data/review/uxui/sian_zh05_1.jpg
for id in "$@"; do
  curl -s -m 5 http://127.0.0.1:9227/json/version >/dev/null || ssh -fN -o ExitOnForwardFailure=yes -L 9227:127.0.0.1:9227 macmini4
  TID=$(curl -s -X PUT "http://127.0.0.1:9227/json/new?https://grok.com/" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])"); sleep 8
  frag="grok.com/"
  for req in $(ls data/review/art/$id/cut*_req.md | sort -V); do
    k=$(basename $req _req.md)
    [ -f data/review/art/$id/$k.jpg ] && continue
    A=$ATT; [ -f data/review/art/$id/attach.txt ] && A="$ATT,$(head -1 data/review/art/$id/attach.txt)"
    out=$(GROK_CDP_PORT=9227 /usr/bin/python3 tools/grok_image.py $req data/review/art/$id/$k.jpg --tab "$frag" --attach $A --wait 900 2>&1 | tail -1)
    echo "$id $k $out"; rm -f data/review/art/$id/$k.jpg.md
    frag=$(curl -s http://127.0.0.1:9227/json/list | python3 -c "import json,sys;l=[t for t in json.load(sys.stdin) if t['id']=='$TID'];import re;m=re.search(r'/c/([0-9a-f-]{8})',l[0]['url']) if l else None;print(m.group(1) if m else 'grok.com/')")
  done
  curl -s "http://127.0.0.1:9227/json/close/$TID" >/dev/null
done
