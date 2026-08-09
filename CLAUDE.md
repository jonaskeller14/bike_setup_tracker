# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Development
flutter pub get                            # Fetch dependencies
flutter analyze                            # Static analysis (lint)

# Testing
flutter test                               # Run all tests
flutter test test/some_test.dart           # Run a single test file

# Code generation (required after modifying database tables, models with @JsonSerializable, or env/)
flutter pub run build_runner build         # Generate .g.dart files (drift, envied)
flutter pub run build_runner clean         # Clean generated files
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

Drift ORM over SQLite3 with an explicit, append-only migration strategy (`schemaVersion` + `onUpgrade` steps in `lib/database/app_database.dart`).

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

## Code Conventions

Match the surrounding code. Before writing a new widget, page, sheet, DAO, or model,
open the nearest existing one of the same kind and mirror its structure, naming, and
idioms. Consistency with existing code outranks personal preference.

### UI/UX
- **Reuse before rebuild.** Prefer existing widgets in `lib/widgets/` (and `lists/`,
  `sheets/`) over new ones. New UI should look and behave like its neighbors — same
  spacing, same interaction patterns.
- **Style via `lib/theme.dart` and `Theme.of(context)`** — never hardcode colors or
  text styles. Both `materialAppTheme` and `materialAppDarkTheme` exist; verify new UI in
  **light and dark**.
- **Overflow-safe & resolution-agnostic by default.** Every layout must survive long
  text and narrow/wide screens. Use `Flexible`/`Expanded`, `TextOverflow.ellipsis`,
  `FittedBox`, `LayoutBuilder` as appropriate. Never assume a fixed width fits.
- **Respect insets.** Wrap screen content in `SafeArea` and handle the keyboard
  (`viewInsets`) so nothing hides behind the notch, home indicator, or keyboard — the app
  is edge-to-edge (`SystemUiMode.edgeToEdge`).
- **Every async view handles three states:** loading, empty, and error — not just the
  happy path. Reuse the existing empty-state sheet helpers.
- **Feedback is consistent.** Confirm completed actions and surface errors via `SnackBar`;
  fire `HapticFeedback` on primary/destructive interactions; gate destructive/irreversible
  actions behind a confirmation dialog (see the `lib/utils/*_actions.dart` pattern).

### Code quality
- **Maintainable over clever.** Small, single-purpose widgets and functions. Keep
  pages thin — delegate logic to `lib/utils/*_actions.dart` and `AppRepository`.
- **Comments only when they add non-inferable value** (a *why*, a non-obvious edge
  case). No comments that restate the code.
- **No dead scaffolding.** Don't leave TODOs, commented-out code, or unused params.
- **Surgical, clean-diff edits.** Change only what the task functionally requires. No
  reformatting, re-aligning, or "cleanup" of untouched lines; never run a whole-file formatter
  for a minor edit. A 3-line fix beats a 10-line one. Run `dart format` for newly created files;
  for existing code, leave lines you don't touch as-is.
- **Guard `context` across async gaps.** After an `await`, check `mounted` /
  `context.mounted` before using `context` or calling `setState` (matches existing usage).
- **Minimize rebuilds.** Use `context.read` for one-off reads and `context.select` to watch
  a single field; reserve `context.watch` for when the whole object is needed. Keep `const`
  constructors wherever possible.

### Tests
- **Add/extend tests when logic is non-trivial** (repository logic, mappers,
  migrations, computed status, date/duration math). Skip tests for pure-layout tweaks.
- Mirror the `lib/` path under `test/`; use `group`/`setUp`/`tearDown` and
  `AppDatabase.memory()` (see `test/rating_score_service_test.dart`).
