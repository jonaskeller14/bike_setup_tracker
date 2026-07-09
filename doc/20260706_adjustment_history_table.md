# Adjustment History Table — Design Report

**Date:** 2026-07-06 (revised 2026-07-07 after follow-up discussion — see §4 onward)
**Status:** Brainstorm / evaluation only — no code changes yet
**Scope:** A new "Adjustment history" table on [BikeDetailsPage](lib/pages/details/bike_details_page.dart)
(columns = grouped adjustments, rows = setups), plus the modelling gap that motivated the question
(front/rear collision, the "installed on" hack). Feature #2 (sub-component nesting) turned out, after
review, to be the actual recommendation — see §6.
Cross-referenced to [20260627_component_archive_and_nesting.md](20260627_component_archive_and_nesting.md).

> **Revision note:** the first pass (§3, below) recommended a static `side` field on `Component`. Two
> follow-up points from the user broke that: (1) switching a tire from front to rear is a *dated event*,
> not a static attribute — a snapshot field retroactively mislabels history; (2) the same flaw already
> exists, unnoticed, in shipped code (`wheelFront`/`wheelRear`), because wheels get swapped between
> positions too. §4 onward supersedes the Option 3 recommendation. §3 is kept for the reasoning trail
> (why the naive fix fails), not as the current recommendation.

---

## 1. The ask

On [BikeDetailsPage](lib/pages/details/bike_details_page.dart), next to the new
[InstallationTimelineTable](lib/widgets/installation_timeline_table.dart) (`_installationOverview`,
line 23), add a second table: **columns = adjustments, rows = setups**, so a value like tire pressure
reads as one continuous history even though the physical tire gets replaced every month and each
replacement is a *different* `Component` with a *different* `Adjustment` underneath.

Two concrete edge cases came with it:

1. **Front/rear collision.** Grouping by `(componentType, adjustment.name)` — e.g. `(tire, "Pressure")`
   — merges the front tire and rear tire into one column, because both are `ComponentType.tire` with an
   adjustment literally named "Pressure".
2. **The "installed on" hack.** To distinguish them today, an extra `CategoricalAdjustment` ("installed
   on" = Front/Rear) was added to the tire component — a structural fact modeled as a tunable value,
   which the user correctly flags as impure. It also can't represent *moving* a tire from the front
   wheel to the rear wheel, since `Installation.parent` today is a bike id, never a component id.

The user's proposal: generalize `Installation` so components can mount on other components (Feature #2
in the June 27 report), then group by `(componentType, installationParentId, adjustment.name)`.

---

## 2. Why there's no free lunch: the join-key problem

This is the actual crux, and it's worth stating plainly because it's independent of any particular fix:

- **`Adjustment.id` is not a stable join key across replacements.** Every `Component` owns its own
  `List<Adjustment>`, each with a fresh UUID (`Adjustment(... id: id ?? const Uuid().v4())`,
  [adjustment.dart:34](lib/models/adjustment/adjustment.dart#L34)). Replace the tire → brand new
  `Adjustment` id for "Pressure". `Setup.bikeAdjustmentValues` is keyed by that id
  ([setup_resolution_service.dart:43](lib/services/setup_resolution_service.dart#L43)), so two tires
  a year apart never share a key.
- **`Component.name` is not stable either** — "Continental GP5000 v2" vs. "Schwalbe Pro One" are
  different names for the same *role*. Grouping by name would defeat the entire goal (a new column per
  purchase).
- **`ComponentType` is the only thing that *is* stable** across a replacement — which is exactly why the
  user's instinct (`componentType` + adjustment name) is the right starting point. The gap is only that
  `componentType` alone isn't a fine-enough key for components that come in physical pairs.

So: **any solution needs a derived grouping key that's coarser than `Adjustment.id`, coarser than
`Component.name`, but finer than bare `ComponentType`.** Everything below is really different answers to
"what's the missing piece of that key."

Confirms this doesn't exist anywhere yet: [to_spreadsheet.dart](lib/utils/to_spreadsheet.dart) — the
existing Excel/CSV export — builds one column-group **per live component instance**
([to_spreadsheet.dart:166-181](lib/utils/to_spreadsheet.dart#L166-L181)), not per role. It would have
the *identical* front/rear collision if two same-typed components' adjustment groups were ever merged
— it currently avoids the question entirely by never merging them. This is new ground, not a bug fix.

---

## 3. First pass (superseded): a static `side` field

The original idea: add `enum ComponentSide { none, front, rear, left, right }` directly on `Component`,
and group by `(componentType, side, normalizedAdjustmentName)`. Small, additive, no `Installation`
changes.

**Why this doesn't survive contact with real usage:** a tire that rode Front from January to June, then
got swapped to Rear in July, needs its *pre-swap* setups to land in the Front column and its *post-swap*
setups to land in the Rear column. A plain field can't do that — editing `side` in July silently
relabels January–June's history too. The fix needs a **dated sequence** of "which slot was this playing"
events, not a snapshot. That's not a smaller variant of the problem; it's a different requirement.

This also retroactively indicts something already shipped: `wheelFront`/`wheelRear`
([component_type.dart:44-46](lib/models/component_type.dart#L44)) is a *static* type, and the user
confirmed wheels get swapped front/rear too — the exact same bug, just currently invisible because
nothing reads "what side was this wheel on last March" yet. The table would have been the first thing to
expose it.

---

## 4. The reframe: "which slot" is always a timeline, never a field

Once a dated sequence is required, there's already a mechanism in this codebase for exactly that shape:
`Installation` — an append-only, dated list, current state = latest event at-or-before a given time. A
tire moving from the front wheel to the rear wheel is not a new concept: it's **the same operation the
app already does today when a component moves from bike A to bike B**, just retargeted one level deeper.
That's the strongest argument for nesting (Feature #2, Approach 1 in the June 27 report) over inventing a
second, parallel timeline just for position — one mechanism, not two that must stay in sync.

And the user's observation about scope is the other half of the good news: **tire is very plausibly the
*only* component that's (a) duplicated on one bike and (b) individually adjusted.** Pedals and grips come
in pairs too, but don't carry adjustments (or are set equal if they do), so they never hit this problem.
That means the fix doesn't need to be a general "position" concept for every paired type — it needs
exactly what Approach 1 in the June 27 report already scoped: **components can mount on other
components.** This isn't new design; it's a concrete, motivating reason to prioritize a plan that already
exists.

---

## 5. The wrinkle: nesting alone still bottoms out on a static field

Nesting resolves a tire's position by asking "which wheel is it on" — but *that* wheel's front/rear-ness
today comes from `wheelFront`/`wheelRear`, a static `ComponentType`. Since wheels get swapped too, that
static type has **the identical retroactive-corruption flaw** §3 identified for tires, just one level up.
Fixing tire without also fixing this would leave the same bug, one hop away.

The fix generalizes cleanly: give a **mount slot** to installations, not just a parent id — meaningful
wherever a parent can host more than one child of the same role. Concretely:

```dart
enum MountSlot { none, front, rear } // extend later if a left/right case ever needs it

class BikeInstallation extends Installation {
  final String bikeId;
  final MountSlot slot; // 'front'/'rear' for a wheel; 'none' for singletons (frame, fork, ...)
}

class ComponentInstallation extends Installation { // Feature #2, June 27 report
  final String parentComponentId; // e.g. a tire's parent wheel
  // No slot needed here today: a wheel hosts exactly one tire, one disc, one cassette —
  // already disambiguated by componentType, not by position.
}
```

A component's effective position, at any time, is resolved transitively rather than stored anywhere:

```dart
MountSlot effectiveSlotAt(String componentId, DateTime t) {
  final inst = latestInstallationAtOrBefore(componentId, t);
  return switch (inst) {
    BikeInstallation(:final slot) => slot,              // a wheel: its own slot
    ComponentInstallation(:final parentComponentId) =>
        effectiveSlotAt(parentComponentId, t),           // a tire: inherits its wheel's slot
    _ => MountSlot.none,                                 // deinstalled / archived / none
  };
}
```

This one mechanism replaces **both** hacks — `wheelFront`/`wheelRear` type-doubling and the tire's
"installed on" adjustment — with a single dated, append-only pattern that reuses machinery the app
already trusts for bike reassignment. No static field can be edited out from under history anymore.

**Consequence:** `wheelFront`/`wheelRear` should collapse into one `wheel` type + `slot` on its
`BikeInstallation`. This is no longer an optional cleanup (as the first pass framed it) — since wheels
are confirmed to be swapped in practice, leaving the static type in place keeps the bug alive.

---

## 6. Recommendation

**Proceed with Feature #2 (Approach 1, sealed `Installation`, one nesting level — already scoped in the
June 27 report), extended with the `MountSlot` discriminator from §5.** This replaces both position hacks
with one mechanism, fixes the table's grouping key with full time-fidelity, and — per the user's own
reasoning — also delivers bulk install/deinstall of a wheel with its mounted parts and an honest "what's
on this wheel" query, which a display-only fix never would.

**Being transparent about the trade being made:** the table's grouping problem alone does *not* strictly
require full component-to-component nesting. A cheaper alternative exists — add `MountSlot` directly to
`BikeInstallation` for *both* wheel and tire (tire stays bike-parented, never wheel-parented) — which
would fix the collision and the retroactive-corruption bug with none of Feature #2's stats-SQL/`bikeAt`/
cascade-recompute cost. What it would *not* give you is a real parent-child link between tire and wheel:
no "what's mounted on this wheel right now," and swapping a wheel wouldn't automatically carry its tire
along — you'd update both independently. Since bulk install/deinstall and the truer mental model are
exactly the two extra things the user said matter, full nesting is the right call *for this project*, not
just the more thorough one in the abstract. Table below makes the trade explicit.

| Approach | Fixes collision + hack | Time-correct across swaps | Bulk install/deinstall | "What's on this wheel" query | Stats SQL / `bikeAt` change | Effort |
|---|---|---|---|---|---|---|
| Static `side` field (§3) | ✅ (naively) | ❌ retroactive corruption | ❌ | ❌ | No | Small — **rejected** |
| `MountSlot` on `BikeInstallation` only (tire stays bike-parented) | ✅ | ✅ | ❌ | ❌ | No | Small–medium |
| **Full nesting + `MountSlot` (recommended)** | ✅ | ✅ | ✅ | ✅ | **Yes** | Large (as already scoped, §7) |

---

## 7. What this costs

This is the Feature #2 effort already estimated in the
[June 27 report](20260627_component_archive_and_nesting.md#3-feature-2--sub-components-mounted-on-a-wheel)
— sealed `ComponentInstallation` case, stats SQL two-level `UNION`, transitive `bikeAt`, cascade
recompute, cycle/depth invariants — **plus** three small increments specific to this thread:

1. **`MountSlot` on `BikeInstallation`**, alongside the existing `bikeId` — small, additive.
2. **Collapse `wheelFront`/`wheelRear` → `wheel` + `slot`.** Mechanical one-time migration: for each
   existing wheel component, set `componentType = wheel` and backfill `slot` on its historical
   `BikeInstallation` events from its pre-migration static type. Same shape as the `parentType` backfill
   already done for archiving ([20260628 plan, §3.2](20260628_feature1_archiving_implementation.md#32-db-table--migration-installationsdart-app_databasedart)).
   Needs a `ComponentType` JSON/import compatibility shim so old backups referencing `wheelFront`/
   `wheelRear` still map correctly.
3. **Retire the "installed on" adjustment** on tire components: parent it to the correct wheel via
   `ComponentInstallation`, delete the adjustment. A handful of the user's own components — realistically
   a manual, one-time cleanup rather than an automated script.

**Known limitation, stated plainly:** if a past wheel swap or tire reassignment was never recorded as a
dated event — just a silent type edit, as happens today — the exact swap date can't be reconstructed
retroactively. The migration can only backfill "whatever the type says right now" as a single event at
migration time; anything finer requires the user's own memory of when swaps happened. Going forward,
every swap is exact by construction.

---

## 8. Table grouping key, updated

Column key: `(componentType, effectiveSlotAt(component.id, setup.datetime), normalizedAdjustmentName)` —
resolved **per setup**, not once per component. This is what closes the original hole: a tire's pre-swap
setups resolve to the old slot, post-swap setups resolve to the new one, automatically, because the key
is evaluated at each setup's own timestamp rather than read off a mutable field.

`effectiveSlotAt` is exactly the transitive resolver Feature #2 already needs for `bikeAt`/stats
attribution (§3.2 of the June 27 report) — so the table's implementation rides on top of that
investment rather than being separate work. Cell resolution otherwise proceeds as before: for a given
`(setup, columnKey)`, scan the column's contributing `Adjustment`s and take the one whose id is present
in `setup.bikeAdjustmentValues` (formatted via that adjustment's own type/unit).

**Ordering:** columns by `ComponentTypeCategory` → `ComponentType.index` → slot → adjustment name,
mirroring the sort already used in `InstallationTimelineTable`
([installation_timeline_table.dart:123-127](lib/widgets/installation_timeline_table.dart#L123)). Rows
newest-first, matching the convention in `to_spreadsheet.dart` and the setup list.

**Scope note (unchanged):** this table only concerns `bikeAdjustmentValues`, all of which originate from
component adjustments (`Bike` itself has no adjustments field). `personAdjustmentValues` stay out of
scope.

**Reuse from `InstallationTimelineTable`:** the component-type `FilterChip`, the sticky-first-column
horizontally-scrolling `Table`, and the tooltip-on-icon header pattern all transfer directly.

---

## 9. Open decisions

1. **Confirm the direction:** full nesting + `MountSlot` (§5–§7), given it's costed against the known
   alternative in §6's table and the extra cost buys bulk install/deinstall + true parent-child queries.
2. **`wheelFront`/`wheelRear` → `wheel` + `slot` collapse:** bundle into this work now (recommended, since
   the swap bug is confirmed live) vs. defer — deferring means the tire fix inherits the same bug from
   its parent.
3. **Historical backfill for undocumented past swaps:** accept the "single event at migration time" limit
   from §7, or spend time manually reconstructing known swap dates first.
4. **`ComponentInstallation` slot:** not needed today (a wheel hosts one tire, one disc, one cassette —
   already disambiguated by type). Leave unadded until a real case needs it, rather than speculatively
   including it now.
5. **Sequencing against the rest of Feature #2** (archiving is done; nesting is Phase 3 in the June 27
   report's phasing, §7 there) — whether this becomes the concrete trigger to start Phase 3 now.
