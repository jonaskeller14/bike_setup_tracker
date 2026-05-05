# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
flutter pub get                            # Fetch dependencies
flutter run                                # Run app on connected device
flutter analyze                            # Static analysis (lint)
dart format .                              # Format code

# Testing
flutter test                               # Run all tests
flutter test test/some_test.dart           # Run a single test file

# Code generation (required after modifying database tables, models with @JsonSerializable, or env/)
flutter pub run build_runner build         # Generate .g.dart files (drift, envied)
flutter pub run build_runner clean         # Clean generated files

# Builds
flutter build apk                          # Android APK
flutter build appbundle                    # Android App Bundle (Play Store)
flutter build ios                          # iOS
```

CI runs `flutter pub get` → `flutter analyze` → `flutter test` on push to `main`/`dev`.

## Architecture

### State Management

The app uses the **Provider pattern** with a single central `AppRepository` (`lib/repositories/app_repository.dart`) that extends `ChangeNotifier`. It is the hub for all business logic — it holds in-memory filtered state, calls DAOs for persistence, and notifies the UI.

`AppSettings` (`lib/models/app_settings.dart`) is a separate `ChangeNotifier` backed by SharedPreferences, holding feature flags and user preferences (e.g., `enableStrava`, `enableGoogleDrive`, `enablePerson`).

Both are provided at the root via `MultiProvider` in `main.dart`, with services (`StravaService`, `GoogleDriveService`, `StorageService`) added as `ChangeNotifierProxyProvider`s.

**Data flow:**
```
UI (Pages/Widgets) → context.watch<AppRepository>() / context.read<AppRepository>()
AppRepository → Services + DAOs
DAOs → AppDatabase (Drift/SQLite)
```

### Database

Drift ORM over SQLite3. Schema version 3 with explicit migration strategy.

- **Tables** (`lib/database/tables/`): 13 tables — bikes, components, installations, setups, setup_adjustment_values, adjustments, persons, ratings, task_rules, task_entries, strava activities, etc.
- **DAOs** (`lib/database/daos/`): One DAO per entity group; `SoftDeleteDaoMixin` provides the soft-delete pattern (all deletes set `isDeleted = true` rather than removing rows).
- **Converters** (`lib/database/converters/`): Custom type converters for `Duration`, `DateTime` (UTC vs. local-floating), `LatLng`, `Placemark`, and `Weather`.
- **Mappers**: DAOs return DB entities that `AppRepository` maps to domain models (`lib/models/`).

After changing any table or adding a `@JsonSerializable` annotation, run `build_runner build`.

### Domain Models & Relationships

- **Bike** → has a **Person** (rider), optional Strava gear, contains **Component**s
- **Component** → has **Adjustment** definitions and **Installation** history (timeline)
- **Setup** → snapshot of a bike state, links to Bike + Person + Rating, stores **SetupAdjustmentValues**
- **TaskRule** → maintenance rule linked to Bike/Component, interval or distance-based
- **TaskEntry** → log of a completed maintenance task with a component stats snapshot
- **StravaActivity** → synced from Strava, linked to bike stats

### Filtering State in AppRepository

`_selectedBike` is the primary filter — it drives which components, setups, persons, ratings, task rules, and installations are shown. Setup tags and task rule tags provide secondary filtering. Computed properties like `toDoTaskRules` and `completedTaskRules` derive status (Overdue / Due / Upcoming) from rule intervals and Strava distance data.

### Services (`lib/services/`)

| Service | Purpose |
|---|---|
| `StravaService` | OAuth2 flow (client_id=193047), Firestore listener, paginated activity sync |
| `GoogleDriveService` | Cloud backup (Android only) — JSON export/import |
| `StorageService` | Local file storage |
| `NotificationService` | Firebase Cloud Messaging |
| `DeepLinkService` | App link handling |
| `QuickActionsService` | iOS/Android home screen quick actions |
| `DatabaseMigrationService` | One-time legacy data import on first launch |

### Actions Pattern (`lib/utils/`)

Files like `bike_actions.dart`, `component_actions.dart`, `setup_actions.dart` etc. contain top-level functions for UI-triggered operations (dialogs, confirmations, multi-step flows). They call into `AppRepository` but live outside widgets to keep pages lean.

### Pages & Widgets

Pages (`lib/pages/`) are thin — they `watch` the repository and delegate to action helpers. Reusable components live in `lib/widgets/`, with sub-folders for list views (`widgets/lists/`) and bottom sheets (`widgets/sheets/`).

App startup goes through `LoadingGate` (async init: AppSettings load, DB migration check) before the main navigation shell (`home_page.dart`).

### Environment / Secrets

Secrets (e.g., `MAPBOX_TOKEN`) are stored in `.env` and obfuscated via `envied`. Generated output lands in `lib/env/env.g.dart` (gitignored). Do not hardcode tokens in source.

### Platform Notes

- Google Drive sync is Android-only (guarded at runtime).
- Firebase App Check uses debug providers in debug mode, `PlayIntegrity`/`AppAttest` in release.
- `SystemUiMode.edgeToEdge` is set globally for full-bleed UI.
- The app targets iOS (App Store) and Android (Play Store); web and desktop builds exist but are secondary.
