# iOS SwiftPM fallback to CocoaPods

## Status

The app uses CocoaPods for iOS native dependencies. Swift Package Manager is explicitly disabled in `pubspec.yaml`.

## Why

Commit `9bc1c450dff15f7ad001fd2e207bd6b41cad981b` migrated the app to Flutter's Swift Package Manager integration. Flutter 3.44 generated `FlutterGeneratedPluginSwiftPackage/Package.swift` with an iOS 13 deployment target even though the Runner target and Firebase dependencies require iOS 15.

As a result, the normal `flutter build ipa` command failed during package resolution with errors such as:

```
The package product 'firebase-messaging' requires minimum platform version 15.0 for the iOS platform, but this target supports 13.0.
```

The issue is tracked upstream in [flutter/flutter#186804](https://github.com/flutter/flutter/issues/186804).

## Revisit SwiftPM when the Flutter bug is fixed

1. Confirm the upstream issue is closed and that the fix is included in the Flutter version used by this project.
2. Create a branch and remove `flutter.config.enable-swift-package-manager: false` from `pubspec.yaml`.
3. Run `flutter clean`, `flutter pub get`, and `flutter build ipa` without custom scripts or generated-file edits.
4. Only remove the Podfile and CocoaPods integration after the normal IPA build succeeds.

Until then, use the standard `flutter build ipa` workflow with CocoaPods.
