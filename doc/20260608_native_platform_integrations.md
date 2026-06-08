# Native Platform Integrations (iOS & Android)

_Last updated: 2026-06-08_

This document describes the current state of all OS-level entry points that let the user trigger
in-app actions from **outside** the running app — deep links, home-screen Quick Actions, and the
Assistant/Shortcuts surfaces (Apple Shortcuts / Siri on iOS, Google Assistant App Actions on
Android).

All of these ultimately funnel into the **same Flutter action helpers**
(`SetupActions.addSetup`, `BikeActions.addBike`, `ComponentActions.addComponent`,
`TaskActions.addTaskRule`) via the shared deep-link layer.

- App ID (Android): `com.jonaskeller14.bike_setup_tracker`
- URL scheme (both platforms): `bike-setup-tracker://`
- iOS deployment target: 15.0 (App Intents are gated to iOS 16+)

---

## 1. Shared deep-link layer (foundation for everything else)

Every external entry point below resolves to a `bike-setup-tracker://` URL. Routing is owned by
[lib/services/deep_link_service.dart](../lib/services/deep_link_service.dart) using the `app_links`
package — **not** Flutter's built-in router, which is deliberately disabled on both platforms:

- iOS: `FlutterDeepLinkingEnabled = false` in [ios/Runner/Info.plist](../ios/Runner/Info.plist)
- Android: `flutter_deeplinking_enabled = false` meta-data in
  [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)

### Routes handled

| URL | Action |
|---|---|
| `bike-setup-tracker://add-setup` | `SetupActions.addSetup()` |
| `bike-setup-tracker://add-bike` | `BikeActions.addBike()` |
| `bike-setup-tracker://add-component` | `ComponentActions.addComponent()` |
| `bike-setup-tracker://add-task` | `TaskActions.addTaskRule()` |
| `bike-setup-tracker://add?type={setup\|bike\|component}` | routes to the matching add flow (used by Android App Actions inline inventory) |
| `bike-setup-tracker://strava-auth?success=&error=` | Strava OAuth callback → `StravaService.handleStravaAuthCallback()` |

`DeepLinkService` dedupes rapid duplicate URIs (stream + `getInitialLink()` can both fire on cold
start) and reads `getInitialLink()` so cold-start launches are handled.

### Scheme registration

- **iOS** — `CFBundleURLTypes` in [ios/Runner/Info.plist](../ios/Runner/Info.plist) registers the
  `bike-setup-tracker` scheme (under the `strava-auth` URL name; one scheme covers all hosts).
- **Android** — one `<intent-filter>` per host (`add-setup`, `add-bike`, `add-component`,
  `add-task`, `strava-auth`) on `MainActivity` in
  [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml).

---

## 2. Home-screen Quick Actions (long-press the app icon)

iOS and Android share **one code path**, registered at runtime by
[lib/services/quick_actions_service.dart](../lib/services/quick_actions_service.dart) (the
`quick_actions` plugin):

- Single entry: **"Add New Setup"** — type `add_setup`, icon `ic_add` → `SetupActions.addSetup()`.
- It is registered at runtime (not statically) so the same definition works on both platforms and
  avoids a duplicate launcher entry on Android.
- On Android, the icon resources are kept from R8/shrinker stripping via
  [android/app/src/main/res/raw/keep.xml](../android/app/src/main/res/raw/keep.xml)
  (`@drawable/ic_add`, `@mipmap/ic_add`).

> Note: Android's static `shortcuts.xml` intentionally does **not** declare a launcher shortcut for
> this — the runtime registration above owns the long-press entry.

---

## 3. Assistant / Shortcuts ("routines") — platform-divergent

This is the layer that differs most between platforms.

### iOS — Apple Shortcuts (App Intents + Siri), iOS 16+

Defined natively in [ios/Runner/AppDelegate.swift](../ios/Runner/AppDelegate.swift):

- `AddSetupIntent` → opens `bike-setup-tracker://add-setup`
- `AddBikeIntent` → opens `bike-setup-tracker://add-bike`
- `AddComponentIntent` → opens `bike-setup-tracker://add-component`
- `AddTaskIntent` → opens `bike-setup-tracker://add-task`
- `BikeTrackerAppShortcuts` (`AppShortcutsProvider`) — makes all four auto-appear in the
  **Shortcuts** app and Spotlight, with Siri phrases (e.g. _"Add a setup with Bike Setup Tracker"_).

Implementation notes:
- Each intent returns `OpensIntent` wrapping an `OpenURLIntent`, so the system opens the registered
  deep link and the existing `DeepLinkService` handler does the work — **no Dart-side code** is
  specific to App Intents.
- All three types are `@available(iOS 16.0, *)`. On iOS 15 the provider is simply never registered
  (graceful no-op); the deployment target stays at 15.0.
- No `Info.plist` changes were needed: the URL scheme is already registered, and App Shortcut Siri
  phrases are invoked through the system Siri UI (no microphone/speech usage descriptions required).
- No Flutter package is used — packages such as `flutter_app_intents` still require the same static
  Swift for discovery, so native is simpler here.

### Android — Google Assistant App Actions (Built-In Intents)

Defined statically in [android/app/src/main/res/xml/shortcuts.xml](../android/app/src/main/res/xml/shortcuts.xml),
registered via the `<meta-data android:name="android.app.shortcuts">` entry on `MainActivity`:

- **`actions.intent.CREATE_CREATE_TYPE_NAME`** — with an inline inventory of entity shortcuts
  (`setup`, `bike`, `component`). The matched `shortcutId` is substituted into the capability's URL
  template `bike-setup-tracker://add{?type}`, i.e. it routes to `…://add?type=setup|bike|component`.
  These inventory shortcuts have no `<intent>`/label/icon, so they don't appear in the launcher.
- **`actions.intent.CREATE_TASK`** — Assistant-only BII → `bike-setup-tracker://add-task`.

> Android has no exact equivalent of the user-built **Apple Shortcuts** app; the closest surface is
> Google Assistant App Actions (and Assistant Routines), which is what the above provides.

---

## Parity at a glance

| Action | iOS Apple Shortcuts (App Intents) | Android App Actions (Assistant) | Quick Actions (long-press, both OS) |
|---|---|---|---|
| Add Setup | ✅ `AddSetupIntent` | ✅ `CREATE_CREATE_TYPE_NAME` (`setup`) | ✅ "Add New Setup" |
| Add Bike | ✅ `AddBikeIntent` | ✅ `CREATE_CREATE_TYPE_NAME` (`bike`) | ❌ |
| Add Component | ✅ `AddComponentIntent` | ✅ `CREATE_CREATE_TYPE_NAME` (`component`) | ❌ |
| Add Task | ✅ `AddTaskIntent` | ✅ `CREATE_TASK` | ❌ |

All cells that exist ultimately call the same Dart action helpers via the deep-link layer (§1).

---

## Known limitations & future work

- **Data-backed intents are impractical in Flutter.** Intents that need to show a picker populated
  from the user's data, or return results *inside* Shortcuts/Spotlight **without launching the app**
  (App Intents "entity query" / `AppEntity` pickers, Apple-Intelligence/Spotlight results), run in
  Swift while the Flutter engine is not active. They cannot reach the Drift/SQLite data behind the
  Dart layer without re-implementing DB access in Swift — not worth the fragility.
- **Realistic search path (not yet built):** a "Tier A" intent that takes a text parameter, opens
  the app via a new `bike-setup-tracker://search?q=…` route, and drives the existing in-app setup
  search ([lib/widgets/chips/setup_list_search.dart](../lib/widgets/chips/setup_list_search.dart)).
  Keeps all data access in Dart; only adds a deep-link route + a parameterized Swift intent.
- **Coverage:** iOS App Intents and Android App Actions both now cover all four create actions
  (Setup / Bike / Component / Task). Quick Actions deliberately expose only "Add Setup" to keep the
  long-press menu focused.
