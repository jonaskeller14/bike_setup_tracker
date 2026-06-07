---
description: Bump app version (patch + build), commit, tag, and generate GitHub + store release notes
argument-hint: "[optional explicit version, e.g. 1.4.0]"
allowed-tools: Read, Edit, WebFetch, Bash(git add:*), Bash(git commit:*), Bash(git tag:*), Bash(git log:*), Bash(git describe:*), Bash(git status:*), Bash(git diff:*)
---

Cut a new release for this Flutter app. Argument (optional): `$ARGUMENTS` = an explicit
version name `X.Y.Z` to use instead of the auto-incremented one.

Follow these steps in order. Do not skip the constraints at the bottom.

## 1. Determine the new version
- Read `pubspec.yaml` and find the `version:` line (format `X.Y.Z+B`).
- New version name: if `$ARGUMENTS` is non-empty, use it as `X.Y.Z`; otherwise increment the
  **patch** (third) number by 1.
- New build number: always increment `B` by 1.
- Examples: `1.3.3+25` with no argument → `1.3.4+26`; with argument `1.4.0` → `1.4.0+26`.

## 2. Update the version in both files
- Edit `pubspec.yaml`: replace the version in the `version:` line. Keep the trailing
  `# TODO: Update AppInfo …` comment intact.
- Edit `lib/utils/app_info.dart`: set `appVersion` = new `X.Y.Z`, `buildNumber` = new `B`
  (as a string), and `releaseDate` = the current month and year in `"Month YYYY"` form
  (e.g. `July 2026`).

## 3. Commit and tag
- Capture the previous tag: run `git describe --tags --abbrev=0`.
- Create the release commit using only the two version files (leave any other working changes
  untouched): `git commit pubspec.yaml lib/utils/app_info.dart -m "Release vX.Y.Z+B"`.
- Create the tag: `git tag vX.Y.Z+B`.
- Match the repo style exactly: commit message `Release vX.Y.Z+B`, tag `vX.Y.Z+B`.

## 4. GitHub release notes
- List user-facing commits since the previous tag: `git log <prevTag>..HEAD --oneline`
  (ignore the just-created `Release …` commit).
- Optionally WebFetch `https://github.com/jonaskeller14/bike_setup_tracker/releases` to mirror
  the current formatting.
- Produce notes in this exact structure and print them in a ```markdown code block:
  - `## Features:` then `- ` bullets with em-dash phrasing for new/changed user-facing features.
  - `## Bugs:` then `- ` bullets for fixes.
  - Footer: `**Full Changelog**: [<prevTag>...vX.Y.Z+B](https://github.com/jonaskeller14/bike_setup_tracker/compare/<prevTag>...vX.Y.Z+B)`
  - Omit purely internal commits (refactor/chore/docs/test/build tooling) unless user-visible.

## 5. App Store / Play Store release notes
- Print a separate, short "What's New" block (plain text, 4–6 bullets), user-focused and free of
  technical jargon (no "refactor", "sealed class", "verification flow", etc.).

## 6. Summary
- Print: the new version, the release commit hash, the tag name, and a reminder that nothing was
  pushed — to publish run `git push && git push --tags`, then create the GitHub release manually
  (the `gh` CLI is not installed here).

## Constraints
- Do NOT `git push`, do NOT create the GitHub release online, do NOT run a build.
- The release commit must contain ONLY `pubspec.yaml` and `lib/utils/app_info.dart`.
- Never add a `Co-Authored-By` line to the commit message.
- For any multi-paragraph message use multiple `-m` flags (avoid PowerShell here-strings).
