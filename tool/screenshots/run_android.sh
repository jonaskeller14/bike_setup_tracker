#!/usr/bin/env bash
# Regenerates the Play Store raw screenshots (assets/store/play-store/**/0N_raw.png).
# macOS/Linux counterpart of run_android.ps1: builds lib/main_screenshots.dart,
# boots each dedicated AVD (see create_avds.sh), pins the status bar via
# SystemUI demo mode, runs the Maestro flows and overwrites the raws in place,
# then runs check_output.py.
#
# Usage: run_android.sh [phone|tablet|all] [--screens 3,7] [--skip-build]
#                       [--keep-running] [--tile-wait-ms N]
#   --screens N,N         Screen numbers to capture. Default: all flows.
#   --skip-build          Reuse the last built APK.
#   --keep-running        Leave the emulators running (faster reruns).
#   --tile-wait-ms N      Fixed wait for live map tiles on screen 07 (default 20000).
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
flows_dir="$script_dir/flows"
app_id='com.jonaskeller14.bike_setup_tracker'
apk="$repo_root/build/app/outputs/flutter-apk/app-debug.apk"

# Finale Ligure, to match the Add Setup name on screen 03.
gps_lon='8.3439'
gps_lat='44.1690'

device='all'
screens=''
skip_build=0
keep_running=0
tile_wait_ms=20000
while [ $# -gt 0 ]; do
  case "$1" in
    phone | tablet | all) device="$1" ;;
    --screens) screens="$2"; shift ;;
    --skip-build) skip_build=1 ;;
    --keep-running) keep_running=1 ;;
    --tile-wait-ms) tile_wait_ms="$2"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

# Prints "<AVD>|<port>|<store folder>".
device_config() {
  case "$1" in
    phone) echo 'screenshots_phone|5580|play-store/phone' ;;
    tablet) echo 'screenshots_tablet|5582|play-store/tablet_10-inch' ;;
  esac
}
if [ "$device" = all ]; then selected='phone tablet'; else selected="$device"; fi

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[ -n "$sdk" ] || { echo 'ANDROID_HOME (or ANDROID_SDK_ROOT) is not set.' >&2; exit 1; }
adb="$sdk/platform-tools/adb"
emulator="$sdk/emulator/emulator"

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

start_avd() {
  local avd="$1" port="$2" serial="emulator-$2"
  if ! "$adb" devices | grep -q "^$serial[[:space:]]*device"; then
    echo "Booting $avd as $serial ..." >&2
    nohup "$emulator" -avd "$avd" -port "$port" -no-snapshot-save -no-boot-anim -no-audio \
      > "${TMPDIR:-/tmp}/$avd.emulator.log" 2>&1 &
  fi
  "$adb" -s "$serial" wait-for-device
  local deadline=$((SECONDS + 300))
  while [ "$("$adb" -s "$serial" shell getprop sys.boot_completed 2> /dev/null | tr -d '\r')" != 1 ]; do
    [ $SECONDS -lt $deadline ] || { echo "$serial did not finish booting." >&2; return 1; }
    sleep 2
  done
  echo "$serial"
}

set_demo_status_bar() {
  local serial="$1"
  "$adb" -s "$serial" shell settings put global sysui_demo_allowed 1
  demo() { "$adb" -s "$serial" shell am broadcast -a com.android.systemui.demo -e command "$@" > /dev/null; }
  # After a cold boot the real wifi icon can register once demo mode is
  # already on and then shows next to the demo one. Re-entering drops it.
  demo exit
  demo enter
  demo clock -e hhmm 0941
  demo battery -e level 100 -e plugged false -e powersave false
  demo network -e wifi show -e level 4 -e fully true
  # The Android 16 SystemUI ignores `datatype` and always labels a demo
  # mobile signal "3G", so the mobile icon is hidden instead.
  demo network -e mobile hide
  demo notifications -e visible false
}

initialize_device() {
  local serial="$1"
  "$adb" -s "$serial" install -r "$apk" > /dev/null
  for permission in ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION; do
    "$adb" -s "$serial" shell pm grant "$app_id" "android.permission.$permission"
  done
  # Play services' Location Accuracy prompt is handled in the flows.
  "$adb" -s "$serial" shell cmd location set-location-enabled true
  "$adb" -s "$serial" emu geo fix "$gps_lon" "$gps_lat" > /dev/null
  # Gboard otherwise opens its "Try out your stylus" onboarding over a focused
  # text field and swallows the flow's input.
  "$adb" -s "$serial" shell settings put secure stylus_handwriting_enabled 0
}

# Maestro connects to every entry in `adb devices` and reports no device at all
# when a single one is not ready (offline, authorizing, unauthorized), even an
# unrelated emulator.
not_ready="$("$adb" devices | tail -n +2 | awk 'NF == 2 && $2 != "device" { printf "%s(%s) ", $1, $2 }')"
if [ -n "$not_ready" ]; then
  echo "Maestro cannot see any device while these adb entries are not ready: $not_ready" >&2
  echo 'Shut them down (adb -s <serial> emu kill) or unplug them, then rerun.' >&2
  exit 1
fi

if [ "$skip_build" -eq 0 ]; then
  (cd "$repo_root" && flutter build apk --debug -t lib/main_screenshots.dart)
fi
[ -f "$apk" ] || { echo "APK not found: $apk" >&2; exit 1; }

failed=()
checked_folders=()
for name in $selected; do
  IFS='|' read -r avd port folder <<< "$(device_config "$name")"
  serial="$(start_avd "$avd" "$port")"

  out_dir="$(mktemp -d -t "screenshots_$name")"
  target_dir="$repo_root/assets/store/$folder"

  initialize_device "$serial"
  for flow in "${flows[@]}"; do
    ok=0
    # The emulator's adb transport can drop briefly (seen right after
    # installing the APK), which kills Maestro's device server: wait for the
    # device before each attempt and retry a failed flow once.
    for attempt in 1 2; do
      if [ "$attempt" -eq 1 ]; then echo "[$name] $flow"; else echo "[$name] $flow (retry)"; fi
      "$adb" -s "$serial" wait-for-device
      set_demo_status_bar "$serial"
      if (cd "$flows_dir" && "$maestro" --device "$serial" test "$flow" \
        --test-output-dir "$out_dir" \
        -e "APP_ID=$app_id" \
        -e "DEVICE=$name" \
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

  # Best effort: a dropped adb transport here must not abort the next device.
  "$adb" -s "$serial" shell am broadcast -a com.android.systemui.demo -e command exit > /dev/null 2>&1 || true
  if [ "$keep_running" -eq 0 ]; then "$adb" -s "$serial" emu kill > /dev/null 2>&1 || true; fi
done

check_exit=0
python3 "$script_dir/check_output.py" "${checked_folders[@]}" || check_exit=$?

if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed flows (raws left unchanged): ${failed[*]}" >&2
  exit 1
fi
exit "$check_exit"
