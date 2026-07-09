# Adjustment Units & Conversion — Design Options

**Date:** 2026-07-09
**Status:** Decided — kept as the option/decision record. Final plan: [20260709_adjustment_unit_conversion_implementation.md](20260709_adjustment_unit_conversion_implementation.md) (chosen: A2 + C2 + B1 + D1 + E2).

## Goals

1. **Unit toggle while entering values** — in `SetNumericalAdjustmentWidget`, tap the unit to enter the value in another compatible unit (e.g. type `4.5 bar` for a `psi` adjustment).
2. **Consistent data after unit edits** — when the user edits an Adjustment's unit, existing setup/rating values must not silently become wrong.
3. **Structured units instead of free strings** — today `"km/h"`, `"kph"`, `"KM/H"` are three different units. Need a migration strategy toward unit-system + custom-unit.
4. **General UX improvements** around units.

## Current State

| Where | What |
|---|---|
| `Adjustment.unit` ([adjustment.dart](../lib/models/adjustment/adjustment.dart)) | Free `String?`, max 10 chars, on the **base class** (all 6 adjustment types have it; UI-relevant mainly for numerical) |
| `Adjustments` table | `unit TEXT NULL` — plain string |
| `RatingMetrics` table | Duplicates the adjustment columns incl. `unit TEXT NULL` |
| `SetupAdjustmentValues` / `RatingEntryValues` | `value TEXT` — **no unit stored**; implicitly in the adjustment's unit *at the time of saving* |
| `NumericalAdjustment.min/max` | Doubles in the adjustment's unit |
| Unit edit today | [numerical_adjustment_page.dart](../lib/pages/adjustment/numerical_adjustment_page.dart) shows a red warning: *"Editing Unit will not update existing setup values!"* — nothing is recalculated |
| `units_converter` 3.2.0 | Already a dependency; used for weather units (temperature / wind speed / precipitation) in `context_weather.dart` + `app_settings.dart` |
| Backups | JSON export/import with per-model `version` fields (`NumericalAdjustment.toJson` is v1, `Setup.toJson` is v6); Google Drive backup on Android |
| Component presets | YAML DB creates adjustments with units like `psi`, `mm`, `clicks`, `%` |

### Relevant `units_converter` capabilities

- Properties useful for this domain: `PRESSURE` (psi, bar, kPa, atm…), `LENGTH` (mm, cm, in…), `MASS` (kg, lb, g…), `TEMPERATURE`, `SPEED` (km/h, mph, m/s), `ANGLE`, `VOLUME`, `TORQUE`, `TIME`.
- `SimpleCustomProperty` allows defining custom conversion ratios → we can add bike-specific quantities the package lacks, most importantly **spring rate** (`lbs/in` ↔ `N/mm`, factor ≈ 0.17513).
- **Not convertible** (must remain "custom" units): `%` (sag), `clicks`, `turns`, `tokens`/volume spacers, `PSI front/rear` composites, etc.

---

## Decision A — Unit data model

How should a unit be represented on `Adjustment` (and `RatingMetric`)?

### A1: Keep free string, resolve at runtime via alias lookup

Keep `unit String?` as-is. A `UnitResolver` maps known strings/aliases (`"kph"`, `"km/h"`, `"KPH"` → `SPEED.kilometersPerHour`) at runtime. Unrecognized strings behave like today (no conversion offered).

- **Pros:** Zero schema change, zero DB migration, zero backup-format change. Old backups import unchanged. Smallest diff.
- **Cons:** Alias table must be maintained forever; resolution logic runs everywhere a unit is used. Two adjustments can still hold different spellings of the same unit ("km/h" vs "kph" look different in UI). No user-visible normalization. Ambiguity is never cleaned up ("in" = inches or …?). Custom-vs-known distinction is implicit and fragile.

### A2: Structured unit — quantity + unit id, with custom fallback (recommended candidate)

Model the unit as a sealed type:

```dart
sealed class AdjustmentUnit {
  String get label;                      // display string, e.g. "psi"
}
class KnownUnit extends AdjustmentUnit { // convertible
  final UnitQuantity quantity;           // pressure, length, mass, …
  final String unitId;                   // e.g. "psi" → PRESSURE.psi
}
class CustomUnit extends AdjustmentUnit { // not convertible
  final String label;                    // "clicks", "tokens", …
}
```

Persisted in the existing `unit TEXT` column as a canonical encoding (e.g. `pressure:psi` vs `custom:clicks`), or in two new columns (`unit_quantity`, `unit_id`). A one-time migration normalizes existing strings via the alias table; unmatched strings become `CustomUnit`.

- **Pros:** Conversion capability is explicit and type-safe (`KnownUnit` → offer toggle; `CustomUnit` → behave like today). Alias mess is cleaned up **once** at migration instead of forever at runtime. Display stays a simple `label`. Enables a proper unit picker UI. Custom units keep full freedom.
- **Cons:** Requires a schema/serialization decision + migration + JSON version bumps (`Adjustment` v1→2, backup import path must normalize old versions). More upfront work. Alias table still needed once (for migration + import of old backups).

### A3: Full user-extensible unit registry

Like A2, but users can also define their own *convertible* units (name + factor to a base unit), stored in a new `units` table; adjustments reference a unit id.

- **Pros:** Maximum power (exotic units, e.g. proprietary spacer volumes); single source of truth for units; `SimpleCustomProperty` supports this directly.
- **Cons:** Significant scope: new table, CRUD UI, referential integrity in backups/exports, cross-device merge questions. For a bike app the useful unit set is small and known — likely over-engineering. Can be added later on top of A2 if ever needed.

---

## Decision B — In which unit are values stored?

### B1: Store values in the adjustment's unit (status quo); convert values when the unit is edited (recommended candidate)

Values remain "in the unit of their adjustment". The **unit-edit event** becomes the trigger that rewrites all affected stored values (setups, previous values are derived, rating entry values, min/max).

- **Pros:** No change to value storage or the dozens of read sites (charts, history table, compare, export). What the user typed is what is stored and re-displayed — no float round-trip artifacts in the common path. Migration only touches the `unit` column. Unit *toggle* during input simply converts to the storage unit on commit.
- **Cons:** Unit edit becomes a heavier, transactional operation (bounded: one adjustment's values). Rewriting rows churns `lastModified` on setups → noise in Drive-backup merges (mitigable: update only the value rows, not setup `lastModified` — needs a decision). Converted historical values get rounded once per unit change (repeated back-and-forth edits could drift — mitigate by storing enough decimals, e.g. `0.#####`).

### B2: Store values (and min/max) in SI base units; convert for UI everywhere

`SetupAdjustmentValues` always holds the SI value (Pa, m, kg…); every read/write site converts to the adjustment's display unit.

- **Pros:** Unit edit becomes a metadata-only change — nothing to rewrite, ever. Display-unit toggle is trivially cheap. Theoretically the "clean" model.
- **Cons:** Very large blast radius: every UI read/write, chart, history table, CSV/JSON export, validation, preview must convert — one missed site shows Pascals. One-time migration must convert **all existing values** (risky, irreversible without backup). Backups from older app versions need conversion on import forever. "What you typed" is lost: 65 psi stores as 448159.5 Pa and may re-display as 64.99999 without careful precision handling. Custom units have no SI base → dual code path anyway. High effort, high regression risk.

### B3: Store the unit alongside each value row

Add `unit` to `SetupAdjustmentValues`/`RatingEntryValues`; each value knows its own unit.

- **Pros:** Historically exact — a setup snapshot records what was actually entered, in the unit of that day. Unit edits never touch old rows. No migration of value contents (backfill unit from the adjustment).
- **Cons:** Comparison/charting/highlighting logic must normalize on every read (mixed-unit series). "Previous value" diff highlighting must convert. Schema change on two tables + backup format change for Setup (v6→v7). Complexity moves into every consumer, permanently. Probably the worst effort/benefit ratio here.

---

## Decision C — Migration strategy for existing unit strings

(Only relevant if A2/A3 chosen; A1 needs no migration.)

### C1: Lazy / runtime-only normalization

Don't touch stored data; parse the string into a structured unit on model load, write back canonically only when the user next saves that adjustment.

- **Pros:** No Drift schema migration; gradual; trivially safe.
- **Cons:** DB stays inconsistent indefinitely; import/export and any raw-DB feature must keep handling legacy spellings; two formats coexist forever.

### C2: One-time Drift migration (schema v3 → v4) (recommended candidate)

Migration rewrites `Adjustments.unit` + `RatingMetrics.unit` to the canonical encoding using the alias table; unmatched → `custom:<original>`. Backup **import** path applies the same normalization to old JSON versions (this code must exist regardless, for old backups).

- **Pros:** After one migration, exactly one format exists in the DB. Runtime code is simple. The alias table is still needed for backup import, but isolated in one place.
- **Cons:** Requires schema version bump + migration test. A wrong alias mapping mislabels units at scale (mitigate: only map unambiguous spellings; everything else → custom, user can re-assign in UI).

### C3: Keep original string + add structured columns

Add `unit_quantity`/`unit_id` columns, keep the old `unit` string untouched as display text.

- **Pros:** Nothing user-visible changes; original spelling preserved ("kph" users keep seeing "kph"); rollback-friendly.
- **Cons:** Two sources of truth that can diverge; every writer must maintain both; the alias mess is preserved in the UI instead of cleaned up.

---

## Decision D — Unit toggle UX in `SetNumericalAdjustmentWidget`

Precondition: the adjustment has a `KnownUnit`. For `CustomUnit`/no unit, the field behaves exactly as today.

### D1: Tap the unit suffix to cycle through a curated shortlist (ephemeral)

Suffix text becomes tappable (`psi → bar → kPa → psi`). While in an alternate unit, the typed value is converted back to the adjustment's storage unit on commit (`onChanged` still reports storage-unit values, so no caller changes). Field re-displays converted value when toggling. Min/max validation messages convert too. Toggle state resets when the sheet/page closes.

- **Pros:** Matches the requested interaction 1:1. Zero persistence, zero schema impact. Curated shortlists (pressure: psi/bar/kPa; length: mm/cm/in; mass: kg/lb) keep the cycle short and useful.
- **Cons:** Cycling breaks down if a quantity has many units (mitigated by shortlist). Discoverability of "tap to toggle" is low (mitigate: subtle affordance, e.g. underline or swap icon). User must re-toggle every time (it's per-input ephemeral).

### D2: Tap opens a small unit menu (bottom sheet / dropdown)

Same conversion mechanics as D1, but tapping shows all compatible units to pick from.

- **Pros:** Scales to any number of units; more discoverable than blind cycling; one tap + one pick.
- **Cons:** Two interactions instead of one for the common "the other unit" case; heavier UI for what is usually a binary metric↔imperial flip.

### D3: Persisted per-adjustment display unit

Like D1/D2, but the chosen unit is saved (e.g. `displayUnit` column or on the fly via the existing unit-edit path) so the adjustment shows that unit everywhere from then on.

- **Pros:** "Set once, forget" — imperial users never toggle again. Naturally unifies with Decision E (a persisted toggle *is* a unit edit if values are stored per B1... or is metadata-only under B2).
- **Cons:** Under B1, silently persisting a display unit ≠ storage unit reintroduces the two-unit bookkeeping of B3, *or* every toggle rewrites values like a unit edit (surprising side effect from a small tap). Blurs the line between "enter in other unit once" (the stated goal) and "change the adjustment's unit" (already exists via edit page). Suggest: **not now**; D1/D2 first, revisit if users ask.

---

## Decision E — Behavior when editing an Adjustment's unit

### E1: Always auto-convert values

If old and new unit are both `KnownUnit` of the same quantity → convert all setup values, previous values, rating entry values, min/max, silently. Otherwise (custom involved, or quantity change) keep numbers and warn like today.

- **Pros:** Zero extra UI; data always consistent; "it just works".
- **Cons:** Sometimes the user *means* reinterpretation ("I mislabeled this as bar, it was psi all along") — auto-conversion would then corrupt every historical value. No way out except manual re-edit of all setups.

### E2: Dialog on save — "Convert values" vs "Keep numbers" (recommended candidate)

When the unit changed and conversion is possible, ask:

> Unit changed from **psi** to **bar**.
> • **Convert values** — 65 psi becomes 4.48 bar (recommended)
> • **Keep numbers** — 65 psi becomes 65 bar (values were mislabeled)

If conversion is impossible (custom unit involved), show the current warning, keep numbers.

- **Pros:** Handles both real-world intents (unit *migration* vs label *correction*). Explicit, no silent data rewriting. Replaces today's scary-but-useless warning with an actual solution.
- **Cons:** One more dialog; needs a well-written explanation; conversion is transactional work across `SetupAdjustmentValues` + `RatingEntryValues` + min/max (single Drift transaction; bounded per adjustment).

### E3: Restrict unit edits to within the same quantity

Once structured, the edit UI only allows picking another unit of the same quantity (or switching to/from custom with the keep-numbers warning).

- **Pros:** Simplest mental model; conversion always well-defined.
- **Cons:** Blocks legitimate "this adjustment is actually a different kind of measurement" corrections; users will fight the restriction. Better as validation/UX inside E2 than as a hard rule.

---

## Cross-cutting details (apply to most combinations)

- **Rating metrics**: `RatingMetrics` mirrors `Adjustments` — everything above (model, migration, edit-conversion, toggle in entry widget) applies to numerical rating metrics + `RatingEntryValues` too.
- **min/max**: must convert together with values (E) and with the input toggle (D — validate in storage unit, display bounds in the active unit).
- **Precision**: define one formatting rule for converted values (existing `NumberFormat('0.#####')` in `Adjustment.formatValue` is a good default); store converted values with full precision, round only for display, to avoid drift on repeated conversions.
- **`lastModified` / backup merge**: decide whether converting values bumps each setup's `lastModified` (correct for merge semantics, but floods the change history) or only rewrites value rows. Needs a look at how Drive-restore merges rows.
- **Backup/JSON versions**: A2+C2 → `Adjustment.toJson` v1→2 (structured unit encoding); import path normalizes v1 unit strings via the alias table. `Setup` JSON unaffected under B1.
- **Component presets**: preset YAML units (`psi`, `mm`, `clicks`) map through the same alias table at preset-instantiation time → new adjustments are born structured.
- **Unit input UI** ([numerical_adjustment_page.dart](../lib/pages/adjustment/numerical_adjustment_page.dart)): free-text field becomes a picker: quantity → unit chips (Pressure: psi · bar · kPa …), plus a "Custom…" free-text escape hatch. Autocomplete on the alias table so typing "kph" suggests "km/h".

## Other UX suggestions (Goal 4)

1. **Unit-system default in settings** — a metric/imperial preference (like the existing weather unit settings) that picks the default unit when creating adjustments and the *first* toggle target in D.
2. **Secondary conversion hint** — while typing, show the converted value as helper text below the field ("= 4.48 bar"), even without toggling. Cheap, high value for pressure especially.
3. **Spring rate as custom convertible quantity** — `lbs/in ↔ N/mm` via `SimpleCustomProperty`; very common coil-shock conversion no generic converter app covers.
4. **History table / charts** — once units are structured, the adjustment-history table and value charts can render in the user's preferred unit consistently (follow-up, out of scope here).
5. **Duplicate-unit cleanup nudge** — after migration, adjustments that resolved to the same unit display identically; no action needed, but a one-time "3 units were normalized" note in the changelog/release notes builds trust.

---

## Recommended combination (proposal, to be discussed)

**A2 + B1 + C2 + D1 (with D2 as fallback if shortlists feel arbitrary) + E2**

Rationale: values keep meaning "what the user typed, in the adjustment's unit" (B1) — smallest blast radius and no historical-precision loss in the common path. Structure lives only on the unit itself (A2), migrated once (C2). The two user-facing features (D toggle, E2 convert-on-edit) are then thin layers over one shared `UnitConversionService`.

Suggested phasing:

1. **Phase 1 — Foundation:** `AdjustmentUnit` model + alias table + `UnitConversionService` + Drift migration v3→v4 + backup-import normalization + unit picker UI in adjustment pages. (No behavior change for values yet.)
2. **Phase 2 — E2:** convert-values dialog + transactional value/min-max rewrite (setups + rating entries).
3. **Phase 3 — D:** input toggle in `SetNumericalAdjustmentWidget` (+ conversion helper text).
4. **Phase 4 — polish:** settings default unit system, spring-rate custom property, presets mapping.

## Open questions

1. **Scope:** numerical adjustments + numerical rating metrics, correct? (Step adjustments stay "clicks"; duration already has its own type.)
2. **A2 encoding:** canonical string in the existing `unit` column (`pressure:psi`) vs. two new columns? (String keeps schema/backup diff minimal; columns are cleaner SQL.)
3. **Curated unit set:** which quantities/units should the picker offer? Proposal: pressure (psi, bar, kPa), length (mm, cm, in), mass (kg, g, lb), temperature (°C, °F), speed (km/h, mph, m/s), percent + clicks + turns as blessed *custom* labels, spring rate (N/mm, lbs/in) as custom property.
4. **`lastModified` on conversion:** should converting setup values bump the setups' `lastModified` (affects Drive backup merge)?
5. **D toggle persistence:** confirm ephemeral-per-input is the intent (D1/D2), not a persisted display unit (D3)?
