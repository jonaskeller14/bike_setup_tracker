# Displaying Strava `workoutType` — Design Options

> **Status (2026-07-03):** Brainstorm only. `StravaActivity.workoutType` is
> already synced & persisted ([strava_activity.dart:22](../lib/models/strava/strava_activity.dart#L22)).
> This doc proposes ways to surface it in four widgets. **Pick one approach to
> implement.** Nothing here is built yet.

## What `workoutType` is

Strava's `workout_type` is a nullable `int` whose meaning depends on the sport
(`Run` vs `Ride`). The relevant values:

| Raw value | Meaning | Applies to |
|---|---|---|
| `null`, `0`, `10` | **Default / None** (a normal ride/run) | all |
| `1` | Race | Run |
| `2` | Long Run | Run |
| `3` | Workout | Run |
| `11` | Race | Ride |
| `12` | Workout | Ride |

**Key UX consequence:** the vast majority of activities are "None". Whatever we
build should render **nothing** (or an invisible placeholder) for None, and only
decorate the interesting cases — **Race**, **Workout**, **Long Run**. Treating
None as a first-class badge would clutter every list/marker/event for no signal.

---

## Step 0 (shared foundation — needed by every approach)

Right now `workoutType` is a bare `int?` with a comment. Every option below is
cleaner if we first give it a semantic layer, mirroring the existing
`SportType` enum ([strava_sportType.dart](../lib/models/strava/strava_sportType.dart)).

Proposed helper (e.g. `lib/models/strava/strava_workout_type.dart`, a new
`part of 'strava_activity.dart'`):

```dart
enum StravaWorkoutType {
  none,
  race,
  longRun,
  workout;

  /// Maps the raw Strava int (sport-dependent) to a semantic type.
  static StravaWorkoutType fromRaw(int? raw) => switch (raw) {
        1 || 11 => StravaWorkoutType.race,
        2 => StravaWorkoutType.longRun,
        3 || 12 => StravaWorkoutType.workout,
        _ => StravaWorkoutType.none, // null, 0, 10, anything else
      };

  bool get isNotable => this != StravaWorkoutType.none;

  String get label => switch (this) {
        StravaWorkoutType.none => 'Activity',
        StravaWorkoutType.race => 'Race',
        StravaWorkoutType.longRun => 'Long Run',
        StravaWorkoutType.workout => 'Workout',
      };

  IconData get icon => switch (this) {
        StravaWorkoutType.none => Icons.circle_outlined,
        StravaWorkoutType.race => Icons.emoji_events,   // trophy
        StravaWorkoutType.longRun => Icons.timeline,
        StravaWorkoutType.workout => Icons.fitness_center,
      };

  /// Only used by color-forward approaches (C). None returns null so callers
  /// fall back to the Strava brand orange.
  Color? get accent => switch (this) {
        StravaWorkoutType.none => null,
        StravaWorkoutType.race => const Color(0xFFD32F2F),   // red
        StravaWorkoutType.longRun => const Color(0xFF00897B),// teal
        StravaWorkoutType.workout => const Color(0xFF5E35B1),// deep purple
      };
}

// on StravaActivity:
StravaWorkoutType get workout => StravaWorkoutType.fromRaw(workoutType);
```

Icon/label/color are just defaults — swap freely. `Icons.sports_score`
(checkered flag) is a good alt for Race; `Icons.bolt` for Workout.

Everything below assumes this helper exists and refers to `activity.workout`.

---

## The four approaches

Each approach is a **coherent visual language** applied across all four widgets,
so "choose one" gives you a consistent result everywhere. Per-widget notes call
out where the treatment bends to fit tight space (map markers, calendar cells).

### Approach A — Text label (inline, lowest effort)

Append the workout type to the **existing sport-type text** so it reads as one
line. No new rows, no new colors.

- **List tile** ([strava_list_tile.dart:73](../lib/widgets/items/strava_list_tile.dart#L73)):
  `Mountain Bike Ride · Race` — change the sport `Text` to
  `"${sportType.label}${w.isNotable ? " · ${w.label}" : ""}"`.
- **Details page** ([strava_activitiy_details_page.dart:165](../lib/pages/details/strava_activitiy_details_page.dart#L165)):
  same concatenation on the sport-type row under the title.
- **Map marker:** *no change possible without a label* — markers have no text.
  Text-only approach effectively skips the map (or falls back to A's sibling
  treatment: a tooltip on tap only, which users won't see). **This is A's main
  weakness.**
- **Calendar:** the subject already dominates the cell; optionally prefix the
  subject in `calendarSubjectFor` (`"Race — <name>"`), but cells are cramped so
  this often gets ellipsis'd away.

**Pros:** trivial, zero layout risk, localizable.
**Cons:** invisible on the map; weak/blink-and-miss on calendar; no at-a-glance
scanning (you must read the text).

---

### Approach B — Icon glyph (compact, scannable)

Attach a **single small icon** (`activity.workout.icon`) next to the existing
sport-type icon, shown only when `isNotable`. Monochrome, inherits
`onSurfaceVariant` — quiet but scannable.

- **List tile:** add one `Icon(w.icon, size: 12)` into the sport-type `Row`
  (line 67–81), guarded by `if (w.isNotable)`.
- **Details page:** add the icon before/after the sport label on the row at
  line 157–173.
- **Map marker:** overlay a tiny glyph on the pin via `Positioned` inside the
  existing `Stack` (map_page.dart:186) — e.g. a 14px white-circle badge with the
  workout icon at the pin's top-right. Only rendered for `isNotable`.
- **Calendar:** in `_appointmentBuilder` ([calendar_page.dart:600](../lib/pages/calendar_page.dart#L600))
  **swap** the leading `SimpleIcons.strava` glyph for `w.icon` when notable
  (keeps the single-icon layout the builder already carefully space-budgets),
  or append a second tiny icon before the text when `showText && width` allows.

**Pros:** works in *all four* surfaces including the map; respects the calendar's
existing icon-only fallback; no color decisions.
**Cons:** an unlabelled icon is a learned symbol (trophy = race is guessable,
dumbbell = workout less so); tiny map badge adds a little marker complexity.

---

### Approach C — Color accent (strongest at-a-glance, most invasive)

Encode the type with **color**: Race red, Workout purple, Long Run teal, None =
existing Strava orange. Best "pops from across the room" signal, but touches the
map's brand-color convention, so use sparingly.

- **List tile:** a thin colored leading bar or a colored dot before the sport
  row, or tint the sport-type text/icon with `w.accent ?? onSurfaceVariant`.
- **Details page:** a filled color chip (icon + label) on the sport row — the
  most prominent spot, where color reads best.
- **Map marker:** recolor the pin `w.accent ?? const Color(0xFFFC5200)`. Races
  become red pins, etc. **Caveat:** the map already color-codes by *entity type*
  (orange = Strava, amber = rating, primary = setup — map_page.dart:19,196,227).
  Recoloring Strava pins by workout type breaks "orange = Strava". Safer variant:
  keep the pin orange and add a small **colored ring/badge** (a blend of B + C).
- **Calendar:** the appointment container color comes from `calendarColorFor`
  (calendar_page.dart:41). Overriding Strava's orange per-workout-type is
  possible but, again, collides with the "color = entry type" scheme used across
  calendar + map. Safer: keep orange, add a colored left stripe inside the
  container.

**Pros:** highest glanceability; great on the details page.
**Cons:** fights the existing entity-type color scheme on map & calendar;
accessibility (color-only encoding) — should pair with an icon anyway; most code
churn and the most review-sensitive change.

---

### Approach D — Chip / pill (explicit, labelled badge)

A small rounded **pill** = `icon + label` (e.g. a red-tinted "🏆 Race" chip),
shown only when notable. The most self-explanatory option — combines B's icon
with A's text in a contained badge.

- **List tile:** drop the pill into the existing `Wrap` at line 28 (it already
  wraps date/time chips), so it flows naturally on the same row.
- **Details page:** a `Chip`/container beside the sport-type row — reads as a
  proper tag under the activity title (arguably the nicest home for a pill).
- **Map marker:** a pill doesn't fit a 40px marker. Degrade to B here (icon
  badge on the pin) — the pill only lives in list/details/calendar. This
  **inconsistency across surfaces** is D's cost.
- **Calendar:** only feasible in tall cells (day/week view); in month/indicator
  mode there's no room, so it degrades to B (icon swap). The builder already
  branches on available width/height, so this fits its existing logic.

**Pros:** most legible and self-describing; looks polished in list & details.
**Cons:** doesn't fit the map or dense calendar cells, so it can't be *fully*
consistent — it becomes "pill where there's room, icon where there isn't"
(really D-in-roomy-places + B-elsewhere).

---

## Side-by-side

| | List tile | Details | Map marker | Calendar | Effort | Glanceability | Consistency |
|---|---|---|---|---|---|---|---|
| **A** Text | ✅ inline | ✅ inline | ❌ none | ⚠️ weak | ★ | ★ | map gap |
| **B** Icon | ✅ | ✅ | ✅ badge | ✅ icon swap | ★★ | ★★ | ✅ all four |
| **C** Color | ✅ | ✅ chip | ⚠️ breaks scheme | ⚠️ breaks scheme | ★★★ | ★★★ | ⚠️ collides |
| **D** Pill | ✅ | ✅ | ❌→B | ⚠️→B | ★★ | ★★★ | mixed |

---

## Recommendation

**Approach B (icon glyph)** is the best all-rounder: it's the only option that
lands cleanly and *consistently* in all four surfaces — including the map and the
space-budgeted calendar builder — without disturbing the existing entity-type
color conventions. It's low-risk and cheap.

If you want more punch on the **details page and list** specifically (where space
is generous) while staying safe on map/calendar, go **B as the baseline + a pill
(D) only in list & details**. That's a small, principled extension rather than a
different design.

Avoid making **C** the map/calendar treatment unless you're deliberately willing
to rethink the "color = entry type" scheme those two views share.

**Suggested pick order:** B → (B+D) → C.
