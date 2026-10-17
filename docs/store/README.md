# Store listings

Text for App Store Connect and Play Console, plus the screenshot sources. The marketing plan and
its status live in [#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69).

## Layout

| Path | Content |
|---|---|
| `app-store/metadata/<locale>/*.txt` | App Store listing text, one plain-text file per field (fastlane layout, read by `asc migrate import`); `copyright.txt` is shared, `review_information/notes.txt` holds the App Review notes |
| `play-store/metadata/<locale>/*.txt` | Play listing text, one file per field (fastlane `supply` layout) |
| `play-store/experiments/<locale>_B/*.txt` | Variant B of a running Play listing experiment; never uploaded |
| `app-store/custom-product-pages/` | One file per custom product page (same fields as `app-store/metadata/`), rules and page tests |
| `app-store/creative/` | Header and search-results assets: HTML sources, shared `creative.css`, rendered PNGs and `README.md` |
| `play-store/metadata/<locale>/changelogs/<versionCode>.txt` | "What's New" text per release for both stores (max. 500 characters), written by `/releaseversion` |
| `release-steps.md` | Upload commands per release and the remaining manual clicks (submit) |
| `captions/<locale>.md` | Screenshot captions, shared by both stores |
| `screenshots.af` | Affinity composition; links the raws and holds the caption layer |
| `app-store/<device>/`, `play-store/<device>/` | Raws (`0N_raw.png`, from `tool/screenshots/`) and the device `frame.png` |
| `app-store/screenshots/en-US/` | Exported App Store screenshots (`iphone_NN.png` 1206×2622, `ipad_NN.png` 2064×2752), uploaded by `ios.sh screenshots` |
| `app-store/app_previews/en-US/iphone_65/` | App previews (`preview_N.mp4`), uploaded by `ios.sh screenshots` |
| `play-store/metadata/<locale>/images/` | Play graphics: `icon.png`, `featureGraphic.png`; export target for `phoneScreenshots/` and `tenInchScreenshots/` |
| `play-store/feature_graphic.html` | Play feature graphic (1024×500): HTML source, rendered to `metadata/<locale>/images/featureGraphic.png`. Same look as the App Store search asset; render with `python tool/marketing/render_images.py play-feature`. `?safe` marks the centre, where Play overlays its play button once a promo video is set |

Previews and screenshots upload in filename order (`preview_1`, `iphone_01`, `iphone_02`, ...), so renaming a file changes the order.

Locales: `en-US` (primary) and `de-DE` (listing text only). Screenshots stay English until the app UI
is translated ([#18](https://github.com/jonaskeller14/bike_setup_tracker/issues/18)); the per-locale
screenshot layout is planned in #69.

## Field rules

| Store | Field | File | Limit | Indexed for search |
|---|---|---|---|---|
| App Store | Title | `name.txt` | 30 | yes |
| App Store | Subtitle | `subtitle.txt` | 30 | yes |
| App Store | Keywords | `keywords.txt` | 100 | yes |
| App Store | Promotional Text | `promotional_text.txt` | 170 | no; editable without review |
| App Store | Description | `description.txt` | 4000 | no |
| App Store | Marketing URL | `marketing_url.txt` | n/a | no; link to the landing page, not indexed |
| App Store | Copyright | `copyright.txt (not per locale)` | n/a | no; "year owner" without ©, same as `LICENSE`. Update the year range in January |
| Play | Title | `title.txt` | 30 | yes |
| Play | Short Description | `short_description.txt` | 80 | yes |
| Play | Long Description | `full_description.txt` | 4000 | yes |

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

## Screenshot sizes

| Folder | Raw `0N_raw.png` | Export |
|---|---|---|
| `app-store/iPhone-17-Pro-Max` | 1320×2868 | `screenshots/en-US/iphone_NN.png`, 1206×2622 |
| `app-store/iPad-Pro-13-inch_M5` | 2064×2752 | `screenshots/en-US/ipad_NN.png`, not checked |
| `play-store/phone` | 1080×2400 | n/a, not checked |
| `play-store/tablet_10-inch` | 1200×1920 | n/a, not checked |

The iPhone exports (`iphone_NN.png`) are 1206×2622, the only size (besides 1179×2556) App Store Connect accepts in the
6.1″/6.3″ slot. One set serves the default page and all custom product pages.
`tool/screenshots/check_output.py` checks both columns where a size is listed.

## App previews

App Store, iPhone only: 886×1920 HEVC, 30 s, 30 fps, recorded with v1.3.7. They are tracked in Git
LFS; commit a preview only once it is live in the store, not every rendered draft.

| File | Shows |
|---|---|
| `preview_1.mp4` | Add a bike and a component with adjustments |
| `preview_2.mp4` | Record a setup |
| `preview_3.mp4` | Analyze setups (component details), then add and complete a task |

## A/B tests

`metadata/` is always the live listing (variant A). While a Play listing experiment runs, variant B
sits in `play-store/experiments/<locale>_B/` with the same file names, and `0N_B.png` exists only
when a screenshot itself differs. The Play `metadata` and `screenshots` lanes refuse to run while
that folder holds files. No files there means no test is running.

- Each test changes one variable.
- When it ends, the winner becomes the live file and the variant B files are deleted.
- The hypothesis and outcome ("improved / unchanged / worse") go in #69. Numbers stay in the
  gitignored `docs/marketing/metrics/`.
