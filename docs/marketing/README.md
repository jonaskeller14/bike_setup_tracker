# Marketing

Working files for the marketing & growth plan in
[#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69). The issue is the
canonical plan and status tracker; this folder holds the reusable material.

## Layout

| Path | Content | Tracked |
|---|---|---|
| `docs/marketing/messaging.md` | Positioning, pillars, audiences, headline bank (EN + DE) and which surface uses which headline (#77) | yes |
| `docs/marketing/brand.md` | Brand guide: look, logo, color, type, safe areas, end card, callouts, do's and don'ts (#77) | yes |
| `docs/marketing/brand/reference/` | Reference frames of the picked design direction; new templates match them (#77) | yes |
| `docs/marketing/links.md` | Campaign-tagged store links per channel | yes |
| `docs/marketing/accounts/<channel>.md` | Live profile text per account (bio, description, links) | yes |
| `docs/marketing/posts/` | One file per post with its text, media and status | yes, once posted |
| `docs/marketing/release-issue.md` | Template for the `vX.Y.Z: Marketing` issue `/releaseversion` opens | yes |
| `docs/marketing/channels.md` | Posting rules per channel (Phase 4) | yes |
| `docs/marketing/backlog.md` | Evergreen Short topics with pillar, audience and hook; `/marketingkit` builds them (#77 Phase 10) | yes |
| `.claude/commands/marketingkit.md` | `/marketingkit <release tag \| backlog topic \| monthly>`: re-record, render, contact sheet, post files (#77 Phase 10) | yes |
| `docs/marketing/templates/` | HTML/CSS templates: video backgrounds, end card, posts (4:5, 1:1), banners, channel art; brand tokens in `marketing.css` (#77) | yes |
| `docs/marketing/kits/` | One JSON per content kit: clip edits, captions, Shorts, images (Phase 3); `<kit>.posts.md`: post drafts per channel (Phase 4) | yes |
| `docs/marketing/metrics/` | Store exports and baseline/monthly numbers | **no — gitignored** |
| `tool/marketing/` | Record and render scripts (Phase 3) | yes |
| `tool/marketing/assets/music/` | Licensed music beds | **no — gitignored** |
| `build/marketing/<kit>/` | Rendered media + `POST.md` (index) and `posts/` (one checklist file per post) per kit | no (`build/`) |

## Monthly rhythm

About 20 minutes of the maintainer's time (#77 Phase 10):

1. `/marketingkit monthly`: Claude picks four topics from [`backlog.md`](backlog.md), records the
   flows that don't exist yet, renders the kit and writes the planned post files.
2. Review the kit's `sheet.html` (or the `/reviewkit` page) and paste the feedback back.
3. Batch-upload the approved Shorts and schedule them natively (YouTube Studio, Meta Business
   Suite, TikTok web), then set `Status: scheduled` and commit the post files.

Every release does the same with `/marketingkit vX.Y.Z+B`, which `/releaseversion` offers as its last
step.

**Optional monthly review:** copy the store and channel numbers into `docs/marketing/metrics/` (private).
The only thing that leaves that folder is a keep/drop decision for a channel or a topic, recorded in
#77 or #69.

## Rules

- **Store metrics never leave `docs/marketing/metrics/`.** No numbers in issues, comments,
  commits or posts — the issue only records decisions ("baseline recorded", "channel X dropped").
- Every public link to a store uses the channel's campaign link from `links.md`, so installs can
  be attributed.
- Reddit and forum posts are posted manually from the maintainer's own account, with the
  developer disclosed. No bots, no second accounts, no automated replies.
