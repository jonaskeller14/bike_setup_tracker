# Alchemist golden tests — implementation plan

## Summary

Add deterministic, platform-neutral golden coverage for `GarageList`, `SetupList`, and `SetupPage`. Use Alchemist CI goldens at a fixed phone viewport in both light and dark themes, backed by a shared in-memory repository fixture.

## Implementation Changes

### 1. Golden infrastructure and sample data

- Add `alchemist: ^0.14.0` to dev dependencies and update `pubspec.lock`.
- Create a shared test harness under `test/goldens/support/` that:
  - Owns and disposes `AppDatabase.memory()`, `AppRepository`, `AppSettings`, and required providers.
  - Uses fixed IDs, dates, ordering, values, and viewport dimensions.
  - Disables onboarding, hints, network-backed features, animations where controllable, and other unrelated optional UI.
  - Wraps scenarios with `materialAppTheme` or `materialAppDarkTheme`.
  - Uses explicit pumping instead of `pumpAndSettle` where repository streams keep scheduling frames.
- Seed:
  - Two bikes, installed components, and an uninstalled component for the garage.
  - A component containing numerical, step, categorical, and boolean adjustments.
  - Two chronological setups whose values include both changed and unchanged adjustments, allowing compact displays and current-setup highlighting to render deterministically.
- Configure Alchemist with CI goldens enabled, platform goldens disabled, obscured text, stabilized shadows, and zero diff tolerance.
- Ignore `goldens/windows`, `goldens/linux`, and `goldens/macos`; commit only `goldens/ci`.

### 2. Golden scenarios

- Add a `GarageList` golden suite:
  - Render the populated garage with two bike cards, installed component content, and the uninstalled section.
  - Capture identical fixed-size light and dark scenarios.
- Add a `SetupList` golden suite:
  - Hide unrelated hints and timeline integrations.
  - Render at least two `SetupListTile` instances.
  - Ensure both tiles contain `AdjustmentCompactDisplayList` content, with the newer setup showing meaningful changes from the older setup.
  - Include current-setup highlighting and capture light and dark scenarios.
- Add a `SetupPage` golden suite using edit mode:
  - Seed the repository before constructing the page so its bike and component relationships resolve normally.
  - Include numerical, step, categorical, and boolean set-adjustment widgets with representative selected values.
  - Capture top-of-page and deterministically scrolled adjustment-area states so all four widget types are visible.
  - Capture both states in light and dark themes.
- Generate and commit the neutral reference PNGs with `flutter test test/goldens --update-goldens`.

### 3. CI integration

- Split the existing test workflow into clearly reported steps:
  - `flutter test --coverage --exclude-tags golden` for ordinary tests.
  - `flutter test --tags golden` for committed Alchemist baselines.
- Keep the existing Ubuntu runner; the checked-in CI baselines remain host-independent because Alchemist obscures text and stabilizes shadows.
- Continue uploading coverage from the non-golden test step.

## Interfaces and Test Utilities

- No production API, model, database schema, or widget interface changes.
- The shared golden harness will expose test-only helpers for:
  - Deterministic fixture creation and repository reload.
  - Light/dark provider-wrapped applications.
  - Fixed viewport constraints and controlled settling.
  - Locating and scrolling the `SetupPage` adjustment area.

## Verification

- Confirm each suite finds the expected structural widgets before comparing pixels:
  - Garage: two bike cards and the uninstalled section.
  - Setup list: two setup tiles and compact adjustment lists.
  - Setup page: numerical, step, categorical, and boolean set-adjustment widgets across the two captures.
- Run:
  - `flutter test test/goldens --update-goldens`
  - `flutter test test/goldens`
  - `flutter test --exclude-tags golden`
  - `flutter analyze`
- Review every generated light/dark CI image before committing.
- Verify a deliberate visual change causes the appropriate golden test to fail and emits diff artifacts.

## Assumptions

- Golden tests protect populated representative states; empty, loading, drag, dialog, and error states remain outside the initial scope.
- Set-adjustment behavior remains covered by existing widget tests; the new page goldens cover their integrated appearance.
- The fixed reference viewport is a 390×844 logical-pixel phone surface with text scale 1.0.
- CI baselines use exact comparison; tolerance is introduced only if a demonstrated deterministic rendering difference requires it.
