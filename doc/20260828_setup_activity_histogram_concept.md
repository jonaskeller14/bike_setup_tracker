# Setup activity counts and adjustment histograms — concept brainstorming

**Status:** Decisions complete — ready for `/plan`.

Goal: show how many Strava activities relate to each setup in the component-details
table, then summarize those counts by adjustment value in the tooltip opened from
`AdjustmentIconNameNotes`. The result must use the complete local Strava history,
remain correct when setups or activities change, and keep tooltip opening responsive.

Relevant constraints found in the current code:

- `strava_activitiy_details_page.dart` associates an activity with the setup active
  at activity start plus every setup created before the activity ends. One activity
  can therefore relate to more than one setup.
- `AppRepository.stravaActivities` is only the currently paginated/filtered activity
  window. It cannot be the source for a complete count.
- `StravaDao` already owns full-history aggregate queries and activity-count logic.
- `AdjustmentIconNameNotes` is shared by display, comparison, and edit widgets; it
  currently knows only the `Adjustment`, not a component or setup scope.
- `fl_chart` 1.2.0 is already a direct dependency.

## A. Setup-to-activity matching

### A1 — Interval overlap, matching the activity-details behavior (recommended)

Treat a setup as active from its timestamp until the next setup for the same bike.
An activity belongs to a setup when its time interval overlaps that setup interval.
Use half-open boundaries so an activity ending exactly when a setup is created does
not count for the new setup.

**Pros:**

- Inverts the existing activity-details rule cleanly: the setup active at the start
  and setups changed during the activity all receive that activity.
- Handles mid-activity setup changes without special cases.
- Can be expressed and tested independently of UI filters.

**Cons:**

- Counts are not additive across setups because one activity may count more than once.
- Requires an explicit boundary decision for equal timestamps.

**Decision:** Selected. An activity counts for the setup active at activity start
and for every setup recorded during the activity. The interval calculation must use
**all non-deleted setups for the bike** to determine setup boundaries. UI setup/tag
filters affect only which rows are displayed; they must never affect attribution.

### A2 — Attribute each activity only to the setup active at activity start

Find the newest setup at or before the activity start and count the activity once.

**Pros:**

- Counts are mutually exclusive and add up to the bike's activity count.
- Simpler mental model and query.

**Cons:**

- Does not match the referenced activity-details page for mid-activity changes.
- A setup created during a ride receives no evidence from that ride.

### A3 — Attribute each activity only to the setup active at activity end

Find the newest setup at or before the activity end and count the activity once.

**Pros:**

- The final setup used during a tuning ride receives the ride.
- Counts remain mutually exclusive.

**Cons:**

- Does not match current activity-details behavior.
- Discards earlier setups used for most of a ride.

## B. Calculation and caching

### B1 — One full-history DAO query, cached only for the current UI state (recommended)

Add a DAO-level bulk calculation returning setup IDs and counts. The component page
loads it once for all visible setups. A tooltip starts or reuses the same kind of
future and shows a small progress indicator while it resolves. Keep the result only
in widget/repository memory and invalidate it when setup, bike-link, installation, or
Strava activity data changes.

**Pros:**

- Reads the full local activity table rather than the paginated repository window.
- One query avoids an N+1 query per setup.
- No schema migration and no stale persisted derived data.
- The local SQLite query should normally complete quickly; the loading state covers
  large histories and cold reads.

**Cons:**

- Needs a clear invalidation signal if the future is memoized above widget scope.
- The query and interval-boundary tests are non-trivial.

**Decision:** Selected. Both the input setup timeline and activities come from the
full database. The component page may project the resulting `setupId -> count` map
onto its filtered rows only after the complete calculation has finished.

### B2 — Recalculate independently every time a tooltip opens

Run the full DAO query on every tooltip trigger and do not retain its result.

**Pros:**

- Always fresh and has no invalidation logic.
- Smallest cache-related implementation surface.

**Cons:**

- Repeated taps repeat identical database work.
- The table and tooltip cannot naturally share work.

### B3 — Persist counts or setup/activity links in Drift

Store a materialized count or explicit join rows and update them during setup edits and
Strava synchronization.

**Pros:**

- Fastest reads after the cache has been maintained.
- Explicit links could support future activity drill-down features.

**Cons:**

- Requires a migration, backfill, and invalidation for edits, imports, gear relinking,
  activity deletion, and Strava resync.
- Duplicates data that SQLite can derive from the existing timestamps.
- Much higher correctness risk for a relatively cheap aggregate.

## C. Histogram meaning

### C1 — Activity-weighted bars by exact adjustment value (recommended)

Group setups by the selected adjustment's formatted value and sum their activity
counts. For step, boolean, categorical, and other discrete adjustments, one bar means
one exact value. For numerical/sag/duration values, initially use exact values and
introduce numeric binning only when the number of distinct values exceeds a threshold.

**Pros:**

- Directly answers “how many activities were ridden with this value?”
- Preserves exact click/pressure values where exactness is useful.
- Works naturally as an `fl_chart` bar chart.

**Cons:**

- Continuous data may require bins to stay readable.
- If A1 is chosen, a mid-ride change can contribute one activity to multiple bars.

**Decision:** Selected. A multi-select categorical setup contributes its full
activity count independently to every selected category.

### C2 — Number of setups by adjustment value

Each setup contributes one, regardless of its activity count.

**Pros:**

- Conventional frequency histogram.
- Simple and unaffected by duplicated activity attribution.

**Cons:**

- Does not use the requested setup activity count.
- Overweights experimental setups that were never ridden.

### C3 — Two series: setup count and activity count

Show grouped bars for both the number of setups and summed activities per value.

**Pros:**

- Reveals both experimentation frequency and real-world usage.
- Makes zero-activity setups visible.

**Cons:**

- Too dense for the current compact tooltip.
- Needs a legend and more explanatory UI.

## D. Tooltip scope and loading behavior

### D1 — Opt-in histogram data for `AdjustmentIconNameNotes` (recommended)

Keep the shared widget generic. Add an optional analysis input/provider; only callers
with a meaningful component/setup scope enable the histogram. While its future is
pending, show a compact `CircularProgressIndicator`; on empty/error, show a concise
message without hiding the existing adjustment properties and notes.

**Pros:**

- Avoids database work in every setup form, comparison row, and display widget.
- Makes the component/history scope explicit and testable.
- Preserves all current call sites by default.

**Cons:**

- The desired caller(s) must pass the scope or prepared future down.
- Histogram availability may differ between screens.

**Decision:** Selected, with the analysis provider made available to every current
`AdjustmentIconNameNotes` context. The shared widget remains decoupled from
`AppRepository`/Drift: it asks an injected lazy analysis provider by adjustment ID,
and starts work only when its tooltip is triggered. Thus the histogram is available
everywhere the widget is used without putting database logic directly in the widget.

When no setups contain the adjustment, omit the histogram section entirely—no empty
placeholder. The same applies when the analysis produces no activity-weighted bars.

## E. Strava availability gate

### E1 — Show only when the full local database contains an activity (recommended)

Expose a cheap DAO/repository-level `hasAnyActivity` signal and use it to decide whether
to add the table column or histogram analysis. Do not inspect the paginated
`AppRepository.stravaActivities` map.

**Pros:**

- Directly tests whether the feature can display useful data.
- Avoids coupling a read-only visualization to subscription UI state.
- In the current app, expired entitlement clears local Strava data, so this follows
  the effective entitlement lifecycle while also handling loading/restoration cleanly.

**Cons:**

- It is a data-presence gate rather than an explicit product/paywall rule.
- A future change that retains Strava data after expiry would change its semantics.

**Decision:** Selected provisionally from the stated “subscriber or any activity”
choice because it is simpler and avoids showing an empty feature to a new subscriber.

The “Activities” component-table column is active by default only while this gate is
open. When no activity exists, do not add the column to the available column set.

## F. Continuous-value binning

### F1 — Named static thresholds with an exact-value fast path (recommended)

Use exact bars while the histogram has at most a named maximum number of distinct
values. Above that limit, group values into a named fixed number of equal-width bins.
Define both tuning values as static constants owned by the histogram/grouping widget
or helper (initial recommendation: 12 exact values and 8 bins), rather than embedding
numeric literals in grouping code.

**Pros:**

- Keeps common pressure, SAG, and duration histories exact and readable.
- Prevents an unbounded number of narrow labels/bars.
- Both density choices can be tuned later in one place.

**Cons:**

- Equal-width bins can be sparse for strongly clustered data.
- The initial values still need visual verification on narrow screens.

**Decision:** Selected. Treat the initial values as implementation constants subject
to adjustment during visual testing, without changing the grouping contract.

### D2 — Make every `AdjustmentIconNameNotes` query globally by adjustment ID

Resolve the component and all setups from `AppRepository` inside the shared widget.

**Pros:**

- Histogram appears everywhere without changing callers.
- Minimal call-site plumbing.

**Cons:**

- Hides repository/database work inside a low-level presentation widget.
- Edit forms and comparison views trigger analysis with potentially ambiguous scope.
- Harder to test and more likely to rebuild or query unnecessarily.

## Recommended combination

Choose **A1 + B1 + C1 + D1 + E1 + F1**:

1. Define one tested interval-overlap matcher using UTC timestamps, all non-deleted
   setups (independent of current filters), and the full local Drift activity dataset.
2. Add one bulk DAO/repository analysis result, including `setupId -> activityCount`
   and enough setup adjustment data to group counts without per-row queries.
3. Load it asynchronously on the component-details page, expose “Activities” as a
   sortable optional general-context column, and reuse the loaded result for charts.
4. Render an activity-weighted `BarChart` through a lazy injected provider in every
   `AdjustmentIconNameNotes` tooltip. Use exact discrete values, bounded numeric bins
   when cardinality is high, and a compact loading indicator. Omit the chart entirely
   when no setups/bars exist; surface query errors without replacing existing tooltip
   content.
5. Gate the column and histogram on a full-database `hasAnyActivity` signal.
   Add “Activities” as an active-by-default table column only while that gate is open.
6. Keep the exact-value threshold and continuous bin count as named static constants
   (starting at 12 and 8 respectively) so visual tuning remains a local change.

This is dynamic calculation with a small ephemeral cache, not persisted caching. It
keeps derived data correct while avoiding repeated work during one screen session.

## Open questions for the final plan

None. All concept decisions required for planning have been made.
