# Store screenshots

This tooling regenerates the store raws (`assets/store/**/0N_raw.png`) from seeded data. `assets/store/screenshots.af` links the raws, so after a run, recomposing in Affinity takes one click.

| Folder | Device | Size (px) |
|---|---|---|
| `play-store/phone` | AVD `screenshots_phone` (420 dpi, `medium_phone` profile) | 1080×2400 |
| `play-store/tablet_10-inch` | AVD `screenshots_tablet` (240 dpi) | 1200×1920 |
| `app-store/iPhone-17-Pro-Max` | iPhone 17 Pro Max simulator | 1320×2868 |
| `app-store/iPad-Pro-13-inch_M5` | iPad Pro 13-inch (M5) simulator | 2064×2752 |

The Affinity device frames assume these sizes. If `check_output.py` reports a mismatch, fix the device or adjust the frames before recomposing.

The phone AVD uses the generic `medium_phone` profile on purpose. Device profiles such as `pixel_8` add a camera cutout, which makes the status bar about twice as tall as in the old raws.

## Prerequisites

- Flutter plus the Android SDK, with `ANDROID_HOME` set and `cmdline-tools/latest` installed.
- Java 17 or newer.
- The [Maestro CLI](https://docs.maestro.dev/getting-started/installing-maestro). The run script finds it on `PATH` or in `~/.maestro/maestro/bin`.
- Python 3 (standard library only).
- The usual local build config: `android/key.properties`, `android/app/google-services.json` and `.env`. A debug build still reads all three.

## Android

```powershell
tool/screenshots/create_avds.ps1                       # one-time setup
tool/screenshots/run_android.ps1                       # phone + tablet, all 8 screens
tool/screenshots/run_android.ps1 -Device phone -Screens 3,7 -SkipBuild -KeepRunning
```

The run does the following:

1. Builds `flutter build apk --debug -t lib/main_screenshots.dart`.
2. Boots each AVD on a fixed port (5580 for the phone, 5582 for the tablet). Any other running emulator is left alone.
3. Installs the APK and grants the location permission.
4. Sets the GPS to Finale Ligure and pins the status bar with SystemUI demo mode: 9:41, full battery, full wifi, no notifications. The mobile icon is hidden, because Android 16's demo mode ignores `datatype` and always labels it "3G".
5. Runs each flow and copies the resulting PNGs over the raws in place. A flow that fails is retried once, because the emulator's adb connection sometimes drops right after the install. If it fails again, its raw is left unchanged and the script exits non-zero.
6. Runs `python tool/screenshots/check_output.py <folders>`. It checks the sizes and lists which raws changed against `HEAD`.

Review the changed raws with `git diff` or an image diff before committing.

## How the flows stay deterministic

- **Fresh data on every launch.** `lib/main_screenshots.dart` wipes the database and preferences on each launch, seeds `assets/data/20260925_sample_simple.json` plus the Strava sample, and shifts all dates so that the newest one is yesterday. Every flow cold-starts the app through `flows/_launch.yaml`, so no flow depends on another.
- **Selectors are identifiers.** Flows select elements by `Semantics.identifier` values from `lib/utils/automation_ids.dart`, never by UI labels, so localization won't break them. Record names such as tags are data rather than UI labels, so the flows can select them by text.
- **Record IDs are fixed.** Records are addressed by the sample's fixed IDs, for example `garage.component.<Lyrik id>`.
- **Screen 03 (Add Setup):**
  - On a fresh AVD, the first location request makes Play services ask to turn on Location Accuracy. That toggle lives inside Play services, so `adb` can't pre-set it. `flows/_accept_location_accuracy.yaml` taps *Turn on*, and the choice sticks on the AVD.
  - Weather is fixed: `main_screenshots.dart` swaps in `ScreenshotWeatherService` (clear sky, dry). A live Open-Meteo fetch can fail or time out (one run showed N/A), and it changes from run to run.
- **Screen 02 (Add Component):** a duplicate lands on the Lyrik's bike, which already has a fork, so the type field would warn. The flow first adds an empty bike that is also named *Santa Cruz Hightower* and installs the duplicate there. That bike only lives until the next launch reseeds. New bikes get `orderIndex` 0 like the seeded Hightower and sort right after it, so the flow picks the namesake directly above *Trek Session 9*.
- **Screen 05 (component details):**
  - The flow hides the *Pressure* column via the Columns sheet, so the line chart's y-range fits the click-based adjustments. It then ticks the table's select-all box, so the charts compare all setups instead of the latest three, and highlights the first (newest) setup in the radial chart.
  - It then drags from a section title over 10 s. That's slow enough that Flutter doesn't fling, and the title's centre lands at 10 % of the screen height. The phone anchors on *Line Chart* (both charts); the tablet anchors on *Adjustment History* (table and both charts). `run_android.ps1` passes the device as `DEVICE` (`phone` or `tablet`).
- **Screen 07 (map):** tiles load live from CyclOSM. `-TileWaitMs` (default 20 s) is a fixed wait, because nothing signals that the tiles have finished loading.
- **Screen 08 (calendar):** `flows/scripts/calendar_months_back.js` pages back to the sample's busiest month, which is mid-May before the date shift.

## Adding a screen

1. Add any missing identifier to `AutomationIds`, and cover it in `test/utils/automation_ids_test.dart`.
2. Create `flows/NN_name.yaml`:
   - Start it with `- runFlow: _launch.yaml`.
   - End it with `takeScreenshot: { path: NN_raw }`. The run script collects it from Maestro's `--test-output-dir`.
3. Iterate with `maestro studio`, or with `run_android.ps1 -Screens NN -SkipBuild -KeepRunning`.
4. Update `SCREEN_COUNT` in `check_output.py` if the total changes.

## Recording (App Store previews, later)

Maestro's `startRecording` and `stopRecording` work in the same flows, so a preview flow can reuse `_launch.yaml` and the same identifiers.
