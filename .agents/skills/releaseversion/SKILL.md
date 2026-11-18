---
name: releaseversion
description: Prepare a signed Flutter release, open it as a GitHub PR, and publish it once merged
allowed-tools: Read, Edit, Grep, WebFetch, Bash(flutter:*), Bash(git add:*), Bash(git branch:*), Bash(git commit:*), Bash(git describe:*), Bash(git diff:*), Bash(git fetch:*), Bash(git log:*), Bash(git pull:*), Bash(git push:*), Bash(git status:*), Bash(git switch:*), Bash(git tag:*), Bash(gh:*)
---

The canonical instructions for this skill are in `.claude/commands/releaseversion.md`.
Read that file and follow it exactly, with `$ARGUMENTS` as the optional version and `--push` flag. Do not keep a copy here.

In Codex, where that file says `AskUserQuestion`, use `functions.request_user_input` when it is available; otherwise stop and wait for a normal chat reply.
