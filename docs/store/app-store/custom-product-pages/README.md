# Custom product pages

App Store only. One folder per page, with plain-text files like [`../metadata/`](../metadata/), so
`git diff` shows exactly what changed. Phase 1b of
[#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69); the file layout is
[#82](https://github.com/jonaskeller14/bike_setup_tracker/issues/82). The header and
search-results assets are in [`../creative/`](../creative/README.md).

| Folder | Audience | Reference name |
|---|---|---|
| [`suspension/`](suspension/) | MTB suspension tuning | `cpp-suspension` |
| [`tire-pressure/`](tire-pressure/) | Road and gravel tire pressure | `cpp-tire-pressure` |
| [`service/`](service/) | Maintenance log | `cpp-service` |
| [`strava/`](strava/) | Strava users (link-only, no keywords) | `cpp-strava` |

## Layout

```
<page>/
  page.txt                       reference_name, url, linked_from (not per locale)
  media_order.txt                iPhone and iPad order as default file names
  <locale>/                      en-US, de-DE
    keywords.txt                 comma-separated, empty for a link-only page
    promotional_text.txt
  en-US/screenshots/             iphone_NN.png, ipad_NN.png (generated, gitignored)
  en-US/app_previews/iphone_61/  preview_N.mp4 (generated, gitignored; only when the order lists previews)
```

- `page.txt` holds one `key: value` line per field. `linked_from` lists channel ids from
  [`docs/marketing/links.md`](../../../marketing/links.md); append `&ct=<channel>` to the URL.
- Text files end with one newline, like `metadata/`; uploads strip it.
- `tool/store/ios.sh page-metadata [--dry-run]` uploads `reference_name`, promotional text and
  keywords (adds and removes only the difference) to each page's editable version. It takes
  seconds, unlike the media upload below.
- `media_order.txt` holds one line per device, e.g.
  `iphone: preview_2, preview_1, 03, 04, 02, 01, 05, 06, 07, 08`. `preview_N` names a default
  preview, `NN` a default screenshot (see [`../../captions/en-US.md`](../../captions/en-US.md)).

## Media

The page media are copies of the default set, never edited by hand and not committed:
`media_order.txt` plus the default files are the source of truth.

```
python tool/store/custom_page_media.py           # copy in page order, remove what the order dropped
python tool/store/custom_page_media.py --check   # exit 1 if a page is out of date
tool/store/ios.sh page-screenshots [--dry-run]   # upload them to each page's editable version
```

- The copies are renamed to `iphone_01`, `ipad_01`, `preview_1`, ... in page order, because App
  Store Connect uploads in filename order.
- Only `en-US` holds media; `de-DE` shows it as well while the screens are English
  ([#18](https://github.com/jonaskeller14/bike_setup_tracker/issues/18)).
- `ios.sh page-screenshots` fills the 6.1″ iPhone and the 13″ iPad slots and empties every other set
  (the 6.5″ slot, or previews a page no longer lists). It needs an editable page version:
  App Store Connect locks a version's media once it was submitted, even after a rejection.
- Header and search-results assets: every page uses the default ones in
  [`../creative/`](../creative/README.md). A page that needs its own variant gets
  `<page>/<locale>/creative/{header,search}.png` (3840×1646 and 3840×2560, RGB, no alpha), rendered
  like the default ones; no page has one yet.

### Why the copies aren't committed

They would be cheap: LFS stores one object per unique content (SHA-256), so a byte-identical copy
adds only a pointer, and only a re-render with different bytes creates a new object (check usage
with `git lfs ls-files -s`). But they hold nothing the order file doesn't, would add about 70 files
to every re-render commit, and could drift from it. Regenerate them after a checkout.

## Rules

- A keyword belongs to **one page only**.
- Assigned keywords can only come from the app's keyword field in [`../metadata/`](../metadata/);
  App Store Connect offers nothing else (not the "Strava Sync" in-app purchase name). Re-check all
  pages when the keyword field changes.
- A page without keywords (`strava/`) only appears through its URL, e.g. in channel posts.
- Media order uses the files of the default page. Only the first positions differ per page; the
  rest follow the default order.
- iPhone screenshots must be 1206×2622 (or 1179×2556) for the 6.1″/6.3″ slot; the exported
  `screenshots/en-US/iphone_0N.png` are 1206×2622, so the default page and the custom pages share one set.
  App previews are 886×1920. The optional 6.5″ slot stays empty.
- Promotional Text ≤170 characters.
- Each folder holds what is live in App Store Connect. Fill in the URL once Apple approves the page.

## Keyword coverage

Keywords that stay on the default product page: `mtb`, `enduro`, `downhill`, `ebike`, `emtb`,
`fahrrad`, and the title/subtitle words. The broad MTB audience lands on the default page, whose
creative assets already lead with suspension.

## When a page needs an update

Custom product pages aren't tied to an app version: an approved page stays live through every
release. Update a page (create a new page version in App Store Connect, then submit it for review
again) only when:
- **Screenshots or app previews change.** Each page holds its own copies, so new default
  screenshots don't reach it. Run `custom_page_media.py`, then `ios.sh page-screenshots`.
- **The keyword field changes** and drops a word that a page uses. Edit `keywords.txt`, then
  `ios.sh page-metadata`.
- **A feature the page promises changes.**

## Product page optimization

Start only once both creative assets are approved and live.

- Up to 3 treatments against the default page, each changing **one placement**: first the
  search-results asset (for example a headline about tire pressure, or a single phone instead of
  two), then the header.
- Run each test 2–4 weeks. Record the hypothesis and "improved / unchanged / worse" in #69; numbers
  stay in the gitignored `docs/marketing/metrics/`.
- Video treatments (3:2 search, 21:9 header) wait for the Phase 3 renderer.
