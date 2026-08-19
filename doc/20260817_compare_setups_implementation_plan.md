# Compare setups sheet — implementation plan

**Date:** 2026-08-17
**Status:** Approved concept → phased implementation plan
**Concept doc:** `doc/20260817_compare_setups_concept.md`

Locked direction: a responsive hierarchical comparison matrix that keeps the
existing `Context → Values → Ratings` structure, compares effective values by
strict identity, opens in Differences view, and uses the theme's changed-color
background for differing rows. The normal setup-tile entry point compares a
historical setup with its bike's current setup; explicit callers remain robust
for distinct setups from different bikes.

---

## Resolved open questions

### Primary visualization → hierarchical paired matrix

Keep section and owner hierarchy, then compare only the leaf values side by
side. On phones each leaf uses a full-width label above two equal A/B panels; on
wider screens it becomes `label | A | B`. Do not build synchronized detail
panes, horizontal scrolling or a flat whole-sheet table.

### Default density → Differences first

Every newly opened sheet starts with `differencesOnly = true`; this state is
local to the sheet and is not persisted in `AppSettings`. A single
`Differences / All` control switches modes. Difference filtering removes
unchanged leaf rows and empty groups, but never removes the pinned setup
identities. Group headers report `x of y differ` so hidden content remains
understandable. Identical setups get a designed “No differences” state with a
one-tap Show all action.

### Highlight treatment → changed-color row backgrounds

Use `Theme.of(context).extension<ValueHighlightColors>()!.changedFill` as the
background across the complete differing leaf row (label plus both value
panels), rather than the concept's neutral outline/tint. Keep a `Different`
semantics label (and a compact visible `≠` where it fits) so color is not the
only signal. Dangling/deleted data retains the existing error treatment on the
affected side; the row-level changed fill remains behind it to communicate that
the pair differs.

No theme change is needed: `ValueHighlightColors.changed` and `changedFill`
already provide light/dark-safe orange values.

### Value basis → effective state with provenance

For an adjustment side:

1. if the setup's value map `containsKey(adjustment.id)`, use that explicit
   value (including an explicit `null`/cleared value);
2. otherwise, if the corresponding previous-value map contains the key, use
   the inherited value;
3. otherwise, mark it unavailable.

Compare the effective raw values with `adjustmentValuesEqual`; explicit versus
inherited provenance alone is **not** a difference when the effective values
are equal. Show an understated `Inherited` provenance label where applicable.
Keep unavailable, explicit-cleared, owner-absent, dangling-owner and
deleted-adjustment states distinct.

### Alignment → strict UUID identity only

Join components by `Component.id`, persons by `Person.id`, adjustments/rating
metrics by their UUIDs, and deleted raw values by their stored adjustment ID.
Never match names, normalized names, component types or units heuristically.
When an owner exists on only one side, render a structural-difference owner
card and its actual values on that side; do not fabricate cross-component
deltas.

This applies to different-bike comparisons too. A component physically moved
between bikes can still match because its UUID is stable; unrelated components
remain honestly one-sided.

### Entry-point scope → current baseline normally, explicit cross-bike support

`showCompareSetupsSheet(context, setupA: null, setupB: historical)` resolves A
only to the distinct current setup of `setupB.bike`. It never falls back to an
arbitrary repository setup. The setup-tile Compare action is offered only for a
non-current setup with a resolvable distinct current setup on the same bike.

When both A and B are supplied explicitly, accept different bikes and preserve
the caller's left/right order. Reject equal IDs. No setup picker and no swap
button are required in this iteration. Cross-bike support is defensive API
behavior, not a new user-facing entry point.

### Context → notes and tags visible; location/weather nested

Names and local dates/times stay pinned in the sheet header. Bike and person
are primary Context rows. Notes and enabled tags are rendered immediately in
side-by-side panels, matching their always-visible treatment on
`SetupDetailsPage`; they are never put inside an `ExpansionTile`.

Location and Conditions remain secondary disclosures. Conditions summarize
condition, temperature and weather label, then expand to the fields already
shown by `ContextWeatherCard`: precipitation, humidity, wind and soil moisture.
Do not introduce extra raw API fields that setup details does not display.

### Images → two side-by-side strips

When `AppSettings.enableSetupImages` is enabled and either setup has images,
render one horizontal `ImageStrip` per side inside a single two-column `Row`.
The strips stay left/right even at phone width; never stack them vertically. An
empty side keeps an 80 px-high “No images” placeholder so the strips remain
aligned. Use one `FutureBuilder`/image-directory lookup for both strips.

Add an optional `heroTagPrefix` to `ImageStrip` (default preserves current
behavior) and pass different A/B prefixes. This prevents duplicate Hero tags if
both setup records reference the same filename.

### Ratings → aggregate summary with expandable strict-ID metrics

When ratings are enabled, show each setup's aggregate score and rating-entry
count. Expand to per-metric score rows joined strictly by metric UUID, with the
metric weight shown as in setup details. A score delta is descriptive only; do
not name a winner. Missing scores/metrics get explicit unavailable states.

### Sheet actions → restore B and reuse comparison from setup details

The comparison sheet gets a B-specific `Restore B` tonal action. It reuses the
existing Restore semantics (`SetupActions.duplicateSetup`): copy B into the
duplicate form at the current time, let the user review/edit it, then save the
new setup as current. It is not a silent mutation of the historical setup.
Hide the action when B is already current. After a successful restore, close
the comparison sheet because its original current-baseline context is stale;
after cancellation, keep it open.

In `SetupDetailsSheet`, replace the standalone sheet Edit icon with one compact
overflow menu containing Edit, Restore and Compare; retain the separate Close
button. Edit is always available, Restore only for a non-current setup, and
Compare only when `enableSetupComparison` is on and the strict target resolver
finds a distinct current setup on the same bike. Opening comparison stacks it
above the details sheet so closing comparison returns to the details context.
After a successful Restore, close details. Keep the full-page
`SetupDetailsPage` app-bar behavior unchanged.

---

## Feature flag

Add a persisted `AppSettings.enableSetupComparison` flag, defaulting to
`false`. Expose its toggle in `FeaturesPage` only inside the existing
`if (kDebugMode)` development-feature section, so normal release users have no
settings UI for enabling this unfinished feature.

Guard the setup-tile Compare menu action with **only**
`appSettings.enableSetupComparison` plus the normal comparison eligibility
checks. Do not repeat `kDebugMode` in `SetupListTile`: debug-only availability
comes from where the setting is exposed, while the widget remains driven by
settings state and straightforward to test. Keep the public
`showCompareSetupsSheet` API ungated so direct/internal callers and widget tests
can exercise it independently of the menu rollout.

Continue respecting the existing `enablePerson`, `enableRating`,
`enableSetupTags` and `enableSetupImages` flags for their corresponding
sections.

No dependency, database migration, generated file or platform-specific change
is required.

---

## Phase 1 — Pure comparison projection and target contract

**Status:** ✅ Complete

Implemented the strict UUID-based comparison projection, deterministic target resolution, and focused service coverage.

**Goal:** produce a deterministic, UI-independent comparison tree and safe
implicit/explicit target resolution. No finished sheet UI yet.

**Files:**

- Add `lib/models/setup_comparison.dart`
- Add `lib/services/setup_comparison_service.dart`
- Add `test/services/setup_comparison_service_test.dart`

### Projection model

- [ ] Add immutable comparison types with no `BuildContext` dependency:
  - `SetupComparison` — setup IDs, ordered owner groups, structural/difference
    counts and helpers for filtered views;
  - `SetupComparisonGroup` — component/person/deleted-values kind, stable owner
    ID, per-side owner state, label/icon metadata, ordered rows;
  - `SetupComparisonRow` — stable row ID, label, optional owning `Adjustment`,
    A/B side values, row kind and `isDifferent`;
  - `SetupComparisonSideValue` — raw effective value, provenance/state and
    enough definition metadata for later formatting;
  - enums for value provenance (`explicit`, `inherited`, `unavailable`,
    `dangling`, `deleted`) and owner presence (`installedOrLinked`, `dangling`,
    `absent`).
- [ ] Keep the model generic enough for later context/rating paired rows, but
  do not put theme colors, formatted dates or unit-converted strings into it.
- [ ] Define difference counting once: count differing leaf rows; a structural
  owner change with no leaf rows contributes one difference. Do not double-count
  the group header plus all its rows.

### Strict comparison builder

- [ ] In `SetupComparisonService`, independently call
  `DanglingAdjustmentService.analyzeSetup` for A and B using the full component
  and person collections. Do not reuse B's timestamp-resolved owners for A.
- [ ] Build a union of component groups by exact component UUID. Preserve A's
  repository/component order, then append B-only groups in B order.
- [ ] Within a matched component, build the adjustment union by exact UUID,
  preserving A's adjustment order then B-only order. Although a shared UUID
  normally has one definition, retain the side definition separately so the
  projection is robust to stale/imported data.
- [ ] Build person groups with the same identity and ordering rules. A different
  linked person creates two one-sided groups; it is never matched by name.
- [ ] Merge dangling component/person groups into the same UUID-based owner
  union, recording each side as installed/linked, dangling or absent.
- [ ] Put unrecoverable deleted adjustment values in a dedicated error group,
  keyed and joined only by stored adjustment ID; use the ID as the fallback
  label, matching the information available in setup details.
- [ ] Resolve effective values with `containsKey` so explicit `null` remains
  distinguishable from an absent key. Use bike and person previous maps only in
  their corresponding domains.
- [ ] Set `isDifferent` from effective value equality plus owner/value-state
  compatibility. Use `adjustmentValuesEqual` for list/scalar values. Equal raw
  values remain unchanged if one is explicit and the other inherited.
- [ ] Treat one-sided owners, installed-versus-dangling owners,
  unavailable-versus-recorded values and deleted values as differences.

### Target resolution

- [ ] Add a pure target-resolution function/result:
  - implicit A: select the distinct `isCurrent` setup whose `bike == setupB.bike`;
  - never use `setups.first` or another-bike fallback;
  - explicit A: accept any bike but require `setupA.id != setupB.id`;
  - return a typed unavailable/equal-input result rather than throwing.
- [ ] Keep left/right order stable: A is baseline/left, B is candidate/right.

### Tests

- [ ] Cover explicit versus inherited values: same effective value is unchanged;
  different inherited/effective values differ; explicit null is not absent.
- [ ] Cover every supported adjustment value shape: number, bool, text,
  duration, categorical list and counted/duplicate categorical values.
- [ ] Cover strict identity: same labels/different UUIDs do not match; same UUID
  matches even if a component moved between bikes; two same-type components do
  not collide.
- [ ] Cover installed, dangling, absent-owner and deleted-adjustment groups on
  either side, including a structural group with zero adjustments.
- [ ] Cover person same/different/null cases.
- [ ] Cover deterministic A-first/B-only ordering.
- [ ] Cover target resolution for historical→current, B already current,
  one-setup bike, no current setup, equal explicit inputs and valid explicit
  cross-bike inputs.
- [ ] Format only the newly added Dart files.

**Verification:**

```bash
flutter test test/services/setup_comparison_service_test.dart
flutter analyze
```

**Commit:** `feat(setups): add strict setup comparison projection`

---

## Phase 2 — Sheet shell, responsive paired rows and safe entry point

**Status:** ✅ Complete

Implemented the reactive comparison sheet shell, pinned A/B header, responsive rows, safe entry point, and widget coverage.

**Goal:** replace the empty TODO body with a navigable comparison shell,
pinned identity/orientation, the default Differences filter and reusable row
geometry. Initially it may render projection groups as basic rows; detailed
Context/Values/Ratings content lands in later phases.

**Files:**

- Modify `lib/widgets/sheets/compare_setups.dart`
- Modify `lib/widgets/items/setup_list_tile.dart`
- Add `lib/widgets/compare_setups/setup_comparison_header.dart`
- Add `lib/widgets/compare_setups/setup_comparison_row.dart`
- Add `lib/widgets/compare_setups/setup_comparison_section.dart`
- Add `test/widgets/sheets/compare_setups_harness.dart`
- Add `test/widgets/sheets/compare_setups_test.dart`
- Modify `test/widgets/items/setup_list_tile_test.dart`

### Entry point and lifecycle

- [ ] Keep `showCompareSetupsSheet(BuildContext, {Setup? setupA, required
  Setup setupB})` as the public API, but run Phase 1's resolver before opening
  the modal.
- [ ] For implicit failure (current/equal/no baseline), do not open an empty
  sheet. Surface a concise `SnackBar` only for a direct invocation; the normal
  menu should omit impossible actions.
- [ ] Pass resolved setup IDs into the sheet content and `watch<AppRepository>`
  there so repository updates rebuild from current objects rather than stale
  snapshots. If either setup disappears while the sheet is open, show a clear
  in-sheet error state instead of dereferencing `null`.
- [ ] Continue using `showModalBottomSheet(isScrollControlled: true,
  useSafeArea: true, showDragHandle: true)`. Use a bounded nearly full-height
  body/`CustomScrollView`, not `SingleChildScrollView` around an unbounded
  `Column`.

### Setup-tile action

- [ ] Fix the missing `return false` in the current setup's Compare-menu
  predicate.
- [ ] Omit Compare when the row is current or no distinct current setup exists
  for that bike. Keep the menu action's ordinary path implicit-A so there is no
  extra picker/tap.
- [ ] Extend `setup_list_tile_test.dart` to verify Compare is absent for a
  current/only setup and present for a historical setup with a current peer.

### Pinned header and filtering

- [ ] Make `CompareSetups` stateful with `_differencesOnly = true`; reset to
  true every time a new sheet instance opens.
- [ ] Add a pinned header using the repository's `PinnedHeaderSliver`/
  `SliverAppBar` patterns. It contains:
  - title and close action using existing sheet helpers;
  - equal-width A/B identity cells with one-line ellipsized setup name and
    formatted local date/time;
  - `CurrentSetupBadge` on whichever side is current;
  - total difference count;
  - a `SegmentedButton` or equivalently compact `Differences / All` control.
- [ ] Keep names/dates visible regardless of filtering; do not duplicate them
  as ordinary Context rows.
- [ ] When Differences yields no rows, show an existing-style empty hint with
  “These setups have no differences” and a Show all action.

### Responsive comparison primitive

- [ ] Implement one `SetupComparisonRow` widget used by every later section.
  Use `LayoutBuilder` with a named breakpoint (start at 600 logical px and tune
  during verification):
  - narrow: full-width label, then two equal Expanded A/B panels;
  - wide: label column plus two equal A/B value columns.
- [ ] Make label/value text overflow-safe (`Flexible`, wrapping where useful,
  ellipsis only for identity/header strings). Preserve selectable value text
  where the existing details view uses it.
- [ ] Apply `ValueHighlightColors.changedFill` across a differing row. Add a
  visible compact `≠` and `Semantics(label: 'Different …')`; do not rely on
  background color alone.
- [ ] Give affected dangling/deleted side panels error-container styling while
  retaining the outer changed background.
- [ ] Add keys for sections, groups, rows, filter control and A/B panels so
  widget tests do not depend on fragile text counts.

### Widget tests

- [ ] Build the dedicated harness like `SetupTileHarness`: in-memory database,
  repository created outside the widget-test zone, fixed IDs/dates, required
  providers, explicit settling and disposal.
- [ ] Verify Differences is initially selected, toggling All reveals unchanged
  rows, and an identical projection displays the empty hint/Show all action.
- [ ] Verify header pinning by scrolling a long fixture and asserting the two
  setup identities remain visible.
- [ ] Pump at 320/390 px and 800 px widths; assert the narrow/wide structures
  and no overflow with 200-character setup/adjustment names.
- [ ] Verify differing rows use `changedFill` in both light and dark themes and
  expose `Different` semantics.
- [ ] Verify explicit cross-bike inputs open successfully and implicit
  unresolved/equal inputs do not open the modal.
- [ ] Format only new/modified files from this phase.

**Verification:**

```bash
flutter test test/widgets/sheets/compare_setups_test.dart
flutter test test/widgets/items/setup_list_tile_test.dart
flutter analyze
```

Manual: open a historical setup's menu on a 320 px emulator, confirm Compare
opens directly against Current, header stays pinned, the initial view says
Differences, and orange changed backgrounds remain legible in light and dark.

**Commit:** `feat(setups): add responsive setup comparison shell`

---

## Phase 3 — Debug feature gate, context, visible notes/tags and side-by-side images

**Status:** ✅ Complete

**Goal:** place the setup-tile entry behind a persisted debug-exposed feature
setting, then implement the full Context section with the approved information
priority and two horizontal image strips.

**Files:**

- Modify `lib/models/setup_comparison.dart`
- Modify `lib/models/app_settings.dart`
- Modify `lib/services/setup_comparison_service.dart`
- Modify `lib/pages/settings/features_page.dart`
- Modify `lib/widgets/sheets/compare_setups.dart`
- Modify `lib/widgets/compare_setups/setup_comparison_row.dart`
- Modify `lib/widgets/items/setup_list_tile.dart`
- Modify `lib/widgets/image_strip.dart`
- Modify `test/models/app_settings_test.dart`
- Add `test/pages/settings/features_page_test.dart`
- Modify `test/services/setup_comparison_service_test.dart`
- Modify `test/widgets/items/setup_list_tile_test.dart`
- Modify `test/widgets/sheets/compare_setups_test.dart`

### Debug-exposed feature setting and menu guard

- [ ] Add `_enableSetupComparison = false`, its public getter/setter and
  `_persistBool('enableSetupComparison', value)` handling to `AppSettings`.
  Load the same prefixed key in `loadAppSettings`, matching adjacent boolean
  feature settings exactly.
- [ ] In `FeaturesPage`, add a `Setup Comparison` list tile inside
  `if (kDebugMode)`. Reuse `_offOnOptionWidgets` and
  `appSettingsRadioGroupSheet<bool>`; explain that it exposes comparison of a
  historical setup against the current setup while the feature is experimental.
- [ ] In `SetupListTile`, require
  `appSettings.enableSetupComparison` before including the Compare menu item.
  Keep the Phase 2 rules too: the setup must be non-current and have a distinct
  current setup on the same bike.
- [ ] Do **not** add `kDebugMode` to the `SetupListTile` guard and do not gate
  `showCompareSetupsSheet`; the setting is the single runtime source of truth.
- [ ] Update Phase 2-era tests/harness setup so scenarios that expect Compare
  explicitly enable the setting; default-setting scenarios must now expect the
  action to be absent.
- [ ] Extend `app_settings_test.dart` to verify the default is false, the setter
  notifies/persists it, and a new `AppSettings` instance reloads the stored value.
- [ ] Add `features_page_test.dart` to verify the debug build shows the Setup
  Comparison tile, reflects Off/On, and changes the setting through the existing
  radio-group interaction.
- [ ] Extend `setup_list_tile_test.dart` to verify: flag off hides Compare even
  for an otherwise eligible historical setup; flag on shows it only when the
  current-baseline eligibility rules pass.

### Context projection

- [ ] Add context row/group kinds for bike, person, notes, tags, images,
  location and conditions. Keep display formatting in widgets; keep raw values
  and explicit equality policies in the service/model.
- [ ] Resolve bike/person names independently per side. Preserve the ID as the
  comparison key and show `BIKE NOT FOUND` / `PERSON NOT FOUND` states with
  error styling consistent with setup details.
- [ ] Compare notes as nullable text and tags as order-independent sets. Sort
  tags only for deterministic display. Exclude tags entirely when
  `enableSetupTags` is off so hidden feature data does not inflate the visible
  difference count.
- [ ] Compare image filename lists in their stored order (strip order is user
  data). Exclude image rows/counts when `enableSetupImages` is off.
- [ ] Compare location fields already shown by `ContextLocationCard`: formatted
  address, latitude/longitude and altitude. Keep the paired address summary in
  the disclosure header and the numeric details inside.
- [ ] Compare only weather fields already surfaced by `ContextWeatherCard`:
  weather-code label, condition, temperature, accumulated precipitation,
  humidity, wind and soil moisture. Do not compare `currentDateTime`,
  `currentIsDay` or hidden raw current precipitation.
- [ ] Ensure equality matches displayed precision after unit conversion so a
  row is never orange while both formatted strings look identical. Centralize
  these context format/equality helpers rather than duplicating decisions in
  each widget.

### Visible notes and tags

- [ ] Render Notes & tags immediately beneath bike/person using one paired row
  or paired outlined card. Reuse `NotesText`; preserve multi-line wrapping and
  cap extreme notes consistently with setup details (`maxLines: 10`).
- [ ] Render enabled tags under each side's notes with the existing tag icon
  vocabulary. Do not use `ExpansionTile`, dialogs or tooltips as the primary
  access to notes/tags.
- [ ] In Differences mode, omit the whole Notes & tags block only when both
  notes and tag sets are equal; in All mode show it whenever either side has
  content.

### Side-by-side image strips

- [ ] Add `ImageStrip.heroTagPrefix`, defaulting to the current
  `'setup-image'`; build Hero tags as `'$heroTagPrefix-$filename'`. Existing
  callers require no changes.
- [ ] Resolve `ImageStorageService().getImagesPath()` once, then render a single
  `Row` with two `Expanded` children. Pass distinct prefixes derived from
  setup/side IDs.
- [ ] Keep both children at the existing 80 px strip height on every width.
  Each non-empty side uses view-mode `ImageStrip`; each empty side uses a
  themed “No images” placeholder of the same height. Never use a responsive
  branch that stacks the strips.
- [ ] Preserve each strip's independent horizontal scrolling and image-viewer
  tap behavior. Do not add edit/delete controls to comparison.
- [ ] Handle loading and storage-path failure: loading placeholder at fixed
  height; failure/invalid files use existing broken-image visuals and do not
  remove the rest of Context.

### Location and conditions disclosures

- [ ] Add compact, initially collapsed Location and Conditions cards using
  existing `ExpansionTile` conventions (`dense`, borderless shape).
- [ ] Their headers show a paired gist; expanded content is composed from the
  same responsive comparison-row primitive.
- [ ] In Differences mode show only differing child rows and omit a disclosure
  with no visible differences. In All mode show recorded fields and explicit
  unavailable sides.

### Tests

- [ ] Add service cases for note null/text, order-independent tags, image order,
  different bikes/persons, partial place/location and partial weather.
- [ ] Verify notes/tags are visible without tapping and long content does not
  overflow at 320 px.
- [ ] Verify location/weather start collapsed, expand correctly and obey
  Differences filtering.
- [ ] Verify the two `ImageStrip`s are simultaneous siblings in one horizontal
  `Row` at both 320 and 800 px; one empty side retains alignment.
- [ ] Render the same filename on both sides and open an image to prove distinct
  Hero prefixes avoid duplicate-Hero exceptions.
- [ ] Verify `enableSetupTags` and `enableSetupImages` gates hide both UI and
  associated difference counts.
- [ ] Verify `enableSetupComparison` defaults/persistence, the debug-only
  FeaturesPage control, and the setting-only setup-tile menu guard.
- [ ] Format only new/modified files from this phase.

**Verification:**

```bash
flutter test test/models/app_settings_test.dart
flutter test test/pages/settings/features_page_test.dart
flutter test test/services/setup_comparison_service_test.dart
flutter test test/widgets/items/setup_list_tile_test.dart
flutter test test/widgets/sheets/compare_setups_test.dart
flutter analyze
```

Manual: in a debug build, confirm Setup Comparison defaults Off, the historical
setup menu hides Compare while Off and shows it after enabling the feature; then
compare setups with long notes, many tags, images on both/one/neither side,
different places and partial weather. Verify strips stay side by side and
weather remains secondary in both themes.

**Commit:** `feat(setups): gate comparison and add setup context`

---

## Phase 4 — Component, person and dangling value hierarchy

**Status:** ✅ Complete

Values now render as strict-ID component/person/deleted-owner cards with responsive paired values, provenance, state labels, filtering, and safe formatting.

**Goal:** render the main Values section from Phase 1's strict projection,
including effective/provenance states and structural component differences.

**Files:**

- Modify `lib/widgets/sheets/compare_setups.dart`
- Add `lib/widgets/compare_setups/setup_comparison_owner_card.dart`
- Modify `lib/widgets/compare_setups/setup_comparison_row.dart`
- Modify `test/widgets/sheets/compare_setups_test.dart`
- Modify `test/services/setup_comparison_service_test.dart`

### Section and owner hierarchy

- [ ] Add a Values section after Context. Order owner groups exactly as the
  projection provides; do not sort again by display name in the widget.
- [ ] Render one outlined owner card per component/person using
  `CardHeaderTile`, component-type/person icons, owner name and `x of y differ`.
- [ ] For matched UUIDs, use one owner card. For one-sided/installed-versus-
  dangling owners, show both side-presence labels in the header and use the
  changed background as a structural difference.
- [ ] Use existing error vocabulary/messages for dangling owners (“Component
  was not installed at setup time”, “Person is not linked to this setup”).
  Dedicated deleted-value groups use error headers and fallback adjustment IDs.
- [ ] Respect `enablePerson`: when off, remove person groups from UI and visible
  difference totals without changing the underlying stored setup data.
- [ ] In Differences mode keep an owner card when it has a structural difference
  or at least one differing row; filter unchanged children. In All mode show
  every defined adjustment, including paired unavailable values.

### Leaf formatting and provenance

- [ ] Format adjustment values with `Adjustment.formatValue` and the owning
  side's `unitSuffix`; handle mismatched/stale side definitions without unsafe
  casts. Reuse existing categorical/text coercion helpers where required.
- [ ] Give each row its adjustment-type icon and full label/notes context. Notes
  may be secondary text but must remain overflow-safe.
- [ ] Display `Inherited` beneath inherited values with muted theme text.
  Explicit and inherited values that are equal stay unhighlighted in All mode.
- [ ] Distinguish `—` states with text/semantics: `Not recorded`, `Cleared`,
  `Owner not present`, `Dangling value`, `Adjustment deleted`; do not render all
  of them as an unexplained dash.
- [ ] Optionally show a signed numeric delta only when both effective values are
  numeric and their adjustment definitions have compatible units. Do not add
  red/green direction semantics or a “better” label.
- [ ] Keep changed fill on the entire differing row, including one-sided
  structural rows. Error-container fill on an affected value cell takes visual
  priority locally.

### Tests

- [ ] Verify strict-ID behavior in the rendered tree: equal names/different IDs
  create separate one-sided cards; a moved same-ID component creates one paired
  card.
- [ ] Verify same effective explicit/inherited values appear in All but not
  Differences, and display the inherited provenance correctly.
- [ ] Verify formatting for every adjustment subtype and long categorical/text
  values at narrow width.
- [ ] Verify one-sided, dangling and deleted states have distinct visible text,
  semantics and error styling without suppressing changed-row background.
- [ ] Verify owner counts, global difference counts and filtering agree after
  `enablePerson` is toggled.
- [ ] Verify a different-bike comparison containing no shared component IDs is
  a series of honest one-sided groups and never crashes.
- [ ] Format only new/modified files from this phase.

**Verification:**

```bash
flutter test test/services/setup_comparison_service_test.dart
flutter test test/widgets/sheets/compare_setups_test.dart
flutter analyze
```

Manual: compare before/after component replacement, moved components,
different persons and a setup with dangling values; inspect long values at
320/390/800 px in light and dark.

**Commit:** `feat(setups): compare component and person setup values`

---

## Phase 5 — Sheet actions, ratings, accessibility and full regression

**Status:** ✅ Complete

**Goal:** complete the comparison/details sheet actions and Ratings, lock
visual behavior, and verify the finished experience as an integrated feature.

**Files:**

- Modify `lib/models/setup_comparison.dart`
- Modify `lib/services/setup_comparison_service.dart`
- Modify `lib/utils/setup_actions.dart`
- Modify `lib/pages/details/setup_details_page.dart`
- Modify `lib/widgets/sheets/compare_setups.dart`
- Modify `lib/widgets/sheets/setup_details.dart`
- Modify `lib/widgets/compare_setups/setup_comparison_row.dart`
- Add `test/utils/setup_actions_test.dart`
- Modify `test/services/setup_comparison_service_test.dart`
- Modify `test/widgets/items/setup_list_tile_test.dart`
- Modify `test/widgets/sheets/compare_setups_test.dart`
- Add `test/widgets/sheets/setup_details_test.dart`

### Restore B from the comparison sheet

- [x] Change `SetupActions.duplicateSetup` from `Future<void>` to
  `Future<Setup?>`. Preserve its existing image-copy cleanup and duplicate-form
  workflow; return the created setup after `addSetup`, and return `null` on
  cancellation or when the initiating context is lost. Existing callers may
  continue awaiting and ignoring the result.
- [x] Add a compact `FilledButton.tonalIcon` (restore icon, label `Restore B`)
  to the comparison header/action row. It is explicitly associated with the
  right/candidate side, remains overflow-safe at 320 px/text scale 2.0, and is
  hidden when B is current.
- [x] Do not gate this in-sheet action with `enableSetupComparison`: once a
  caller has opened comparison, the setting has already served its menu-entry
  purpose.
- [x] On tap, call `SetupActions.duplicateSetup(context, setup: setupB)`. Keep
  the comparison sheet open if the duplicate form is cancelled. After a
  successful add, check `context.mounted` and close comparison rather than
  leaving an A/B view whose current baseline has changed.
- [x] Provide clear button tooltip/semantics (“Restore setup B as current”);
  the duplicate form is the review/confirmation step, so do not add a second
  confirmation dialog.

### Setup-details sheet action menu

- [x] Replace the sheet-only standalone Edit button in
  `SetupDetailsPageContent` with a filled overflow `PopupMenuButton`; retain the
  separate Close button. Keep the full-page `SetupDetailsPage` app-bar Edit
  action unchanged.
- [x] Give the menu Edit, Restore and Compare entries using the same labels and
  icons as `SetupListTile`. Avoid copying the private `_SetupOptions` enum; a
  small details-sheet-local enum is sufficient.
- [x] Edit is always present. Restore is present only when the displayed setup
  is not current. On successful restore, close details; on cancellation, leave
  it open.
- [x] Compare is present only when
  `appSettings.enableSetupComparison` is true and Phase 1's target resolver can
  resolve a distinct current setup on the same bike. Reuse the resolver rather
  than duplicating `setups.any(...)` eligibility logic.
- [x] Launch `showCompareSetupsSheet(context, setupA: null, setupB: setup)`
  above the details sheet. Do not close details first; dismissing comparison
  returns the user to the details context.
- [x] Keep action callbacks guarded across awaits and handle a setup removed
  while the sheet is open with the existing missing-setup/error behavior.
- [x] Update `showSetupDetailsSheet`/`SetupDetailsPageContent` parameters to
  express “show sheet actions” rather than an Edit-only contract, without
  changing default full-page rendering.
- [x] Keep the header overflow-safe with a long setup name, Current badge,
  overflow button and Close button at narrow widths and large text scale.

### Ratings integration

- [x] When `enableRating` is true, obtain each setup's entry count,
  `scoreForSetup`, `metricScoresForSetup` and metric definitions through the
  same `AppRepository` APIs used by `SetupDetailsPage`.
- [x] Add rating projection input/types without coupling the pure comparison
  service directly to `AppRepository`; pass immutable per-side rating summaries
  into the builder or build a small rating sub-projection at the sheet boundary.
- [x] Show Overall score and rating count in an always-visible paired summary.
  Format score to one decimal and base highlighting on the displayed precision
  so identical-looking scores are not marked different.
- [x] Add an initially collapsed metric breakdown. Join metrics strictly by
  metric UUID; show name, paired `x.x / 10` scores and weight. One-sided metrics
  are structural differences, not name-matched rows.
- [x] Keep rating-entry sample counts visible beside each overall score and
  render neutral signed score delta text only when both scores exist.
- [x] When both sides have no ratings, hide Ratings in Differences mode and show
  the familiar “No ratings yet” state in All mode. Omit the entire section when
  ratings are disabled.

### Accessibility and interaction review

- [x] Establish deterministic traversal: header/filter, Context, Values, then
  Ratings; A precedes B within each row.
- [x] Add semantic labels that include row name, side/setup name, formatted
  value, provenance/state and whether the pair differs.
- [x] Ensure minimum tap targets for filter, Restore B, action overflow, close
  button and disclosures.
- [x] Verify text scale 1.3 and 2.0 without overflow; the modal remains
  scrollable and the pinned header does not consume the full viewport.
- [x] Confirm background highlighting meets contrast expectations in light/dark
  while text keeps normal theme foreground colors.

### Widget and regression coverage

- [x] Add rating tests for no ratings, unequal entry counts, equal/different
  rounded scores, strict metric IDs, one-sided missing definitions and
  `enableRating = false`.
- [x] Add `setup_actions_test.dart` coverage for the new duplicate return
  contract: successful duplicate returns the added setup; form cancellation
  and lost context return `null`; copied images are cleaned on cancellation.
- [x] Extend comparison-sheet tests: Restore B is visible only for non-current
  B, cancellation leaves the sheet open, successful restore closes it, and the
  button has the required tooltip/semantics.
- [x] Add setup-details-sheet tests: overflow replaces the sheet Edit icon;
  Edit is always present; Restore follows current state; Compare follows the
  setting plus target resolver; Compare opens above details and returns to it;
  successful/cancelled Restore closes/retains details as specified.
- [x] Re-run/extend setup-list-tile tests to prove the
  `duplicateSetup` return-type change does not alter the existing Restore menu
  flow or comparison eligibility.
- [x] Add one full interaction test: open from a historical setup tile, confirm
  Current is A, Differences is selected, toggle All, expand Conditions and
  Ratings, scroll through Values, open an image, cancel Restore B, and close
  cleanly.
- [x] Run the full suite after targeted tests. Preserve unrelated existing
  working-tree changes and avoid whole-file formatting.

**Verification:**

```bash
flutter test test/utils/setup_actions_test.dart
flutter test test/services/setup_comparison_service_test.dart
flutter test test/widgets/sheets/compare_setups_test.dart
flutter test test/widgets/sheets/setup_details_test.dart
flutter test test/widgets/items/setup_list_tile_test.dart
flutter analyze
flutter test
```

Manual acceptance matrix:

- historical versus current on the same bike;
- explicit distinct setups on different bikes;
- identical effective values with different provenance;
- component replacement and moved same-ID component;
- different/null persons and person feature disabled;
- notes/tags long, equal, different and feature-gated;
- images on both/one/neither side, including the same filename;
- partial/missing location and weather;
- no ratings, unequal samples and different metric sets;
- Restore B cancelled and completed, including copied setup images;
- setup-details Edit/Restore/Compare overflow eligibility and stacked compare
  navigation;
- 320, 390 and 800 px widths; text scale 1.0/1.3/2.0; light and dark themes.

**Commit:** `feat(setups): complete setup comparison actions and ratings`

---

## Suggested commit granularity

1. `feat(setups): add strict setup comparison projection`
   - Pure models/service, target resolution and exhaustive unit tests.
2. `feat(setups): add responsive setup comparison shell`
   - Modal lifecycle, pinned header, default Differences filter, row primitive
     and setup-tile entry contract.
3. `feat(setups): gate comparison and add setup context`
   - Persisted debug-exposed feature setting, setup-tile guard,
     primary/secondary Context, visible notes/tags and side-by-side ImageStrips.
4. `feat(setups): compare component and person setup values`
   - Owner hierarchy, effective/provenance display and dangling/structural data.
5. `feat(setups): complete setup comparison actions and ratings`
   - Restore B, setup-details action menu, Ratings, semantics and full
     regression verification.

Each phase is sized for one commit or small PR and can be handed to a fresh
context independently. Phases 1–2 establish the stable service/widget contracts;
Phases 3–5 should extend those contracts rather than bypassing them with
section-specific map joins inside `build()`.
