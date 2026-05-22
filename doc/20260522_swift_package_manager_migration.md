# Swift Package Manager Migration

Flutter 3.44+ uses Swift Package Manager (SPM) by default for iOS/macOS dependencies, replacing CocoaPods. The following plugins currently lack SPM support and fall back to CocoaPods automatically (with a warning).

## Plugins pending SPM support

| Plugin | Current version | Role | pub.dev |
|---|---|---|---|
| `location` | 8.0.1 | GPS / location services | https://pub.dev/packages/location |
| `file_save_directory` | 1.0.4 | Pick save directory on iOS | https://pub.dev/packages/file_save_directory |
| `permission_handler_apple` | 9.4.7 | iOS permission handling (transitive via `permission_handler`) | https://pub.dev/packages/permission_handler_apple |
| `open_file_ios` | 1.0.4 | Open files on iOS (transitive) | https://pub.dev/packages/open_file_ios |

## What to do when migrating

1. Check each plugin above for a `Package.swift` in their `ios/` directory — that indicates SPM support.
2. Run `flutter pub upgrade` and confirm the warnings disappear after updating.
3. If a plugin is permanently abandoned without SPM support, find a replacement.

## flutter_native_splash — removed from dev deps (temporary)

`flutter_native_splash 2.4.4` has a broken `Package.swift` that causes a hard SPM build error. Upgrading to 2.4.7 (which fixes it) is blocked by a dependency conflict:

- `flutter_native_splash >=2.4.6` requires `image ^4.5.4` → `xml ^7.0.1`
- `excel ^4.0.6` requires `xml >=5.0.0 <7.0.0`

**Workaround:** `flutter_native_splash` was removed from `dev_dependencies`. The generated splash screen files are committed to the repo and still work. To re-add it when ready:

1. Check if `excel` has a version supporting `xml ^7.0.1`: https://pub.dev/packages/excel
2. If yes, bump `excel` in `pubspec.yaml`, then add back: `flutter_native_splash: "^2.4.7"`
3. Run `dart run flutter_native_splash:create` to regenerate if the splash config changed.

The `flutter_native_splash:` config block in `pubspec.yaml` is kept so the settings are preserved.

## Current status

As of Flutter 3.44 / May 2026, none of these plugins have added SPM support. The build still succeeds because Flutter automatically falls back to CocoaPods for these specific plugins.

The warning message is:
```
The following plugins do not support Swift Package Manager for ios:
  - location
  - file_save_directory
  - permission_handler_apple
  - open_file_ios
This will become an error in a future version of Flutter.
```
