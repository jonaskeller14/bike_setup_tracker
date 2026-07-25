# Calendar event grouping — concept brainstorming

**Status:** Brainstorming — pick one option per section, then run /plan.

Goal: bring the timeline **event-grouping framework** SetupList already uses
(`buildTimelineRows` in `lib/utils/timeline_grouping.dart`) into
`lib/pages/calendar_page.dart`, **starting with replacement detection**. A
replacement collapses the two installation events (the part that came off + the
part that went on) into one calendar appointment that, when tapped, opens the
same `showReplacementSheet` SetupList uses. The design must be a *framework*:
adding the next grouping (setup groups, future collapse types) later should be a
small change, not a rewrite. Everything stays behind the existing AppSettings
flag(s), and the Strava horizon/coverage loading must behave exactly as today.

### What the code does now (constraints)

- **SetupList** builds `List<TimelineEntry>`, sorts it, then calls
  `buildTimelineRows(entries, sortAscending, appSettings)` → `List<TimelineRow>`
  (sealed: `SingleEntryRow`, `SetupGroupRow`, `ReplacementRow`, `DayHeaderRow`).
  Each concern is gated by its own flag: `enableTimelineReplacementDetection`,
  `enableTimelineSetupGrouping`, `enableTimelineStravaContext`,
  `enableTimelineDayHeaders`. `pairReplacements(...)` is the pure, sort-order-
  independent pairing core; it returns anchor-keyed pairs + consumed ids.
- **CalendarPage** never touches `buildTimelineRows`. `_buildEntries` returns raw
  `TimelineEntry`s straight into `_TimelineDataSource extends
  CalendarDataSource<TimelineEntry>`. Top-level helpers
  `calendarIconFor/ColorFor/OnColorFor/SubjectFor(TimelineEntry)` drive rendering.
  `_onTap` and `_onDragEnd` `switch` on the `TimelineEntry` subtype.
- **Strava coverage:** `_ensureStravaCoverage(visibleDates)` pages older
  activities in as the user scrolls back. It reads `repo.stravaActivities` /
  `hasMoreStrava` and is completely separate from how entries become appointments.
  Grouping is a *pure post-process* on the already-built entry list, so it can be
  inserted between `_buildEntries` and the data source without touching coverage.
- **Reuse target:** `ReplacementRow`, `ReplacementListTile`, `showReplacementSheet`,
  `pairReplacements`, and the `EntryRow.anchorDateLocal` anchor all already exist.

The document has these independent decision axes:

- **A. Grouping engine** — how the calendar obtains grouped items
- **B. Appointment model** — what the Syncfusion data source holds
- **C. Flag scope** — which groupings the calendar honors (now / later)
- **D. Interaction** — tap + drag for a grouped (multi-event) appointment
- **E. Rendering** — icon / colour / subject / time-span for a grouped appointment

---

## A. Grouping engine: how the calendar gets grouped items

### A1 — Reuse `buildTimelineRows`, filter to `EntryRow` (recommended)

Sort `_buildEntries()` output, call `buildTimelineRows(...)`, drop `DayHeaderRow`s,
feed the remaining `EntryRow`s to the data source. Same engine, same flags, one
call site.

**Pros:**
- Maximum reuse: replacement pairing, setup grouping, and any *future* collapse
  type come along for free the moment their flag is on — this is the "framework"
  the user asked for, with near-zero calendar-side code.
- One source of truth for grouping semantics; SetupList and Calendar can never
  drift apart on what counts as a replacement.
- `pairReplacements` is already sort-independent and deterministic, so calendar
  order (which is irrelevant — Syncfusion positions by date) doesn't matter.

**Cons:**
- `buildTimelineRows` also runs the **Strava-context reordering** pass and emits
  **day headers**, both list-only. We'd compute + discard them. Wasted work is
  trivial, but `stravaContext` annotation on rows is meaningless for calendar.
- Couples calendar to list-only concepts it must then ignore — mild conceptual
  noise. Mitigated by A3.

### A2 — Call only `pairReplacements`, keep everything else raw

Calendar keeps feeding raw `TimelineEntry`s, but first runs `pairReplacements`,
removes both consumed installations, and injects one synthetic replacement item
per pair.

**Pros:**
- Surgical: touches only replacement, nothing else changes in the calendar.
- No exposure to day-header / strava-context passes at all.

**Cons:**
- Re-implements the "emit combined row at the anchor slot, skip the other half"
  loop that `buildTimelineRows` already contains — redundant logic to keep in sync.
- Not a framework: adding setup grouping later means writing a *second* bespoke
  collapse path in the calendar. Directly against the stated goal.

### A3 — Extract a shared `collapseIntoRows()` core, both callers use it (recommended companion to A1)

Refactor `buildTimelineRows` so its *grouping* body (replacement + setup-group
collapsing) is a standalone function returning `List<EntryRow>`; the existing
`buildTimelineRows` calls it and then layers strava-context + day headers on top.
Calendar calls the core directly.

**Pros:**
- Calendar gets exactly the grouped rows with no list-only passes computed or
  discarded — clean separation, honest layering.
- Still a single grouping source of truth; framework property preserved.
- Makes the list function's own structure clearer (grouping vs. list-decoration).

**Cons:**
- A real (small) refactor of a load-bearing function that SetupList depends on;
  needs its existing behavior held constant (covered by existing timeline tests +
  a golden-ish check). Slightly more up-front work than A1 alone.

---

## B. Appointment model: what `_TimelineDataSource` holds

### B1 — Widen the data source generic to `EntryRow` (recommended)

Change `_TimelineDataSource extends CalendarDataSource<EntryRow>`.
`getStartTime` = `row.anchorDateLocal`; `getEndTime` special-cases
`SingleEntryRow(StravaEntry)` (elapsed time) and `ReplacementRow` (earlier→later
installation span), else `+ kCalendarZeroDuration`. `SingleEntryRow` unwraps to
the existing per-entry helpers.

**Pros:**
- One uniform appointment type; tap/drag/render all branch on the row sealed type,
  which the analyzer exhaustively checks (no silent gaps when a new row type lands).
- `EntryRow.anchorDateLocal` already gives the correct single anchor for grouped
  rows that straddle events.

**Cons:**
- Every `calendar*For(TimelineEntry)` helper needs a row-aware sibling (see E).
- Drag-and-drop's `convertAppointmentToObject` and `_onDragEnd` must handle rows,
  not entries — more switch arms (see D).

### B2 — Keep `TimelineEntry` generic, add a `ReplacementEntry extends TimelineEntry`

Introduce a synthetic `TimelineEntry` subtype wrapping the pair; data source stays
`CalendarDataSource<TimelineEntry>`.

**Pros:**
- Smallest diff to the data source and to the `calendar*For` helpers (just one new
  `switch` arm each).
- `_onTap` keeps its current shape.

**Cons:**
- `TimelineEntry` is a *model* type (`lib/models/timeline_entry.dart`) with a single
  `date`; a replacement is inherently two events and a UI grouping, not a model
  entity — polluting the model layer with a view concept.
- Diverges from SetupList, which represents replacements as `ReplacementRow` (a
  view/row type). Two different representations of the same concept re-introduces
  the drift A-options try to kill.
- Doesn't generalize: setup groups are already `SetupGroupRow`, not entries, so a
  future port would still need the row path anyway.

---

## C. Flag scope: which groupings does the calendar honor?

### C1 — Replacement only for now; setup-grouping stays list-only (recommended)

Calendar honors `enableTimelineReplacementDetection`. It does **not** collapse
setup groups (pass `enableTimelineSetupGrouping: false` to the engine, or filter
`SetupGroupRow` back into its members).

**Pros:**
- Matches the explicit ask ("Replacement-Detection to start with").
- Setup groups on a time-grid are questionable UX (several setups minutes apart
  render fine as separate appointments); deferring avoids designing a calendar
  group affordance now.
- Framework (A1/A3 + B1) still lets us flip setup grouping on later by one flag.

**Cons:**
- Calendar and list momentarily honor *different* subsets of the timeline flags —
  a small inconsistency to document.

### C2 — Honor replacement + setup grouping together

Calendar collapses everything the engine collapses.

**Pros:**
- Full parity with SetupList; one mental model for the user.

**Cons:**
- Needs a calendar UX for a multi-setup appointment (subject, tap target → which
  setup? a group sheet?) that doesn't exist yet — scope creep beyond "start with
  replacement".

---

## D. Interaction: tap + drag for a grouped appointment

### D1 — Tap opens the replacement sheet; grouped rows are **not** draggable (recommended)

`_onTap`: `SingleEntryRow` → existing per-entry dispatch; `ReplacementRow` →
`showReplacementSheet(context, removed: row.removed, installed: row.installed)`.
`_onDragEnd`: single entries behave as today; a `ReplacementRow` drag is rejected
with a "can't move a replacement" SnackBar and a `setState` snap-back (mirrors the
existing read-only-Strava rejection).

**Pros:**
- Reuses the exact SetupList tap behavior and the existing drag-rejection pattern —
  no new interaction primitives.
- A replacement is two timestamps; dragging one appointment can't sensibly move
  both, so refusing is the honest behavior.

**Cons:**
- Slight asymmetry: the two installations *are* individually draggable when
  detection is off; turning the flag on removes that. Acceptable and reversible.

### D2 — Allow dragging a replacement (moves both installations by the same delta)

**Pros:**
- Preserves drag for those events even when grouped.

**Cons:**
- Two `editComponent` writes + a combined undo; edge cases if the two halves are on
  different components/bikes. Meaningfully more logic for a marginal gain — defer.

---

## E. Rendering: icon / colour / subject / span for a grouped appointment

### E1 — Add row-aware `calendar*For(EntryRow)` wrappers over the entry helpers (recommended)

New thin dispatchers: `SingleEntryRow` → existing `calendar*For(entry)`;
`ReplacementRow` → `Icons.swap_horiz`, `cs.secondary` (matches
`ReplacementListTile`'s installation vocabulary), subject `"Replaced <type>"`.
Duration spans earlier→later installation.

**Pros:**
- Keeps the existing entry helpers untouched; grouped rendering is additive and
  visually consistent with `ReplacementListTile` (`swap_horiz`, secondary colour).
- Exhaustive `switch` on the row type = compile-time safety for future row kinds.

**Cons:**
- One more small indirection layer (five wrapper switches). Low cost, high clarity.

### E2 — Custom `appointmentBuilder` branch that renders both component names inline

**Pros:**
- Richer at-a-glance detail (old → new) directly on the appointment.

**Cons:**
- Calendar appointments are often icon-only / very narrow (`_appointmentBuilder`
  already degrades label→icon by width); a two-line swap won't fit. Over-design for
  the space. The sheet already shows full detail on tap.

---

## Recommended combination

**A1 + A3 · B1 · C1 · D1 · E1.**

- **A3 then A1:** extract the grouping core out of `buildTimelineRows` so the
  calendar consumes grouped `EntryRow`s without the list-only strava-context / day-
  header passes, while SetupList keeps its current behavior. This is the "framework"
  spine — one grouping source of truth, new group types are one flag away.
- **B1:** widen `_TimelineDataSource` to `EntryRow`; anchor start via
  `anchorDateLocal`, span replacements earlier→later. Sealed-type exhaustiveness
  keeps future additions honest.
- **C1:** ship replacement detection only, gated by the existing
  `enableTimelineReplacementDetection`; setup grouping stays list-only for now.
- **D1:** tap → `showReplacementSheet` (identical to SetupList); grouped rows reject
  drags via the existing snap-back pattern.
- **E1:** additive row-aware render wrappers, styled like `ReplacementListTile`.

**Strava safety:** grouping is inserted strictly *between* `_buildEntries` and the
data source. `_ensureStravaCoverage`, `_buildEntries`, `hasMoreStrava`, and paging
are untouched — a half-loaded pair simply stays two single appointments until the
other half loads (same graceful degradation the list's horizon filter yields).

Phasing: **Phase 1** = A3 refactor + existing timeline tests still green. **Phase 2**
= B1 + E1 + D1 wired into the calendar behind C1's flag. **Phase 3 (later)** = flip
C2 / D2 if setup groups on the grid prove desirable.

## Open questions for the final plan

1. **A1 vs. A3:** accept the small refactor of `buildTimelineRows` (A3, cleaner) or
   just call it and discard day-header/strava-context output (A1-only, faster)?
2. **Setup grouping (C):** confirm calendar honors *only* replacement for now, or do
   you also want setup groups collapsed on the grid?
3. **Drag (D):** OK to make replacements non-draggable (snap-back), accepting that
   the two installs lose individual drag while the flag is on?
4. **Replacement colour/icon (E):** `swap_horiz` + `cs.secondary` to match
   `ReplacementListTile`, or a distinct calendar colour so replacements stand out
   from plain installations (currently also `cs.secondary`)?
5. Should a replacement appointment's **span** be earlier→later installation (a
   visible bar when they're minutes apart) or a fixed `kCalendarZeroDuration` dot
   like other point events?
