# Posts

One file per post, so the current state of every account can be read from the repo. Drafts stay in
`kits/<kit>.posts.md`; `build_kit.py` renders them to `build/marketing/<kit>/posts/`, and the
release's marketing issue (see [`release-issue.md`](../release-issue.md)) lists one todo per file.

A `planned` file stays untracked until the post is up; commit it with the status it then has.

File name: `YYYYMMDD_<channel>_<label>.md`, dated the day it goes live. `<channel>` is the channel
id from [`links.md`](../links.md); `<label>` is kebab-case.

```markdown
# <channel> · <label>

- Status: planned | scheduled | live | unlisted | deleted
- URL: <post URL, or — before it's up>
- Posted: YYYY-MM-DD (the planned or scheduled date before it's up)
- App version: X.Y.Z
- Playlist: vX.Y.Z (YouTube videos only)
- Kit: <kit>
- Media: <files to upload, while planned>
- Retire when: <condition that makes the post outdated, e.g. "a feature it shows changes">

## <Field>
```

Below the header, one `## <Field>` heading per field, each followed by a ```` ```text ```` block
holding the text exactly as it is (or will be) live. When a post is edited on the platform, edit the
file; when it is unlisted or deleted, set the status and keep the file.
