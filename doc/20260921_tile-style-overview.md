# Tile / card style overview

Snapshot of how the list tiles and cards in `lib/widgets/items/` are styled, focused on differences.
Title sizes marked "default" come from the Material 3 `ListTile` default (about 16 sp) and were not verified in a running app.

## Two families

- **Card family:** each item is its own `Card`, title uses `titleMedium`. `GarageBikeCard`, `PersonListCard`, `RatingListCard`, `TaskRuleListCard`, `GarageUninstalledCard`.
- **Row family:** timeline rows without a card, compact `ListTile`, bold title. `TaskEntryListItem`, `InstallationListTile`, `ReplacementListTile`, `RatingEntryListTile`, `StravaListTile`. `SetupTile` is a custom layout that mostly follows this family.

`ComponentListCard` is a `Card` but is currently styled like the row family (hybrid).

## Title and layout

| Item | Container | Title style | dense / visualDensity | titleAlignment | contentPadding | Leading gap |
|---|---|---|---|---|---|---|
| GarageBikeCard | Card, margin v4 | `titleMedium`, no bold | dense only | default | h16 v8 | default |
| PersonListCard | Card | `titleMedium` | not dense, minTileHeight 0 | default | h16 v8 | default |
| RatingListCard | Card | `titleMedium` | dense only | default | h16, vertical not recorded | default |
| TaskRuleListCard | Card | `titleMedium`, line-through if done | none, minTileHeight 0 | top | L16 T4 R16 B4 | default |
| ComponentListCard (now) | Card | bold, default size | dense; compact commented out | titleHeight | L16 R16 T8 B4 (or 8) | default (`minLeadingWidth` and gap commented out) |
| TaskEntryListItem | none (Material + InkWell) | bold, default size | dense + compact | top | L16 R16 T8 B4 (or 8) | minLeadingWidth 0, gap 8, minVerticalPadding 0 |
| InstallationListTile | none | bold | dense + compact | top | L16 R16 T8 B4 | same as TaskEntry |
| ReplacementListTile | none | bold | dense + compact | top | L16 R16 T8 B4 | same |
| RatingEntryListTile | none | bold | dense + compact | top | L16 R16 T8 B4 | same |
| StravaListTile | none | bold, 1 line | dense only | titleHeight | h16 only | minLeadingWidth 0, gap 8 |
| SetupTile / SetupTileHeader | custom Stack | `titleMedium` + bold, up to 3 lines | not a `ListTile` | n/a | h16, content T8 B8 | 8px `SizedBox` |

## Subtitle, meta and notes

| Item | Subtitle / meta text | Icon size | Notes text | Notes icon | Meta alpha | Notes alpha |
|---|---|---|---|---|---|---|
| GarageBikeCard | 13 | 13 | 13 | full colour | 0.8 | 0.8 |
| PersonListCard | 13 | 13 | none | none | 0.8 | none |
| RatingListCard | 13 | 13 | 13 | 13, 0.8 text | 0.8 | 0.8 |
| TaskRuleListCard | 13 | 13 | 13 | 13, full colour | 0.8 | 0.8 |
| ComponentListCard (now) | 12 | 12 | 12 | 12, full colour | 0.8 | 0.8 |
| TaskEntryListItem | 12 | 12 | 12 | 12 | 0.8 | 0.6 |
| InstallationListTile | 12 (`TileMetaRow`) | 12 | none | none | 0.8 | none |
| ReplacementListTile | 12 | 12 to 14 | none | none | 0.6 to 0.8 (emphasized) | none |
| RatingEntryListTile | 12 | 12 | 12 | 12, 0.6 | 0.8 | 0.6 |
| StravaListTile | 12 | 12 | none | none | 0.8 | none |
| SetupTileHeader | 12 (`TileMetaRow`, muted) | 12 | 12 | 12, 0.6 | 0.8 or 0.6 (muted) | 0.6 |

## Bottom block and extras

| Item | Notes / stats placement | Stats style | Bottom padding |
|---|---|---|---|
| GarageBikeCard | notes in subtitle | none | tile v8, then component grid `fromLTRB(12,0,12,12)` |
| PersonListCard | none | none | 8 before the adjustment list |
| RatingListCard | notes in subtitle | none | 16 |
| TaskRuleListCard | notes in subtitle | progress bar (8px gap above) | tile 4 |
| ComponentListCard (now) | notes and stats in a bottom block | plain text items, 12 px, medium weight (no chip) | 4 (adjustments follow) or 8 |
| TaskEntryListItem | bottom block, L16 R16 B8 | chip: `primaryContainer` at 0.5, radius 4, 10 px bold | 8 |
| RatingEntryListTile | bottom block | chip like TaskEntry | 8 |
| StravaListTile | stats only, bottom block | chip in Strava orange at 0.12, 10 px bold | 8 |
| SetupTileHeader | metadata and notes, 6px top padding | none | 8 |

## Main inconsistencies

1. **Title:** row family is bold at the default size; card family is `titleMedium` (w500) with no explicit bold. `SetupTile` is both. `ComponentListCard` mixes the two (bold + default size inside a `Card`).
2. **Secondary text:** 13 px in the card family, 12 px in the row family. `ComponentListCard` is now 12, the only card at 12.
3. **Notes alpha:** 0.8 in the cards and `ComponentListCard`, 0.6 in `TaskEntry`, `RatingEntry` and `SetupTile`.
4. **Stats:** `ComponentListCard` uses plain 12 px text; `TaskEntry` and `Strava` use a chip at 10 px bold.
5. **Compact settings** (`visualDensity`, `minLeadingWidth`, gap 8, `minVerticalPadding`) are applied in every row-family tile except `StravaListTile`, and commented out in `ComponentListCard`.
6. **`titleAlignment`:** `titleHeight` in `ComponentListCard` and `StravaListTile`, `top` elsewhere in the row family.
7. The notes row (`Row`, 3px top padding, icon, `NotesText`) is copy-pasted in about six files.

## Recommendation

`ComponentListCard` is nested inside `GarageBikeCard` and `GarageUninstalledCard` and also appears in the details lists, so the row-family style fits best:

- Bold title at the default size.
- 12 px secondary text.
- Notes at alpha 0.6 with a 0.6 icon, like `TaskEntry`.
- Compact `ListTile` settings.
- `titleAlignment: top`.
- Stats as a small chip, or plain text if the chip looks noisy inside the card.

Keep the `Card` container. The alternative is to align with the card family (13 px, `titleMedium`, notes 0.8), but that makes the nested component card as large as its parent bike card.

Follow-up: a shared `NotesRow` widget, and the existing `TileMetaRow` for ancestors and stats, would remove the copy-paste and stop the sizes and alphas from drifting.
