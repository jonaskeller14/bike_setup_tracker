---
description: Explore a feature/change and prepare a brainstorm as a GitHub issue comment (no code)
argument-hint: "<GitHub issue URL or number, OR a topic description if no issue exists yet>"
allowed-tools: Read, Grep, Glob, Bash(date:*), Bash(ls:*), Bash(gh issue:*), Write, WebFetch
---

GitHub Issues are canonical. Read the issue body/comments and prepare the brainstorm as an issue comment; do not create a new planning file under `doc/`. The issue body owns status/checklists, while comments own rationale and Mermaid architecture diagrams.

Produce a brainstorm for `$ARGUMENTS` as a comment on a GitHub issue, using existing
brainstorm docs only as historical style reference.
This is a thinking step: **do not write or change any app code.**

## 0. Resolve or create the issue
- If `$ARGUMENTS` is an issue URL/number, use that issue (`gh issue view <n>`).
- Otherwise, brainstorming is likely the *first* step for this idea and no issue exists yet:
  create one with `gh issue create --title "<short title derived from the topic>" --body ""`
  (empty body — `/issueplan` fills it in later once decisions are made), then treat
  `$ARGUMENTS` as the topic and proceed. Tell the user the new issue number/URL.

## 1. Ground it in the codebase first
- Before proposing anything, find the parts of the app this touches: relevant models,
  DAOs, widgets/sheets, actions, and any existing doc in `doc/` on an adjacent topic.
- Note real constraints you find (existing patterns, migrations, feature flags, platform
  guards) so the options are grounded, not generic.

## 2. Prepare the issue comment
- Do not create a local planning file.
- Structure it like the existing concept docs:
  - `# <Topic> — concept brainstorming`
  - `**Status:** Brainstorming — pick one option per section, then run /issueplan.`
  - A short problem statement / goal.
  - **Lettered decision areas** (`## A. …`, `## B. …`) for each independent design choice.
    Under each, list numbered options (`### A1 — …`, `### A2 — …`). **Every option must
    have an explicit `**Pros:**` and `**Cons:**` bullet list** — no bare prose. Mark your
    suggestion `(recommended)`.
  - **Collapsible decisions:** wrap the body of each lettered decision area (everything under
    its `## X. …` heading, up to the next heading) in a `<details open>` block. Keep the
    `## X. …` heading visible above it. The first line inside is
    `<summary>Status: 🟡 Open — pick one option</summary>`. Leave a blank line after
    `<summary>` and before `</details>` so GitHub renders the Markdown inside:

    ```
    ## A. <Decision area>

    <details open>
    <summary>Status: 🟡 Open — pick one option</summary>

    ### A1 — …
    **Pros:**
    - …
    **Cons:**
    - …

    ### A2 — … (recommended)
    …

    </details>
    ```

    `/issueplan` closes these blocks once the decisions are locked in.
  - `## Recommended combination` — the option letters you'd pick and why, phased if useful.
  - `## Open questions for the final plan` — anything the user must decide before /issueplan.

## 3. Hand back
- Ask the user to confirm or adjust choices. After confirmation, run `/issueplan` to write
  implementation phases and acceptance checkboxes into the issue body.

## Constraints
- No app code, no dependency changes, no migrations — this step only writes the doc.
- Keep options honest and grounded in what the code actually does; call out unknowns
  rather than inventing behavior.
- Mirror the existing docs' tone and structure; don't invent a new template.
