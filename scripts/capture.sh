#!/usr/bin/env bash
# Regenerates screenshots/{light,dark}/<NN-name>.png on an iOS 27 iPhone simulator.
#
#   scripts/capture.sh                  all six screens, light and dark
#   scripts/capture.sh --only 02-place  one screen, light and dark
#
# Env: DEVICE_NAME (default "iPhone 18 Pro"), MAP_WAIT (default 25), WAIT (default 4).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEVICE_NAME="${DEVICE_NAME:-iPhone 18 Pro}"
BUNDLE_ID="dev.heyparsa.liquidglassshowcase"
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY="${2:?--only needs a screen slug}"; shift 2 ;;
    *) echo "usage: $0 [--only NN-name]" >&2; exit 2 ;;
  esac
done

if [ -n "$ONLY" ] && ! grep -qxF -- "$ONLY" "$ROOT/scripts/screens.txt"; then
  echo "error: unknown screen '$ONLY' (see scripts/screens.txt)" >&2
  exit 2
fi

# Prefer a booted device with that name on an iOS 27 runtime, else the first match.
UDID="$(xcrun simctl list devices available -j | DEVICE_NAME="$DEVICE_NAME" python3 -I -c '
import json, os, sys
name = os.environ["DEVICE_NAME"]
matches = [d for runtime, devices in json.load(sys.stdin)["devices"].items()
           if "iOS-27" in runtime for d in devices if d["name"] == name]
matches.sort(key=lambda d: d["state"] != "Booted")
print(matches[0]["udid"] if matches else "")
')"
if [ -z "$UDID" ]; then
  echo "error: no available '$DEVICE_NAME' simulator on iOS 27" >&2
  exit 1
fi

ORIGINAL_APPEARANCE=""
cleanup() {
  xcrun simctl status_bar "$UDID" clear >/dev/null 2>&1 || true
  case "$ORIGINAL_APPEARANCE" in
    light|dark) xcrun simctl ui "$UDID" appearance "$ORIGINAL_APPEARANCE" >/dev/null 2>&1 || true ;;
  esac
}
trap cleanup EXIT
trap 'exit 130' INT TERM

xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
ORIGINAL_APPEARANCE="$(xcrun simctl ui "$UDID" appearance 2>/dev/null || true)"

echo "building…"
(cd "$ROOT" && xcodegen generate --quiet && xcodebuild -project Showcase.xcodeproj -scheme Showcase \
  -sdk iphonesimulator -destination "id=$UDID" -derivedDataPath build -quiet build)
xcrun simctl install "$UDID" "$ROOT/build/Build/Products/Debug-iphonesimulator/Showcase.app"

# Another app in the foreground when ours launches puts a "< App name" return link in the status
# bar. Close every other running app first so the status bar is clean.
xcrun simctl spawn "$UDID" launchctl list 2>/dev/null \
  | sed -n 's/.*UIKitApplication:\([^[]*\)\[.*/\1/p' \
  | while IFS= read -r other; do
      [ "$other" = "$BUNDLE_ID" ] || xcrun simctl terminate "$UDID" "$other" >/dev/null 2>&1 || true
    done

xcrun simctl status_bar "$UDID" override --time "9:41" \
  --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 \
  --batteryState charged --batteryLevel 100

for appearance in light dark; do
  xcrun simctl ui "$UDID" appearance "$appearance"
  mkdir -p "$ROOT/screenshots/$appearance"
  index=0
  while IFS= read -r slug || [ -n "$slug" ]; do
    [ -z "$slug" ] && continue
    index=$((index + 1))
    if [ -n "$ONLY" ] && [ "$slug" != "$ONLY" ]; then continue; fi
    target="$ROOT/screenshots/$appearance/$slug.png"
    rm -f "$target"                        # a failed capture must not leave an old image for the checker
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
    pid="$(xcrun simctl launch "$UDID" "$BUNDLE_ID" -screen "$index" | awk -F': ' '{print $2}')"
    case "$slug" in
      *explore|*navigation) sleep "${MAP_WAIT:-25}" ;;
      *) sleep "${WAIT:-4}" ;;
    esac
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "error: the app exited before the $appearance/$slug screenshot (crashed?)" >&2
      exit 1
    fi
    if ! shot_error="$(xcrun simctl io "$UDID" screenshot --type=png "$target" 2>&1 >/dev/null)"; then
      echo "error: screenshot of $appearance/$slug failed: $shot_error" >&2
      exit 1
    fi
    echo "captured $appearance/$slug"
  done < "$ROOT/scripts/screens.txt"
done

python3 -I "$ROOT/scripts/optimize_screenshots.py" "$ROOT/screenshots"

check_args=("$ROOT/screenshots")
if [ -n "$ONLY" ]; then check_args+=(--only "$ONLY"); fi
python3 -I "$ROOT/scripts/check_screenshots.py" "${check_args[@]}"
