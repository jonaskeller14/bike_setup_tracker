# Categorical Adjustment — Multi-Select Support

**Status:** Implemented & tested (behind debug-gated `AppSettings.enableMultiSelect`). Full suite green (460 tests).
**Date:** 2026-07-05

Allow a `CategoricalAdjustment` to hold **multiple** selected options instead of exactly one. Single-select stays the default; the whole feature is gated behind a debug-only feature flag until we choose to ship it.

---

## Key design decisions (as built)

| Decision | Choice | Why |
|---|---|---|
| In-memory / DB / JSON value type | **Always `List<String>`** (single-select = one-element list) | Removes all "String vs List" branching; one representation everywhere. |
| Legacy single `String` values | Tolerated via `categoricalValueAsList()`; self-heal on next save | No migration needed; old data keeps working. |
| Widget count | **One** `SetCategoricalAdjustmentWidget` (both modes) | `multiSelect` only changes sheet behaviour, not the widget. |
| Picker UI | **Bottom sheet** of chips (dropdown-styled dummy field opens it) | Chosen over inline dropdown / `dropdown_button2`; reuses the app's sheet pattern, keeps `FormField` validation. |
| Value order | **Option order** | Deterministic render / diffing. |
| Display separator | **Comma** (`Adjustment.multiValueSeparator`) | Matches exports; single place to restyle. |
| JSON `version` | **Conditional: 2 iff `multiSelect`**, else 1 | Guards multi-select data across cloud sync (old builds refuse v2 rather than silently dropping `multiSelect`), while single-select stays v1-readable. |
| Value equality | `DeepCollectionEquality` via `adjustmentValuesEqual()` | Handles scalars *and* lists (the compact list compares all types). |

---

## What's done

### Model & value helpers
- `CategoricalAdjustment.multiSelect` flag through ctor / `deepCopy` / `==` / `hashCode`.
- `toJson` emits `version: multiSelect ? 2 : 1` + `multiSelect`; `fromJson` accepts `null|1|2`, defaults `multiSelect:false`.
- `Adjustment.fromJson` envelope accepts version 2.
- `isValidValue` unified for `List<String>` (tolerates legacy `String`).
- `Adjustment.formatValue` `List` case → comma-joined (`multiValueSeparator`); empty → `-`.
- Helpers in `adjustment.dart`: `adjustmentValuesEqual` (DeepCollectionEquality), `categoricalValueAsList`, `textValueAsString`.

### Storage / codec
- New `lib/database/adjustment_value_codec.dart`: `encodeAdjustmentValue` (JSON-encode lists, `toString` otherwise) and `decodeCategoricalValue(raw, {multiSelect})` (**multiSelect-aware** — single-select only unwraps a genuine one-element array, so a legacy JSON-looking option name like `[1,2]` is preserved, not split).
- Write paths encode: `setups_dao._upsertValuesMap`, `rating_entries_dao._upsertValues`.
- Read paths decode: `mappers._parseValue` / `_parseTypedValue` (categorical only), with `multiSelect` read from the adjustment's `jsonPayload` via `_payloadIsMultiSelect`.
- Backup JSON: `Setup.adjustmentValuesFromJson` `List` case (text values stay quoted Strings → never confused with categorical arrays).

### UI
- One `SetCategoricalAdjustmentWidget` (`List<String>?`) — dropdown-styled `InputDecorator` + chevron opening `showSetCategoricalSheet`.
- `lib/widgets/sheets/set_categorical.dart` — `Wrap` of chips; single-select tap = select + close, multi-select tap = toggle + stay open; dangling (no-longer-valid) preselected values shown as removable **error-red** chips.
- Routing normalizes at boundaries: `AdjustmentSetList` (categorical → `categoricalValueAsList`, **text → `textValueAsString`** so a stray List can never crash a `TextEditingController`); `AdjustmentDisplayList` likewise.
- Change-detection / sort fixes: `display_categorical_adjustment`, `adjustment_compact_display_list` (×2), and `component_details_page` categorical sort (now via `formatValue`, no more `as String` crash).
- `AppSettings.enableMultiSelect` (persisted, default false) + `FeaturesPage` toggle under `kDebugMode`.
- `CategoricalAdjustmentPage` & `CategoricalMetricPage`: `_multiSelect` state, centralized `_composePreview()`, guarded `CheckboxListTile` (shown when `enableMultiSelect || adjustment.multiSelect`), `List<String>` preview.

### Tests (460 total, green)
- `test/models/categorical_multiselect_migration_test.dart` — version guard, `fromJson`, envelope accept-v2 / reject-v3, codec encode/decode round-trips, legacy `[1,2]` preservation, `categoricalValueAsList`, `textValueAsString`, backup-import shape preservation.
- `test/database/adjustment_value_roundtrip_test.dart` — real DAO→mapper round-trips: JSON-looking **text value stays a `String`**, categorical → `List`, legacy plain string wraps, legacy JSON-like value preserved.
- Updated: `set_categorical_adjustment_test` (List API + multi cases), `adjustment_format_value_test` (List case), `categorical_adjustment_pages_test` (AppSettings provider).

---

## Next stage — TODO

### 1. jsonEncode ALL values in the DB (deferred refactor) — biggest cleanup ✅ DONE (schema v11)
Moved the single value column to a **uniformly JSON-encoded** format for every type, migrated via a **DB schema version bump** (10 → 11).

- **Why:** the root of every prior hack (shape detection, multiSelect-aware decode) was the "one stringly-typed column, re-parse by type" design. Decoding is now keyed on the adjustment `type`, and because every value is real JSON, a text `"[\"a\"]"` (quoted string) can never be confused with a multi-select categorical `["a"]` (JSON array).
- **As built** (`lib/database/adjustment_value_codec.dart`):
  - `encodeAdjustmentValue` → `jsonEncode` for every value; `Duration` → `inMicroseconds` (int).
  - `decodeAdjustmentValue(raw, type)` → thin type switch (`num→double`, `num→int`, `int→Duration`, list-or-scalar → `List<String>`, JSON string → text). A `FormatException` branch degrades a stray non-JSON (un-migrated) row gracefully instead of crashing the load.
  - **Categorical is still single-select in practice** (multi-select unshipped), so callers pass a plain option `String`. It is JSON-encoded as a *scalar* and read back canonicalised to a one-element `List<String>` — the `type` column, not the storage shape, marks it categorical. So the "always `List<String>` in storage" assumption from the top table is relaxed to "always `List<String>` **on read**".
- **Migration** (`AppDatabase.migrateAdjustmentValuesToJson`, `from < 11`): lossless "reparse old → re-encode new" over all `setup_adjustment_values` + `rating_entry_values` rows via `decodeLegacyAdjustmentValue` (old format: scalars via `toString`, categoricals as a plain option string, durations via `Duration.toString()`). Rows already valid JSON (bool/num/step) are skipped.
- **Deleted:** `decodeCategoricalValue` cleverness + `multiSelect` plumbing (`_payloadIsMultiSelect`), and `_parseValue`/`_parseTypedValue`. `textValueAsString`/`categoricalValueAsList` are **kept** — still used by the UI routing boundaries.
- **Tests:** `test/database/adjustment_value_json_migration_test.dart` (real v10→v11 upgrade: text-that-looks-like-a-list, categorical, JSON-looking option name `[1,2]`, duration→micros, both value tables, mapper read-back), plus updated codec/round-trip tests. Full suite green (480).

### 2. Smaller follow-ups
- **`Setup.==` / `hashCode`** still use identity-based `mapEquals` / `Object.hashAll` for the two adjustment maps → two equal-content multi-values compare unequal. Low impact (setups keyed by id), but switch to `DeepCollectionEquality` for correctness.
- **Component-preset DB**: optionally accept `multiSelect: true` on categorical specs in `data/component_presets/SCHEMA.md` + loader (default false keeps all presets valid). See [[project_component_preset_db]].
- **Chips-in-field** (optional UX): the collapsed field is comma-separated text; a wrapped-chips variant could be added later (storage/export unaffected).
- **Manual QA**: run the app and eyeball the sheet — single-select tap-to-close, multi-select toggle, dangling red chips, overflow in the collapsed field, and a backup export/restore round-trip.

### 3. Ship checklist (when leaving debug)
- Decide default (`enableMultiSelect`) exposure — currently `kDebugMode`-only.
- Confirm the v2 version guard behaviour on a real old-build device (multi-select adjustment refuses to load rather than downgrading).

---

## Future feature evaluation — quantities and/or ordered items

**Idea:** richer categorical modes beyond a set of distinct options — e.g. nutrition tracking. Two related-but-distinct wishes:
- **Quantities (a bag):** *"1× bottle isotonic, 3× bars, 2× gels"* — counts matter, order doesn't.
- **Sequence (ordered):** *"bottle → bar → gel → bar"* — order (and interleaved repeats) matter.

Config-wise each is a further flag/enum on `CategoricalAdjustment` (e.g. `CategoricalMode { single, multi, counted, sequence }`). **Not scheduled.**

### Value representation — pick the most general shape now
The representation choice is load-bearing because it constrains which future is reachable without another migration:

| Semantics | Example | Shape that fits |
|---|---|---|
| Set (multi-select, today) | Front, Rear | `List<String>`, canonicalized to option order |
| Bag / quantities (unordered counts) | 3× bars, 2× gels | `Map<String,int>` |
| **Sequence (ordered, repeats, interleaved)** | bottle → bar → gel → bar | `List<String>` in insertion order |

**`List<String>` is the most general shape — it can encode all three** (dedupe → set, count occurrences → bag, keep insertion order → sequence). A `Map<String,int>` is a *counted set*: it preserves the order distinct keys were first added, but **cannot represent the same option at two separate positions** (`bar → gel → bar` collapses to `{bar:2,gel:1}` — interleaving lost).

**Recommendation: standardize on `List<String>` (with repeats, order-preserving in the ordered mode).** Choosing `Map<String,int>` would paint us into a corner — adding order later means a Map→List migration (another schema-version dance on a cloud-synced app). With the list, the **mode flag only changes UI/validation, never the stored shape**. Reserve `Map<String,int>` only if we are certain order will *never* matter and we specifically want the semantic clarity of counts-per-key.

### Why `List<String>` is also the cheaper build
It reuses nearly everything already in place:
- **Storage / codec / backup / routing / equality** — all **reused, zero change**. `DeepCollectionEquality` on a `List` is already order-sensitive, so `[bar,gel] ≠ [gel,bar]` comes free (correct for the sequence mode).
- **`formatValue`** — already joins a list in order. Ordered mode ⇒ `"bottle, bar, gel, bar"` with essentially no change. Quantity mode ⇒ add a small "group consecutive/all repeats into `N×`" render (`"3× bars, 2× gels"`); note grouping is only for the *bag* mode — it would destroy order, so the *sequence* mode keeps the raw list. Flows free to compact list, detail table, CSV/Excel, text export; sort already keys on `formatValue`.

### Effort by layer
- **Model** — *Small.* Add the mode flag/enum; extend `isValidValue` (keys ∈ options; bag: counts ≥ 1), `toJson`/`fromJson` (reuse the conditional-version guard — bump only for the new mode), `==`/`hashCode`/`deepCopy`.
- **Widget / sheet — the dominant cost.**
  - The widget must **stop canonicalizing to option order** in the ordered mode (today it re-sorts via `options.where(selected.contains)`) and preserve raw insertion order.
  - The sheet interaction changes: *bag* ⇒ a `+`/`−` **stepper** per option (internal `Map<String,int>`, emit a repeated `List`); *sequence* ⇒ **append / remove / drag-reorder** an ordered list. Different UX from today's toggle chips — budget *Medium-Large* here.
- **Pages** — *Small.* A guarded mode toggle in `CategoricalAdjustmentPage` + `CategoricalMetricPage`, fed through `_composePreview()` / save.
- **Tests** — *Medium.* formatValue (ordered vs grouped), sheet stepper / reorder behaviour, validator, order-sensitive equality, DB round-trip, version guard.

### Overall
**~Medium effort, and the cost is almost entirely UI** (an order-preserving / stepper sheet), *because* the list representation reuses the existing storage, codec, backup, routing, equality, and most of the display path. The deferred *jsonEncode-all-values* refactor (§1) doesn't change this calculus much for lists (they already round-trip cleanly today) — the main win there is unrelated cleanup. Net: if quantities *or* order is ever wanted, build on `List<String>`; don't introduce `Map<String,int>` unless order is permanently off the table.
