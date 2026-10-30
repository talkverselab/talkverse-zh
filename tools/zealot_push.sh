#!/bin/bash
# 가장 최근 release APK 를 Zealot(https://apps.talkverse.uk)에 올린다.
# 사용: tools/zealot_push.sh ["변경 내용 한 줄"]   (없으면 최근 커밋 제목)
#       ZEALOT_FROM_CI=1 tools/zealot_push.sh [...]  — 로컬 빌드 대신 GitHub `latest` 릴리스의 APK 를 받아 올린다
# 빌드는 하지 않는다 — 먼저 release APK 를 만들어 둘 것. 앱이름은 CLAUDE.md 의 "Zealot 앱이름" 과 같아야 한다.
set -euo pipefail

APP_NAME="중국어유니버스"
# 폰에 깔린 앱의 서명(CLAUDE.md §1). 다른 키로 서명된 APK 는 덮어 설치가 거부된다.
SIGN_SHA1="c2c37b28ce7b9e71fa75957ecaed82fdc1fa7ebd"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/android/app/build/outputs/apk/release"

if [ "${ZEALOT_FROM_CI:-}" = "1" ]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  gh release download latest -R talkverselab/talkverse-zh -p app-latest.apk -D "$TMP"
  APK="$TMP/app-latest.apk"
else
  # 서명 안 된 APK(*-unsigned.apk)는 폰에 설치되지 않으므로 제외
  APK="$(ls -t "$OUT"/*.apk 2>/dev/null | grep -v -- '-unsigned\.apk$' | head -n 1 || true)"
  if [ -z "$APK" ]; then
    echo "서명된 release APK 가 없습니다: $OUT" >&2
    echo "CI 가 만든 APK 를 올리려면: ZEALOT_FROM_CI=1 $0" >&2
    exit 1
  fi
fi

# 서명 확인 — apksigner 가 있으면 SHA-1 이 다를 때 올리지 않는다
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
APKSIGNER="$(command -v apksigner || true)"
if [ -z "$APKSIGNER" ] && [ -n "$SDK" ]; then
  APKSIGNER="$(ls "$SDK"/build-tools/*/apksigner 2>/dev/null | tail -n 1 || true)"
fi
if [ -n "$APKSIGNER" ]; then
  GOT="$("$APKSIGNER" verify --print-certs "$APK" | grep -m 1 'SHA-1' | awk '{print $NF}')"
  if [ "$GOT" != "$SIGN_SHA1" ]; then
    echo "서명이 다릅니다: $GOT (기대 $SIGN_SHA1) — 올리지 않습니다. CLAUDE.md §1 참조." >&2
    exit 1
  fi
else
  echo "주의: apksigner 를 찾지 못해 서명을 확인하지 못했습니다(기대 SHA-1 $SIGN_SHA1)." >&2
fi

NOTE="${1:-$(git -C "$ROOT" log -1 --pretty=%s)}"

echo "올리는 파일: $APK"
echo "변경 내용: $NOTE"
"$HOME/bin/zealot-upload" "$APK" "$APP_NAME" -c "$NOTE"
