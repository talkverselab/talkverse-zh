#!/bin/zsh
cd "$(dirname "$0")"
ids=($(cat ids.txt))
for ((i=1;i<=${#ids};i+=26)); do
  ./run.sh ${ids[@]:$((i-1)):26}; rc=$?
  [[ $rc -eq 3 ]] && { echo "ALL LIMIT 멈춤"; exit 3; }
done
echo ALL 끝
