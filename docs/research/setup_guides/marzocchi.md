# Marzocchi — setup guide research

Catalog files: `data/component_presets/fork/marzocchi.yaml`, `data/component_presets/shock/marzocchi.yaml`
Researched: 2026-10-11

## Summary

- Every catalog product has a tier-1 guide. Sources are the Marzocchi tuning guides and owner's guides on
  tech.ridefox.com, plus the PDFs that the bike.marzocchi.com product pages link (Shopify CDN).
- Fork shapes:
  - rider weight → psi, as single values with lb and kg both printed;
  - rider weight → rebound clicks counted from closed;
  - a SAG band of 15-20 %, with a mm table per travel;
  - factory and maximum volume-spacer counts per travel;
  - for the 58, a base LSC constant;
  - for the Z1 Coil, rider weight → spring colour.
- Shock shapes:
  - Bomber Air: a formula (psi = rider weight in lb), a pressure → rebound table that is a second-order
    input, and a 25-30 % SAG band.
  - Bomber CR: a 30 % SAG constant. The bike.marzocchi.com spring calculator is a spring-rate formula
    that needs rear-wheel travel and stroke.
- Encoding:
  - the Bomber Air rebound, keyed on pressure, is an adjuster input (R4) with an open `<100` row (R1);
  - the Z1 Coil spring colours become a categorical `Spring` adjuster (R9), once the editions agree.
- No rule, note only:
  - the Z2 E-Bike+ column, which has no catalog option (#72);
  - the Bomber CR spring formula, which needs a bike input (rear wheel travel, #71).
- No click-direction conflicts: every click table counts from closed (clockwise to the stop, then
  counter-clockwise), the same as the catalog `dial_ccw` default.

## Guide `marzocchi_z1_2024` — BOMBER Z1 Owner's Guide

### Source

- URL: https://cdn.shopify.com/s/files/1/0618/4989/5143/files/605-00-311_REV_B_-_Marzocchi_BOMBER_Z1_Owners_Guide.pdf (linked as "Bomber Z1 Tuning Guide" from https://bike.marzocchi.com/products/bomber-z1)
- Document: Marzocchi BOMBER Z1 Owner's Guide, 605-00-311 REV B, © 2024, English (multilingual PDF; EN pp. 1-14)
- Section / page: p. 8 (max/min pressure), p. 9 (coil spring information), p. 10 (sag, pressure + rebound), p. 11 (RAIL rebound direction), p. 12 (volume spacers)
- Retrieved: 2026-10-11
- Older edition: 605-00-256 REV B "Bomber Z1 & DJ Tuning Guide" (© 2020, GRIP-era). It gives the same air
  pressures, rebound clicks and spacer counts, and adds sag/spacer rows for 100, 130 and 180 mm (see
  `marzocchi_z1_dj_2020`). Its coil table uses different weight bands; see "Coil spring" below.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/marzocchi/z1/standard` | `damper: rail` | Air Z1. Catalog travel options 100/150/160. Guide covers 140-170 |
| `fork/marzocchi/z1-coil/coil` | `damper: rail` | Coil table only. Rebound table is labelled for air pressure |

Gaps:
- This guide has no 100 mm row for sag or spacers. The 2020 guide has a 100 mm sag row, but its 100 mm
  spacer row is for the DJ.
- The guide lists 140 and 170 mm; the catalog Z1 has neither as a `travel_mm` option.

### Air pressure

Input: rider weight (lb, kg also printed) · Output: psi (bar also printed) · `when: { damper: rail }` on `fork/marzocchi/z1/standard`

| Rider weight (lbs) | Rider weight (kgs) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 55 | 3.8 |
| 130-140 | 59-64 | 59 | 4.1 |
| 140-150 | 64-68 | 63 | 4.3 |
| 150-160 | 68-73 | 67 | 4.6 |
| 160-170 | 73-77 | 72 | 5.0 |
| 170-180 | 77-82 | 76 | 5.2 |
| 180-190 | 82-86 | 80 | 5.5 |
| 190-200 | 86-91 | 85 | 5.9 |
| 200-210 | 91-95 | 89 | 6.1 |
| 210-220 | 95-100 | 93 | 6.4 |
| 220-230 | 100-104 | 97 | 6.7 |
| 230-240 | 104-109 | 102 | 7.0 |
| 240-250 | 109-113 | 106 | 7.3 |

### Rebound — RAIL

The guide tells you to read rebound from your air pressure, but prints it keyed on rider weight, in the
same table as the pressure. Encode it on `rider_weight`.

Source direction: from closed (clockwise to the stop, then counter-clockwise). Catalog: `rail` `rebound`, default `dial_ccw`, max 13 (estimate from this table) → same direction, encode as published.

| Rider weight (lbs) | Rider weight (kgs) | Rebound (clicks) |
|---|---|---|
| 120-130 | 54-59 | 13 |
| 130-140 | 59-64 | 12 |
| 140-150 | 64-68 | 11 |
| 150-160 | 68-73 | 10 |
| 160-170 | 73-77 | 9 |
| 170-180 | 77-82 | 8 |
| 180-190 | 82-86 | 7 |
| 190-200 | 86-91 | 6 |
| 200-210 | 91-95 | 5 |
| 210-220 | 95-100 | 4 |
| 220-230 | 100-104 | 3 |
| 230-240 | 104-109 | 2 |
| 240-250 | 109-113 | 1 |

The dial graphic beside the table prints "OPEN 9 8 7 6 5 4 3 2 1 CLOSED", nine positions, which conflicts
with the 13-click table. The table is the data; the graphic is decorative.

### Coil spring — Z1 Coil

Input: rider weight · Output: spring colour / label (no rate) · `fork/marzocchi/z1-coil/coil`.
The catalog `spring_rate` is lbs/in. The guide gives no rate, only colours, so the catalog type follows the
guide (R9): a categorical `Spring` adjuster with the published colour labels as options, replacing the
numerical `spring_rate` on this trim. The two editions disagree (below), so neither is encoded until resolved.

2024 guide (p. 9). The header row is misprinted as "BOMBER Z1 Pressure" / "BOMBER Z1 Rebound Setting";
the columns hold the colour and the label:

| Rider weight (lbs) | Rider weight (kgs) | Spring colour | Label |
|---|---|---|---|
| 120-130 | 54-59 | Purple | Soft |
| 130-140 | 59-64 | Blue | Medium |
| 140-150 | 64-68 | Green | Firm |
| 150-160 | 68-73 | Yellow | X-Firm |

2020 guide 605-00-256 (p. 3), different bands:

| Rider weight (lbs) | Rider weight (kgs) | Spring colour | Spring rate (label) |
|---|---|---|---|
| 120-150 | 54-68 | Purple | Soft |
| 150-180 | 68-82 | Blue | Medium |
| 180-210 | 82-95 | Green | Firm |
| 210-250 | 95-113 | Yellow | X-Firm |

The two editions disagree. The 2024 bands cover only 120-160 lb, which looks like a copy error (they repeat
the first four weight rows of the air table). Follow-up: confirm with Marzocchi before encoding either.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open (while setting sag) | — | `damper: rail`; procedure, not a riding setting: no rule, `note` only (R9) |

### SAG

Band 15-20 % of travel (15 % "Firm", 20 % "Plush"). Set it with the compression lever in OPEN. Coil:
adjust preload until sag is 15-20 %.

| Travel | 15% sag (Firm) | 20% sag (Plush) |
|---|---|---|
| 140 mm (5.5 in) | 21 mm (0.8 in) | 28 mm (1.1 in) |
| 150 mm (5.9 in) | 22 mm (0.9 in) | 30 mm (1.2 in) |
| 160 mm (6.3 in) | 24 mm (1.0 in) | 32 mm (1.3 in) |
| 170 mm (6.7 in) | 26 mm (1.0 in) | 34 mm (1.3 in) |

Rows for travels the 2024 table omits, from the 2020 Z1/DJ guide (inch values as printed there):

| Travel | 15% sag (Firm) | 20% sag (Plush) |
|---|---|---|
| 100 mm (3.9 in) | 15 mm (0.6 in) | 20 mm (0.8 in) |
| 130 mm (5.1 in) | 19.5 mm (0.7 in) | 26 mm (1.0 in) |
| 180 mm (7.1 in) | 27 mm (1.1 in) | 36 mm (1.4 in) |

Encoding: `sag` `range: [15, 20]` %, no `when`. The mm values are 15 %/20 % of travel and do not need their
own rules.

### Volume spacers

Factory-installed count per travel (2024 p. 12; identical in 2020):

| Travel | Factory installed | Max |
|---|---|---|
| 170 mm | 1 | 6 |
| 160 mm | 2 | 7 |
| 150 mm | 3 | 7 |
| 140 mm | 4 | 8 |

2020 adds 180 mm 1 / max 5 and 130 mm 5 / max 8. `volume_spacers` rows on `travel_mm` (literal points):
150 → 3 and 160 → 2 are the catalog options. 100 mm has no Z1 row (see gaps).

### Pressure limits

Max 120 psi (catalog `max: 120` ✓). Minimum 40 psi (p. 8; catalog `min: 0`). Pressures are measured at
70-75 °F.

### Formulas

None.

### Does not fit B3

- Coil spring colours carry no rate in the catalog's unit → a categorical `Spring` adjuster with the colour options (R9), once the edition conflict is resolved.

## Guide `marzocchi_z1_dj_2020` — Bomber Z1 & DJ Tuning Guide

### Source

- URL: https://tech.ridefox.com/img/help/page2836-KNVM/inline/605-00-256_RevB_DJ-Z1_TuningGuide.pdf (byte-identical copy linked from https://bike.marzocchi.com/products/bomber-dj as `Marzocchi_Z1_and_Bomber_DJ_Tuning_Guide.pdf`)
- Document: Marzocchi Tuning Guide BOMBER Z1 and DJ, 605-00-256 REV B, © 2020, English
- Section / page: p. 2 (sag), p. 3 (air pressure, coil, max pressure), p. 4 (rebound), p. 5 (GRIP sweep, Z1 Coil preload), p. 8 (volume spacers)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/marzocchi/dj/standard` | `damper: grip` | Primary use. The Z1 uses the 2024 guide |

Gaps: none for the DJ (100 mm, 26").

### Air pressure — BOMBER Z1 and DJ column

Input: rider weight (lb, kg) · Output: psi · `when: { damper: grip }` on `fork/marzocchi/dj/standard`

| Rider weight (lbs) | Rider weight (kgs) | psi |
|---|---|---|
| 120-130 | 54-59 | 55 |
| 130-140 | 59-64 | 59 |
| 140-150 | 64-68 | 63 |
| 150-160 | 68-73 | 67 |
| 160-170 | 73-77 | 72 |
| 170-180 | 77-82 | 76 |
| 180-190 | 82-86 | 80 |
| 190-200 | 86-91 | 85 |
| 200-210 | 91-95 | 89 |
| 210-220 | 95-100 | 93 |
| 220-230 | 100-104 | 97 |
| 230-240 | 104-109 | 102 |
| 240-250 | 109-113 | 106 |

### Rebound — GRIP (DJ)

Source direction: from closed. Catalog: `grip` `rebound`, `dial_ccw`, max 13 (estimate) → same direction, encode as published.

| Rider weight (lbs) | Rider weight (kgs) | Rebound (clicks) |
|---|---|---|
| 120-130 | 54-59 | 13 |
| 130-140 | 59-64 | 12 |
| 140-150 | 64-68 | 11 |
| 150-160 | 68-73 | 10 |
| 160-170 | 73-77 | 9 |
| 170-180 | 77-82 | 8 |
| 180-190 | 82-86 | 7 |
| 190-200 | 86-91 | 6 |
| 200-210 | 91-95 | 5 |
| 210-220 | 95-100 | 4 |
| 220-230 | 100-104 | 3 |
| 230-240 | 104-109 | 2 |
| 240-250 | 109-113 | 1 |

### Constants / base tune

None beyond the volume spacers.

### SAG

Band 15-20 % of travel; the 100 mm row is 15 mm (0.6 in) Firm / 20 mm (0.8 in) Plush. Set it with the
lever in OPEN. Full table (100/130-180 mm) under `marzocchi_z1_2024` → SAG.

### Volume spacers

| Travel | Factory installed | Max |
|---|---|---|
| 100 mm | 8 | 10 |

`volume_spacers` `value: 8` on `fork/marzocchi/dj/standard` (catalog max 10 ✓). The guide's Z1 rows are
recorded under `marzocchi_z1_2024`.

### Pressure limits

Max 120 psi for Z1 and DJ (catalog `max: 120` ✓). The 2021 Marzocchi Forks Owner's Guide (605-00-255 REV A,
p. 6) adds a 40 psi minimum for all Bomber air forks.

### Formulas

None.

### Does not fit B3

Nothing.

## Guide `marzocchi_z2_2019` — Bomber Z2 Tuning Guide

### Source

- URL: https://tech.ridefox.com/img/help/page2836-KNVM/inline/605-00-237-%20RevA_Z2_TuningGuide.pdf
- Document: Marzocchi Tuning Guide BOMBER Z2, 605-00-237 REV A, © 2019, English
- Section / page: p. 2 (sag), p. 3 (air pressure, max), p. 4 (rebound), p. 8 (volume spacers)
- Retrieved: 2026-10-11
- The current product page (https://bike.marzocchi.com/products/bomber-z2) links the older 605-00-207
  REV A (© 2018, https://cdn.shopify.com/s/files/1/1640/5435/files/605-00-207_RevA_Z2_TuningGuide-Bomber-z2.pdf).
  That edition has the same standard Z2 pressures and spacer counts, has no E-Bike+ column, and differs in
  two rebound rows (see below). The 2019 edition is the newer one and is recorded here.
- No RAIL 2.0 / 2024+ Z2 owner's guide was found (searched marzocchi.com product pages and tech.ridefox.com).

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/marzocchi/z2/standard` | `damper: rail` | Standard column only |

Gaps:
- The guide has an "E-Bike+" column (pressure, rebound, spacers). The catalog has no E-Bike+ node or option;
  the tune is only mentioned in notes and in the `pressure` max of 140. Transcribed below, not encoded.
- The guide has 100/110 mm rows; the catalog Z2 travel options are 120-150.

### Air pressure

Input: rider weight (lb, kg) · Output: psi · `when: { damper: rail }` on `fork/marzocchi/z2/standard`

| Rider weight (lbs) | Rider weight (kgs) | BOMBER Z2 psi | BOMBER Z2 E-Bike+ psi (not encoded) |
|---|---|---|---|
| 120-130 | 54-59 | 58 | 65 |
| 130-140 | 59-64 | 63 | 70 |
| 140-150 | 64-68 | 68 | 74 |
| 150-160 | 68-73 | 72 | 80 |
| 160-170 | 73-77 | 77 | 85 |
| 170-180 | 77-82 | 82 | 90 |
| 180-190 | 82-86 | 86 | 96 |
| 190-200 | 86-91 | 91 | 101 |
| 200-210 | 91-95 | 96 | 106 |
| 210-220 | 95-100 | 100 | 111 |
| 220-230 | 100-104 | 105 | 116 |
| 230-240 | 104-109 | 110 | 121 |
| 240-250 | 109-113 | 114 | 126 |

### Rebound — RAIL

Source direction: from closed. Catalog: `rail` `rebound`, `dial_ccw`, max 13 → same direction, encode as published.

| Rider weight (lbs) | Rider weight (kgs) | BOMBER Z2 | BOMBER Z2 E-Bike+ (not encoded) |
|---|---|---|---|
| 120-130 | 54-59 | 13 | 10 |
| 130-140 | 59-64 | 10 | 9 |
| 140-150 | 64-68 | 9 | 9 |
| 150-160 | 68-73 | 9 | 8 |
| 160-170 | 73-77 | 8 | 8 |
| 170-180 | 77-82 | 8 | 7 |
| 180-190 | 82-86 | 8 | 7 |
| 190-200 | 86-91 | 7 | 6 |
| 200-210 | 91-95 | 7 | 5 |
| 210-220 | 95-100 | 6 | 3 |
| 220-230 | 100-104 | 4 | 2 |
| 230-240 | 104-109 | 3 | 1 |
| 240-250 | 109-113 | 2 | 1 |

605-00-207 (2018) standard column differs at 180-190 lb (7 instead of 8) and 220-230 lb (5 instead of 4).
All other rows match.

### Constants / base tune

None.

### SAG

Band 15-20 % (Firm/Plush), set with the lever in OPEN.

| Travel | 15% sag (Firm) | 20% sag (Plush) |
|---|---|---|
| 100 mm (3.9 in) | 15 mm (0.6 in) | 20 mm (0.8 in) |
| 110 mm (4.3 in) | 17 mm (0.65 in) | 22 mm (0.85 in) |
| 120 mm (4.7 in) | 18 mm (0.7 in) | 24 mm (0.9 in) |
| 130 mm (5.1 in) | 19.5 mm (0.7 in) | 26 mm (1.0 in) |
| 140 mm (5.5 in) | 21 mm (0.8 in) | 28 mm (1.1 in) |
| 150 mm (5.9 in) | 22 mm (.9 in) | 30 mm (1.2 in) |

### Volume spacers

| Travel | Z2 factory | Z2 max | E-Bike+ factory (not encoded) | E-Bike+ max |
|---|---|---|---|---|
| 150 mm | 0 | 4 | 2 | 4 |
| 140 mm | 0 | 4 | 3 | 4 |
| 130 mm | 1 | 5 | 4 | 5 |
| 120 mm | 2 | 5 | 4 | 5 |
| 110 mm | 3 | 6 | 5 | 6 |
| 100 mm | 4 | 6 | 6 | 6 |

`volume_spacers` rows on `travel_mm`: 120 → 2, 130 → 1, 140 → 0, 150 → 0.

### Pressure limits

Z2 max 120 psi; E-Bike+ max 140 psi. The catalog `pressure` `max: 140` covers both; its notes say so ✓.

### Formulas

None.

### Does not fit B3

- E-Bike+ column: no catalog node or option → not encoded. Encoding it would need a `tune: ebike_plus`
  option (or node) on the Z2.

## Guide `marzocchi_58_2017` — Bomber 58 Tuning Guide

### Source

- URL: https://tech.ridefox.com/img/help/page2836-KNVM/inline/605-00-174-58_TuningGuide-revA.pdf (byte-identical copy linked from https://bike.marzocchi.com/products/bomber-58)
- Document: Marzocchi Tuning Guide BOMBER 58, 605-00-174 REV A, © 2017, English
- Section / page: p. 2 (sag), p. 3 (air pressure), p. 4 (rebound), p. 5 (GRIP LSC), p. 7 (volume spacers)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/marzocchi/58/standard` | `damper: grip_58` | 203 mm, 27.5" |

Gaps: none.

### Air pressure

Input: rider weight (lb, kg) · Output: psi · `when: { damper: grip_58 }`

| Rider weight (lbs) | Rider weight (kgs) | psi |
|---|---|---|
| 120-130 | 54-59 | 49 |
| 130-140 | 59-64 | 53 |
| 140-150 | 64-68 | 57 |
| 150-160 | 68-73 | 61 |
| 160-170 | 73-77 | 65 |
| 170-180 | 77-82 | 69 |
| 180-190 | 82-86 | 73 |
| 190-200 | 86-91 | 76 |
| 200-210 | 91-95 | 80 |
| 210-220 | 95-100 | 84 |
| 220-230 | 100-104 | 88 |
| 230-240 | 104-109 | 92 |
| 240-250 | 109-113 | 96 |

### Rebound — GRIP (58)

Source direction: from closed (full clockwise, then back out counter-clockwise). Catalog: `grip_58` `rebound`, `dial_ccw`, max 13 (estimate) → same direction, encode as published.

| Rider weight (lbs) | Rider weight (kgs) | Rebound (clicks) |
|---|---|---|
| 120-130 | 54-59 | 13 |
| 130-140 | 59-64 | 12 |
| 140-150 | 64-68 | 11 |
| 150-160 | 68-73 | 10 |
| 160-170 | 73-77 | 9 |
| 170-180 | 77-82 | 8 |
| 180-190 | 82-86 | 7 |
| 190-200 | 86-91 | 6 |
| 200-210 | 91-95 | 5 |
| 210-220 | 95-100 | 4 |
| 220-230 | 100-104 | 3 |
| 230-240 | 104-109 | 2 |
| 240-250 | 109-113 | 1 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression` | 4 | from closed (full clockwise, back out CCW); catalog `grip_58` `compression` `dial_ccw` max 8 → same, encode as published | `damper: grip_58` |

The diagram marks 4 clicks out on an 8-click (OPEN = 8 clicks) range. Sag is set with the LSC fully open
(counter-clockwise).

### SAG

Band 15-20 %. 203 mm (8 in): 30 mm (1.2 in) Firm / 41 mm (1.6 in) Plush.

### Volume spacers

| Travel | Factory installed | Max |
|---|---|---|
| 203 | 4 | 7 |

`volume_spacers` `value: 4` (catalog max 7 ✓).

### Pressure limits

Max 120 psi (catalog ✓). The 2021 Forks Owner's Guide gives a 40 psi minimum.

### Formulas

None.

### Does not fit B3

Nothing.

## Guide `marzocchi_bomber_air_2022` — Bomber Air Shock Owner's Guide

### Source

- URL: https://tech.ridefox.com/img/help/page2836-KNVM/inline/605-00-269_REV_A%202022%20Marzocchi%20Bomber%20Air%20Shock%20Owners%20Guide%20Rev%20A_FINAL.pdf (same document linked from https://bike.marzocchi.com/products/bomber-air)
- Document: 2022 Marzocchi Bomber Air Shock Owner's Guide, 605-00-269 REV A, English (multilingual; EN pp. 1-7)
- Section / page: p. 4 (sag procedure, start pressure, max), p. 5 (sag table), p. 6 (compression, rebound table)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/marzocchi/bomber-air/metric` | `damper: bomber_air` | all `size` options |
| `shock/marzocchi/bomber-air/trunnion` | `damper: bomber_air` | all `size` options |

Gaps: the sag table lists 45/55/65/75 mm strokes only. Catalog strokes 50, 52.5, 57.5, 60 and 62.5 have
no mm row, but the % band covers them.

### Air pressure

Formula: start with the shock pressure in psi equal to the rider's weight in pounds, then adjust to sag.
No weight range is stated. See Formulas.

### Rebound — Bomber Air

Input: **air pressure (psi)**, not rider weight. Source direction: from closed (clockwise to the stop, then CCW). Catalog: `bomber_air` `rebound`, `dial_ccw`, max 10 → same direction, encode as published.

| Air pressure (psi) | Starting rebound setting (clicks) |
|---|---|
| <100 | 10 |
| 100-120 | 10 |
| 120-140 | 9 |
| 140-160 | 8 |
| 160-180 | 7 |
| 180-200 | 6 |
| 200-220 | 5 |
| 220-240 | 4 |
| 240-260 | 3 |
| 260-280 | 2 |
| 280-300 | 1 |

The Spanish section prints the same rows with bar (psi): <6.9 (100) … 19.3-20.7 (280-300).

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open (fully counter-clockwise) as the starting / sag setting | — | `damper: bomber_air` |

### SAG

Band 25-30 % of shock travel (25 % "Firm", 30 % "Plush").

| Travel | 25% sag (Firm) | 30% sag (Plush) |
|---|---|---|
| 45 mm (1.7 in) | 11.25 mm (0.44 in) | 13.5 mm (0.53 in) |
| 55 mm (2.16 in) | 13.75 mm (0.54 in) | 16.5 mm (0.65 in) |
| 65 mm (2.56 in) | 16.25 mm (0.64 in) | 19.5 mm (0.77 in) |
| 75 mm (2.95 in) | 18.75 mm (0.74 in) | 22.5 mm (0.88 in) |

Encoding: `sag` `range: [25, 30]` %.

### Volume spacers

None as a count. Spacers come in 0.1 in³ steps (BOMBER AIR Volume Tuning Kit). The compatibility chart
605-01-348 REV A (https://cdn.shopify.com/s/files/1/1640/5435/files/605-01-348_REV_A_Instruction-_BOMBER_AIR_Volume_Spacer_Installation_FINAL.pdf)
lists allowed spacer volumes and the resulting compression ratios per eye-to-eye/stroke. It gives no
factory or recommended volume; the catalog has no Volume Spacers adjuster.

### Pressure limits

Max 350 psi (catalog `max: 350` ✓). The rebound table ends at 300 psi.

### Formulas

Pressure (psi) ≈ rider weight in lb. Calculated from the published formula (no range stated → 50-120 kg; 1 kg = 2.20462 lb):

| Rider weight (kg) | Start pressure (psi) |
|---|---|
| 50 | 110.2 |
| 55 | 121.3 |
| 60 | 132.3 |
| 65 | 143.3 |
| 70 | 154.3 |
| 75 | 165.3 |
| 80 | 176.4 |
| 85 | 187.4 |
| 90 | 198.4 |
| 95 | 209.4 |
| 100 | 220.5 |
| 105 | 231.5 |
| 110 | 242.5 |
| 115 | 253.5 |
| 120 | 264.6 |

### Does not fit B3

- Rebound keyed on air pressure: a rule with `input: pressure` (the rider's current or recommended
  `pressure` value). It chains off the formula result. Proposed: `target: rebound`, `input: pressure`,
  `rows` as above, with `<100` as an open lower bound (R1, R4).
- The formula is linear (psi = lb): the calculated rows above as `rider_weight` rows (Q1), reproduced exactly
  by interpolation.

## Guide `marzocchi_bomber_cr_2018` — Bomber CR Tuning Guide

### Source

- URL: https://tech.ridefox.com/img/help/page2836-KNVM/inline/605-00-205_Marzocchi-BomberCR-Tuning-Guide-white-RevA.pdf
- Document: Marzocchi Tuning Guide (Bomber CR), 605-00-205 REV A, © 2018, English
- Section / page: p. 2 (sag 30 %, preload), p. 3 (sag table), pp. 4-5 (LSC/rebound directions only)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/marzocchi/bomber-cr/standard` | `damper: bomber_cr` | |
| `shock/marzocchi/bomber-cr/trunnion` | `damper: bomber_cr` | |

Gaps: no click recommendations for compression or rebound. Directions only: clockwise is more damping on
both.

### Constants / base tune

None for clicks. Preload: increase sag by turning counter-clockwise; at most two full turns clockwise. The
2019 Marzocchi Rear Shock User Manual (605-00-201 REV A, p. 4) says to tighten until the spring stops moving,
then one more full turn. The catalog has no preload adjuster (`missing_adjustments: [Preload]`), so these are
notes only.

### SAG

30 % of shock travel (a single target, not a band).

| Travel | 30% sag |
|---|---|
| 50 mm / 2.0 in | 15 mm / 0.6 in |
| 55 mm / 2.25 in | 17 mm / 0.68 in |
| 65 mm / 2.50 in | 19 mm / 0.75 in |
| 70 mm / 2.75 in | 21 mm / 0.82 in |
| 75 mm / 3.00 in | 22 mm / 0.90 in |

The inch labels are printed as-is; several do not match their mm value (e.g. 55 mm / 2.25 in). Encoding:
`sag` `value: 30` %.

### Formulas

Not in the PDF. The spring calculator in the add-to-cart popup on https://bike.marzocchi.com/products/bomber-cr-rear-shock
(also https://bike.marzocchi.com/pages/spring-calculator) computes the coil rate. Read from the page's
`theme.js` (bike.marzocchi.com/cdn/shop/t/68/assets/theme.js), retrieved 2026-10-11:

- spring rate (lbs/in) = (rider weight in lb / 165) × 400 × (rear wheel travel in inches / stroke in inches²)
- Inputs: rider weight (lb, or kg × 2.205) and rear wheel travel (in, or mm / 25.4). Stroke comes from the
  selected shock size (mm / 25.4 for Metric and Metric Trunnion; inch figure for Imperial).
- The result is rounded to the nearest 50 lbs/in and mapped to the spring SKU for that stroke.

Calculated from the published formula. Example only: a 230x65 shock (65 mm stroke) on a bike with 160 mm
of rear wheel travel, 50-120 kg (no range stated):

| Rider weight (kg) | Raw rate (lbs/in) | Rounded (lbs/in) |
|---|---|---|
| 50 | 257.1 | 250 |
| 55 | 282.8 | 300 |
| 60 | 308.5 | 300 |
| 65 | 334.2 | 350 |
| 70 | 359.9 | 350 |
| 75 | 385.6 | 400 |
| 80 | 411.3 | 400 |
| 85 | 437.0 | 450 |
| 90 | 462.8 | 450 |
| 95 | 488.5 | 500 |
| 100 | 514.2 | 500 |
| 105 | 539.9 | 550 |
| 110 | 565.6 | 550 |
| 115 | 591.3 | 600 |
| 120 | 617.0 | 600 |

### Does not fit B3

- The spring-rate formula needs rear wheel travel, a bike input with no catalog or B3 input, plus stroke
  (derivable from the `size` option). No rule until bike-level inputs exist (#71); the calculator link stays
  in the notes. Catalog `spring_rate` is lbs/in ✓ (same unit).

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| — | Every catalog product has at least a SAG band. The Bomber CR has no click or spring table in its PDF (only the web calculator formula above). |

## Catalog changes before encoding (R8, R9)

R8 fixes: none found; every click table fits the catalog maxima.

R9 type changes:
- `fork/marzocchi/z1-coil/coil`: a categorical `Spring` adjuster with the
  published colour labels instead of the numerical `spring_rate`, once the
  2020 / 2024 charts are reconciled.

## Follow-ups

- Z1 Coil spring chart: the 2024 owner's guide (120-160 lb in 10 lb steps) and the 2020 tuning guide
  (120-250 lb in 30-40 lb steps) disagree. Ask Marzocchi which is right before encoding.
- Z1 `travel_mm: 100` in the catalog: no Z1 guide has a 100 mm spacer row (only the DJ's). The 2024 guide
  lists 140-170 mm, and 140/170 are not catalog options. Check the catalog travel list against
  bike.marzocchi.com.
- Z2: the newer RAIL 2.0 Z2 (2024+) has no published tuning guide. The product page still links the 2018
  edition, whose rebound differs from the 2019 edition in two rows. Watch for a 605-00-3xx Z2 owner's guide.
- Z2 E-Bike+: transcribed but not encoded. It needs a catalog option first.
- Rebound dial graphic ("OPEN 9 … 1 CLOSED") contradicts the 13-row tables in every fork guide. The tables are
  taken as the data.
