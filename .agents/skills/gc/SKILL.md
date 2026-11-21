---
name: gc
description: Commit the currently staged changes with a generated conventional-commit message
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git commit:*)
---

## Codex execution

Delegate this workflow to the project-local `commit-staged` custom agent. It runs on the configured lightweight model; do not execute the commit workflow in the parent agent.

The commit workflow itself is in `.claude/commands/gc.md`. Read that file and follow it exactly, with `$ARGUMENTS` as the optional message hint. Do not keep a copy here.
