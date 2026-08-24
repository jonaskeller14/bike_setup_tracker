---
description: Explore a feature/change in a GitHub issue and prepare an issue comment (no code)
argument-hint: "<GitHub issue URL or number>"
allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(ls:*), Write, WebFetch
---

GitHub Issues are canonical. Read the issue body/comments and prepare the brainstorm as an issue comment; do not create a new planning file under `doc/`. The issue body owns status/checklists, while comments own rationale and Mermaid architecture diagrams.

Produce an **issue comment** for the GitHub issue supplied in `$ARGUMENTS`, using existing
brainstorm docs only as historical style reference.
This is a thinking step: **do not write or change any app code.**

## 1. Ground it in the codebase first
- Before proposing anything, find the parts of the app this touches: relevant models,
  DAOs, widgets/sheets, actions, and any existing doc in `doc/` on an adjacent topic.
- Note real constraints you find (existing patterns, migrations, feature flags, platform
  guards) so the options are grounded, not generic.

## 2. Prepare the issue comment
- Do not create a local planning file.
- Structure it like the existing concept docs:
  - `# <Topic> — concept brainstorming`
  - `**Status:** Brainstorming — pick one option per section, then run /plan.`
  - A short problem statement / goal.
  - **Lettered decision areas** (`## A. …`, `## B. …`) for each independent design choice.
    Under each, list numbered options (`### A1 — …`, `### A2 — …`). **Every option must
    have an explicit `**Pros:**` and `**Cons:**` bullet list** — no bare prose. Mark your
    suggestion `(recommended)`.
  - `## Recommended combination` — the option letters you'd pick and why, phased if useful.
  - `## Open questions for the final plan` — anything the user must decide before /plan.

## 3. Hand back
- Ask the user to confirm or adjust choices. After confirmation, update the issue body with
  implementation phases and acceptance checkboxes.

## Constraints
- No app code, no dependency changes, no migrations — this step only writes the doc.
- Keep options honest and grounded in what the code actually does; call out unknowns
  rather than inventing behavior.
- Mirror the existing docs' tone and structure; don't invent a new template.
