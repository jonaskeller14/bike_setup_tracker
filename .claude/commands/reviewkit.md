---
description: Build a review checklist page for a marketing kit, then apply the maintainer's pasted feedback
argument-hint: "<kit> [--compare <kit>] — or paste the feedback the page copied"
allowed-tools: Read, Write, Edit, Grep, Bash(python3 tool/marketing/*), Bash(python tool/marketing/*), Bash(ffmpeg:*), Bash(ffprobe:*), Bash(open:*), Bash(git diff:*), Bash(git status:*)
---

Review loop for a content kit built by `tool/marketing/build_kit.py` (docs: `tool/marketing/README.md`).
Nothing gets committed until the maintainer has reviewed it.

## A. `$ARGUMENTS` names a kit: build the review page
1. If `build/marketing/<kit>/manifest.json` is missing or older than the kit file, run a full
   `python3 tool/marketing/build_kit.py <kit>` first. It must exit 0; report `FAIL` lines instead
   of continuing.
2. Write the decisions you need from the maintainer (open questions, plan deviations, tool changes
   worth a look) to `build/marketing/<kit>/review_items.json`: a JSON list of
   `{"key": "decision:<slug>", "title": "…", "html": "<p>…</p>"}`. Skip it if there are none.
3. Run `python3 tool/marketing/review_kit.py <kit> [--compare <older kit>] [--items build/marketing/<kit>/review_items.json] --open`.
   Pass `--compare` when the kit replaces another one (its website loops are shown side by side).
4. Tell the maintainer the page's path, what's on it, and to paste the **Copy feedback** text back.

## B. `$ARGUMENTS` (or the message) is pasted feedback
The lines look like `- [FEEDBACK] Short · core (short:core): <note>`. Only `FEEDBACK` lines need
work; `ok` is approved; `not reviewed` stays open (list them in the summary).

1. Map each key to its sources before changing anything:

   | Key | Change it in |
   |---|---|
   | `short:<name>` | the kit's `shorts.<name>` (title, hook, clips) and its clips' `segments`/`captions`/`callouts`; layout notes → `docs/marketing/templates/video_9x16.html` + `brand.md` + `brand/reference/reference.html` |
   | `hook:<id>` | the headline bank in `docs/marketing/messaging.md`, then every kit that uses the line |
   | `posts:<group>` | `docs/marketing/kits/<kit>.posts.md` |
   | `gif:<clip>`, `web:<clip>` | the clip in the kit; quality settings in `tool/marketing/render_video.py` (`GIF_*`, `WEB_*`) and limits in `build_kit.py` |
   | `appstore:<file>` | `docs/marketing/kits/00_appstore.json` |
   | `image:<file>` | the kit's `images` |
   | `decision:<slug>` | whatever the item asked about |

2. **Feedback about what the app shows** (a value, a selection, an extra tap, a different screen)
   belongs in the demo, not the cut: change the flow (`tool/screenshots/flows/demo_*.yaml`), the
   scenario (`lib/screenshots/demo_scenario.dart` + `test/screenshots/demo_scenario_test.dart`) or
   the master sample data (`assets/data/20260925_sample_simple.json`). Then:
   - find every kit that uses that clip (`grep -l <clip> docs/marketing/kits/*.json`), including
     `00_appstore`, and apply the change there too;
   - re-record only the changed flows: `tool/screenshots/run_ios.sh iphone --demo --flows a,b`
     (Java 17 on `PATH`, see `tool/screenshots/README.md`); without `--skip-build` when the data or
     app code changed;
   - re-time the segments, captions and callouts of the re-recorded clips from a contact sheet
     (`ffmpeg -i <clip>.mp4 -vf "fps=1,scale=200:-2,tile=6x5" -frames:v 2 sheet_%d.png`);
   - run `flutter test test/screenshots` after scenario or data changes.
3. Rebuild each affected kit fully, check the changed videos frame by frame (1 fps tiles), and fix
   what you find before showing anything.
4. Regenerate the review page (step A3). Ticks and notes reset with every rebuild, so the
   maintainer sees a clean page.
5. Summarize per key what changed, what you decided differently and why, and what's still open.
   Ask before staging or committing (`CLAUDE.md`, Git Workflow).

## Constraints
- Every headline and hook comes from `docs/marketing/messaging.md`; a new line goes into the bank
  first.
- Flag-check every capability a caption or post names against the latest release build.
- Never commit, upload or post anything; the maintainer does that.
