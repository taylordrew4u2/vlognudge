#!/usr/bin/env bash
# Builds VlogNudge for the iOS Simulator, launches it in -ScreenshotMode with
# seeded demo data, and saves the README screenshots to docs/screenshots/.
#
# Usage: scripts/capture_screenshots.sh [simulator-udid]
# Without a UDID it picks (or creates) an available iPhone simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/screenshots"
DERIVED="$ROOT/build/screenshots"
BUNDLE_ID="comedy.vlognudgee"

UDID="${1:-}"
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
ios = sorted((r for r in devices if "iOS" in r), reverse=True)
print(next((d["udid"] for r in ios for d in devices[r] if d["name"].startswith("iPhone") and "Pro" in d["name"] and "Max" not in d["name"]),
           next((d["udid"] for r in ios for d in devices[r] if d["name"].startswith("iPhone")), "")))
')
fi
if [ -z "$UDID" ]; then
  RUNTIME=$(xcrun simctl list runtimes available -j | python3 -c '
import json, sys
print([r for r in json.load(sys.stdin)["runtimes"] if r["platform"] == "iOS"][-1]["identifier"])
')
  DEVICE_TYPE=$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
print([t for t in json.load(sys.stdin)["devicetypes"] if t["name"].startswith("iPhone")][-1]["identifier"])
')
  UDID=$(xcrun simctl create "Screenshots iPhone" "$DEVICE_TYPE" "$RUNTIME")
fi
echo "Using simulator $UDID"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl ui "$UDID" appearance dark
xcrun simctl status_bar "$UDID" override \
  --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100

xcodebuild build \
  -project "$ROOT/vlognudgee.xcodeproj" \
  -scheme vlognudgee \
  -destination "id=$UDID" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

APP=$(find "$DERIVED/Build/Products" -maxdepth 2 -name "vlognudgee.app" -path "*iphonesimulator*" | head -1)
xcrun simctl install "$UDID" "$APP"
mkdir -p "$OUT"

# Run the app in a time zone where it is ~1 PM so greetings and clip times
# look like a normal day regardless of when this runs.
OFFSET=$(( 13 - 10#$(date -u +%H) ))
if [ "$OFFSET" -ge 0 ]; then SHOT_TZ="Etc/GMT-$OFFSET"; else SHOT_TZ="Etc/GMT+${OFFSET#-}"; fi
echo "App time zone: $SHOT_TZ"

capture() {
  local name="$1"; shift
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  SIMCTL_CHILD_TZ="$SHOT_TZ" xcrun simctl launch "$UDID" "$BUNDLE_ID" -ScreenshotMode "$@" >/dev/null
  sleep 4
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$name.png" >/dev/null
  echo "Saved $OUT/$name.png"
}

capture home            -ScreenshotTab 0
capture today           -ScreenshotTab 1
capture timeline        -ScreenshotTab 2
capture settings        -ScreenshotTab 4
capture settings-places -ScreenshotTab 4 -ScreenshotSettingsPlaces

xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl status_bar "$UDID" clear
