# SetupList Redesign — Options & Evaluation Report

> A decision report exploring how to make the timeline view (`lib/widgets/lists/setup_list.dart`)
> more sophisticated. Presents architecture + per-feature approaches with pros/cons, not a fixed
> implementation plan.

## Context

`lib/widgets/lists/setup_list.dart` renders a **flat, chronologically sorted** `List<TimelineEntry>`
from 5 sources (setups, Strava activities, task entries, installations, rating entries) in a single
`ListView.builder`. As history grows, the view becomes a long, undifferentiated wall of different
tile types. The goal is to **show only relevant information and visualize context** — group related
events, collapse unchanged data, detect component replacements, and make it obvious when something
happened *during a ride*.

This report lays out the architecture, then for each feature presents **2–3 approaches with
pros/cons and a recommendation**, so the direction is clear before any code is written.

---

## The one architectural decision that enables everything

Today the 200-line `build()` mixes data shaping, horizon/lazy-load logic, and rendering. Every
feature below (day headers, grouping, replacement detection, Strava correlation) needs to *look at
neighbouring entries* — which a per-item `itemBuilder` can't do cleanly.

**Proposal: insert a pure transformation layer between the sorted entries and the renderer.**

```
filteredSetups + strava + tasks + installations + ratings
        │  (existing sort + horizon filtering — UNCHANGED)
        ▼
   List<TimelineEntry>           ← already produced today
        │  buildTimelineRows()   ← NEW pure function, in lib/utils/timeline_grouping.dart
        ▼
   List<TimelineRow>             ← DayHeader | SingleEntry | SetupGroup | Replacement | StravaGroup
        │  CustomScrollView + SliverList.builder
        ▼
        UI
```

`TimelineRow` is a new sealed type. A single pure entry point composes independent passes:

```dart
List<TimelineRow> buildTimelineRows(
  List<TimelineEntry> sortedEntries, {
  required bool sortAscending,
  TimelineGroupingOptions options = const TimelineGroupingOptions(),
});
```

Each pass is `List<TimelineRow> → List<TimelineRow>` and individually unit-testable. `options` gates
each feature independently, so they can ship one at a time.

**Why this is good practice (not over-engineering):** it *extracts* hard-to-test logic out of a
giant `build()` into pure functions — exactly what this codebase already values (60+ test files incl.
`set_installation_timeline_test.dart`). Nothing about data fetching, filtering, or the Strava
horizon/lazy-load mechanism changes; the new layer sits purely on top. The over-engineering risk
lives only in the *rendering* treatments (see each section), which is why each is gated and shipped
incrementally.

---

## Feature 1 — Day section dividers

Group entries under a per-day header (using each entry's **local** day).

| Approach | Pros | Cons |
|---|---|---|
| **A. Scrolling dividers** — day header is a normal `SliverList` item ★ | Zero new deps; tiny change; composes with lazy-load as-is; matches existing empty-state `CustomScrollView` | Header scrolls away (not pinned) |
| **B. Sticky/pinned** — `SliverMainAxisGroup` + `SliverPersistentHeader(pinned:true)` per day | Flutter-native (no package); true pinned headers; orientation while scrolling | Must pre-partition rows by day; write a header delegate w/ fixed extent; more surface area |
| C. 3rd-party sticky header pkg | Easiest sticky API | **Rejected** — no such dep in `pubspec.yaml`; avoid adding one |

**Recommendation: A first, B as a later upgrade.** Both keep `CustomScrollView`. `pubspec.yaml`
confirms no sticky-header package exists, and B needs none, so the upgrade path stays dependency-free.

**Extra polish:** render "Today / Yesterday" relative labels (reusing `DateFormat`) instead of raw
dates for recent days — cheap, big readability win.

---

## Feature 2 — Grouping multiple setups in a time window

Collapse a run of adjacent setups (default window ~2h) into one block that shows **place/bike once**
and, per setup, **only the changed adjustment values**.

| Approach | Pros | Cons |
|---|---|---|
| **A. Same-bike only** ★ | Avoids confusing mixed-bike blocks; clean shared header (bike + place) | Two bikes tweaked back-to-back stay separate (usually desired) |
| B. Any setups in window | Most aggressive clutter reduction | One block can mix bikes/places → header dedupe becomes misleading |

**"Changed values only" is already solved** — `SetupListCard` delegates to
`AdjustmentCompactDisplayList` with `displayOnlyChanges`, whose `valueHasChangedOrInitial` logic
(`lib/widgets/lists/adjustment_compact_display_list.dart`) filters to changed/initial adjustments.
The group row just instantiates **one `AdjustmentCompactDisplayList` per setup** — no new diff logic.

**Recommendation: A (same-bike only).** To keep one source of truth, add a compact/`hideMetadata`
flag to `SetupListCard` (or extract its adjustment block) so grouped members reuse the existing card
without duplicating logic. Show place once from the first member that has one; if members' places
diverge, fall back to per-row place rather than hiding divergent info.

---

## Feature 3 — Replacement detection (special tile)

A **replacement** = a `Deinstallation` of component X and a `BikeInstallation` of component Y where
`X.componentType == Y.componentType`, different component ids, within ~5 min. Render as **one** tile
(deinstall → install) instead of two adjacent installation tiles.

| Approach | Pros | Cons |
|---|---|---|
| **A. Pairing pass over installation entries** ★ | Pure & testable; keys on stable `installation.id`; greedy nearest-time pairing is deterministic | Needs care with the ~5-min threshold and ASC/DESC |
| B. Detect at DB/repository level | Available everywhere, not just this list | Heavier; touches `ComponentInstallation` semantics used elsewhere; premature |

**Algorithm (Approach A):** sort a copy of installation entries by absolute `dateTimeUTC`; forward
scan; for each `Deinstallation` find the nearest unconsumed same-`componentType` `BikeInstallation`
within the window; emit `ReplacementRow`, record both ids in a `consumedIds` set; the main builder
skips consumed entries and places the `ReplacementRow` at the earlier event's slot.

`ComponentInstallation` already exposes `.component.componentType` and the `.installation` subtype,
so no model changes are needed.

**Edge cases (tests):** unmatched deinstall stays a normal tile; `Archival` never participates;
`isInitial` ("Added") never participates; same component moved to another bike is a *move*, not a
replacement (require different component ids).

**Recommendation: A.** Bounded, pure, strong test story; the new combined tile reuses
`InstallationListTile`'s `_CompactBikeLabel` styling.

---

## Feature 4 — Entries during a Strava activity

Activity window = `[startDate, startDate + elapsedTime]` (the model has `elapsedTime`, **no** end
date). Any entry whose UTC time falls inside is "during" the activity.

> **Critical:** membership must be computed from **absolute timestamps**, not list adjacency —
> in DESC order the activity tile appears *after* its during-entries. Compute context independently
> of sort direction, then annotate display rows.

| Approach | Pros | Cons |
|---|---|---|
| **A. Orange left bar** (4px, Strava brand `0xFFFC5200`) ★ | Lowest risk; tiles unchanged; survives day dividers + both sort orders; directly reduces clutter | Less explicit than nesting |
| B. Nest entries inside the activity tile | Strongest semantic grouping | Big refactor; breaks flat sort when entries span midnight; needs expand/collapse state; complicates lazy-load |
| C. Drawn bracket around the group | Visually clear span | Custom painting; brittle with variable tile heights & across day dividers |

**Recommendation: A (orange left bar).** Wrap during-rows in a `_StravaContextWrapper` that paints a
rounded-top/-bottom bar (first/last) matching the existing "View on Strava" orange. Keep B behind
`options.stravaTreatment` as a future option, but don't build it first.

---

## Additional UX ideas (beyond the brief)

1. **Relative day labels** ("Today/Yesterday", week separators for older entries) in headers.
2. **Sticky header running summary** (with Feature 1B): e.g. "3 setups · 1 ride" per day.
3. **Collapsible day sections** — tap a header to collapse; persist collapsed days in `AppSettings`;
   filter them out of the sliver. Falls out naturally from the row-list architecture.
4. **Score/temperature trend chip** on a setup group header showing delta across grouped setups
   (`scoreForSetup` already exists).

---

## Risks & good-practice evaluation

- **Over-engineering?** The pipeline layer *reduces* complexity (testable pure passes vs. a fat
  `build()`). Doing nesting + brackets + pinned headers all at once *would* be over-engineering —
  hence each treatment is gated and shipped incrementally.
- **Lazy-load interaction:** keep the "load more when tail Strava activity is visible" trigger keyed
  on the activity's stable id (relocated into the row builder), so grouping/nesting can't break it.
- **Sort direction (ASC & DESC both supported):** compute Strava membership and replacement pairing
  from absolute UTC timestamps; only day-header insertion and setup-run grouping may use adjacency.
- **Performance:** `buildTimelineRows` builds a concrete list eagerly (like today's `entries`), but
  `SliverList.builder` still builds *widgets* lazily. If profiling shows churn on unrelated
  `notifyListeners`, memoize the result keyed on `(entries identity, sortAscending, horizonDate, options)`.
- **Day boundaries:** anchor a grouped/replacement row to one representative day so it gets exactly
  one header even if it straddles midnight.

## Recommended rollout order (each independently shippable behind an `options` flag)

1. **Day headers** (Feature 1A) — self-contained, immediately visible, lowest risk.
2. **Replacement detection** (Feature 3A) — pure, well-bounded, great tests.
3. **Setup grouping** (Feature 2A) — reuses `AdjustmentCompactDisplayList`.
4. **Strava context bar** (Feature 4A).
5. *(optional, later)* sticky headers (1B) and/or Strava nesting (4B).

## Files involved (when implemented)

- **`lib/utils/timeline_grouping.dart`** *(new)* — `TimelineRow` sealed types, `TimelineGroupingOptions`,
  `StravaContext`, `buildTimelineRows` + per-pass pure functions.
- **`lib/widgets/lists/setup_list.dart`** *(modify)* — `CustomScrollView` + `SliverList.builder` over
  `buildTimelineRows(...)`; relocate lazy-load trigger and pagination loader; keep header/hint + horizon
  filtering unchanged.
- **`lib/widgets/items/setup_list_card.dart`** *(modify)* — compact/`hideMetadata` variant for grouped members.
- **`lib/widgets/items/`** *(new)* — `replacement_list_tile.dart`, `setup_group_card.dart`,
  `strava_context_wrapper.dart`.
- **`test/utils/timeline_grouping_test.dart`** *(new)* — per-pass tests incl. ASC & DESC.

### Reference (read-only)

- `lib/models/timeline_entry.dart`, `lib/models/installation.dart`, `lib/models/strava/strava_activity.dart`
- `lib/repositories/app_repository.dart` (`ComponentInstallation`, horizon/lazy-load getters)
- `lib/widgets/lists/adjustment_compact_display_list.dart`

---

# Round 2 — Refinements after first on-device review (2026-07-07)

Rollout 1–4 is implemented (`buildTimelineRows` pipeline + tiles + 30 unit tests). The points below
came from reviewing the result on-device. Guiding principle: **the timeline reads as day sections
containing event blocks; a ride is a block that owns everything that happened during it.**

## R1 — Strava bar on *every* activity ("ride block" model)

**Change of mental model:** the orange bar no longer means "entry during a ride" — it marks a
*ride block*: the activity tile itself plus every entry inside its time window. Consequences:

1. **Every** activity tile gets the bar (previously only activities containing entries).
2. Two adjacent activities must read as **two separate blocks**: bars never merge across different
   activity ids. Visually enforced with a small vertical end-inset (~3 px) at `isFirst`/`isLast`,
   so back-to-back rides show a visible break while a ride + its during-entries stay seamless.
3. **New ordering pass (block regrouping):** rows attributed to activity X are pulled adjacent to
   X's tile — immediately after it in ASC, immediately before it in DESC — preserving their
   relative order. No-op when activities don't overlap (the common case).

**Overlap edge case** (a2 starts during a1):
- Entry inside *both* windows → innermost wins (latest `startDate`, i.e. a2) → chronological order
  already yields contiguous blocks: `a1 | a2, entry`.
- Entry inside a1 *only* but after a2's start (a2 already ended) → block regrouping reorders
  display to `a1, entry, a2` (ASC) / `a2, entry, a1` (DESC). Displayed times become locally
  non-monotonic — accepted price for unbroken blocks.
- Both cases get dedicated ASC + DESC tests in `timeline_grouping_test.dart`.

## R2 — Setup group card polish *(decided 2026-07-07)*

- **Group condition tightened:** members must additionally share the same **local day** (keeps the
  header's `HH:mm – HH:mm` range honest). The 2 h adjacency chain stays — a morning and an evening
  session on the same day remain separate groups.
- **No "Current" border / corner label on the group card** — a group is not "current", one member
  is.
- **Header:** bike (title), time range (single time when min == max), setup count, shared place,
  weather (temperature + condition) from the first member that has any — shared testing-session
  context. No date (the day band carries it, see R4).
- **Members are radically minimal (test-session view):** each member renders **only its collapsed
  `AdjustmentCompactDisplayList`** (changed values only) stacked vertically, plus an
  expand chevron. Expanding a member reveals its setup title, time, score, tags/images/notes,
  editing popup menu, and the full (all-values) adjustment list. Tapping a member still opens the
  setup details page. Rationale: in a 5-setup test session the *values* are the relevant data;
  everything else is one chevron away.
- **The current member** is framed at group level: primary border + small `Current` label around
  that member's section.

## R3 — Replacement tile & dedicated sheet *(decided 2026-07-07)*

- **Tile:** verb title (`⇄ Replaced Fork`, `Icons.swap_horiz` inline in the title row); subtitle
  has 4 lines: time (range when the two events differ), bike, `Installed <new>`,
  `Deinstalled <old>` (with component-type icons).
- **Tap opens a dedicated ReplacementSheet** (`lib/widgets/sheets/replacement_sheet.dart`) —
  **combined editor**: swap preview box (mirrors `InstallationSheet`'s origin→target box) +
  bike/time, then both components' `SetInstallationTimeline`s stacked vertically (side-by-side is
  too cramped on phones), each with only its replacement event editable, one Save persisting both
  components.

## R4 — Prominent full-bleed day dividers + date de-duplication

- Horizontal list padding moves from the sliver into the individual rows so day headers can span
  the **full screen width** as a slim band (`surfaceContainerHighest`, small vertical padding) —
  clearly a *section* boundary, not just another divider line.
- Header text always carries the absolute date: `Today · Mon, 07.07.2026`.
- **Dates disappear from tiles inside the timeline** (time stays) *(decided 2026-07-07)*: with day
  sections, per-tile dates are redundant noise — the standard feed pattern (Strava, messengers,
  photo apps). Since `StravaListTile` / `TaskEntryListItem` / `InstallationListTile` /
  `RatingEntryListTile` / `SetupListCard` are reused outside the timeline (search overlay,
  task-rule details page, Strava dashboard), this is an opt-in `showDate: false` flag passed only
  by `SetupList`; everywhere else keeps the date.


TODOS: More refinements after the ROUND 2
- Setup group. Expand collapsed setups to use full width so that chevron buttons align horizontally. Use horizontal dividers to divide setups. 
- Setup group: i dont like bike as title. replace it with "2 Setups" from the subtitle. put bike in the subtitle. 
- Replacement sheet/Preview: Remove time from preview. its not obvious which component is installed/deinstalled. Maybe we can use green/red colors or other style to improve this. Put the bike above the "component <-> component". 
- replacement sheet: if both compeonnts have the same name the sections titles are equal. maybe add a little hint (icon or text). 
- replacement tile: 
- MAJOR BUG: When i edit something like a taskEntry or Setup (change the datetime and save). Coming back to the setupList, it wont update as expected. Should be displayed as during activitiy (left orange bar) now but isnt. 