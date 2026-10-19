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
| 1 | `tool/store/ios.sh release` | Uploads the IPA, creates or finds the App Store version, attaches the build, sets text, review notes, copyright and What's New |
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

## Guards

- Release commands abort if the IPA/AAB version differs from `pubspec.yaml` (stale `build/` folder)
  or if `changelogs/<B>.txt` is missing.
- `ios.sh` aborts if the newest App Store version is already submitted, or if an editable version
  with another number exists.
- The Play `metadata` and `screenshots` lanes refuse to run while `play-store/experiments/` holds
  files. Releases are fine.

## Not needed per release

- **Custom product pages** (`app-store/custom-product-pages/`), experiments and the **Kopfzeile** /
  **Suchergebnisse** assets (`app-store/creative/`) aren't tied to a version and stay live; they
  are managed in the consoles. Update them only when screenshots, the screens in the creative
  assets, or the keyword field change (see
  [`app-store/custom-product-pages/README.md`](app-store/custom-product-pages/README.md#when-a-page-needs-an-update)).
- Keywords, subtitle and description: edit the `.txt` files, then `ios.sh release` or
  `ios.sh metadata` ships them.
