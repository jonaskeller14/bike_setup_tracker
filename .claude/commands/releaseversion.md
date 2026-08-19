---
description: Prepare, confirm, and publish a signed Flutter release with GitHub assets
argument-hint: "[optional explicit version, e.g. 1.4.0]"
allowed-tools: Read, Edit, Grep, WebFetch, AskUserQuestion, Bash(flutter:*), Bash(git add:*), Bash(git branch:*), Bash(git commit:*), Bash(git describe:*), Bash(git diff:*), Bash(git fetch:*), Bash(git log:*), Bash(git merge:*), Bash(git pull:*), Bash(git push:*), Bash(git status:*), Bash(git switch:*), Bash(git tag:*), Bash(gh:*)
---

Cut a new release for this Flutter app. Argument (optional): `$ARGUMENTS` = an explicit
version name `X.Y.Z` to use instead of the auto-incremented one.

Follow these steps in order. Never merge, commit, tag, push, build a signed
artifact, or create a GitHub release until the applicable confirmation gate has
been approved.

## 1. Determine the new version
- Read `pubspec.yaml` and find the `version:` line (format `X.Y.Z+B`).
- New version name: if `$ARGUMENTS` is non-empty, use it as `X.Y.Z`; otherwise increment the
  **patch** (third) number by 1.
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
  summary back for use in steps 5–6 instead of inferring notes from commit subjects alone, and
  cross-check it against `git log <prevTag>..HEAD --oneline` (step 5) so nothing gets missed and
  nothing gets attributed to the wrong commit. Commit subjects alone are not a reliable source for
  release notes — they routinely overstate what's actually user-visible (e.g. a feature still gated
  behind a debug flag, or a doc claiming a UI element that was never added).

## 3. Branch readiness and merge confirmation

- Releases are cut from `main`. Use `AskUserQuestion` before switching to
  `main`, fast-forwarding it from `origin/main`, or merging a source branch.
  Do not push the source branch as a release branch. If declined, stop; if a
  fast-forward or merge conflicts, stop and report it without improvising a
  resolution.
- On the final `main` history, run `flutter clean`, then `flutter pub get` before
  creating the version commit. This refreshes the build environment and installs
  `pubspec.lock` versions; it does not upgrade dependency versions. Run
  `flutter analyze` and `flutter test`, stopping on failure.

## 4. Update the version in both files
- Edit `pubspec.yaml`: replace the version in the `version:` line. Keep the trailing
  `# TODO: Update AppInfo …` comment intact.
- Edit `lib/utils/app_info.dart`: set `appVersion` = new `X.Y.Z`, `buildNumber` = new `B`
  (as a string), and `releaseDate` = the current month and year in `"Month YYYY"` form
  (e.g. `July 2026`).

## 5. Prepare the release commit and tag
- Reuse the previous tag captured in step 2 (or re-run `git describe --tags --abbrev=0`).
- Do not commit or tag yet. They are created only after the publish confirmation. The version
  commit contains only the two version files and uses `Release vX.Y.Z+B`; create a lightweight
  `vX.Y.Z+B` tag with no annotation message.

## 6. GitHub release notes
- List user-facing commits since the previous tag: `git log <prevTag>..HEAD --oneline`
  (ignore the just-created `Release …` commit).
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

## 7. App Store / Play Store release notes
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

## 8. Publish confirmation and release

- Save the exact GitHub release notes in a temporary UTF-8 Markdown file and
  show them with the store-note blocks. This file is the single source of truth for the GitHub
  release: revise it after user feedback and pass it unchanged to `gh release create`, rather than
  duplicating release content in a tag annotation. Use `AskUserQuestion` to confirm the
  version commit/tag, pushing `main` and the tag, Android AAB build, optional
  macOS IPA build, and creating a draft GitHub release. If declined, stop.
- Commit only the two version files with `Release vX.Y.Z+B`, create the lightweight, message-free
  tag with `git tag vX.Y.Z+B` (never `-a` or `-m`), and push precisely with `git push origin main` then
  `git push origin vX.Y.Z+B`.
- Run `flutter build appbundle --release` and verify
  `build/app/outputs/bundle/release/app-release.aab`. On macOS also run
  `flutter build ipa --release` and attach the IPA from `build/ios/ipa/`; otherwise
  provide `gh release upload vX.Y.Z+B build/ios/ipa/<ipa-file>` for the Mac.
- Create and verify the draft with `gh release create vX.Y.Z+B <assets...>
  --verify-tag --draft --title "vX.Y.Z+B" --notes-file <notes-file>`, then
  `gh release view`. Never publish the draft automatically.

## Constraints
- The step 2 typo review is a hard gate: if it finds anything, abort before editing/committing/tagging
  and surface the findings — do not silently fix typos and continue.
- The release commit must contain ONLY `pubspec.yaml` and `lib/utils/app_info.dart`.
- Release tags must be lightweight and message-free; GitHub release notes are their only
  human-readable release description.
- Never silently resolve merge conflicts, force-push, or overwrite a release asset.
- Never log, commit, or expose signing credentials, keystores, `key.properties`,
  Firebase configuration, or `.env` values.
- Never add a `Co-Authored-By` line to the commit message.
- For any multi-paragraph message use multiple `-m` flags (avoid PowerShell here-strings).
