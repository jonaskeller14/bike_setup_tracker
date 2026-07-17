# Component presets — concept brainstorming

**Date:** 2026-07-17
**Status:** Brainstorming — pick one concept per section, then write the final implementation plan.

Goal: a user adding a fork/shock should be able to pick their exact product
(brand › model › trim › damper) and get a `Component` prefilled with the correct
name, notes and `Adjustment`s (real click ranges) — instead of building
everything by hand. Source of truth is the human/AI-editable YAML DB in
`data/component_presets/` (see `SCHEMA.md` there).

The document has three independent decision axes:

- **A. Data pipeline** — how YAML becomes Dart objects
- **B. Loading strategy** — when/how much of it is held in memory
- **C. UI/UX** — how the user reaches and applies a preset

---

## A. Data pipeline: YAML → `Component` / `Adjustment`

Non-negotiable constraint: YAML stays the authoring format. It's readable,
diff-able, and AI agents can update it from manufacturer pages (or I edit it
manually when specs only exist as PDF). Whatever pipeline we choose must keep
"edit YAML, done" as the whole authoring workflow.

Important structural point for **all** options: YAML should *not* be parsed
directly into `Component` objects. `Component` carries identity (`id`,
`lastModified`, `installations`) that presets must not have. Introduce a small
intermediate model:

```dart
class ComponentPreset {
  final String brand, model, trim;      // "FOX", "38", "Factory"
  final ComponentType componentType;
  final String? url;                    // source page → goes into notes
  final List<String> damperKeys;        // >1 = user must pick one
  final List<num> travelOptions;        // fork: travel_mm, shock: stroke_mm
  // ...
  Component toComponent({...});         // fresh UUIDs at instantiation time
}
```

`toComponent()` merges the generic type presets (Pressure, SAG, Volume Spacers
from `component_add_adjustment.dart`) with the damper-specific
`StepAdjustment`s exactly as SCHEMA.md describes.

### A1 — Runtime YAML parsing on device (recommended)

Bundle `data/component_presets/**` as Flutter assets, parse on device with the
[`yaml`](https://pub.dev/packages/yaml) package (pure Dart, small, by the Dart
team).

| | |
|---|---|
| ✅ | Single source of truth. An AI agent edits `fox.yaml`, commits — next build ships it. Zero extra steps. |
| ✅ | No codegen, no generated-file diffs, no second artifact to drift out of sync. |
| ✅ | Data size is trivial (all 6 files today ≈ 30 KB; even 20 brands ≈ a few hundred KB). Parse time is single-digit ms. |
| ⚠️ | Schema errors surface at runtime, not compile time. **Mitigation:** a Dart test (`test/component_presets_test.dart`) that parses every YAML file and asserts invariants (damper keys resolve, clicks > 0, componentType valid, …). CI already runs `flutter test` → a bad AI edit breaks CI, not the app. This test is mandatory for this option and effectively replaces compile-time safety. |
| ⚠️ | Mapping code (`YamlMap` → `ComponentPreset`) is hand-written and `dynamic`-typed. Same code we'd write in any option, though. |

### A2 — Build-time codegen → Dart constants

A script (build_runner builder or standalone Dart/Python script) converts YAML
into a generated `.dart` file with const preset definitions.

| | |
|---|---|
| ✅ | Compile-time safety; typos in YAML fail the build. Fastest possible runtime. |
| ❌ | Every data edit needs a regeneration step — breaks the "AI edits YAML, done" workflow (agent must also run the generator, generated diffs pollute PRs). |
| ❌ | A custom builder is real maintenance surface for what is ultimately ~30 KB of data. |
| Verdict | The safety win is small vs. A1 + CI test, the workflow cost is permanent. Not worth it. |

### A3 — Build-time YAML → JSON asset, runtime `json.decode`

Keep YAML as authoring format, convert to a single `presets.json` asset in a
pre-build step (script or CI), parse JSON at runtime.

| | |
|---|---|
| ✅ | JSON parsing is built-in; could reuse patterns from existing `fromJson` code. |
| ❌ | Two artifacts (YAML + JSON) that can drift; needs a build hook on every platform/dev machine or a "forgot to regenerate" failure mode. |
| Verdict | All of A2's workflow downsides with none of its type-safety upside. Skip. |

### A4 — Remote data (Firestore / hosted JSON), fetched at runtime

Presets live server-side; app fetches and caches them.

| | |
|---|---|
| ✅ | Preset updates without an app release; usage analytics possible. |
| ❌ | Network dependency in an offline-first app; cache/versioning/migration complexity; infra cost; slower first-use. |
| Verdict | Wrong first step, but the right **evolution**: bundled assets now, optional "remote override newer than bundled" layer later. A1 doesn't block this — the same parser can consume a downloaded file. |

**Recommendation: A1** (+ the CI validation test, non-optional), designed so A4
can be layered on later.

> Asset note: Flutter asset declarations are per-directory, so
> `pubspec.yaml` gets `data/component_presets/fork/`, `data/component_presets/shock/`
> (one line per component-type folder). `SCHEMA.md` in the same tree is not
> declared and stays repo-only. Alternatively mirror the files under
> `assets/component_presets/` if we want `data/` to stay build-free —
> decide in the implementation plan.

---

## B. Loading strategy: eager vs. lazy

Reality check first: this is **not a memory problem**. The full dataset parsed
into Dart objects is well under 1 MB even with 10× today's brands. The real
costs are (a) startup time, (b) doing work users never need (many users never
add a suspension component), and (c) object churn (creating `Adjustment`s with
fresh UUIDs that are thrown away).

### B1 — Eager: parse everything at app startup

❌ Pays parse cost on every launch for a feature used rarely (garage setup is
mostly one-time). Adds to `LoadingGate` work. No upside — nothing at startup
needs presets. Skip.

### B2 — Lazy per component type, index-first (recommended)

Two-tier design:

1. **Index tier** — on first opening of the preset picker for a component type,
   parse only that type's directory (`fork/` *or* `shock/` — the folder layout
   already partitions by type) into lightweight `ComponentPreset` descriptors:
   brand/model/trim/damper *names* + metadata. No `Adjustment` objects yet.
   This is what browsing and search run against. Cached for the session in a
   `PresetRepository` (plain service class or lazy `Provider` — it's immutable
   data, no `ChangeNotifier` needed).
2. **Instantiation tier** — only when the user confirms a selection does
   `toComponent()` build actual `Adjustment` objects (fresh UUIDs, correct
   click ranges).

✅ Zero startup cost. First picker open costs one asset load + YAML parse
(~few ms — a `compute()` isolate is available as a safety valve but likely
unnecessary at this size). Search stays cheap (string matching over the index).
Object creation happens exactly once, at selection.

### B3 — Fully lazy per file/brand (parse `fox.yaml` only when FOX is tapped)

❌ Over-engineering at this data size, and it breaks **search across brands**
("fox 38" typed into a global search field requires all brands of that type
indexed anyway). B2 already gives the per-type granularity that matters.

**Recommendation: B2.** One caveat: if UI concept C2 (name-field autocomplete,
below) is chosen, the index must span *all* component types (so "fox 38" can be
matched before a type is selected). That's still fine — parse all directories
on first keystroke-with-≥3-chars, it's the same few-ms cost, just triggered by
the name field instead of the picker.

---

## C. UI/UX concepts

Guiding principles (from the app's DNA): minimal taps, no new required fields,
everything editable later, don't overwhelm — presets must be an *accelerator*
for those who want them and *invisible* to those who don't. Users adding a
saddle or frame must never pay a cost for a feature that only covers
fork/shock (for now).

The concepts below are entry points; C5 describes the shared picker they open,
C6 the prefill semantics after selection. Entry points are combinable.

### C1 — Reorder the form: Type above Name

Today Name is first (and autofocused) and Type second. Swapping them means the
page knows the component type before the name is typed, so preset UI (C4
banner, filtered autocomplete) can appear at the right moment, and the
keyboard doesn't pop up over a dropdown interaction.

- ✅ Cheap, low-risk change; type-first matches how users think ("I'm adding a
  fork") and enables every other concept below.
- ✅ Losing name-autofocus is arguably a win: the current autofocus+keyboard on
  page open is aggressive when the first real decision is the type.
- ⚠️ Pure enabler — does nothing alone.
- **Verdict: do it regardless of which concept wins.**

### C2 — Name-field autocomplete ("fox 38" → suggestions)

While typing in the Name field, an inline suggestion list (overlay under the
field, `RawAutocomplete`-style) shows matching presets: *"FOX 38 Factory
GRIP X2"*, *"FOX 38 Performance Elite"*, … Tapping one prefills everything —
**including the component type** if not yet chosen (the preset knows it's a
fork). Matching: case-insensitive token matching over brand+model+trim+damper
strings ("rs lyrik ult" matches "RockShox Lyrik Ultimate"). Show a subtle hint
(e.g. helper text *"Type a product name for suggestions — e.g. 'Fox 38'"*)
only while the field is empty and mode == add.

- ✅ **Fastest possible path**: 4 keystrokes + 1 tap = fully configured
  component. No extra screens, no mode decision up front — exactly the
  "smooth & quick" goal.
- ✅ Perfectly non-blocking: users typing a custom name just keep typing;
  suggestions disappear on no-match. Zero cost for non-suspension components.
- ✅ Autocompletes the *type* too — removes a tap instead of adding one.
- ⚠️ Discoverability is the weak spot: nothing advertises that presets exist
  until you happen to type a brand. Needs the hint text and/or pairing with a
  visible entry point (C4).
- ⚠️ UI care needed: suggestion overlay competes with keyboard space on small
  phones; cap at ~4-5 suggestions, scrollable.
- ⚠️ Slightly fuzzy failure mode: "Fox 38" matches 3 trims × sometimes 2
  dampers — suggestion rows must be self-explanatory (title = model+trim,
  subtitle = damper/travel/year) so picking the right one doesn't require
  already knowing the catalog.

### C3 — Intercept "Add": "From catalog / Start blank" menu

Tapping *Add Component* first shows a two-option sheet: **Browse catalog**
(→ full-screen searchable picker, then lands in a prefilled ComponentPage) or
**Start blank** (→ today's flow).

- ✅ Maximum discoverability — every user sees the catalog exists.
- ✅ Full-screen picker gets room for search + drill-down + rich rows.
- ❌ **Adds one tap to every component creation forever**, including the ~15
  component types that have no presets at all. This directly violates the
  quick-setup principle and punishes the common case to advertise a feature
  for two component types.
- ❌ Forces the preset/no-preset decision at the moment the user knows the
  least (before they've even said it's a fork).
- **Verdict: reject** in this form. A variant — only intercept when the tap
  originates from a context where type is already known — collapses into C4.

### C4 — Contextual catalog card inside ComponentPage

When (mode == add) and the selected type has presets (fork/shock), a compact
tappable card appears directly under the Type dropdown:

```
┌──────────────────────────────────────────────┐
│ 📦  Choose from catalog                      │
│     FOX · RockShox · Öhlins — prefill        │
│     adjustments with factory click ranges  › │
└──────────────────────────────────────────────┘
```

Tap → picker sheet (C5) → selection prefills the form in place. Card
disappears for types without presets and in edit mode (or shrinks to a small
"replace with preset…" text button — v2 decision).

- ✅ Discoverable at exactly the right moment (you just said "fork") with zero
  cost to everyone else. No extra navigation level; ComponentPage stays the
  single screen it is today.
- ✅ Natural place to *re-enter* the picker if the first pick was wrong.
- ⚠️ One more visual element on the page — must stay one-line-compact so the
  page doesn't feel busier. It replaces nothing, purely additive.
- ⚠️ Requires C1 (type before name) to feel natural — the card should appear
  above/at the fields it will fill.

### C5 — The picker itself (shared by C2/C4): hybrid search + drill-down sheet

One reusable modal bottom sheet (same pattern as
`showComponentAddAdjustmentBottomSheet`), internally staged:

- **Search field pinned on top** — typing switches to a flat filtered list of
  all trims of that component type (rows like *"FOX 38 Factory · GRIP X2 ·
  160-180 mm"*). Same matching logic as C2 → one implementation.
- **Below, when not searching: drill-down** — Brand list (with logo/count) →
  models (grouped by category: Enduro, Trail, …) → trims. Back arrow in the
  sheet header, no full-screen routes.
- Tapping a trim with **multiple dampers** shows one final inline choice
  (two large option rows: *GRIP X2 — 4-way* / *GRIP X — 3-way*), because the
  damper decides the click ranges. Single-damper trims skip this.

Evaluation of alternatives considered:

| Variant | Verdict |
|---|---|
| Pure drill-down (3 taps: brand→model→trim) | Fine for browsers, slow for users who know their fork; no search is a miss since he explicitly wants one |
| Pure flat search list | Great for knowers, bad for explorers ("what trims exist for the Lyrik?"); empty-state before typing is awkward |
| **Hybrid (recommended)** | Search for knowers, drill-down for browsers, one component |
| Full-screen page instead of sheet | More room, but heavier feel; sheet keeps the "you're still on the component form" context — prefer sheet, switch only if content overflows |

### C6 — Prefill semantics (applies to every entry point)

What a selection actually does to the form:

- **Name** ← `"FOX 38 Factory"` (brand + model + trim; damper name appended
  only when it disambiguates, e.g. two dampers offered).
- **Type** ← preset's componentType (if not already set).
- **Notes** ← compact spec block: damper, travel options, wheel size,
  stanchion, year range, and the product `url` (SCHEMA.md wants the URL kept
  as source reference; notes is the existing free-text home for exactly this
  kind of info — see the field's own hint text).
- **Adjustments** ← generic type presets (Pressure, SAG, Lockout, Volume
  Spacers) with Rebound/Compression **replaced** by the damper's real
  `StepAdjustment` ranges; `compression_positions` → `CategoricalAdjustment`.
- **Travel**: don't force a choice. If the trim has >1 travel option, list them
  in notes; the SAG adjustment's travel field is where a concrete number
  matters and stays user-set (they know their bike's spec).

Conflict handling — the form may already contain user input:

- Empty form (the 95% case: tap preset right after choosing type): just fill.
- Non-empty fields: **never silently overwrite.** Simplest good rule: fill
  only empty fields; for adjustments, if any exist, ask once
  (*"Replace 3 existing adjustments with preset?"* Replace / Keep both /
  Cancel). Avoid clever merging in v1.
- Everything stays editable afterwards — the preset is a form-filler, not a
  binding. No live link to the YAML entry. (Optionally store the preset key,
  e.g. `fox/38/factory/grip_x2`, in notes or a future field for provenance /
  "update from catalog" later — nice-to-have, not v1.)

---

## Recommended combination

1. **Pipeline:** A1 — bundle YAML as assets, parse with `yaml`, guarded by a
   CI test that validates every file. Intermediate `ComponentPreset` model +
   `toComponent()`.
2. **Loading:** B2 — `PresetRepository`, parse per component-type directory on
   first use, index-first, `Adjustment` objects only at selection.
3. **UI, phased:**
   - **Phase 1:** C1 (type field first) + C4 (contextual catalog card) +
     C5 (hybrid picker sheet) + C6 semantics. Complete, discoverable,
     zero-cost-to-others feature.
   - **Phase 2:** C2 (name-field autocomplete reusing the same index and
     matcher) — the power-user accelerator, added once the picker/prefill
     machinery is proven.
   - **Later, only if data goes stale between releases:** A4 remote overlay.

## Open questions for the final plan

- Asset location: keep `data/component_presets/` (declare as assets) vs.
  mirror into `assets/`? (Leaning: keep `data/`, declare directly — one source
  of truth beats tidy foldering.)
- Should selecting a preset in C4 also *rename* an already-named component if
  the name field was auto-filled by a previous preset pick (i.e. track
  "name is still pristine/preset-owned")?
- Damper choice UI when a trim lists two dampers: inline step in the sheet
  (proposed) vs. chip toggle on the catalog card after selection?
- Store preset provenance key on the component now (schema touch) or defer?
- How do year_range revisions work long-term — same model name, different
  clicks per year (SCHEMA.md already allows per-generation damper keys; picker
  rows may eventually need a year badge)?
