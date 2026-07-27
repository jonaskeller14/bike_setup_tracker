# Setup card → ListTile conversion — implementation plan

**Date:** 2026-07-27
**Status:** Approved concept → phased implementation plan
**Concept doc:** `doc/20260727_setup_tile_conversion_concept.md`

Locked decisions: **A1** (full conversion, tile everywhere) + **B4** (keep the
existing `Stack` body — no `ListTile` rewrite) + **C1** (prominence via the
`titleMedium` bold title only; all secondary text normalized to the other tiles'
12 px) + **D1** (4 px primary left bar + 8 % primary tint for `isCurrent`) +
**E** (`Current` badge stacked *above* the score badge in a trailing `Column`)
+ **F1** (row-level padding removed; every row owns its 16 px) + **G1**
(`SetupGroupCard` → full-bleed section) + **H2** (tile in every call site).
Plus a cross-cutting cleanup: the duplicated `_subtitleRow` / `_metadataRow`
helpers become one shared widget.

No new dependencies, no model/DAO/migration work — this is a widget-layer change
end to end.

---

## Resolved open questions

### Font sizes → one step, at the title only

The setup row keeps `titleMedium` bold (16 px) for its title while the other
event tiles are `dense: true`, which makes `ListTile` force title 13 px /
subtitle 12 px. That is a real, visible step and it is the *only* prominence
mechanism the setup row gets once the card is gone. Everything below the title —
subtitle row, metadata rows, notes — **drops from 13 px to 12 px** (icons 13 →
12 with it), matching every other tile.

Rationale: hierarchy should be carried by one step in the type scale, at the
level that is actually scanned. A row that is bigger at *both* levels reads as
"zoomed in", not "more important". The secondary content is literally identical
across row types (time, bike, place, weather, tags), so rendering it at 13 px in
one row and 12 px in the next is exactly the mismatch a divided list makes
obvious — the baselines in that column stop lining up. It also frees horizontal
space, which the badge column needs.

### `Current` + score badges → trailing `Column`, spaced *(superseded, see deviation 2)*

Title row becomes `Row(Expanded(title), Column(CurrentBadge, gap, ScoreBadge))`
with `crossAxisAlignment: end` on the column, so the two badges stack instead of
competing for width with the title. Both keep `mainAxisSize: min`.

### `isCurrent` bar vs. Strava bar → both drawn in the 16 px left gutter

After **F1** every row's content sits at 16 px, which leaves a 16 px gutter that
both indicators can be painted into as overlays instead of insetting the child:

- `StravaContextWrapper` stops adding `Padding(left: _barWidth + _contentInset)`
  and draws its bar over the gutter at `x = 0..4`. Without this, Strava-wrapped
  rows would land 14 px deeper than every other row — undoing F1 for exactly the
  rows it matters most for.
- `CurrentSetupHighlight` draws its bar at `x = barLeft .. barLeft + 4`, with
  `barLeft` defaulting to `0`. `SetupList` passes `barLeft: 6` when the row also
  has a Strava context, so the two bars sit side by side in the gutter and the
  content never shifts in any combination.

This is ~3 lines of wiring and keeps the ride block unbroken, which matters
because the Strava context feature (`enableTimelineStravaContext`) may or may not
ship — the default path (`barLeft: 0`) is correct on its own.

---

## Deviations from this plan (decided on device during implementation)

1. **One bordered container per *group*, not per member.** A box around every
   member's value block read as a stack of unrelated boxes. Shipped: one
   outlined container wraps the whole member list inside `SetupGroupSection`,
   with a hairline `Divider` between members. The standalone `SetupListTile`
   keeps its values **unboxed**, exactly as before.
   `AdjustmentCompactDisplayList` gained a `contentInset` override (not the
   planned `outerPadding`) so members line their values up at 8 px inside that
   container.
2. **One trailing badge, not a stacked column.** Stacking `Current` above the
   score pushed the subtitle down and opened a gap under the title. Shipped: the
   score badge wins, and `CurrentSetupBadge` only appears when there is no score
   — the bar and tint already mark the current setup.
3. **The Strava activity details page keeps a `Card` per setup row.** There the
   rows sit among other cards rather than in a divided list, so H2 ("tile in
   every call site") is applied to the tile itself, with the card supplied at
   that one call site (`margin: 16/4`, `clipBehavior: antiAlias` so the InkWell
   and the current-setup bar follow the corners).

---

### Group members → bordered value containers instead of dividers *(superseded, see deviation 1)*

The `AdjustmentCompactDisplayList` inside each setup row gets wrapped in a
rounded, **outlined** container (`outlineVariant` border, radius 8, neutral or no
fill). That container is what visually binds a group's members, so
`SetupGroupCard._memberDivider` goes away entirely. The tint stays neutral —
`primary` remains exclusively "this is the current setup" (D1).

`AdjustmentCompactDisplayList` already self-pads by `_outerPadding = 9`
(`_contentInset 16 − _rowIndent 7`) so its rows align at 16 px inside its parent.
Wrapped in a container that adds its own padding, that 9 px stacks. It therefore
gains an optional `outerPadding` override (default unchanged) that the boxed call
site sets to `0`, so existing call sites are untouched.

### Rename → yes

`SetupListCard` → `SetupListTile`, file `setup_list_card.dart` →
`setup_list_tile.dart`. "Card" in the name becomes actively misleading. Four call
sites plus one test comment.

### Dedup scope → subtitle/metadata rows only

`_subtitleRow` is duplicated in four files (`installation_list_tile`,
`replacement_list_tile`, `setup_list_card`, `setup_group_card`) and
`_metadataRow` in two — identical bodies modulo the 12/13 px difference that C1
removes anyway. Those become one shared widget. The three `_buildStatItem`
copies (`rating_entry_list_tile`, `task_entry_list_item`,
`component_stats_card`) have genuinely different signatures and layouts and are
**left alone** — forcing a shared abstraction there would cost more than it saves.

### Group-level `Current` → unchanged

Round 2 of `doc/20260702_setup_list_redesign.md` decided a group is never
"current"; one member is. That stands: `SetupGroupCard` never renders the badge
or bar at group level, only around the current member — which after Phase 3 is
the same `CurrentSetupHighlight` a standalone current setup uses.

---

## Feature flag

**None.** This is a visual refactor of existing rows; there is no new behaviour
to gate. Two existing flags already gate parts of the affected surface and must
keep working in both states:

- `enableTimelineSetupGrouping` — Phase 5's group section (off → single rows only).
- `enableTimelineStravaContext` — the orange bar / `StravaContextWrapper` changes
  in Phase 4 (off → no wrapper at all, `barLeft` always 0).
- `enableTimelineDayHeaders` — the timeline has **two** row-building paths
  (`_daySection` and `_daySliverList`); every padding/divider change in Phase 4
  must land in both.

---

## Phase 1 — Shared tile primitives + secondary-text normalization

**Goal:** one widget for the subtitle/metadata rows every event tile repeats, and
one `Current` badge; setup rows drop to the shared 12 px secondary text (C1). No
structural change yet — after this phase the setup row is still a `Card`.

**Status:** ✅ Done

**Files:**
- `lib/widgets/items/tile_meta_row.dart` *(new)*
- `lib/widgets/current_setup_badge.dart` *(new)*
- `lib/widgets/items/installation_list_tile.dart` *(modify)*
- `lib/widgets/items/replacement_list_tile.dart` *(modify)*
- `lib/widgets/items/setup_list_card.dart` *(modify)*
- `lib/widgets/items/setup_group_card.dart` *(modify)*
- `lib/pages/details/setup_details_page.dart` *(modify)*
- `lib/pages/map_page.dart` *(modify — check its inline current indicator)*

- [ ] Add `TileMetaRow` in `lib/widgets/items/tile_meta_row.dart`: a `const`
      `StatelessWidget` taking `icon`, `text`, `isError = false`,
      `iconColor`, and a `muted = false` flag. `muted: false` reproduces today's
      `_subtitleRow` (icon `onSurfaceVariant`, text `onSurfaceVariant` @ 0.8);
      `muted: true` reproduces `_metadataRow` (both @ 0.6, `iconColor` override
      for the weather glyph). Fixed at **fontSize 12 / icon size 12**, `Row` with
      `mainAxisSize: min`, `spacing: 2`, `Flexible` text with
      `TextOverflow.ellipsis`, `maxLines: 1` — i.e. exactly the current bodies.
- [ ] Replace `_subtitleRow` in `installation_list_tile.dart` and
      `replacement_list_tile.dart` (no visual change — they are already 12 px).
- [ ] Replace `_subtitleRow` + `_metadataRow` in `setup_list_card.dart` and
      `setup_group_card.dart`. **This is where 13 → 12 lands.** Also drop the two
      remaining hardcoded 13 px styles in those files: the time text in the
      subtitle `Wrap` and the `NotesText(fontSize: 13)` call.
- [ ] Add `CurrentSetupBadge` in `lib/widgets/current_setup_badge.dart` — the
      rounded `primary` pill with `onPrimary` bold 12 px text currently
      duplicated in `setup_list_card.dart:46-69` (corner variant, asymmetric
      radius) and `setup_details_page.dart:155-171` (radius 8). Ship the
      **radius-8 standalone** variant; the corner-anchored variant dies with the
      card in Phase 2.
- [ ] Use it in `setup_details_page.dart` and, if it renders its own copy,
      `map_page.dart:164`; delete the local helpers.

**Verification:**
- `flutter test` — full suite. Existing widget tests that assert on icon/text
  sizes in these tiles are the regression net; fix any that legitimately changed
  (setup rows only).
- `flutter analyze` on the changed files.
- Manual (you): setup rows in the timeline still read correctly with the smaller
  secondary text; long bike/place names still ellipsize; details-page badge
  unchanged in light **and** dark.

**Commit:** `refactor(tiles): extract shared meta row and unify secondary text size`

---

## Phase 2 — `SetupListCard` → `SetupListTile`

**Goal:** the setup row loses its `Card` and gains the badge column and the
bordered value container. The `Stack` body stays exactly as it is (B4).

**Status:** ✅ Done

**Files:**
- `lib/widgets/items/setup_list_tile.dart` *(new — git-mv of `setup_list_card.dart`)*
- `lib/widgets/lists/adjustment_compact_display_list.dart` *(modify)*
- `lib/widgets/lists/setup_list.dart` *(modify — call site)*
- `lib/widgets/chips/setup_list_search.dart` *(modify — call site)*
- `lib/pages/details/strava_activitiy_details_page.dart` *(modify — call site + padding)*
- `lib/widgets/items/setup_group_card.dart` *(modify — call sites)*
- `test/widgets/adjustment_compact_display_list_test.dart` *(modify — stale comment)*
- `test/widgets/items/setup_list_tile_test.dart` *(new)*

- [ ] `git mv lib/widgets/items/setup_list_card.dart lib/widgets/items/setup_list_tile.dart`;
      rename `SetupListCard` → `SetupListTile`, `_SetupListCardState` →
      `_SetupListTileState`; update the four call sites and the doc comment in
      `test/widgets/adjustment_compact_display_list_test.dart:102`.
- [ ] In `build()`, replace the `Card(...)` wrapper with the bare
      `InkWell(onTap:) → Stack` it already contains. Keep `_setupListTile(...)`,
      the `Positioned` popup menu, the `Positioned` `ExpandIcon` and the
      `ConstrainedBox(minHeight: 2 * kMinInteractiveDimension)` untouched.
      Drop `clipBehavior`, `margin`, the `shape`/`isCurrent` border and
      `_setupCardCurrentLabel` (the corner badge) — `isCurrent` is Phase 3;
      until then the row shows no current marker, which is a deliberate,
      reviewable intermediate state.
- [ ] Add vertical rhythm the card margin used to provide: the row's own
      `Padding` becomes `fromLTRB(16, 8, embedded ? 4 : 16, 8)` (was
      `(16, 12, …, 0)` with the value list adding `bottom: 8`) so a row's total
      height is stable with and without the value block. Verify against the
      neighbouring tiles' `top: 8 / bottom: 4-8`.
- [ ] Badge column (E): in the title `Row`, replace the inline
      `if (score != null) _scoreBadge(...)` with a trailing
      `Column(mainAxisSize: min, crossAxisAlignment: end, spacing: 4, children:
      [if (setup.isCurrent) const CurrentSetupBadge(), if (score != null)
      _scoreBadge(...)])`, rendered only when at least one badge exists. Title
      stays `Expanded` + ellipsis.
- [ ] Add `final double? outerPadding;` to `AdjustmentCompactDisplayList`
      (default `null` → today's `_outerPadding`), used in its `build()`'s
      `EdgeInsets.symmetric(horizontal:)`.
- [ ] Wrap the adjustment list in the bordered container: `Container(padding:
      EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration:
      BoxDecoration(border: Border.all(color: colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(8)), child: AdjustmentCompactDisplayList(
      …, outerPadding: 0))`, inside the existing `AnimatedSize`. Applies to both
      the standalone and the `embedded` path so group members get it in Phase 5.
      Skip the container when the list renders nothing (collapsed with no
      changes → the `_noChangesHint` path).
- [ ] `strava_activitiy_details_page.dart`: the `ExpansionTile`'s
      `childrenPadding: symmetric(horizontal: 16, vertical: 8)` would now
      double-pad the tile — change to `symmetric(vertical: 8)` (H2).
- [ ] New `test/widgets/items/setup_list_tile_test.dart`, using the provider
      harness from `test/widgets/lists/setup_list_perf_test.dart`
      (`AppDatabase.memory()` + `AppRepository` + `AppSettings` +
      `_EntitledSubscriptionService`):
      - renders **no `Card` ancestor**;
      - `Current` badge appears above the score badge when `isCurrent`, absent
        otherwise;
      - score badge absent when `enableRating` is false;
      - the `ExpandIcon` toggles the value list between changed-only and all
        values;
      - a 200-character setup name at a 320 px surface does not overflow.

**Verification:**
- `flutter test test/widgets/items/setup_list_tile_test.dart` then the full suite.
- `flutter analyze` on the changed files.
- Manual (you): timeline, search overlay and the Strava activity details
  "Setups (n)" section in light + dark; check the value container's border is
  visible but not louder than the row text in dark mode.

**Commit:** `refactor(setup): render setup rows as tiles instead of cards`

---

## Phase 3 — `isCurrent` highlight (D1)

**Goal:** one mechanism — 4 px primary bar + 8 % primary tint — marks the current
setup, whether standalone or inside a group.

**Status:** ✅ Done

**Files:**
- `lib/widgets/current_setup_highlight.dart` *(new)*
- `lib/widgets/items/setup_list_tile.dart` *(modify)*
- `lib/widgets/items/setup_group_card.dart` *(modify)*
- `test/widgets/items/setup_list_tile_test.dart` *(extend)*

- [ ] `CurrentSetupHighlight({required Widget child, double barLeft = 0})` —
      `Stack` with the child at full width (no inset) and a
      `Positioned(left: barLeft, top: 0, bottom: 0, width: 4)` primary bar, over
      a `ColoredBox(primary.withValues(alpha: 0.08))` background. Painting the
      bar **over** the row's 16 px left gutter rather than insetting the child is
      what keeps every row's content at the same x (see resolved questions).
- [ ] `SetupListTile` wraps its own output in `CurrentSetupHighlight` when
      `setup.isCurrent` — including the `embedded` path, so a group member and a
      standalone row look identical for the first time.
- [ ] Delete `SetupGroupCard._member`'s inline `DecoratedBox` (8 % fill + 4 px
      left border) — the tile now owns it. `_member` collapses to just the
      `SetupListTile` call.
- [ ] Add `barLeft` plumbing: `SetupListTile` takes `currentBarLeft = 0.0` and
      forwards it. (The `SetupList` call site that sets it lands in Phase 4.)
- [ ] Extend the Phase 2 test: current row renders the bar + tint; a current
      group member renders the same widget (find `CurrentSetupHighlight` in both
      trees); a group never renders it at group level.

**Verification:**
- `flutter test test/widgets/items/setup_list_tile_test.dart` + full suite.
- `flutter analyze` on the changed files.
- Manual (you): current setup standalone and as a group member look the same;
  the 8 % tint is visible but not muddy in dark mode; the bar does not clash with
  the value container's border.

**Commit:** `feat(setup): mark the current setup with a primary bar and badge`

---

## Phase 4 — Full-bleed rows: 16 px inset + dividers everywhere (F1)

**Goal:** the timeline's content inset drops 32 → 16 and every pair of adjacent
rows gets a divider. This is the phase with the widest blast radius — it touches
every row type.

**Status:** ✅ Done

**Files:**
- `lib/widgets/lists/setup_list.dart` *(modify)*
- `lib/widgets/chips/setup_list_search.dart` *(modify)*
- `lib/widgets/items/strava_context_wrapper.dart` *(modify)*
- `lib/widgets/items/strava_list_tile.dart` *(modify — explicit `contentPadding`)*
- `test/widgets/lists/setup_list_layout_test.dart` *(new)*

- [ ] `setup_list.dart` `_buildRow`: drop the
      `Padding(EdgeInsets.symmetric(horizontal: 16))` wrapper; return the child
      (or the `StravaContextWrapper`) directly. Day headers already bypass it.
- [ ] `_isTileRow`: return `true` for `SetupEntry()` **and** `SetupGroupRow()`
      so setups and groups participate in the divider rule like every other row.
      With every case now `true` the helper can go away entirely — replace the
      separator logic with an unconditional `Divider(height: 1)` between
      consecutive rows in **both** `_daySection` and `_daySliverList`.
- [ ] `strava_context_wrapper.dart`: set `_contentInset = 0` and remove the
      `Padding` around `child` — the bar is painted over the row's own gutter.
      Keep `_barWidth = 4` and the first/last end insets.
- [ ] `setup_list.dart`: pass `currentBarLeft: row.stravaContext != null ? 6 : 0`
      into the `SetupListTile` for `SetupEntry` rows, so the two gutter bars sit
      side by side.
- [ ] `strava_list_tile.dart`: it relies on `ListTile`'s default 16 px
      `contentPadding` when `contentPadding` is null — make that explicit
      (`contentPadding ?? const EdgeInsets.symmetric(horizontal: 16)`) so the
      row's inset can't silently change with a Material default.
- [ ] Audit each row type for its own 16 px: `InstallationListTile` /
      `ReplacementListTile` / `RatingEntryListTile` / `TaskEntryListItem` already
      set `contentPadding: only(left: 16, right: 16, …)` **and** their below-block
      `Padding(left: 16, right: 16)` — no change expected, but confirm each
      renders at 16 and not 0 or 32 after the wrapper is gone.
- [ ] `setup_list_search.dart` mirrors the timeline verbatim (its own
      `Padding(horizontal: 16)` at line 182 and its own `isTileEntry` at line
      163) — apply the identical two changes there.
- [ ] New `test/widgets/lists/setup_list_layout_test.dart`: build a timeline with
      a setup, a Strava activity and an installation on one day and assert
      (a) a `Divider` sits between the setup row and its neighbour, and (b) the
      leading icons of a setup row and a tile row share the same global `dx`
      (i.e. 16 px, not 32 / not misaligned).

**Verification:**
- `flutter test test/widgets/lists/` — new layout test plus the existing
  `setup_list_perf_test.dart`, which asserts widget composition and is the most
  likely thing to break here.
- Full `flutter test`; `flutter analyze` on the changed files.
- Manual (you): with `enableTimelineDayHeaders` **on and off** (two different
  code paths); with `enableTimelineStravaContext` on and off; a current setup
  inside a ride block (two bars, content not shifted); day bands still full-bleed
  and visually distinct from the new full-bleed dividers.

**Commit:** `refactor(setup-list): full-bleed rows at a 16px inset with dividers between all rows`

---

## Phase 5 — `SetupGroupCard` → full-bleed section (G1)

**Goal:** the group stops being the last `Card` in the stream. Header row +
member rows, bound by the members' bordered value containers rather than by a
container or dividers.

**Status:** ✅ Done

**Files:**
- `lib/widgets/items/setup_group_card.dart` → `lib/widgets/items/setup_group_section.dart` *(rename + rewrite)*
- `lib/widgets/lists/setup_list.dart` *(modify — call site)*
- `test/widgets/items/setup_group_section_test.dart` *(new)*

- [ ] `git mv` to `setup_group_section.dart`; rename `SetupGroupCard` →
      `SetupGroupSection` and update the `SetupGroupRow` call site.
- [ ] Drop the `Card` + `clipBehavior`; the widget becomes a
      `Column(crossAxisAlignment: start)` of header row + member rows.
- [ ] Header row: reuse the existing header content (`"n Setups"` title,
      bike / time-range / place / weather in the subtitle `Wrap`) with the same
      `Padding(fromLTRB(16, 8, 16, 8))` rhythm the tiles now use, and
      `TileMetaRow` from Phase 1 for its rows. Per the Round 2 TODO the title
      stays `"n Setups"` with the bike in the subtitle — that is already the
      current behaviour, so this is a padding/typography alignment, not a
      content change.
- [ ] Delete `_memberDivider` and both its call sites — the members' bordered
      value containers (Phase 2) carry the separation.
- [ ] Members render full width (no residual card inset) so their `ExpandIcon`s
      line up vertically — the open item from the Round 2 TODO list.
- [ ] New `test/widgets/items/setup_group_section_test.dart`: renders no `Card`;
      one header row + N member rows; **no** `Divider` between members; the
      current member (and only it) is wrapped in `CurrentSetupHighlight`; the
      single-member shortcut still delegates to a plain `SetupListTile`.

**Verification:**
- `flutter test test/widgets/items/setup_group_section_test.dart` + full suite.
- `flutter analyze` on the changed files.
- Manual (you), with `enableTimelineSetupGrouping` on: does the group still read
  as one unit without its card? If it reads flat, the fallback (not built by
  default) is a slightly heavier `Divider(thickness: 2)` above and below the
  group, or an indent on the member rows — decide on device.

**Commit:** `refactor(setup-group): render setup groups as a full-bleed section`

---

## Suggested commit granularity

One commit per phase, in order — each is independently mergeable and each leaves
the app in a coherent (if intermediate) visual state:

1. `refactor(tiles): extract shared meta row and unify secondary text size`
2. `refactor(setup): render setup rows as tiles instead of cards`
3. `feat(setup): mark the current setup with a primary bar and badge`
4. `refactor(setup-list): full-bleed rows at a 16px inset with dividers between all rows`
5. `refactor(setup-group): render setup groups as a full-bleed section`

Phases 2 and 3 are the pair worth reviewing together on device before moving on:
between them the current setup has no marker at all, so don't ship 2 without 3.
Phase 1 is a safe standalone landing; Phases 4 and 5 are each self-contained and
can be deferred without leaving anything half-done.

## Explicitly out of scope

- No changes to `buildTimelineRows` / `lib/utils/timeline_grouping.dart` — row
  *composition* is untouched; only rendering changes.
- No changes to the calendar page (it renders appointments, not these tiles).
- The `_buildStatItem` triplicate stays as-is (see resolved questions).
- The `//FIXME was 8` chevron padding note in the embedded path
  (`setup_list_card.dart:424`) is a pre-existing nit; fix it only if Phase 2's
  padding rework makes it obviously wrong.
