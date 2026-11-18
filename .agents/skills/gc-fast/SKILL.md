---
name: gc-fast
description: Commit the currently staged changes directly with a generated conventional-commit message, without delegating to a subagent
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git commit:*)
---

The canonical workflow is in `.claude/commands/gc.md`. Read that file and follow it exactly in this agent, with `$ARGUMENTS` as the optional message hint. Do not delegate it to a subagent. Do not keep a copy here.
