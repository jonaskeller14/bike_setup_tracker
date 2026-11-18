# Store release steps

What to do after `/releaseversion` has built the release (AAB + IPA) and the PR is merged. The
"What's New" text comes from `play-store/metadata/<locale>/changelogs/<versionCode>.txt` for both
stores; listing text lives in `app-store/metadata/` and `play-store/metadata/`. The store labels
are from the **German** consoles. Setup (keys, tools) is in
[#73](https://github.com/jonaskeller14/bike_setup_tracker/issues/73).

## Commands

Run from the repo root. Every `tool/store/ios.sh` command takes `--dry-run`; the fastlane lanes take
`dry_run:true`.

| Step | Command | Does |
|---|---|---|
| 1 | `tool/store/ios.sh release` | Uploads the IPA, creates or finds the App Store version, attaches the build, sets text, review notes, copyright and What's New. Waits up to 30 minutes for processing (`ASC_TIMEOUT` changes it). If the build is already in App Store Connect, because an earlier run timed out, it asks `[y/N]` and on `y` skips the upload and carries on with the version, build and text |
| 2 | `tool/store/ios.sh screenshots` | Only if screenshots or previews changed: replaces them on the editable version |
| 3 | `bundle exec fastlane android release` | Uploads the AAB and release notes as a production **draft** |
| 4 | `bundle exec fastlane android metadata` / `android screenshots` | Only if the Play listing changed and no experiment runs: title, descriptions, icon, feature graphic / screenshots. Both lanes only save the change in the Play Console; send it for review there (Publishing overview → send changes for review), or pass `send_for_review:true` to send it right away. Screenshots need no new release |

Between releases: `tool/store/ios.sh promo` (promotional text, no version needed) and the Play
`metadata` / `screenshots` lanes.

## Manual clicks

1. [ ] **App Store Connect** → **Bike Setup Tracker** → the new version → **Zur Prüfung hinzufügen**
   → **Zur Prüfung einreichen**.
2. [ ] **Play Console** → **Testen und veröffentlichen** → **Produktion** → open the draft →
   **Release prüfen** → **Zur Überprüfung senden**.

## New listing languages

A locale added to `LOCALES` in `tool/store/ios.sh` needs, before the first upload:

- **App Store Connect:** `ios.sh release` creates the version localizations itself, then stops at the app
  info: App Store Connect has already created those entries with the English subtitle, so the import's create
  fails. Set name and subtitle of the new locales with `asc api PATCH /v1/appInfoLocalizations/<id>`, then
  what `release` didn't reach: copyright and What's New. Approved custom product pages are locked: create a
  new page version and add the locales (`asc product-pages custom-pages versions create` and
  `localizations create`) before `ios.sh page-metadata`, which stops on a page without the locale. Page
  keywords are only accepted for a locale that a released app version has, so `page-metadata` skips them for
  new locales: rerun it once the version is live, then submit the pages. The header and search-results images
  are skipped until `creative/<header|search>_<locale>.png` exists; a large image can stall in processing
  (`UPLOAD_COMPLETE`), so run `creatives` with `ASC_TIMEOUT=300s` (the unit is required).
- **Release notes:** the next `/releaseversion` writes `changelogs/<versionCode>.txt` for every locale; both
  `ios.sh release` and the Play `release` lane abort if one is missing.
- **Play Console:** `android metadata` adds the new languages itself; run it with `dry_run:true` first. After
  `android release` the production track holds the draft next to the live release, so pass
  `version_code:<B>` to `android metadata` and `android screenshots`.

## Guards

- `ios.sh release` never uploads a build number twice: with the build already in App Store Connect it
  asks whether to skip the upload, and on `n` it stops (raise the build number instead). Without a
  terminal it stops as well.
- Release commands abort if the IPA/AAB version differs from `pubspec.yaml` (stale `build/` folder)
  or if `changelogs/<B>.txt` is missing.
- `ios.sh` aborts if the newest App Store version is already submitted, or if an editable version
  with another number exists.
- The Play `metadata` and `screenshots` lanes refuse to run while `play-store/experiments/` holds
  files. Releases are fine.

## Not needed per release

- **Custom product pages** (`app-store/custom-product-pages/`), experiments and the **Kopfzeile** /
  **Suchergebnisse** assets (`app-store/creative/`) aren't tied to a version and stay live; the
  assets are uploaded with `tool/store/ios.sh creatives` (replaces the placements with the PNGs),
  the page text and media with `tool/store/ios.sh page-metadata` and `page-screenshots`. Update them only when screenshots, the screens in the creative
  assets, or the keyword field change (see
  [`app-store/custom-product-pages/README.md`](app-store/custom-product-pages/README.md#when-a-page-needs-an-update)).
- Keywords, subtitle and description: edit the `.txt` files, then `ios.sh release` or
  `ios.sh metadata` ships them.

## Raising the minimum supported build

Builds below the Remote Config value `min_supported_build` open on a full-screen gate with **Update**
and **Export backup** instead of the app (see
[#108](https://github.com/jonaskeller14/bike_setup_tracker/issues/108)). It stays `0` unless one of
these forces it:

- **A backend contract change** that old builds can't handle, such as the Strava string IDs in
  [#112](https://github.com/jonaskeller14/bike_setup_tracker/issues/112) Phase 3.
- **A client bug that corrupts data.**

Before raising it:

1. **Check adoption.** In Firebase Analytics, look at active users by app version, and in
   Crashlytics at users per version. Everyone below the new value gets the gate.
2. **Check the OS floor.** The new minimum build mustn't need a newer iOS deployment target
   (`IPHONEOS_DEPLOYMENT_TARGET`, 15.0 today) or Android `minSdk` (`flutter.minSdkVersion` in
   `android/app/build.gradle`) than the builds it blocks, or those devices can't update and only
   have the export.

Raising it: in the Firebase console, **Remote Config** → `min_supported_build` → set the build
number → publish. If only one store is affected, add a platform condition (iOS or Android) instead
of changing the default.

When it takes effect: the app fetches the value after every cold start and every return to the
foreground, at most once per hour in release. The gate appears at the first cold start after a fetch,
never while the app is open. So a user gets at most one more session on the old build.

Rollback: set the value back to `0`. A blocked user is let in at the first cold start after the
next fetch, which runs on the gate too.

### Contract migration order

1. Ship the client that accepts both the old and the new shape (and the gate).
2. Wait for adoption.
3. Raise `min_supported_build` to the first build that accepts the new shape.
4. Wait at least a week, so everyone who opens the app in that time is gated before the backend
   changes.
5. Deploy the breaking backend change.
