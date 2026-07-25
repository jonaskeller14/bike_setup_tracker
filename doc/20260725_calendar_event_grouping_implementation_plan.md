# Calendar event grouping — implementation plan

**Date:** 2026-07-25
**Status:** Approved concept → phased implementation plan
**Concept doc:** `doc/20260724_calendar_event_grouping_concept.md`

Locked decisions: **A3** (extract a shared grouping core out of
`buildTimelineRows` returning `List<EntryRow>`; the list function keeps layering
strava-context + day headers on top, its behavior held constant) + **B1** (widen
the calendar data source to `CalendarDataSource<EntryRow>`, appointment start =
`anchorDateLocal`) + **C1** (calendar honors only
`enableTimelineReplacementDetection`; no setup grouping, but dispatch is sealed-
type based so setups/tasks can be flipped on later) + **D** (tap replacement →
`showReplacementSheet`; drag sets an *identical* new date/time to both halves;
drag rejected — snap-back — if it would produce an invalid installation timeline,
same guard applied to single installation drags; validity extracted into one
reusable pure function shared with the widget validator) + **E1** (row-aware
`calendar*For(EntryRow)` wrappers; `ReplacementRow` reuses the installation
icon+colour `cs.secondary`, subject `"Replaced <type>"`).

No new feature flag — this reuses the existing `enableTimelineReplacementDetection`
`AppSettings` flag that already gates replacement detection in SetupList.

---

## Resolved open questions

### No setup grouping in the calendar for now
Only replacement rows are collapsed. The shared core still *produces*
`SetupGroupRow`s when `enableTimelineSetupGrouping` is on, but the calendar call
passes setup grouping **off** so the calendar never sees them in v1. Turning it
on later is a one-argument change plus a tap/render arm — the sealed dispatch
makes that a compile-time-checked addition, not a rewrite.

### Replacement colour = installation colour (`cs.secondary`)
A replacement *is* an installation event (two of them), so it shares the
installation vocabulary already used by `ReplacementListTile` (`Icons.swap_horiz`
is the list glyph; on the calendar the colour is what carries meaning at small
sizes, and it matches `calendarColorFor(InstallationEntry)` = `cs.secondary`).

### Replacement appointment span → earlier→later installation
`getStartTime` = `row.anchorDateLocal` (the earlier of the two events), `getEndTime`
= the later installation's local time. When both halves share a timestamp (e.g.
after a drag sets them identical) the span collapses to `kCalendarZeroDuration`
so a dot still renders. This mirrors how `StravaEntry` already gets a real span
while point events fall back to `kCalendarZeroDuration`.

### Drag semantics for a replacement
Both halves move to the **same** dropped date/time (no offset). Because
`pairReplacements` guarantees the two halves are on **different components**
(`candidate.component.id != removed.component.id`), the move is two independent
`editComponent` writes, each validated against the shared timeline-validity
function. If either component's resulting timeline is invalid, the whole drag is
rejected and snapped back (no partial write). Undo restores both components.

---

## Feature flag

Reuses existing `AppSettings.enableTimelineReplacementDetection`. No new flag, no
migration. The calendar simply starts honoring a flag it previously ignored.

---

## Phase 1 — Extract installation-timeline validity into a shared pure function

**Status:** ✅ Complete — `validateInstallationTimeline` / `isValidInstallationTimeline` live in `lib/utils/installation_timeline_validation.dart` (sorts a copy internally); the sheet's FormField validator now delegates to it, covered by `test/utils/installation_timeline_validation_test.dart`.

Pull the ordering rules out of the `set_installation_timeline.dart` FormField
validator into one reusable function, so both the widget and the calendar drag
guard share a single definition of "valid timeline".

**Files:**
- `lib/utils/installation_timeline_validation.dart` *(new)*
- `lib/widgets/set_installation_timeline.dart` *(edit — call the extracted fn)*
- `test/utils/installation_timeline_validation_test.dart` *(new)*

**Steps:**
- [ ] Create `installation_timeline_validation.dart` with a pure function
      `String? validateInstallationTimeline(List<Installation> installations)`
      returning the same error strings as today (null = valid). It must **sort a
      copy** by `dateTimeUTC` before checking (the widget currently relies on its
      list already being sorted; the calendar guard will pass an unsorted list).
      Rules, in order: ≥1 entry; `Archival` only as the last entry; no consecutive
      `Uninstallation`s; no consecutive `BikeInstallation`s on the same bike; at
      most one from-beginning (`dateTimeUTC.millisecondsSinceEpoch == 0`) entry.
- [ ] Add a thin `bool isValidInstallationTimeline(List<Installation>)` =>
      `validateInstallationTimeline(list) == null` for call sites that only need a
      bool (the drag guard).
- [ ] In `set_installation_timeline.dart`, replace the inline validator body with
      `validator: (value) => validateInstallationTimeline(_installations)`. Keep
      the `_installations` list sorted as it is today (the function sorts a copy,
      so behavior is identical). Do not touch any other logic in the widget.

**Verification:**
- [ ] New unit test covers: empty list; single entry; archival-last OK vs.
      archival-not-last error; consecutive uninstallations error; consecutive
      same-bike installations error vs. different-bike OK; two from-beginning
      error; a valid mixed timeline returns null; **unsorted input** is validated
      correctly (proves the internal sort).
- [ ] `flutter test test/utils/installation_timeline_validation_test.dart`
- [ ] `flutter analyze` clean on the two touched files.
- [ ] Manual: open the installation sheet, reproduce each error (e.g. two
      uninstalls) — the same error text still appears under the timeline.

**Commit:** `refactor(installation): extract installation-timeline validity into a shared fn`

---

## Phase 2 — Shared grouping core (`collapseIntoRows`) reused by `buildTimelineRows`

**Status:** ✅ Complete — `collapseIntoRows` in `lib/utils/timeline_grouping.dart` now holds the replacement/setup-group/single collapsing; `buildTimelineRows` delegates to it and recomputes the per-row containing activity (via `_rowActivity`) for its unchanged strava-context and day-header passes.

Refactor `buildTimelineRows` so its grouping body (replacement pairing + setup-
group collapsing → `List<EntryRow>`) is a standalone function the calendar can
call directly, without the list-only strava-context reordering and day-header
passes.

**Files:**
- `lib/utils/timeline_grouping.dart` *(edit — extract + delegate)*
- `test/utils/timeline_grouping_test.dart` *(edit/extend if present, else new)*

**Steps:**
- [x] Add `List<EntryRow> collapseIntoRows(List<TimelineEntry> sortedEntries, {required AppSettings appSettings})`
      containing exactly the current base-row construction loop from
      `buildTimelineRows` (the `while (i < sortedEntries.length)` block that emits
      `ReplacementRow` / `SetupGroupRow` / `SingleEntryRow`). It must keep using
      `pairReplacements` (gated by `enableTimelineReplacementDetection`) and setup
      grouping (gated by `enableTimelineSetupGrouping`). It must **not** set
      `stravaContext` or emit `DayHeaderRow`s.
- [x] Note the coupling: the current base loop also fills `duringActivity` and
      later uses it for the strava-context pass. Keep that pass **inside**
      `buildTimelineRows`: have `collapseIntoRows` return only the rows; let
      `buildTimelineRows` recompute the per-row containing activity via the
      existing `contextOf`/`containingStravaActivity` helpers when
      `enableTimelineStravaContext` is on (it already calls these). This keeps the
      strava-context + day-header layering identical for SetupList.
- [x] Rewrite `buildTimelineRows` to: `final rows = collapseIntoRows(sortedEntries, appSettings: appSettings);`
      then run the unchanged strava-context reordering/annotation and day-header
      passes on `rows`. Confirm output is byte-for-byte equivalent to before for
      every flag combination.

**Verification:**
- [x] Extend timeline-grouping tests to call `collapseIntoRows` directly and
      assert: replacement pair collapses to one `ReplacementRow` at the earlier
      slot with the other half consumed; setup run collapses to `SetupGroupRow`;
      flags off → all `SingleEntryRow`; **no `DayHeaderRow` and no `stravaContext`**
      ever appear in its output.
- [x] Add/keep a `buildTimelineRows` regression test asserting SetupList-facing
      output is unchanged (day headers present when flag on, strava-context
      annotated when flag on, replacement/group collapsing intact).
- [x] `flutter test test/utils/timeline_grouping_test.dart`
- [x] `flutter analyze` clean.

**Commit:** `refactor(timeline): extract collapseIntoRows core shared by list + calendar`

---

## Phase 3 — Calendar consumes grouped rows (render only, no interaction change)

**Status:** ✅ Complete — the calendar builds `collapseIntoRows` rows (setup groups expanded back to singles), `_TimelineDataSource` is a `CalendarDataSource<EntryRow>` anchored on `anchorDateLocal`, and `calendar*ForRow` dispatchers render replacements as one `cs.secondary` appointment; tap/drag still unwrap `SingleEntryRow` only.

Insert grouping between `_buildEntries` and the data source, widen the data
source to `EntryRow`, and add row-aware render helpers. Tap/drag still operate
per-entry via unwrapping `SingleEntryRow`; replacement tap/drag handled in
Phase 4. **Strava coverage code untouched.**

**Files:**
- `lib/pages/calendar_page.dart` *(edit)*

**Steps:**
- [ ] After `_buildEntries(...)` in `build`, produce grouped rows:
      sort a copy of the entries by `date` (UTC), then
      `collapseIntoRows(sortedEntries, appSettings: appSettings)`. **Pass setup
      grouping off for the calendar** — either call with a settings view where
      `enableTimelineSetupGrouping` is treated as false, or (simpler) after
      collapsing, expand any `SetupGroupRow` back into per-setup `SingleEntryRow`s
      so v1 shows setups individually. Pick the expand-back approach to avoid
      threading an override into the shared fn; leave a one-line comment on why.
- [ ] Add row-aware dispatchers next to the existing entry helpers:
      `calendarIconFor(EntryRow)`, `calendarColorFor(EntryRow, cs)`,
      `calendarOnColorFor(EntryRow, cs)`, `calendarSubjectFor(EntryRow)`. For
      `SingleEntryRow` delegate to the existing `*(entry)` helpers; for
      `ReplacementRow` return `Icons.swap_horiz` / `cs.secondary` / `cs.onSecondary`
      / `"Replaced ${row.removed.component.componentType.label}"`. Include a
      `SetupGroupRow` arm (defensive, even though expanded away) so the switch is
      exhaustive over the sealed `EntryRow` type.
- [ ] Change `_TimelineDataSource` to `extends CalendarDataSource<EntryRow>`:
      `getStartTime` = `row.anchorDateLocal`; `getEndTime` = for
      `SingleEntryRow(StravaEntry)` the existing elapsed-time span, for
      `ReplacementRow` the later installation's local time (clamp to
      `anchorDateLocal + kCalendarZeroDuration` when equal), else
      `anchorDateLocal + kCalendarZeroDuration`; `getSubject`/`getColor` via the
      new row helpers; `convertAppointmentToObject` returns the same row.
- [ ] Update `_appointmentBuilder` and `_onTap`/`_onDragEnd` signatures to receive
      `EntryRow` (cast `details.appointments.first`); for this phase, in
      `_onTap`/`_onDragEnd` handle only `SingleEntryRow` by unwrapping `.entry`
      into the **existing** per-entry switch (extract the current body into a
      helper taking a `TimelineEntry`), and no-op (Phase 4 fills replacement).
- [ ] **Do not touch** `_buildEntries`, `_ensureStravaCoverage`, `hasMoreStrava`,
      `onViewChanged`, or `_visibleDates`. Grouping happens strictly on the built
      entry list.

**Verification:**
- [ ] `flutter analyze` clean (exhaustive switch over `EntryRow` compiles).
- [ ] Manual, replacement flag **on**: a replacement shows as **one** appointment
      (secondary colour) spanning earlier→later; the two installation appointments
      no longer appear separately. Flag **off**: two separate installation
      appointments (unchanged from today).
- [ ] Manual: scroll back past the loaded Strava window — older activities still
      page in exactly as before (coverage untouched); month/week/day/schedule/3-day
      all render; long component names ellipsize in narrow columns.
- [ ] Manual: existing single-entry tap (setup/strava/task/installation/rating)
      still opens the correct sheet; single installation drag still moves it.

**Commit:** `feat(calendar): render grouped replacement events behind existing flag`

---

## Phase 4 — Replacement tap + guarded drag (identical-date, validity-checked)

**Status:** ✅ Complete — tap opens `showReplacementSheet`; dragging a replacement
re-dates both halves to one identical timestamp (both timelines validated before
either write, undo restores both components); the same
`isValidInstallationTimeline` guard now rejects invalid single-installation drags
via a shared `_rejectMove` snap-back.

Wire the replacement interactions: tap opens the shared sheet; drag moves both
halves to one identical date, guarded by the Phase 1 validity function, with the
same guard applied to single-installation drags.

**Files:**
- `lib/pages/calendar_page.dart` *(edit)*

**Steps:**
- [ ] `_onTap`, `ReplacementRow` arm →
      `await showReplacementSheet(context, removed: row.removed, installed: row.installed);`
      (mirrors `setup_list.dart`). Add the `showReplacementSheet` import.
- [ ] `_onDragEnd`: add a `ReplacementRow` arm. Compute `newLocal`/`newUtc` from
      `details.droppingTime`; build `newRemovedInstallation` and
      `newInstalledInstallation` as `copyWith(dateTimeUTC: newUtc, dateTimeLocal: newLocal)`
      — **identical** date for both. For each of the two (distinct) components,
      build the updated installations list (replace the moved installation by
      identity) and validate with `isValidInstallationTimeline(updated)`.
- [ ] If **either** component's updated timeline is invalid → reject: show the
      existing error-style SnackBar (reuse the Strava-rejection SnackBar pattern
      with a message like "Can't move this replacement there.") and `setState(() {})`
      to snap back. **No write.**
- [ ] If both valid → `await appRepository.editComponent(removedComponent.copyWith(installations: ...))`
      then the installed component likewise; show the move-undo SnackBar whose UNDO
      restores **both** original components (`editComponent(removedOriginal)` +
      `editComponent(installedOriginal)`).
- [ ] Apply the **same guard to the single `InstallationEntry` drag** (currently in
      `_onDragEnd`): before persisting, validate the updated installations list;
      on invalid, reject with the error SnackBar + snap-back instead of writing.
- [ ] Guard `context`/`mounted` across every `await` (matches existing arms).

**Verification:**
- [ ] `flutter analyze` clean.
- [ ] Manual: tap a replacement appointment → the replacement sheet opens (same as
      SetupList). Drag it to a new day → both installation dates update to the same
      new datetime; reopening the sheet/timeline confirms identical timestamps.
- [ ] Manual (guard, replacement): drag a replacement so one component would get
      two consecutive uninstalls / a non-last archival → move is rejected, snaps
      back, error SnackBar shown, nothing persisted.
- [ ] Manual (guard, single installation): drag a lone installation into an
      invalid position (e.g. adjacent to another uninstall) → rejected + snap-back;
      a valid move still works and shows the undo SnackBar.
- [ ] Manual: UNDO on a replacement move restores both components' original dates.

**Commit:** `feat(calendar): tap opens replacement sheet, drag moves both halves with validity guard`

---

## Suggested commit granularity

Four commits, one per phase, each independently mergeable and verifiable:

1. `refactor(installation): extract installation-timeline validity into a shared fn` — pure logic + tests, no behavior change.
2. `refactor(timeline): extract collapseIntoRows core shared by list + calendar` — pure refactor, SetupList output unchanged.
3. `feat(calendar): render grouped replacement events behind existing flag` — visible grouping, interactions still per-entry.
4. `feat(calendar): tap opens replacement sheet, drag moves both halves with validity guard` — completes the feature.

Phases 1 and 2 are independent (either order); 3 depends on 2; 4 depends on 1 + 3.
Each phase fits a single fresh context window — run `/handoff doc/20260725_calendar_event_grouping_implementation_plan.md <phase>` to execute one.
