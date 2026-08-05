---
name: brainstorm
description: Explore a feature/change and write a concept-brainstorming doc in doc/ (no code)
allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(ls:*), Write, WebFetch
---

Produce a **concept-brainstorming document** for `$ARGUMENTS`, matching the style of the
existing brainstorm docs in `doc/` (e.g. `doc/20260717_component_preset_concepts.md`).
This is a thinking step: **do not write or change any app code.**

## 1. Ground it in the codebase first
- Before proposing anything, find the parts of the app this touches: relevant models,
  DAOs, widgets/sheets, actions, and any existing doc in `doc/` on an adjacent topic.
- Note real constraints you find (existing patterns, migrations, feature flags, platform
  guards) so the options are grounded, not generic.

## 2. Write the doc
- Filename: `doc/<YYYYMMDD>_<slug>_concept.md` where `<YYYYMMDD>` is today's date
  (run `date +%Y%m%d`) and `<slug>` is the topic in lower_snake_case. If the user gave an
  explicit filename in `$ARGUMENTS`, use that instead.
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
- Print the file path and a 3–5 line summary: the key decision areas and your recommended
  combination. Then ask the user to confirm/adjust choices before running `/plan`.

## Constraints
- No app code, no dependency changes, no migrations — this step only writes the doc.
- Keep options honest and grounded in what the code actually does; call out unknowns
  rather than inventing behavior.
- Mirror the existing docs' tone and structure; don't invent a new template.
