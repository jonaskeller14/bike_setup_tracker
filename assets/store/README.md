# Store listings

Text for App Store Connect and Play Console, plus the screenshot sources. The marketing plan and
its status live in [#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69).

## Layout

| Path | Content |
|---|---|
| `<store>/listing/<locale>.md` | Listing text and per-device media order (previews, screenshots) per language, one code block per console field |
| `<store>/listing/<locale>_B.md` | Variant B of a running A/B test: a full copy of the listing with the tested field changed |
| `app-store/review-notes.md` | App Review notes (locale-independent) |
| `captions/<locale>.md` | Screenshot captions, shared by both stores |
| `screenshots.af` | Affinity composition; links the raws and holds the caption layer |
| `app-store/<device>/`, `play-store/<device>/` | Raws (`0N_raw.png`, from `tool/screenshots/`), exported frames (`0N.png`) and app previews (`preview_N.mp4`) |
| `play-store/drawing.*`, `play-store/logo_512_white.png` | Play feature graphic and icon |

Locales: `en-US` (primary) and `de-DE` (listing text only). Screenshots stay English until the app UI
is translated ([#18](https://github.com/jonaskeller14/bike_setup_tracker/issues/18)); the per-locale
screenshot layout is planned in #69.

## Field rules

| Store | Field | Limit | Indexed for search |
|---|---|---|---|
| App Store | Title | 30 | yes |
| App Store | Subtitle | 30 | yes |
| App Store | Keywords | 100 | yes |
| App Store | Promotional Text | 170 | no; editable without review |
| App Store | Description | 4000 | no |
| Play | Title | 30 | yes |
| Play | Short Description | 80 | yes |
| Play | Long Description | 4000 | yes |

- **App Store keywords:** title, subtitle and keywords are indexed together, so no word appears
  twice across them. Comma-separated without spaces. No brand names: Strava is already indexed
  through the "Strava Sync" in-app purchase name, and Fox/RockShox would risk guideline 2.3.7.
- **Play:** no keyword field. The main search terms (mountain bike, MTB, suspension, tire pressure,
  bike maintenance, fork, shock) sit in the first lines and recur a few times in natural sentences.
  No "free", "best" or "#1" in the title.
- **Keep the EULA link at the end of the App Store description.** App Review guideline 3.1.2(c)
  requires a Terms of Use link in the metadata of apps with auto-renewable subscriptions (Strava Sync).
- **Only features that are live in release builds.** Debug-only features in
  `lib/pages/settings/features_page.dart` stay out of the copy until they ship.
- **Subtitle and keyword changes ship with an app version.** Watch the two weeks after the release.

## App previews

App Store, iPhone only: 886×1920 HEVC, 30 s, 30 fps, recorded with v1.3.7. They are tracked in Git
LFS; commit a preview only once it is live in the store, not every rendered draft.

| File | Shows |
|---|---|
| `preview_1.mp4` | Add a bike and a component with adjustments |
| `preview_2.mp4` | Record a setup |
| `preview_3.mp4` | Analyze setups (component details), then add and complete a task |

## A/B tests

Unsuffixed files are always the live listing (variant A). While a test runs, variant B sits next to
it with a `_B` suffix: `listing/en-US_B.md` is a full copy of the listing (so `diff` shows the tested
variable), and `0N_B.png` exists only when a screenshot itself differs. No `_B` file means no test
is running.

- Each test changes one variable.
- When it ends, the winner becomes the unsuffixed file and the `_B` files are deleted.
- The hypothesis and outcome ("improved / unchanged / worse") go in #69. Numbers stay in the
  gitignored `docs/marketing/metrics/`.
