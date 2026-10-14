# Custom product pages

App Store only. One file per page, with the same layout as [`../listing/`](../listing/): one code
block per App Store Connect field, so `git diff` shows exactly what changed. Phase 1b of
[#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69). The header and search-results
assets are in [`../creative/`](../creative/README.md).

| File | Audience | Reference name |
|---|---|---|
| [`suspension.md`](suspension.md) | MTB suspension tuning | `cpp-suspension` |
| [`tire-pressure.md`](tire-pressure.md) | Road and gravel tire pressure | `cpp-tire-pressure` |
| [`service.md`](service.md) | Maintenance log | `cpp-service` |
| [`strava.md`](strava.md) | Strava users | `cpp-strava` |

## Rules

- A keyword belongs to **one page only**.
- Assigned keywords must already be indexed for the app (title, subtitle, keyword field, or the
  "Strava Sync" in-app purchase name). Re-check all pages when the keyword field in
  [`../listing/`](../listing/) changes.
- Media order uses the files of the default page (`preview_N`, `01`–`08`, see
  [`../../captions/en-US.md`](../../captions/en-US.md)). Only the first positions differ per page;
  the rest follow the default order.
- Promotional Text ≤170 characters.
- Each file holds what is live in App Store Connect. Fill in the URL once Apple approves the page.

## Keyword coverage

Keywords that stay on the default product page: `mtb`, `enduro`, `downhill`, `ebike`, `emtb`,
`fahrrad`, and the title/subtitle words. The broad MTB audience lands on the default page, whose
creative assets already lead with suspension.

## When a page needs an update

Custom product pages aren't tied to an app version: an approved page stays live through every
release. Update a page (edit in App Store Connect, then submit it for review again) only when:
- **Screenshots or app previews change.** Each page holds its own copies, so new default
  screenshots don't reach it. Re-upload them in the page's media order.
- **The keyword field changes** and drops a word that a page uses.
- **A feature the page promises changes.**

## Product page optimization

Start only once both creative assets are approved and live.

- Up to 3 treatments against the default page, each changing **one placement**: first the
  search-results asset (for example a headline about tire pressure, or a single phone instead of
  two), then the header.
- Run each test 2–4 weeks. Record the hypothesis and "improved / unchanged / worse" in #69; numbers
  stay in the gitignored `docs/marketing/metrics/`.
- Video treatments (3:2 search, 21:9 header) wait for the Phase 3 renderer.
