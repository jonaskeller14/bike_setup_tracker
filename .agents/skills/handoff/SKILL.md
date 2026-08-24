---
name: handoff
description: Emit a paste-ready, self-contained brief to execute ONE GitHub issue phase in a fresh context window
allowed-tools: Read, Grep, Glob, Edit
---

**GitHub workflow:** `$ARGUMENTS` identifies a GitHub issue, optionally followed by a phase number. Read the phase from the issue body and relevant comments. Do not create or update a local plan file under `doc/`; on completion, check the issue boxes and add a progress comment with verification evidence.

Generate a self-contained kickoff brief for a single phase of a GitHub issue, so it can be
executed in a **fresh Claude context window**. `$ARGUMENTS` is the issue URL/number, optionally
followed by a phase number (e.g. `1 3`). Do not create or update a plan file under `doc/`.

## 1. Pick and read the phase
- If a phase number was given, use it. Otherwise **default to the first phase whose
  `**Status:**` is not `✅ Complete`** (the next unfinished phase, top to bottom). If every
  phase is complete, say so and stop.
- State which phase you selected, then locate it in the issue body and read its goal, `**Files:**`,
  checklist,
  `**Verification:**`, and `**Commit:**`.
- Skim the plan's `## Resolved open questions` and `## Feature flag` for any decision that
  constrains this phase, and note earlier phases this one depends on (so the brief can state
  what is assumed already done).

## 2. (Optional) mark it in progress
- Do not edit a local plan file. If requested, update only the issue phase status.

## 3. Print the paste-ready brief
Print ONE fenced ```markdown code block (nothing else around it that the user shouldn't
copy) containing a fully self-contained brief. It must include, in this order:

- **Title:** `Implement Phase <N> — <goal>` and the issue URL (for reference).
- **Context:** 2–4 lines — what the feature is, the relevant decisions/flag, and what
  earlier phases are assumed complete. Enough to work without reading the whole plan.
- **Scope — files to touch:** the concrete paths from `**Files:**`.
- **Steps:** the phase's ordered checklist.
- **Conventions to honor:** a short list — mirror the nearest existing code, style via
  `lib/theme.dart`, overflow-safe & resolution-agnostic UI, tests for non-trivial logic,
  comments only when they add non-inferable value, and **surgical clean-diff edits: change
  only what the task needs, no reformatting of untouched lines** (this repo's rule). Point
  to `CLAUDE.md` for the full list.
- **Verification:** the exact `flutter test` targets / `flutter analyze` / manual checks
  from the phase's `**Verification:**`. Nothing is done until these pass.
- **Out of scope:** do not start other phases or touch files outside the scope list.
- **On completion:** when all verification passes, check this phase's issue boxes and add a
  one-line progress comment with verification evidence; then stage the changes
  and **stop — summarize what changed and ask before committing.** The user reviews every
  diff manually. Only commit once they say so, with `<Commit subject>` (or `/gc`), following
  the repo's commit rules. Never commit as the closing step of the phase on your own.

## Constraints
- The brief must be self-contained: a fresh window with no prior context should be able to
  execute the phase from the block alone (plus reading the named files).
- Only ever read/emit ONE phase. Do not generate code here — this command only produces the
  brief and, optionally, flips the phase to `🔄 In progress`.
- Keep the block tight — it is a kickoff prompt, not a copy of the whole plan.
