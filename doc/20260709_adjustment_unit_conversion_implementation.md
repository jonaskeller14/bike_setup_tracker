# Adjustment Units & Conversion — Implementation Plan

**Date:** 2026-07-09
**Status:** Final plan, ready for implementation.
**Overview / decision record:** [20260709_adjustment_unit_conversion.md](20260709_adjustment_unit_conversion.md)

## Decisions

| Decision | Choice |
|---|---|
| A — Unit model | **A2**: sealed `AdjustmentUnit` = `KnownUnit(quantity, unitId)` \| `CustomUnit(label)` |
| A — Persistence encoding | Canonical string in the existing `unit TEXT` column: `pressure:psi`; custom units stay a **plain label** (see below) |
| B — Value storage | **B1**: values stay in the adjustment's unit; conversions rewrite values |
| C — Migration | **C2**: one-time data migration (Drift schema v3→v4) normalizing unit strings via alias table |
| D — Input toggle | **D1**: tap the unit suffix to cycle a curated shortlist; ephemeral; converted to the storage unit on commit |
| E — Unit edit | **E2**: dialog "Convert values" vs. "Keep numbers"; incompatible pairs keep today's warning |
| Scope | Component **and** person adjustments **and** rating metrics (numerical only) |
| `lastModified` | Converting values **bumps** the affected setups'/rating entries' `lastModified` |
| Unit set | Pressure, Length, Mass, Temperature, Speed, Angle, Torque, Volume, **Spring rate** (custom property) + blessed custom labels (%, clicks, turns, tokens) |

## Encoding format

- `KnownUnit` → `"<quantity>:<unitId>"`, e.g. `pressure:psi`, `speed:kilometersPerHour`
- `CustomUnit` → the raw label, unchanged, e.g. `clicks`, `%`

Decode rule: split on the first `:`; if the prefix is a valid `UnitQuantity` **and** the suffix a valid unit id of that quantity → `KnownUnit`; anything else → `CustomUnit(raw)`.

Consequences:

- Legacy plain strings (pre-migration DB rows, old backup JSON) decode naturally as `CustomUnit` — **no JSON version bump required**. Alias normalization ("psi" → `pressure:psi`) happens only in the migration and the backup-import path, not in the runtime decoder, so post-migration exactly one format exists.
- Old app versions importing a *new* backup show `pressure:psi` as a raw label — cosmetic only (values are stored in the adjustment's unit, so numbers stay correct). Preferred over a version bump, which would hard-reject the import.

## Unit catalog

| Quantity | Units (label ↔ `units_converter` id) | Toggle cycle order |
|---|---|---|
| pressure | psi, bar, kPa (`PRESSURE.psi/bar/kiloPascal`) | psi → bar → kPa |
| length | mm, cm, in (`LENGTH.millimeters/centimeters/inches`) | mm → cm → in |
| mass | kg, g, lb (`MASS.kilograms/grams/pounds`) | kg → g → lb |
| temperature | °C, °F (`TEMPERATURE.celsius/fahrenheit`) | °C → °F |
| speed | km/h, mph, m/s (`SPEED.kilometersPerHour/milesPerHour/metersPerSecond`) | km/h → mph → m/s |
| angle | ° , rad (`ANGLE.degree/radians`) | ° → rad |
| torque | Nm, in·lb (`TORQUE.newtonMeter/poundForceInch`) | Nm → in·lb |
| volume | ml, fl oz (`VOLUME.milliliters/usFluidOunces`) | ml → fl oz |
| spring rate | N/mm, lbs/in — **`SimpleCustomProperty`**, 1 lbs/in = 0.175127 N/mm | N/mm → lbs/in |

Blessed custom labels offered in the picker (non-convertible): `%`, `clicks`, `turns`, `tokens`.

### Alias table (migration + backup import + picker autocomplete)

Case-insensitive; only unambiguous spellings are mapped, everything else stays custom. Initial set:

`psi`, `bar`, `kpa` → pressure · `mm`, `cm`, `in`, `inch` → length · `kg`, `g`, `lb`, `lbs` → mass · `°c`, `c`, `°f`, `f` → temperature *(bare `c`/`f` only if we decide they're safe — start without them)* · `km/h`, `kph`, `kmh`, `mph`, `m/s` → speed · `°`, `deg` → angle · `nm`, `n·m`, `n-m` → torque · `ml`, `fl oz`, `oz` → volume · `n/mm`, `lbs/in`, `lb/in` → spring rate

---

## Phase 1 — Foundation (no behavior change for values) ✅ Implemented

### 1.1 New model: `lib/models/adjustment/adjustment_unit.dart` ✅

```dart
enum UnitQuantity { pressure, length, mass, temperature, speed, angle, torque, volume, springRate }

sealed class AdjustmentUnit {
  String get label;                          // display, e.g. "psi", "clicks"
  String encode();                           // canonical persistence string
  static AdjustmentUnit? decode(String? raw);        // strict decode (no aliasing)
  static AdjustmentUnit? fromLegacy(String? raw);    // decode + alias table (migration/import only)
}
class KnownUnit extends AdjustmentUnit { final UnitQuantity quantity; final String unitId; ... }
class CustomUnit extends AdjustmentUnit { final String label; ... }
```

- Unit catalog + alias table live here (single source of truth), including per-unit display label and `units_converter` enum mapping.
- Equality/hashCode on both subclasses (adjustment equality depends on it).

> Implementation note: catalog/alias `unitId`s are sourced from the `units_converter` enums' `.name` (e.g. `PRESSURE.psi.name`) rather than hand-typed string literals, so a typo or package rename is a compile error instead of a silent runtime mismatch.

### 1.2 Conversion service: `lib/utils/unit_conversion.dart` ✅

Top-level helpers (matches the existing actions-pattern style, no state needed):

- `double convertUnit(double value, KnownUnit from, KnownUnit to)` — asserts same quantity; dispatches to the right `units_converter` property; spring rate via `SimpleCustomProperty`.
- `List<KnownUnit> toggleCycle(UnitQuantity q)` — curated shortlist order from the table above.
- `String formatConverted(double v)` — reuse `NumberFormat('0.#####', 'en_US')` (same as `Adjustment.formatValue`); store full `toString()` precision, round only for display.

> Implementation note: the spring-rate factor (N/mm ↔ lbs/in) is derived at runtime from the package's own `FORCE` (1 lbf ≈ 4.4482216 N) and `LENGTH` (1 in = 25.4 mm) conversions instead of a hand-copied `0.175127` constant.

### 1.3 Domain model change: `Adjustment.unit` becomes `AdjustmentUnit?` ✅

- [adjustment.dart](../lib/models/adjustment/adjustment.dart): field type change; `unitSuffix()` → `" ${unit!.label}"`. `toJson` in each subclass writes `unit.encode()`; `fromJson` uses `AdjustmentUnit.decode` (runtime) — the backup-import path pre-normalizes via `fromLegacy` (see 1.6).
- Compiler-driven sweep of all `unit` consumers (pages, `set_adjustment` widgets, list widgets, details pages, history table, charts): mechanical `unit` → `unit?.label` where a display string is needed.
- `RatingMetric` model gets the same treatment (it mirrors the adjustment fields — it wraps `Adjustment`, so no separate unit field needed there).

### 1.4 DB migration (Drift schema v3 → v4, data-only) ✅

- No column changes. In `onUpgrade` step `from3To4`: read all `Adjustments` and `RatingMetrics` rows, rewrite `unit` with `AdjustmentUnit.fromLegacy(unit).encode()`.
- Migration test with representative legacy spellings (`psi`, `PSI`, `kph`, `Klicks`, empty, null).

> Implementation note: the live schema version was already at 11 (not 3) by the time this shipped, so the step landed as `from < 12` (v11→v12), not v3→v4.

### 1.5 Unit picker UI (replaces free-text field) ✅

- [numerical_adjustment_page.dart](../lib/pages/adjustment/numerical_adjustment_page.dart) + `numerical_metric_page.dart`: the unit `TextFormField` becomes a read-only picker field opening a bottom sheet:
  - Sections per quantity with unit chips (Pressure: psi · bar · kPa, …),
  - blessed custom chips (%, clicks, turns, tokens),
  - "Custom…" free-text row (keeps `maxLength: 10`), with alias-aware suggestion: typing `kph` hints "Did you mean km/h (speed)?".
- Other adjustment-type pages keep their free-text unit field (custom-only; no conversion applies).
- `_changeListener` / `_composePreview` / highlight-fill comparisons switch from string compare to `AdjustmentUnit` equality.

### 1.6 Backup import + presets ✅

- Backup import: when deserializing adjustments/rating metrics from JSON (all legacy versions), pass units through `fromLegacy` — old backups arrive normalized.
- Component-preset instantiation: map YAML unit strings through `fromLegacy` so new preset adjustments are born structured.

> Implementation note: the YAML component-preset DB (`data/component_presets/`) isn't wired into `lib/` yet (no loader exists) — `fromLegacy` normalization was applied to the hardcoded preset maps that are live today (`component_add_adjustment.dart`, `person_add_adjustment.dart`, `person_page.dart`). The YAML loader will need the same treatment once built.

### 1.7 Tests ✅

- encode/decode round-trip for every catalog unit + custom edge cases (`a:b` with unknown prefix stays custom).
- Alias mapping table test.
- Conversion correctness per quantity (incl. spring rate 500 lbs/in ≈ 87.56 N/mm) and round-trip precision (psi→bar→psi within ε).
- Migration test (1.4).

---

## Phase 2 — E2: convert values on unit edit ✅ Implemented

### 2.1 Edit-page flow ✅

In `NumericalAdjustmentPage._saveNumericalAdjustment` (and `NumericalMetricPage._saveMetric`), when `mode == edit` and the unit changed:

- **Both `KnownUnit`, same quantity** → show dialog ([unit_conversion_dialog.dart](../lib/widgets/dialogs/unit_conversion_dialog.dart)):
  > Unit changed from **psi** to **bar**. What should happen to existing values?
  > **Convert values** — e.g. 65 psi → 4.48 bar
  > **Keep numbers** — 65 psi becomes 65 bar (values were mislabeled)
- If *Convert*: attach the conversion intent to the result. **`min`/`max` are left exactly as typed** — silently rewriting the bounds during save is opaque (especially if the user just edited them), so only stored historical setup/rating values are converted. The user re-enters bounds in the new unit if desired. *(Deviation from the original plan, which converted min/max too.)*
- Any other pair (custom involved, quantity change) → keep numbers; the red warning tile is replaced by an inline note. A compatible-unit change instead shows an info note that a convert prompt appears on save.

The page's pop result is generalized to a small generic wrapper (`EditResult<T>` in [value_unit_conversion.dart](../lib/models/adjustment/value_unit_conversion.dart)) so the intent survives the staging step. `_editAdjustment`/`_editMetric` push `<Object>` and unwrap `EditResult<Adjustment>`/`EditResult<RatingMetric>` (other adjustment types still pop bare):

```dart
class EditResult<T> {
  final T value;
  final List<ValueUnitConversion> conversions; // (adjustmentId, from: KnownUnit, to: KnownUnit)
}
```

### 2.2 Staging in `component_page.dart` / `person_page.dart` / `rating_page.dart` ✅

- `_editAdjustment`/`_editMetric` stage `result.conversions` into a `Map<String, ValueUnitConversion> _pendingConversions` (keyed by adjustment/metric id) via `_stageConversion`.
- Two edits of the same adjustment before saving **compose** (`ValueUnitConversion.composeWith`): existing `from` is kept, `to` is replaced (values are only rewritten once, on save). A composed round-trip (psi→bar→psi) is a no-op and dropped.
- Removing an adjustment drops its pending conversion; discarding the page drops all pending conversions — stored values untouched (staging keeps E2 transactional with the container save, matching today's semantics where nothing persists until save).

### 2.3 Repository + DAO ✅

- `editComponent` / `editPerson` / `editRating` gained an optional `List<ValueUnitConversion> conversions` parameter and execute everything in **one Drift transaction**:
  1. Persist the component/person/rating with its adjustments (as today).
  2. For each conversion: select affected `SetupAdjustmentValues` (resp. `RatingEntryValues`) rows via the new `SetupsDao.convertAdjustmentValues` / `RatingEntriesDao.convertMetricValues`, decode each via `decodeNumericalValueOrNull` (safe — never throws on non-numeric), convert, write back full-precision string. Unparseable/null values are left untouched. *(Person adjustment values live in `setup_adjustment_values` too, so `editPerson` reuses `convertAdjustmentValues`.)*
  3. Bump `lastModified` on every touched `Setups` (resp. `RatingEntries`) row so Drive-backup merge propagates the converted values.

### 2.4 Tests ✅

- Repository tests: unit edit with *Convert* rewrites setup + rating-entry values and bumps `lastModified`; with *Keep numbers* (no conversions) rewrites nothing and leaves `lastModified` untouched; `editPerson` convert path covered.
- Composition/no-op test on `ValueUnitConversion.composeWith`.
- DAO test: unparseable value rows survive untouched while numeric rows convert.

---

## Phase 3 — D1: input unit toggle in `SetNumericalAdjustmentWidget`

[set_numerical_adjustment.dart](../lib/widgets/set_adjustment/set_numerical_adjustment.dart) — used by setup entry, rating entry (`adjustment_set_list.dart`), and the adjustment-page preview, so all surfaces get the toggle for free.

### 3.1 Behavior

- Only active when `adjustment.unit is KnownUnit` (else the field is unchanged).
- New state `KnownUnit _activeUnit` (init = storage unit; ephemeral, resets on dispose).
- The suffix becomes tappable: tap advances through `toggleCycle(quantity)` (starting from the storage unit) with light haptic feedback (project convention). Visual affordance: small `swap_horiz` glyph next to the suffix text so the tap target is discoverable.
- On toggle: parse controller text (in the previous active unit) → convert → reformat via `formatConverted` → cursor to end.
- **Contract with the parent stays unchanged**: `onChanged` always reports the value converted to the *storage* unit. Keep a `_lastReported` guard so `didUpdateWidget`'s echo comparison works while the controller displays alternate-unit text.
- While `_activeUnit != storage unit`, show helper text with the stored equivalent: `= 4.48 bar` — the user always sees what will be saved.
- Reset (replay) button: sets `initialValue` converted into the active unit.
- Validator: converts `min`/`max` into the active unit for both the bounds check and the message text.

### 3.2 Edge cases

- Empty/invalid text on toggle: just switch the suffix, don't touch the text.
- Highlight logic (`isChanged`/`isInitial`) already compares parsed storage-unit values via `widget.value` — unaffected.

### 3.3 Tests

- Widget test: toggle psi→bar converts displayed text and reports storage-unit value; validation messages show converted bounds; reset shows converted initial value; custom-unit adjustment shows no toggle.

---

## Phase 4 — Polish (small, independent follow-ups)

1. **Release note**: "unit spellings were normalized; tap a unit while entering values to convert".
2. *(Optional, decide later)* Settings default unit system (metric/imperial) controlling the first toggle target and default picker unit — mirrors the existing weather unit settings.
3. *(Optional, decide later)* History table / charts rendering in a preferred display unit.

## Suggested commit slicing

1. ✅ `feat(units): add AdjustmentUnit model, catalog, alias table, conversion helpers` (Phase 1.1–1.2 + tests)
2. ✅ `refactor(units): structured unit on Adjustment/RatingMetric + DB migration + import normalization` (1.3–1.6)
3. ✅ `feat(units): unit picker in numerical adjustment/metric pages` (1.5)
4. ✅ `feat(units): convert stored values when editing an adjustment's unit` (Phase 2)
5. ☐ `feat(units): tap-to-toggle input unit in SetNumericalAdjustment` (Phase 3)
6. ☐ Phase 4 pieces as needed.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Wrong alias mapping mislabels units at scale | Map only unambiguous spellings; everything else stays custom; user can re-assign via the picker |
| Float drift from repeated convert-edits | Store full precision, round only for display; round-trip tests |
| Missed `unit`-as-string consumer after the type change | Type change makes it a compile error — sweep is compiler-driven |
| Backup restore resurrecting pre-conversion values | `lastModified` bump on converted rows (decided) |
| Old app importing new backup | Shows canonical string as label, cosmetic only — accepted trade-off vs. hard version bump |
