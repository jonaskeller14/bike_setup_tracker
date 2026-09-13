---
description: Prepare a signed Flutter release, open it as a GitHub PR, and publish it once merged
argument-hint: "[optional explicit version, e.g. 1.4.0] [--push to skip the PR and push main directly]"
allowed-tools: Read, Edit, Grep, WebFetch, AskUserQuestion, Bash(flutter:*), Bash(git add:*), Bash(git branch:*), Bash(git commit:*), Bash(git describe:*), Bash(git diff:*), Bash(git fetch:*), Bash(git log:*), Bash(git pull:*), Bash(git push:*), Bash(git status:*), Bash(git switch:*), Bash(git tag:*), Bash(gh:*)
---

Cut a new release for this Flutter app. Argument (optional): `$ARGUMENTS` = an explicit
version name `X.Y.Z` to use instead of the auto-incremented one, and/or `--push` to skip the
PR and push straight to `main` (only when explicitly requested — the default is a PR).

Follow these steps in order. Never commit, tag, push, build a signed artifact, open a PR, or
create a GitHub release until the applicable confirmation gate has been approved.

## 1. Determine the new version
- Read `pubspec.yaml` and find the `version:` line (format `X.Y.Z+B`).
- New version name: if `$ARGUMENTS` gives an explicit version, use it as `X.Y.Z`; otherwise
  increment the **patch** (third) number by 1.
- New build number: always increment `B` by 1.
- Examples: `1.3.3+25` with no argument → `1.3.4+26`; with argument `1.4.0` → `1.4.0+26`.

## 2. Typo review (abort gate — runs before any files are touched)
- Capture the previous tag: run `git describe --tags --abbrev=0`.
- Review everything that changed since that tag, including the working tree:
  `git diff <prevTag> -- lib/ README.md doc/ assets/ test/ ':(exclude).claude/**' ':(exclude).agent/**'`.
  Exclude the bundled `.claude/**` and `.agent/**` skill files — they are third-party and not ours
  to fix.
- Read the diff and look for **typos** in:
  - user-facing strings (`Text(...)`, snackbars, dialog/button labels, error messages, enum labels),
  - store/README copy, and
  - code comments and identifiers.
  Misspellings in user-visible strings (e.g. `'Tash'` for `'Trash'`, `occured` for `occurred`) are
  the priority.
- **If you find any typo: STOP here. Do NOT update the version, commit, or tag — nothing should be
  edited yet.** Print a table of each typo with its `file:line`, the wrong text, and the suggested
  fix, then ask the user to fix them (or confirm they want to proceed anyway) before re-running.
  Only continue to step 3 when the review is clean or the user explicitly waives a finding.
- If the diff is large enough that you delegate this review to a subagent, have that same subagent
  also summarize the user-facing changes it saw (new/changed features, fixed bugs, feature-flag
  state — e.g. "debug only, not exposed yet") while it's already reading every file. Bring that
  summary back for use in steps 6–7 instead of inferring notes from commit subjects alone, and
  cross-check it against `git log <prevTag>..HEAD --oneline` (step 6) so nothing gets missed and
  nothing gets attributed to the wrong commit. Commit subjects alone are not a reliable source for
  release notes — they routinely overstate what's actually user-visible (e.g. a feature still gated
  behind a debug flag, or a doc claiming a UI element that was never added).

## 3. Branch readiness and PR confirmation
- Record the current branch.
  - If it is **not** `main`, it already holds every commit since the last release and becomes
    the PR head as-is — no local merge into `main`, no push to `main`.
  - If it **is** `main`, there's nothing to PR against itself: create a small
    `release/vX.Y.Z+B` branch off `main` to hold just the version-bump commit.
- Use `AskUserQuestion` before doing anything else, to confirm the plan: which branch will be
  the PR head, and that this cuts a **PR into `main` by default** — never push to `main`
  directly unless the user explicitly asked for `--push` in `$ARGUMENTS` or earlier in the
  conversation. If declined, stop.
- **Tell the user the PR must be merged with "Create a merge commit."** Squash or rebase merges
  create a new commit SHA on `main`, which would invalidate the exact commit this run built,
  tested, and will tag later.
- On the current branch/HEAD, run `flutter clean`, then `flutter pub get`. This refreshes the
  build environment and installs `pubspec.lock` versions; it does not upgrade dependency
  versions. Run `flutter analyze` and `flutter test`, stopping on failure.
- If `--push` was explicitly requested: skip the PR entirely — switch to `main`, fast-forward
  from `origin/main`, merge the source branch into `main`, and push `main` directly instead of
  opening a PR. Everything else below (build order, tagging, release) still applies, just
  without the PR/merge-wait steps.

## 4. Update the version in both files
- Edit `pubspec.yaml`: replace the version in the `version:` line. Keep the trailing
  `# TODO: Update AppInfo …` comment intact.
- Edit `lib/utils/app_info.dart`: set `appVersion` = new `X.Y.Z`, `buildNumber` = new `B`
  (as an int), and `releaseDate` = the current month and year in `"Month YYYY"` form
  (e.g. `July 2026`).
- If the release ships a major feature users would not discover on their own, add a
  hint to `releaseHintBuilds` in `lib/models/app_hint.dart` with build `B`.

## 5. Create the release commit
- Commit only the two version files (plus `app_hint.dart` if touched) with
  `Release vX.Y.Z+B`. This commit is local only so far — not pushed yet.

## 6. Build before opening the PR
- Run `flutter build appbundle --release` and verify
  `build/app/outputs/bundle/release/app-release.aab`. On macOS also run
  `flutter build ipa --release` and verify the IPA under `build/ios/ipa/`.
- **If either build fails, stop.** Do not push the branch or open the PR — report the failure
  so it can be fixed on the exact commit that would otherwise ship.

## 7. GitHub release notes
- List user-facing commits since the previous tag: `git log <prevTag>..HEAD --oneline`
  (this already includes the just-created `Release …` commit's parent range correctly since
  the release commit itself has no user-facing content).
- Cross-reference this list against the change summary gathered in step 2 (if a subagent produced
  one) — that's what tells you whether a commit's feature actually shipped to users or is still
  behind a debug flag.
- Optionally WebFetch `https://github.com/jonaskeller14/bike_setup_tracker/releases` to mirror
  the current formatting.
- Produce notes in this exact structure and print them in a ```markdown code block:
  - `**Features:**` then `- ` bullets with em-dash phrasing for new/changed user-facing features.
    Include developer-relevant work here too when it materially affects the project: architecture
    changes, important refactors, migrations, performance work, CI/coverage, and tooling. Make
    these bullets specific enough for another developer to understand the change and its impact.
  - `**Bugs:**` then `- ` bullets for fixes.
  - Footer: `**Full Changelog**: [<prevTag>...vX.Y.Z+B](https://github.com/jonaskeller14/bike_setup_tracker/compare/<prevTag>...vX.Y.Z+B)`
  - Cover the full release diff rather than a selective subset of commits. Include prototypes,
    feature-flagged work, removed packages, and developer-impacting changes when relevant, but
    explicitly label their shipping state so the notes never imply that an unreleased feature is
    generally available.
  - Use only the `**Features:**` and `**Bugs:**` headers; do not add a separate Development,
    Performance, or Internal section.

## 8. App Store / Play Store release notes
- Print a separate, concise "What's New" block, user-focused and free of technical jargon (no
  "refactor", "sealed class", "verification flow", etc.), inside its own ``` code block (plain
  text, not markdown) so it's easy to copy-paste as-is. Keep each language's complete release-note
  text at **500 characters or fewer**, including bullets, punctuation, and line breaks. Report the
  character count beside each generated language block.
- **Platform-specific split:** check whether this release contains changes that only apply to one
  store's platform.
  Genuinely platform-bound examples: iOS-only — Siri / Apple Shortcuts, App Attest, Apple Sign-In,
  Live Activities; Android-only — Play Integrity, predictive back gesture, Material You / dynamic
  color theming. If the release has such changes, print **two separate "What's New" blocks, each in
  its own ``` code block** — one labeled **App Store (iOS)** and one labeled **Play Store
  (Android)** — and put each platform-specific bullet only in the matching block. The Play Store
  notes must never mention iOS-only features (e.g. no "Improved Siri / Apple Shortcuts
  integration"), and the App Store notes must never mention Android-only features. Shared bullets
  appear in both.
- If the release has no platform-specific changes, print a single combined "What's New" code block
  as before.

## 9. Push the branch and open the PR
- Push the branch: `git push -u origin <branch>`.
- Open the PR: `gh pr create --base main --head <branch> --title "Release vX.Y.Z+B" --body-file <notes-file-from-step-7>`.
- Save the exact GitHub release notes from step 7 in a temporary UTF-8 Markdown file if not
  already saved; this file is the single source of truth for the eventual GitHub release notes
  too — revise it after user feedback and pass it unchanged to `gh release create` later.
- Print the PR URL alongside the release notes and store-note blocks from steps 7–8.

## 10. Wait for the merge, then tag and publish
- Use `AskUserQuestion` to ask: has the PR been merged into `main` using "Create a merge
  commit", and are the release notes approved as printed (or with edits)? Do not proceed until
  confirmed — this may span an arbitrary amount of real time while the PR is reviewed.
- Once confirmed: `git fetch origin main`, `git switch main`, `git pull --ff-only origin main`.
- Verify the exact release commit from step 5 is reachable on `main` (its SHA is unchanged by
  a merge commit). If it is not found — e.g. because the PR was squashed or rebased instead —
  **stop and report this**; do not guess at or re-tag a different commit.
- Tag it: `git tag vX.Y.Z+B <sha>` (lightweight, no `-a`/`-m`). Push only the tag:
  `git push origin vX.Y.Z+B`. Never push `main` — it was already updated by the merged PR.
- Create and verify the draft release using the built assets from step 6: `gh release create
  vX.Y.Z+B <assets...> --verify-tag --draft --title "vX.Y.Z+B" --notes-file <notes-file>`, then
  `gh release view`. Never publish the draft automatically.

## Constraints
- **Default is a PR into `main`, never a direct push** — a direct push only happens if `--push`
  was explicitly given in `$ARGUMENTS` or requested elsewhere in the conversation.
- The PR must be merged via "Create a merge commit"; the skill verifies the release commit's SHA
  survives on `main` before tagging, and stops rather than tagging a squashed/rebased substitute.
- Build (AAB, +IPA on macOS) happens **before** the PR is opened, so build failures surface
  pre-review instead of after merge.
- The step 2 typo review is a hard gate: if it finds anything, abort before editing/committing/tagging
  and surface the findings — do not silently fix typos and continue.
- The release commit must contain ONLY `pubspec.yaml`, `lib/utils/app_info.dart` (and
  `lib/models/app_hint.dart` if a hint was added).
- Release tags must be lightweight and message-free; GitHub release notes are their only
  human-readable release description.
- Never silently resolve merge conflicts, force-push, or overwrite a release asset.
- Never log, commit, or expose signing credentials, keystores, `key.properties`,
  Firebase configuration, or `.env` values.
- Never add a `Co-Authored-By` line to the commit message.
- For any multi-paragraph message use multiple `-m` flags (avoid PowerShell here-strings).
