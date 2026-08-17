# Compare setups sheet — concept brainstorming

**Date:** 2026-08-17
**Status:** Brainstorming — pick one option per section, then run /plan.

Goal: make comparing two setups answer “what is actually different, where does
that difference belong, and under which conditions was it tested?” without
turning the sheet into a flat wall of cells. The result must preserve the
existing `Context → Values → Ratings` hierarchy from `SetupDetailsPage`, keep
component and person ownership visible, and remain usable on a narrow phone.

## What the code already tells us

- `Setup` contains metadata (`name`, local/UTC date, notes, tags), bike/person
  references, two adjustment-value maps, location, weather and images. Ratings
  are not embedded; `AppRepository` resolves rating entries and aggregated
  scores for a setup.
- Adjustment maps are keyed by adjustment UUID. `SetupResolutionService` also
  attaches the previous values. The effective value shown in compact setup UI
  is the setup's explicit value when its key is present, otherwise the inherited
  previous value. A comparison must use that same rule or it will disagree with
  the rest of the app.
- `SetupDetailsPage` resolves components at each setup timestamp through
  `DanglingAdjustmentService`; this correctly handles installations and also
  exposes values whose component/person is no longer linked or was deleted.
- The details hierarchy is already useful: context cards, one card per
  component, a person card, error-styled dangling groups, then aggregate rating
  score and per-metric scores. Weather and location are expandable because they
  are supporting context rather than the main setup.
- The TODO's proposed three-column table has a sound comparison geometry
  (`field | A | B`) but not a sufficient information architecture. The problem
  is not the three columns themselves; it is making the *whole sheet* one flat
  table.
- The sheet is launched from a setup tile with that setup as B and an implicit A.
  Current resolution can fall back to the first setup of any bike, accepts A ==
  B, and the menu's attempt to hide Compare on a current setup is missing a
  `return`. These are product-state decisions, not just defensive coding details.

## Product principles

1. Compare **effective setup state**, not merely fields explicitly edited in
   that setup.
2. Preserve ownership: an adjustment name without its component/person is
   insufficient context.
3. Difference does not mean better or worse. Adjustment deltas should be
   visually neutral; only rating scores have a meaningful quality direction.
4. A missing value, an inherited value, a removed component and a deleted
   adjustment are different states and must not collapse into the same dash.
5. The two setup identities must remain visible while scrolling.

---

## A. Primary visualization concept

### A1 — Hierarchical comparison matrix (recommended)

Keep the familiar details-page sections and component cards, but make each leaf
inside them a paired comparison row. On phones the label occupies its own line
and the two values sit below it; on wider layouts it becomes the conventional
`label | A | B` row.

```text
┌──────────────────────────────────────────────┐
│ Compare setups                         [×]   │
│        CURRENT                     TEST 04   │  ← pinned
│        16 Aug · 18:10              14 Aug    │
│ [12 differences]            [Differences ▾] │
├──────────────────────────────────────────────┤
│ CONTEXT                                      │
│ Bike                                         │
│ [Trail Bike]                    [Trail Bike] │
│ Conditions · 3 differences              [⌄] │
├──────────────────────────────────────────────┤
│ VALUES                                       │
│ ┌ Fork · FOX 38 ───────────────────────────┐ │
│ │ Rebound                                  │ │
│ │ [ 8 clicks ]              [ 6 clicks ]  │ │
│ │                                  −2  ≠   │ │
│ │ Low-speed compression                    │ │
│ │ [ 5 clicks ]              [ 5 clicks ]  │ │
│ └──────────────────────────────────────────┘ │
│ ┌ Person · Jonas ──────────────────────────┐ │
│ │ Riding weight                            │ │
│ │ [ 82 kg ]                  [ 84 kg ]  ≠  │ │
│ └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│ RATINGS                                      │
│ Overall             [7.8 / 10] [8.4 / 10]   │
└──────────────────────────────────────────────┘
```

**Pros:**

- Preserves `Context → Values → Ratings` and component/person nesting instead
  of flattening adjustment names into an anonymous list.
- Side-by-side values remain easy to scan; the useful part of a table is kept
  at the leaf level.
- Maps closely to `SetupDetailsPage`, `CardHeaderTile`, existing component icons
  and dangling-value error treatments.
- Can collapse low-priority groups and omit unchanged groups without losing the
  user's sense of where a value belongs.
- Adapts cleanly between phone and tablet without horizontal scrolling.

**Cons:**

- Taller than a dense table because labels need room and hierarchy consumes
  vertical space.
- Requires a comparison projection layer before rendering; directly zipping
  two maps in the widget is not sufficient.
- Component replacement and dangling-value states need deliberate group designs.

### A2 — Difference narrative / change feed

Render only changes as statements grouped by component: `Fork → Rebound: 8 → 6
clicks`, `Weather → Temperature: 18 → 25 °C`, followed by unchanged-count chips.

```text
Fork · FOX 38                         3 changes
  Rebound                 8  →  6 clicks
  Pressure               82  →  86 psi

Conditions                              2 changes
  Temperature             18 → 25 °C
  Trail condition          Wet → Dry
```

**Pros:**

- Fastest way to answer “what changed?”; very compact for two similar setups.
- Reads naturally on narrow screens and needs no table-like alignment.
- Numeric delta text can be added where units/types are compatible.

**Cons:**

- Hides the unchanged configuration that often provides necessary tuning
  context.
- Performs poorly when setups differ substantially; the feed becomes long and
  repetitive.
- Asymmetric arrow language implies A is a baseline and B is a candidate, which
  may not always match how an explicit A/B comparison is used.
- Metadata such as notes and long categorical values does not fit the sentence
  pattern consistently.

### A3 — Two synchronized setup detail panes

Show two miniature `SetupDetailsPage` columns with synchronized section
scrolling and highlights across matching rows.

**Pros:**

- Maximum fidelity to the existing detail page; almost all information has an
  obvious home.
- Each setup retains its own hierarchy even when components differ completely.
- Natural on tablets and landscape screens.

**Cons:**

- Two phone columns are too narrow for component names, notes and categorical
  values.
- Synchronized scrolling and matching highlights are complex and fragile when
  one side has extra components or expanded weather.
- The eye must repeatedly travel left/right to find corresponding rows.
- Reusing full detail widgets would carry controls and layout assumptions that
  do not belong in a comparison.

### A4 — Full-width A/B spotlight switch

Show one setup's existing hierarchy at full width and provide a pinned A/B
segmented control. Each visible value gets a small `other: …` annotation when it
differs from the hidden setup.

**Pros:**

- Best readability on very narrow devices and for long text values.
- Keeps a single, familiar details hierarchy with minimal visual density.
- Avoids horizontal compression entirely.

**Cons:**

- The user cannot see both values simultaneously; this is inspection with a
  reference, not true side-by-side comparison.
- Switching repeatedly creates memory load and makes broad scanning slow.
- Component mismatch is still hard to communicate because the hidden setup's
  hierarchy is not visible.

**Recommendation: A1.** A2 is valuable as a summary mode inside A1, not as the
entire sheet. A3 should only be reconsidered if the app later gets a dedicated
tablet comparison page. A4 is a reasonable narrow-screen fallback only if paired
rows prove too dense in device review.

---

## B. Information hierarchy and default density

### B1 — Mirror SetupDetailsPage exactly

Order everything as `Context → Values → Ratings`; show all rows and expanded
component cards by default.

**Pros:**

- Maximum consistency with setup details and no hidden information.
- Easy to explain and implement from existing section semantics.

**Cons:**

- A comparison sheet becomes much longer than either details page because every
  leaf carries two values.
- Important changes are buried among unchanged rows.
- Images, full location and full weather compete with the actual setup values.

### B2 — Difference-first hierarchy with retained structure (recommended)

Start with a compact difference summary. Keep `Context → Values → Ratings`, but
show only groups containing differences while “Differences only” is enabled.
Within Context, keep identity/date/bike/person visible and nest Notes & tags,
Location, Weather and Images behind compact disclosure rows.

**Pros:**

- Optimizes for the comparison task while preserving section and owner context.
- Empty groups disappear rather than consuming space; badges can still say
  `Fork · 2 of 6 values differ`.
- Secondary context stays available without dominating suspension and person
  values.

**Cons:**

- Users can mistake “not visible” for “not recorded” unless the filter state and
  hidden counts are explicit.
- A completely identical comparison needs a designed empty state plus an “Show
  all” escape hatch.
- Notes/tags may contain meaningful differences that are hard to summarize in a
  count.

### B3 — User-configurable section filters

Add filter chips for `Context`, `Bike values`, `Person`, `Ratings`, `Changed`.

**Pros:**

- Handles advanced workflows such as suspension-only or ratings-only review.
- Scales if more setup data categories are added later.

**Cons:**

- Too much control surface for a two-item sheet; users must configure the view
  before consuming it.
- Chip wrapping consumes the same scarce vertical space the filters are meant
  to save.
- Adds state combinations and test surface without evidence they are needed.

**Recommendation: B2**, with a single `Differences / All` segmented control or
switch. Do not add per-section filters in v1.

---

## C. Component and adjustment alignment

This is the most important data decision. Equal-looking labels are not always
the same entity: replacement components receive new adjustment UUIDs, and types
such as tire, brake and shifter may appear twice.

### C1 — Strict identity matching (recommended for v1)

Match component and adjustment rows only by their stable UUIDs. When a component
exists on only one side, show a structural change card: `Installed only in A`,
`Installed only in B`, or `Component changed`, with each side's values retained
under its actual component name.

**Pros:**

- Never fabricates equivalence between front/rear or old/new parts.
- Reuses the exact identities that key setup adjustment maps.
- Correct for components moved between bikes and for dangling historical values.
- Makes uncertainty visible rather than silently producing a misleading delta.

**Cons:**

- Replacing a FOX fork with another fork prevents an automatic `Rebound A ↔
  Rebound B` row even when that comparison would be useful.
- Structural-change cards are less compact than aligned rows.
- Deleted adjustments may only have an ID and raw value, so their label can no
  longer be recovered.

### C2 — Semantic matching by type + normalized names

Pair components by `ComponentType`, then pair adjustments by normalized name,
runtime type and unit.

**Pros:**

- Produces useful cross-component deltas after a fork, shock or tire replacement.
- Matches how a rider may think about a role (“fork rebound”), not database IDs.

**Cons:**

- Unsafe for `maxCount: 2` types and repeated names such as tire pressure or
  brake reach.
- Renames, unit changes and two similar dampers create ambiguous or false matches.
- The existing adjustment-history design explicitly identifies this missing
  stable-role/join-key problem; comparison UI should not hide it with heuristics.

### C3 — Conservative hybrid matching

Use identity first. If identities differ, semantically pair only singleton
component types (`maxCount == 1`) and only when adjustment name, type and unit
have one unambiguous match; label the group `Different components` and always
show both component names.

**Pros:**

- Recovers common fork/shock replacement comparisons without guessing among
  paired tires or brakes.
- Ambiguity can fall back to C1 rather than returning a wrong result.

**Cons:**

- More rules for users and developers to understand.
- “Unambiguous” is still heuristic and may change when a user adds another
  same-named adjustment.
- Requires more extensive tests than strict identity and could disagree with a
  future stable component-role model.

**Recommendation: C1 for the first release.** Design the comparison projection
so C3 can be added later without changing the widgets. Never implement C2 as a
silent best-effort join.

---

## D. Effective values, missing states and delta semantics

### D1 — Compare only explicitly recorded values

Use `setup.bikeAdjustmentValues` and `personAdjustmentValues` directly.

**Pros:**

- Shows exactly what the user changed or entered in each setup.
- Simple and useful for reconstructing the act of creating the setup.

**Cons:**

- Misrepresents the effective bike state when unchanged values were inherited.
- Disagrees with `AdjustmentCompactDisplayList` and setup details.
- A missing key looks like an unknown even when a previous value is known.

### D2 — Compare effective state, annotate provenance (recommended)

Resolve each leaf as explicit value when the current map contains the key,
otherwise inherited previous value. Render explicit/inherited as subtle
provenance (for example a small “inherited” label or reduced emphasis), and keep
separate states for unavailable, cleared, dangling and owner-not-present.

**Pros:**

- Answers the product question: how the two complete setups differ in practice.
- Matches existing compact-list resolution behavior.
- Provenance still lets the user see whether B deliberately changed the value.
- Makes correct difference filtering possible.

**Cons:**

- More view-model states than a raw `dynamic?` pair.
- Inheritance depends on repository resolution having run successfully.
- Provenance indicators can add visual noise if repeated on every row.

### D3 — Two modes: effective state / recorded changes

Expose a second control that switches the comparison basis.

**Pros:**

- Supports both tuning comparison and audit/history workflows.
- Makes the semantic distinction explicit rather than choosing for the user.

**Cons:**

- Adds a second filter axis beside `Differences / All`, making four view states.
- Harder to explain and test; likely excessive for v1.
- Recorded-change mode may appear broken when sparse setups contain few fields.

**Recommendation: D2.** Use type-aware `adjustmentValuesEqual`, format through
the owning `Adjustment`, and show a signed numeric delta only when both sides are
numeric and share a compatible unit. A delta is informational, not red/green.

---

## E. Difference signaling and filtering

### E1 — Color the entire changed cell

Use a fill or text color whenever A and B differ.

**Pros:**

- Strongest at-a-glance signal.
- Easy to scan in a dense matrix.

**Cons:**

- Suggests good/bad or validation state even though most tuning changes are
  neutral.
- Can conflict with existing initial/changed orange/green and dangling error
  colors.
- Color-only meaning is inaccessible and can become loud in dark mode.

### E2 — Neutral row emphasis + explicit marker (recommended)

Use a low-contrast theme-derived row tint or outline plus a visible `≠`, arrow
or “Different” semantics label. Reserve error colors for missing/deleted data;
use positive/negative rating styling only where score meaning is known.

**Pros:**

- Clear without claiming one adjustment is better.
- Works with light/dark themes and remains understandable without color.
- Leaves the existing error vocabulary intact.

**Cons:**

- Less visually immediate than saturated cell fills.
- Needs careful spacing so the marker does not compete with units and deltas.

### E3 — No inline emphasis; rely on Differences-only mode

**Pros:**

- Visually quiet and simple.
- Every visible leaf has the same meaning while filtered.

**Cons:**

- In All mode differences become difficult to find.
- Does not explain structural or missing-state differences.

**Recommendation: E2**, plus a pinned `Differences / All` control. Default to
`Differences` because this action exists specifically to compare; preserve group
headers and show `x of y differ` so filtering never removes hierarchy.

---

## F. Context, weather, notes and images

### F1 — Treat all context as ordinary comparison rows

Name, date, notes, tags, bike, person, address, coordinates, altitude, all
weather fields and images appear alongside adjustment rows.

**Pros:**

- Complete and structurally uniform.
- Every difference participates in the same filter behavior.

**Cons:**

- Weather/location can dominate the sheet even though they explain rather than
  define the setup.
- Notes and images do not compare naturally as cells.
- Raw coordinates and weather timestamps add noise without aiding most tuning
  decisions.

### F2 — Layered context disclosures (recommended)

Keep date/time, bike and person in the visible summary. Use three compact
disclosure groups: `Notes & tags`, `Location`, and `Conditions`. The Conditions
header shows the useful gist per setup (condition, temperature and optionally
weather label); expansion reveals precipitation, humidity, wind and soil
moisture. Images show only an availability/count indicator with a route to the
setup details, not duplicated image strips.

**Pros:**

- Mirrors the existing decision to nest weather/location while making the most
  explanatory context visible.
- Keeps component values near the top of the comparison.
- Long notes get full-width treatment inside an expansion rather than squeezed
  into half-width cells.
- Avoids loading and laying out two image galleries in a comparison sheet.

**Cons:**

- Important notes can be overlooked while collapsed.
- Header summaries require rules for partial/missing weather.
- A setup recorded at a different place may deserve more prominence than the
  default gives it.

### F3 — Context summary chips only

Show compact chips such as `Dry · 22 °C`, `Bike Park`, `Jonas`, with no expanded
details.

**Pros:**

- Extremely compact and visually scannable.
- Good fit above a difference-first values list.

**Cons:**

- Hides meaningful weather dimensions and notes entirely.
- Long/localized values wrap poorly in chips.
- Requires opening both detail pages to understand unexplained differences.

**Recommendation: F2.** Weather's manually set `Condition` should be treated as
the most important condition value; raw API fields remain secondary.

---

## G. Sticky orientation and responsive layout

### G1 — Fixed three-column table at all widths

**Pros:**

- Perfect vertical alignment and familiar spreadsheet scanning.
- Simple mental model.

**Cons:**

- At phone width each setup value gets roughly 25–30% of the screen after the
  label column; long names and categorical values become unreadable.
- Encourages horizontal scrolling or aggressive truncation.

### G2 — Responsive paired rows with pinned setup header (recommended)

Pin both setup identities, dates and A/B labels. Under a phone breakpoint,
render the field label full width and two equal value panels beneath it. At a
wider breakpoint, render `label | A | B`. Keep the same comparison view model in
both layouts.

**Pros:**

- Preserves simultaneous comparison without horizontal scrolling.
- Long field labels and units receive enough room on phones.
- A/B identities remain available after many component sections.
- One semantic structure supports phones, landscape and tablets.

**Cons:**

- Phone rows are taller and their vertical alignment is less table-like.
- Requires responsive widget/golden coverage at multiple widths.
- The pinned header must stay compact when setup names are long.

### G3 — Horizontal scrolling matrix with frozen label column

**Pros:**

- Retains dense table geometry and full value widths.
- Scales to a potential future three-or-more setup comparison.

**Cons:**

- Nested horizontal and vertical gestures are awkward in a modal sheet.
- Flutter frozen-column behavior is custom work and easy to desynchronize.
- Two setups do not justify spreadsheet-level interaction complexity.

**Recommendation: G2.** Truncate pinned names to one line, show full names in a
tooltip/semantics label, and optionally provide a small swap button so A/B order
can be reversed without reopening the sheet.

---

## H. Comparison target resolution and edge states

### H1 — Preserve the current automatic fallback

When A is absent, use the current setup for B's bike, otherwise the first setup
in the repository.

**Pros:**

- Always attempts to open a sheet with no additional interaction.
- Minimal change from the TODO implementation.

**Cons:**

- Can compare unrelated bikes silently.
- Repository iteration order is not a meaningful fallback.
- A == B and one-setup cases produce a useless comparison.

### H2 — Same-bike baseline with explicit unavailable states (recommended)

The setup selected from the list is B (candidate). A defaults to that bike's
current setup. Offer Compare only when B is not current and a distinct same-bike
current setup exists. If the function is called explicitly with two setups,
validate distinct IDs and same bike. Otherwise show a concise unavailable state
or a same-bike setup picker—never choose an arbitrary repository item.

**Pros:**

- Matches the likely intent: historical/test setup versus the bike's current
  setup.
- Prevents semantically weak cross-bike comparisons and all same-object cases.
- Makes the menu rule, resolver and sheet contract agree.

**Cons:**

- Users cannot compare two historical setups through the tile action alone.
- Bikes with only one setup have no comparison action.
- Requires deciding whether “no current” should disable or open a picker.

### H3 — Always open a two-setup picker

Open with B preselected and let the user choose A from all setups, optionally
filtering by bike.

**Pros:**

- Supports historical-to-historical and cross-bike exploration.
- Removes hidden baseline-selection rules.

**Cons:**

- Adds interaction to the most common “compare with current” flow.
- Cross-bike values mostly fail strict identity matching and will read as
  structural differences.
- Requires a new picker UX before the comparison itself can be evaluated.

**Recommendation: H2 for v1.** A later entry point from multi-select can pass two
explicit same-bike setups and reuse the same sheet. If no current setup exists,
disable Compare with an explanatory tooltip/menu omission rather than silently
substituting another bike.

---

## I. Ratings presentation

### I1 — Overall score only

**Pros:**

- Compact and directly comparable.
- Reuses `scoreForSetup` and the setup-list badge concept.

**Cons:**

- Hides why the score changed.
- Averages may be based on different rating-entry counts.

### I2 — Overall score + expandable metric breakdown (recommended)

Show score, rating-entry count and numeric score delta in the section header;
expand to paired per-metric scores and their weights, mirroring setup details.

**Pros:**

- Preserves the useful summary while retaining explanatory detail.
- Entry counts prevent overinterpreting a one-rating versus five-rating average.
- Metrics fit the same paired-row visual language as adjustments.

**Cons:**

- Metric definitions may be missing/changed and need an unavailable state.
- Ratings are repository-derived, so the sheet must rebuild when repository
  rating data changes.
- Score deltas can look definitive despite different sample counts.

### I3 — Full individual rating-entry comparison

**Pros:**

- Maximum transparency about every recorded opinion/test run.
- Avoids hiding variation behind an average.

**Cons:**

- There is no natural one-to-one pairing between entries from two setups.
- Turns setup comparison into a second rating history screen.
- Much too large for this sheet.

**Recommendation: I2**, with neutral wording such as `+0.6 score` and visible
sample counts rather than declaring one setup a “winner.”

---

## Recommended combination

Choose **A1 + B2 + C1 + D2 + E2 + F2 + G2 + H2 + I2**:

1. A nearly full-height modal sheet with a compact pinned header for A and B.
2. A difference summary and `Differences / All` control, defaulting to
   Differences.
3. Existing high-level order: Context, Values, Ratings.
4. Values nested first by component/person, then rendered as paired leaf rows.
5. Effective values resolved with explicit/inherited provenance; strict UUID
   matching and honest structural-change cards for component replacement.
6. Neutral difference emphasis; error colors reserved for dangling/deleted
   states.
7. Context disclosures for notes/tags, location and weather; compact condition
   gist outside, details inside.
8. Responsive phone rows (label above A/B) and conventional three-column rows
   on wider screens.

This is a hybrid, not a rejection of tables: **use matrix geometry where exact
values are compared, and cards/sections where meaning and ownership are
established.** That preserves scanability without sacrificing context.

## Suggested implementation phases after the concept is decided

1. **Comparison projection:** define pure comparison models for section, owner
   group, row, side value/provenance and difference kind. Resolve each setup
   independently with `DanglingAdjustmentService`, then join strictly by IDs.
2. **Target contract and edge states:** make implicit baseline selection
   same-bike/current-only; handle same IDs, one setup, missing bike/person,
   deleted adjustments and absent ratings deterministically.
3. **Sheet shell:** build the pinned identity header, difference count/control,
   safe-area/keyboard-independent scrolling and responsive paired-row primitive.
4. **Content sections:** add primary Context rows and disclosures, component and
   person cards, structural/dangling states, then Ratings summary/breakdown.
5. **Verification:** unit-test projection/effective-value semantics and all
   resolver edge cases; widget-test filter/expansion behavior; visually verify
   narrow/wide widths plus light/dark themes. Use representative long names,
   categorical lists, nulls and replaced components in fixtures.

## Open questions for the final plan

1. Confirm the primary direction: hierarchical paired matrix (A1), or do you
   want the more minimal difference narrative (A2)?
2. Should `Differences` be the default as recommended, or should the first view
   show all values with differences merely emphasized?
3. Is strict identity matching acceptable for v1 when a component was replaced,
   or is cross-component comparison important enough to accept C3's conservative
   heuristic now?
4. Should comparison remain same-bike only, or must explicit A/B callers be able
   to compare different bikes?
5. Do notes/tags belong collapsed under Context, or are setup notes important
   enough to stay visible by default?
6. Should images be omitted entirely, or is a count/link-to-details indicator
   useful in the comparison header?
