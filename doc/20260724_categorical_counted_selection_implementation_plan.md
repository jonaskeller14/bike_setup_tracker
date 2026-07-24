# Categorical Counted Selection — implementation plan

**Date:** 2026-07-24
**Status:** Approved concept → phased implementation plan
**Concept doc:** `doc/20260724_categorical_counted_selection_concept.md`

Locked decisions: **A1** (two independent bools `multiSelect` + `counted` → four valid states) +
**B1** (`List<String>` with repeats, no storage/codec/migration change) + **C1** (new
`enableCountedSelect` flag, default false, FeaturesPage tile under `kDebugMode`) + **D1** (second
guarded "Count occurrences" checkbox on the categorical adjustment **and** metric pages) + **E1**
(picker sheet: tap chip to increment, trailing × to decrement) + **F1** (emit grouped by option
order, N copies per option) + **G revised** (grouping lives in `Adjustment.formatValue`'s `List`
case) + **H1** (four-state validation). Whole feature behind `enableCountedSelect`, dev-only for now.

---

## Resolved open questions

### JSON version → extend the existing one-liner to `counted ? 3 : (multiSelect ? 2 : 1)`

`CategoricalAdjustment.toJson` currently emits `version: multiSelect ? 2 : 1`. Extend it to
`counted ? 3 : (multiSelect ? 2 : 1)`. Both `CategoricalAdjustment.fromJson` and the
`Adjustment.fromJson` envelope (which today accept `null | 1 | 2`) must also accept `3`. Rationale:
counted data carries v3, so an old build refuses it rather than silently dropping counts;
single/multi data stays v1/v2-readable. No per-flag ceremony beyond the one ternary.

### Value formatting → group inside `Adjustment.formatValue`, no separate formatter

Change the `List` case of `Adjustment.formatValue` from a flat join to a count-grouped render:
collapse equal elements into `"Element (N)"`, **omit `(1)`**, preserve first-occurrence order, join
with `multiValueSeparator`. Multi/single values are always distinct → every count is 1 → output is
byte-identical to today (`Front, Rear`, `Front`). Only counted values render `(N)`. One code path
serves all three modes; every existing display/sort/export site inherits counted rendering for free.

### Counted-single `(multiSelect:false, counted:true)` tap behaviour → reset to count 1

Tapping a *different* option when one is already counted **clears the current selection and selects
the tapped option with count 1** (no auto-close), so `[Bar, Bar, Bar]` + tap `Gel` → `[Gel]`. The
user can then keep tapping to increment.

### Collapsed set-widget field → must switch to `formatValue`

`set_categorical_adjustment.dart` builds its field text from
`validSelected = adjustment.options.where(selected.contains)`, which **de-dupes and drops counts**.
It must render `Adjustment.formatValue(value)` (filtered to valid options) so a counted value shows
`Bar (2), Gel (3)` instead of `Bar, Gel`. Needed regardless — lands in Phase 3 with the sheet.

### Metric page → full parity

`categorical_metric_page.dart` mirrors the adjustment page; it gets the same guarded checkbox and
`_counted` wiring.

### YAML/component presets → optional key, reader-only change

`counted` is an optional preset key, default `false`. Only `CategoricalAdjustment.fromYaml` changes
(add `counted` to the allowed-keys set + parse `map['counted'] as bool? ?? false`). No existing YAML
files change; a `SCHEMA.md` note is nice-to-have, not required.

### Four-state validation (H1)

With `distinct = list.toSet()`, `isValidValue` (and the set-widget `FormField` validator):

```
if (list.isEmpty) return false;
if (!list.every(options.contains)) return false;
if (!multiSelect && distinct.length > 1) return false;   // >1 distinct needs multi
if (!counted && list.length != distinct.length) return false;  // repeats need counted
```

| `multiSelect` | `counted` | Example valid value |
|---|---|---|
| false | false | `[Bar]` |
| true  | false | `[Bar, Gel]` |
| false | true  | `[Bar, Bar, Bar, Bar]` |
| true  | true  | `[Bar, Bar, Gel, Gel, Gel]` |

---

## Feature flag

`AppSettings.enableCountedSelect` (persisted key `enableCountedSelect`, default `false`), mirroring
`enableMultiSelect`. The "Count occurrences" checkbox on both categorical pages is shown when
`enableCountedSelect || adjustment.counted` (so an existing counted adjustment can always be edited
even if the flag is later turned off). The FeaturesPage entry is wrapped in `if (kDebugMode)` — the
established pattern for unshipped features in that page.

---

## Phase 1 — Model, feature flag & count-grouped formatting (pure logic, no visible change)

**Status:** ✅ Complete — `counted` bool + four-state validation + v3 JSON guard + grouped
`formatValue` + `enableCountedSelect` flag (debug-gated FeaturesPage tile) landed; all new/extended
tests green, `flutter analyze` clean on touched files.

**Files:**
- `lib/models/adjustment/categorical_adjustment.dart` — add `counted`.
- `lib/models/adjustment/adjustment.dart` — count-grouped `formatValue` `List` case; accept v3 in
  the `fromJson` envelope.
- `lib/models/app_settings.dart` — `enableCountedSelect` field / getter / setter / load.
- `lib/pages/settings/features_page.dart` — `if (kDebugMode)` "Count occurrences" tile.
- `test/models/adjustment_format_value_test.dart` — grouping cases (extend).
- `test/models/categorical_counted_test.dart` — **new**: four-state validation, JSON v3 round-trip,
  format grouping.
- `test/models/categorical_multiselect_migration_test.dart` — extend the version-guard cases for v3.

**Steps:**
- [ ] `CategoricalAdjustment`: add `final bool counted` (default `false`) to the ctor; thread it
      through `deepCopy`, `==`, `hashCode`.
- [ ] `toJson`: emit `version: counted ? 3 : (multiSelect ? 2 : 1)` and a `'counted': counted` key.
- [ ] `fromJson`: accept `case null || 1 || 2 || 3`; read `counted: json['counted'] as bool? ?? false`.
- [ ] `fromYaml`: add `'counted'` to the `_checkPresetKeys` allowed set; parse
      `counted: map['counted'] as bool? ?? false`.
- [ ] `Adjustment.fromJson` envelope: extend the version switch to accept `3`.
- [ ] `isValidValue`: implement the four-state rule (reject repeats unless `counted`; reject >1
      distinct unless `multiSelect`).
- [ ] `Adjustment.formatValue` `List` case: group equal elements into `"Element (N)"`, omit `(1)`,
      first-occurrence order, join with `multiValueSeparator`; empty stays `'-'`.
- [ ] `AppSettings`: add `_enableCountedSelect = false`, getter, setter (`_persistBool`), and the
      load line in the prefs loader — copy the `enableMultiSelect` trio exactly.
- [ ] `FeaturesPage`: add an `if (kDebugMode)` "Count occurrences" `ListTile` mirroring the
      "Categorical Multi-select" tile (radio-group sheet, `infoText` explaining the mode).

**Verification:**
- [ ] `flutter test test/models/categorical_counted_test.dart` — new: `[Bar,Bar]` invalid when
      `counted:false`; valid when `counted:true`; `[Bar,Gel]` invalid when `multiSelect:false`
      (both counted values); `formatValue(["Bar","Bar","Gel","Gel","Gel"]) == "Bar (2), Gel (3)"`;
      `formatValue(["Bottle"]) == "Bottle"` (no `(1)`); counted `toJson()['version'] == 3` and
      `fromJson` round-trips `counted`.
- [ ] `flutter test test/models/adjustment_format_value_test.dart` — multi-select distinct list
      still renders `"Front, Rear"` (parity, no `(N)`).
- [ ] `flutter test test/models/categorical_multiselect_migration_test.dart` — envelope accepts v3,
      still rejects an unknown higher version.
- [ ] `flutter analyze` clean on the touched files.

**Commit:** `feat(categorical): add counted mode model, flag & grouped formatValue`

---

## Phase 2 — Adjustment & metric page "Count occurrences" checkbox

**Status:** ⬜ Not started

**Files:**
- `lib/pages/adjustment/categorical_adjustment_page.dart`
- `lib/pages/metric/categorical_metric_page.dart`
- `test/pages/adjustment/categorical_adjustment_pages_test.dart` — extend.

**Steps (apply symmetrically to both pages):**
- [ ] Add `bool _counted` state, initialised from `adjustment?.counted` / `_initialAdj?.counted`.
- [ ] `_composePreview()` and the save path (`_saveCategoricalAdjustment` / `_saveMetric`): pass
      `counted: _counted`.
- [ ] `_changeListener()`: include `_counted != (initial?.counted ?? false)` in the change check.
- [ ] Add a second `CheckboxListTile` "Count occurrences" (subtitle e.g. *"Allow the same option
      multiple times"*) directly below the existing "Multi Select" tile, shown when
      `appSettings.enableCountedSelect || _counted`. On change: `setState` `_counted`, reset
      `_previewValues = null`, recompose preview, call `_changeListener()` — mirror the Multi Select
      handler exactly.
- [ ] Keep the two checkboxes independent (four states); no auto-tick coupling.

**Verification:**
- [ ] `flutter test test/pages/adjustment/categorical_adjustment_pages_test.dart` — with
      `enableCountedSelect:true` the checkbox renders; toggling it and saving returns a
      `CategoricalAdjustment` with `counted:true`; with the flag false and `adjustment.counted:false`
      the checkbox is absent; an existing `counted:true` adjustment still shows the checkbox when the
      flag is false.
- [ ] `flutter analyze` clean.
- [ ] Manual: both pages, long option names + long adjustment name — checkbox row and preview are
      overflow-safe in light and dark.

**Commit:** `feat(categorical): count-occurrences checkbox on adjustment & metric pages`

---

## Phase 3 — Counting picker sheet, field rendering & validation

**Status:** ⬜ Not started

**Files:**
- `lib/widgets/sheets/set_categorical.dart` — counted branch (increment on tap, × to decrement,
  per-chip count, counted-single replace, grouped emit).
- `lib/widgets/set_adjustment/set_categorical_adjustment.dart` — field text via `formatValue`;
  relax the `FormField` validator to the four-state rule.
- `test/widgets/set_adjustment/set_categorical_adjustment_test.dart` — extend.
- `test/widgets/set_categorical_sheet_test.dart` — **new** (or extend the existing sheet test): count
  up / down / counted-single replace / emit order.

**Steps:**
- [ ] Sheet: add `final bool counted = adjustment.counted;`. Track counts as a
      `Map<String,int>` (or keep the `List` and count occurrences) instead of the `Set current` when
      `counted`.
- [ ] Counted chip: render option label + current count (0 = unselected, tappable to add). Selected
      chips get a trailing × (`deleteIcon`) that decrements by one; reaching 0 removes it. Use
      `InputChip` for the counted branch; keep `ChoiceChip`/`FilterChip` for single/multi unchanged.
- [ ] Tap-to-increment in counted mode; for counted-single (`!multiSelect`), tapping a *different*
      option clears the map and sets the tapped option to 1 (no auto-close).
- [ ] `emit()`: in counted mode return each option repeated by its count, in `options` order, then
      dangling values (existing pattern), so the stored value is grouped/canonical (F1).
- [ ] Keep haptics (`HapticFeedback.selectionClick`) on inc/dec; keep the dangling-chip removal path.
- [ ] `set_categorical_adjustment.dart`: replace the field text
      `validSelected.join(multiValueSeparator)` with `Adjustment.formatValue(<valid-filtered value>)`
      so counts show; `hasValidValue` unchanged.
- [ ] `set_categorical_adjustment.dart`: relax the `FormField` validator — replace the
      `!multiSelect && selection.length > 1` check with the four-state rule (`>1 distinct` needs
      multi; repeats need counted).

**Verification:**
- [ ] `flutter test test/widgets/set_categorical_sheet_test.dart` — counted: tapping `Bar` twice
      then `Gel` thrice emits `["Bar","Bar","Gel","Gel","Gel"]`; the × on `Gel` decrements to
      `["Bar","Bar","Gel","Gel"]`; counted-single: `Bar×3` then tap `Gel` emits `["Gel"]`.
- [ ] `flutter test test/widgets/set_adjustment/set_categorical_adjustment_test.dart` — field for a
      counted value renders `"Bar (2), Gel (3)"`; the validator accepts a counted value and still
      rejects repeats when `counted:false`.
- [ ] `flutter analyze` clean.
- [ ] Manual: open the sheet on a counted adjustment — chips count up, × decrements, chip label +
      count + × stay overflow-safe with long option names in light and dark; collapsed field
      ellipsises a long counted value.

**Commit:** `feat(categorical): counting picker sheet with per-option counts`

---

## Suggested commit granularity

Three commits, one per phase, each independently green and mergeable:

1. `feat(categorical): add counted mode model, flag & grouped formatValue` — Phase 1 (no visible
   change; safe to land alone since the flag stays off).
2. `feat(categorical): count-occurrences checkbox on adjustment & metric pages` — Phase 2 (checkbox
   creates counted adjustments; picker still behaves as multi/single, which is self-consistent).
3. `feat(categorical): counting picker sheet with per-option counts` — Phase 3 (the counting UX +
   field rendering + validator), completing the feature behind `enableCountedSelect`.

Land 1 → 2 → 3 in order (each builds on the previous). No `build_runner` step is required — no table
or `@JsonSerializable` change (values stay `List<String>`; the model JSON is hand-written).

Execute a single phase in a fresh context window with
`/handoff doc/20260724_categorical_counted_selection_implementation_plan.md <phase>`.
