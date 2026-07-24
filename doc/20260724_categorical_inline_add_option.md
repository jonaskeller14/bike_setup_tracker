# Inline "add option" chip in the categorical selection sheet

## Context

In the categorical value-picker sheet (`lib/widgets/sheets/set_categorical.dart`) the user can only pick from options that already exist on the adjustment definition. If an option is missing, they must leave the flow, open the adjustment edit page, add the option, and come back.

The feature: a chip showing only a `+` icon (no label) at the **end of the `Wrap`**. Tapping it turns the chip into an inline text field (keyboard opens); submitting the typed text **adds the option to the adjustment definition and persists it**, then it becomes a normal, selectable chip.

The new option is **persisted permanently** to the owning definition (component / person attribute / rating metric) via the existing `editComponent` / `editPerson` / `editRating` repository methods — not session-only.

### Implication
The categorical adjustment definition is **shared**. Adding an option from a setup/rating-entry sheet permanently changes that component's/person's/rating's adjustment for **all** setups and entries that use it. This mirrors what the adjustment edit page already does; no per-setup override exists.

## Where the sheet is used

`SetCategoricalAdjustmentWidget` (`lib/widgets/set_adjustment/set_categorical_adjustment.dart`) opens the sheet. It appears in:

- **Value-setting contexts (get the `+` chip):**
  - Component adjustments — setup page → `SetupBikeTab` in `lib/widgets/setup_page_tabs.dart` → `AdjustmentSetList`
  - Person attributes — setup page → `SetupPersonTab` in `lib/widgets/setup_page_tabs.dart` → `AdjustmentSetList`
  - Rating metrics — `lib/pages/rating_entry_page.dart` → `AdjustmentSetList`
- **Preview-only contexts (NO `+` chip — they already edit the definition):**
  - `lib/pages/adjustment/categorical_adjustment_page.dart`
  - `lib/pages/metric/categorical_metric_page.dart`

The feature is **opt-in via a nullable callback**: when the callback is null, the `+` chip is not rendered.

## Design: thread a persist callback down, resolve the owner up

Sheet-level, owner-agnostic callback: `Future<bool> Function(String option)` — returns whether the option was persisted. Each value-setting caller builds a closure that knows its owner and returns success/failure.

### 1. Model helper — `lib/models/adjustment/categorical_adjustment.dart`
A general-purpose `copyWith` (mirroring the `_Sentinel` pattern used by `Person`/`Rating`) so callers append an option with `adj.copyWith(options: {...adj.options, option})`.

### 2. Sheet — `lib/widgets/sheets/set_categorical.dart`
- Add param `Future<bool> Function(String option)? onAddOption`.
- Local ordered option list `final List<String> optionList = adjustment.options.toList();`; replace all `adjustment.options` reads in the builder and `emit()`. This lets a just-added option render/emit while the sheet stays open (captured `adjustment` is stale until close).
- Render a new `_AddOptionChip` at the end of the `Wrap` **only when `onAddOption != null`**.
- On submit: trim → reject empty/duplicate (exact trimmed match, `SnackBar` + keep focus) → `await onAddOption!(value)` → on `false` error `SnackBar`; on success append to `optionList`, **auto-select** (non-counted → `current.add`; counted → `counts[value] = 1`; single-select clears others and closes with the 200ms delay like an ordinary tap), `onChanged(emit())`, `HapticFeedback.selectionClick()`.
- `_AddOptionChip`: private `StatefulWidget`; collapsed = `ActionChip` with only `Icon(Icons.add)`; editing = compact chip-shaped `TextField` (autofocus, `TextInputAction.done`, collapse on blur/empty). Theme-only styling, overflow-safe.

### 3. Widget — `lib/widgets/set_adjustment/set_categorical_adjustment.dart`
Add `Future<bool> Function(String option)? onAddOption`, forward into `showSetCategoricalSheet`.

### 4. List — `lib/widgets/lists/adjustment_set_list.dart`
Add `Future<bool> Function({required CategoricalAdjustment adjustment, required String option})? onAddCategoricalOption`; in the `CategoricalAdjustment()` case pass `onAddOption: onAddCategoricalOption == null ? null : (option) => onAddCategoricalOption!(adjustment: adjustment, option: option)`.

### 5. Callers — persist closures
Each closure resolves the owner from the repository by `adjustment.id`, rebuilds it with `withAddedOption`, calls the edit method, returns `true` (guarded by `context.mounted`, `try/catch` → `false`).

- **Setup page** (`lib/pages/setup_page.dart`): bike → `editComponent(component.copyWith(adjustments: updated))`; person → `editPerson(person.copyWith(adjustments: updated))`.
- **`setup_page_tabs.dart`**: nullable `onAddCategoricalOption` fields on `SetupBikeTab`/`SetupPersonTab`, forwarded to their `AdjustmentSetList`.
- **Rating entry** (`lib/pages/rating_entry_page.dart`): find the rating whose metric has the id → `editRating(rating.copyWith(metrics: updated))` where the matching `RatingMetric` is `metric.copyWith(adjustment: adj.withAddedOption(option))`.

All `copyWith`/`editX` methods already exist.

## Notes / edge cases
- Empty-options categorical: the "No options yet" hint stays; the `+` chip populates it inline.
- Typing a value equal to a dangling value resurrects it — acceptable.
- While the sheet is open, `editX` notifies and rebuilds the underlying page; the modal is unaffected. On close, the widget's `ValueKey(adjustment)` changes and it rebuilds cleanly; the value is stored by id in `AdjustmentSetList._adjustmentValues`.
- The FormField validator in `set_categorical_adjustment.dart` passes once the widget receives the updated adjustment after persist.

## Verification
- `flutter analyze` on the touched files.
- Extend `test/widgets/set_adjustment/set_categorical_adjustment_test.dart`: `+` chip renders when `onAddOption` provided; submit invokes callback and (on success) option appears/selected; duplicate/empty rejected; chip absent when `onAddOption` null. Unit test for `CategoricalAdjustment.withAddedOption`.
- Manual: setup page → component adjustment → sheet → `+` → type → submit → option persists (reopen edit page shows it); repeat for person attribute and rating-entry metric; light + dark, long text, single/multi/counted modes.
