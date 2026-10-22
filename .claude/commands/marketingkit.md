---
description: Turn a release or a backlog topic into a reviewed marketing kit (re-record, render, contact sheet, post files)
argument-hint: "<release tag, e.g. v1.7.0+45 | backlog topic | monthly>"
allowed-tools: Read, Write, Edit, Grep, Glob, AskUserQuestion, Bash(python3 tool/marketing/*), Bash(python tool/marketing/*), Bash(tool/screenshots/run_ios.sh:*), Bash(flutter test test/screenshots:*), Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(open:*), Bash(git describe:*), Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git tag:*), Bash(gh issue:*)
---

Produce the marketing content for `$ARGUMENTS` with the pipeline in `tool/marketing/README.md`
(Maestro demo flows → `build_kit.py` → contact sheet → post files). The plan is
[#77](https://github.com/jonaskeller14/bike_setup_tracker/issues/77) Phase 10; the maintainer
reviews and uploads, Claude never posts, uploads, stages or commits (`CLAUDE.md`, Git Workflow).

Read first: `docs/marketing/messaging.md` (headline bank, Is / is not), `docs/marketing/brand.md`,
`docs/marketing/channels.md`, `docs/marketing/links.md`, `docs/marketing/posts/README.md`,
`docs/marketing/backlog.md`.

## 0. Resolve the argument

| `$ARGUMENTS` | Mode | Kit name |
|---|---|---|
| a tag like `vX.Y.Z+B` | **release** | `vX.Y.Z` |
| `monthly` | **monthly**: four backlog topics, picked per the backlog's pick rules (≥3 pillars, ≥2 audiences, nothing waiting for a release) | next free `NN_<month>`, e.g. `04_2026-11` |
| anything else | **topic**: the closest `docs/marketing/backlog.md` row; ask if two rows match | next free `NN_<slug>` |

Number kits by listing `docs/marketing/kits/` (`ls`) and taking the next number after the highest
`NN_`. If `docs/marketing/kits/<kit>.json` already exists, stop and ask: a full `build_kit.py` run
clears `build/marketing/<kit>/`, and the old `01_launch` kit's timings fit the v1 recordings.

## 1. Scope

**Release mode**
- `prev` = `git describe --tags --abbrev=0 <tag>^`. Read
  `docs/store/play-store/metadata/{en-US,de-DE}/changelogs/B.txt`: that is the "What's New" text,
  reused as the base of every release post (don't write a second version).
- Read `git diff <prev> <tag> -- lib/ assets/data/ docs/store/` and `git log <prev>..<tag> --oneline`.
  Summarize the user-facing changes.
- **Flag-check every named capability** against `lib/models/app_settings.dart` (a `false` default
  means opt-in: the post says "Switch it on under Settings → Features"; a debug-only feature is
  never posted), and against the iOS/Android split (a store text never names the other platform's
  features).
- Find the affected demo flows: compare the changed screens/widgets against the Flow table in
  `tool/screenshots/README.md` ("Demo clips") and `grep -l <clip> docs/marketing/kits/*.json` for
  the kits that use them. A flow is affected when a screen it records changed.
- Pick the content: a release card and a "what changed" card from a real setup comparison, plus a
  Short per new default-on feature (opt-in features get a Short only when they are the headline of
  the release). Flows that don't exist yet are listed as new.

**Topic / monthly mode**
- Take the row(s) from the backlog: pillar, audience, hook, what it shows, notes. Re-run the pick
  rules and the flag check against the **latest release tag** (`git describe --tags --abbrev=0`).
  A row that fails is reported and skipped, not worked around.

Print the scope: affected clips to re-record, new flows to write, the Shorts and images the kit
will contain, and every row that was skipped and why. `AskUserQuestion` to approve before
anything is recorded.

## 2. Hooks and headlines

Every hook and headline comes from the bank in `messaging.md`. A hook marked `new` in the backlog,
or a release headline, goes into the bank first: EN + DE, an ID in its pillar, bike context in the
line, a question for hooks. No headline repeats a store-funnel headline (Surfaces table).

## 3. Record

For a new or changed flow, follow `tool/screenshots/README.md` (Demo scenarios, Adding a screen):
the flow in `tool/screenshots/flows/demo_*.yaml`, the scenario in `lib/screenshots/demo_scenario.dart`
with a case in `test/screenshots/demo_scenario_test.dart`, selectors from `AutomationIds`. Run
`flutter test test/screenshots` after scenario or data changes. Content rules: ≤3 changed values on
screen, tags off, no fake UI.

Re-recording overwrites `build/marketing/raw/ios/<flow>.mp4`, and other kits cut those files at
fixed timings. Before recording:
- list the exact files that would be overwritten and which kits use them;
- ask (`AskUserQuestion`) before overwriting any that exist, and say when the new take needs the
  other kits re-timed (`/reviewkit` covers that);
- Java 17 on `PATH` (`tool/screenshots/README.md`, Prerequisites).

Then `tool/screenshots/run_ios.sh iphone --demo --flows a,b` (add `--skip-build` only when neither
the app code nor the sample changed). Re-record only the affected flows.

## 4. Write the kit

`docs/marketing/kits/<kit>.json`, in the shape documented in `tool/marketing/README.md` (Kit file);
copy `02_showcase.json` or `03_features.json` as the starting point.
- Time each clip's `segments`, `captions` and `callouts` from a contact sheet of the recording:
  `ffmpeg -i <clip>.mp4 -vf "fps=1,scale=200:-2,tile=6x5" -frames:v 2 sheet_%d.png` into the
  scratchpad, never next to the recordings.
- Each Short: a problem hook (≤1.5 s) from the bank, the action, an on-screen payoff, the end card;
  at least one callout where a single control is the point.
- Images (release mode): `release` and `changed` slides in `carousel` and `square`, a thumbnail.
- Voiceover is optional. If the kit uses it, write `<kit>.vo.md` and the `batch-N.md` texts in
  `tool/marketing/assets/voice/<kit>/` (style rules in `03_features.vo.md`), then **stop**: the
  maintainer generates the MP3s in speechma. Continue after they say the batches exist; check
  them with `python3 tool/marketing/voice.py <kit>/batch-N`.

## 5. Render

`python3 tool/marketing/build_kit.py <kit>` (the kit is new, so the full run clears only its own
folder). It must exit 0; on `FAIL` lines, fix the kit and rebuild, don't continue. It writes
`build/marketing/<kit>/` with the videos, images, `POST.md`, `posts/` and the contact sheet
`sheet.html`.

Check every video frame by frame (1 fps tiles) and fix what you find before showing anything.
Then `python3 tool/marketing/review_kit.py <kit> --open` (the `/reviewkit` page) and hand the
maintainer the path, plus the **Copy feedback** instruction: pasted feedback goes to `/reviewkit`.

## 6. Post files

- `docs/marketing/kits/<kit>.posts.md`: the drafts per channel, in the format of
  `02_showcase.posts.md`. Channels, languages and limits come from `channels.md`: English everywhere
  except the German channel (`mtbnews`), which gets German copy. Release posts reuse the changelog
  text, carry the app version (`{version}`) and only campaign links from `links.md`
  (`{ios:<channel>}`, `{android:<channel>}`).
- Facts a post states: only what step 1's flag check passed. Opt-in features say
  "Switch it on under Settings → Features"; Strava Sync is named as the paid add-on.
- `python3 tool/marketing/build_kit.py <kit> post` to validate the drafts.
- One `docs/marketing/posts/YYYYMMDD_<channel>_<label>.md` per post, `Status: planned`, in the
  format of `posts/README.md`: space them one per day for Shorts and 2–3 days apart for launch-style
  posts; copy the pinned-comment and Retire-when lines from the existing files. They stay untracked
  until the post is up (`posts/README.md`).
- Release mode: add the planned posts to the `vX.Y.Z: Marketing` issue's **Publish** section
  (`gh issue list --search "vX.Y.Z: Marketing in:title"`; `gh issue edit` the body, keeping its
  other items as they are).

## 7. Report

Summarize: the kit and its outputs, what was re-recorded, the post files with dates, rows skipped
and why, and what's open (voice batches, Shorts to re-time, opt-in notes). Remind the maintainer of
the monthly rhythm: review the contact sheet, batch-upload and schedule natively. Backlog topics
that now have a Short: delete their rows from `backlog.md`. Ask before staging or committing.

## Constraints
- Never post, upload, stage or commit. Never overwrite an existing recording or kit without asking.
- Never put store numbers from `docs/marketing/metrics/` into any file, issue or post.
- Never claim the app finds, recommends or tunes a setting (messaging.md, Is / is not).
- No presets, ratings, pressure check, riders or bookmarks in any demo or post.
- No Claude or Co-Authored-By attribution in anything written here.
