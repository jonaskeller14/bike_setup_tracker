---
name: gc-fast
description: Commit the currently staged changes directly with a generated conventional-commit message, without delegating to a subagent
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git commit:*)
---

Commit only the changes that are already staged. Do not stage anything yourself.

## Steps

1. Inspect the staged changes with `git diff --cached --stat` and `git diff --cached`.
   - If nothing is staged, stop and tell the user there is nothing to commit.
   - Scan the staged diff for obvious major errors or typos, such as syntax errors, leftover debug code, obviously wrong identifiers, or misspellings in user-facing strings. If any exist, stop and list them instead of committing. Ignore stylistic nitpicks.
2. If `$ARGUMENTS` is provided, use it as the commit message or a strong subject hint. Otherwise generate a Conventional Commit message in this format:
   `type(scope): summary`
   where `type` is one of `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `perf`, `style`, or `build`. Keep the summary imperative.
   For changes covering multiple substantial sub-changes, use multiple `-m` flags with a concise subject followed by a bullet-list body.
3. If the current branch is `main` or `master`, warn the user and ask for confirmation before committing.
4. Commit only the staged changes with `git commit -m "<message>"`; never run `git add`.
5. Print the result with `git log -1 --format='%h %s'`.

## Constraints

- Never run `git add`, `git push`, or `git commit --amend`.
- Never include a `Co-Authored-By` line or similar attribution.
- Use multiple `-m` flags for multi-paragraph commit messages; avoid PowerShell here-strings.
