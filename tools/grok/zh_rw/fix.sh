#!/bin/zsh
# 다시 받기: fix.txt 의 줄 「<id>|<이유>」 마다 새 방(규칙 첨부)에서 그 편 전체를 다시. 옛 답은 out/<id>.md.old
cd "$(dirname "$0")"; export GROK_CDP_PORT=9261; chat=""
while IFS='|' read -r id why; do
  [[ -z $id ]] && continue; out=out/$id.md; [[ -f $out ]] && mv $out $out.old
  msg="$id.txt — 앞 답의 문제: $why. 규칙대로 모든 줄을 새로 써서 그 편 전체를 다시."
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rules_zh.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $msg" > first.txt
    r=$(python3 ../grok_text.py first.txt $out rules_zh.md src/$id.txt 2>&1)
  else
    r=$(python3 ../grok_text.py -m "$msg" $out src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?; echo "$(date +%H:%M) fix $id rc=$rc $(echo $r | grep -E "저장|LIMIT|TIMEOUT|MISMATCH" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 15
done < ${1:-fix.txt}
echo "fix 끝 $chat"
