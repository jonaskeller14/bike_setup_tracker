---
name: handoff
description: Emit a paste-ready, self-contained brief to execute ONE plan phase in a fresh context window
allowed-tools: Read, Grep, Glob, Edit
---

Generate a self-contained kickoff brief for a single phase of an implementation plan, so it
can be executed in a **fresh Claude context window** without loading the whole plan or this
conversation. `$ARGUMENTS` = the plan doc path, optionally followed by a phase number (e.g.
`doc/20260724_foo_implementation_plan.md` or `… 3`).

## 1. Pick and read the phase
- If a phase number was given, use it. Otherwise **default to the first phase whose
  `**Status:**` is not `✅ Complete`** (the next unfinished phase, top to bottom). If every
  phase is complete, say so and stop.
- State which phase you selected, then locate `## Phase <N>` and read its goal, `**Files:**`,
  checklist,
  `**Verification:**`, and `**Commit:**`.
- Skim the plan's `## Resolved open questions` and `## Feature flag` for any decision that
  constrains this phase, and note earlier phases this one depends on (so the brief can state
  what is assumed already done).

## 2. (Optional) mark it in progress
- In the plan doc, set this phase's `**Status:**` line to `🔄 In progress`. Leave all other
  phases untouched. (Skip if the user asked you not to modify the plan.)

## 3. Print the paste-ready brief
Print ONE fenced ```markdown code block (nothing else around it that the user shouldn't
copy) containing a fully self-contained brief. It must include, in this order:

- **Title:** `Implement Phase <N> — <goal>` and the plan doc path (for reference if needed).
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
- **On completion:** when all verification passes, open `<plan doc>` and set this phase's
  `**Status:**` to `✅ Complete` with a one-line note of what landed; then stage the changes
  and **stop — summarize what changed and ask before committing.** The user reviews every
  diff manually. Only commit once they say so, with `<Commit subject>` (or `/gc`), following
  the repo's commit rules. Never commit as the closing step of the phase on your own.

## Constraints
- The brief must be self-contained: a fresh window with no prior context should be able to
  execute the phase from the block alone (plus reading the named files).
- Only ever read/emit ONE phase. Do not generate code here — this command only produces the
  brief and, optionally, flips the phase to `🔄 In progress`.
- Keep the block tight — it is a kickoff prompt, not a copy of the whole plan.
