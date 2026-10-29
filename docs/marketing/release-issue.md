# Release marketing issue

`/releaseversion` opens one issue per release, titled `vX.Y.Z: Marketing`, with the body below.
Keep every section; where a section has nothing to do, its only line is `- Nothing for this release.`
Each post and account gets one item that names its file, which holds the text, media and steps.
Tick items as they're done and keep the files in [`posts/`](posts/README.md) and `accounts/` in step.

````markdown
Part of #69. Release notes: [`B`](https://github.com/jonaskeller14/bike_setup_tracker/blob/main/docs/store/play-store/metadata/en-US/changelogs/B.txt)

Text, media and steps per item: `docs/marketing/posts/` and `docs/marketing/accounts/`.

## Content
- [ ] Run `/marketingkit vX.Y.Z+B`: it drafts the release posts in `docs/marketing/kits/<kit>.posts.md` (only features that are on by default), renders the kit and its contact sheet, and writes one `posts/` file per post
- [ ] Create the YouTube playlist `vX.Y.Z`

## Accounts
- [ ] `<channel>`: <create, or the bio/description text to change> (`accounts/<channel>.md`)

## Publish
- [ ] DD.MM. `<channel>` · <label> (`posts/YYYYMMDD_<channel>_<label>.md`)

## Once live
- [ ] DD.MM. `<channel>` · <label>: <step that needs the post to be public, e.g. pin the comment>
- [ ] Post files: set `Status: live` and the URL, then commit them

## Retire
- [ ] `<post file>`: <its "Retire when", met by this release>
````
