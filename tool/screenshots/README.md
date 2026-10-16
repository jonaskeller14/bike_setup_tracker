# Store screenshots

This tooling regenerates the store raws (`assets/store/**/0N_raw.png`) from seeded data. `assets/store/screenshots.af` links the raws, so after a run, recomposing in Affinity takes one click.

| Folder | Device | Size (px) |
|---|---|---|
| `play-store/phone` | AVD `screenshots_phone` (420 dpi, `medium_phone` profile) | 1080×2400 |
| `play-store/tablet_10-inch` | AVD `screenshots_tablet` (240 dpi) | 1200×1920 |
| `app-store/iPhone-17-Pro-Max` | iPhone 17 Pro Max simulator | 1320×2868 |
| `app-store/iPad-Pro-13-inch_M5` | iPad Pro 13-inch (M5) simulator | 2064×2752 |

The Affinity device frames assume these sizes. If `check_output.py` reports a mismatch, fix the device or adjust the frames before recomposing.

The exported iPhone frames (`app-store/iPhone-17-Pro-Max/0N.png`) are 1206×2622, the 6.3″ slot size App Store Connect accepts for the default page and every custom product page. The raws have the same aspect ratio, so the composition is exported at that canvas size rather than from a new simulator. `check_output.py` checks the frames as well as the raws.

The phone AVD uses the generic `medium_phone` profile on purpose. Device profiles such as `pixel_8` add a camera cutout, which makes the status bar about twice as tall as in the old raws.

## Prerequisites

- Flutter plus the Android SDK, with `ANDROID_HOME` set and `cmdline-tools/latest` installed.
- Java 17 or newer. Homebrew's `openjdk@17` isn't on `PATH` by default: `export JAVA_HOME=/opt/homebrew/opt/openjdk@17` and add `$JAVA_HOME/bin` to `PATH`.
- The [Maestro CLI](https://docs.maestro.dev/getting-started/installing-maestro). The run script finds it on `PATH` or in `~/.maestro/maestro/bin`.
- Python 3 (standard library only).
- The usual local build config: `android/key.properties`, `android/app/google-services.json` and `.env`. A debug build still reads all three.
- iOS only: a Mac with Xcode and the *iPhone 17 Pro Max* and *iPad Pro 13-inch (M5)* simulators.

## Android

```powershell
tool/screenshots/create_avds.ps1                       # one-time setup
tool/screenshots/run_android.ps1                       # phone + tablet, all 8 screens
tool/screenshots/run_android.ps1 -Device phone -Screens 3,7 -SkipBuild -KeepRunning
```

On macOS/Linux use the bash equivalents (`create_avds.sh` uses the `arm64-v8a` image on Apple Silicon):

```bash
tool/screenshots/create_avds.sh                        # one-time setup
tool/screenshots/run_android.sh                        # phone + tablet, all 8 screens
tool/screenshots/run_android.sh phone --screens 3,7 --skip-build --keep-running
```

The run does the following:

1. Builds `flutter build apk --debug -t lib/main_screenshots.dart`.
2. Boots each AVD on a fixed port (5580 for the phone, 5582 for the tablet). Any other running emulator is left alone.
3. Installs the APK, grants the location permission and turns off stylus handwriting, so Gboard's stylus onboarding can't cover a text field.
4. Sets the GPS to Finale Ligure and, before each flow, pins the status bar with SystemUI demo mode: 9:41, full battery, full wifi, no notifications. The mobile icon is hidden, because Android 16's demo mode ignores `datatype` and always labels it "3G". Demo mode is re-entered per flow, because after a cold boot a second wifi icon can appear next to the demo one.
5. Runs each flow and copies the resulting PNGs over the raws in place. A flow that fails is retried once, because the emulator's adb connection sometimes drops right after the install. If it fails again, its raw is left unchanged and the script exits non-zero.
6. Runs `python tool/screenshots/check_output.py <folders>`. It checks the sizes and lists which raws changed against `HEAD`.

Before building, the script aborts if any entry in `adb devices` is not in the `device` state (`offline`, `authorizing`, `unauthorized`). Maestro connects to every listed device, and a single stuck one, even an unrelated emulator, makes it report "Device emulator-5580 was requested, but it is not connected". Shut the stuck emulator down with `adb -s <serial> emu kill`, or unplug the device.

Review the changed raws with `git diff` or an image diff before committing.

## iOS

```bash
tool/screenshots/run_ios.sh                            # iPhone + iPad, all 8 screens
tool/screenshots/run_ios.sh iphone --screens 3,7 --skip-build --keep-running
```

The run does the following:

1. Builds `flutter build ios --simulator --debug -t lib/main_screenshots.dart`.
2. Boots each simulator by name (the newest runtime wins if a name exists twice). A simulator that was already running stays running; one the script booted is shut down afterwards unless `--keep-running` is set.
3. Pins the status bar with `xcrun simctl status_bar … override`: 9:41, a full battery that is not charging (no green charging icon), full wifi and cellular bars. The override is cleared at the end.
4. Installs the app, pre-grants location with `simctl privacy` and sets the simulated location to Finale Ligure.
5. Runs each flow and copies the resulting PNGs over the raws in place. A failed flow is retried once; if it fails again, its raw is left unchanged and the script exits non-zero.
6. Runs `check_output.py` for the two App Store folders.

The iPhone flows run with `DEVICE=phone` and the iPad flows with `DEVICE=tablet`, so screen 05 anchors the same way as on Android.

## How the flows stay deterministic

- **Fresh data on every launch.** `lib/main_screenshots.dart` wipes the database and preferences on each launch, seeds `assets/data/20260925_sample_simple.json` plus the Strava sample, and shifts all dates so that the newest one is yesterday. Every flow cold-starts the app through `flows/_launch.yaml`, so no flow depends on another.
- **One set of flows for both platforms.** The bundle ID differs (`com.jonaskeller14.bike_setup_tracker` on Android, `com.jonaskeller14.bike-setup-tracker` on iOS), so the flows use `appId: ${APP_ID}`, which the run scripts pass in. Platform differences live in `when: platform:` blocks: `flows/_dismiss_sheet.yaml` presses Back on Android and taps the barrier above the sheet on iOS, which has no Back key, and the Location Accuracy subflow runs on Android only.
- **Keyboard on iOS (screen 03).** Maestro's `hideKeyboard` fails on Flutter text fields on iOS, so it only runs on Android (`flows/_hide_keyboard_android.yaml`). On iOS the keyboard stays up while the flow fills the form. At the end, the flow opens and closes the tags sheet, which closes the keyboard for good.
- **Selectors are identifiers.** Flows select elements by `Semantics.identifier` values from `lib/utils/automation_ids.dart`, never by UI labels, so localization won't break them. Record names such as tags are data rather than UI labels, so the flows can select them by text.
- **Record IDs are fixed.** Records are addressed by the sample's fixed IDs, for example `garage.component.<Lyrik id>`.
- **Screen 03 (Add Setup):**
  - On a fresh AVD, the first location request makes Play services ask to turn on Location Accuracy. That toggle lives inside Play services, so `adb` can't pre-set it. `flows/_accept_location_accuracy.yaml` taps *Turn on*, and the choice sticks on the AVD.
  - Weather is fixed: `main_screenshots.dart` swaps in `ScreenshotWeatherService` (clear sky, dry). A live Open-Meteo fetch can fail or time out (one run showed N/A), and it changes from run to run.
- **Screen 02 (Add Component):** a duplicate lands on the Lyrik's bike, which already has a fork, so the type field would warn. The flow first adds an empty bike that is also named *Santa Cruz Hightower* and installs the duplicate there. That bike only lives until the next launch reseeds. New bikes get `orderIndex` 0 like the seeded Hightower and sort right after it, so the flow picks the second namesake in the Bike menu.
- **Screen 05 (component details):**
  - The flow hides the *Pressure* column via the Columns sheet, so the line chart's y-range fits the click-based adjustments. It then ticks the table's select-all box, so the charts compare all setups instead of the latest three, and highlights the first (newest) setup in the radial chart.
  - It then drags from a section title over 10 s. That's slow enough that Flutter doesn't fling, and the title's centre lands at 10 % of the screen height. The phone anchors on *Line Chart* (both charts). On the iPhone the status bar plus app bar are taller than 10 % of the screen, so a second slow drag pulls the title back down by 5 %; the tablet anchors on *Adjustment History* (table and both charts). The run scripts pass the device as `DEVICE` (`phone` or `tablet`).
- **Screen 07 (map):** tiles load live from CyclOSM. `-TileWaitMs` / `--tile-wait-ms` (default 20 s) is a fixed wait, because nothing signals that the tiles have finished loading.
- **Screen 08 (calendar):** `flows/scripts/calendar_months_back.js` pages back to the sample's busiest month, which is mid-May before the date shift.

## Adding a screen

1. Add any missing identifier to `AutomationIds`, and cover it in `test/utils/automation_ids_test.dart`.
2. Create `flows/NN_name.yaml`:
   - Start it with `- runFlow: _launch.yaml`.
   - End it with `takeScreenshot: { path: NN_raw }`. The run script collects it from Maestro's `--test-output-dir`.
3. Iterate with `maestro studio`, or with `run_android.ps1 -Screens NN -SkipBuild -KeepRunning` / `run_android.sh --screens NN --skip-build --keep-running` / `run_ios.sh --screens NN --skip-build --keep-running`. Running a flow by hand needs `-e APP_ID=<bundle id>` (plus `-e DEVICE=…` for screen 05).
4. Update `SCREEN_COUNT` in `check_output.py` if the total changes.

## Recording (App Store previews)

```bash
tool/screenshots/run_ios.sh iphone --preview           # records flows/preview_*.yaml
```

`--preview` runs the `preview_*.yaml` flows instead of the numbered ones, on the same build, seeded data and status bar. Each flow's recording lands in `build/store_previews/<iphone|ipad>/<flow name>.mp4`. That folder is not tracked, and `flutter clean` deletes it.

`flows/preview_setup.yaml` is an example that proves recording works: Garage → Add Setup → Setup History in about 27 s on the iPhone. It is not a finished preview.

- **Recording.** Maestro's `startRecording: <name>` and `stopRecording` wrap `simctl io recordVideo`. The clip has the simulator's full resolution (1320×2868 on the iPhone, 2064×2752 on the iPad), H.264, no audio track, and a variable frame rate, because the simulator only writes a frame when the screen changes.
- **Pacing.** Maestro has no sleep command. `flows/_pause.yaml` waits `MS` milliseconds for an element that never appears. Without pauses the flow runs faster than a viewer can follow.
- **Touch dots.** With `--preview`, the app draws a dot under every tap and drag (`lib/screenshots/touch_indicator.dart`).
  - Maestro's taps last a few milliseconds, so each dot stays at least 450 ms, with a ring expanding from it, before it fades out.
  - Each dot is drawn up to 6 px off the touch, so taps don't all land on the exact centre of a button. Only the drawing moves; the tap itself stays where the flow put it. The offsets come from a fixed seed, so every recording of a flow looks the same.
  - The Simulator's own *Show Single Touches* setting can't do this. It only follows the mouse in the Simulator window, so it is neither part of the recorded video nor triggered by Maestro's synthesized touches.
  - The run script switches the dots on by creating the marker file `Documents/screenshot_show_touches` in the app's data container, and deletes it at the end. A file is used because Dart can't read environment variables on iOS. Every run deletes a leftover marker first, so the raws stay free of dots.
  - `run_android.sh --demo` creates the same marker in the app's `app_flutter` folder with `adb shell run-as`, so both platforms show the same dots.

### App Store preview specs

Check these against App Store Connect's current *App preview specifications* before producing real previews:

| | 6.9" iPhone | 13" iPad |
|---|---|---|
| Resolution (portrait) | 886×1920 | 1200×1600 |
| Length | 15–30 s | 15–30 s |

- H.264 (High profile, level 4.0, 10–12 Mbps) or ProRes 422 HQ, at most 30 fps, at most 500 MB, as `.mov`, `.m4v` or `.mp4`.
- Stereo AAC audio at 256 kbps, 44.1 or 48 kHz. Uploads without an audio track tend to be rejected, so add a silent one.
- Up to three previews per device size and localization.

### Trim, resize and encode

`python tool/marketing/build_kit.py appstore` cuts `preview_setup.mp4` as set in `docs/marketing/kits/appstore.json`, scales it to 886×1920 at a constant 30 fps (H.264 High, level 4.0) and adds a silent stereo AAC track: `build/marketing/appstore/preview_iphone.mp4`. See `tool/marketing/README.md`. The kit has no iPad preview yet; `render_video.appstore_preview` takes the size (`(1200, 1600)`) for one.

## Demo clips (marketing)

```powershell
tool/screenshots/run_android.ps1 -Demo                 # records flows/demo_*.yaml
```

```bash
tool/screenshots/run_android.sh --demo
tool/screenshots/run_ios.sh iphone --demo              # the clips the marketing kits use
```

`-Demo` / `--demo` records the `demo_*.yaml` flows with touch dots and the same build, seeded data, status bar and GPS as the screenshots. Each recording lands in `build/marketing/raw/<flow name>.mp4` on the phone AVD (1080×2400) and in `build/marketing/raw/ios/<flow name>.mp4` on the iPhone (1320×2868); both H.264, no audio, variable frame rate. `-Screens` / `--screens` don't apply.

The marketing kits use the iPhone clips: the iPhone frame's screen hole is exactly 1320×2868, so the recording fits without cropping, and an iPhone looks familiar on social media. The Android clips stay available for a kit that sets `"recordings": "build/marketing/raw"`.

| Flow | Shows |
|---|---|
| `demo_add_bike` | A new bike in the garage |
| `demo_add_component` | A fork with Pressure and Rebound from the type's suggestions |
| `demo_add_setup` | Location and weather filling in, tags, one adjustment, save |
| `demo_setup_history` | The Hightower's history, then its newest setup compared with the one before |
| `demo_analysis` | The Lyrik's line and radial charts over all setups |
| `demo_tasks` | Ticking off a due task |
| `demo_map` | The Finale Ligure ride on the map with its setups |
| `demo_calendar` | The month view |
| `demo_strava` | The Strava dashboard, then a ride with the setup ridden on it |

- **Only released features.** Demo flows don't show anything behind a debug-only feature flag, such as the component preset catalog.
- **Pacing.** Each flow starts recording once the app is on its first screen and holds key moments with `_pause.yaml`, aiming for 15–30 s.
- **Ending.** Flows end with `_stop_recording.yaml` instead of `stopRecording`. Both the Android encoder and the iOS Simulator keep the last frames before a still screen until the screen changes again, and `stopRecording` drops them, so a clip would end before its final transition. The subflow holds the screen, then presses *Volume Up* (Android) or *Home* (iOS). The volume panel or home animation that follows stays in the file; `tool/marketing/build_kit.py` cuts it off automatically. A tap can't do this: the status bar opens the notification shade, and an in-app tap depends on the page.
- **Map tiles.** `demo_map` waits `TILE_WAIT_MS` before it starts recording, so the clip doesn't show tiles loading.
- Running a demo flow by hand needs `-e APP_ID=<bundle id>`, plus `-e TILE_WAIT_MS=<ms>` for `demo_map`; `maestro test --test-output-dir <dir>` keeps the mp4.
