---
description: Turn decided feature work into a phased GitHub issue plan (no code)
argument-hint: "<GitHub issue URL or number>"
allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(ls:*), Write
---

GitHub Issues are canonical. Read the issue body/comments and, after confirmation, write the phased plan into the issue body; do not create a plan file under `doc/`. Use comments for detailed rationale, Mermaid diagrams, and progress evidence.

Turn the decided concept for `$ARGUMENTS` into a concrete **implementation plan in the
GitHub issue**. Do not create a plan file under `doc/`. This is still a planning step:
**do not write or change any app code.**

## 1. Read the decisions
- Read the issue body and relevant architecture/decision comments.
- Extract the chosen option for every lettered decision area and every answer to the
  "Open questions" section.

## 2. Confirmation gate (STOP here)
- Before writing anything, print a short recap: the locked-in decisions (one line each) and
  any open question you still see unanswered.
- **Ask the user: "Are you happy with these decisions? Should I write the plan?"**
- Do NOT create the plan file until the user confirms. If they adjust a decision, update the
  recap and ask again.

## 3. Write the plan into the issue body
- Structure it like the existing implementation plans:
  - `# <Topic> — implementation plan`
  - `**Status:** Approved concept → phased implementation plan`
  - `## Resolved open questions` — the decisions from step 1, each with its one-line rationale.
  - `## Feature flag` — if the feature should land behind a flag / `kDebugMode`, say which.
  - **`## Phase N — <goal>`** for each phase. Size a phase so it lands as **one commit (or
    small PR)** and can be built in a single fresh context window. Each phase contains:
    - `**Status:** ⬜ Not started`
    - `**Files:**` — the concrete files to add/change (real paths).
    - A checklist (`- [ ] …`) of the implementation steps, in order.
    - `**Verification:**` — how to prove the phase works: exact `flutter test` targets to
      add/run, `flutter analyze`, and any manual check (e.g. overflow with long text).
    - `**Commit:**` — the suggested conventional-commit subject for this phase.
  - `## Suggested commit granularity` — the overall commit/PR sequencing across phases.
- Order phases so pure-logic layers (models, DAOs, repository) land before UI, and each
  phase is independently mergeable where possible.

## 4. Hand back
- Print the issue URL and the phase list. 

## Constraints
- No app code — this step only updates issue planning.
- Do not skip the step 2 confirmation gate; the issue body must not be updated before the
  user approves the decisions.
- Every phase must be independently verifiable (its own tests / checks), and follow the
  repo conventions in CLAUDE.md (mirror existing code, overflow-safe UI, tests for
  non-trivial logic).
- Mirror the existing plans' structure; don't invent a new template.
