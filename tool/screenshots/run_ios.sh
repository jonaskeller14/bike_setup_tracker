#!/usr/bin/env bash
# Regenerates the App Store raw screenshots (assets/store/app-store/**/0N_raw.png).
#
# Builds the screenshot entry point (lib/main_screenshots.dart) for the
# simulator, boots each simulator, pins the status bar via `simctl status_bar`,
# runs the Maestro flows in tool/screenshots/flows and overwrites the raws in
# place, then runs check_output.py.
#
# Usage: tool/screenshots/run_ios.sh [iphone|ipad|all] [options]
#   --screens 3,7         Screen numbers to capture. Default: all flows.
#   --skip-build          Reuse the last built Runner.app.
#   --keep-running        Leave simulators booted by this script running.
#   --tile-wait-ms N      Fixed wait for live map tiles on screen 07 (default 20000).
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
flows_dir="$script_dir/flows"
app_id='com.jonaskeller14.bike-setup-tracker'
app="$repo_root/build/ios/iphonesimulator/Runner.app"

# Finale Ligure, to match the Add Setup name on screen 03.
gps='44.1690,8.3439'

device='all'
screens=''
skip_build=0
keep_running=0
tile_wait_ms=20000
while [ $# -gt 0 ]; do
  case "$1" in
    iphone | ipad | all) device="$1" ;;
    --screens) screens="$2"; shift ;;
    --skip-build) skip_build=1 ;;
    --keep-running) keep_running=1 ;;
    --tile-wait-ms) tile_wait_ms="$2"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

# Prints "<simulator name>|<store folder>|<DEVICE value for the flows>".
device_config() {
  case "$1" in
    iphone) echo 'iPhone 17 Pro Max|app-store/iPhone-17-Pro-Max|phone' ;;
    ipad) echo 'iPad Pro 13-inch (M5)|app-store/iPad-Pro-13-inch_M5|tablet' ;;
  esac
}
if [ "$device" = all ]; then selected='iphone ipad'; else selected="$device"; fi

maestro="$(command -v maestro || true)"
if [ -z "$maestro" ]; then
  maestro="$HOME/.maestro/bin/maestro"
  [ -x "$maestro" ] || { echo 'Maestro CLI not found. See tool/screenshots/README.md.' >&2; exit 1; }
fi
export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true

flows=()
for flow in "$flows_dir"/[0-9][0-9]_*.yaml; do
  number=$((10#$(basename "$flow" | cut -c1-2)))
  if [ -z "$screens" ] || [[ ",$screens," == *",$number,"* ]]; then
    flows+=("$(basename "$flow")")
  fi
done
[ ${#flows[@]} -gt 0 ] || { echo 'No flows selected.' >&2; exit 1; }

# The newest available runtime wins if a name exists more than once.
simulator_udid() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
matches = [
    (runtime, d["udid"])
    for runtime, devices in json.load(sys.stdin)["devices"].items()
    for d in devices
    if d["name"] == name
]
print(sorted(matches)[-1][1] if matches else "")
' "$1"
}

simulator_booted() {
  xcrun simctl list devices | grep -q "($1) (Booted)"
}

if [ "$skip_build" -eq 0 ]; then
  (cd "$repo_root" && flutter build ios --simulator --debug -t lib/main_screenshots.dart)
fi
[ -d "$app" ] || { echo "App not found: $app" >&2; exit 1; }

failed=()
checked_folders=()
for name in $selected; do
  IFS='|' read -r sim_name folder flow_device <<< "$(device_config "$name")"
  udid="$(simulator_udid "$sim_name")"
  [ -n "$udid" ] || { echo "Simulator \"$sim_name\" not found. Create it in Xcode first." >&2; exit 1; }

  booted_here=0
  if ! simulator_booted "$udid"; then
    echo "Booting $sim_name ($udid) ..."
    booted_here=1
  fi
  xcrun simctl bootstatus "$udid" -b > /dev/null

  xcrun simctl status_bar "$udid" override --time 9:41 \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState discharging --batteryLevel 100
  xcrun simctl install "$udid" "$app"
  xcrun simctl privacy "$udid" grant location "$app_id"
  xcrun simctl location "$udid" set "$gps"

  out_dir="$(mktemp -d -t "screenshots_$name")"
  target_dir="$repo_root/assets/store/$folder"

  for flow in "${flows[@]}"; do
    ok=0
    # Retry a failed flow once, like the Android runner: the first Maestro run
    # after a boot sometimes fails while its XCTest driver is still starting.
    for attempt in 1 2; do
      if [ "$attempt" -eq 1 ]; then echo "[$name] $flow"; else echo "[$name] $flow (retry)"; fi
      if (cd "$flows_dir" && "$maestro" --device "$udid" test "$flow" \
        --test-output-dir "$out_dir" \
        -e "APP_ID=$app_id" \
        -e "DEVICE=$flow_device" \
        -e "TILE_WAIT_MS=$tile_wait_ms"); then
        ok=1
        break
      fi
    done

    shot="$(find "$out_dir" -name "$(echo "$flow" | cut -c1-2)_raw.png" | head -n 1)"
    if [ "$ok" -eq 1 ] && [ -n "$shot" ]; then
      cp "$shot" "$target_dir/"
    else
      failed+=("$name/$flow")
    fi
  done
  checked_folders+=("$folder")

  xcrun simctl status_bar "$udid" clear || true
  if [ "$booted_here" -eq 1 ] && [ "$keep_running" -eq 0 ]; then
    xcrun simctl shutdown "$udid" || true
  fi
done

check_exit=0
python3 "$script_dir/check_output.py" "${checked_folders[@]}" || check_exit=$?

if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed flows (raws left unchanged): ${failed[*]}" >&2
  exit 1
fi
exit "$check_exit"
