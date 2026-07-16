# SAG Adjustment Type — Evaluation & Integration Plan

**Date:** 2026-07-15
**Status:** ✅ **Phase 1 implemented** (2026-07-16, Approach C) — phases 2 & 3 open
**Related:** `doc/20260709_adjustment_unit_conversion.md` (unit toggle work on branch `unitToggle`), memory: component preset DB (`data/component_presets/`)

---

## 1. The idea

Add a dedicated **SAG adjustment** (conceptually inheriting from Numerical) so that:

- The user can enter SAG as a percentage, as today.
- Alternatively the user enters the **measured length in mm** and the app computes the
  percentage. This requires a reference length: **fork travel** for forks, **shock stroke**
  for shocks (note: shock SAG is measured against *stroke*, not rear-wheel travel — the
  model must not conflate the two).
- SAG gets a special visualization (a travel-depth gauge).

This document evaluates the idea, lists integration approaches (architecture + UI/UX),
and addresses the four raised concerns: generalization to future special types, converting
existing numerical adjustments, avoiding UI clutter, and the impact on the app's
"5–6 fundamental adjustment types" principle.

## 1a. Implementation status (2026-07-16)

Phase 1 is in on branch `sag`, following Approach C unchanged. What landed:

| Area | File |
|---|---|
| ✅ Model | [sag_adjustment.dart](lib/models/adjustment/sag_adjustment.dart) — `SagAdjustment extends NumericalAdjustment`, `referenceTravelMm`, `subtype` discriminator |
| ✅ Subtype dispatch | [numerical_adjustment.dart:69](lib/models/adjustment/numerical_adjustment.dart#L69) — recognized subtype → `SagAdjustment`, unknown → plain numerical |
| ✅ Unit-cycle abstraction | [unit_conversion.dart](lib/utils/unit_conversion.dart) — `UnitCycleEntry`, `knownUnitCycle`, `sagUnitCycle` |
| ✅ Entry | [set_sag_adjustment.dart](lib/widgets/set_adjustment/set_sag_adjustment.dart) + `cycle`/`icon` params on [set_numerical_adjustment.dart](lib/widgets/set_adjustment/set_numerical_adjustment.dart) |
| ✅ Display | [display_sag_adjustment.dart](lib/widgets/display_adjustment/display_sag_adjustment.dart) + `cycle` param on [toggleable_unit_value.dart](lib/widgets/display_adjustment/toggleable_unit_value.dart) |
| ✅ Edit page | [sag_adjustment_page.dart](lib/pages/adjustment/sag_adjustment_page.dart) — Travel/Stroke field, no unit picker, no min/max |
| ✅ Routing | [component_page.dart](lib/pages/component_page.dart), [person_page.dart](lib/pages/person_page.dart), [component_actions.dart](lib/utils/component_actions.dart) — `SagAdjustment` case *before* `NumericalAdjustment` at all 10 sites |
| ✅ Presets | [component_add_adjustment.dart](lib/widgets/sheets/component_add_adjustment.dart) — fork + shock SAG presets are now `SagAdjustment` |
| ✅ Tests | [sag_adjustment_test.dart](test/models/sag_adjustment_test.dart) (14), [set_sag_adjustment_test.dart](test/widgets/set_adjustment/set_sag_adjustment_test.dart) (3) |

**Confirmed by implementation:** zero DB migration, zero schema change, no new `AdjustmentType`
value, `RatingMetrics` untouched — `toCompanion` derives `type` from the JSON `type` string and
dumps the payload wholesale, so `subtype` rides along for free.

**Deviations from the plan as written:**

1. **No lazy travel prompt (dropped, not just deferred).** Persisting travel from the *set*
   widget means editing an adjustment *definition* from a value-entry surface, which
   `AdjustmentSetList` has no callback for — too much plumbing for the payoff. Instead the mm
   toggle is simply **not offered when travel is unknown** (sag then behaves as a plain % field),
   and travel is set where definitions belong: the SAG page, reached by every preset via the
   template flow. In practice the user enters travel when first adding the adjustment.
2. **A generic unit-cycle abstraction was extracted** rather than duplicating the toggle logic.
   `ToggleableUnitValue` and `SetNumericalAdjustmentWidget` now take an optional `cycle`; the
   catalog path rotates so entry 0 is always the storage unit, preserving the existing tap order.
   This is what keeps sag's %↔mm and the catalog's psi↔bar on one code path.
3. **A travel chip was added** to [adjustment_properties.dart](lib/widgets/items/adjustment_properties.dart)
   so the preset sheet and name tooltip show the reference length.
4. **Version stays 2** (§11 unchanged). `SagAdjustment.toJson` inherits `version` from
   `NumericalAdjustment` via the spread, so a future bump there **must** be mirrored in
   `SagAdjustment.fromJson`'s guard or sag payloads would fail to decode their own output. Noted
   at both ends in code; the round-trip test fails loudly if they ever desync.

**Pre-existing, unrelated:** `test/widgets/display_adjustment_robustness_test.dart` has 2 failures
on this branch that predate this work — they expect `find.text('12 mm')`/`'6 clicks'`, but the
2b2425c0 `ToggleableUnitValue` refactor renders value and unit as separate `Text` widgets. Stale
expectations, not a widget bug.

## 2. Verdict up front

The feature is worth building, and the architectural risk is manageable **if SAG is not a
new fundamental type**. The recommended shape (Approach C below) is:

> `SagAdjustment extends NumericalAdjustment` in Dart for clean widget dispatch, but
> **persisted as `type: numerical`** with a `subtype: "sag"` payload discriminator.
> The stored value stays a plain `double` percent. Every code path that doesn't know
> about SAG keeps treating it as a numerical adjustment — which is always correct.

This keeps the 6 primitives as the storage fundament, makes numerical↔SAG conversion a
metadata edit (no value/ID migration), degrades gracefully in old app versions and
backups, and establishes a reusable pattern for future special types (tire pressure, …).

---

## 3. Current architecture (facts the plan builds on)

### Type system
- `Adjustment` is a **sealed class** ([adjustment.dart:27](lib/models/adjustment/adjustment.dart#L27))
  with exactly 6 subtypes mirrored in the `AdjustmentType` enum
  ([adjustment.dart:18](lib/models/adjustment/adjustment.dart#L18)):
  boolean, categorical, step, numerical, text, duration.
- `NumericalAdjustment` holds `min`/`max`, stores values as `double`, serializes with a
  **JSON version guard** (currently v2, [numerical_adjustment.dart:54](lib/models/adjustment/numerical_adjustment.dart#L54));
  `fromJson` ignores unknown keys.
- `StepAdjustment` already carries a `visualization` enum
  ([step_adjustment.dart:3](lib/models/adjustment/step_adjustment.dart#L3)) — precedent
  for per-type presentation variants that are *not* new types.

### Persistence
- DB table `Adjustments` stores `type` as `textEnum<AdjustmentType>()` plus a
  `jsonPayload` for subclass extras ([adjustments.dart:33-36](lib/database/tables/adjustments.dart#L33-L36)).
  `RatingMetrics` reuses the same enum ([rating_metrics.dart:16](lib/database/tables/rating_metrics.dart#L16)).
- Row → model goes through `Adjustment.fromJson`
  ([mappers.dart:84-97](lib/database/mappers.dart#L84-L97)); model → row resolves the
  enum via `firstWhere` on the JSON `type` string ([mappers.dart:246](lib/database/mappers.dart#L246)) —
  **an unknown `type` string throws**, in DB mapping and in backup import alike.
- Setup values are decoded per `AdjustmentType` in
  [adjustment_value_codec.dart](lib/database/adjustment_value_codec.dart).

### Exhaustive dispatch sites (what a new sealed subtype touches)
| Site | Purpose |
|---|---|
| [adjustment_set_list.dart:58,75](lib/widgets/lists/adjustment_set_list.dart#L75) | set-widget dispatch |
| [display_adjustment_list.dart:35](lib/widgets/display_adjustment/display_adjustment_list.dart#L35) | display-widget dispatch |
| [adjustment_compact_display_list.dart:516](lib/widgets/lists/adjustment_compact_display_list.dart#L516) | compact display |
| [component_details_page.dart:193,293,552](lib/pages/details/component_details_page.dart#L193) | sorting, chart/table eligibility |
| [adjustment_properties.dart:60](lib/widgets/items/adjustment_properties.dart#L60) | property chips |
| [component_actions.dart:184-213](lib/utils/component_actions.dart#L184-L213) | add/edit page routing |
| `to_spreadsheet.dart`, `to_text.dart`, `table_column.dart` | exports |
| [adjustment_value_codec.dart](lib/database/adjustment_value_codec.dart) | value (de)serialization per `AdjustmentType` |

Key Dart property exploited below: if `SagAdjustment extends NumericalAdjustment`, all
existing `case NumericalAdjustment():` patterns **still match** a `SagAdjustment` instance.
Switches stay exhaustive without edits; only places that want special SAG behavior add a
`case SagAdjustment():` *before* the numerical case. Unaware code paths automatically get
correct numerical fallback behavior.

### Adjacent recent work
- Branch `unitToggle`: tap-to-cycle unit in `SetNumericalAdjustmentWidget`
  ([set_numerical_adjustment.dart:114](lib/widgets/set_adjustment/set_numerical_adjustment.dart#L114))
  and `ToggleableUnitValue` for display. The SAG %↔mm entry is the *same interaction*,
  except the conversion needs a per-adjustment reference length instead of a global unit table.
- The presets sheet already ships SAG as a plain `NumericalAdjustment` (%) for fork and
  shock ([component_add_adjustment.dart:17,26](lib/widgets/sheets/component_add_adjustment.dart#L17)).
- Planned component preset DB (YAML fork/damper specs in `data/component_presets/`) will
  eventually know travel/stroke per fork/shock model — a future auto-fill source for the
  reference length.

---

## 4. Architecture approaches

### Approach A — Full new fundamental type (`AdjustmentType.sag`)

New sealed subtype + new enum value, persisted as `type: "sag"` in DB and backups.

- ✅ Cleanest conceptual separation; own icon, own pages, own codec entry.
- ❌ **Backward compatibility is the killer.** `textEnum<AdjustmentType>` rows and backup
  JSON with `type: "sag"` make older app versions throw on DB read after a downgrade and
  on backup import ([mappers.dart:247](lib/database/mappers.dart#L247)). There is no
  graceful degradation — the data is *numerically identical* to what the old app could
  display, yet it hard-fails.
- ❌ Touches every dispatch site in the table above, plus `RatingMetrics` implications
  (should "sag" be selectable as a rating metric type? No — but the shared enum drags it in).
- ❌ Sets the precedent that each future special adjustment (tire pressure, …) is another
  enum value with the same blast radius.

**Reject.** The cost is structural, recurring, and pays for nothing the other approaches
don't deliver.

### Approach B — Flag on `NumericalAdjustment` (no new class)

Add `kind: NumericalKind { plain, sag, … }` + optional `referenceLength` to
`NumericalAdjustment` itself.

- ✅ Zero new type; trivial persistence (extra payload keys under version 2); conversion
  is a field edit.
- ✅ Old apps import the backup and simply see a plain numerical adjustment.
- ❌ No type-safe dispatch: every SAG-specific behavior becomes `if (adj.kind == sag)`
  branching inside numerical widgets/pages, which is exactly how god-classes grow.
  `NumericalAdjustment` accumulates fields that are meaningless for 95% of instances.
- ❌ Harder to give SAG its own set/display widgets and edit page cleanly.

Workable, but the widget layer gets uglier with each future kind.

### Approach C — Subclass in Dart, `numerical` in persistence ⭐ recommended — ✅ **implemented**

```dart
class SagAdjustment extends NumericalAdjustment {
  /// Fork travel or shock stroke, always stored in mm. Null = unknown
  /// (mm entry/display disabled until provided).
  final double? referenceTravelMm;
  // min: 0, max: 100, unit: CustomUnit('%') — enforced/defaulted by ctor
}
```

Serialization keeps `type: AdjustmentType.numerical.name` and adds a generic
discriminator, e.g.:

```jsonc
{ "version": 2, "type": "numerical", "subtype": "sag",
  "referenceTravelMm": 150.0, "min": 0, "max": 100, ... }
```

`NumericalAdjustment.fromJson` (or `Adjustment.fromJson`) checks `subtype` and constructs
`SagAdjustment` when recognized, plain `NumericalAdjustment` when the value is unknown —
i.e. **unknown subtypes degrade instead of failing**, by design.

- ✅ Type-safe dispatch where wanted (`case SagAdjustment():` above the numerical case),
  automatic numerical fallback everywhere else (charts, sorting, exports, codec, compact
  lists need *no changes* to stay correct).
- ✅ **No DB migration, no schema change, no new enum value.** `RatingMetrics` untouched.
- ✅ Old app versions (any release that accepts payload v2) import backups gracefully as
  plain numerical — values, IDs, history intact. Caveat: if the old app then *edits* that
  adjustment, its `toJson` drops the unknown keys and the sag-ness is lost. Acceptable:
  data (%) is never corrupted, only the skin is shed. (Bumping to v3 instead would trade
  this silent-downgrade for a hard import rejection — worse for a purely cosmetic delta.)
- ✅ Numerical↔SAG conversion is a payload rewrite with the same `id` (§7).
- ✅ `subtype` is the general mechanism for future special types (§8).
- ⚠️ One structural cost: `NumericalAdjustment` can no longer rely on `runtimeType ==`
  semantics carelessly — its `==` already checks `runtimeType`, which is correct here.
  `deepCopy`/`copyWith` must be overridden in `SagAdjustment` (compiler forces `deepCopy`;
  `copyWith` needs care — a `copyWith` on a `SagAdjustment` must return a `SagAdjustment`).
- ⚠️ Convention needed: any new `switch` over adjustments must list subclass cases before
  their parent. A short note in `adjustment.dart` above the sealed class should state this.

### Approach D — Generic trait/plugin system

Attachable "traits" (derived-entry converters, visualizations, recommendation providers)
on any adjustment, with a registry.

- ✅ Maximally general.
- ❌ Speculative machinery for exactly one concrete consumer today. The registry,
  serialization of trait configs, and UI plumbing would dwarf the feature itself.

**Reject for now.** Approach C's `subtype` discriminator *is* the seed of this system; if
multiple special types ever appear and share behavior, extract the trait layer then, from
real examples — not before.

---

## 5. Reference length (travel/stroke): where does it come from?

| Option | Assessment |
|---|---|
| **Field on the SAG adjustment itself** (`referenceTravelMm`, set in edit page / preset flow) | ⭐ Recommended — ✅ **implemented**. Single source of truth, survives export/import, no cross-entity coupling. |
| Link to a sibling "Travel" adjustment on the component | Fragile (user renames/deletes it; travel is a component *spec*, not a tunable setting). Reject. |
| Component preset DB (`data/component_presets/` YAML) | Great future auto-fill: picking "FOX 36 Factory 160mm" pre-fills `referenceTravelMm: 160`. Phase 3, additive. |
| Ask lazily on first mm-entry attempt | ❌ **Dropped** — needs a definition-edit callback through `AdjustmentSetList` for little gain (§1a). Unknown travel simply hides the mm toggle; the user sets travel on the SAG page, normally when first adding the adjustment. |

Naming in UI: "Travel" for forks, "Stroke" for shocks. Since the adjustment doesn't
know its component's type at model level, use a neutral label ("Travel / Stroke") or pass
the `ComponentType` down to the edit page for the right word (the preset flow has it).

## 6. UI/UX approaches

### 6.1 Value entry (set widget)

**Option E1 — Reuse the unit-toggle interaction ⭐ — ✅ implemented.** `SetSagAdjustmentWidget` looks like
the numerical field, but the tappable suffix cycles `%` ↔ `mm`:
`mm = % / 100 × referenceTravelMm`. Helper text shows the equivalent in the other unit
(exact pattern of [set_numerical_adjustment.dart:176-181](lib/widgets/set_adjustment/set_numerical_adjustment.dart#L176-L181)).
Storage unit is always `%`. If travel is unknown, tapping `mm` opens the travel prompt (§5).
Consistent with the just-built unitToggle UX — users learn one gesture.

**Option E2 — Two fields side by side (% and mm, mutually updating).** More discoverable,
but doubles the horizontal space in an already tight row (`flex: 3` value column) and
diverges from every other adjustment row. Reject for the list row; fine inside a
future full-screen "setup wizard".

**Option E3 — Measurement dialog** ("zip-tie method": enter measured length, get %).
Nice guided flow but heavier; could be added later as an icon-button beside the field.

**Option E4 — Vertical slider as the input.** Sliders are poor for precise % values and
tall rows break list rhythm. Use vertical visualization for *display*, not input.

**Recommendation:** E1 now; E3 as optional phase-3 nicety.

### 6.2 Display

**Option D1 — Text with both units ⭐ (phase 1) — ✅ implemented.** Extend the `ToggleableUnitValue`
idea: value shows `28 %`, tap toggles to `42 mm` (computed). Minimal, consistent.

**Option D2 — Inline mini-gauge (phase 2).** Give sag a compact visual read of *how deep
into the travel* the value sits, so a number like "28 %" also lands as a picture.

Concretely: a thin bar (vertical reads most like a fork leg; horizontal packs into the row
more easily) drawn as a `CustomPaint`, where the filled fraction = sag ÷ 100. 0 % is empty
(topped-out), 100 % is full (bottomed-out). It replaces nothing — it sits beside the
existing `ToggleableUnitValue` text in the `flex: 3` value column, so tapping still toggles
% ↔ mm and the gauge just mirrors the same stored percentage. A subtle tick or fill-height
label can mark the current value; the point is a glanceable "roughly a quarter in" without
reading digits. Because sag is bounded 0–100 by construction, the fraction is always well-
defined with no extra config — this is why it survives dropping recommended ranges: the bar
needs only the value, not a target band. Keep it small and low-contrast (the list row must
not shout); it is decoration on top of the authoritative number, not a replacement for it.

**Option D3 — Full fork/shock illustration with o-ring indicator.** Charming but a lot of
asset/paint work for one row; consider only for a dedicated suspension-setup screen later.

**Recommendation:** D1 in phase 1 (done), D2 as the phase-2 visualization, D3 not planned.

### 6.3 Edit page — ✅ implemented

`SagAdjustmentPage` = `NumericalAdjustmentPage` layout + "Travel / Stroke (mm)" field.
Since min/max/unit are fixed for SAG (0–100 %), the page is actually *simpler* than the
numerical one — hide the unit picker and min/max inputs. Route it in
[component_actions.dart](lib/utils/component_actions.dart#L184)
with a `SagAdjustment` case above the numerical one.

## 7. Converting existing adjustments (existing users) — ⬜ phase 2

Under Approach C this is metadata-only — no value migration, no ID change:

- `setup_adjustment_values` rows key on `adjustment.id` and decode via
  `AdjustmentType.numerical` — both unchanged. History, charts, spreadsheet exports keep
  working on the same rows.
- **Upgrade:** in `NumericalAdjustmentPage` (edit mode), when the adjustment looks like a
  SAG candidate — unit is `%` **and** name contains "sag" (case-insensitive), optionally
  gated to fork/shock components — show a low-key affordance (an outlined banner or an
  overflow-menu item): *"Convert to SAG adjustment — unlocks mm entry and gauge"*.
  Tapping asks for travel/stroke, then saves the same adjustment `id` re-serialized with
  `subtype: "sag"`. One-tap, reversible.
- **Downgrade:** "Convert to plain numerical" in `SagAdjustmentPage`'s menu — drops the
  subtype keys. Free under Approach C, and a good escape hatch.
- Do **not** auto-convert silently on load: users may have % adjustments named "sag"
  measured against something else; conversion changes UI behavior and should be explicit.

## 8. Generalization: SAG is the first of several special types — ✅ mechanism in place

The `subtype` discriminator is the general contract (`adjustmentSubtypeKey`, live in
[sag_adjustment.dart](lib/models/adjustment/sag_adjustment.dart)). Rule that keeps it safe:

> **A subtype must never change the value shape of its base type.** SAG stores a `double`
> percent exactly like any numerical adjustment. Subtypes may add *config* (e.g. reference
> travel) and *presentation* (derived entry units, gauges), never a new value encoding.

Consequences:
- `adjustment_value_codec.dart`, exports, comparison/highlighting, charts, and old-version
  compatibility hold automatically for any future subtype.
- The mechanism is deliberately generic (`adjustmentSubtypeKey`, not a sag-specific flag), so
  if another special adjustment is ever wanted it slots in the same way — subclass +
  `subtype:` discriminator + preset-only creation — with the same zero-migration story. No
  such second subtype is planned; this section documents that the door is open, not that we
  intend to walk through it.

## 9. Discoverability without clutter — ✅ implemented

- ✅ **Creation only via the presets section** of the add-adjustment sheet: the fork/shock SAG
  presets are now `SagAdjustment` (discipline notes retained; `referenceTravelMm: null` →
  filled in on the template page, which every preset tap routes through).
  Recommended-range defaults are phase 2.
- ✅ The **"Custom Adjustment" section stays at 5–6 entries** — no new tile. `switch(T)` in the
  custom-add path matches type literals exactly, so `SagAdjustment` is unreachable there by
  construction. The §7 upgrade path (phase 2) is the escape hatch for unusual components.
- ✅ Icon: `SagAdjustment.iconData = Icons.height`, everything else visually identical to
  numerical rows.

## 10. Does this break the "5–6 fundamental types" idea?

No — it reframes it. The `AdjustmentType` enum is unchanged at 6 entries. ⬜ Writing the
reframing into `CLAUDE.md` is still open:

> The 5–6 fundamental types define **value shapes** (bool, number, step, category set,
> text, duration) and remain the closed, load-bearing set: persistence, codecs, exports,
> diffing, and rating metrics are built on them and only them. **Subtypes** are semantic
> refinements of one fundamental type that add configuration and presentation but reuse
> the parent's value shape end-to-end.

The fundament stays 6. What changes is the admission that "numerical" spans both
anonymous quantities and rich domain concepts — and the architecture now has a sanctioned
slot for the latter that doesn't multiply the fundament.

## 11. Compatibility matrix (Approach C) — ✅ holds as implemented

| Scenario | Outcome |
|---|---|
| New app, DB row with `subtype: "sag"` | `SagAdjustment`, full features |
| Old app (accepts payload v2), same row / backup import | Plain numerical %, fully usable; sag config dropped only if the old app *edits* that adjustment |
| New app importing old backup | Plain numerical (no subtype key) — §7 upgrade offer applies |
| New app, payload with unknown future `subtype: "tirePressure"` | Degrades to plain numerical instead of throwing — forward compatible |
| DB schema | Unchanged (no migration, stays version 3) |

## 12. Phased implementation sketch

**Phase 1 — Model + entry (core value):** ✅ **done 2026-07-16**
1. ✅ `SagAdjustment extends NumericalAdjustment` (`referenceTravelMm`, fixed %/0–100,
   `deepCopy`/`copyWith`/`==`/`toJson`/`fromJson` with `subtype` discriminator; icon).
   ✅ Unit tests: round-trip, unknown-subtype degradation, old-payload import.
2. ✅ `SagAdjustmentPage` (template/add/edit/duplicate) + routing cases in
   `component_actions.dart`, `component_page.dart`, `person_page.dart`.
3. ✅ `SetSagAdjustmentWidget` with %↔mm toggle (E1); dispatch case in
   `adjustment_set_list.dart`. Travel is entered on the SAG page (mm toggle simply hidden
   until it's known) — no lazy prompt.
4. ✅ Display case (D1: toggleable %/mm) in `display_adjustment_list.dart`.
5. ✅ Upgrade fork/shock presets in `component_add_adjustment.dart`.

**Phase 2 — Existing users + visualization:**
6. ⬜ Convert-to-SAG affordance in `NumericalAdjustmentPage` (+ reverse conversion).
7. ⬜ Inline mini-gauge (D2) in the set/display widgets — a small travel-depth bar beside
   the value. Needs only the stored percentage, no extra config.

**Phase 3 — Preset DB auto-fill:**
8. ⬜ Once the component preset DB ([[project-component-preset-db]], `data/component_presets/`)
   is wired into component creation, pre-fill `referenceTravelMm` from the selected fork/shock
   trim (`travel_mm` for forks, `stroke_mm` for shocks). Those specs are lists of offered
   options, so: auto-fill when a trim lists a single value, otherwise pre-select from the
   offered set. Purely additive — the manual Travel/Stroke field stays the fallback.

## 13. Open questions

1. ✅ **Settled — % is stored.** The mm value is never stored: % is travel-independent and
   survives a travel correction. `toMillimeters`/`fromMillimeters` derive mm on the fly.
2. ⚠️ **Still open.** When `referenceTravelMm` changes later, stored % values stay valid but
   historic mm readings for old setups are recomputed with the *new* travel. Implemented as
   proposed (accepted, not snapshotted) — revisit if it bites.
3. ❌ **Dropped — no recommended-range fields.** Not worth the model/UI surface. The
   discipline guidance (fork 15–25 %, shock 20–35 %) stays as prose in the preset `notes`,
   which the name tooltip already shows. The phase-2 gauge needs only the value, not a band.
4. ✅ **Settled — fallback is fine.** [adjustment_compact_display_list.dart:516](lib/widgets/lists/adjustment_compact_display_list.dart#L516)
   keeps `case NumericalAdjustment()`, which matches sag and renders it as a plain %.
   Same for charts, sorting, exports and the value codec — all untouched.
5. 🆕 **New.** Sag on a **person** is reachable in code (the routing cases exist defensively)
   but not in the UI, since presets are keyed by `ComponentType`. Its travel label falls back
   to "Travel / Stroke". Fine, or should person sag be blocked outright?
