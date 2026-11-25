#!/bin/bash
# 사용: tools/grok/cuts_one.sh <편id>...  (조연이 있으면 data/review/art/<id>/attach.txt 의 조연 시트를 더 첨부)
# 모든 컷을 한 방에서 이어서(tools/grok/room.sh), 컷은 한 장씩(전문가 모델은 한 메시지에 그림 1~2장만)
cd ~/talkverse/zh; source tools/grok/room.sh; room_open
ATT=/Users/talkverse/talkverse/zh/data/review/art/chars_zh01.jpg,/Users/talkverse/talkverse/zh/data/review/uxui/sian_zh05_1.jpg
for id in "$@"; do
  for req in $(ls data/review/art/$id/cut*_req.md | sort -V); do
    k=$(basename $req _req.md)
    [ -f data/review/art/$id/$k.jpg ] && continue
    A=$ATT; [ -f data/review/art/$id/attach.txt ] && A="$ATT,$(head -1 data/review/art/$id/attach.txt)"
    out=$(GROK_CDP_PORT=9227 /usr/bin/python3 tools/grok_image.py $req data/review/art/$id/$k.jpg --tab $ROOM --attach $A --wait 900 2>&1 | tail -1)
    echo "$id $k $out"; rm -f data/review/art/$id/$k.jpg.md
    case "$out" in LIMIT*) room_close; exit 3;; esac
  done
done
room_close
