# Rating Redesign — Architecture & Implementation Plan

> **Status (2026-06-20):** Phases **A–D done**, **E mostly done**. Backend + the new
> rating-entry UX are committed and green (`flutter analyze` clean, 292 tests pass).
> **Schema version is now 6** (not 3→4 as originally drafted): v5 added the 3 rating tables
> + simplified `Adjustments`; v6 made `RatingEntry.setupId` **non-nullable** (a rating always
> relates to a preceding setup; a purged setup leaves a tolerated dangling id) and recreated
> `rating_entries`.
>
> **Done in Phase E:** E0 mechanical green-up; the **rating-entry editor**
> ([rating_entry_page.dart](../lib/pages/rating_entry_page.dart), structured like SetupPage —
> context capture + applicable-rating metric inputs + **live 0–10 / weighted-sum score** +
> **drift warning with Relink**); **`setupId` resolved in the page's save** (blocked if no
> preceding setup); **`RatingEntryListTile`** (dense, two scores) + `RatingEntryActions`
> (add/edit/remove/restore w/ snackbar); **SetupCard** score badge + "Add Rating" / "Ratings (n)"
> popup; **setup detail** "Ratings" section (setup score + entries + add); **rating entries
> surfaced on the SetupList, search & Calendar** behind a global `displayShowRatingEntries` flag
> (filter sheet chip); and the **RatingEntry details page + sheet** (tap a tile/calendar item →
> details with a **0–10 score breakdown** §7.2, edit/delete inside) — including **Map markers**
> (tap → details). **Still pending:** dedicated weight editor (E19 — interim weight=1) and the
> analytics rating-score column/series (E′-b).


Rework the **not-yet-shipped** Rating feature so that ratings are **decoupled from
`Setup`**, can be captured **multiple times per setup** (different tracks / runs /
days), produce a **single weighted score** per rating session, and roll up into a
**score per setup**. This score is the foundation for the long-term vision: comparing
good vs. bad setups and (eventually) predicting an optimal setup with ML, plus pulling
in **objective** signals such as Strava segment times.

Because the feature is **not shipped**, there is **no data migration to preserve** for
rating data — existing rating values may be discarded. (The shared `Adjustments` table
and component/person data must of course survive — see §6.)

---

## 1. Vision (why this shape)

The end goal is a dataset where each **setup** (a bike state = a feature vector of
adjustment values + context like weather/condition) is paired with one or more
**quality measurements**. Some measurements are **subjective** (rider rates grip 1–10),
some are **objective** (lap time, Strava segment time). To train or rank anything we
need:

- measurements **attached to the setup that was active when they were taken**,
- measurements **repeatable** (same setup, different track/day → different scores),
- each measurement reduced to a **comparable scalar** (normalized, weighted), and
- context stored **with the measurement** (where/when/weather), because a lap time only
  means something relative to track + conditions.

The current implementation satisfies none of these cleanly. This redesign does.

---

## 2. Current implementation — what's wrong

| File | What it does today | Problem |
|---|---|---|
| [rating.dart](../lib/models/rating.dart) | `Rating` = a *template* (name, `filter`/`filterType`, `List<Adjustment>` metrics). | Good as a template, but metrics carry **no weight and no direction**, so no score can be computed. |
| [setup.dart](../lib/models/setup.dart) | Holds `ratingAdjustmentValues` (`Map<adjId, value>`) **inside the Setup**. | A setup can hold **exactly one** answer per metric. Can't rate the same setup twice (two tracks). Rating is **welded onto** the setup. |
| [setup_page.dart](../lib/pages/setup_page.dart) | A third tab (`SetupRatingTab`) lets you fill rating metrics while editing the setup; `_filteredRatings`, `_ratingAdjustmentValues`, dangling-value bookkeeping. | Rating capture is trapped in the setup editor and shares its date/place/weather. You can't rate "later, at the trail" with its own context. Big chunk of setup_page complexity exists only for this. |
| [rating_list.dart](../lib/widgets/lists/rating_list.dart) | Lists the rating **templates**. | Fine — stays. There is **no** list of actual rating *results* anywhere. |

Net: today "a rating" is conflated between **the questionnaire** and **the single set of
answers stored on a setup**. We need to split those and add scoring.

---

## 3. Proposed architecture

Three concepts (the third is new), mirroring the existing **TaskRule → TaskEntry**
pattern already in the codebase:

```
Rating  (template / questionnaire)         ← exists, gains weights+direction
  └─ RatingMetric (Adjustment + weight + higherIsBetter)   ← NEW wrapper
        ▲
        │ defines which metrics to capture
        │
RatingEntry  (a "rating snapshot": one filled-in session)  ← NEW
  • ratingId        → which template was used
  • bikeId          → which bike (for filtering + setup resolution)
  • datetime/local, notes, position, place, weather(+condition)   (like Setup)
  • metricValues: Map<adjustmentId, value>
  • → resolves to the Setup active for that bike at that datetime
        │
        ▼
Setup  (loses ratingAdjustmentValues)      ← simplified
  • score = aggregate(scores of all RatingEntries that resolve to it)
```

- **Rating** stays the **template**: name, filter (Bike / Component / ComponentType /
  Person / global), and an ordered list of **RatingMetrics**.
- **RatingMetric** = an `Adjustment` (the existing value-capture definition: step,
  numeric, duration, bool, text, categorical) **plus** `weight: double` and
  `higherIsBetter: bool`. Weight/direction only apply to **scored** types
  (step / numeric / duration / bool). Text & categorical are captured but **excluded
  from the score**.
- **RatingEntry** = one **filled-in** rating session ("rating snapshot"): the answers
  for one template's metrics, **with its own** datetime / location / place / weather /
  condition (independent of any setup). It belongs to a bike and resolves to the setup
  that was active for that bike at that moment.
- **Setup** drops `ratingAdjustmentValues` entirely; its score is **derived**, not
  stored.

### Why a wrapper (`RatingMetric`) instead of subclassing `Adjustment`

The prompt floated "derive new `ratingMetricAdjustments` from the existing adjustments."
`Adjustment` is a **sealed** hierarchy with 6 concrete subtypes
([adjustment.dart](../lib/models/adjustment/adjustment.dart)). Subclassing to add
weight/direction means either 6 new subclasses or polluting the base class with two
fields that are meaningless for component/body/equipment adjustments. **Composition** is
cleaner:

```dart
class RatingMetric {
  final Adjustment adjustment;     // reuses ALL existing capture UI + validation
  final double weight;             // SIGNED. + = higher-is-better, − = "bad" metric
                                   //   (lower-is-better). magnitude = importance.
  bool get isScored => adjustment is StepAdjustment
                     || adjustment is NumericalAdjustment
                     || adjustment is DurationAdjustment
                     || adjustment is BooleanAdjustment;
}
```

This reuses every adjustment editor page and value widget untouched, and keeps
`Adjustment` pure. **Persistence is fully separated** from component/person adjustments:
rating metrics live in their own `RatingMetrics` table (not `Adjustments`) — see §6. The
`Adjustment` class is reused only to *capture/serialize* the metric definition; in the DB
it's stored as a `RatingMetrics` row.

**Signed weight replaces any direction flag — there is no `higherIsBetter` field at all.**
A negative weight ("How bad does it feel?" → lower is better) and a `higherIsBetter = false`
flag express the *same thing*, so we store a **single signed `weight`** and nothing else.
The metric editor has **no direction toggle**; instead, a **dynamic helper text below the
weight field** states the consequence of the current sign in plain language — e.g. weight
> 0 → *"Higher values improve the score"*, weight < 0 → *"Lower values improve the score"*
(can be phrased with the metric's type/name, e.g. *"Lower Duration is better"*), weight = 0
→ *"Not counted in the score"*. The model's `const RatingMetric` defaults `weight` to
`+1.0`; the **editor** pre-fills `−1.0` when adding a `DurationAdjustment` (lower lap time
is better).

---

## 4. Is the plan good? Assessment + alternatives

**Verdict: yes, the direction is right.** Decoupling rating results into their own
first-class object is the correct call and unlocks everything in §1. Specific notes:

**Strong points of your plan**
- Multiple ratings per setup → modeled as multiple `RatingEntry` rows. ✅
- Per-metric **signed** weight → importance + direction in one field, ML-friendly. ✅
- Rating snapshot carrying its own datetime/location/weather → essential; a lap time
  without conditions is noise. ✅
- "Link to the last setup, mean over multiple ratings" → sound; details in §5.4 and §7.

**Decided (see §10)**
1. **Per-metric normalization is still required (even though the score has no fixed
   range).** This is the one place I'll push back on "score = Σ value·weight": raw values
   have **incompatible units**. A Duration metric (seconds, magnitude ~100) and a 1–10
   Step metric live on different scales, so a raw `value·weight` sum is silently
   dominated by the large-magnitude metric unless the user hand-tunes tiny weights to
   compensate — fragile and unexplainable. So each metric value is first **normalized to
   [0,1]** against its bounds, *then* multiplied by its signed weight. `StepAdjustment`
   always has min/max, `BooleanAdjustment` is 0/1; **`Numerical`/`Duration` can be
   unbounded**, so when marked **scored** the editor **requires finite min/max** (decided
   earlier). With normalization, the user's intent — "value·weight, higher generally
   better, negative weight for bad questions" — becomes "**normalizedValue · signedWeight,
   summed**", which behaves exactly as expected and stays comparable (see §7 + §7.1).
2. **Entry spans ALL applicable ratings — DECIDED (revised).** A `RatingEntry` is a
   per-bike rating *session*: it captures values across **every rating that applies** at
   that time (one rating for the fork, one for the whole bike, …), exactly like the old
   setup rating tab listed them together. So an entry has **no `ratingId`** — `metricValues`
   is keyed by `ratingMetricId` across whichever metrics were filled, and the applicable
   ratings are derived from their filter at the entry's time. Cross-rating aggregation
   works because scores normalize per metric (§7).
3. **Setup linkage — DECIDED: hybrid (resolve dynamically + store a provenance snapshot).**
   - On **first save**, compute the active setup (most recent non-deleted setup for the
     entry's bike with `datetime <= entry.datetime`, via the chronological logic in
     [SetupResolutionService](../lib/services/setup_resolution_service.dart)) and store it
     as a **write-once** `setupId` snapshot on the entry — never auto-overwritten.
   - At **read time**, re-resolve dynamically. **Dynamic resolution is authoritative for
     the score** (always reflects the current, corrected setup timeline).
   - When the stored `setupId` ≠ the currently-resolved setup, show a **passive drift
     warning** ("originally linked to *Setup A*, now resolves to *Setup B*") in the entry
     list tile and on the entry page.
4. **Aggregation — DECIDED: per-metric pooled mean.** Per-setup score pools each metric's
   normalized values across all resolving entries, then applies the signed weights once
   (§7) — so weights aren't distorted by how many entries answered each metric. Null-safe
   (no data ⇒ `null`). Kept in one pure function so it can later become recency-weighted or
   per-track.

---

## 5. Data-model changes (Dart)

### 5.1 `Rating` — [rating.dart](../lib/models/rating.dart)
- Replace `List<Adjustment> adjustments` with **`List<RatingMetric> metrics`**.
- `toJson`/`fromJson`: bump version to 3; serialize metrics as
  `{ adjustment: <adjustment json>, weight }`. Since the feature is unshipped, the
  v1/v2 branch can map old `adjustments` → metrics with default weight 1.0 (or just
  drop — data is disposable).
- Keep `filter`/`filterType` exactly as-is (template targeting is unchanged).

### 5.2 `RatingMetric` — NEW `lib/models/rating_metric.dart` ✅ (done)
- **`const` class.** Fields: `adjustment`, **signed** `weight` (const default `+1.0`;
  editor pre-fills `−1.0` for Duration), `isScored` getter, `deepCopy`, `toJson`/`fromJson`,
  `==`/`hashCode`, `copyWith`. No `higherIsBetter` field (sign of `weight` carries
  direction — see §3).
- The metric's **id is `adjustment.id`** — same id is the `RatingMetrics` row id and what
  `RatingEntryValues` keys on. No new id concept; rating metrics simply no longer live in
  the `Adjustments` table (see §6).

### 5.3 `RatingEntry` — NEW `lib/models/rating_entry.dart` ✅ (done)
Context fields mirror `Setup`; the shared context wrappers live in `lib/models/context/`:
`ContextPosition` (`context_position.dart`), `ContextPlace` (`context_place.dart`) — both
handle JSON + equality — and `ContextWeather` (`context_weather.dart`, formerly `Weather`).
`Setup` was refactored to use these too.
```
id, isDeleted, lastModified
name?              // optional, like Setup; displayName falls back to a derived label
bike               // FK → Bike   (NO ratingId — an entry spans all applicable ratings, §4.2)
setupId            // REQUIRED (non-nullable). Write-once provenance, resolved in the entry
                   //   page's save (blocked if no preceding setup); NOT authoritative for
                   //   scoring (dynamic resolution is). A purged setup leaves a dangling id.
dateTimeUTC, dateTimeLocal
notes?
metricValues: Map<String, dynamic>   // ratingMetricId → value (same dynamic typing as Setup)
position?, place?, weather?          // weather carries `condition`
```
- The repository exposes both the **resolved** setup (authoritative, drives score) and
  the stored `setupId` (provenance); when they differ, the UI shows the drift warning.
- **Scores are derived, not stored** — the repository/score service computes the
  `weightedAvg` (0–10) and `weightedSum` on the fly from the entry's values + the
  template's current metrics (so an entry that predates a newly-added metric just averages
  over what it has). No completeness field (§7.1).
- `toJson`/`fromJson` (v1), `deepCopy`, `copyWith`, `==`/`hashCode`.
- Reuse `Setup.adjustmentValuesToJson/fromJson`, `locationDataToJson`, placemark/weather
  helpers (consider extracting them to a shared util to avoid duplication).

### 5.4 `Setup` — [setup.dart](../lib/models/setup.dart)
- **Remove** `ratingAdjustmentValues` (field, json, copyWith, ==, hashCode, deepCopy,
  `previousRatingAdjustmentValues`). Bump json version; older backups simply ignore the
  dropped key.
- Add a **transient, non-persisted** `double? score` populated by the repository
  (derived, never serialized) — or expose score via a repository method rather than a
  field. Recommendation: repository method `double? scoreForSetup(String id)` to keep
  `Setup` a pure data holder.

---

## 6. Database changes (Drift) — full separation (Option B)

No migration is required for rating **data** (disposable), but the schema still changes;
component/person adjustments and their values must be preserved. **Rating metrics are
moved out of `Adjustments` into their own `RatingMetrics` table**, which also *simplifies*
`Adjustments`.

### 6.1 `Adjustments` table — [adjustments.dart](../lib/database/tables/adjustments.dart) (simplified)
- **Remove** the `ratingId` FK column.
- **Simplify** the `customConstraints` CHECK from "exactly one of
  (component_id, person_id, rating_id)" to "exactly one of (component_id, person_id)".
- Result: `Adjustments` now serves **only** component & person adjustments — no rating
  concern, no rating-only columns. (Disposable rating-metric rows currently in this table
  are dropped; component/person rows are untouched.)

### 6.2 NEW `RatingMetrics` table — `lib/database/tables/rating_metrics.dart`
Holds the metric definition **and** its scoring weight (mirrors the relevant
`Adjustments` columns minus the parent FKs, plus `ratingId` + `weight`):
```
id (pk)                       // == the Adjustment's UUID (§5.2)
ratingId → Ratings (cascade)  // owning template
orderIndex (int)              // sort within the template
weight (real)                 // SIGNED; sign = direction (§3). NULL/0 ⇒ not scored-counted
name, notes?, unit?, category (EnumNameConverter<AdjustmentCategory>),
type (textEnum<AdjustmentType>),
jsonPayload?                  // subclass-specific props, exactly as Adjustments stores them
```
The `Adjustment` Dart model's existing `toJson`/`fromJson` + `jsonPayload` serialization
is reused verbatim to read/write these columns — only the table differs.

### 6.3 NEW `RatingEntries` table — `lib/database/tables/rating_entries.dart`
Parallel to [setups.dart](../lib/database/tables/setups.dart). **No `ratingId`** — an entry
spans all applicable ratings (§4.2):
```
id (pk), bikeId → Bikes (cascade),
setupId → Setups (NON-NULL, no onDelete action)   // required provenance (§4.3, §5.3);
                                                  // setups are soft-deleted, so a dangling
                                                  // id is tolerated (FKs not enforced)
name?,
isDeleted, lastModified (UtcDateTimeConverter),
dateTimeUTC (UtcDateTimeConverter), dateTimeLocal (LocalFloatingDateTimeConverter),
notes?, position? (LocationDataConverter), place? (PlacemarkConverter),
weather? (WeatherConverter)
```

### 6.4 NEW `RatingEntryValues` table — `lib/database/tables/rating_entry_values.dart`
Parallel to [setup_adjustment_values.dart](../lib/database/tables/setup_adjustment_values.dart),
but keyed on the metric (not an adjustment):
```
ratingEntryId  → RatingEntries (cascade),
ratingMetricId → RatingMetrics (cascade),
value (text, parsed back by the metric's type),  pk = {ratingEntryId, ratingMetricId}
```

### 6.5 `Setups` table
**No column change** — today `ratingAdjustmentValues` is stored in the shared
`SetupAdjustmentValues` junction, not as a column. After the refactor the setup save
path simply stops writing rating-category rows; old rows (if any) are orphaned and
harmless. (Optional one-time cleanup, not required.)

### 6.6 Schema version + codegen
- Bump `schemaVersion` in [app_database.dart](../lib/database/app_database.dart) (3→4).
- `onUpgrade` (non-destructive for component/person data):
  - create `RatingMetrics`, `RatingEntries`, `RatingEntryValues`
    (drift `m.createTable(...)`);
  - drop the `ratingId` column + recreate the CHECK on `Adjustments` — simplest via a
    drift table recreation/`alterTable` migration step (SQLite can't drop a column
    in-place pre-3.35; use drift's `TableMigration`/recreate helper). Component/person
    rows are copied across; rating rows are discarded (disposable).
- New DAOs: `RatingsDao` updates (metrics now from `RatingMetrics`, carry `weight`) and a
  new `RatingEntriesDao` (soft-delete mixin, `watchAll...WithValues`, insert/update with
  values transaction, reorder).
- Mappers in [mappers.dart](../lib/database/mappers.dart): `RatingMetric` ↔
  `RatingMetricDb` (reusing `Adjustment` json), `RatingEntry` ↔ companion + values.
- Run `flutter pub run build_runner build --delete-conflicting-outputs`.

---

## 7. Score computation

New pure, unit-tested service `lib/services/rating_score_service.dart`.

**Per-metric normalization → [0,1]** (`nᵢ`):
- **Step / Numerical:** `n = (value - min) / (max - min)` (requires finite min<max).
- **Duration:** same on `inMicroseconds` (requires finite min/max).
- **Boolean:** `true → 1.0`, `false → 0.0`.
- **Text / Categorical:** skipped (not scored).
- Direction is applied as a **per-metric "goodness"**: `gᵢ = nᵢ` if `wᵢ ≥ 0`
  (higher is better), else `gᵢ = 1 − nᵢ` (lower is better). The weight's **sign** carries
  direction, its **magnitude** the importance; `wᵢ = 0` ⇒ captured but not counted.

**Per-entry — compute BOTH a weighted average and a weighted sum (see §7.1):**
```
scored = metrics where isScored AND wᵢ ≠ 0 AND answered AND has finite bounds
weightedSum = Σ(gᵢ · |wᵢ|)                       // ≥0, unbounded; grows with breadth+quality
weightedAvg = (weightedSum / Σ|wᵢ|) · 10         // → 0–10, higher = better (headline score)
```
- Using **goodness `gᵢ`** (not signed `nᵢ`) gives a clean full-range 0–10: a positive
  metric at its worst scores 0, at its best 10 (the earlier `(avg01+1)·5` form compressed
  positive metrics into `[5,10]` — fixed). Negative weights ("how bad…") invert correctly.
- All metrics share the same normalization so units never dominate.
- **`weightedAvg`** is the comparable, fixed 0–10 score (invariant to how many questions
  were answered). **`weightedSum`** is unbounded and *implicitly* encodes breadth (more
  answered + higher quality ⇒ bigger). Both are stored/shown per entry; the user compares
  whichever is meaningful (§7.1).
- Unanswered metrics are simply excluded from the sums (no penalty).
- A metric with `weight = 0` is captured but ignored by both figures.

**Per-setup score — pool each metric across entries, THEN weight (null-safe):**
Do **not** average the already-collapsed per-entry scores — that lets the number of
entries answering a metric distort its weight (an important metric answered in 1 entry
would be diluted vs. a trivial metric answered in 5). Instead:
```
E   = RatingEntries that resolve to this setup
for each scored metric m (across all templates used by E), weight wₘ (wₘ ≠ 0):
    answersₘ = [ gₘ(e)  for e ∈ E  if e answered m and m has finite bounds ]   // goodness [0,1]
    if answersₘ is empty: skip m                                               // null-safe
    ḡₘ = mean(answersₘ)                                                        // pooled per-metric goodness
M   = { metrics with a non-empty answersₘ }
setupScore = M empty ? null                                                    // null-safe: no data ⇒ no score
                     : (Σ_{m∈M}(ḡₘ · |wₘ|) / Σ_{m∈M}|wₘ|) · 10                 // → 0–10
```
- Each metric contributes **once**, carrying its full signed weight, no matter how many
  entries answered it → robust to **sparse / overlapping** entries (your point).
- Fully **null-safe**: metrics with no answer anywhere are skipped; a setup with no
  answered scored metrics (or no entries) yields **`null`** (render as "no score"), never 0.
- Per-entry `weightedAvg` / `weightedSum` are still computed for the entry list (§7); only
  the *setup roll-up* uses this pooled method.

Resolution = the most recent non-deleted setup for the entry's bike with
`datetime <= entry.datetime` (reuse the chronological logic in
[SetupResolutionService](../lib/services/setup_resolution_service.dart)).

Keep aggregation isolated so it can later become recency-weighted or per-track.

### 7.1 Sparse / incomplete rating entries — DECIDED: surface both average and sum

A large catalogue means users will often answer **only some** metrics, and metrics get
**added to a template after** entries already exist. Entries are inherently sparse and we
can't prevent it. **Decision: compute and surface BOTH** the **weighted average (0–10)**
and the **weighted sum** per entry, and **drop the completeness flag.**

Rationale (your call, and it holds up):
- The **weighted average** is **comparable** across entries regardless of how many
  questions were answered — a 2-question and a 12-question entry land on the same 0–10
  axis. This is the headline score and the per-setup roll-up.
- The **weighted sum** is **also comparable between entries** and *implicitly* reflects how
  much was answered and how good it was (more, better answers ⇒ larger sum). So a separate
  **completeness** indicator is redundant — and, as you noted, completeness is **not** in
  itself a "better/worse" signal, so showing it as a quality-adjacent badge would mislead.
- Both are cheap to compute from the same normalized values; showing both lets the user
  read "how good on average" *and* "how much total goodness" without inventing a metric.

So: **no completeness ratio in the score.** Per-entry UI shows the 0–10 average prominently
and the sum as a secondary figure. Per-setup score = mean of entry averages (§7).

**But surface a lightweight "incomplete" hint for UX (not a score input).** Even though
completeness must not influence the score, it's genuinely useful to *tell the user* an
entry didn't answer every metric — e.g. a small muted icon/text like *"3 of 9 metrics"*
or an "incomplete" chip on the entry tile / entry page. This is purely informational (it
explains why an entry looks sparse and invites the user to fill more), and it stays
decoupled from `weightedAvg`/`weightedSum`. Show it whenever answered scored-metrics <
template's scored-metrics.

> The "score has no fixed range" wish is satisfied by the **weighted sum** (unbounded),
> while the **weighted average** provides the fixed 0–10 axis you confirmed — you get both.
> Per-metric normalization is still applied to both so mixed units don't dominate, and
> signed/negative weights are fully preserved.

### 7.2 Score breakdown UX — DECIDED: one public 0–10 axis, weight as `×N`, points as the receipt

The entry detail shows "how the score adds up." Two facts drive the design:
- **For a single entry, `weightedAvg/10 == weightedSum/Σ|w|`** (same ratio). So Sum and Average
  are *the same number* on one entry — the Sum's only extra info is the **scale** (Σ|w| = how
  much was at stake / breadth). Sum becomes genuinely distinct only **across** entries.
- Showing per-metric `0–1` goodness next to a `0–10` average is a confusing scale clash.

**Decision:** put everything the user reads as a *score* on **0–10**, show **importance as a
separate `×N`**, and keep 0–1 / "points" only in a muted footer:
- Headline = **Score `X.X / 10`** (the weighted average).
- Per-metric row = the metric's **0–10 sub-score** (`goodness×10`) + a **`×weight` chip** +
  a goodness bar; `lower is better` caption for negative-weight metrics; unanswered → "–".
- Muted footer = the additive **"Weighted total `Σcontribution / Σ|w|` pts ( ×10 ÷ max ⇒ X.X/10 )"**
  — preserves the "contributions sum to the total" property for transparency without putting a
  second scale in front of the user. (`contribution = goodness·|w|`.)
- The **Sum stays "total points"**, surfaced as the *receipt*, not a competing headline;
  its cross-entry role (breadth) lives in comparison/analytics views (E′-b), not the single
  entry. Service support: `RatingScoreService.breakdown` → `EntryScoreBreakdown` (per-metric
  rows + `weightedTotal`/`maxTotal`).

---

## 8. UI / pages / widgets

### 8.1 Rating **template** editor — [rating_page.dart](../lib/pages/rating_page.dart)
- **Current state (E0):** the page reuses the existing **Adjustment** add/edit/duplicate/
  reorder pages unchanged (they produce the inner `Adjustment`), and `rating_page` wraps each
  in a `RatingMetric`. Existing metric **weights are preserved on edit**; **new metrics
  default to weight `+1.0`** (no weight UI yet). This is the agreed interim behaviour.
- **DECIDED target — dedicated RatingMetric add/edit pages with a weight field.** The user
  wants the metric definition *and* its weight edited together in a proper metric editor
  (the Adjustment pages already have a drag-a-slider **preview** — value not saved, just
  visualization — which will later be extended to show the **resulting score in realtime**,
  §8.1.1). Open implementation question (work out later): **either** add `if`/mode clauses to
  the existing 6 adjustment pages to optionally show a weight field and return a
  `RatingMetric`, **or** add separate `RatingMetric*Page` dart files (likely via extracting
  each adjustment page's form *body* into a shared widget so the metric page = body + weight
  field + score preview, avoiding 6× duplication — see the earlier discussion). Until then,
  the interim per-row/weight-1 behaviour above stands.
- Weight semantics when the editor lands: a **signed weight number field** pre-filled with the
  default (`+1.0`, or `−1.0` for Duration) and, below it, a **dynamic helper text** describing
  the sign's effect (*"Lower Duration is better"* / *"Higher values improve the score"* /
  *"Not counted in the score"* when 0). **No direction toggle.** Text/categorical → muted
  "Not included in score" hint.

### 8.2 Rating **entry** editor — NEW `lib/pages/rating_entry_page.dart`
- Reuse the context-capture UX from [setup_page.dart](../lib/pages/setup_page.dart):
  date/time pickers, location/place chip, weather + condition chips
  (`_wrap()` logic, location/address/weather services). Factor the shared widget out if
  practical (`lib/widgets/setup_context_capture.dart`).
- Pick the **bike**, then render the metrics of **all ratings that apply** to it
  (global / bike / component / componentType / person filters), grouped per rating — exactly
  like the old `SetupRatingTab` listed every applicable rating at once. Reuse those value
  widgets. No single-template selection (§4.2).
- On save → one `RatingEntry` whose `metricValues` span all filled metrics. Show the live
  computed **entry score (0–10 average)** with the **weighted sum** as a secondary figure
  (§7.1). Surface the **drift warning** here when applicable (§4.3).

### 8.3 Where RatingEntries appear
**Creation** stays setup-centric (no global FAB) — entries are *created* through a setup:
- **SetupCard popup menu — [setup_list_card.dart:239](../lib/widgets/items/setup_list_card.dart#L239):**
  extend the existing `_SetupOptions` `PopupMenuButton` (today: edit / share / restore /
  remove) with **"Add Rating"** and **"Ratings (n)"** (open the setup's rating list).
- **Setup detail page** (see §8.4): the full list of a setup's entries + their scores.
- New `lib/widgets/items/rating_entry_list_card.dart` (used in the setup detail list and
  the popup-launched list): template name, date, place, condition, 0–10 score + weighted
  sum, and any drift warning.

**Visibility — REVISED (2026-06-19): RatingEntries are surfaced globally, behind one display
flag.** RatingEntries carry their own datetime + position, so they *are* shown on the
**SetupList, the Map, and the Calendar**, governed by a single **global `displayShowRatingEntries`
flag** that mirrors the existing `displayShowSetups` / `displayShowActivities` /
`displayShowInstallations` display toggles (filter sheet chip in
[filter.dart](../lib/widgets/sheets/filter.dart) + roll-up in
[filter_sheet_chip.dart](../lib/widgets/chips/filter_sheet_chip.dart)). Toggling it
shows/hides rating entries (and the setup rating-score badge) **everywhere at once**, not just
in the SetupList. Gate on `enableRating`. This supersedes the earlier "no
`displayShowRatingEntries` flag / no calendar/map items" note — a `RatingEntryTimelineEntry`
(or equivalent map/calendar item) is now in scope. (See §E′-a.)

### 8.4 Setup detail / setup card
- Setup detail page: show the **setup score** + a section listing the `RatingEntry`s that
  resolve to it, each tappable to edit, plus an **"Add rating"** action (pre-fills bike +
  datetime so the new entry resolves to this setup).
- Setup list card: show a small **score badge** (the setup score) — reinforces the
  setup-centric focus. **Remove** the now-defunct `displayRatingAdjustmentValues` path
  ([setup_list_card.dart:315](../lib/widgets/items/setup_list_card.dart#L315),
  [setup_list.dart:153](../lib/widgets/lists/setup_list.dart#L153)) and the
  `setupListRatingAdjustmentValues` setting, since setups no longer hold rating values.

### 8.5 Remove from setup_page
- Delete `SetupRatingTab`, `_filteredRatings`, `_ratingAdjustmentValues`,
  `_initialRatingAdjustmentValues`, `_danglingRatingAdjustmentValues`,
  `_setFilteredRatings`, rating branches in `_setDangling/_setInitial/...`, the Rating
  tab in `TabBar`, and the `ratingAdjustmentValues` plumbing in `_saveSetup`. This
  meaningfully **shrinks** setup_page.
- Keep `enableRating` gating (`AppSettings`) for all new rating UI.

---

## 9. AppRepository changes — [app_repository.dart](../lib/repositories/app_repository.dart)
- Update rating CRUD to carry `RatingMetric`s (signed weight) through the DAO, now backed
  by the `RatingMetrics` table (no longer `Adjustments`).
- Add `ratingEntries` in-memory state + CRUD (`addRatingEntry`, `editRatingEntry`,
  `removeRatingEntries`/`restore`, watch wiring) following the rating/setup patterns.
- Add filtered views (by `_selectedBike`) and derived getters:
  `ratingEntriesForSetup(setupId)`, `scoreForSetup(setupId)` (nullable — per-metric pooled,
  §7), `entryScore(entry)` (0–10 average), `entryWeightedSum(entry)`, and
  `resolvedSetupFor(entry)` (for the drift warning).
- No new display/timeline flag (ratings surface only via the SetupCard menu, §8.3).
- Wire `RatingScoreService`; recompute on rating/entry/setup changes (these already
  trigger `notifyListeners`).

---

## 10. Decisions & remaining questions

**Resolved**
- **Naming:** `RatingEntry` (parallels existing `TaskEntry`). ✅
- **Entry spans all applicable ratings** (revised — no `ratingId`; like the old setup
  rating tab). ✅
- **Scored numeric/duration bounds:** require finite min/max when a metric is scored. ✅
- **Setup linkage:** hybrid — resolve dynamically (authoritative for score) **and** store
  a write-once `setupId` provenance snapshot; warn on drift (§4.3). ✅

- **Aggregation:** per-setup score = **per-metric pooled mean** then signed-weighted, not
  a mean of entry scores (respects weights under sparse/overlapping entries); null-safe (§7). ✅
- **Weight UX:** signed **number field** pre-filled with default + **dynamic helper text**
  describing the sign's effect; **no direction toggle**, no `higherIsBetter` field. ✅
- **Direction default:** signed weight, default `+1.0`, Duration default `−1.0`. ✅
- **Entry surfaces:** **only** via the SetupCard popup menu + setup detail page — no
  timeline/calendar/map item, no global FAB (setups stay the focus). ✅
- **Drift warning UX:** **passive** info in the entry list tile and on the entry page. ✅
- **Sparse entries:** surface **both** the weighted **average (0–10)** and the weighted
  **sum**; **no completeness flag** (§7.1). ✅
- **Fixed 0–10 axis** for the average (sum stays unbounded). ✅
- **Score display:** **0–10** numeric. ✅
- **Storage:** full separation (Option B) — rating metrics live in a dedicated
  `RatingMetrics` table; `Adjustments` loses its `ratingId` FK + CHECK arm (§6). ✅
- **Incomplete hint:** show a passive "n of m metrics" / "incomplete" indicator on entries
  (UX only, never affects the score) (§7.1). ✅
- **Strava-segment objective metric:** **deferred** — not in this phase; architecture &
  vision captured in §11. ✅
- **Metric catalogue:** curated **presets already shipped** (no blank page). Open *future*
  lever (not this phase): a stable **semantic key** per metric for cross-user poolability —
  decide the convention early, it's hard to reverse (§11.8). ✅

**All open questions for this phase are resolved — ready to implement (Phase A onward, §13).
Strategy/vision items live in §11 and are intentionally out of scope for v1.**

---

## 11. Future / vision & strategy (NOT in this phase)

All deferred, but the v1 architecture is designed so these slot in without rework.
**§11.1–11.6** cover Strava segments; **§11.7–11.10** capture the broader data-foundation
strategy distilled from the competitive review (SAGLY, Suspend).

### 11.1 Requirements (target behaviour)
- Track **only selected or Strava-starred segments** (not every segment the user ever rode).
- When a new activity arrives via the **Strava webhook**, automatically rate the setup that
  was active when the ride happened.
- That means **auto-create a `RatingEntry`** for the resolved setup, filled with the
  segment effort time(s).
- Introduce a way to capture a segment as a metric — the user's idea of a new
  **segment adjustment type** where you pick a Strava segment.

### 11.2 Proposed integration
- **New `SegmentAdjustment` metric type** (sealed `Adjustment` subtype) that stores
  `segmentId` + `segmentName` (+ optional distance) and behaves like a **Duration** for
  capture/scoring, with a **negative default weight** (faster = better). Its `jsonPayload`
  carries the segment binding. It can be excluded from the manual adjustment pickers (it's
  populated by Strava, not typed).
- **Tracked-segments registry:** a small store of segment ids the user opted into — seeded
  from Strava *starred segments* (the API can list them) plus manual in-app selection. UI
  to manage this list (future).
- **Webhook → auto-entry pipeline** (extends `StravaService`'s existing webhook/Firestore
  listener + activity sync): on a new activity →
  1. resolve **bike** via `gearId` (already done in `SetupPage.addFromStravaActivity`);
  2. fetch the activity's **segment efforts**; keep only efforts on **tracked** segments;
  3. resolve the **active setup** for that bike at the activity datetime (§4.3 logic);
  4. **auto-create a `RatingEntry`** holding each tracked segment's effort time, with the
     activity's datetime / position / place / weather as the entry context, and the
     write-once `setupId` provenance.
- Result: an objective, automatically-labelled data point per setup per ride — exactly the
  clean signal the ML vision wants.

### 11.3 The relevance caveat (your Finale "DH-men" example) — and the fix
Your worry is real **if segment metrics are placed inside a hand-filled template**: the
template would forever prompt "DH-men", and entries elsewhere would look odd. The fix is a
modelling rule:

> **Segment metrics are auto-generated and segment-scoped — never mixed into a manual
> subjective template, and never compared across different segments.**

Concretely this dissolves the caveat:
- **"Always shows DH-men":** segment metrics live in an **auto-managed objective rating**
  (or one auto-rating per tracked segment), *not* in the manual questionnaire — so the
  manual rating UX never shows DH-men. You only ever see DH-men data when you actually rode
  it.
- **"Sum is messed up":** our scoring **excludes unanswered metrics** from both the sum and
  the average (§7), so a segment you didn't ride contributes nothing. And because segments
  are **compared per-segment, never blended** with subjective metrics or with other
  segments, leaving Finale simply means no new DH-men entries appear — old ones stay valid
  as the genuine performance record of that test week.
- **Relevance window is implicit:** an entry exists **iff** there was an effort, so the
  data is inherently scoped to where/when you actually rode the segment. No manual
  archiving needed (though a "retire/untrack segment" action is a nice-to-have).

### 11.4 Normalization for segment times (a nice opportunity)
Manual scored metrics require finite bounds (§4.1), but for a segment the natural,
*meaningful* normalization is **per-segment against the athlete's own effort
distribution** — best effort → 10, worst → 0 (or PR/KOM as the anchor). This is the one
place where "normalize against observed values" (rejected for manual metrics) is exactly
right, because all efforts on one segment are directly comparable. Keep this logic inside
`RatingScoreService` as a segment-specific normalizer.

### 11.5 Assessment — is it a good idea?
**Yes — it's the highest-value future hook**, because it injects *objective* labels into a
dataset that is otherwise all self-reported. It also fits the architecture with no schema
churn (a new metric type + an auto-entry producer; everything else — entries, setup
resolution, scoring, context capture — already exists).

**Caveats to plan for:**
1. **Noisy label:** segment time reflects fitness, fatigue, traffic, line choice, tyre
   wear, weather — not just the setup. Treat it as a weak/noisy signal; rely on the
   already-captured `weather`/`condition` to filter or stratify, and require several
   efforts before trusting a comparison.
2. **Effort data + API cost:** the webhook gives an activity id; segment efforts need a
   detailed-activity fetch → watch Strava **rate limits**; efforts only exist if Strava
   matched the segment.
3. **Data-retention policy:** auto-creating entries means **persisting derived Strava data
   on-device indefinitely**, which collides with the 2026 API ~7-day cache limit already
   flagged in our retention risk note — must be clarified with Strava before shipping this.
4. **Resolution gaps:** unmapped `gearId` → no bike → no auto-entry; no logged setup at the
   ride time → entry resolves to the most recent setup (drift warning covers later edits).
5. **Duplicates / laps:** multiple efforts on one segment in a ride — pick best effort per
   activity (simplest) or one entry per effort (more data); decide later.
6. **Privacy/UX:** silently creating entries can surprise users — make auto-rating opt-in
   per segment and visibly attributed ("auto from Strava").

**Improvements / ideas:**
- Compare and chart **within a segment** ("which setup is fastest on DH-men?") — this is
  the cleanest, most motivating view and a natural ML grouping key.
- Stratify by `condition`/weather so wet vs. dry efforts aren't conflated.
- Let a starred segment define an implicit "test session" so the UI can surface
  *"3 setups compared on DH-men this week"*.
- Store the raw effort time alongside the normalized value so re-normalization is lossless
  as more efforts arrive.

### 11.6 ML
Each setup → feature vector (bike/person adjustment values + context); labels = setup score
*and/or* per-segment objective times. The normalized [0,1] per-metric values are already
model-ready; **group by segment** so objective lap/segment times are never averaged across
different tracks. Segment entries give the model trustworthy, automatically-growing labels.

### 11.7 Positioning & two-track recommendation strategy
The product goal is **the data foundation for genuinely qualified recommendations**, not
(yet) the recommendation itself. Competitive read: **SAGLY** = coach/community + guided
base setup; **Suspend** = AI/LLM conversational tuner + service tracking. Both close the
loop and solve cold-start; both may be shallower in reality than advertised. Our
differentiator is the **complete, context-rich, longitudinal per-rider history** (setup
values + per-metric scores + free text + weather/condition + Strava) — the fuel neither
competitor has per user.

Recommended long-term loop is **two-track and complementary**:
- **Track A — generalized (LLM + heuristics + domain knowledge):** carries the **early /
  cold-start** phase, maps symptom language → adjustment changes (like Suspend's chat).
  Our edge over a generic chat is **grounding it on the user's own history** ("for you,
  rebound −2 in the wet last gained +1.3").
- **Track B — personal data-driven (ML):** takes over as the rider's rated history grows;
  delivers true personalization.
- The **historical store is the moat for both** — training set for Track B *and* RAG
  context for Track A. Recommendations should be **explainable and confirm-only** (never
  auto-apply). LLM-on-user-data implies cost/privacy/Strava-retention considerations.

### 11.8 Data principles (decide the convention now, even while local-only)
- **Raw per-metric normalized values + context are the asset — the aggregate score is a
  reinterpretable UX/ranking artifact.** Weights and the 0–10 score can be recomputed
  anytime; the raw measurements cannot be recovered. ⇒ feed ML the **raw per-metric vector**
  (not just the score), and don't over-stress getting weights "perfect".
- **Metric catalogue — presets done; shared/semantic vocabulary is the open lever.**
  Curated **presets already ship** (good — solves the blank-page/cold-start of *measurement
  design* and keeps a user's data internally consistent). The remaining high-value, and
  **hard-to-reverse**, decision is whether metrics carry a **stable semantic key from a
  controlled vocabulary**. Today everything is local/per-user, but free-form, idiosyncratic
  metric names make a future **cross-user** pool impossible (User A "grip in turns" vs.
  User B "front traction" = non-poolable columns). A semantic key (preset metrics map to
  shared concepts; custom metrics flagged personal/non-poolable) keeps the door open at
  near-zero cost now — and is the same anchor Track A/heuristics need to reason
  domain-aware over generic adjustments. **Adopt the convention before data accumulates.**

### 11.9 Delta as the learning unit (setup change → feel/score change)
Both competitors think in **changes** ("you turned rebound +2 — how did it feel?"). The
real causal signal for the feedback loop *and* for ML is the pair **(Δ between consecutive
setups, Δ in resulting rating/score)** — not isolated snapshots. The data already supports
this (setups are chronological; `previousBikeAdjustmentValues` already expose deltas). Make
the `(setup-delta → rating-delta)` pairing **easily computable/queryable** so a simple,
explainable, *data-driven* "next step" (à la SAGLY) can be offered **from the score alone,
before any ML** — e.g. "Setup B (7.8) beat A (6.2); main change was rebound +2 → keep that
direction." Also note **multi-discipline profiles** (Suspend's park/XC/trail one-tap
switch): our tags + setup history can express this; revisit if a first-class "profile"
concept is wanted.

### 11.10 Cold-start of the *setup itself* (product gap)
Distinct from metric presets: a brand-new user still has **no starting setup**. Competitors
fill this (SAGLY: SAG method + tyre-pressure calc + factory-settings import; Suspend: AI
base tune from weight/style). Our app currently assumes setups already exist. Plan a
**base-setup entry point** (rider profile + component-type defaults / factory settings /
LLM-generated) so day-one users aren't on a blank page. No model change — a product/UX
addition, but important for adoption parity.

---

## 12. Touched files

**New**
- `lib/models/rating_metric.dart`, `lib/models/rating_entry.dart` ✅ (done)
- `lib/models/context/context_position.dart`, `context_place.dart` — shared
  `ContextPosition`/`ContextPlace` codecs (also used by Setup); `context_weather.dart`
  (`ContextWeather`, moved from `weather.dart`) ✅ (done)
- `lib/services/rating_score_service.dart` + `test/rating_score_service_test.dart` ✅ (done)
- `lib/database/tables/rating_metrics.dart`, `lib/database/tables/rating_entries.dart`,
  `lib/database/tables/rating_entry_values.dart`
- `lib/database/daos/rating_entries_dao.dart`
- `lib/pages/rating_entry_page.dart`
- `lib/widgets/items/rating_entry_list_card.dart`, (optional) `lib/widgets/lists/rating_entry_list.dart`
- `lib/utils/rating_entry_actions.dart`
- (maybe) `lib/widgets/setup_context_capture.dart` — extracted date/place/weather widget

**Modified**
- `lib/models/rating.dart` — metrics, json v3
- `lib/models/setup.dart` — drop `ratingAdjustmentValues`, json bump, derived score;
  geo helpers now delegate to `ContextPosition`/`ContextPlace`; weather is `ContextWeather`
  (`lib/models/context/`) ✅ (geo/context part done)
- `lib/database/tables/adjustments.dart` — **remove** `ratingId` FK; simplify CHECK to
  (component_id, person_id)
- `lib/database/app_database.dart` — schemaVersion 3→4, onUpgrade (create 3 tables +
  recreate `Adjustments`), register DAOs/tables
- `lib/database/mappers.dart` — `RatingMetric`↔`RatingMetricDb`, `RatingEntry` mappers
- `lib/database/daos/ratings_dao.dart` — metrics from `RatingMetrics` (signed weight),
  stop joining `Adjustments` for ratings
- `lib/repositories/app_repository.dart` — rating-entry state, CRUD, score getters
- `lib/models/app_settings.dart` — remove `setupListRatingAdjustmentValues`
- `lib/pages/rating_page.dart` — metric signed-weight editor
- `lib/pages/setup_page.dart` — remove rating tab + all rating plumbing
- `lib/widgets/setup_page_tabs.dart` — remove `SetupRatingTab`
- `lib/widgets/items/setup_list_card.dart` — add Rating options to `_SetupOptions` popup
  menu + setup score badge; drop `displayRatingAdjustmentValues` param
- `lib/widgets/lists/setup_list.dart` — drop `displayRatingAdjustmentValues` wiring
- `lib/pages/details/setup_details_page.dart` — score + entries section + "Add rating"
- `lib/utils/rating_actions.dart` — adjust for metrics

**Regenerate:** `flutter pub run build_runner build --delete-conflicting-outputs`

---

## 13. Step-by-step TODO

**A. Models (no DB yet)** ✅ done
1. ✅ `RatingMetric` model (+ `isScored`, json, copyWith, equality, deepCopy).
2. ✅ Refactor `Rating` to `List<RatingMetric> metrics` (+ json v3).
3. ✅ `RatingEntry` model (context fields reusing Setup helpers; json, copyWith, equality).
4. ✅ Strip `ratingAdjustmentValues` from `Setup` (+ json bump).
5. ✅ Shared context wrappers extracted to `lib/models/context/`.

**B. Scoring** ✅ done
6. ✅ `RatingScoreService`: per-metric normalize, per-entry `weightedAvg` (0–10) +
   `weightedSum`, and per-setup **per-metric pooled** score (null-safe, §7).
7. ✅ Unit tests (11 passing): bounds, signed/negative weights, missing values, mixed
   types, empty entry, comparability of avg across answered-counts, **per-metric pooling
   vs entry-mean under sparse/overlapping entries**, and null-safety (§7/§7.1).

**C. Database** ✅ done
8. ✅ New `RatingMetrics` table (adjustment-def columns + `ratingId` + signed `weight`).
9. ✅ New `RatingEntries` (incl. `setupId` provenance) + `RatingEntryValues`
   (keyed `ratingMetricId`) tables.
10. ✅ Simplify `Adjustments`: drop `ratingId` FK + CHECK arm (recreate-table migration).
11. ✅ `RatingEntriesDao` + `RatingsDao` updates (metrics from `RatingMetrics`).
12. ✅ schemaVersion → **5** + onUpgrade (createTable ×3 + delete rating rows + recreate
    `Adjustments`); register in DB.
13. ✅ Mappers for `RatingMetric` (reuse `Adjustment` json) and `RatingEntry`.
14. ✅ `build_runner build`; generated breakage fixed.

**D. Repository** ✅ done
16. ✅ Rating CRUD carries signed weight (via `RatingMetrics`).
17. ✅ RatingEntry in-memory state + CRUD + filtered-by-bike views.
18. ✅ `scoreForSetup` / `entryScore` getters wired to `RatingScoreService`.

**E. UI** — *mechanical green-up done; new rating UX still pending*
- **E0 (mechanical) ✅ done:** swapped `rating.adjustments` →
  `rating.metrics.map((m) => m.adjustment)` in display code; removed all
  `setup.ratingAdjustmentValues` / `previousRatingAdjustmentValues` /
  `displayRatingAdjustmentValues` usages (incl. `AppSettings.setupListRatingAdjustmentValues`
  + the filter chip); deleted `SetupRatingTab` + all rating plumbing from `setup_page.dart` /
  `setup_page_tabs.dart`; removed the obsolete rating section from `setup_details_page`,
  the rating-metric analytics columns from `component_details_page` / `person_details_page`
  (now fed empty — they'll re-hook to RatingEntries later), and the rating blocks from
  `to_text` / `to_spreadsheet`. `rating_page` now round-trips `RatingMetric`s (preserving
  signed weights on edit; no weight UI yet). `trash_page` restores RatingEntries. **Full
  `flutter analyze` (lib + test) clean and all 291 tests pass.**
19. Metric editor with weight. **Interim (done):** reuse Adjustment pages, weight defaults
    to `+1.0` (preserved on edit). **Target:** dedicated RatingMetric add/edit pages with a
    signed-weight field + dynamic sign helper (scored only; no toggle) + realtime score
    preview — impl approach (if-clauses in adjustment pages vs separate files / body
    extraction) TBD (§8.1).
20. ✅ `rating_entry_page.dart` (context capture + applicable-rating metric inputs + live
    0–10 average + weighted sum + drift warning with Relink; `setupId` resolved in save).
21. ✅ `rating_entry_list_tile.dart` (dense, two scores) + `rating_entry_actions.dart`
    (add/edit/remove/restore w/ snackbar+UNDO).
22. ✅ `setup_list_card.dart`: "Add Rating" / "Ratings (n)" in the `_SetupOptions` popup
    + setup **score badge** (`scoreForSetup`).
23. ✅ Setup detail: setup score + resolving-entries list + "Add rating".
24. ✅ Removed `SetupRatingTab` + all rating plumbing from `setup_page.dart` (E0).
27. ✅ **RatingEntry details (page + sheet)** —
    [rating_entry_details_page.dart](../lib/pages/details/rating_entry_details_page.dart)
    (`RatingEntryDetailsContent` reused by the full page + the
    [sheet](../lib/widgets/sheets/rating_entry_details.dart)). Tapping a `RatingEntryListTile`
    or a Calendar rating item now opens the **details sheet** (edit is a button inside), not the
    editor. Shows the **score breakdown** (§7.2) + context (bike, resolved setup + drift note,
    place, weather/condition) + notes. Backed by `RatingScoreService.breakdown` +
    `AppRepository.entryBreakdown` (2 new unit tests). Map tap → same sheet is pending (E′-a).

**E′. Re-introduce rating signals removed in E0 (sourced from RatingEntries, not setups)**
The E0 pass deleted the old setup-sourced rating displays. These must come back, but now
backed by **`scoreForSetup` / entry scores** (§7), not the removed `ratingAdjustmentValues`:
- **E′-a — Global RatingEntry visibility filter.** ✅ **done.** Global
  `displayShowRatingEntries` flag (filter sheet "Ratings" chip in **both** the Map-visibility
  and Timeline-visibility sections + roll-up in `filter_sheet_chip`) and a
  `RatingEntryTimelineEntry`; rating entries now appear on the **SetupList**, **search**,
  **Calendar** (tap → details, drag → reschedule), and **Map** (amber location-pin markers,
  clustered; tap → details sheet), all gated on `enableRating`. Setup **score badge** respects
  `enableRating`.
- **E′-b — Rating score in analytics.** Re-add a **rating column** to the
  `component_details_page` / `person_details_page` setup tables **and a series to the line /
  radial charts**, showing each setup's **`scoreForSetup`** (0–10). The `ratingMetrics`
  column plumbing was kept (currently fed empty) precisely so this can re-hook to the pooled
  setup score — likely a single "Rating Score" column rather than per-metric columns.

**F. Verify**
25. `flutter analyze` on touched files; `flutter test`.
26. Manual: define a template with signed/negative weights → from a SetupCard menu create
    2 entries on different tracks → confirm per-entry 0–10 average + weighted sum and the
    setup's mean score badge; answer only some questions → confirm the average stays
    comparable; edit a setup's date so entries re-resolve → confirm drift warning; toggle
    `enableRating` off → all rating UI hidden, setup editor clean.
