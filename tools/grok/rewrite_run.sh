#!/bin/bash
# 사용: tools/grok/rewrite_run.sh <편id>...  (M4 Chrome 9227 터널 필요, 요청문 = data/review/<id>_grok_rewrite_prompt.md)
# Grok(전문가) 재작성 — 모든 편을 한 방에서 이어서(tools/grok/room.sh). 답의 턴 수가 요청과 다르면 건너뛰지 않고 표시한다.
cd ~/talkverse/zh; source tools/grok/room.sh; room_open
for id in "$@"; do
  [ -s data/review/${id}_grok_rewrite.md ] && grep -q '^1 [AB]' data/review/${id}_grok_rewrite.md && continue
  res=$(GROK_CDP_PORT=9227 /usr/bin/python3 tools/grok_send.py data/review/${id}_grok_rewrite_prompt.md data/review/${id}_grok_rewrite.md --tab $ROOM --wait 400 2>&1 | tail -1)
  case "$res" in LIMIT*) echo "$id 한도로 중단: $res"; rm -f data/review/${id}_grok_rewrite.md; break;; esac
  sleep 30
  GROK_CDP_PORT=9227 /usr/bin/python3 tools/grok_fetch.py $ROOM data/review/${id}_grok_rewrite.md -1 >/dev/null 2>&1
  echo "$id $(grep -c '^[0-9]* [AB]:' data/review/${id}_grok_rewrite.md)줄 / 요청 $(grep -c '^[0-9]* [AB]:' data/review/${id}_grok_rewrite_prompt.md)줄"
done
room_close
