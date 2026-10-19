#!/usr/bin/env bash
# Regenerates the App Store raw screenshots (docs/store/app-store/**/0N_raw.png).
#
# Builds the screenshot entry point (lib/main_screenshots.dart) for the
# simulator, boots each simulator, pins the status bar via `simctl status_bar`,
# runs the Maestro flows in tool/screenshots/flows and overwrites the raws in
# place, runs check_output.py, then renders the store screenshots (raw screen
# in the device frame with its caption) from the new raws.
#
# Usage: tool/screenshots/run_ios.sh [iphone|ipad|all] [options]
#   --screens 3,7         Screen numbers to capture. Default: all flows.
#   --skip-build          Reuse the last built Runner.app.
#   --keep-running        Leave simulators booted by this script running.
#   --raw-only            Don't render the store screenshots from the new raws.
#   --tile-wait-ms N      Fixed wait for live map tiles on screen 07 (default 20000).
#   --preview             Record the preview_*.yaml flows instead, with touch dots,
#                         to build/store_previews/<device>/*.mp4.
#   --demo                Record the demo_*.yaml flows instead, on the iPhone with
#                         touch dots, to build/marketing/raw/ios/*.mp4.
#   --flows a,b           With --preview or --demo: only these flows (names without
#                         .yaml), so the other recordings keep the timings kits use.
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
only_flows=''
skip_build=0
keep_running=0
raw_only=0
tile_wait_ms=20000
preview=0
demo=0
while [ $# -gt 0 ]; do
  case "$1" in
    iphone | ipad | all) device="$1" ;;
    --screens) screens="$2"; shift ;;
    --flows) only_flows="$2"; shift ;;
    --skip-build) skip_build=1 ;;
    --keep-running) keep_running=1 ;;
    --raw-only) raw_only=1 ;;
    --tile-wait-ms) tile_wait_ms="$2"; shift ;;
    --preview) preview=1 ;;
    --demo) demo=1 ;;
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
# Marketing clips are iPhone-only.
if [ "$demo" -eq 1 ]; then selected='iphone'; fi
# Recording modes collect each flow's mp4 instead of a screenshot.
record=$((preview || demo))

maestro="$(command -v maestro || true)"
if [ -z "$maestro" ]; then
  maestro="$HOME/.maestro/bin/maestro"
  [ -x "$maestro" ] || { echo 'Maestro CLI not found. See tool/screenshots/README.md.' >&2; exit 1; }
fi
export MAESTRO_CLI_NO_ANALYTICS=1
export MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED=true

flows=()
if [ "$record" -eq 1 ]; then
  if [ "$demo" -eq 1 ]; then pattern='demo_*.yaml'; else pattern='preview_*.yaml'; fi
  for flow in "$flows_dir"/$pattern; do
    name="$(basename "$flow" .yaml)"
    if [ -z "$only_flows" ] || [[ ",$only_flows," == *",$name,"* ]]; then
      flows+=("$name.yaml")
    fi
  done
else
  for flow in "$flows_dir"/[0-9][0-9]_*.yaml; do
    number=$((10#$(basename "$flow" | cut -c1-2)))
    if [ -z "$screens" ] || [[ ",$screens," == *",$number,"* ]]; then
      flows+=("$(basename "$flow")")
    fi
  done
fi
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

# Prints the flow's `# scenario: <name>` (see lib/screenshots/demo_scenario.dart), if any.
flow_scenario() {
  sed -n 's/^# scenario: *\([a-z_]*\).*/\1/p' "$flows_dir/$1" | head -n 1
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
  target_dir="$repo_root/docs/store/$folder"
  # lib/main_screenshots.dart draws touch dots while this marker exists. It is
  # removed first, in case an aborted preview run left it behind.
  touch_marker="$(xcrun simctl get_app_container "$udid" "$app_id" data)/Documents/screenshot_show_touches"
  rm -f "$touch_marker"
  # The app seeds this demo scenario; without the marker it seeds the full sample.
  scenario_marker="$(dirname "$touch_marker")/demo_scenario"
  if [ "$record" -eq 1 ]; then
    if [ "$demo" -eq 1 ]; then
      target_dir="$repo_root/build/marketing/raw/ios"
    else
      target_dir="$repo_root/build/store_previews/$name"
    fi
    mkdir -p "$target_dir" "$(dirname "$touch_marker")"
    touch "$touch_marker"
  fi

  for flow in "${flows[@]}"; do
    rm -f "$scenario_marker"
    scenario="$(flow_scenario "$flow")"
    if [ -n "$scenario" ]; then
      mkdir -p "$(dirname "$scenario_marker")"
      printf '%s' "$scenario" > "$scenario_marker"
    fi
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

    if [ "$record" -eq 1 ]; then
      shot="$(find "$out_dir" -name "${flow%.yaml}.mp4" | head -n 1)"
    else
      shot="$(find "$out_dir" -name "$(echo "$flow" | cut -c1-2)_raw.png" | head -n 1)"
    fi
    if [ "$ok" -eq 1 ] && [ -n "$shot" ]; then
      cp "$shot" "$target_dir/"
    else
      failed+=("$name/$flow")
    fi
  done
  checked_folders+=("$folder")

  rm -f "$touch_marker" "$scenario_marker"
  xcrun simctl status_bar "$udid" clear || true
  if [ "$booted_here" -eq 1 ] && [ "$keep_running" -eq 0 ]; then
    xcrun simctl shutdown "$udid" || true
  fi
done

check_exit=0
if [ "$demo" -eq 1 ]; then
  echo "Recordings: $repo_root/build/marketing/raw/ios"
elif [ "$preview" -eq 1 ]; then
  echo "Recordings: $repo_root/build/store_previews"
else
  python3 "$script_dir/check_output.py" "${checked_folders[@]}" || check_exit=$?
  if [ "$raw_only" -eq 0 ]; then
    # shellcheck disable=SC2086 # $selected is a list of device names
    python3 "$repo_root/tool/marketing/render_images.py" store-screenshots $selected ${screens:+"$screens"} || check_exit=$?
  fi
fi

if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed flows (outputs left unchanged): ${failed[*]}" >&2
  exit 1
fi
exit "$check_exit"
