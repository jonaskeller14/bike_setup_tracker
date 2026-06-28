# Component Archiving & Sub-Component Nesting — Design Report

**Date:** 2026-06-27
**Status:** Proposal / planning only — no code changes yet
**Scope:** Object models (`lib/models/`) and the Drift database (`lib/database/`). UI changes are
listed for impact-awareness but are explicitly **out of scope** for this report.

---

## 1. Context & current model

Three files define everything relevant here:

- [installation.dart](lib/models/installation.dart) — the `Installation` value object
- [component.dart](lib/models/component.dart) — `Component`, owns `List<Installation>`
- [installations.dart](lib/database/tables/installations.dart) / [components.dart](lib/database/tables/components.dart) — the Drift tables

### How a component's "location" works today

An `Installation` is a timeline event: *"on date X, this component went onto `parent`"*, where
`parent` is **a bike id, or `null` = deinstalled**.

```dart
class Installation {
  final String? parent;        // bike id, or null = "in the parts bin"
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
}
```

A component's current bike is *derived*, never stored:
[`Component.bikeAt(t)`](lib/models/component.dart#L36) sorts the installations and returns the
`parent` of the latest event at or before `t`; `Component.bike` is `bikeAt(now)`.

Key properties of the current design that constrain everything below:

1. **`Installation` has no `id` and no `componentId` in the model.** Both exist only in the table.
   The repository *regenerates* installation ids on every save via `Uuid().v4()`
   ([app_repository.dart:1118](lib/repositories/app_repository.dart#L1118),
   [:1163](lib/repositories/app_repository.dart#L1163)), and
   [`updateComponentWithData`](lib/database/daos/components_dao.dart#L110) **deletes all rows for the
   component and re-inserts them**. Installation rows are therefore disposable and have no stable
   identity. (Relevant to §4.)

2. **`installations.parent` is a plain nullable `text`, not a foreign key.** Dangling bike ids are
   already a supported reality (the timeline renders a red *"BIKE NOT FOUND"* item —
   [set_installation_timeline.dart:333](lib/widgets/set_installation_timeline.dart#L333)).

3. **Mileage/stat attribution is done in SQL and keys directly off `parent = bike id`.** This is the
   single most important constraint for Feature #2. In
   [`StravaDao.watchComponentStats`](lib/database/daos/strava_dao.dart#L102):

   ```sql
   FROM strava_activities a
   JOIN bikes b         ON a.gear_id = b.strava_gear
   JOIN installations i ON b.id = i.parent           -- parent MUST be a bike
   WHERE a.start_date >= i.date_time_u_t_c
     AND (a.start_date < <next installation event of this component> OR <no next event>)
   GROUP BY i.component_id
   ```

   For each window `[install, next-event)` the component accrues the activities of that bike's gear.
   A deinstall (`parent = null`) contributes no rows itself but **bounds** the previous window.
   The same shape is repeated in
   [`getComponentStatsAt`](lib/database/daos/strava_dao.dart#L196). Bike stats
   ([`watchBikeStats`](lib/database/daos/strava_dao.dart#L163)) are independent of installations.

4. **`ComponentInstallation`** ([app_repository.dart:1344](lib/repositories/app_repository.dart#L1344))
   is *not* persisted. It is a flattened view `{component, installation, originParent, isInitial}`
   rebuilt every cycle by [`_filterInstallations`](lib/repositories/app_repository.dart#L624) and fed
   to the calendar via [`InstallationEntry`](lib/models/timeline_entry.dart#L32). `originParent` and
   `isInitial` are purely derived from neighbour ordering.

### The four lifecycle states we want

| State | Today | On a bike? | In primary UI? | Reusable? | Stats/history kept? |
|---|---|---|---|---|---|
| Installed | latest `parent = bikeId` | yes | yes | — | yes |
| Deinstalled (parts bin) | latest `parent = null` | no | yes | yes (shown in Replace picker) | yes |
| Deleted (trash) | `isDeleted = true` | — | no (Trash page) | on restore | yes, but hidden |
| **Archived (new)** | — | no | **no** | **no** | **yes — that's the point** |

The crucial observation: **deinstalled and archived both have `parent = null`**, so archived
*cannot* be derived from the timeline by parent alone. It needs an explicit marker — either a distinct
*terminal installation event type* (recommended — §2 Approach A) or a *component-level flag*
(§2 Approach B).

---

## 2. Feature #1 — Archive state

> *Old tires / brake pads / sold components: not ridable, hidden from the primary UI, but their data
> stays accessible for analysis.*

**Refined requirement (from review):** archiving only makes sense for a component that is *not on a
bike* — you retire something you've already taken off. The model should make "archived **and**
installed" **unrepresentable**, not merely discouraged. And no separate archive timestamp is needed:
the retire moment is simply the date of the component's final off-bike event.

For stat summation, **archived and deinstalled are identical — both are ignored**: neither carries a
bike, so they accrue nothing and only *bound* the previous on-bike window (the `MIN(next_event)`
sub-query in [strava_dao.dart:128](lib/database/daos/strava_dao.dart#L128) already bounds on *any*
later event, regardless of type). They differ in exactly one respect: a **deinstalled** part is
reusable (it shows in the Replace picker), an **archived** part is retired (hidden). That lone
difference is what forces an explicit marker — both states have `parent = null`.

Two viable shapes (the earlier "hybrid" idea is dropped):

### Approach A — Archived as a terminal installation state (recommended)

Model retirement as a terminal timeline event, sharing Feature #2's sealed hierarchy + `parentType`
discriminator (§3):

```dart
sealed class Installation { /* id, componentId, dateTimeUTC, dateTimeLocal */ }
class BikeInstallation      extends Installation { final String bikeId; }
class ComponentInstallation extends Installation { final String parentComponentId; } // Feature #2
class Deinstallation        extends Installation { }   // parts bin — reusable
class Archival              extends Installation { }   // retired — hidden
```

State is *derived from the latest event*, exactly like `bike`/`bikeAt` today:
`isArchived ⇔ latest event is Archival`, `isDeinstalled ⇔ latest event is Deinstallation`. Persisted
via the same `parentType` column Feature #2 adds, with one extra value:
`{bike, component, none, archived}`.

| Pros | Cons / caveats |
|---|---|
| **Illegal states unrepresentable:** archived constructionally implies "off a bike" — no cross-field invariant to police. | Couples archive to the installation-model work (sealed classes + discriminator); not a standalone one-column add — see phasing (§7). |
| **No `archivedAt`:** the `Archival` event's timestamp *is* the retire date — and correctly differs from an earlier deinstall date if a part is parts-binned first and retired later (a case a bare flag can't timestamp). | "Archived?" is computed (sort + inspect latest event), not a column ⇒ no cheap SQL `WHERE is_archived = 0`. Not needed — primary-UI hiding is done in Dart (see caching nuance). |
| Single source of truth = the timeline; installed / deinstalled / archived all derived the same way. | Timeline editor + validation must learn `Archival` (UI, out of scope): e.g. it can't be "From beginning"; re-installing after it simply un-archives. |
| **Stats need no special-casing** — `Archival` behaves exactly like `Deinstallation`. | Archive state travels inside the installation type in backup/JSON, not as a component field. |
| One coherent model with Feature #2: archiving = append one `Archival` event (vs. "deinstall + flip flag"); reuses `parentType`, no new component column. | |
| Composes with nesting: archiving a wheel ⇒ wheel has no bike ⇒ its still-mounted sub-components resolve to no-bike (stop accruing) **without being archived themselves**. | |

### Approach B — Boolean flag `isArchived` on `Component` (fallback)

Add `BoolColumn isArchived` to `Components` + `bool isArchived` on the model, mirroring `isDeleted`.

| Pros | Cons / caveats |
|---|---|
| Dead simple; mirrors `isDeleted`; plain additive `addColumn`, no table recreation. | **Allows the invalid "archived + installed" combination** — the exact weakness the review flagged; the invariant must be enforced imperatively (auto-append a deinstall on archive). |
| **Fully independent of Feature #2** ⇒ shippable now as an isolated phase. | Two pieces of state (timeline + flag) for one concept; the retire moment isn't captured unless you keep the deinstall convention or add `archivedAt` (otherwise unnecessary). |
| Trivial `WHERE is_archived = 0` if ever wanted. | Same caching nuance applies (below), so it's no simpler at the repository layer. |

### Recommendation: **Approach A** (archived as a terminal installation state)

The review's argument is decisive. Because Feature #2 is already introducing the sealed `Installation`
hierarchy and `parentType` discriminator, Approach A rides on that machinery for almost free **and**
makes "archived + installed" structurally impossible. Archiving = append one `Archival` event at the
retire date (which also closes the last on-bike window); un-archiving = re-install, or delete that
event. No `archivedAt`, no auto-deinstall convention, no new boolean dimension.

- **Replace picker:** show only reusable parts — *latest event is `Deinstallation`, not `Archival`* —
  replacing the current `c.bike == null` test in
  [replace_component.dart:176](lib/widgets/sheets/replace_component.dart#L176).

**Keep Approach B as the fallback** only if archiving must ship *before* the installation refactor and
you want zero coupling; then enforce the invariant by auto-appending a deinstall when archiving an
installed component, and accept that archived vs deinstalled is distinguished by a flag rather than by
construction.

#### ⚠️ Caching nuance — archive is *not* exactly the trash pattern

`isDeleted` is fully excluded from the active stream and surfaced via a *separate* deleted stream.
**Archived components must NOT be excluded from the primary in-memory cache**, because analysis still
reads them:

- [`SetupResolutionService.resolveSetups`](lib/services/setup_resolution_service.dart#L40) iterates
  `_components` to resolve historical adjustment values;
- `_componentStats` mapping and `getTaskRuleStatus` read `_components`;
- the installation timeline reads `components.values`.

So keep archived rows flowing through
[`watchAllComponentsWithData`](lib/database/daos/components_dao.dart#L22) (i.e. *don't* add
`isArchived = 0` there, and **don't** add it to the stats SQL `WHERE c.is_deleted = 0`). Hide them
only at the **presentation/filter** layer:

- exclude archived in [`_filterComponents`](lib/repositories/app_repository.dart#L511) (garage list),
- add an `archivedComponents` getter derived from the in-memory cache (no new DB stream needed).

This is the one place where archive deliberately diverges from the soft-delete mixin.

#### Open logic decision (not schema)
Should component-linked task rules for an archived component still appear as Due/Overdue? Almost
certainly no — filter them out in [`_filterTaskRules`](lib/repositories/app_repository.dart#L549).
Flagged as a follow-up; it is logic, not schema.

---

## 3. Feature #2 — Sub-components mounted on a Wheel

> *Mount cassette / brake disc / tire on a Wheel component; install or deinstall the whole wheel
> (with all sub-components) in one action. Deeper nesting not strictly necessary.*

The blocker: today `parent` is **always a bike**, and the stats SQL hard-codes
`JOIN installations i ON b.id = i.parent`.

### Approach 1 — Generalise `parent` to bike *or* component, via a discriminator (recommended)

Let an installation point at either a bike or a parent component. The user already leans toward
**sealed `Installation` subclasses** — a good fit; the codebase uses sealed + pattern matching
already ([TimelineEntry](lib/models/timeline_entry.dart#L7),
[ReplaceComponentResult](lib/widgets/sheets/replace_component.dart#L11), adjustments).

```dart
sealed class Installation {
  final String id;            // NEW — persisted & stable (see §4)
  final String componentId;   // NEW — the child component (see §4)
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;
}
class BikeInstallation      extends Installation { final String bikeId; }
class ComponentInstallation extends Installation { final String parentComponentId; } // ⚠ name clash, see §4
class Deinstallation        extends Installation { /* parts bin — reusable */ }
class Archival              extends Installation { /* retired — Feature #1 (§2) */ }
```

This single hierarchy is **shared by both features**: `Archival` is Feature #1's terminal state (§2)
and `ComponentInstallation` is Feature #2's nesting. Table change: add `parentType TEXT`
(`bike` | `component` | `none` | `archived`); keep `parent` as the id payload (null for
`none`/`archived`). (A lighter, less type-safe variant keeps **one** class with a `parentType` enum +
nullable `parentId` — smaller diff, no pattern-matching exhaustiveness. Recommend sealed, per the
user's instinct.)

**Why this is the elegant choice — moving the wheel moves its parts for free.** If `bikeAt`
resolves *transitively* (a sub-component's bike = its parent component's bike at that time), then
deinstalling the wheel from the bike makes every mounted sub-component resolve to "no bike" with
**zero writes to the sub-components**. You only ever write a sub-component installation when you
physically add/remove that part *from the wheel*. This directly satisfies "install/deinstall the
whole wheel with all sub-components in one action."

| Pros | Cons / caveats |
|---|---|
| Matches the real-world mental model (a tire *is on* a wheel). | **The stats SQL gets materially harder** — see §3.1. This is the main cost/risk. |
| Reuses the existing timeline mechanism unchanged in spirit. | **`bike`/`bikeAt` can no longer be a self-contained `Component` getter** — see §3.2. |
| "Move the wheel ⇒ parts follow" falls out of transitive resolution. | Need invariants: no cycles, depth cap, dangling-parent handling (§3.3). |
| Discriminator column is a small additive schema change. | Several call sites assume `parent` = bike (timeline dropdown, `_filterInstallations`, `watchCurrentBikeForComponent`). |
| Frees us to also fix the installation-id wart (§4). | Editing a wheel must cascade stat/snapshot recompute to its descendants (§3.4). |

### Approach 2 — Component groups / "wheelset" entity

A separate grouping entity bundles components; install/deinstall the group.

| Pros | Cons / caveats |
|---|---|
| Explicit bulk operations; the group has its own identity. | The user's own objection: *"what is grouping in real life?"* A wheel is a real, wearing component, not a container. |
| | The wheel would need to be both a `Component` (it wears) **and** a group — duplication. |
| | Two parallel structures (groups + installations) to keep consistent. |
| | Stats still need group→bike attribution — similar complexity to Approach 1 **plus** an extra indirection. |

### Approach 3 — Bulk-action macro only (no stored relationship)

Keep `parent = bike` always; a UI macro writes the same bike+date event to the wheel and each
selected part at once.

| Pros | Cons / caveats |
|---|---|
| **Zero schema change; stats SQL untouched.** | No persistent "tire belongs to wheel" — re-selected every time, error-prone. |
| Trivial to ship. | Can't answer "what's on this wheel now?"; if the wheel moves bikes you must re-pick the parts. |
| | Doesn't durably satisfy "one action" — only an ad-hoc multi-select. Doesn't match intent. |

### Recommendation: **Approach 1** (sealed installations + transitive bike resolution), one nesting level.

It is the only option that models the real relationship and makes the headline UX ("move the wheel,
parts follow") essentially free. The cost concentrates in two well-bounded places — the stats SQL
(§3.1) and bike-resolution (§3.2) — which is acceptable and testable.

### 3.1 The hard part: stat attribution for sub-components

A tire on a wheel on a bike accrues an activity **iff**, at the activity's `start_date`, the tire was
on the wheel **and** the wheel was on a bike whose gear matches the activity. This is a **temporal
interval intersection** across two levels. Three ways to implement it:

**(a) Two-level `UNION` query — recommended for a 1-level requirement.**
Keep the existing query for `parentType = bike`, and `UNION ALL` a second branch for
`parentType = component`:

```sql
-- direct-on-bike windows: existing query, restricted to parentType='bike'
UNION ALL
-- on-a-component-that-is-on-a-bike windows:
FROM strava_activities a
JOIN bikes b          ON a.gear_id = b.strava_gear
JOIN installations wi ON b.id = wi.parent                 -- wheel on bike   (parentType='bike')
JOIN installations ti ON ti.parent = wi.component_id      -- tire on wheel   (parentType='component')
WHERE a.start_date >= wi.date_time_u_t_c AND a.start_date < <next wheel event>
  AND a.start_date >= ti.date_time_u_t_c AND a.start_date < <next tire event>
GROUP BY ti.component_id
```

- ✅ Single source of truth (installations); no cache to invalidate.
- ⚠️ One extra branch *per nesting level*. Fine for one level ("further nesting not necessary");
  doesn't scale to arbitrary depth.

**(b) Recursive CTE** that walks `parent → … → bike` intersecting intervals at query time. Elegant,
no extra table, arbitrary depth; trickier to write and to keep fast. SQLite supports it.

**(c) Materialised "effective bike intervals" table** `(componentId, bikeId, startUtc, endUtc)`,
computed in Dart by resolving the parent chain on every installation write, with the existing simple
stats query pointed at it. Scales to any depth and keeps the hot query trivial, but duplicates the
windowing logic and adds cache-invalidation surface (every install/deinstall/archive/wheel-move must
recompute affected subtrees). Fits the app's existing "recompute on write" habit
([`refreshTaskEntrySnapshots`](lib/repositories/app_repository.dart#L841)).

> **Recommendation:** ship **(a)** for the one-level requirement; keep **(b)/(c)** as the escape
> hatch if deeper nesting or performance ever demands it.

### 3.2 `bike` / `bikeAt` must become parent-chain-aware

Today [`Component.bikeAt`](lib/models/component.dart#L36) is self-contained — it only reads its own
installations. Once a parent can be a component, resolving a tire's bike needs the *wheel* object too,
which a `Component` doesn't hold. Resolution must move to something that owns the full component map
(the repository, or a small `InstallationResolutionService`), e.g.
`resolveBikeAt(componentId, t)` walking the chain (depth-capped, cycle-guarded). Known call sites to
migrate:

- [`_filterComponents`](lib/repositories/app_repository.dart#L511) — `entry.value.bike == selectedBike`
- [`SetupResolutionService.resolveSetups`](lib/services/setup_resolution_service.dart#L41) — `bikeAt(setup.datetime)`
- [`getTaskRuleStatus`](lib/repositories/app_repository.dart#L866) — installation lookup for a component's bike
- [replace_component.dart:178](lib/widgets/sheets/replace_component.dart#L178) — `c.bike == null`
- [component_actions.dart:100](lib/utils/component_actions.dart#L100) — `component.bike` during replace

This refactor is the second real cost of Approach 1.

### 3.3 New invariants

- **No cycles** (A on B, B on A) and **depth cap** (recommend hard-limit to 1 level now; structurally
  allow more later). Validate before save.
- **Dangling/incompatible parent**: parent component deleted/archived ⇒ treat like today's
  "BIKE NOT FOUND" (graceful orphan, no hard FK). Keep `parent` a soft reference.
- **Type sanity** (optional, UI-enforced): only sensible types mount on a wheel
  (`tire`, `casette`, `brakeDisc`); the data model needn't enforce this.

### 3.4 Cascade recompute

[`editComponent`](lib/repositories/app_repository.dart#L1143) gates snapshot recompute on
`statsInputsChanged` for the *edited* component only. With nesting, **changing a wheel's installations
changes its sub-components' stats too**, so recompute must cascade to descendants (or simply always
call the global [`refreshTaskEntrySnapshots`](lib/repositories/app_repository.dart#L841) when a
component that has children is edited).

---

## 4. Consolidation — fold `ComponentInstallation` into the data model

The user asked whether the `ComponentInstallation` helper can be merged into the data model. It can,
and it pairs naturally with Feature #2.

### The wart
`Installation` (model) lacks `id`/`componentId`; the repository invents ids on every save and
[`updateComponentWithData`](lib/database/daos/components_dao.dart#L110) does delete-all + re-insert.
So installation rows churn on every edit and have no stable identity.

### Proposal
1. **Add `id` and `componentId` to the `Installation` model** (they already exist in the table). Map
   them through in [mappers.dart](lib/database/mappers.dart#L66) and switch the DAO from
   delete-all/re-insert to a keyed upsert (+ delete-missing). Stable ids; far less table churn.
2. **Retire `ComponentInstallation`.** Its three pieces become:
   - `component` → resolved from `componentId` via the repository map;
   - `originParent`, `isInitial` → derived getters on a small timeline view (or a
     `Component.timeline()` method) computed from the sorted list — exactly what
     [`_filterInstallations`](lib/repositories/app_repository.dart#L624) does today, minus the bespoke
     class.
   - [`InstallationEntry`](lib/models/timeline_entry.dart#L32) then wraps the real installation +
     component instead of the helper.

| Pros | Cons / caveats |
|---|---|
| Removes id churn; enables stable references & clean upserts. | **Name clash:** Feature #2's `ComponentInstallation` subclass vs. today's helper — retiring the helper frees the name (sequence the rename). |
| One installation concept instead of model + helper. | Touches the timeline/calendar surface ([calendar_page](lib/pages/calendar_page.dart), [display_installation_timeline](lib/widgets/display_installation_timeline.dart), [set_installation_timeline](lib/widgets/set_installation_timeline.dart)). |
| `componentId` on the model makes the parent-chain logic in §3 cleaner. | JSON/backup gains `id` (back-compat: synthesise on import when absent). |

**Synergy:** Feature #2 references parents by **component id** (stable — a component's own id), not by
installation id, so it does *not* depend on this fix. But doing them together gives a single coherent
installation model. **Recommend bundling §4 with Feature #2.**

---

## 5. Combined impact surface

**Models**
- [installation.dart](lib/models/installation.dart) — sealed subclasses (`BikeInstallation`, `ComponentInstallation`, `Deinstallation`, `Archival`) or a `parentType` enum, + `id`/`componentId`; `toJson`/`fromJson`/`copyWith`/`==`/`hashCode`.
- [component.dart](lib/models/component.dart) — derived `isArchived`/`isDeinstalled` getters (Approach A); JSON **version bump to 5** ([toJson:192](lib/models/component.dart#L191), [fromJson:209](lib/models/component.dart#L209)); `bike`/`bikeAt` delegated to a resolver; `deepCopy`/`copyWith`/`==`. *(Approach B instead: an `isArchived` field here.)*
- [timeline_entry.dart](lib/models/timeline_entry.dart) — `InstallationEntry` no longer wraps the helper.

**Database**
- [tables/installations.dart](lib/database/tables/installations.dart) — `parentType` (`bike`/`component`/`none`/`archived`); under Approach A archive lives here.
- [tables/components.dart](lib/database/tables/components.dart) — *Approach B fallback only:* an `isArchived` column.
- [app_database.dart](lib/database/app_database.dart) — `schemaVersion` **8 → 9**; migration (§6).
- [mappers.dart](lib/database/mappers.dart) — installation & component mappers (new fields).
- [daos/components_dao.dart](lib/database/daos/components_dao.dart) — keyed installation upsert; keep archived in `watchAllComponentsWithData`.
- [daos/strava_dao.dart](lib/database/daos/strava_dao.dart) — nested stat attribution in `watchComponentStats` + `getComponentStatsAt` (§3.1).

**Repository / services**
- [app_repository.dart](lib/repositories/app_repository.dart) — `_filterComponents` (hide archived), `archivedComponents` getter, parent-aware `_filterInstallations`, retire `ComponentInstallation`, cascade recompute, archived task-rule filtering, `bikeAt` resolver.
- [setup_resolution_service.dart](lib/services/setup_resolution_service.dart) — use the new resolver.
- [data_export_service.dart](lib/services/data_export_service.dart) + [database_migration_service.dart](lib/services/database_migration_service.dart) + [file_import.dart](lib/utils/file_import.dart) — JSON round-trip of new fields/versions.

**UI (out of scope — listed for awareness):** [set_installation_timeline.dart](lib/widgets/set_installation_timeline.dart) (pick a parent component, not only a bike), [replace_component.dart](lib/widgets/sheets/replace_component.dart) (exclude archived), [installation_sheet.dart](lib/widgets/sheets/installation_sheet.dart), [garage_list.dart](lib/widgets/lists/garage_list.dart), [component_page.dart](lib/pages/component_page.dart), [calendar_page.dart](lib/pages/calendar_page.dart).

**Tests to update:** `component_test`, `mappers_test`, `component_stats_test`, `setup_resolution_service_test`, `app_repository_test`, `replace_component_test`, `installation_sheet_test`, `set_installation_timeline_test`, `trash_test`, `task_snapshot_healing_test`.

---

## 6. Migration & backup/JSON versioning

Bump `schemaVersion` 8 → 9. In `onUpgrade` (recommended Approach A):

- `addColumn(installations, installations.parentType)`, then backfill existing rows:
  `parentType = 'bike'` where `parent IS NOT NULL`, else `'none'`. All legacy parents are bikes and
  nothing is archived yet, so this is lossless (`'archived'` / `'component'` only arise from new writes).
- *Approach B fallback only:* additionally `addColumn(components, components.isArchived)` — default
  `false` (plain add, no recreation).

**Backups / legacy import:**
- Component JSON version → **5**; `fromJson` must accept the new installation shape while still
  accepting v2–v4 (parent = bike, no `parentType`, no installation `id`). Under Approach A archive
  state rides inside the installation type, so there is no component-level archive field to read
  (under Approach B, read `isArchived`, default `false`).
- `Installation.fromJson`: infer `parentType = 'bike'` when a non-null `parent` is present and no type
  is given; synthesise an `id` when absent. Keep the import path tolerant of pre-nesting backups.

No conflict with the Strava data-retention concerns tracked separately; stats logic here is on-device
only.

---

## 7. Recommended phasing

Because the recommended archive model (Approach A) rides on the sealed/discriminated `Installation`,
the natural order is **foundation → archive → nesting**:

1. **Phase 1 — Installation model foundation (§4 + discriminator).** Introduce the sealed hierarchy
   (`BikeInstallation`, `Deinstallation`) + `parentType` column + `id`/`componentId` on the model +
   keyed upsert, and retire the `ComponentInstallation` helper. No behavioural change (installed vs
   deinstalled already exist — just remodelled). Migration v9.
2. **Phase 2 — Archiving (Feature #1, Approach A).** Add the `Archival` case (`parentType='archived'`),
   `Component.isArchived`/`isDeinstalled` getters, presentation-layer hiding + `archivedComponents`,
   Replace-picker exclusion, archived task-rule filtering. Small once Phase 1 exists.
3. **Phase 3 — Nesting (Feature #2, Approach 1, one level).** Add the `ComponentInstallation` case
   (`parentType='component'`), transitive `bikeAt` resolver, two-level `UNION` stats (§3.1a),
   invariants, cascade recompute.

**Shortcut:** if archiving must ship *before* the installation refactor, do it as a standalone boolean
(Approach B) first and re-fold it into the timeline model later.

---

## 8. Decisions needed before implementation

1. **Archive model:** terminal installation state (Approach A) vs. boolean flag (Approach B)?
   (Recommend A — makes "archived + installed" unrepresentable and needs no `archivedAt`.)
2. **Ship archive before or after the installation refactor?** A couples to it (foundation-first, §7);
   shipping now would mean the Approach B boolean shortcut.
3. **Archived task rules:** hide component-linked rules for archived components from Due/Overdue?
   (Recommend yes.)
4. **Installation modelling:** sealed subclasses (type-safe, user's instinct) vs. single class +
   `parentType` enum (smaller diff)? (Recommend sealed.)
5. **Stats strategy:** two-level `UNION` now (recommended) vs. recursive CTE / materialised intervals
   for future-proof depth?
6. **Nesting depth:** hard-cap at 1 level in validation now, or allow N structurally? (Recommend cap
   at 1, structure for more.)
```
