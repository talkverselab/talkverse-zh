#!/bin/bash
# 장면 컷 채우기 — PC 크롬 9261(11/23 uk 「zh Grok 차례」). 「빠른」 모드, 컷 한 장씩, 25장마다 새 방(한도 아끼기).
# 사용: tools/grok/cuts_pc.sh <편id>...   첨부는 PC D:/grok_att/zh/ 에 미리 올려 둔 것(크롬이 PC 에서 돎)
cd ~/talkverse/zh; export GROK_CDP_PORT=9261 GROK_REMOTE=; B=http://127.0.0.1:9261; PA=D:/grok_att/zh
ATT=$PA/chars_zh01.jpg,$PA/sian_zh05_1.jpg; n=0; TID=""
newroom() {   # 탭이 하나만 있어야 grok_image 가 grok.com 으로 그 탭을 찾는다 — 있던 탭은 모두 닫고 새 방 하나
  for t in $(curl -s $B/json/list | python3 -c "import json,sys;[print(t['id']) for t in json.load(sys.stdin) if t['type']=='page']"); do curl -s "$B/json/close/$t" >/dev/null; done
  TID=$(curl -s -X PUT "$B/json/new?https://grok.com/" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])"); sleep 12; }
newroom
for id in "$@"; do
  for req in $(ls data/review/art/$id/cut*_req.md 2>/dev/null | sort -V); do
    k=$(basename $req _req.md); [ -f data/review/art/$id/$k.jpg ] && continue
    [ $n -gt 0 ] && [ $((n % 25)) -eq 0 ] && newroom
    A=$ATT; [ -f data/review/art/$id/attach.txt ] && A="$ATT,$PA/$(basename $(head -1 data/review/art/$id/attach.txt))"
    out=$(/usr/bin/python3 tools/grok_image.py $req data/review/art/$id/$k.jpg --tab grok.com --attach $A --wait 180 2>&1 | tail -1)
    n=$((n+1)); echo "$(date +%H:%M) $id $k $out"; rm -f data/review/art/$id/$k.jpg.md
    case "$out" in LIMIT*) curl -s "$B/json/close/$TID" >/dev/null; exit 3;; esac
  done
done
curl -s "$B/json/close/$TID" >/dev/null
