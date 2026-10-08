#!/usr/bin/env bash
# Creates the two dedicated screenshot AVDs (one-time setup). macOS/Linux
# counterpart of create_avds.ps1.
#
#   screenshots_phone  : 1080x2400 @ 420 dpi -> assets/store/play-store/phone
#   screenshots_tablet : 1200x1920 @ 240 dpi -> assets/store/play-store/tablet_10-inch
#
# The resolutions must match the raw PNGs that assets/store/screenshots.af
# links; check_output.py fails loudly if they drift.
#
# Usage: create_avds.sh [--force]    (--force recreates existing AVDs)
set -euo pipefail

force=0
[ "${1:-}" = '--force' ] && force=1

sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[ -n "$sdk" ] || { echo 'ANDROID_HOME (or ANDROID_SDK_ROOT) is not set.' >&2; exit 1; }
avdmanager="$sdk/cmdline-tools/latest/bin/avdmanager"
sdkmanager="$sdk/cmdline-tools/latest/bin/sdkmanager"
avd_home="${ANDROID_AVD_HOME:-$HOME/.android/avd}"

# Apple Silicon runs arm64 images; everything else uses x86_64.
if [ "$(uname -m)" = arm64 ]; then abi='arm64-v8a'; else abi='x86_64'; fi
image="system-images;android-36;google_apis;$abi"

if [ ! -d "$sdk/${image//;//}" ]; then
  echo "Installing $image ..."
  "$sdkmanager" "$image"
fi

# Prints "<name>|<device profile>|<width>|<height>|<density>".
avds=(
  'screenshots_phone|medium_phone|1080|2400|420'
  'screenshots_tablet|Nexus 7 2013|1200|1920|240'
)

for entry in "${avds[@]}"; do
  IFS='|' read -r name device width height density <<< "$entry"
  config="$avd_home/$name.avd/config.ini"
  if [ -f "$config" ] && [ "$force" -eq 0 ]; then
    echo "$name already exists (use --force to recreate)."
    continue
  fi

  echo "Creating $name ..."
  echo no | "$avdmanager" create avd --force --name "$name" --package "$image" --device "$device"

  # Pin the exact output resolution; the device profiles only approximate it.
  python3 - "$config" "$width" "$height" "$density" <<'PY'
import sys
path, width, height, density = sys.argv[1:]
overrides = {
    'hw.lcd.width': width,
    'hw.lcd.height': height,
    'hw.lcd.density': density,
    'hw.keyboard': 'yes',
    'hw.initialOrientation': 'portrait',
    'showDeviceFrame': 'no',
    'skin.dynamic': 'yes',
    'skin.name': f'{width}x{height}',
    'skin.path': f'{width}x{height}',
    'disk.dataPartition.size': '6G',
}
with open(path) as f:
    lines = [l.rstrip('\n') for l in f if l.split('=', 1)[0].strip() not in overrides]
lines += [f'{k}={v}' for k, v in overrides.items()]
with open(path, 'w') as f:
    f.write('\n'.join(lines) + '\n')
PY
done

echo 'Done. AVDs:'
"$sdk/emulator/emulator" -list-avds
