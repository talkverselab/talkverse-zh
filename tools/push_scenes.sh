#!/bin/bash
# 생성된 장면 컷(data/review/art/<편id>/cutN.jpg)을 공용 그림 저장소 talkverselab/talkversehanja 의
# talkverse_art/scene/zh/<편id>/cutN.jpg 로 푸시한다(uk 세션이 R2 로 올려 /art/zh/scene/manifest 로 제공, 2026-11-02 약속).
# 사용: tools/push_scenes.sh   — 새로 생긴 jpg 만 복사해 한 커밋. 작업용 얕은 클론은 세션 스크래치(없으면 다시 만든다).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
S="${SCRATCH:-/private/tmp/claude-501/-Users-talkverse-talkverse-zh/a3b9f983-bfaf-470b-b1e7-3f34212db5c9/scratchpad}"
C="$S/art_push"
if [ ! -d "$C/.git" ]; then
  git clone -q --depth 1 --filter=blob:none --sparse https://github.com/talkverselab/talkversehanja.git "$C"
  git -C "$C" sparse-checkout set talkverse_art/scene/zh
  git -C "$C" config user.email talkverse.lab@gmail.com; git -C "$C" config user.name "talkverse-zh session"
fi
git -C "$C" reset -q --hard
git -C "$C" pull -q --rebase origin main
count=0
for f in "$ROOT"/data/review/art/*/cut*.jpg; do
  id=$(basename "$(dirname "$f")"); b=$(basename "$f")
  [[ "$id" =~ ^[a-z0-9_]+$ ]] || continue
  dst="$C/talkverse_art/scene/zh/$id/$b"
  if [ ! -f "$dst" ] || ! cmp -s "$f" "$dst"; then mkdir -p "$(dirname "$dst")"; cp "$f" "$dst"; count=$(( count + 1 )); fi
done
if [ "$count" -eq 0 ]; then echo "새 컷 없음"; exit 0; fi
git -C "$C" add talkverse_art/scene/zh
git -C "$C" commit -q -m "scene/zh: 장면 컷 ${count}장 (talkverse-zh)" && git -C "$C" push -q origin main && echo "푸시: ${count}장"
