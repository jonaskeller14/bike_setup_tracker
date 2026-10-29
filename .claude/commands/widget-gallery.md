---
description: Build an on-demand screenshot gallery of every valid and invalid state of a widget, and check no state crashes or traps the user
argument-hint: "<widget or sheet name, e.g. InstallationParentField> [extra states to cover]"
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(flutter test:*), Bash(flutter analyze:*), Bash(dart format:*)
---

Create a visual state gallery for one widget (or sheet/page section), so the maintainer can
look at **every** state after changing it, without recreating the cases on a device.
`$ARGUMENTS` = the widget name plus any states the maintainer already wants covered.

Reference implementation: `test/gallery/installation_parent_gallery_test.dart` (states) on
`test/gallery/gallery_harness.dart` (fonts, screenshots, one-page overview). Open both
before writing anything and mirror them. Do not touch `lib/` — if the gallery exposes a
bug, report it (step 6); never fix the widget silently.

## Invariant the gallery enforces
**Every state — valid or not — must (a) render without throwing and (b) leave the user a
way to reach a valid state through the UI.** Invalid states come from imported JSON, deleted
rows, older app versions and feature flags being turned off, so they are reachable by real
users even when the UI itself would never create them. A state that is disabled on purpose
(e.g. a locked replace flow) must say why on screen.

## 1. Understand the widget
- Read the widget, every widget it embeds, and every call site (grep the constructor): the
  different parameter combinations at call sites are states.
- Read the models and validators it depends on (`lib/models/`, `lib/utils/*_validation.dart`,
  `lib/services/*resolver*.dart`) and the `AppSettings` flags that change its behaviour.
- Note where soft-deleted rows disappear: `AppRepository` maps only hold non-deleted rows,
  so a soft-deleted entity usually looks identical to a missing one to the widget. Still
  render both when the maintainer lists both, and caption that they are the same.

## 2. Enumerate the states (the matrix)
Walk these axes and write the result as a short matrix in your reply before coding. Proceed
without waiting unless a state needs a product decision (then ask).
1. **Value states** of every entity the widget displays or links to: present, soft-deleted,
   hard-deleted (id dangling), archived, not installed/inactive, deep nesting, cyclic,
   self-referencing, orphaned by a deleted parent.
2. **Invalid/imported data**: whatever the validators reject, plus what they do *not* reject
   but the UI assumes (depth, ordering, duplicates, empty lists, nulls).
3. **Settings and modes**: each relevant `AppSettings` flag on/off (also: off while the data
   already uses the feature), add/edit/replace modes, new vs existing entity.
4. **Modifiers**: disabled, changed-from-saved, invalid, helper text, error text, empty,
   loading, error.
5. **Content stress**: long names, many items, no items, narrow width, large text scale,
   keyboard open (sheets).
6. **Sheet/dialog internals**: sections, empty sections, search with/without matches,
   collapsed/expanded, hints and suggestion cards, selected/previous/changed markers.
Cover every valid *and* invalid combination that is reachable; skip combinations that cannot
occur (and say which).

## 3. Write the gallery
- File `test/gallery/<snake_case_widget>_gallery_test.dart`, same shape as the reference:
  `@Tags(['gallery'])` + `library;`, header comment with the run command, `prepareGallery`
  in `setUpAll`, one `testWidgets` per entry of `galleryThemes` (light **and** dark),
  `GallerySession.add(...)` per screenshot, `session.finish()` at the end.
- Output goes to `build/gallery/<name>/` (git-ignored). Never write elsewhere, never compare
  against goldens, never add the tag to CI.
- Drive the **real** widget through its real entry point (tap the field to open the real
  sheet; pass real parameters). Mock only the repository/services around it, as the
  reference does; use `AppDatabase.memory()` when the widget needs real persistence.
- **Names:** every user-entered value (bike/component/setup/person names...) is
  `my<Thing><N>` (`myBike1`, `myFork`, `myTire2`) so it is obvious on screen what is user
  data and what the UI generated (UPPERCASE placeholders, hints, warnings, reasons).
- Label each cell/screenshot with the state it shows, in plain words.
- Sheets: tall viewport, crop to the `BottomSheet` rect, one screenshot per sheet state.
- Run `dart format` on the new file only.

## 4. Check the invariant
- **No crash:** flutter_test fails a test on any thrown exception, including RenderFlex
  overflows — the gallery rendering every state is the crash check.
- **Recoverable:** add a second test that, for every enabled invalid state, uses the UI
  (taps, `enterText`) to reach a valid state and asserts the resulting value/callback is
  valid, with the state's label in the `reason:`. The reference does this for the field
  ("every enabled field state can be fixed by picking a bike"). A state that cannot be
  fixed is a finding, not something to hide.

## 5. Run and look
1. `flutter test test/gallery/<file>` — must report the test as **skipped**.
2. `flutter test test/gallery/<file> --run-skipped` — must pass.
3. `Read` `build/gallery/<name>/overview_light.png` and `overview_dark.png` (and single
   screenshots if the overview is too small) and look for: boxes instead of text/icons,
   clipped or overflowing text, unreadable contrast, a state that looks identical to
   another by accident, user data that looks like a UI placeholder (or vice versa).
4. `flutter analyze test/gallery`.

## 6. Report
- Where the PNGs are and the run command.
- The matrix: states covered, states deliberately left out and why.
- **Findings**: any state that crashes, is a trap, looks broken, or is confusing — each with
  the state, what happens, and a suggested fix. Do not fix `lib/` yourself.
- Do not stage or commit (see CLAUDE.md).

---

# Appendix: the Installation scenario catalog (worked example)

This is how many states one small widget has. Use it as the benchmark for completeness.
"Gallery" marks what `installation_parent_gallery_test.dart` covers today; the rest is
covered by unit/widget tests or still open.

## A. Where one installation entry points (the `Installation` value)
| # | State | Gallery |
|---|---|---|
| A1 | Not installed (`Uninstallation`) | yes |
| A2 | Archived (`Archival`) | yes |
| A3 | On a bike that exists | yes |
| A4 | On a bike that was hard-deleted (id dangling) | yes |
| A5 | On a bike that was soft-deleted (repository drops it; same as A4) | yes |
| A6 | On a component that sits on a bike (depth 1) | yes |
| A7 | On a component on a component (depth 2) | yes |
| A8 | Depth 3+ (only via import; the picker caps new picks at depth 2) | yes (3) |
| A9 | Parent component sits on a deleted bike | yes |
| A10 | Parent component is archived | yes |
| A11 | Parent component is in an archived chain | yes |
| A12 | Parent component is not installed | yes |
| A13 | Parent component is in a not installed chain | yes |
| A14 | Parent component hard-deleted | yes |
| A15 | Parent component soft-deleted | yes |
| A16 | Parent's own parent hard-deleted (broken chain) | yes |
| A17 | Parent's own parent soft-deleted (broken chain) | yes |
| A18 | Two components installed on each other (loop) | yes |
| A19 | Component installed on itself (import) | no |
| A20 | Parent is a *descendant* of the edited component (picking it would create a loop) | no (picker hides it when the component carries parts) |

## B. Timeline-level states (`SetInstallationTimeline`, `installation_timeline_validation.dart`)
Each must show a readable error on the offending row **and** be fixable by editing that row:
- Archival that is not the last entry.
- Two uninstallations in a row.
- Two installations on the same bike / the same component in a row.
- Two entries at the same timestamp; several "from beginning" (epoch 0) entries.
- Entry on a bike that no longer exists; on the component itself; a loop that only closes
  later because an ancestor moves while the entry applies.
- Empty timeline; single entry; many entries (scrolling); future-dated entries.
- Entries that are not editable (replace flow) next to editable ones.
- Complex timeline while the Installation Timeline flag is off (must still be shown/editable).
Covered by `test/widgets/set_installation_timeline_test.dart` and the validation tests, not
by the gallery.

## C. Settings and modes
- Subcomponents (`enableInstallOnComponent`) off with component parents already in the data
  (A6–A18 must still display and stay pickable as the current/saved value).
- Subcomponents on; mount suggestion hint shown / not shown.
- Installation Timeline off/on; timeline suggestion shown on a move.
- `allowArchive` false (add mode) while the current value is `Archival`.
- Add / edit / replace (replace locks the field) / new component (no id) / existing component.
- Edited component carries parts (descendants) → every component parent disabled, depth-cap
  hint shown; edited component is a leaf; edited component is itself deep (kept parent stays
  enabled).
- Component type with suggested parents (others behind "Show all", "unusual for a …" hint)
  vs a type with no restriction.

## D. Field modifiers
Enabled, disabled, changed-from-saved, invalid border + tinted content, helper text, error
text, long names (ellipsis), narrow width, large text scale, no label.

## E. Sheet internals
- ≤ 8 options (no search) vs more (search field); query with matches / without.
- Sections: Not installed, Bikes, Components on the current bike, on other bikes, on missing
  bikes, with a missing parent, Uninstalled, Archived. Empty sections left out.
- Rows: enabled, selected, previous-value marker, changed highlight, disabled with reason
  (nested parent), missing bike / missing component (error colour), ancestors column.
- Hints: Subcomponents mount suggestion, Installation Timeline suggestion, depth-cap hint
  (hidden while searching).
- Keyboard open; very long list scrolls to the selected row.

## F. Events that create invalid states at runtime
Delete a bike a component is installed on; delete or archive a parent component that has
children; restore a soft-deleted parent; import JSON with deep nesting or loops; disable
Subcomponents after using it; open an old entry whose referenced rows are gone. For each:
opening the form, editing and saving must not throw, and the user must be able to repair the
value from the UI.
