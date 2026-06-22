# Setup Photos — Implementation Plan

Allow a user to **optionally** attach **multiple photos** to a `Setup`, either picked
from the gallery or captured with the camera. Photos are shown on the setup add/edit
page and on the read-only setup detail view, with a full-screen viewer on tap. The
whole feature is **gated behind a debug-only feature flag** and is not shipped to
production yet.

### Phasing

- **Phase 1 (this plan, §0–§11):** photos attached to a **`Setup`** — a per-setup album.
- **Phase 2 (outlook, §12):** an **`ImageAdjustment`** type — photos as diffable
  per-component *setting* values (e.g. cockpit configuration, saddle-rail position),
  flowing through the existing change-tracking engine.

Phase 1 is built so Phase 2 **reuses its whole infrastructure** (the shared `images/`
store, `ImageStorageService`, photo strip/viewer widgets, missing-file handling, ZIP
bundle). The two are deliberately **decoupled** behind separate flags, so we can ship
either alone or both — see §12.

## Decisions (confirmed with user)

| Topic | Decision |
|---|---|
| Feature gating | **Debug-only flag** `enableSetupImages` on `AppSettings`, default `false`, toggle visible only when `kDebugMode`. Not in production builds yet. |
| Storage strategy | **On-device only** — image files in the app documents directory, DB stores only filenames. Not auto-included in JSON backup / Google Drive sync. |
| Quantity / quality | **Unlimited photos, original quality** — no cap, no compression. |
| Missing files | Show an **error placeholder** tile when a referenced file no longer exists (e.g. after reinstall/restore). |
| Reordering | **Nice-to-have** — include if low effort (it is; see §8). |
| List tiles | Show a small **image icon + count** when a setup has ≥1 photo. **No preview** thumbnail in the list. |
| Where shown | Setup add/edit page + setup detail view (full-screen viewer); icon+count in list rows. |
| Export/transfer | See §7 — recommendation: **ZIP bundle**. |

### Consequence of "on-device only" — surfaced to the user in-app

The app's backup/restore + Google Drive sync pipeline is **JSON-based**
(`DataExportService.backupDatabaseToJson` → `FileExport`), and we deliberately do **not**
embed image bytes in the routine backup. So photos:

- **NOT** included in the automatic local/Drive JSON backup,
- **NOT** restored on reinstall (files are removed when the app is uninstalled),
- **NOT** synced to a second device automatically.

We store only a relative **filename** in the DB. After a restore, those filenames may
point at files that no longer exist → the UI must show a **placeholder**, never crash.
This tradeoff is acceptable per the decisions above and is mitigated by the explicit
export feature (§7). A **warning is shown next to the settings toggle and on the setup
photo UI** so the user understands photos are local-only.

---

## 0. Feature gating (debug-only flag)

### `AppSettings` — [lib/models/app_settings.dart](../lib/models/app_settings.dart)

Add a persisted bool following the exact pattern of the other flags (e.g.
`_enableSetupTags`):

1. Field: `bool _enableSetupImages = false;`
2. Getter: `bool get enableSetupImages => _enableSetupImages;`
3. Setter: standard guard + `notifyListeners()` + `_persistBool('enableSetupImages', …)`.
4. Load: in `loadAppSettings()`,
   `_enableSetupImages = prefs.getBool('${_kPrefix}enableSetupImages') ?? _enableSetupImages;`
5. Do **not** add it to `_legacyDefaults` (that map is frozen history; new flags are not
   added there).

### Toggle UI — [lib/pages/settings/features_page.dart](../lib/pages/settings/features_page.dart)

> Placement note: the user asked for `app_settings_page.dart`, but all feature toggles —
> including the existing `if (kDebugMode)` ones (Profile, Rating, Strava, MapBox, Task
> Interval/Delay) — already live in **`features_page.dart`**, which is the "Features"
> sub-page reached from `app_settings_page.dart`. Putting it there keeps the pattern
> consistent. (If you'd rather it sit directly on the top-level settings page, say so.)

Add, wrapped in `if (kDebugMode)`, a `ListTile` + `appSettingsRadioGroupSheet<bool>`
exactly like the other entries:

```dart
if (kDebugMode)
  ListTile(
    leading: const Icon(Icons.photo_library_outlined),
    title: const Text("Setup Images"),
    subtitle: _offOnOptionWidgets[appSettings.enableSetupImages] ?? const Text("-"),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
    onTap: () => appSettingsRadioGroupSheet<bool>(
      context: context,
      title: "Setup Images",
      value: appSettings.enableSetupImages,
      optionWidgets: _offOnOptionWidgets,
      onChanged: (bool? newValue) {
        if (newValue == null) return;
        appSettings.enableSetupImages = newValue;
        Navigator.pop(context);
      },
      // The sheet's infoText is where the local-only warning lives:
      infoText: 'Attach photos to setups. WARNING: photos are stored only on this '
          'device. They are NOT included in cloud/Drive backups and will be lost on '
          'reinstall or when restoring from a backup. Use “Export Photos” to move them '
          'to a new device.',
    ),
  ),
```

Every photo entry point in the app (add/edit strip, detail view, list icon) is wrapped
in `if (appSettings.enableSetupImages) …`, so flipping the flag off hides all UI while
leaving stored data intact.

---

## 1. Where are the photos stored?

Reuse the app documents directory pattern already used for the SQLite DB and JSON
backups (`getApplicationDocumentsDirectory()` in
[app_database.dart](../lib/database/app_database.dart#L134-L140),
[file_export.dart](../lib/utils/file_export.dart#L72-L73)).

```
<app documents dir>/
  bike_setup_tracker.sqlite
  backup/                      # existing JSON backups
  images/                      # NEW — shared image store for ALL objects
    <uuid>.jpg
```

**One shared `images/` folder, flat, UUID filenames.** Photos for setups (and future
objects — bikes, components, …) all live here. Because filenames are random UUIDs,
there are no collisions and no need for per-object subfolders; the DB row is the only
thing that says which object a file belongs to. This keeps import/export/sync to a
**single directory** regardless of how many object types gain photos later.

**Store the *filename* only (e.g. `9f3c….jpg`), never the absolute path** — on iOS the
app-container path changes between launches/updates, so a persisted absolute path
breaks. At display time resolve `…/images/<filename>`.

New **`ImageStorageService`** (`lib/services/image_storage_service.dart`) — a generic,
object-agnostic owner of all image file I/O (named generically on purpose so setups,
bikes, components, etc. can reuse it):

- `Future<String> importImage(XFile picked)` — copy into `images/` with a fresh
  `Uuid().v4()` + original extension; return the filename.
- `Future<String> copyExisting(String filename)` — duplicate a file under a new name
  (used by setup duplicate/restore so two objects never share a file).
- `File resolveSync(String dir, String filename)` / `Future<File> resolve(String)` —
  absolute `File` for display.
- `Future<bool> exists(String filename)` — for placeholder logic.
- `Future<void> deleteImages(Iterable<String>)` — best-effort delete (ignore missing).
- `Future<void> ensureDir()` — create the `images/` folder if absent.

---

## 2. Additional packages

| Package | Purpose | Notes |
|---|---|---|
| `image_picker: ^1.1.2` | Pick from gallery **and** capture from camera | Official plugin (`pickImage`, `pickMultiImage`). |
| `archive: ^4.0.2` | ZIP export/import for device transfer (§7) | Pure-Dart; only if we go with the ZIP option. |

- **Full-screen viewer:** no package needed — `PageView` + `InteractiveViewer` (built
  in) give swipe + pan/zoom. (`photo_view` is an optional future polish.)
- **Reordering:** `reorderables: ^0.6.0` is **already a dependency**, or use the
  built-in `ReorderableListView` — no new package.
- Already present and reused: `path_provider`, `path`, `uuid`, `share_plus`,
  `file_picker`.

### Platform permission config

- **iOS** — `ios/Runner/Info.plist` **already declares** `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription`, but their current text was written for `file_picker`
  and literally says *"This app does not capture photos or videos."* Once we add real
  capture/attachment this becomes a **misleading purpose string** → likely App Store
  rejection. **Rewrite both** to describe the actual use (see §11). No new keys needed —
  `image_picker`'s gallery path uses `PHPickerViewController` (out-of-process, no library
  permission prompt), and camera uses `NSCameraUsageDescription`.
- **Android** — **do not add `CAMERA`.** `image_picker` reads the gallery via the
  Android 13+ **Photo Picker** (no `READ_MEDIA_IMAGES`) and captures via an
  `ACTION_IMAGE_CAPTURE` intent handled by the system camera app, so **no extra
  manifest permission is required**. Declaring `CAMERA` would add an
  `android.hardware.camera` requirement and filter the app off camera-less devices on
  Play — avoid it. (If a future need forces declaring `CAMERA`, also add
  `<uses-feature android:name="android.hardware.camera" android:required="false"/>`.)

---

## 3. How is this stored in the `Setup` model?

[lib/models/setup.dart](../lib/models/setup.dart) — add an ordered, non-nullable list of
filenames (empty = no photos; **order is the user's chosen photo order**, so a `List`,
not a `Set`):

```dart
final List<String> photos; // relative filenames in images/, ordered
```

1. **Field + constructor** — `this.photos` defaulting to `const []` (optional, backward
   compatible).
2. **`toJson`** — bump `'version'` `4 → 5`; add `'photos': photos`.
3. **`fromJson`** — accept version 5 in the existing `case`; read
   `(json['photos'] as List?)?.map((e) => e as String).toList() ?? <String>[]` so older
   v1–v4 backups load as empty.
4. **`copyWith`** — add `Object? photos = const _Sentinel()` (sentinel pattern).
5. **`deepCopy`** (duplicate/restore) — copy the list; the repository's duplicate flow
   calls `ImageStorageService.copyExisting` for each filename so files aren't shared.
6. **`==` / `hashCode`** — add `listEquals(photos, other.photos)` /
   `Object.hashAll(photos)`.

---

## 4. How is this stored in the Drift database?

### Table — [lib/database/tables/setups.dart](../lib/database/tables/setups.dart)

Photo **order matters**, so we need a list-preserving converter. `tags` uses
`StringListConverter`; confirm whether it round-trips a `List` (ordered) or a `Set`. If
it's `Set`-typed, add a sibling `StringListOrderedConverter` (trivial JSON
encode/decode of `List<String>`). Then:

```dart
TextColumn get photos =>
    text().map(const StringListOrderedConverter()).withDefault(const Constant('[]'))();
```

### Schema migration — [lib/database/app_database.dart](../lib/database/app_database.dart#L74-L92)

- Bump `schemaVersion` `3 → 4`.
- In `onUpgrade`:

```dart
if (from < 4) {
  await m.addColumn(setups, setups.photos);
}
```

Then regenerate: `flutter pub run build_runner build --delete-conflicting-outputs`.

### Mappers — [lib/database/mappers.dart](../lib/database/mappers.dart#L310-L373)

- `Setup.toCompanion()` → add `photos: Value<List<String>>(photos)`.
- `SetupDbMapper.toModel()` → add `photos: photos`.

No DAO change needed: `insertSetup`/`updateSetup` write the full `SetupsCompanion` via
`replace`, and `watchAllSetupsWithValues` already maps `toModel` — photos flow through.

---

## 5. UI — display, viewer, missing-file placeholder

Photos are local files → `Image.file(File(absolutePath))`. Resolve the documents dir
once per page (cache it) to avoid a `FutureBuilder` per thumbnail.

### Missing-file handling (required)

Every photo tile uses `Image.file(..., errorBuilder: …)` returning a **placeholder**
(grey box, broken-image icon, optional filename). This covers post-restore dangling
references and any deleted file. Optionally, a one-time `ImageStorageService.exists`
pre-check can mark a photo as missing to also disable share/zoom for it.

### New widgets

1. **`ImageStrip`** (`lib/widgets/image_strip.dart`) — horizontal list of
   square thumbnails (`Image.file`, `BoxFit.cover`, rounded, `errorBuilder`
   placeholder). Tap → full-screen viewer at that index. In **edit mode**: delete (✕)
   badge per tile + trailing **"＋ Add photo"** tile opening a Camera/Gallery bottom
   sheet (same `showModalBottomSheet` style as `lib/widgets/sheets/`). Edit mode also
   enables **drag-to-reorder** (§8).
2. **`ImageViewer`** (`lib/widgets/image_viewer.dart`) — full-screen route:
   `PageView` of `InteractiveViewer(child: Image.file(...))` with the same placeholder
   on error, close button, optional share via `ShareService`.

### Add/edit integration — [lib/pages/setup_page.dart](../lib/pages/setup_page.dart)

- State: `List<String> _photos = [...?widget.setup?.photos]` + `_initialPhotos` for
  dirty-tracking.
- `_addPhotos()` → `ImagePicker().pickMultiImage()` / `.pickImage(source: camera)`; for
  each `XFile` `await ImageStorageService.importImage(x)`; append; `setState` +
  `_changeListener()`.
- remove/reorder handlers update `_photos`; `_changeListener()`.
- Extend `_changeListener()` with `!listEquals(_photos, _initialPhotos)`.
- Render `if (appSettings.enableSetupImages) ImageStrip(mode: edit, …)` in the
  header `Column` near
  [setup_page.dart:1016-1019](../lib/pages/setup_page.dart#L1016-L1019).
- In `_saveSetup()` ([setup_page.dart:584-629](../lib/pages/setup_page.dart#L584-L629))
  pass `photos: _photos` into the returned `Setup(...)`.

### Read-only detail — [lib/pages/details/setup_details_page.dart](../lib/pages/details/setup_details_page.dart)

- `if (appSettings.enableSetupImages && setup.photos.isNotEmpty)
  ImageStrip(mode: view, …)` → tap opens `ImageViewer`.

### List tiles — icon + count (no preview)

[lib/widgets/items/setup_list_card.dart](../lib/widgets/items/setup_list_card.dart) — in
the subtitle `Wrap` (alongside place/weather/tags rows, ~line 190), add:

```dart
if (appSettings.enableSetupImages && setup.photos.isNotEmpty)
  Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    spacing: 2,
    children: [
      Icon(Icons.photo_library_outlined, size: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      Text('${setup.photos.length}',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13)),
    ],
  ),
```

No file I/O here (just `photos.length`), so the list stays cheap.

---

## 6. File lifecycle & orphan cleanup

Setups use **soft-delete** (`SoftDeletableDaoMixin`,
[setups_dao.dart:17](../lib/database/daos/setups_dao.dart#L17)) — a soft-deleted row (and
its filenames) still exists, so **do not delete files on soft delete**.

- **Edit, photo removed + saved** → after a successful save, delete files in
  `_initialPhotos` but not in saved `_photos`. **Cancel** deletes nothing.
- **Hard delete / purge** (permanently removing a soft-deleted setup, e.g. empty trash)
  → delete its files. Hook into the purge flow near `_deletedSetups`.
- **Duplicate / restore** → `copyExisting` each file to a new filename.
- **Startup sweep (optional)** → delete files in `images/` not referenced by **any**
  object row (covers crashes mid-edit). Once other object types use `images/`, the sweep
  must check all of them before deleting, so a filename is removed only when no object
  references it. Cheap, self-healing; can be deferred.

---

## 7. Export for device transfer — ZIP vs base64 JSON (effort)

Goal: let a user move their photos (which are otherwise local-only) to a new device.

### Option A — ZIP bundle (recommended)

Bundle the JSON export **and** the whole `images/` folder into one `.zip`, shared via
`share_plus`; import picks a `.zip`, restores the JSON, and unzips images into
`images/`. Because the DB already stores filenames that match the archived files, links
resolve immediately after import — and because `images/` is shared, this bundle covers
every object type's photos at once, not just setups.

- **Work:** add `archive` package; an `ImageBundleExportService` to build the zip
  (`getApplicationDocumentsDirectory()` → read `images/*` + the JSON string →
  `ZipEncoder`) and to import (decode zip → write files + feed JSON into the existing
  import path); two buttons ("Export Photos / Full Bundle", "Import Bundle"); reuse
  `ShareService` / `file_picker`.
- **Effort:** ~Medium (½–1 day). Mostly plumbing; no model/schema change.
- **Pros:** efficient (binary, ~no bloat), photos stay real files, single file to
  transfer, doesn't touch the routine backup. **Cons:** new dependency; large libraries
  load fully into memory while zipping (fine for typical sizes, not for GBs).

### Option B — base64 embedded in JSON

Add an **opt-in** flag to `DataExportService.backupDatabaseToJson` that, when set,
inlines each photo as base64 (a side map `photoBlobs: {filename: base64}` or per-setup).
Import decodes and writes files.

- **Work:** no new package (`dart:convert`); extend export/import; gate it so the
  **automatic** backup never embeds blobs (only an explicit "Export with photos").
- **Effort:** ~Medium-low (a few hours), slightly less than A.
- **Pros:** single JSON file, no new dependency, smallest code delta. **Cons:** base64 is
  ~33% larger than binary; big memory spikes and slow encode/decode; risks bloating
  backups if the gating is ever wrong; mixes binary into a human-readable data file.

### Recommendation

For a genuine **device-transfer** feature, **Option A (ZIP bundle)** is the better fit —
efficient and clean, and it naturally carries both data and photos together. Since the
whole feature is debug-gated and experimental right now, **Option B is a valid quick
interim** if you want the smallest possible first cut; we can swap to ZIP later without
touching the data model. Default plan assumes **Option A**.

---

## 8. Reordering (low effort — included)

In edit mode, make `ImageStrip` a horizontal `ReorderableListView` (built-in) or
use the already-present `reorderables` package. `onReorder` mutates `_photos`
(remove/insert) + `_changeListener()`; the saved list order is what persists (the
`List` column preserves order end-to-end). **Effort: ~1–2 h.** No schema/model impact
beyond already using an ordered list.

---

## 9. Touched files summary

**New**
- `lib/services/image_storage_service.dart` — generic image file I/O (shared `images/`).
- `lib/services/image_bundle_export_service.dart` — ZIP bundle export/import (§7A).
- `lib/widgets/image_strip.dart` — thumbnails, add tile, reorder, delete.
- `lib/widgets/image_viewer.dart` — full-screen viewer.
- `lib/database/converters/string_list_ordered_converter.dart` — if `tags` converter is
  `Set`-typed (§4).

**Modified**
- `pubspec.yaml` — `image_picker` (+ `archive` for §7A).
- `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml` — permissions.
- `lib/models/app_settings.dart` — `enableSetupImages` flag (field/getter/setter/load).
- `lib/pages/settings/features_page.dart` — debug-only toggle with local-only warning.
- `lib/models/setup.dart` — `photos` field, json v5, copyWith, ==, hashCode, deepCopy.
- `lib/database/tables/setups.dart` — `photos` column.
- `lib/database/app_database.dart` — schemaVersion 3→4 + `onUpgrade` addColumn.
- `lib/database/mappers.dart` — `toCompanion` + `toModel` include `photos`.
- `lib/pages/setup_page.dart` — photo state, picker, strip, reorder, save wiring.
- `lib/pages/details/setup_details_page.dart` — view-only strip + viewer.
- `lib/widgets/items/setup_list_card.dart` — image icon + count.
- Setup duplicate flow + hard-delete/purge flow — file copy/cleanup hooks.

**Regenerate**: `flutter pub run build_runner build --delete-conflicting-outputs`.

---

## 10. Suggested implementation order

1. `AppSettings.enableSetupImages` + debug toggle in `features_page.dart` (with warning).
2. `pubspec.yaml` deps + platform permission config; `flutter pub get`.
3. Table column + ordered converter + schemaVersion 3→4 migration → `build_runner build`.
4. `Setup` model (field, json v5, copyWith, equality, deepCopy) + mappers.
5. `ImageStorageService` (generic, shared `images/`).
6. `ImageStrip` (incl. reorder + missing-file placeholder) + `ImageViewer`.
7. Wire into `setup_page.dart` (add/edit/save) — all behind `enableSetupImages`.
8. Wire into `setup_details_page.dart` (view) + `setup_list_card.dart` (icon+count).
9. Orphan cleanup on save-edit + hard delete; copy-on-duplicate.
10. ZIP export/import (§7A).
11. Manual test: toggle flag on/off; add (gallery+camera); reorder; remove; full-screen;
    restart app; delete & purge setup; delete a file on disk → placeholder shows;
    export bundle → import on a fresh install → links resolve; verify v1–v4 backups
    still import as empty.

## 11. App Store & Play Store compliance

The app is worldwide, **age 0+**. Adding camera/gallery access has implications on both
stores. Summary first: **no new store-console "entitlements" are needed, the privacy
declarations must be updated, and the age rating should stay 0+** — but the iOS purpose
strings must be fixed and the Play photo-permission policy must be respected.

### Do I need new "rights"/permissions?

| | Gallery pick | Camera capture |
|---|---|---|
| **iOS** | No library permission prompt (uses `PHPickerViewController`). | `NSCameraUsageDescription` (already present — must be **reworded**). |
| **Android** | None — Photo Picker, no `READ_MEDIA_IMAGES`. | None — delegated to system camera app via intent. |

So functionally you only need to **reword the two iOS strings**; Android needs no
manifest change.

### iOS — App Store Connect / Info.plist

- **Info.plist purpose strings (must fix, see §0/§2):** rewrite to truthfully describe
  capture + attachment, e.g.
  - `NSCameraUsageDescription` → *"Allows you to take a photo to attach to a bike setup."*
  - `NSPhotoLibraryUsageDescription` → *"Allows you to attach photos from your library to
    a bike setup."*
  Misleading/placeholder strings are a common rejection reason (Guideline 5.1.1).
- **No App Store Connect toggle** is required to "enable" camera/photos — the purpose
  strings are the mechanism.
- **Privacy nutrition label (App Privacy section):** photos are stored **only on
  device**, never collected or transmitted by us. If you keep it that way, **no new
  "Data Collected" entry is required** (on-device-only data is not "collected" per
  Apple). The OS share/export (§7) is **user-initiated sharing**, which is also not
  "collection." Keep "Photos" out of the collected-data list unless that changes.
- **Privacy manifest (`PrivacyInfo.xcprivacy`):** `image_picker` ships its own manifest;
  ensure the pod is up to date so required-reason API declarations are covered. Our app
  writes images to its own documents dir (no extra reason-API beyond what's already
  declared).
- **Encryption (`ITSAppUsesNonExemptEncryption`):** unchanged — local file copies add no
  new cryptography.

### Android — Google Play Console

- **Manifest:** no change (no `READ_MEDIA_IMAGES`, no `CAMERA`) — so the **Play Photo &
  Video Permissions policy / declaration form does NOT apply.** That policy only triggers
  for apps that request broad `READ_MEDIA_IMAGES/VIDEO`; by using the Photo Picker we are
  explicitly exempt. This is the cleanest path and avoids a policy declaration.
- **Data safety form:** review it. Since photos stay on-device and aren't sent to your
  servers, you can keep "Photos and videos" as **not collected / not shared**. (User-
  initiated export via the share sheet is not "collection.") Only if you later add
  base64/ZIP cloud upload or Firebase Storage would this change.
- **No special Play Console capability** needs enabling for camera/gallery.

### Privacy policy

- Add a short clause: *"Photos you attach to setups are stored only locally on your
  device. They are not uploaded to our servers or shared with third parties. They are
  included only if you explicitly use the export/share feature, and are removed when you
  uninstall the app."*
- Because nothing leaves the device automatically, there's **no new processor/sub-
  processor, no new data-transfer, and no GDPR/CCPA "collection"** to disclose beyond
  that local-storage note.

### Age rating / content (0+)

- **Stays 0+.** The User-Generated-Content rules (Apple Guideline 1.2; Play UGC policy)
  target apps where users **view content created by *other* users** (feeds, communities,
  chat). Here photos are **private to the single user**, never shown to anyone else and
  never aggregated by a backend — so UGC moderation requirements (reporting, blocking,
  moderation) **do not apply**.
- No camera/photo capability by itself raises the age rating. Keep the Apple age rating
  and Google **IARC** questionnaire answers as-is (answer "no" to user-interaction/UGC/
  sharing-of-others'-content questions — sharing *your own* file via the OS sheet is not
  a social feature).
- ⚠️ If the feature ever evolves into sharing photos to a **shared/online space visible to
  other users**, both stores would require UGC safeguards and the age rating would rise
  (Apple typically 17+ without moderation). Not the case for this local-only design.

### Action checklist before shipping this feature to production

1. Reword the two iOS `UsageDescription` strings to reflect real capture/attachment.
2. Confirm Android manifest stays free of `READ_MEDIA_IMAGES` / `CAMERA`.
3. Update the privacy policy with the local-storage clause above.
4. Re-confirm Apple App Privacy + Play Data safety still say photos are **not
   collected** (true for the on-device design).
5. Leave age rating at 0+; re-verify IARC/Apple questionnaires answer "no" to UGC/social.
6. Remember the feature is `kDebugMode`-gated — none of the above is needed until the
   flag is enabled for a production build.

## 12. Phase 2 (outlook): `ImageAdjustment` type — reusing Phase-1 infrastructure

> Not built in Phase 1. Documented so Phase 1 is shaped to make this cheap, and so we can
> later decide to ship **A only, B only, or both**. Kept behind its own flag, decoupled
> from setup photos.

### Concept

Add a new adjustment type so a photo becomes a **first-class, diffable setting value** —
the alternative to a numeric/slider/dropdown input. Because the app already treats an
adjustment's value as "whatever expresses a setting," an image *is* a valid value (e.g.
a photo of the cockpit, saddle-rail position, flip-chip, cable routing, token stack).

- New `AdjustmentType.image` + `ImageAdjustment` (a `part` sealed subtype of `Adjustment`,
  modeled on the minimal `TextAdjustment`). Its value is **filename(s)** in `images/`.
- The value is stored per-setup in `setup_adjustment_values.value` exactly like every
  other value (single TEXT column) — JSON-encode the filename list for multi-image.
- It therefore **flows through the existing diff/inheritance engine**: the previous
  setup's photo is shown alongside the new one in the adjustment row
  (`AdjustmentCompactDisplayList`), and an unchanged photo **carries forward** via
  `SetupResolutionService` — exactly like clicks/PSI today.

### Why it fits the app (vs Phase-1 setup photos)

| Dimension | A · Setup photos (Phase 1) | B · ImageAdjustment (Phase 2) |
|---|---|---|
| Question answered | "How did the bike/session look?" | "What is *this* setting, and how did it change?" |
| README fit | Literal roadmap line ("images to setups"). | Core value prop — per-component settings & change history. |
| Change tracking | None (flat album). | Full diff + inheritance, photo-in-a-row. |
| Organization | Per-setup pile. | Auto-grouped by component/adjustment. |
| UX friction | Zero config — just snap. | Must define an image adjustment on a component first. |
| Cost | Low, isolated. | Higher — touches the adjustment engine. |

### What Phase 1 already gives Phase 2 (reuse)

- **Shared `images/` store** + `ImageStorageService` (import/copy/resolve/exists/delete)
  — object-agnostic on purpose; B uses it unchanged.
- **`ImageStrip` / `ImageViewer`** — already generic (take a `List<String>` + edit
  callbacks), so both A and B render with them unchanged.
- **Missing-file placeholder, `cacheWidth` thumbnails, reorder** — all reused.
- **ZIP bundle export/import** — already archives the whole `images/` folder, so it
  covers B's images automatically; no change needed.
- **Permissions / store compliance (§11)** — identical; already done once.

### What Phase 2 adds (the extra work, kept isolated)

- `ImageAdjustment` model subtype: `isValidValue` (filename string / list), `toJson`,
  `fromJson`, `deepCopy`, `getProperties`, icon.
- Value (de)serialization: extend the mapper `_parseValue(valStr, type)` and
  `Setup.adjustmentValues{To,From}Json` with an `image` case (JSON list ↔ `List<String>`).
- An **input widget** (add/replace/remove photos) for the setup tabs, and a **thumbnail
  cell** in `AdjustmentCompactDisplayList` rendering old→new instead of text.
- Adjustment **creation UI**: add "Image" to the type picker in the component/adjustment
  editor.
- **Reference-counted cleanup:** inheritance means many setups legitimately share one
  filename, so a file is deleted only when **no** setup value references it (the §6
  startup-sweep already generalizes to this — extend it to scan adjustment values).
- Its own gate, e.g. `enableImageAdjustment`, separate from `enableSetupImages`.

### Decoupling / "ship only one" guarantee

- Separate flags, separate columns/tables (`setups.photos` for A vs
  `setup_adjustment_values` rows for B) — neither references the other.
- Only shared code is the **generic image substrate** (`images/`, `ImageStorageService`,
  `ImageStrip`/`ImageViewer`, ZIP bundle). If we drop A, that substrate stays for B (and
  vice-versa); if we drop B, nothing in A depends on it.
- Phase 1 already names the strip/viewer/service generically (`ImageStrip`,
  `ImageViewer`, `ImageStorageService`) rather than setup-specific, so Phase 2 is purely
  additive — no rename/refactor needed when it lands.

---

## 13. Resolved decisions / future work

- **Placement of the toggle — DECIDED:** lives in `features_page.dart`, wrapped in
  `if (kDebugMode)` (matches the existing debug-only toggles). Not on the top-level page.
- **Thumbnail performance — DECIDED: decode-downscaling + built-in cache; NO separate
  thumbnail files.** Rationale and how it works:
  - The concern is **decode RAM, not disk**: a 12 MP photo decoded into a small
    thumbnail costs ~48 MB of memory at full res. With 0–10 images per setup, showing a
    few of these would spike memory and jank.
  - **Fix (one line):** decode at reduced resolution in the strip —
    `Image.file(file, cacheWidth: 300, errorBuilder: …)` (≈2–3× the on-screen thumbnail
    width). The full-screen `ImageViewer` omits `cacheWidth` to show full quality.
  - **In-memory cache is automatic:** Flutter's global `ImageCache` (LRU) already
    avoids re-decoding recently shown images — no code needed.
  - **We do NOT generate separate downscaled `.jpg` thumbnail files.** That only pays off
    for hundreds-of-images grids and would add a resize dependency plus extra
    write/cleanup/lifecycle. Originals stay full quality on disk per the decision.
  - If a future dense gallery ever needs it, on-disk thumbnails are an additive change
    that doesn't touch the data model.
- **Portability without manual export** — base64-in-JSON or Firebase Storage remain
  future options; the filename column stays unchanged.
