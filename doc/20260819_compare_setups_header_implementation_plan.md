# Compare setups header — implementation plan

**Date:** 2026-08-19
**Status:** Approved concept → phased implementation plan
**Concept doc:** `doc/20260819_compare_setups_header_concept.md`

Locked decisions: **A1** (scrolling sheet action bar + independently pinned
identity sliver) + **B1** (two compact cards with inline plain A/B labels) +
**C1** (each card is an independent Material/InkWell surface prepared for a
future optional callback, with no chevron) + **D1** (the same two-line,
one-name-line layout in portrait and landscape) + **E1** (surface-colored band,
existing neutral card treatment and bottom divider). The dedicated Restore B
action is removed; restoration of either side belongs in the future per-card
setup dialog. Current setups use the existing `CurrentSetupHighlight` bar and
tint instead of a width-consuming badge.

The Values `SegmentedButton` remains exclusively in the pinned Values section
title and is not moved or redesigned by this work. No model, repository,
service, DAO, migration, dependency or generated-file change is required.

---

## Resolved open questions

### A/B treatment → inline plain labels

Place a fixed-width `A` or `B` text label at the leading edge inside each setup
card. Use themed label typography and `colorScheme.onSurfaceVariant`; do not add
a pill, circle, overlay or dropdown chevron. Keep the label column narrow and
align the setup name and date/time to its right.

Rationale: this is B1's most compact treatment, matches the A/B language already
used by comparison rows and map pins, and spends less horizontal space than a
decorated badge.

### Pinned band spacing → compact fixed values

Use `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` around the paired
cards, an 8 px gap between cards, the cards' existing 8 px internal padding and
a 1 px bottom divider. The surrounding band uses `colorScheme.surface`; cards
keep `surfaceContainerHighest` and their current 12 px corner radius.

Rationale: reducing the current 12 px top inset to 8 px keeps the persistent
area compact without compressing the two requested text lines. The divider
provides scroll separation without adding a bespoke shadow or elevation.

### Future setup selection and restoration → two independent InkWell surfaces

Build each identity card as `Material` + clipped `InkWell` with its own optional
callback. The first delivery passes no callbacks, so the cards expose no false
button semantics and do not react as disabled controls. Later work can wire A
and B independently to a dialog that offers both selecting another setup for
that side and restoring that side as current.

Rationale: selection and restoration both operate on one comparison side. One
card-owned entry point avoids a dedicated B-only action and keeps the sheet
action bar simple and symmetrical.

### Restore action → remove the dedicated button now

Remove `Restore B`, its tooltip/semantics, the header callback and the sheet's
restore method. The scrolling action bar contains only `Compare setups` and
Close. Do not add Restore A, an overflow menu or a placeholder dialog in this
phase.

Rationale: a dedicated Restore B action gives one comparison side special
treatment and adds visual weight to a row that should scroll away. Restoration
returns later through the same per-card dialog as setup selection.

### Current setup treatment → reuse `CurrentSetupHighlight`

Remove `CurrentSetupBadge` from the identity cards. For whichever side is
current, reuse `lib/widgets/current_setup_highlight.dart`: a 4 px primary left
bar plus the existing 8% primary tint. Clip the highlight and InkWell to the
card's 12 px radius so the bar/fill cannot escape the card shape.

Rationale: this matches `SetupListTile`, preserves horizontal space for the
setup name beside the inline A/B label, and communicates current state without
adding text to an already narrow row.

### Landscape behavior → retain both lines

Keep setup name and formatted date/time visible in short landscape viewports.
Names remain one line with ellipsis; do not introduce an orientation-specific
collapse or allow the identities to scroll away.

Rationale: identity remains essential comparison context in every orientation.
Landscape may be less comfortable than portrait, but it must remain usable.

---

## Feature flag

**None.** This changes the hierarchy and presentation of an existing sheet; it
does not introduce optional product behavior. The future setup-selection
callbacks/dialog remain absent, so there is no unfinished feature to gate.

---

## Phase 1 — Scroll-away actions and pinned A/B identities

**Goal:** make only the two compact setup identities persistent, retain their
name/date/time context at narrow and landscape sizes, prepare each card for a
future independent selection/restore dialog, replace the Current badge with the
shared bar/tint treatment, simplify the action row, and protect the existing
section-local Values filter behavior.

**Status:** ✅ Complete

**Landed:** The action row now scrolls away while clipped A/B identity cards stay pinned, independently callback-ready, and stacked above section headers.

**Files:**

- `lib/widgets/compare_setups/setup_comparison_header.dart` *(modify)*
- `lib/widgets/sheets/compare_setups.dart` *(modify)*
- `test/widgets/sheets/compare_setups_harness.dart` *(modify)*
- `test/widgets/sheets/compare_setups_test.dart` *(modify)*

- [ ] Split the current header responsibilities without changing the sheet's
      overall `CustomScrollView`: keep `SetupComparisonHeader` as the first
      `SliverAppBar`, but make it non-pinned so `Compare setups` and Close leave
      the viewport with normal upward scrolling. Remove Restore B entirely so
      the action bar contains only `Compare setups` and Close.
      Preserve `automaticallyImplyLeading: false`, theme colors and close-button
      spacing.
- [ ] Remove the obsolete `onRestoreB` API from `SetupComparisonHeader`,
      `_restoreSetupB` from `_CompareSetupsState`, and imports that become
      unused (including `setup_actions.dart` and `current_setup_badge.dart` if
      no other code in those files needs them). Do not add Restore A, an
      overflow action or a placeholder dialog; the future per-card dialog is
      out of scope.
- [ ] Replace the normal `SliverToBoxAdapter` around
      `SetupComparisonSummary` with a dedicated pinned identity sliver (rename
      the widget to reflect its persistent-header responsibility if that makes
      the call site clearer). Its child is a surface-colored band with 16 px
      horizontal/8 px vertical padding, the two equally expanded cards with an
      8 px gap, and a 1 px divider at the bottom.
- [ ] Keep the identity sliver immediately after the scrolling action sliver
      and before the `SliverSafeArea` content. Verify that the existing Context,
      Values and Ratings `PinnedHeaderSliver`s paint below the identity band
      rather than covering or displacing it. Use the existing sliver primitives
      before introducing a custom `SliverPersistentHeaderDelegate`; only add a
      delegate if rect-based tests prove the standard pinned headers cannot
      maintain the required obstruction/stacking behavior.
- [ ] Extend the identity-card input with a required side label (`A` or `B`)
      and an optional `VoidCallback`. Render the label in a fixed-width leading
      column using theme label typography and `onSurfaceVariant`. Keep the setup
      name on one line with ellipsis, keep the formatted local date/time on one
      line with ellipsis, and remove `CurrentSetupBadge` from the name row.
- [ ] Change each card from a decorated `Container` to a `Material` using
      `surfaceContainerHighest`, 12 px border radius and clipping, with an
      `InkWell` sharing the same radius around the padded content. Wire separate
      optional callbacks for A and B; leave both null at the current
      `CompareSetups` call site. Do not add chevrons, placeholder dialogs,
      snackbars or no-op presses.
- [ ] When a side's setup is current, apply the existing
      `CurrentSetupHighlight` inside the clipped card surface so it gets the
      shared 4 px primary left bar and 8% primary tint used by
      `SetupListTile`. Keep non-current cards on the neutral
      `surfaceContainerHighest` treatment. Reuse the shared widget/constants;
      do not duplicate its bar width, fill alpha or colors.
- [ ] Give the identity band and both cards stable keys so scroll persistence,
      rect relationships and future callback semantics can be tested without
      relying on visual widget types. Retain the existing
      `compare-identity-a` / `compare-identity-b` keys unless moving them is
      necessary; if moved, keep each key on the complete tap surface.
- [ ] Preserve the missing-setup path: it continues to render the scrolling
      action bar and error hint, but no pinned A/B identity cards because one or
      both identities cannot be truthfully shown. Do not alter its message or
      dismissal behavior.
- [ ] Leave `_ValueFilter`, `_sectionTitle`, Context filtering and the current
      compare-setups projection untouched. In particular, the Values filter
      must remain a descendant of the Values `PinnedHeaderSliver` and must not
      enter the identity band.
- [ ] Extend `CompareSetupsHarness.wrap` and the local `pumpComparison` helper
      with an optional height so tests can render a short landscape-like
      viewport (for example 700 × 320) without changing existing test defaults.
- [ ] Replace the outdated test that expects the title to stay pinned and the
      identities to disappear. After scrolling a long comparison, assert that
      `Compare setups` and Close are no longer visible while both identity-card
      keys and their A/B labels remain visible. Assert `Restore B` is absent
      before and after scrolling because the action no longer exists.
- [ ] Add header-content assertions for both setup names, both formatted
      date/time values and the current-state styling. Assert that
      `CurrentSetupHighlight` is a descendant only of the current identity and
      that no `CurrentSetupBadge` appears in the header. Scope A/B label
      assertions to their card keys so map markers or comparison panels cannot
      produce false positives.
- [ ] Add a rect-based pinned stacking test after scrolling into Values: the
      identity band's bottom must be at or above the Values header's top, and
      both must remain within the viewport. Also assert the Values filter is
      still inside the Values pinned header and remains operable in Changes and
      All states.
- [ ] Extend the existing long-name/responsive test to cover 320 px width and a
      short landscape-like viewport. Assert no Flutter exception/overflow,
      both identities remain visible after scrolling, and comparison content
      can still scroll below the pinned identity plus current section header.
- [ ] Add a widget-level callback/semantics test for the identity primitive:
      with null callbacks it exposes no tappable/button semantics; with distinct
      test callbacks, tapping A invokes only A and tapping B invokes only B.
      This verifies future readiness without enabling setup selection in the
      production sheet.
- [ ] Check the pinned band with a larger text scale in the widget test or
      manual verification. Preserve two text lines and ellipsis without a
      render overflow; do not silently hide date/time to make the test pass.

**Verification:**

- Run `flutter test test/widgets/sheets/compare_setups_test.dart`.
- Run `flutter analyze`.
- Manually open a long comparison in light and dark themes and confirm:
  the title/Close row scrolls away; no Restore button is present; A/B cards stay
  pinned; Context, Values and Ratings headers do not overlap the cards; the
  Values filter still affects Values only.
- Repeat at a narrow portrait width and in landscape with long setup names,
  one current setup rendered with the shared bar/tint treatment, and each side
  current in turn. Confirm the highlight is clipped to the card and at least a
  useful portion of comparison content remains visible and scrollable beneath
  the pinned identity/header stack.
- Scroll back to the top and confirm all sheet actions return in their original
  order and remain tappable.

**Commit:** `feat(compare-setups): pin setup identities while scrolling`

---

## Suggested commit granularity

One commit / small PR is appropriate:

1. `feat(compare-setups): pin setup identities while scrolling` — sliver
   hierarchy, compact A/B Material/InkWell cards, responsive harness support and
   complete widget-test coverage.

Keep this commit limited to the four files listed in Phase 1. Because those
files already contain in-progress compare-setups edits, stage by hunk and verify
the final diff does not revert the Values-filter relocation or unrelated
Context-card work.
