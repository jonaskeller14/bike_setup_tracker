# Feature #1 — Component Archiving: Implementation Plan

**Date:** 2026-06-28
**Status:** Implementation plan (no code yet)
**Builds on:** [20260627_component_archive_and_nesting.md](20260627_component_archive_and_nesting.md) (design report)
**Scope:** Feature #1 (archiving) only, via **Approach A** (archived = terminal installation state) plus
the **`ComponentInstallation` refactor** (give `Installation` a stable `id`/`componentId`, retire the
helper). Designed so **Feature #2 (nesting) can follow** without rework. **UI is a later phase** — this
plan covers data model, DB, mappers, DAO, repository, services, and tests, keeping call-site churn
minimal so the app still compiles and the existing install/deinstall UI keeps working untouched.

---

## 1. What "archived" means in this design

- A component's lifecycle is the ordered list of its `Installation` events. State is **derived from the
  latest event** — exactly how [`Component.bikeAt`](lib/models/component.dart#L36) already works.
- **Archived ⇔ the latest event is an `Archival`.** Archiving = append one `Archival` event at the
  retire date (which also closes the last on-bike window). Un-archiving = **append** a `Deinstallation`
  event so the component returns to the parts-bin. The timeline is **append-only**: the archived period
  stays visible in history rather than being erased.
- For Strava stat summation, `Archival` behaves **identically to a deinstall**: it carries no bike, so
  it accrues nothing and only bounds the previous window. **The stats SQL needs no change** (§3.5).
- Archived components stay in the in-memory cache (analysis still reads them); they are hidden only at
  the presentation/filter layer.

### Key simplifications vs. the design report
- **No `Components` table change, no component-model archive field, no `archivedAt`.** Archive lives
  entirely in the installation timeline.
- **No `Component` JSON version bump.** Archive state rides inside the installation JSON as an additive
  field, so old and new app versions stay mutually compatible (§3.8).
- **No Strava SQL change.** (Feature #2 will need it; Feature #1 does not.)

---

## 2. Locked design decisions

| # | Decision | Rationale |
|---|---|---|
| D1 | Sealed `Installation` with subclasses `BikeInstallation` / `Deinstallation` / `Archival`. `ComponentInstallation` subclass is **reserved for Feature #2** (not added now). | User-chosen Approach A; makes "archived + installed" unrepresentable; codebase already uses sealed + pattern matching. |
| D2 | Persist a `parentType` discriminator column on `installations`: enum `{bike, none, archived}` (`component` reserved for F2). Keep the existing `parent` text column as the target id (bike id, or null). | Distinguishes archived from deinstalled (both have `parent = null`); forward-compatible with F2. |
| D3 | Add stable `id` + `componentId` to the `Installation` **model** (they already exist on the table). Stop regenerating ids on every save. | The `ComponentInstallation` refactor; removes id churn; needed for F2. |
| D4 | Keep a backward-compatible **unnamed factory** `Installation({parent, …})`, a base `copyWith`, and a `parent` getter, so existing construction/read sites compile unchanged. | Minimizes churn; lets the install/deinstall UI stay untouched until its phase. |
| D5 | Retire the `ComponentInstallation` **helper** (app_repository.dart) in favour of a slim timeline-view type based on the enriched `Installation`. | Frees the `ComponentInstallation` name for F2; the user asked to fold the helper in. |
| D6 | Archiving auto-handled as appending `Archival`; no separate `archivedAt`. | The event's timestamp *is* the retire date (correct even when archiving a long-deinstalled part). |

---

## 3. Implementation steps (dependency order)

### 3.1 Data model — sealed `Installation` ([installation.dart](lib/models/installation.dart))

Replace the single class with a sealed hierarchy. Sketch:

```dart
enum InstallationParentType { bike, none, archived } // 'component' reserved for Feature #2

sealed class Installation {
  final String id;
  final String componentId;     // owner; normalised at persist time (§3.4/3.6)
  final DateTime dateTimeUTC;
  final DateTime dateTimeLocal;

  Installation._({String? id, String? componentId,
                  required DateTime dateTimeUTC, required this.dateTimeLocal})
      : id = id ?? const Uuid().v4(),
        componentId = componentId ?? '',
        dateTimeUTC = dateTimeUTC.toUtc();

  /// Immediate target id — the **bike** for Feature #1 (null when off a bike).
  /// (Feature #2 will let this be a parent component id.)
  String? get parent => switch (this) { BikeInstallation b => b.bikeId, _ => null };

  InstallationParentType get parentType => switch (this) {
        BikeInstallation _ => InstallationParentType.bike,
        Deinstallation _   => InstallationParentType.none,
        Archival _         => InstallationParentType.archived,
      };

  bool get isFromBeginning => dateTimeUTC.millisecondsSinceEpoch == 0;

  // Backward-compatible: legacy `Installation(parent: bikeId)` keeps working.
  factory Installation({String? parent, String? id, String? componentId,
                        required DateTime dateTimeUTC, required DateTime dateTimeLocal}) =>
      parent == null
          ? Deinstallation(id: id, componentId: componentId, dateTimeUTC: dateTimeUTC, dateTimeLocal: dateTimeLocal)
          : BikeInstallation(bikeId: parent, id: id, componentId: componentId, dateTimeUTC: dateTimeUTC, dateTimeLocal: dateTimeLocal);

  factory Installation.sinceBeginning({String? parent, String? id, String? componentId}) =>
      Installation(parent: parent, id: id, componentId: componentId,
          dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          dateTimeLocal: DateTime.fromMillisecondsSinceEpoch(0));

  /// Retarget when `parent` is passed (picks subtype by null-ness — drops Archival,
  /// which is intended); otherwise preserves the subtype and changes date/id/componentId.
  Installation copyWith({Object? parent = _sentinel, Object? id = _sentinel,
      Object? componentId = _sentinel, Object? dateTimeUTC = _sentinel, Object? dateTimeLocal = _sentinel}) { … }

  Map<String, dynamic> toJson();                      // §3.8
  factory Installation.fromJson(Map<String, dynamic> json, {String? componentId}); // §3.8
  // ==/hashCode include id, componentId, parentType, dates.
}

class BikeInstallation extends Installation {
  final String bikeId;
  BikeInstallation({required this.bikeId, super.id, super.componentId,
      required super.dateTimeUTC, required super.dateTimeLocal}) : super._();
}
class Deinstallation extends Installation {
  Deinstallation({super.id, super.componentId,
      required super.dateTimeUTC, required super.dateTimeLocal}) : super._();
}
class Archival extends Installation {           // retired — Feature #1
  Archival({super.id, super.componentId,
      required super.dateTimeUTC, required super.dateTimeLocal}) : super._();
}
```

Because of the factory + base `copyWith` + `parent` getter (D4), these existing sites compile
**unchanged**: [set_installation_timeline.dart:56/234/352](lib/widgets/set_installation_timeline.dart#L352),
[component_page.dart:94/96/628](lib/pages/component_page.dart#L94),
[component_actions.dart:88/100](lib/utils/component_actions.dart#L88), all `.parent` reads.

**`component.dart` touch-ups:**
- [`bikeAt`](lib/models/component.dart#L50) returns `result?.parent` — still correct (`Archival`/`Deinstallation` → null).
- [`copyWithNewInstallation`](lib/models/component.dart#L101) and the v1 [`fromJson`](lib/models/component.dart#L221) pass `componentId: id` into the installation factory.
- Add derived getters: `bool get isArchived => _latest is Archival;` and `bool get isDeinstalled => _latest is Deinstallation;` (`_latest` = last by `dateTimeUTC`).

### 3.2 DB table + migration ([installations.dart](lib/database/tables/installations.dart), [app_database.dart](lib/database/app_database.dart))

Add the discriminator column (NOT NULL + default so `addColumn` works on existing rows):

```dart
// installations.dart
TextColumn get parentType => text()
    .map(const EnumNameConverter(InstallationParentType.values))
    .withDefault(const Constant('bike'))();
```

Bump `schemaVersion` **8 → 9** and add the step:

```dart
if (from < 9) {
  await m.addColumn(installations, installations.parentType);   // existing rows default to 'bike'
  // A non-null parent was always a bike; null means deinstalled. No archived rows pre-exist.
  await customStatement("UPDATE installations SET parent_type = 'none' WHERE parent IS NULL");
}
```

This is additive and lossless (mirrors the v8 `images` add). The `Components` table is **untouched**.

### 3.3 Mappers ([mappers.dart](lib/database/mappers.dart))

- `InstallationDbMapper.toModel()` — switch on `parentType` to build the subtype, carrying `id`/`componentId`:
  ```dart
  Installation toModel() => switch (parentType) {
    InstallationParentType.bike =>
        BikeInstallation(id: id, componentId: componentId, bikeId: parent ?? '', dateTimeUTC: _utc(dateTimeUTC), dateTimeLocal: dateTimeLocal),
    InstallationParentType.none =>
        Deinstallation(id: id, componentId: componentId, dateTimeUTC: _utc(dateTimeUTC), dateTimeLocal: dateTimeLocal),
    InstallationParentType.archived =>
        Archival(id: id, componentId: componentId, dateTimeUTC: _utc(dateTimeUTC), dateTimeLocal: dateTimeLocal),
  };
  ```
  Defensive: a `bike` row with null `parent` → fall back to `Deinstallation`.
- `InstallationMapper.toCompanion()` — drop the `{id, componentId}` params (model carries them now); set `parent` (bikeId or null) and `parentType` from the subtype.

### 3.4 DAO — stable installation persistence ([components_dao.dart](lib/database/daos/components_dao.dart))

- `watchAllComponentsWithData` — **no WHERE change** (archived components must stay loaded). The join already reads full installation rows; the mapper handles `parentType`.
- `insertComponentWithData` / `updateComponentWithData` — switch the installation write from
  *delete-all + re-insert with freshly generated ids* to a **keyed upsert + delete-missing** using the
  model's stable ids:
  ```dart
  // upsert each incoming installation; then delete rows for this component
  // whose id is not in the incoming set.
  ```
  (A simpler acceptable variant: keep transactional replace but pass the model's stable ids instead of `Uuid().v4()`.)

### 3.5 Strava stats — no change required ([strava_dao.dart](lib/database/daos/strava_dao.dart))

`watchComponentStats` / `getComponentStatsAt` join `installations i ON b.id = i.parent`. `Archival`
rows have `parent = null` ⇒ they don't join a bike (accrue nothing) but **do** bound the previous
window via the `MIN(next_event)` subquery — identical to a deinstall. ✔
**Optional hardening (forward-compat for F2):** add `AND i.parent_type = 'bike'` to the join to make
intent explicit before component-typed parents exist. Not required for Feature #1.

### 3.6 Repository ([app_repository.dart](lib/repositories/app_repository.dart))

- **Persist normalization:** in [`addComponent`](lib/repositories/app_repository.dart#L1111) /
  [`editComponent`](lib/repositories/app_repository.dart#L1143), map installations through
  `inst.copyWith(componentId: updated.id)` before `toCompanion()` (drop the `Uuid().v4()` injection).
- **Archive actions:**
  ```dart
  Future<void> archiveComponent(Component c, {DateTime? at}) {
    final when = (at ?? DateTime.now());
    final ev = Archival(componentId: c.id, dateTimeUTC: when.toUtc(), dateTimeLocal: when);
    return editComponent(c.copyWith(installations: [...c.installations, ev]));
  }
  Future<void> unarchiveComponent(Component c, {DateTime? at}) {
    // Append-only: keep the Archival in history; return to the parts-bin with a fresh
    // Deinstallation guaranteed to be the new latest event.
    var when = at ?? DateTime.now();
    final latestUtc = c.installations
        .map((i) => i.dateTimeUTC)
        .fold<DateTime?>(null, (m, d) => m == null || d.isAfter(m) ? d : m);
    if (latestUtc != null && !when.toUtc().isAfter(latestUtc)) {
      when = latestUtc.add(const Duration(seconds: 1)).toLocal();
    }
    final ev = Deinstallation(componentId: c.id, dateTimeUTC: when.toUtc(), dateTimeLocal: when);
    return editComponent(c.copyWith(installations: [...c.installations, ev]));
  }
  ```
  Append-only un-archive means an `Archival` can be immediately followed by a `Deinstallation`; the
  timeline-editor validation must become type-aware about this (UI phase, §7).
  `editComponent` already detects the installation-list change and heals task snapshots via
  `statsInputsChanged` → `refreshTaskEntrySnapshots`. ✔
- **Surfacing:** add `Map<String, Component> get archivedComponents => { for (c in _components.values) if (c.isArchived) c.id: c };`
- **Hide from primary list:** in [`_filterComponents`](lib/repositories/app_repository.dart#L511) add `&& !c.isArchived` (archived already have `bike == null`, so they're already excluded when a bike is selected; this covers the no-bike-selected case).
- **Task rules:** in [`_filterTaskRules`](lib/repositories/app_repository.dart#L549) drop component-linked rules whose component `isArchived` (don't nag maintenance on a retired/sold part). **Confirmed in scope for this phase.** Note this also drops them from `_filteredOpenTaskRules`/`openTaskRules` counts; verify the open-task badge math.

### 3.7 Retire the `ComponentInstallation` helper (D5)

Replace the helper ([app_repository.dart:1344](lib/repositories/app_repository.dart#L1344)) with a slim
timeline-view type (e.g. `InstallationTimelineEntry`) built from the enriched `Installation`:
fields `installation`, `component`, `originBikeId`, `isInitial`; `label`/`shortLabel` getters extended
with an `Archival` case ("Archived …"). Update:
- [`_filterInstallations`](lib/repositories/app_repository.dart#L624) + the `_filteredInstallations` field/getter to the new type.
- [timeline_entry.dart](lib/models/timeline_entry.dart#L33) `InstallationEntry` to wrap the new type.
- Consumers (mechanical rename + `.parent`→`.parent` unchanged): [installation_list_tile.dart](lib/widgets/items/installation_list_tile.dart), [installation_sheet.dart](lib/widgets/sheets/installation_sheet.dart), [display_installation_timeline.dart](lib/widgets/display_installation_timeline.dart), [calendar_page.dart](lib/pages/calendar_page.dart).

This is mechanical (no new visuals) and frees `ComponentInstallation` for Feature #2.
*(If minimizing churn now is preferred, this rename can be deferred to the UI phase — but doing it now is what the user requested and avoids the F2 name clash.)*

### 3.8 JSON & import/export back-compat

**`Installation.toJson`** — write the new authoritative `type` **and** keep a legacy `parent` mirror so
older app builds still place the component on the right bike:
```json
{ "type": "bike", "id": "...", "componentId": "...", "parent": "<bikeId>",
  "dateTimeUTC": "...", "dateTimeLocal": "..." }      // Deinstalled/Archival: "parent": null
```

**`Installation.fromJson`** — accept both shapes:
- No `type` key (legacy) ⇒ use `parent`: non-null → `BikeInstallation`, null → `Deinstallation`.
- `type` present ⇒ dispatch to the subtype (`archived` → `Archival`).
- Synthesize `id` if absent; fall back `componentId` to the value passed by `Component.fromJson`.

**No `Component` JSON version bump.** Keep writing version `4`; the installation `type` field is purely
additive. Old builds parse installations via their `parent` (archived degrades gracefully to
deinstalled); new builds read `type`. This preserves **both** forward and backward compatibility and
avoids the `default: throw` in [`Component.fromJson`](lib/models/component.dart#L267) rejecting new
backups on older app versions.

**[database_migration_service.dart:66](lib/services/database_migration_service.dart#L66)** — replace
`installation.toCompanion(id: Uuid().v4(), componentId: component.id)` with
`installation.copyWith(componentId: component.id).toCompanion()` (ids now model-owned; legacy imports
still synthesize via the constructor default).

**[data_export_service.dart](lib/services/data_export_service.dart)** — unaffected (calls `i.toModel()`
then `.toJson()`); just verify round-trip in tests.

---

## 4. Migration & backward-compatibility tests

**4.1 Add `test/database/installations_parent_type_migration_test.dart`** (mirror
[setups_images_migration_test.dart](test/database/setups_images_migration_test.dart)):
create a current db, `ALTER TABLE installations DROP COLUMN parent_type` to simulate v8, seed rows
(one with `parent='b1'`, one with `parent=NULL`), run the v9 step, then assert `parent_type` exists and
backfilled to `'bike'` / `'none'` respectively.

**4.2 Extend [migration_upgrade_paths_test.dart](test/database/migration_upgrade_paths_test.dart):**
- In `reshapeToVersion`, add (newest-first): `if (version < 9) ALTER TABLE installations DROP COLUMN parent_type;`
- Seed an installation row alongside the setup (FKs are already off).
- Extend the loop to `[1,2,3,4,5,6,7,8]`.
- Assert `columnNames('installations')` contains `parent_type` and the seeded rows backfilled correctly after upgrade from every entry point.

**4.3 JSON round-trip / legacy parse** (extend [file_import_test.dart](test/utils/file_import_test.dart) and/or [mappers_test.dart](test/database/mappers_test.dart)):
- Legacy component JSON (installations with `parent` only, no `type`) → `BikeInstallation`/`Deinstallation`.
- New JSON with an `Archival` → `toJson`→`fromJson` preserves `Archival` (and writes `parent: null`).
- DB round-trip: `InstallationDb(parentType: archived)` ↔ `Archival` via the mappers.

---

## 5. Other tests to add / update

- **[component_test.dart](test/models/component_test.dart)** — keeps passing via the `Installation(parent:)` factory; add cases for `isArchived`/`isDeinstalled` and `bikeAt` after an `Archival`.
- **[app_repository_test.dart](test/repositories/app_repository_test.dart)** — `archiveComponent` (appends `Archival`, `isArchived` true); `unarchiveComponent` **appends** a `Deinstallation` (the `Archival` stays in `installations`, latest event becomes `Deinstallation`, `isArchived` false); archived excluded from `filteredComponents`, present in `archivedComponents`; component-linked task rule hidden when archived (and removed from `openTaskRules`).
- **[component_stats_test.dart](test/database/component_stats_test.dart)** — archiving a component closes its on-bike window exactly like a deinstall (no stat change vs. the deinstall baseline).
- **[trash_test.dart](test/models/trash_test.dart)** — archived + soft-delete compose (delete an archived component → trash; restore → still archived).
- **[daos_test.dart](test/database/daos_test.dart)** — installation upsert keeps stable ids across an edit (no churn).
- **[setup_resolution_service_test.dart](test/services/setup_resolution_service_test.dart)** — archived components still resolve historical adjustments (they remain in the cache).
- Mechanical compile updates: [set_installation_timeline_test.dart](test/widgets/set_installation_timeline_test.dart), [installation_sheet_test.dart](test/widgets/installation_sheet_test.dart), [replace_component_test.dart](test/widgets/replace_component_test.dart), [component_details_page_test.dart](test/pages/details/component_details_page_test.dart) (helper rename).

---

## 6. Build order & checkpoints

1. **Model** (§3.1) — sealed `Installation` + `component.dart` touch-ups. *(Checkpoint: `flutter test test/models/component_test.dart`.)*
2. **Table + migration** (§3.2) → run `flutter pub run build_runner build` (regenerates `app_database.g.dart`).
3. **Mappers + DAO** (§3.3–3.4) → `build_runner` if needed.
4. **Repository** (§3.6) + **helper retirement** (§3.7) — fix any remaining compile errors from the rename.
5. **JSON + services** (§3.8).
6. **Migration tests** (§4) → `flutter test test/database/`.
7. **Remaining tests** (§5) → `flutter test`.

Run `build_runner build` after every table/converter change. Keep the tree compiling at each step
(the factory/`copyWith`/`parent` shims mean the UI files keep building).

---

## 7. UI follow-up (deferred — separate plan after this lands)

- Archive / un-archive action on the component (button + confirm), choosing the retire date.
- An "Archived" section/view sourced from `archivedComponents`.
- `set_installation_timeline.dart`: render an `Archival` entry distinctly; make the off-bike
  "consecutive deinstallation" validation **type-aware** — an `Archival` followed by a `Deinstallation`
  is the valid append-only un-archive sequence; an `Archival` can't be "From beginning".
- `replace_component.dart`: exclude archived from the "existing deinstalled" picker (only `Deinstallation`).
- Timeline/calendar styling for the `Archival` event.

---

## 8. Risks & open questions

- **Equality change:** `Installation.==` now includes `id`/`componentId`. DB round-trips preserve them,
  so change-detection in `editComponent` stays stable; freshly built events compare unequal (correct).
- **`componentId` defaulting to `''`** for UI-constructed events until persist-normalization — verify
  the normalization in `addComponent`/`editComponent` covers every write path.
- **Helper retirement breadth (§3.7):** touches several widgets mechanically. Acceptable; flagged as
  deferrable if we want an even smaller first commit.
- **Resolved decisions:** archived-task-rule filtering is **in scope** (§3.6); un-archive is
  **append-only** — it adds a `Deinstallation` and never deletes the `Archival` (§1/§3.6).
