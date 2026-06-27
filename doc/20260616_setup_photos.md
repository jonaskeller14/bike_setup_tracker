# Setup Images — Implementation Plan

Allow a user to **optionally** attach **multiple images** to a `Setup`, either picked
from the gallery or captured with the camera. Images are shown on the setup add/edit
page and on the read-only setup detail view, with a full-screen viewer on tap. The
whole feature is **gated behind a debug-only feature flag** and is not shipped to
production yet.

### Phasing

- **Phase 1 (this plan, §0–§11):** images attached to a **`Setup`** — a per-setup album.
- **Phase 2 (outlook, §12):** an **`ImageAdjustment`** type — images as diffable
  per-component *setting* values (e.g. cockpit configuration, saddle-rail position),
  flowing through the existing change-tracking engine.

Phase 1 is built so Phase 2 **reuses its whole infrastructure** (the shared `images/`
store, `ImageStorageService`, image strip/viewer widgets, missing-file handling, ZIP
bundle). The two are deliberately **decoupled** behind separate flags, so we can ship
either alone or both — see §12.

## Decisions (confirmed with user)

| Topic | Decision |
|---|---|
| Feature gating | **Debug-only flag** `enableSetupImages` on `AppSettings`, default `false`, toggle visible only when `kDebugMode`. Not in production builds yet. |
| Storage strategy | **On-device only** — image files in the app documents directory, DB stores only filenames. Not auto-included in JSON backup / Google Drive sync. |
| Quantity / quality | **Unlimited images, original quality** — no cap, no compression. |
| Missing files | Show an **error placeholder** tile when a referenced file no longer exists (e.g. after reinstall/restore). |
| Reordering | **Included** — long-press to start drag. |
| List tiles | Show a small **image icon + count** when a setup has ≥1 image. **No preview** thumbnail in the list. |
| Where shown | Setup add/edit page + setup detail view (full-screen viewer); icon+count in list rows. |
| Export/transfer | See §7 — recommendation: **ZIP bundle**. |

### Consequence of "on-device only" — surfaced to the user in-app

The app's backup/restore + Google Drive sync pipeline is **JSON-based**
(`DataExportService.backupDatabaseToJson` → `FileExport`), and we deliberately do **not**
embed image bytes in the routine backup. So images:

- **NOT** included in the automatic local/Drive JSON backup,
- **NOT** restored on reinstall (files are removed when the app is uninstalled),
- **NOT** synced to a second device automatically.

We store only a relative **filename** in the DB. After a restore, those filenames may
point at files that no longer exist → the UI must show a **placeholder**, never crash.
This tradeoff is acceptable per the decisions above and is mitigated by the explicit
export feature (§7). A **warning is shown next to the settings toggle and on the setup
image UI** so the user understands images are local-only.

---

## Implementation Status

| Section | Status | Notes |
|---|---|---|
| §0 Feature flag + debug toggle | ✅ Done | `enableSetupImages` in `AppSettings`; debug toggle in `features_page.dart` |
| §1 ImageStorageService | ✅ Done | `lib/services/image_storage_service.dart`; added `getImagesPath()` public helper |
| §2 Packages + permissions | ✅ Done | `image_picker ^1.1.2`, `archive ^3.6.1` (downgraded from ^4.0.2 due to `excel` conflict); iOS `Info.plist` reworded |
| §3 Setup model | ✅ Done | `Setup.images` field; JSON v5; `copyWith`, `==`, `hashCode`, `deepCopy` |
| §4 DB table + migration | ✅ Done | `images` column in `setups` table; schema v7 migration; `StringListOrderedConverter`; mappers updated |
| §5 UI — strip + viewer | ✅ Done | `ImageStrip`, `ImageViewer`; "Add image" chip in the Wrap; strip below Wrap (no add tile in strip); long-press reorder; `proxyDecorator` for clean drag ghost |
| §6 File lifecycle / orphan cleanup | ⚠️ Partial | Edit-save orphan cleanup ✅; copy-on-duplicate ✅; hard-delete/purge NOT done; startup sweep NOT done |
| §7 Export — ZIP bundle | ❌ Not done | |
| §8 Reordering | ✅ Done | `ReorderableDelayedDragStartListener`; `proxyDecorator` |
| §9 File summary | ✅ Done | See below |
| §10 Implementation order | ✅ Done (except §7 items) | |
| §11 App Store / Play Store | ✅ Done | iOS strings reworded; Android no manifest changes |
| §12 Phase 2 ImageAdjustment | ❌ Future | Not started |

### Deviation from original plan — UI placement (§5)

The "Add image" button was moved **out of the `ImageStrip` and into the `_wrap()` Wrap**
as a last `ActionChip`. The `ImageStrip` in edit mode now only handles reorder + remove.
This avoids the strip's horizontal scroll conflict with the add action and gives the chip
natural placement alongside other context chips.

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
      infoText: 'Attach images to setups. WARNING: images are stored only on this '
          'device. They are NOT included in cloud/Drive backups and will be lost on '
          'reinstall or when restoring from a backup. Use "Export Images" to move them '
          'to a new device.',
    ),
  ),
```

Every image entry point in the app (add/edit strip, detail view, list icon) is wrapped
in `if (appSettings.enableSetupImages) …`, so flipping the flag off hides all UI while
leaving stored data intact.

---

## 1. Where are the images stored?

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

**One shared `images/` folder, flat, UUID filenames.** Images for setups (and future
objects — bikes, components, …) all live here. Because filenames are random UUIDs,
there are no collisions and no need for per-object subfolders; the DB row is the only
thing that says which object a file belongs to. This keeps import/export/sync to a
**single directory** regardless of how many object types gain images later.

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
- `Future<String> getImagesPath()` — returns the absolute path to the `images/` dir
  (used by pages to avoid resolving per-thumbnail).
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
| `archive: ^3.6.1` | ZIP export/import for device transfer (§7) | Constrained to `^3.6.1` (not ^4) because `excel ^4.0.6` requires `archive ^3.6.1`. |

- **Full-screen viewer:** no package needed — `PageView` + `InteractiveViewer` (built
  in) give swipe + pan/zoom. (`photo_view` is an optional future polish.)
- **Reordering:** built-in `ReorderableListView` — no new package.
- Already present and reused: `path_provider`, `path`, `uuid`, `share_plus`,
  `file_picker`.

### Platform permission config

- **iOS** — `ios/Runner/Info.plist` **already declares** `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription`; both strings reworded to describe image capture/attachment.
- **Android** — **no `CAMERA` added.** `image_picker` reads the gallery via the
  Android 13+ **Photo Picker** (no `READ_MEDIA_IMAGES`) and captures via an
  `ACTION_IMAGE_CAPTURE` intent handled by the system camera app, so **no extra
  manifest permission is required**.

---

## 3. How is this stored in the `Setup` model?

[lib/models/setup.dart](../lib/models/setup.dart) — ordered, non-nullable list of
filenames (empty = no images; **order is the user's chosen image order**, so a `List`,
not a `Set`):

```dart
final List<String> images; // relative filenames in images/, ordered
```

1. **Field + constructor** — `this.images` defaulting to `const []` (optional, backward
   compatible).
2. **`toJson`** — version `5`; includes `'images': images`.
3. **`fromJson`** — reads `json['images']` with fallback to `<String>[]`; older backups
   without the key load as empty.
4. **`copyWith`** — `Object? images = const _Sentinel()` (sentinel pattern).
5. **`deepCopy`** (duplicate/restore) — copies the list; the duplicate flow calls
   `ImageStorageService.copyExisting` for each filename so files aren't shared.
6. **`==` / `hashCode`** — `listEquals(images, other.images)` / `Object.hashAll(images)`.

---

## 4. How is this stored in the Drift database?

### Table — [lib/database/tables/setups.dart](../lib/database/tables/setups.dart)

Image **order matters**, so `StringListOrderedConverter` (new, in
`lib/database/converters/string_list_ordered_converter.dart`) is used — unlike
`StringListConverter` which returns `Set<String>`:

```dart
TextColumn get images =>
    text().map(const StringListOrderedConverter()).withDefault(const Constant('[]'))();
```

### Schema migration — [lib/database/app_database.dart](../lib/database/app_database.dart)

- Schema version bumped to **7** (on top of dev's v6 which covers the rating redesign).
- In `onUpgrade`:

```dart
if (from < 7) {
  await m.addColumn(setups, setups.images);
}
```

### Mappers — [lib/database/mappers.dart](../lib/database/mappers.dart)

- `Setup.toCompanion()` → `images: Value<List<String>>(images)`.
- `SetupDbMapper.toModel()` → `images: images`.

---

## 5. UI — display, viewer, missing-file placeholder

Images are local files → `Image.file(File(absolutePath))`. The `images/` directory path
is resolved once per page (via `ImageStorageService().getImagesPath()`) and passed down
as `imagesDir` to avoid a `FutureBuilder` per thumbnail.

### Missing-file handling

Every image tile uses `Image.file(..., errorBuilder: …)` returning a **placeholder**
(grey box, broken-image icon). The full-screen viewer shows "Image not found" with a
broken-image icon.

### Widgets

1. **`ImageStrip`** (`lib/widgets/image_strip.dart`) — horizontal list of square
   thumbnails. Modes:
   - **view** — `ListView.separated`; tap → full-screen viewer.
   - **edit** — `ReorderableListView` with `ReorderableDelayedDragStartListener`
     (long-press to start drag); delete (✕) badge per tile; custom `proxyDecorator`
     (clean rounded square, 4dp elevation, no item spacing). No "Add" tile — adding
     is handled by the `_wrap()` chip in `setup_page.dart`.
   - `onAdd` parameter still exists but is only wired up if needed elsewhere.
2. **`ImageViewer`** (`lib/widgets/image_viewer.dart`) — full-screen route:
   `PageView` of `InteractiveViewer(child: Image.file(...))` with placeholder on error,
   close button, share via `ShareService`.

### Add/edit integration — [lib/pages/setup_page.dart](../lib/pages/setup_page.dart)

- State: `List<String> _images = [...?widget.setup?.images]` + `_initialImages` for
  dirty-tracking.
- `_addImages()` — shows camera/gallery source sheet, picks images, imports via
  `ImageStorageService`, calls `_onImagesAdded`.
- Remove/reorder handlers update `_images`; `_changeListener()`.
- **Layout** (top header area):
  1. Name field
  2. Notes field
  3. `_wrap()` — action chips for date/time/location/weather/tags, **plus "Photo" `ActionChip`
     as last item** (calls `_addImages()`), gated by `enableSetupImages && _imagesDirPath != null`.
  4. `ImageStrip` in edit mode — only shown when `_images.isNotEmpty`, below the Wrap.
- In `_saveSetup()` passes `images: _images` into the returned `Setup(...)`.

### Read-only detail — [lib/pages/details/setup_details_page.dart](../lib/pages/details/setup_details_page.dart)

- `if (appSettings.enableSetupImages && setup.images.isNotEmpty) ImageStrip(mode: view, …)`

### List tiles — icon + count (no preview)

[lib/widgets/items/setup_list_card.dart](../lib/widgets/items/setup_list_card.dart) — in
the subtitle `Wrap`, adds:

```dart
if (appSettings.enableSetupImages && setup.images.isNotEmpty)
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.photo_library_outlined, size: 13, ...),
      Text('${setup.images.length}', ...),
    ],
  ),
```

---

## 6. File lifecycle & orphan cleanup

Setups use **soft-delete** — do **not** delete files on soft delete.

- ✅ **Edit, image removed + saved** → after save, `SetupActions.editSetup` deletes files in
  `originalImages` but not in `editedSetup.images`.
- ✅ **Duplicate** → `copyExisting` each file to a new filename; deletes copies if user cancels.
- ❌ **Hard delete / purge** — not yet implemented.
- ❌ **Startup sweep** — not yet implemented.

---

## 7. Export for device transfer — ZIP vs base64 JSON (effort)

**❌ Not yet implemented.**

Goal: let a user move their images (which are otherwise local-only) to a new device.

### Option A — ZIP bundle (recommended)

Bundle the JSON export **and** the whole `images/` folder into one `.zip`, shared via
`share_plus`; import picks a `.zip`, restores the JSON, and unzips images into
`images/`.

- **Work:** `ImageBundleExportService` to build/import the zip; two buttons ("Export Full
  Bundle", "Import Bundle"); reuse `ShareService` / `file_picker`.
- `archive ^3.6.1` already in `pubspec.yaml`.

### Option B — base64 embedded in JSON

Inline each image as base64 in the export JSON (opt-in flag only, never in automatic backup).

### Recommendation

**Option A (ZIP bundle)** — efficient, clean, covers all object types at once. **Default
plan.**

---

## 8. Reordering (done)

`ImageStrip` in edit mode uses `ReorderableListView` with
`ReorderableDelayedDragStartListener` (requires long-press before drag starts, so normal
horizontal swipe scrolls without triggering reorder). A custom `proxyDecorator` shows a
clean rounded square with 4dp elevation during drag — no item spacing or square corners.

---

## 9. Touched files summary

**New**
- `lib/services/image_storage_service.dart` ✅
- `lib/widgets/image_strip.dart` ✅
- `lib/widgets/image_viewer.dart` ✅
- `lib/database/converters/string_list_ordered_converter.dart` ✅
- `lib/services/image_bundle_export_service.dart` ❌ (§7, not yet)

**Modified**
- `pubspec.yaml` ✅ — `image_picker`, `archive`
- `ios/Runner/Info.plist` ✅ — reworded camera/gallery purpose strings
- `lib/models/app_settings.dart` ✅ — `enableSetupImages` flag
- `lib/pages/settings/features_page.dart` ✅ — debug-only toggle with local-only warning
- `lib/models/setup.dart` ✅ — `images` field, json v5, copyWith, ==, hashCode, deepCopy
- `lib/database/tables/setups.dart` ✅ — `images` column
- `lib/database/app_database.dart` ✅ — schemaVersion 7 + `onUpgrade` addColumn
- `lib/database/mappers.dart` ✅ — `toCompanion` + `toModel` include `images`
- `lib/pages/setup_page.dart` ✅ — image state, picker, strip, reorder, save wiring
- `lib/pages/details/setup_details_page.dart` ✅ — view-only strip + viewer
- `lib/widgets/items/setup_list_card.dart` ✅ — image icon + count
- `lib/utils/setup_actions.dart` ✅ — edit orphan cleanup + copy-on-duplicate

**Regenerate**: `flutter pub run build_runner build` (done; `app_database.g.dart` up to date).

---

## 10. Suggested implementation order

1. ✅ `AppSettings.enableSetupImages` + debug toggle in `features_page.dart` (with warning).
2. ✅ `pubspec.yaml` deps + platform permission config; `flutter pub get`.
3. ✅ Table column + ordered converter + schemaVersion 7 migration → `build_runner build`.
4. ✅ `Setup` model (field, json v5, copyWith, equality, deepCopy) + mappers.
5. ✅ `ImageStorageService` (generic, shared `images/`).
6. ✅ `ImageStrip` (incl. reorder + missing-file placeholder) + `ImageViewer`.
7. ✅ Wire into `setup_page.dart` (add/edit/save) — all behind `enableSetupImages`.
8. ✅ Wire into `setup_details_page.dart` (view) + `setup_list_card.dart` (icon+count).
9. ⚠️ Orphan cleanup on save-edit ✅ + copy-on-duplicate ✅; hard-delete/purge ❌; startup sweep ❌.
10. ❌ ZIP export/import (§7A).
11. ✅ Manual test: toggle flag on/off; add (gallery+camera); reorder; remove; full-screen;
    restart app. ⚠️ Remaining: delete & purge setup; delete a file on disk → placeholder;
    export bundle → import → links resolve; verify v1–v4 backups load as empty.

## 11. App Store & Play Store compliance

The app is worldwide, **age 0+**. Summary: **no new store-console "entitlements" needed,
privacy declarations up to date, age rating stays 0+.**

### iOS — App Store Connect / Info.plist

- ✅ **Info.plist purpose strings fixed** — reworded to describe actual capture + attachment.
- **No App Store Connect toggle** needed.
- **Privacy nutrition label:** images stored only on device, never collected → no new
  "Data Collected" entry required.
- **Privacy manifest (`PrivacyInfo.xcprivacy`):** `image_picker` ships its own manifest.
- **Encryption (`ITSAppUsesNonExemptEncryption`):** unchanged.

### Android — Google Play Console

- ✅ **No manifest changes** — `image_picker` uses Photo Picker (no `READ_MEDIA_IMAGES`)
  and system camera intent (no `CAMERA` permission).
- **Data safety form:** images stay on-device, not collected → no change.

### Action checklist before shipping to production

1. ✅ Reword the two iOS `UsageDescription` strings.
2. ✅ Confirm Android manifest stays free of `READ_MEDIA_IMAGES` / `CAMERA`.
3. ❌ Update the privacy policy with local-storage clause.
4. ❌ Re-confirm Apple App Privacy + Play Data safety still say images **not collected**.
5. ❌ Leave age rating at 0+; re-verify IARC/Apple questionnaires.
6. Remove `kDebugMode` gate when ready to ship.

## 12. Phase 2 (outlook): `ImageAdjustment` type — reusing Phase-1 infrastructure

> Not built in Phase 1. Documented so Phase 1 is shaped to make this cheap.

### Concept

Add a new adjustment type so an image becomes a **first-class, diffable setting value** —
e.g. a photo of the cockpit, saddle-rail position, flip-chip, cable routing, token stack.

- New `AdjustmentType.image` + `ImageAdjustment`. Its value is **filename(s)** in `images/`.
- Value stored in `setup_adjustment_values.value` — JSON-encode filename list.
- **Flows through the existing diff/inheritance engine**: previous setup's image shown
  alongside the new one; unchanged image carries forward via `SetupResolutionService`.

### What Phase 1 already gives Phase 2 (reuse)

- **Shared `images/` store** + `ImageStorageService` — object-agnostic on purpose.
- **`ImageStrip` / `ImageViewer`** — already generic (`List<String>` + edit callbacks).
- **Missing-file placeholder, `cacheWidth` thumbnails, reorder** — all reused.
- **ZIP bundle export/import** — archives the whole `images/` folder, covers B automatically.
- **Permissions / store compliance (§11)** — identical; already done once.

### What Phase 2 adds (the extra work, kept isolated)

- `ImageAdjustment` model subtype.
- Value (de)serialization in the mapper + `Setup.adjustmentValues{To,From}Json`.
- Input widget + thumbnail cell in `AdjustmentCompactDisplayList`.
- Adjustment creation UI: add "Image" to the type picker.
- Reference-counted cleanup (many setups may share one filename via inheritance).
- Its own gate, e.g. `enableImageAdjustment`, separate from `enableSetupImages`.

### Decoupling / "ship only one" guarantee

- Separate flags, separate columns — neither references the other.
- Only shared code is the **generic image substrate** (`ImageStorageService`,
  `ImageStrip`/`ImageViewer`, ZIP bundle).
- Phase 1 names everything generically so Phase 2 is purely additive.

---

## 13. Open questions / TODOs

| # | Question / Task | Notes |
|---|---|---|
| Q1 | **Images + daily backup** — are image files included in (or excluded from) the automatic daily JSON backup? | The DB backup is JSON-only; the `images/` dir is currently **not** included. Need to decide: warn the user more prominently, or bundle images alongside the backup ZIP. |
| Q2 | **Hard-delete after 30-day trash threshold** — when a soft-deleted Setup is permanently purged, are its image files also deleted? | Not yet implemented (§6 ❌). Risk: orphaned files accumulate silently on disk. |
| Q3 | **Export images** — §7 ZIP bundle export/import is not implemented yet. | Users currently have no way to transfer images to a new device or include them in a backup restore. |
| Q4 | **Unit tests** — no tests cover the new image functionality. | Candidates: `ImageStorageService` (import, copy, delete, exists), `StringListOrderedConverter` (round-trip), `Setup` model (images field in `fromJson`/`toJson`/`copyWith`/`==`), `setup_actions.dart` orphan-cleanup logic. |

---

## 14. Resolved decisions / future work

- **Placement of the toggle — DECIDED:** `features_page.dart`, wrapped in `if (kDebugMode)`.
- **Thumbnail performance — DECIDED: decode-downscaling + built-in cache; NO separate
  thumbnail files.** `Image.file(file, cacheWidth: 300)` in the strip; full quality in viewer.
- **UI placement of "Add image" — DECIDED:** `ActionChip` in the `_wrap()` Wrap as last item,
  not an extra tile inside `ImageStrip`. Strip only handles reorder + remove.
- **Portability without manual export** — base64-in-JSON or Firebase Storage remain
  future options; the filename column stays unchanged.
