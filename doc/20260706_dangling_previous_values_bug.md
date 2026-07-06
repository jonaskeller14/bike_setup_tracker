# Dangling Previous Values in Setup Resolution

**Date:** 2026-07-06  
**Severity:** Low  
**Status:** Documented, not yet fixed

## Problem

In `SetupResolutionService.resolveSetups()`, the `previousBikeAdjustmentValues` can contain values from setups where a component was **not installed** on the bike.

### Example Timeline

```
Setup 1 (2026-01-01): Component installed, value = a
  → Setup 1.previousBikeAdjustmentValues = {} (no previous)
  
Setup 2 (2026-02-01): Component deinstalled, value = b (set in setup UI, persisted)
  → Component.bikeAt(datetime) != setup.bike, so:
    - Adjustment not in bikeAdjustmentIds
    - No previous value populated ✓
  → But b is added to globalLastKnownState (line 76) ✗
  
Setup 3 (2026-03-01): Component reinstalled, value = c
  → Component.bikeAt(datetime) == setup.bike, so:
    - Adjustment IS in bikeAdjustmentIds
    - previousBikeAdjustmentValues[id] = b (found in globalLastKnownState)
  → BUG: Shows "previously b" but b was from when component wasn't on bike!
```

## Root Cause

Line 76 unconditionally adds all `setup.bikeAdjustmentValues` to `globalLastKnownState`, even if the component wasn't on the bike during that setup. Later, when the component is reinstalled, it finds these dangling values.

## Impact

- **Severity:** Low — doesn't affect data integrity
- **UX:** Confusing — shows misleading previous values when re-adding a deinstalled component
- **Scope:** Narrow — only affects the "hint" value shown when editing a setup, a convenience feature

## Fix Options

### Option A: Only update globalState for installed components (Recommended)
Before line 76, filter adjustment values to only include those from installed components:

```dart
// Only track values for components actually on the bike
final relevantValues = <String, dynamic>{};
for (final id in bikeAdjustmentIds) {
  if (setup.bikeAdjustmentValues.containsKey(id)) {
    relevantValues[id] = setup.bikeAdjustmentValues[id];
  }
}
globalLastKnownState.addAll(relevantValues);
globalLastKnownState.addAll(setup.personAdjustmentValues);
```

**Pros:** Clean, correct semantics  
**Cons:** Requires careful testing to ensure previous values still populate correctly

### Option B: Track which adjustments were "relevant" per setup
Add a `relevantAdjustmentIds` field to `Setup` and only show previous values that come from relevant setups.

**Pros:** More explicit, easier to debug  
**Cons:** Schema change, more complex

## Affected Files

### UI Display (Shows dangling previous values)

- **[lib/widgets/lists/adjustment_compact_display_list.dart](../lib/widgets/lists/adjustment_compact_display_list.dart)** — Compact adjustment display widget
- **[lib/widgets/items/setup_list_card.dart](../lib/widgets/items/setup_list_card.dart)** (line 387) — Lists previous bike/person adjustment values when displaying a setup in the list
- **[lib/pages/details/component_details_page.dart](../lib/pages/details/component_details_page.dart)** (line 1092) — Table column displays `previousBikeAdjustmentValues` in component history
- **[lib/widgets/items/component_list_card.dart](../lib/widgets/items/component_list_card.dart)** — Displays adjustment history via `AdjustmentCompactDisplayList`
- **[lib/widgets/items/person_list_card.dart](../lib/widgets/items/person_list_card.dart)** — Displays adjustment history via `AdjustmentCompactDisplayList`

### Setup Creation/Editing (Pre-populates form with dangling values)

- **[lib/pages/setup_page.dart](../lib/pages/setup_page.dart)** (lines 115–238) — Uses `_previousBikeAdjustmentValues` to pre-populate form fields when editing/creating a setup. This is where dangling values would be most visible to users.

### Source & Tests

- **[lib/services/setup_resolution_service.dart](../lib/services/setup_resolution_service.dart)** (line 76) — Source of the bug
- **[test/services/setup_resolution_service_test.dart](../lib/services/setup_resolution_service_test.dart)** — Tests for resolution service
- **[test/widgets/adjustment_compact_display_list_test.dart](../test/widgets/adjustment_compact_display_list_test.dart)** — Tests for compact display

## Decision

Not critical for current release. Fix when refactoring setup-value history logic. Document in code comment near line 76.
