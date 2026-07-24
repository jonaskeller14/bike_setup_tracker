# Categorical Counted Selection — concept brainstorming

**Status:** Brainstorming — pick one option per section, then run /plan.
**Date:** 2026-07-24

## Goal

Add a third categorical mode next to single-select and multi-select: a **counted / quantity**
mode where the *same option can be selected multiple times*. Motivating use case is nutrition
tracking during a ride — *"2 Bars, 3 Gels, 1 Bottle"*. Requirements from the request:

- Value representation reads like `Bars (2), Gels (3), Bottle` (count in parentheses; a count
  of 1 shows no parens).
- Guarded behind an `AppSettings` feature flag (mirrors `enableMultiSelect`).
- **The current UI must stay the same** for single- and multi-select adjustments.
- A **new checkbox** on the categorical adjustment page enables the mode.
- When enabled, the picker sheet **counts up** each time a chip is tapped, and each selected
  chip gets a **trailing delete (×) icon** that decrements the count.

This is the "bag / quantities" future explicitly scoped in
`doc/20260705_categorical_multiselect.md` → *"Future feature evaluation — quantities and/or
ordered items"*. That analysis already recommended standing on `List<String>` (with repeats)
rather than `Map<String,int>`; this doc turns that into concrete, decidable options grounded in
the code as it stands today (post schema-v11 uniform JSON storage).

---

## Decisions (locked 2026-07-24)

Confirmed with the user; the lettered sections below are kept for rationale but these override.

- **A1** — two bools `multiSelect` + `counted`, giving **four valid states** (see the semantics
  table below). All four are legal; there is no illegal combo to normalize.
- **B1** — `List<String>` with repeats; no storage/codec/migration change.
- **C1** — new persisted flag `enableCountedSelect`, **default false**, FeaturesPage tile shown
  **only under `kDebugMode`**.
- **D1** — a second guarded `CheckboxListTile` ("Count occurrences") on the categorical page.
- **E1** — tap-to-increment chip + trailing × to decrement in the picker sheet.
- **F1** — emit grouped by option order, N copies per option.
- **G (revised)** — change `Adjustment.formatValue`'s `List` case itself to group repeats into
  `"Element (N)"` (omit `(1)`); do **not** add a separate counted-only formatter. See the revised
  G section.
- **H1** — repeats allowed in counted mode; validation per the four-state table.

### Four-state semantics (A1)

| `multiSelect` | `counted` | Meaning | Example value | Renders |
|---|---|---|---|---|
| false | false | Single-select (today) | `[Bar]` | `Bar` |
| true  | false | Multi-select (today), distinct | `[Bar, Gel]` | `Bar, Gel` |
| false | **true** | **One** option, repeatable | `[Bar, Bar, Bar, Bar]` | `Bar (4)` |
| true  | **true** | Multiple options, each repeatable | `[Bar, Bar, Gel, Gel, Gel]` | `Bar (2), Gel (3)` |

Note the `(false, true)` cell: `Bar (4)` is allowed but `Bar (4), Gel` is **not** — only a single
distinct option may be chosen, but it may be counted up.

## Grounding — what this touches

- **Model:** `CategoricalAdjustment` (`lib/models/adjustment/categorical_adjustment.dart`) — has
  `multiSelect` bool, `options` Set, `isValidValue`, `toJson`/`fromJson` (conditional version
  1/2), `fromYaml`, `==`/`hashCode`/`deepCopy`.
- **Base:** `Adjustment.formatValue` (`adjustment.dart`) — the `List` case joins with
  `multiValueSeparator` (`", "`). Note it takes **only `value`**, not the adjustment, so it can't
  know "counted vs multi" on its own. Helper `categoricalValueAsList` normalizes stored shapes.
- **Storage / codec:** `lib/database/adjustment_value_codec.dart` — every value is JSON-encoded;
  categorical decodes list-or-scalar → `List<String>`. Repeats survive round-trip **for free**
  (a JSON array `["Bar","Bar","Gel"]` is already valid).
- **Picker sheet:** `lib/widgets/sheets/set_categorical.dart` — `Wrap` of `_OptionChip`
  (`ChoiceChip` single / `FilterChip` multi), `emit()` canonicalizes to option order, dangling
  (removed-option) chips shown as removable error-red `_DanglingChip`.
- **Set widget:** `lib/widgets/set_adjustment/set_categorical_adjustment.dart` — collapsed
  dropdown-styled field, `FormField<List<String>>` validator (rejects length>1 when not
  multiSelect), joins `validSelected` for the field text.
- **Display widget:** `lib/widgets/display_adjustment/display_categorical_adjustment.dart` — uses
  `Adjustment.formatValue(value)`.
- **Pages:** `categorical_adjustment_page.dart` and `categorical_metric_page.dart` — both hold
  `_multiSelect` state, a guarded `CheckboxListTile` (shown when `enableMultiSelect ||
  adjustment.multiSelect`), and a live preview via `SetCategoricalAdjustmentWidget`.
- **Settings:** `AppSettings.enableMultiSelect` (persisted, default false) +
  `FeaturesPage` "Categorical Multi-select" `ListTile` (radio-group sheet).
- **Tests:** `test/models/categorical_multiselect_migration_test.dart`,
  `test/database/adjustment_value_roundtrip_test.dart`,
  `test/widgets/set_adjustment/set_categorical_adjustment_test.dart`,
  `test/pages/adjustment/categorical_adjustment_pages_test.dart`,
  `test/models/adjustment_format_value_test.dart`.

**Key constraint:** because every categorical value is already `List<String>`, the whole
storage/codec/backup/equality stack needs **zero change** to hold repeats. The cost is entirely
model config + UI + formatting, exactly as the prior doc predicted.

---

## A. How to represent the mode on the model

### A1 — Add a second bool `counted` alongside `multiSelect` (recommended)

Keep `multiSelect`, add `bool counted = false`. Semantics: `counted` implies multiple values
allowed *with repeats*; treat it as its own mode where `counted == true` overrides `multiSelect`
behaviour in the sheet/validator.

- **Pros:** Smallest diff to the model and its JSON; `multiSelect` semantics untouched so the
  "current UI stays the same" guarantee is trivially met. Mirrors the incremental style used when
  `multiSelect` was added. Easy `fromJson` default (`counted: false`).
- **Cons:** Two bools encode three-ish states → an illegal/ambiguous combo (`multiSelect:false,
  counted:true`?) must be defined and normalized. Slightly less self-documenting than an enum.

### A2 — Replace both bools with a `CategoricalMode { single, multi, counted }` enum

The exact enum the prior doc floated. `multiSelect` becomes a computed getter for back-compat.

- **Pros:** One source of truth, no illegal combos, clearest intent, most extensible (a future
  `sequence` mode slots in). Reads well at call sites (`mode == CategoricalMode.counted`).
- **Cons:** Larger change — every current `multiSelect` reference (pages, sheet, widget, YAML,
  tests) must route through the enum or a shim getter; more churn against the "surgical diff"
  convention. Needs a `fromJson` that maps legacy `multiSelect:bool` → enum and back.

### A3 — Single bool `counted` only, no relation to `multiSelect`

Counted is fully independent; a counted adjustment ignores `multiSelect` entirely.

- **Pros:** Minimal new surface.
- **Cons:** Muddies validation (what does `multiSelect:true, counted:true` mean?); pushes the
  same "define the illegal combos" work as A1 without A1's clarity that counted is the dominant
  mode. Weakest option.

---

## B. Value representation / storage

### B1 — `List<String>` with repeats, canonicalized to option order (recommended)

`2 Bars, 3 Gels, 1 Bottle` → `["Bar","Bar","Gel","Gel","Gel","Bottle"]`, grouped by option order
on read/emit.

- **Pros:** **Zero storage/codec/backup/migration change** — arrays with repeats already
  round-trip. `DeepCollectionEquality` already compares correctly. Matches the prior doc's
  explicit recommendation and keeps a future ordered/`sequence` mode reachable without another
  schema dance. Reuses `categoricalValueAsList`.
- **Cons:** Counts are implicit (must group-count for display); a very large quantity stores N
  copies of the string (negligible in practice — nutrition counts are small).

### B2 — `Map<String,int>` counts

Store `{"Bar":2,"Gel":3,"Bottle":1}`.

- **Pros:** Counts are explicit; compact for large N; arguably clearer semantics.
- **Cons:** **New storage shape** → codec, backup import/export, equality, routing boundaries all
  need a counted-aware branch and a migration story; breaks the "always `List<String>` on read"
  invariant; the prior doc warns this paints us into a corner (Map→List migration if order ever
  matters). High cost for a nutrition counter. Not recommended.

---

## C. AppSettings feature flag

### C1 — New dedicated flag `enableCountedSelect` (recommended)

New persisted bool + a new `FeaturesPage` `ListTile`, exactly mirroring `enableMultiSelect`.

- **Pros:** Independent ship decision from multi-select (which itself is still debug-gated per the
  prior doc's ship checklist); clean copy of an established pattern; discoverable in Features.
- **Cons:** One more feature toggle to maintain and eventually decide exposure for.

### C2 — Reuse the existing `enableMultiSelect` flag

Counted checkbox appears whenever multi-select is enabled.

- **Pros:** No new setting; conceptually "counted is an advanced multi-select".
- **Cons:** Couples two features that may ship on different timelines; a user who wants counting
  is forced to also surface the multi-select checkbox; muddier Features copy.

### C3 — One umbrella flag `enableAdvancedCategorical` covering multi + counted (+ future)

- **Pros:** Single toggle for all "beyond single-select" modes; tidy Features list long-term.
- **Cons:** Reworks the *existing* `enableMultiSelect` surface (migration of the setting + its
  ListTile + tests) — violates "current UI stays the same" for the multi-select path. Overreach
  for this task.

---

## D. Adjustment-page checkbox UX

The request says explicitly: *add a checkbox*. The open question is how it coexists with the
existing "Multi Select" checkbox.

### D1 — Second independent `CheckboxListTile` "Count occurrences" below "Multi Select" (recommended)

Shown when `enableCountedSelect || adjustment.counted`, same guard pattern as Multi Select.
Ticking "Count occurrences" implies multi behaviour; define the interaction (see Open Questions).

- **Pros:** Literal match to the request; mirrors the existing guarded `CheckboxListTile` exactly;
  "current UI stays the same" when the flag is off. Minimal new widget code.
- **Cons:** Two checkboxes can express an odd combo (counted on, multi off) that must be
  normalized (e.g. counted auto-implies/greys-out multi). Slight UX explanation burden (subtitle
  copy).

### D2 — Replace the two checkboxes with a 3-way selector (Single / Multi / Counted)

SegmentedButton or radio group driven by the A2 enum.

- **Pros:** No illegal combos; clearest mental model; scales to future modes.
- **Cons:** Changes the **existing** categorical page UI (the multi-select checkbox disappears),
  which cuts against "current UI stays the same"; more layout work; pairs naturally only with A2.

---

## E. Sheet interaction (the counting picker)

### E1 — Tap-to-increment chip + trailing × to decrement (recommended — matches the request)

In counted mode each `_OptionChip` shows the option and its current count; tapping increments;
a trailing delete icon decrements by one (removing the chip's selection at zero). Unselected
options render as normal tappable chips (count 0, no × icon).

- **Pros:** Exactly the requested behaviour; reuses the `Wrap`-of-chips sheet and its haptics;
  `InputChip` supports both a label and a `deleteIcon` (×) in one widget. Fits the existing
  dangling-chip removal idiom.
- **Cons:** `InputChip` tap vs delete hit areas are close — must ensure the × only decrements and
  the body increments; per-chip count label needs an overflow-safe render. New chip variant/branch
  in the sheet.

### E2 — Per-option +/- stepper rows (the prior doc's alternative)

A list of rows, each `optionName  [−] N [+]`.

- **Pros:** Unambiguous inc/dec targets; familiar quantity UI; no tap-vs-delete ambiguity.
- **Cons:** Departs from the chip/`Wrap` aesthetic the request wants to preserve; more vertical
  space; a bigger new widget. Doesn't match "chips count up with a trailing ×".

### E3 — Long-press / stepper popover on a chip

Tap adds, long-press opens a small +/- popover.

- **Pros:** Compact; keeps chips.
- **Cons:** Discoverability of long-press is poor; no visible × as requested; more moving parts.

---

## F. Emit / ordering semantics in counted mode

### F1 — Group by option order, N copies per option (recommended)

`emit()` returns each selected option repeated by its count, in `options` order (extending the
existing `adjustment.options.where(current.contains)` logic to `expand` by count). Dangling
counted values append after, as today.

- **Pros:** Deterministic, matches the display grouping (`Bars (2), Gels (3), …` follows option
  order); reuses the existing canonicalization; diff-friendly.
- **Cons:** Loses the order the user tapped (irrelevant for a bag; if insertion order ever
  matters, that's the separate `sequence` mode, out of scope).

### F2 — Preserve tap/insertion order

- **Pros:** Would enable a future sequence mode with no change.
- **Cons:** Display grouping into `(N)` then re-sorts anyway, so order is invisible here;
  inconsistent with the multi-select canonicalization; not requested. Defer to a real sequence
  mode.

---

## G. Value formatting — `Bars (2), Gels (3), Bottle` (revised — decided)

**Decision: group in `Adjustment.formatValue`'s `List` case itself** — no separate counted
formatter, no per-site changes. Change the flat join into a count-grouped render: collapse equal
elements into `"Element (N)"`, **omit `(1)`**, preserve first-occurrence order, join with
`multiValueSeparator`.

The original doc claimed a counted render "must be adjustment-aware" because `formatValue` can't
tell counted from multi. That was wrong: **it doesn't need to.** Multi-select and single-select
values contain only *distinct* options, so every group has count 1 → no `(N)` is printed → the
output is byte-identical to today (`Front, Rear`, `Front`). Only counted values carry repeats, so
only they render `(N)`. One code path serves all three modes.

- **Pros:** **Zero display-site churn** — every path already routes through `formatValue` (display
  widget, compact list, sort keys, CSV/Excel/text export) and gets counted rendering for free. The
  "missed a site → flat `Bar, Bar`" risk of a separate formatter disappears. Exports are
  automatically consistent (resolves the old export sub-decision — grouped everywhere).
- **Cons / caveats to cover in the plan:**
  1. **One non-`formatValue` site still needs fixing regardless:** the collapsed set-widget field
     (`set_categorical_adjustment.dart:121`) builds `validSelected =
     adjustment.options.where(selected.contains)`, which **de-dupes and drops counts**. It must
     switch to `Adjustment.formatValue(value)` (filtered to valid options) so the field shows
     `Bar (2), Gel (3)`.
  2. **Forecloses reusing `formatValue` for a future ordered/`sequence` mode** — interleaved
     repeats (`bar, gel, bar`) would wrongly collapse to `bar (2), gel`. Per the prior doc,
     sequence always needed its own formatter, so this is acceptable; just don't route a future
     sequence value through `formatValue`.
  3. A stray duplicate in a (buggy/legacy) multi-select value would now surface as `(2)` instead
     of a silent repeat — arguably more correct; worth a test either way.
  4. Group by **first-occurrence order** (not sorted) so canonical option-order input (F1) renders
     in option order and the multi-select case stays stable.

### G-alt (rejected) — separate `formatCountedValue` method/helper, called at each display site

- **Pros:** Leaves generic `formatValue` untouched.
- **Cons:** Must update every categorical render/sort/export site and risks missing one (flat
  `Bar, Bar`); more code for no behavioural gain over the `formatValue` change. Rejected in favour
  of the single-path revision above.

---

## H. Validation across the four states (decided — H1)

`isValidValue` (and the set-widget `FormField` validator) must honour all four states. Non-empty
and every element ∈ `options` always hold. Let `distinct = list.toSet()`:

| State | Rule |
|---|---|
| `(false,false)` single | `distinct.length ≤ 1` **and** no repeats (`list.length == distinct.length`) |
| `(true,false)` multi | any number of **distinct** options, no repeats |
| `(false,true)` counted-single | `distinct.length ≤ 1`, repeats allowed |
| `(true,true)` counted-multi | any options, repeats allowed |

Compact form: reject repeats unless `counted`; reject >1 **distinct** option unless `multiSelect`.

```
if (!list.every(options.contains)) return false;
if (!multiSelect && distinct.length > 1) return false;   // >1 distinct needs multi
if (!counted && list.length != distinct.length) return false;  // repeats need counted
```

- **Pros:** Single rule covers all four states; dangling (removed-option) values still surface as
  removable error chips via the existing path.
- **Cons:** The current model/set-widget guard is `!multiSelect && length>1` (uses raw length, not
  distinct) — must change to the distinct-count test so counted-single (`Bar, Bar`) passes. A spot
  to unit-test per state.

**Sheet interaction for counted-single `(false,true)` (decided):** tapping a *different* option
when one is already counted **resets the count to zero and selects the tapped option with
count = 1** (clear-and-add), without auto-closing — the user can then keep tapping to increment.
So `[Bar, Bar, Bar]` + tap `Gel` → `[Gel]`.

---

## Recommended combination — LOCKED

**A1 + B1 + C1 + D1 + E1 + F1 + G(revised) + H1** (see Decisions block at top).

Rationale: lowest-churn path that literally matches the request and honors "current UI stays the
same". Storage/codec/backup/equality ride entirely free on the existing `List<String>` (B1) — no
migration. Two bools (A1, four states) + a debug-gated flag (C1) + a second guarded checkbox (D1)
each mirror an established pattern rather than reworking the multi-select surface. The counting
sheet (E1) is the only genuinely new *widget*; the display side needs **no new formatter** because
grouping lives in `formatValue` itself (G revised).

**Suggested phasing:**
1. **Model + flag + format.** Add `counted` bool to `CategoricalAdjustment` (ctor / `deepCopy` /
   `==` / `hashCode` / `toJson` conditional version / `fromJson` default false / `fromYaml`),
   four-state `isValidValue` (H1), `AppSettings.enableCountedSelect` (C1, default false) +
   `kDebugMode`-gated FeaturesPage tile, and the `formatValue` `List`-case grouping (G revised).
   Unit tests: format grouping (incl. `(1)` omission + multi-select parity), four-state validation,
   JSON round-trip/version guard. No visible behaviour change for existing adjustments.
2. **Adjustment page checkbox (D1)** — second guarded `CheckboxListTile` "Count occurrences",
   `_counted` state through `_composePreview` / save / change-detection; live preview wiring.
   Mirror in `categorical_metric_page.dart` (parity confirmed). Fix the collapsed set-widget field
   to use `formatValue` (G caveat 1).
3. **Counting sheet (E1)** — increment-on-tap, trailing × decrement, per-chip count label; counted
   emit grouped by option order (F1); counted-single replace behaviour (H section). Set-widget
   `FormField` validator relaxed to the distinct-count rule. Widget/page tests per state.

---

## Open questions for the final plan

**Resolved by the user (2026-07-24):**
- ~~Does counted imply multi?~~ **No** — `multiSelect` and `counted` are independent; all four
  states are valid, including counted-single (`false,true`) = one option, counted up.
- ~~Export format / where formatting lives?~~ Grouped everywhere via `formatValue` (G revised).
- ~~Flag exposure?~~ New `enableCountedSelect`, default false, FeaturesPage tile under `kDebugMode`.
- ~~Ordering?~~ F1 group by option order.

**Resolved (2026-07-24, round 2):**
- **JSON version:** keep it simple — extend the existing one-liner to `version: counted ? 3 :
  (multiSelect ? 2 : 1)` and let `fromJson` accept `null|1|2|3` (both the categorical `fromJson`
  and the `Adjustment.fromJson` envelope). Counted data therefore carries v3 (old builds refuse it
  rather than dropping counts); non-counted data stays v1/v2-readable. No per-flag ceremony beyond
  the one ternary.
- **Counted-single interaction:** tapping a different option resets to count 1 on the new option
  (see H section).
- **Metric-page parity:** same behaviour — wire counted into `categorical_metric_page.dart` too.
- **YAML/component presets:** `counted` is an **optional** key, default `false`. Only the *reader*
  changes — add `counted` to `fromYaml`'s allowed keys + parse `map['counted'] as bool? ?? false`.
  No existing YAML files change; `SCHEMA.md` update is optional/nice-to-have, not required.

**Still open (UI detail only):**
1. **Chip count label style / large counts:** how to render the count on a selected chip (e.g.
   `Bar  2  ×` via `InputChip` label + `deleteIcon`), overflow-safe; plain `(12)` for big counts
   assumed. A layout detail to settle during implementation, not a blocker for `/plan`.

---

*Next step: confirm/adjust the choices above, then run `/plan` to produce the implementation plan.*
