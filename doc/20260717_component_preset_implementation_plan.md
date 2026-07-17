# Component presets — implementation plan

**Date:** 2026-07-17 (revised twice same day)
**Status:** Approved concept → phased implementation plan
**Concept doc:** `doc/20260717_component_preset_concepts.md`

Locked decisions: **A1** (runtime YAML parsing of bundled assets + CI validation
test) + **B2** (lazy, index-first `PresetRepository`) + **C1** (type field
first) + **C4** (contextual catalog card) + **C5** (hybrid picker sheet, damper
choice inside the sheet, year badges) + **C6** (prefill semantics; all
adjustments — including air-spring ones — **declared as literal adjustment
lists in the YAML data**, combined by the parser) + **C2** (name-field
autocomplete). Whole feature behind a new `AppSettings` bool, dev-only for now.

---

## Resolved open questions

### Asset location → keep `data/component_presets/`, declare directly

Declare the existing directories as assets in `pubspec.yaml`:

```yaml
assets:
  - data/component_presets/fork/
  - data/component_presets/shock/
```

Rationale: Flutter does not require assets to live under `assets/`; a directory
declaration bundles every file in it (non-recursive), so a **new brand file is
picked up with zero pubspec changes** — which is the whole AI-edits-YAML
workflow. Mirroring into `assets/` would add a sync step, i.e. re-introduce
exactly the drift problem A1 was chosen to avoid. `SCHEMA.md` sits in the
parent directory and is not declared → repo-only, not shipped. At runtime the
file list is discovered via `AssetManifest` (query prefix
`data/component_presets/`), so no hardcoded brand list either.

### "Pristine name" question → moot: presets are **add-mode only**, name/notes always overwritten

The scenario that raised the question: user picks *FOX 38 Factory* → name is
auto-filled `"FOX 38 Factory"`. They realize it's the wrong fork, re-open the
picker and pick *RockShox ZEB Ultimate*. Under a naive "fill only empty
fields" rule the name field is no longer empty, so it would keep saying
"FOX 38 Factory" while the adjustments say ZEB — a stale-prefill bug.
"Pristine tracking" was the proposed fix: remember whether the current name is
exactly what the last preset wrote and only then allow overwriting.

**Decision — simpler:** preset entry points appear **only in add mode**
(catalog card and autocomplete both check `mode == add`). In add mode a preset
pick **always overwrites name and notes** — that's what a user expects from
"pick your fork from a catalog", it fixes the stale-prefill scenario for free,
and no ownership tracking is needed for text fields. Only the **adjustment
list** keeps a light check: if it is empty or still identical to what the last
preset generated → replace silently; if the user has added/edited adjustments
→ one confirm dialog (*Replace / Keep both / Cancel*).

**Edit mode: no presets in v1.** Reasons: the value of a preset is front-loaded
(initial garage setup); in edit mode "apply a preset" has genuinely destructive
semantics (existing adjustments may already be referenced by saved setup
values, so replacing them silently is dangerous and merging is a UX swamp).
If demand appears, a Phase 5 follow-up can add an explicitly **append-only**
"add adjustments from catalog…" action in edit mode (never touching name,
notes, or existing adjustments) — that variant has no overwrite questions at
all.

### Provenance key → moved to the final optional phase (likely never)

"Provenance" = persisting a machine-readable origin on the component, e.g.
`presetKey: "fork/rockshox/lyrik/ultimate/charger_3_1"`, as a real `Component`
field. It would enable "catalog entry updated — refresh this component's click
ranges?" later. Cost: Drift schema migration (v3 → v4), `Component.toJson`
version bump (4 → 5), backup/Drive-restore compatibility.

**Decision: deferred to Phase 6 (optional), with no intention to build the
update flow.** Auto-updating user components when the catalog changes can
introduce a lot of unexpected behavior (components silently changing under
saved setups); a user who spots a catalog error in their component simply
fixes the component — it's their data, the preset was only a form-filler.
The `presetKey` string still exists **in code** (Phase 1) as the natural
identity for index entries and tests; nothing persists it.

### YAML schema — **literal sparse adjustment lists** on dampers and models

**Decision: dampers and models/trims carry an `adjustments:` list written in
(sparse) Adjustment-model YAML form; the parser combines them.** All other
structure stays exactly as today: brand/model/trim hierarchy, damper key
references, `travel_mm`, `stroke_mm`, `wheel_size`, `year_range`, `url`,
`category`, `sources`. `spring: Air | Coil` stays as informational metadata
(picker subtitles, notes) but no longer drives adjustment generation.

Evaluation that led here (an earlier revision preferred a semantic schema —
`clicks:`, a `spring:` block, an `extra_adjustments:` escape hatch — the
counter-arguments won):

1. **Deduplication is unaffected.** The dedup win comes from the *damper key
   indirection*, not the leaf format. A damper holding a literal adjustment
   list is exactly as shared across models as one holding `clicks` entries.
2. **AI authoring is fine.** An agent with the Adjustment field reference in
   SCHEMA.md transcribes a spec table into
   `{name: Rebound, type: step, max: 17}` as reliably as into
   `rebound: {clicks: 17}`.
3. **One mechanism instead of three.** Every edge case that forced a schema
   mechanism disappears: dual/triple-chamber forks → list two/three pressure
   adjustments; no volume spacers → don't list them; linear volume adjuster →
   list what it is; RockShox from-middle ranges → literal `min: -2, max: 2`;
   lockout/compression-mode → plain boolean/categorical entries;
   unconfirmed click counts → omit the entry, note it in the description.
   The Dart mapper shrinks to sparse-defaults + list concatenation; the
   key→label table, `clicks` normalization, spring interpreter, and escape
   hatch are all deleted.
4. **Strongest CI validation.** Entries map 1:1 to `Adjustment`s, so the CI
   test *instantiates* every adjustment in the catalog and asserts validity —
   no trust gap between schema validation and mapping.

Remaining trade-offs, accepted with mitigations:

- **Coupling to the Adjustment model's evolution — mitigated by
  `Adjustment.fromYaml`.** The mapper lives *in the adjustment model files*:
  a static `Adjustment.fromYaml(map)` dispatcher (on `type`, mirroring
  `fromJson`'s structure) with one factory per subclass holding the sparse
  defaults. Co-location makes the coupling self-maintaining: a field rename
  breaks `fromYaml`'s constructor call at **compile time** right where the
  field is defined; the YAML key names stay stable because the mapper absorbs
  the rename. `fromYaml` is **strict** — unknown YAML keys throw — which
  turns the CI catalog test into a typo detector for data edits. It stays a
  separate code path from the persisted `fromJson` (no `version` field,
  different defaults philosophy); the two must never be mixed. And as noted:
  renames/additions are rare anyway, and the CI test catches every YAML-side
  consequence — this trade-off is now close to zero.
- **Repetition within a file** (e.g. ten air FOX models repeating the same
  Pressure/Volume Spacers lines): YAML **anchors/aliases**
  (`&air_spring` … `*air_spring`) work natively within a file and the Dart
  `yaml` package resolves them — no schema mechanism needed. **Edge-case
  guarantee:** anchors are optional sugar for *identical* lists only — YAML
  cannot extend an aliased list with extra entries (merge keys `<<:` exist
  for maps, not lists). A fork that deviates in any way (extra chamber, no
  spacers, different max) simply writes its full literal list instead of the
  alias. Anchors never constrain expressiveness; SCHEMA.md documents this
  rule.
- **App vocabulary in data** (`type`, `unit`, `visualization`): kept rare via
  sparse defaults — `type` is required; `min: 0`, `step: 1`, `unit: null`
  default; `visualization` defaults per type (step → **counterclockwise**
  dial, the FOX convention: clicks counted from fully closed, opening =
  counterclockwise), so authors only write it for exceptions:
  `visualization: stepper` for Volume Spacers, and `visualization: dial_cw`
  (→ existing `sliderWithClockwiseDial` enum value — no app change needed)
  for dials where increasing value = clockwise, e.g. RockShox Charger
  from-middle adjusters where −2 lies counterclockwise of the 0 detent.
  The allowed values and their enum mapping are documented in SCHEMA.md.

Sparse format (documented in SCHEMA.md, with the defaults table):

```yaml
dampers:
  charger_3_1:
    name: Charger 3.1
    adjustments:
      - { name: High-Speed Compression, type: step, min: -2, max: 2, visualization: dial_cw }
      - { name: Low-Speed Compression,  type: step, min: -7, max: 7, visualization: dial_cw }
      - { name: Rebound, type: step, max: 18, notes: Counted from fully open (fastest) }

forks:
  - model: "Lyrik"
    trims:
      - trim: Ultimate
        travel_mm: [140, 150, 160, 170]
        dampers: [charger_3_1]
        spring: Air                      # informational
        adjustments: &debonair_spring    # anchor → reused by sibling models
          - { name: Pressure, type: numerical, unit: psi }
          - { name: Volume Spacers, type: step, max: 6, visualization: stepper }
```

Supported `type` values: `step`, `numerical`, `categorical` (`options:`),
`boolean`; `text`/`duration` intentionally unsupported in data.
**Combine order** at application time: trim/model `adjustments` → auto-injected
**SAG** → damper `adjustments`. SAG is parser-injected for fork/shock (it's
universal and carries app-specific guidance notes that don't belong in brand
data). Within each list, data order is preserved — it is the on-screen order.

### RockShox from-middle click ranges

Confirmed in `fork/rockshox.yaml`: Charger 3.1/3.2 HSC is physically −2…+2
and LSC −7…+7 (counted from the middle detent), but the file stores
`clicks: 5` / `clicks: 15` with the real range only in a human `note:` — the
information is lost to any mapper. The literal format expresses it directly
(`min: -2, max: 2` → `StepAdjustment(min: -2, max: 2, step: 1)`); the Phase 1
data migration converts these entries, and counting-direction remarks move
into the adjustment's `notes` so the info reaches the user, not just the YAML.

### Other confirmations

- **Damper choice**: an inline final step *inside* the picker sheet (only when
  a trim lists >1 damper).
- **Year badge**: picker rows get a small `year_range` badge (e.g. `2025–26`)
  — data already exists per model; becomes important once pre-2025
  GRIP2/FIT4-era entries are added.

---

## Feature flag

`AppSettings.enableComponentPresets` — default `false`, persisted like the
other flags (getter + setter + `_persistBool` + `loadAppSettings` entry).
Exposed as a toggle in `features_page.dart` inside the existing
`if (kDebugMode)` section (same pattern as *Setup Images*). Gates: catalog
card (C4), name-field autocomplete (C2), and the hint text. The data layer
needs no gating — it does nothing until a UI entry point calls it.

---

## Phase 1 — Data layer: schema rev, data migration, parser, repository, CI test ✅

**Goal:** YAML → typed in-memory index, validated in CI. No UI.

**Status:** ✅ Complete — all 6 brand files migrated, parser + strict
`Adjustment.fromYaml` + repository landed, `test/component_presets_test.dart`
green (31 catalog tests), full suite green (675). SAG auto-injection is deferred
to Phase 2's `buildApplication` per the combine-order note (parser holds trim +
damper specs only).

1. ✅ **Dependencies / assets**
   - ✅ Add `yaml: ^3.x` to `pubspec.yaml` (added `yaml: ^3.1.2`).
   - ✅ Declare `data/component_presets/fork/` and `data/component_presets/shock/`
     as asset directories.
2. ✅ **Schema revision (`SCHEMA.md`)**
   - ✅ Replace the `adjusters` / `compression_positions` sections with the
     sparse `adjustments:` list format (fields, defaults table, supported
     `type` and `visualization` values, anchor-reuse tip, combine order,
     SAG auto-injection note).
   - ✅ `spring: Air | Coil` documented as informational metadata per trim
     (model-level default for shocks stays).
3. ✅ **Data migration of existing files** (AI-agent-friendly task, one commit
   per brand file, CI-checked from the first file on)
   - ✅ Convert every damper's `adjusters`/`compression_positions` into
     `adjustments:` lists — RockShox Charger 3.1/3.2 gain their real
     from-middle ranges (HSC −2…+2, LSC −7…+7) **and
     `visualization: dial_cw`** (increasing value = clockwise; −2 lies
     counterclockwise of the 0 detent) in this pass; check
     `shock/rockshox.yaml` (RC2T, Vivid) for the same convention, and decide
     dial direction per adjuster wherever a brand counts from open.
     *(Shock RC2T/RC2/RCT/Vivid compression is 0–5 from fully closed → default
     `dial_ccw`; rebound counts from open → recorded in each adjuster's
     `notes`. Only the fork Charger 3.1/3.2 use the from-middle + `dial_cw`
     treatment.)*
   - ✅ Add spring `adjustments` to models/trims: pressure chamber(s), volume
     spacers **only where the fork/shock actually takes them** (max where
     published), spring-rate/preload for coil. Where hardware details aren't
     published, list only what is certain and add a follow-up note — never
     guess. *(Pressure for every air trim via a per-file `&air_spring` anchor;
     Spring Rate for coil trims. Volume-spacer counts are not published in any
     current source, so none were generated — each file's follow-ups note the
     gap. Öhlins OTX14 R's lockout lever became a `Lockout` boolean.)*
4. ✅ **Models**
   - ✅ `Adjustment.fromYaml(Map)` — static dispatcher on `type` in
     `adjustment.dart` (mirroring `fromJson`'s structure) + one factory per
     supported subclass (step/numerical/categorical/boolean) holding the
     sparse defaults and the `visualization` name→enum mapping. **Strict**:
     unknown keys throw (`_checkPresetKeys`). Separate code path from the
     persisted `fromJson` (no `version` field) — never mixed.
   - ✅ `lib/models/component_preset.dart` — `PresetAdjustmentSpec`: a trivial
     holder of the raw (normalized) map whose `Adjustment build()` delegates
     to `Adjustment.fromYaml` — keeps instantiation (fresh UUIDs) deferred
     to selection time per B2.
   - ✅ `DamperSpec`: key, name, description, `List<PresetAdjustmentSpec>`,
     freeform info map (remote, firm_mode, …).
   - ✅ `ComponentPresetVariant` (one per brand×model×trim): brand, model, trim,
     `ComponentType`, category, yearRange, url (trim override > model),
     wheelSizes, travel/stroke options, spring label,
     `List<PresetAdjustmentSpec>` (trim-level), resolved `List<DamperSpec>`,
     stanchion, note.
   - ✅ `String get presetKey` → `"<type>/<brand>/<model>/<trim>"` — computed
     index identity only, never persisted (see provenance decision).
5. ✅ **Parser** — pure function `List<ComponentPresetVariant> parseBrandFile(String yamlSource)`
   in `lib/utils/component_preset_parser.dart`: resolves damper refs, applies
   sparse defaults, throws descriptive `FormatException`s on malformed data;
   normalizes `YamlMap`/`YamlList` to plain Dart collections. Takes a string →
   shared verbatim by app (assets) and test (filesystem). YAML anchors are
   handled by the `yaml` package before the parser ever sees them.
6. ✅ **Repository** — `lib/repositories/component_preset_repository.dart`
   - ✅ Plain class (immutable data, no `ChangeNotifier`), provided via
     `Provider` in `main.dart`.
   - ✅ `Future<List<ComponentPresetVariant>> forType(ComponentType)` — on first
     call: `AssetManifest` lookup → load + parse that type's files → cache.
   - ✅ `Future<List<ComponentPresetVariant>> all()` — loads every type dir
     (needed by C2's cross-type search). Same session cache; also populates the
     per-type cache.
   - ✅ Parse errors: log + skip the offending file (app must never crash on bad
     data; CI is the correctness gate).
7. ✅ **CI validation test** — `test/component_presets_test.dart`
   - ✅ Enumerates `data/component_presets/**/*.yaml` via `dart:io`, runs
     `parseBrandFile` on each, then **`build()`s every adjustment spec into a
     real `Adjustment` via the strict `fromYaml`** (unknown keys throw → the
     test doubles as a typo detector for data edits) and asserts:
     `component_type` matches its directory, damper keys resolve (enforced by
     the parser), `min < max` and `step > 0` on step adjustments, categorical
     options non-empty, urls are http(s), no duplicate presetKeys.
   - ✅ This test is the compile-time-safety replacement — **an AI data edit that
     breaks the schema fails CI, not the app.**

**Acceptance:** ✅ `flutter test` green (675 total, incl. 31 catalog tests);
`flutter analyze` clean on all new/changed files; parser returns parsed variants
for fork + shock (exercised by the CI test on the real asset files); app size
delta ≈ nothing (text YAML only).

---

## Phase 2 — Prefill engine (C6 semantics) ✅

**Goal:** turn a selected variant + chosen damper into form-fill data.
Pure logic, fully unit-tested, still no UI.

**Status:** ✅ Complete — `PresetApplication` + `buildApplication` landed in
`lib/models/component_preset.dart` and `lib/utils/component_preset_application.dart`;
SAG discipline notes extracted to shared `kForkSagNotes`/`kShockSagNotes`
constants (reused by `component_add_adjustment.dart`, single source of truth);
13 new tests in `test/component_preset_application_test.dart` green, full suite
green (688 total).

1. ✅ **Result object** — `PresetApplication { String name; ComponentType componentType; String notes; List<Adjustment> adjustments; }`
   produced by `buildApplication(variant, [damper])`. (Not `toComponent()` —
   ComponentPage prefills a form; it never needs a full `Component`.) A single
   damper is resolved automatically so callers may omit it.
2. ✅ **Name builder**: `"<Brand> <Model> <Trim>"`; append damper name only when
   the trim offers >1 damper (disambiguation), e.g.
   `"FOX 36 Factory GRIP X2"`.
3. ✅ **Notes builder**: compact spec block — damper (name + description),
   spring label, travel/stroke options, wheel sizes, stanchion, year range,
   trim note, and the product URL as last line. Damper description mentions
   of unpublished adjusters surface here ("Rebound clicks not published —
   add manually").
4. ✅ **Adjustment assembly** — mostly data-driven now:
   - ✅ `[...trim.adjustmentSpecs, SAG, ...damper.adjustmentSpecs].map(build)`
   - ✅ **SAG**: the existing `SagAdjustment` preset with discipline notes,
     auto-injected for fork/shock. If the trim lists exactly **one**
     travel/stroke option, prefill it as the SAG travel value; if several,
     leave unset (they're in notes).
   - ✅ Fresh UUIDs at build time; nothing is added that the data doesn't
     declare (no generic Lockout/Pressure/Spacers/0–20 clicks).
5. ✅ **Unit tests** — `test/component_preset_application_test.dart`: GRIP X2
   air fork (Pressure + Spacers + SAG + 4 clicks adjustments with 8/18/8/16),
   Charger 3.1 (HSC −2…+2, LSC −7…+7 preserved end-to-end), dual-chamber
   spring (two pressure adjustments), air fork without declared spacers
   (none generated), coil variant (Spring Rate, no Pressure/Spacers),
   compression-mode categorical, multi-damper naming, single-travel SAG
   prefill, multiple-travel SAG unset, combine order = trim → SAG → damper.

**Acceptance:** ✅ assembly + builders fully covered by tests; generated
adjustments are indistinguishable from hand-built ones (fresh UUIDs, valid
per `isValidValue`).

---

## Phase 3 — UI: field order, catalog card, picker sheet, apply logic

**Goal:** the complete C1+C4+C5+C6 flow behind the flag. Add mode only.

1. **Flag** — add `enableComponentPresets` to `AppSettings` + `kDebugMode`
   toggle in `features_page.dart` (do this first; everything below checks it).
2. **C1 — field reorder** in `component_page.dart`: Type dropdown above Name
   field; drop the name autofocus in add mode (first decision is now the
   type). Unconditional (not flag-gated) — it's an improvement on its own;
   flag-gating a field order would double the layout code for no benefit.
3. **C4 — catalog card** — `lib/widgets/preset_catalog_card.dart`
   - Shown when: flag on ∧ mode == add ∧ `_componentType` ∈ {fork, shock}.
     One-line compact card under the Type dropdown: icon + "Choose from
     catalog" + brand teaser (from repository index) + chevron.
   - Not shown in edit/duplicate/replace modes (see resolved question above).
4. **C5 — picker sheet** — `lib/widgets/sheets/component_preset_picker.dart`
   - Modal bottom sheet, same scaffolding as
     `showComponentAddAdjustmentBottomSheet` (SheetHeader, safe area,
     scroll-controlled). Internal `Navigator`-less staging (simple state
     enum: brands → models → trims → damper), back arrow in header.
   - **Search field pinned on top** (only stage 1): typing ≥2 chars switches
     to a flat filtered list across the whole type. Matcher: case-insensitive
     AND-of-tokens over `"brand model trim damper"` (`"rs lyrik ult"` matches
     RockShox Lyrik Ultimate). Matcher lives in a shared helper — Phase 4
     reuses it verbatim.
   - Rows: model rows grouped by `category`; trim rows with subtitle
     (damper · travel range · stanchion) and a **year badge** chip
     (`year_range`). Search-result rows: `"FOX 38 Factory"` + same subtitle
     + badge.
   - **Damper stage inside the sheet**: only when the chosen trim has >1
     damper — large option rows (damper name + description + adjuster
     summary "HSC ±2 · LSC ±7 · Rebound 18", derived from the damper's
     adjustment specs). Single damper → stage skipped, sheet pops with the
     selection.
   - Returns `(variant, damper)` to the caller.
5. **C6 — apply logic** in `_ComponentPageState`
   - `_applyPreset(PresetApplication app)` (add mode only):
     - **name + notes: always overwritten** (see resolved question).
     - componentType: set if null (entry via C4 means it's already set; this
       matters for Phase 4, where a suggestion can set the type).
     - adjustments: if the list is empty or still identical to the previous
       preset application → replace silently. Otherwise one dialog:
       *"Replace N existing adjustments?"* — **Replace / Keep both / Cancel**
       (Keep both appends).
     - track `_lastPresetAdjustments` for that check, call `_changeListener()`.
   - Everything stays editable afterwards; no link back to YAML.

**Acceptance (manual, flag on):** add fork → card visible → 3–4 taps to a
fully prefilled component with real click ranges (Lyrik Ultimate shows
HSC −2…+2); coil pick shows Spring Rate and no Pressure/Spacers; air fork
without declared spacers gets none; re-picking a different preset cleanly
swaps name, notes and adjustments without a dialog when nothing was touched;
flag off → app indistinguishable from today.

---

## Phase 4 — C2: name-field autocomplete

**Goal:** the power-user path — type `"fox 38"` into Name, tap a suggestion,
done. Reuses Phase 1 index + Phase 3 matcher/apply. Add mode only.

1. Wrap the name field in a `RawAutocomplete`/overlay (anchored below the
   field, above keyboard): flag on ∧ mode == add, trigger at ≥3 characters,
   max 5 suggestions, ranked (brand-prefix match > token match).
2. Index source: `repository.all()` — **cross-type**, so suggestions work
   before a type is chosen; kick off loading on first keystroke.
3. Suggestion row: title `"FOX 38 Factory"`, subtitle damper · travel · year
   badge. Trims with >1 damper appear once per damper (flat list — no
   damper sub-step in an autocomplete).
4. On select → same `_applyPreset` as C4, which **also sets the component
   type** if not yet chosen (removes a tap instead of adding one).
5. Discoverability hint: name-field `helperText` *"Tip: type a product name —
   e.g. 'Fox 38'"*, only while flag on ∧ add mode ∧ field empty.
6. No-match / user keeps typing → overlay disappears, zero friction.

**Acceptance:** `"fox 38"` → suggestion → tap = name + type + adjustments set
with 5 keystrokes and 1 tap; typing `"My old clunker"` never shows UI noise.

---

## Phase 5 — Rollout & follow-ups (not in initial scope)

- Public rollout: move the toggle out of `kDebugMode` (or default `true` +
  onboarding mention), FAQ entry.
- Edit-mode entry point, **append-only** variant: "add adjustments from
  catalog…" that never touches name, notes, or existing adjustments (see
  resolved question — full preset application stays add-mode only).
- Data growth: publishable spacer counts for existing models, pre-2025 damper
  generations (GRIP2/FIT4 — year badges already in place), more brands (DVO,
  Cane Creek, EXT, Manitou), electronic suspension (the literal adjustment
  lists likely already cover modes/profiles via categorical entries).
- A4 remote overlay (download newer preset files than bundled) if data
  staleness between releases becomes real.

---

## Phase 6 — Optional, currently not planned: persisted provenance

Persist `presetKey` on `Component` (nullable column, Drift v4 + JSON v5).
Deliberately last and possibly never: catalog-driven component updates can
introduce a lot of unexpected behavior (components changing under saved
setups), and a user can simply self-fix a catalog error on their own
component. Only build this when a concrete consumer exists (e.g. a tappable
source link); the computed `presetKey` in Phase 1 makes the migration purely
additive whenever that day comes.

---

## Suggested commit granularity

One commit (or small PR) per phase; Phases 1+2 are pure logic and safely
land on `dev` even half-finished (dead code behind nothing); Phase 3+4 are
flag-gated so they're equally safe. CI (`analyze` + `test`) guards each step —
including, from Phase 1 on, every future YAML data commit.
