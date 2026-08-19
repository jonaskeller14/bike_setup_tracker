# Compare setups header — concept brainstorming

**Date:** 2026-08-19
**Status:** Brainstorming — pick one option per section, then run /plan.

Goal: keep both setup identities visible throughout a comparison without
permanently spending vertical space on sheet-level actions. The pinned identity
must remain compact on a landscape phone, align with the existing A/B language
used by comparison rows and map pins, and leave room for a future tap-to-change
setup interaction.

## What the code already tells us

- `CompareSetups` is one `CustomScrollView`. Its current
  `SetupComparisonHeader` is a pinned `SliverAppBar`, while
  `SetupComparisonSummary` is a normal `SliverToBoxAdapter`. This pins the
  title, Restore B action and close button, but scrolls both setup identities
  away—the inverse of the desired hierarchy.
- The current setup identities already use a compact two-line card: one-line
  setup name, then formatted local date and time. Names and dates are
  overflow-safe, and the current setup has a `CurrentSetupBadge`.
- The Values `SegmentedButton` has already moved into the pinned Values section
  title and now filters only comparison values. It is intentionally outside
  the header redesign.
- Context, Values and Ratings use `PinnedHeaderSliver` section titles inside
  `SliverMainAxisGroup`s. A persistent identity header therefore has to
  coexist with those section headers without covering them or producing an
  incorrect pinned offset.
- The comparison UI already identifies sides as A and B in rows and map pins.
  Adding the same labels to the identity cards removes ambiguity and prepares
  the cards to become setup selectors later.
- The sheet is opened with `isScrollControlled` and `useSafeArea`. It can also
  be dismissed using platform back or the modal drag gesture after the visible
  close action has scrolled away.
- The working tree contains active compare-setups changes. Implementation must
  build on them and avoid reverting or reformatting unrelated edits.

## Product principles

1. Setup identity is comparison context, so A and B remain visible while the
   comparison content scrolls.
2. “Compare setups”, Restore B and Close are sheet actions, so they scroll away
   naturally and are recovered by returning to the top.
3. The persistent area should contain no control that does not apply globally.
4. The compact state retains name, date and time, but setup names stay on one
   line with ellipsis.
5. Future setup selection should be possible without changing the layout or
   adding a permanent dropdown chevron now.
6. Landscape phone use may be tight, but the header must leave meaningful
   scrollable height and must never make the comparison unusable.

---

## A. Sliver composition and persistence

### A1 — Unpinned action bar followed by a pinned identity sliver (recommended)

Keep the current title/action row as the first sliver but remove its pinned
behavior. Render the paired A/B identities as the next, independently pinned
header. Section titles continue below it and pin against the remaining content
area.

```text
At top                              After scrolling
┌──────────────────────────────┐    ┌──────────────────────────────┐
│ Compare setups  Restore B  × │    │ A Setup name │ B Setup name │ ← pinned
├──────────────┬───────────────┤    │   date/time  │   date/time  │
│ A Setup name │ B Setup name  │    ├──────────────────────────────┤
│   date/time  │   date/time   │    │ VALUES             [filter] │ ← section
├──────────────┴───────────────┤    │ comparison content…          │
│ CONTEXT                      │    │                              │
```

**Pros:**

- Directly matches the desired scroll hierarchy: actions disappear, identities
  persist.
- Keeps the sheet actions easy to reach by scrolling to the top without adding
  duplicate controls.
- Separates global comparison identity from section-local controls.
- Can reuse most of the current widgets and styling with a surgical refactor.

**Cons:**

- Requires deliberate interaction between the identity sliver and existing
  pinned section headers so they stack rather than overlap.
- The setup identities occupy their full compact height for the entire scroll.
- The missing-setup error state needs a decision about whether an empty
  identity header should exist; it should likely retain only the normal
  scroll-away action bar and error content.

### A2 — One collapsing SliverAppBar with actions in the expanded area

Put actions and identities into one expanded app bar. As it collapses, remove
the title/actions and retain only the A/B identities at the minimum extent.

**Pros:**

- Produces a single continuous collapse animation.
- One sliver owns the entire header stack.
- Can create a polished transition between expanded and compact states.

**Cons:**

- More custom layout and state logic for a result that does not require an
  animated transformation.
- Expanded/minimum extents become sensitive to text scale and narrow widths.
- Future card press behavior is harder to keep semantically clean inside a
  flexible-space layout.
- Higher regression risk than the simple two-sliver hierarchy.

### A3 — Header outside the CustomScrollView

Place the A/B cards above an `Expanded(CustomScrollView)` and keep them fixed
independently of slivers. Leave the title/actions at the beginning of the
scrollable content.

**Pros:**

- Fixed identities cannot be displaced by section header behavior.
- Simple mental model for a permanently visible header.

**Cons:**

- Splits one sheet into separate fixed and scrollable layout regions.
- Safe-area, modal sizing and shrink-wrap behavior become more fragile.
- Returning to the top would not restore the action bar above a fixed header in
  a natural reading order.
- Less consistent with the existing sliver-based sheet.

**Recommendation: A1.** The desired behavior is a hierarchy change, not a
complex visual transformation. Two consecutive slivers express that hierarchy
directly and leave future setup selection localized to the identity cards.

---

## B. Compact identity layout

### B1 — Two compact cards with inline A/B labels (recommended)

Retain the existing paired cards and two-line content. Add a small, fixed-width
`A` or `B` marker at the start of each card, with name/current badge on the
first line and date/time on the second line. Keep the marker visually aligned
with map pins and paired comparison panels.

```text
┌──────────────────────┐  ┌──────────────────────┐
│ A  Unnamed Setup     │  │ B  Finale Ligure…    │
│    19 Aug · 07:23    │  │    18 Aug · 14:53    │
└──────────────────────┘  └──────────────────────┘
```

**Pros:**

- Preserves the requested name plus date/time in a short two-line card.
- Makes A/B mapping explicit everywhere comparison values or pins are shown.
- Retains equal horizontal weight for the two comparison sides.
- Leaves a natural full-card tap target for future setup selection.

**Cons:**

- The A/B marker consumes some width on narrow devices.
- A long name plus `CurrentSetupBadge` has less available space and will
  ellipsize sooner.
- The label style needs enough contrast to be useful without competing with
  setup names.

### B2 — A/B labels above the two cards

Add a small `A` / `B` caption above each existing card while retaining its
current contents.

**Pros:**

- Preserves the full card width for setup names.
- Creates clear column headers for all comparison content below.
- Easy to style with existing label typography.

**Cons:**

- Adds a third text line and therefore more permanent vertical height.
- The label may appear detached from the card during quick scrolling.
- Weaker landscape fit than an inline label.

### B3 — A/B badges overlaid on card corners

Overlay a compact circular or pill badge on each card rather than reserving
layout width.

**Pros:**

- Keeps nearly all horizontal width for name and date.
- Visually echoes labeled map markers.
- Can be visually distinctive at a small size.

**Cons:**

- Risks covering content or requiring extra internal padding.
- Harder to scale cleanly with accessibility text sizes.
- An overlay can suggest a map marker or status rather than a column identity.

**Recommendation: B1.** Inline labels are compact, accessible, and structurally
clear. Use theme colors and typography rather than a high-emphasis custom badge.

---

## C. Future setup-selection affordance

### C1 — Make the whole card pressable now with subtle material feedback (recommended)

Structure each identity as a Material tap surface with clipped ink/pressed
feedback, but show no dropdown chevron. Until setup selection is implemented,
the callback can remain absent so the cards do not falsely announce an active
control; the same visual structure accepts an `onTap` callback later without a
layout change.

**Pros:**

- Meets the desired subtle, visually quiet interaction direction.
- Future selection needs no new permanent icon or header reflow.
- A full-card target will be easier to use than tapping only the setup name.
- Material pressed-state behavior fits the existing app.

**Cons:**

- With no callback in the first implementation, users will not yet discover
  that setup switching is planned—which is accurate because it is not usable.
- Once enabled, discoverability depends on experimentation unless onboarding or
  semantics explains the action.
- Card semantics must change from a label/group to a button only when selection
  is actually available.

### C2 — Enable a no-op or informational press immediately

Make cards visibly pressable now and show a message that setup selection is not
available yet.

**Pros:**

- Starts teaching users that the identities will be interactive.
- Makes the planned interaction discoverable without a chevron.

**Cons:**

- A control that cannot complete its implied action is frustrating.
- Adds temporary behavior and tests that should later be removed.
- Does not improve the current comparison task.

### C3 — Keep plain containers and convert them later

Leave the identity cards completely non-interactive until the setup picker is
implemented.

**Pros:**

- Smallest immediate change.
- No risk of implying functionality that does not exist.

**Cons:**

- The later picker work must replace the card primitive and verify its layout
  again.
- Easy to accidentally build the new visual structure in a way that is awkward
  to make accessible as a full-card button.

**Recommendation: C1.** Prepare the component API and Material surface now,
but only expose interactive semantics and feedback when a real selection
callback exists.

---

## D. Landscape and constrained-height behavior

### D1 — One compact header at every orientation (recommended)

Use the same two-line paired identity layout everywhere. Keep vertical padding
tight but tap-target-aware, constrain names to one line, and let width—not
orientation—drive ellipsis. Do not add a separate landscape-only mode.

**Pros:**

- Predictable design and test surface across portrait, landscape and tablet.
- The fixed area remains approximately one compact card row rather than an
  action row plus identity row.
- Landscape stays possible even if portrait remains more comfortable.
- Avoids orientation branches and abrupt relayout during rotation.

**Cons:**

- On a very short landscape phone, even a two-line pinned row plus a pinned
  section title consumes a noticeable share of the viewport.
- Long names will ellipsize despite extra landscape width when the Current
  badge is present.

### D2 — Reduce the pinned header to one line in short viewports

When available height is below a threshold, hide date/time and retain only A/B
plus setup names.

**Pros:**

- Maximizes comparison height on short landscape phones.
- Still preserves basic setup identity.

**Cons:**

- Conflicts with the requirement to retain both name and date/time.
- Introduces a height breakpoint that may feel arbitrary.
- Removes useful disambiguation exactly where names are likely to ellipsize.

### D3 — Allow the identities to scroll away in landscape

Pin A/B only in portrait; landscape uses a completely scrolling header.

**Pros:**

- Maximizes content height in landscape.
- Simple per-orientation behavior.

**Cons:**

- Violates the primary requirement in one supported orientation.
- Users lose setup context while comparing values.
- Rotation changes the core interaction model.

**Recommendation: D1.** Keep the product rule consistent and optimize spacing
instead of removing information. Verification should include a short landscape
viewport to ensure at least one useful content region remains scrollable below
the pinned identity and current section title.

---

## E. Visual separation and elevation

### E1 — Surface-colored pinned band with cards and bottom divider (recommended)

Keep the surrounding pinned band on `colorScheme.surface`, retain the existing
`surfaceContainerHighest` cards, and add a subtle divider at the bottom. Let
normal Material scroll-under treatment provide any needed separation.

**Pros:**

- Closely matches the current theme in light and dark modes.
- Clearly separates persistent comparison context from scrolling content.
- Requires no hardcoded colors or bespoke shadow.
- The two cards remain the visual focus rather than the band itself.

**Cons:**

- A divider plus the next pinned section title may create closely spaced
  horizontal rules.
- Needs device review to ensure scroll-under content does not visually bleed
  through.

### E2 — Elevated floating card pair

Place the two identities in one elevated container that appears to float over
the scrolling comparison.

**Pros:**

- Strongly communicates that setup identity remains persistent.

**Cons:**

- Adds visual weight to an element intended to be compact and quiet.
- Nested individual cards inside an elevated parent can look busy.
- Less consistent with existing section headers and cards.

### E3 — Flat two-column text header without cards

Remove the card backgrounds and render A/B, names and dates directly on the
surface band.

**Pros:**

- Lowest visual and vertical weight.
- Can read like stable comparison column headings.

**Cons:**

- Loses the clear hit area needed for future setup selection.
- Long text and Current state are harder to group cleanly.
- Larger departure from the current visual language.

**Recommendation: E1.** It preserves the current card identity, provides a
future tap surface, and keeps the refactor visually restrained.

## Recommended combination

- **A1:** unpin the sheet action bar and follow it with an independently pinned
  identity sliver.
- **B1:** retain two compact two-line cards and add inline A/B labels.
- **C1:** make the identity component structurally ready for an optional
  full-card tap, without advertising unavailable behavior.
- **D1:** use one compact, overflow-safe layout in portrait and landscape.
- **E1:** use the themed surface band, existing card treatment and a subtle
  bottom divider.

This combination gives the header one persistent responsibility: identifying
the two setups. It does not retain sheet actions or the Values filter. The
future setup picker can be introduced by supplying per-card callbacks and
accessible labels such as `Change setup A` without changing header geometry.

## Scope for the implementation plan

1. Split the current header responsibilities into a scrolling sheet action
   sliver and a pinned A/B identity sliver.
2. Refactor the identity card to accept its side label and an optional future
   press callback while keeping inactive semantics honest.
3. Define the pinned stacking behavior with Context, Values and Ratings section
   headers, including the Values filter already present in its title.
4. Preserve the missing-setup state and Restore B visibility rules.
5. Extend widget tests to verify:
   - title, Restore B and Close scroll away;
   - both A/B identities remain visible after a long scroll;
   - A/B labels, names and formatted date/time are present;
   - long names ellipsize without overflow at narrow widths;
   - the pinned identity does not overlap the active section title/filter;
   - portrait, short landscape and wide layouts remain scrollable;
   - light/dark themes and larger text scale remain legible;
   - no interactive semantics are exposed until an `onTap` exists.
6. Perform device-level visual review with long setup names, a Current badge,
   Restore B present/absent, and the Values filter in both states.

## Open questions for the final plan

No product decision is blocking the recommended implementation. The final plan
can treat these details as visual tuning rather than new feature decisions:

- exact inline A/B label treatment (plain label, muted pill, or small circle),
  chosen using existing theme tokens and narrow-width review;
- exact pinned band padding and divider treatment after testing a short
  landscape viewport;
- whether future setup selection will allow changing A and B symmetrically or
  retain special baseline/candidate rules. This does not affect the header
  refactor as long as each card accepts an independent optional callback.
