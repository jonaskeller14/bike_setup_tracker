# Marketing

Working files for the marketing & growth plan in
[#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69). The issue is the
canonical plan and status tracker; this folder holds the reusable material.

## Layout

| Path | Content | Tracked |
|---|---|---|
| `docs/marketing/links.md` | Campaign-tagged store links per channel | yes |
| `docs/marketing/channels.md` | Posting rules per channel (Phase 4) | yes |
| `docs/marketing/backlog.md` | Evergreen Short topics (Phase 8) | yes |
| `docs/marketing/templates/` | HTML/CSS image templates (Phase 3) | yes |
| `docs/marketing/metrics/` | Store exports and baseline/monthly numbers | **no — gitignored** |
| `tool/marketing/` | Record and render scripts (Phase 3) | yes |
| `tool/marketing/assets/music/` | Licensed music beds | **no — gitignored** |
| `build/marketing/<kit>/` | Rendered media + `POST.md` per kit | no (`build/`) |

## Rules

- **Store metrics never leave `docs/marketing/metrics/`.** No numbers in issues, comments,
  commits or posts — the issue only records decisions ("baseline recorded", "channel X dropped").
- Every public link to a store uses the channel's campaign link from `links.md`, so installs can
  be attributed.
- Reddit and forum posts are posted manually from the maintainer's own account, with the
  developer disclosed. No bots, no second accounts, no automated replies.
