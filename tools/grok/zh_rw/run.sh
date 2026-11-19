#!/bin/zsh
# 중국어 회화 Grok 재작성(PC 크롬 9261, 빠른 모드). 방 하나에 N편 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄. 결과 out/<id>.md
cd "$(dirname "$0")"; export GROK_CDP_PORT=9261; chat=""
for id in "$@"; do
  out=out/$id.md; [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rules_zh.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > first.txt
    r=$(python3 ../grok_text.py first.txt $out rules_zh.md src/$id.txt 2>&1)
  else
    r=$(python3 ../grok_text.py -m "$id.txt" $out src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|빠른|TIMEOUT|MISMATCH|Error|error" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 15
done
echo "끝 $chat"
