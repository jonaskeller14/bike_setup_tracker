# `file_save_directory` removal — findings and implementation plan

**Date:** 2026-08-11
**Status:** Approved decisions → phased implementation plan

Locked decisions: replace `file_save_directory` with the already-installed
`file_picker`; use the native Save As dialog on Android and iOS; accept that
Android exports are no longer written silently to public Downloads; treat picker
cancellation as a neutral outcome; show a generic success message instead of an
unreliable path; migrate JSON, image-bundle, and recovered-backup exports; add no
new dependency.

---

## Findings

### Current usage and impact radius

`file_save_directory` has exactly three call paths, all in
`lib/utils/file_export.dart`:

1. JSON data export (`downloadJson`).
2. ZIP data-and-image export (`downloadImageBundle`).
3. Emergency export of the newest automatic local backup
   (`exportLatestBackup`).

Removing it does **not** affect automatic local backups, Google Drive backups,
sharing through `share_plus`, imports through `file_picker`, or the database
serialization format.

The resolved dependency graph confirms that `device_info_plus`, `open_file`, and
`permission_handler` are present only through `file_save_directory`. Removing the
package therefore also removes those dependency families, including the
non-SPM `open_file_ios` and `permission_handler_apple` plugins.

### Platform behavior after migration

| Platform | Current behavior | Behavior with `FilePicker.saveFile` | Implication |
|---|---|---|---|
| Android | Writes directly to public Downloads through `MediaStore` on current Android versions. | Opens the system Save As picker (`ACTION_CREATE_DOCUMENT`); the user can choose Downloads, another local folder, SD card, or a document provider. | One extra confirmation step; no storage permission; destination is user-controlled and survives app uninstall. |
| iOS | Already opens `UIDocumentPickerViewController`; there is no universal app-writable public Downloads folder. | Opens the same class of Files/document picker, including iCloud Drive, On My iPhone, and installed providers. | No meaningful workflow regression. |

Android's Storage Access Framework deliberately makes the user choose the
destination and does not require broad storage permission. `ACTION_CREATE_DOCUMENT`
also resolves duplicate names by creating a numbered name instead of silently
overwriting the existing file.

`path_provider.getDownloadsDirectory()` is not a substitute for public Downloads
on Android: its Android implementation resolves the app-specific external
Downloads directory under the app's storage area. `share_plus` remains appropriate
for sending a file but cannot guarantee that a recipient saves it to Downloads.

### Alternatives considered

| Option | Verdict |
|---|---|
| Existing `file_picker` dependency | **Chosen.** Maintained, SPM-capable, already used by imports, native Save As UI on both mobile platforms, and no new dependency. |
| `path_provider` direct write | Rejected. Does not provide the same public Downloads behavior on Android and does not solve user-selected external storage on iOS. |
| `share_plus` only | Rejected as the save implementation. A share sheet is not a deterministic Save As workflow, though the existing Share feature remains unchanged. |
| Another save plugin | Rejected. It replaces one specialist dependency with another and does not improve the maintenance objective. `file_saver`, for example, saves into app-specific storage by default on mobile. |
| App-owned Android `MediaStore.Downloads` channel | Deferred. It preserves one-tap public Downloads but adds native code and Android-version behavior for the app to maintain. Reconsider only if real user feedback shows the Save As step is unacceptable. |

### Package and SPM implications

As checked on 2026-08-11, `file_save_directory` 1.0.5 has an unverified uploader,
two likes, and about 298 downloads on pub.dev. Package popularity alone is not a
removal reason, but it compounds the missing SPM support and large transitive
surface for three simple save calls.

`file_picker` added Swift Package Manager support in 8.3.0; the project currently
resolves 11.0.3. After cleanup, the SPM warning list should lose
`file_save_directory`, `permission_handler_apple`, and `open_file_ios`.
`location` remains a separate non-SPM blocker, so this change reduces but does
not complete the repository's SPM migration.

Sources:

- https://pub.dev/packages/file_save_directory
- https://pub.dev/packages/file_picker
- https://pub.dev/packages/file_picker/changelog
- https://developer.android.com/training/data-storage/shared/documents-files
- https://developer.apple.com/documentation/UIKit/UIDocumentPickerViewController
- https://pub.dev/documentation/path_provider/latest/index.html

---

## Resolved open questions

### Downloads behavior → native Save As

Accept the Android behavior change from an automatic public-Downloads write to
a native Save As dialog. Downloads remains available as a user-selected
destination, but the app does not force or preselect it. iOS continues to use a
document picker.

### Cancellation and feedback → three distinct outcomes

- **Saved:** show `File saved` without printing the returned path. Android may
  return a document URI path that is not meaningful to a user.
- **Cancelled:** close quietly with no success or error snackbar.
- **Failed:** retain the themed error snackbar and diagnostic `debugPrint`.

### User-facing terminology → Save, not Download

Rename `Download File` to `Save File` and describe it as choosing where to save
the JSON file. Update FAQ copy so it no longer promises an automatic Downloads
destination. Keep `Export Data`, `Save Backup`, and the import/share terminology.

### iOS plist configuration → retain

Keep `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, and the current
document-browser configuration. They are not required solely by
`file_save_directory`, remain compatible with Files-based workflows, and should
not be removed as part of this dependency cleanup.

## Public interfaces and behavior changes

- Add a small `FileSaveService` around `FilePicker.saveFile` with a
  `FileSaveOutcome.saved` / `FileSaveOutcome.cancelled` result. Exceptions remain
  failures and are handled by the caller.
- The service accepts a filename, `Uint8List` bytes, and extension; it calls
  `FilePicker.saveFile` with `FileType.custom` and the matching allowed extension.
- Rename `FileExport.downloadJson` to `saveJson` and
  `downloadImageBundle` to `saveImageBundle`. Keep `exportLatestBackup`, but route
  its final write through the same service.
- Give these `FileExport` entry points an optional `FileSaveService` parameter
  defaulting to the production implementation. Tests inject a fake service;
  application call sites remain simple.
- File contents, timestamped JSON filenames, ZIP filenames, and recovered-backup
  filenames remain unchanged.

## Feature flag

**None.** The native picker replaces an existing export action and is safely
cancellable. There is no parallel storage implementation to retain behind a
flag.

---

## Phase 1 — Migrate export flows to the native Save As service

**Status:** ⬜ Not started

**Files:**
- `lib/services/file_save_service.dart` *(new)*
- `lib/utils/file_export.dart`
- `lib/widgets/sheets/export.dart`
- `lib/pages/settings/faq_page.dart`
- `test/services/file_save_service_test.dart` *(new)*
- `test/utils/file_export_test.dart` *(new)*

- [ ] Add `FileSaveOutcome` and `FileSaveService`. Convert incoming byte lists to
      `Uint8List` at the boundary and call `FilePicker.saveFile` with the proposed
      filename and one allowed extension.
- [ ] Return `cancelled` only when the picker returns `null`; return `saved` for a
      non-null result; let plugin/platform exceptions propagate to the export
      action's existing failure handling.
- [ ] Replace all three `FileSaveDirectory.instance.saveFile` calls with the
      service. Remove `FileSaveResult`, `SaveLocation`, and platform-specific
      success checks from `FileExport`.
- [ ] Consolidate success/cancel/failure snackbar handling so JSON, ZIP, and
      recovered-backup exports behave identically. Do not display a filesystem
      path or `Unknown location`.
- [ ] Rename the two download-oriented Dart methods and their call sites to
      `saveJson` and `saveImageBundle`.
- [ ] Change the export sheet label to `Save File` with copy explaining that the
      user chooses the destination. Update FAQ statements that currently promise
      the device Downloads folder.
- [ ] Keep generated JSON/ZIP data, local temporary bundle handling, local backup
      discovery, and all share/import behavior unchanged.

**Verification:**

- Add service tests for saved, cancelled, and thrown-platform-error outcomes,
  including `.json` and `.zip` filename/extension forwarding.
- Add export tests proving cancellation emits no snackbar, success emits
  `File saved`, failure emits an error snackbar, and all three entry points call
  the injected service with the expected filename and bytes.
- Run `flutter test test/services/file_save_service_test.dart`.
- Run `flutter test test/utils/file_export_test.dart`.
- Run `flutter analyze` and `flutter test`.
- Manually verify on Android that Save File can target Downloads, cancellation is
  silent, a duplicate filename is safely renamed by the system, and the resulting
  JSON can be imported.
- Manually verify on iPhone/iPad that Save File and Export Image Bundle can target
  On My iPhone and iCloud Drive, including cancellation from the picker.

**Commit:** `refactor(export): save files through native picker`

---

## Phase 2 — Remove the plugin and refresh platform metadata

**Status:** ⬜ Not started

**Files:**
- `pubspec.yaml`
- `pubspec.lock`
- `ios/Podfile.lock`
- `doc/20260522_swift_package_manager_migration.md`

- [ ] Remove `file_save_directory` from direct dependencies and run
      `flutter pub get`; do not add another package.
- [ ] Confirm the resolved graph no longer contains `file_save_directory`,
      `device_info_plus`, `open_file`, `permission_handler`, or their platform
      packages unless a new independent parent is discovered at implementation
      time.
- [ ] On macOS, run the normal iOS dependency resolution/build flow so
      `ios/Podfile.lock` drops the obsolete pod entry; do not hand-edit the lock.
- [ ] Update the SPM migration document to remove
      `file_save_directory`, `permission_handler_apple`, and `open_file_ios` from
      its pending list and record that `location` remains.
- [ ] Search the repository for `file_save_directory`, `FileSaveDirectory`,
      `SaveLocation`, and user-facing claims about automatic Downloads; only this
      historical plan/report may retain the package name.

**Verification:**

- Run `flutter pub deps --style=compact` and inspect the dependency removal.
- Run `flutter analyze` and `flutter test`.
- On macOS, run `flutter build ios --no-codesign` with Flutter 3.44+ and verify
  that the SPM warning no longer names the three removed plugins; document the
  still-expected `location` warning.
- Build/run an Android release or profile build and repeat one JSON save/import
  round trip from public Downloads.

**Commit:** `build(deps): remove file save directory plugin`

---

## Suggested commit granularity

1. `refactor(export): save files through native picker` — behavioral migration,
   copy updates, and tests while the old package remains available but unused.
2. `build(deps): remove file save directory plugin` — dependency/lock cleanup,
   CocoaPods refresh, and SPM documentation update.

The two commits keep the behavioral refactor independently testable and make the
dependency removal a small, auditable cleanup. Phase 2 requires a macOS/iOS
environment for final lockfile and SPM verification; all Dart and Android work
can be completed first on Windows.
