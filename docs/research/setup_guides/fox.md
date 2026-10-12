# FOX — setup guide research

Catalog files: `data/component_presets/fork/fox.yaml`, `data/component_presets/shock/fox.yaml`
Researched: 2026-10-11 – 2026-10-12

## Summary

- Every source is a FOX owner's manual on tech.ridefox.com (HTML pages, English). The click tables of the
  FLOAT, FLOAT SL/X, DPS, older FLOAT X2 and the coil shocks are images inside those pages; the image URLs
  are given per section and were read directly.
- Fork shapes (one manual per model family and year):
  - rider weight (lb + kg bands of 10 lb) → psi, one column per chassis variant (FLOAT, Rhythm, E-Bike+,
    E-Optimized); the 40 and the 2019-2020 36 print 30-lb bands with a psi **range**;
  - rider weight → rebound clicks from closed, one column per damper (GRIP, GRIP SL, GRIP X, GRIP X2 LSR/HSR,
    FIT4, GRIP2); the 2018-2020 36 and the Podium key rebound on **air pressure** instead;
  - base-tune constants for compression (GRIP X, GRIP X2, GRIP2, FIT4 open-mode adjust);
  - SAG band 15-20 % for every fork, with a mm table per travel;
  - factory-installed and maximum volume spacers per travel (and per E-Bike+/E-Optimized chassis).
- Shock shapes:
  - a formula: start at psi = rider weight in lb (every FOX air shock, 2016-2027);
  - air pressure → rebound clicks (FLOAT, FLOAT SL, FLOAT X, DPS), and air pressure → LSR/HSR/LSC/HSC
    (FLOAT X2), often as click **ranges** ("11-13");
  - coil spring rate → LSR/HSR/LSC/HSC (DHX2), in 2016-2025 split into tables A/B/C chosen by shock stroke ×
    rear-wheel travel;
  - SAG 25-30 % (FLOAT, FLOAT SL, FLOAT X, DPS/DPX2) or ~30 % (FLOAT X2, DHX2, DHX), with a mm table;
  - constants: open-mode adjust 1, levers in Open.
- B3 cannot hold (details per guide): spring-rate input, the A/B/C selector (stroke × rear-wheel travel),
  E-Bike+/E-Optimized columns (no catalog option), the 2027 38 mixed 10 cc/5 cc spacers, "Open"/"Closed"
  cells and "22-Open" ranges, and pressure-keyed rebound (needs `input: pressure`, which B3 lists).
- Counting direction: every FOX table counts clicks out from fully closed (clockwise to the stop, then
  counter-clockwise), the catalog's `dial_ccw` default. No table needs `max − N`.
- **Catalog conflicts found** (rows above the catalog `max`): `grip` rebound (catalog max 10; every GRIP
  table goes to 13, the 32 Taper-Cast to 22), `rail` rebound (max 9; AWL tables go to 10 and 13), and the 40's
  `grip_x2` HSR column (max 8; table goes to 10). See Follow-ups.

---

# Forks

## Guide `fox_32_34_2027` — FORK- 2027 32mm/34mm (Including 32 Step-Cast and 32 Taper-Cast)

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3162/fork--2027-32mm--or-34mm-(including-32-step-cast-and-32-taper-cast)
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Adjusting Grip X Compression Damping", "Tuning with Air Volume Spacers"
- Retrieved: 2026-10-11
- The 2026 manual (owners-manuals/3104) is identical in every table and constant. The 2025 manual
  (owners-manuals/2978) additionally has 34 Step-Cast tables (no catalog node) and lacks the 60 mm sag row.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/32-taper-cast/factory` | `damper: grip_sl` | "32mm Taper-Cast" pressure + rebound GRIP SL column; travel 40/50 |
| `fork/fox/32-taper-cast/performance` | `damper: grip` | "32mm Taper-Cast" pressure + rebound GRIP column; travel 40 |
| `fork/fox/32-step-cast/factory` | `damper: grip_sl` | "32mm Step-Cast" tables; travel 100 |
| `fork/fox/32-step-cast/performance` | `damper: grip` | "32mm Step-Cast" tables (rebound column "GRIP/Grip SL") |
| `fork/fox/34/factory` | `damper: grip_x` | "34mm FLOAT" pressure; no GRIP X rebound column (see gaps); GRIP X compression constant |
| `fork/fox/34/performance-elite` | `damper: grip_x` | as Factory |
| `fork/fox/34/performance` | `damper: grip` | "34mm FLOAT" pressure + "34mm FLOAT/Rhythm" GRIP rebound |
| `fork/fox/34/rhythm` | `damper: grip` | "34mm Rhythm" pressure + "34mm FLOAT/Rhythm" GRIP rebound |

Gaps:
- The manual prints no GRIP X rebound column for the 34 (the 34mm table has a GRIP column only), so
  `fork/fox/34/factory` and `/performance-elite` get no rebound guide from this manual. The 34SL manual's
  combined "GRIP/Grip SL/GRIP X" column is for the 34 SL chassis; do not borrow it.
- "32mm Rhythm" tables and the 32 Rhythm / 32 Step-Cast 60 mm spacer rows have no catalog node.
- GRIP X2 base-tune paragraph in this manual has no catalog 32/34 product with that damper.

### Air pressure — 32mm Taper-Cast

Input: rider weight (lb, kg also printed) · Output: psi (bar also printed) · `fork/fox/32-taper-cast/*`

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 100 | 6.9 |
| 130-140 | 59-64 | 104 | 7.2 |
| 140-150 | 64-68 | 108 | 7.4 |
| 150-160 | 68-73 | 113 | 7.8 |
| 160-170 | 73-77 | 117 | 8.1 |
| 170-180 | 77-82 | 121 | 8.3 |
| 180-190 | 82-86 | 125 | 8.6 |
| 190-200 | 86-91 | 129 | 8.9 |
| 200-210 | 91-95 | 133 | 9.2 |
| 210-220 | 95-100 | 138 | 9.5 |
| 220-230 | 100-104 | 142 | 9.8 |
| 230-240 | 104-109 | 146 | 10.1 |
| 240-250 | 109-113 | 150 | 10.3 |

### Air pressure — 32mm Step-Cast

`fork/fox/32-step-cast/*`

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 65 | 4.5 |
| 130-140 | 59-64 | 70 | 4.8 |
| 140-150 | 64-68 | 74 | 5.1 |
| 150-160 | 68-73 | 80 | 5.5 |
| 160-170 | 73-77 | 85 | 5.9 |
| 170-180 | 77-82 | 90 | 6.2 |
| 180-190 | 82-86 | 96 | 6.6 |
| 190-200 | 86-91 | 101 | 7.0 |
| 200-210 | 91-95 | 106 | 7.3 |
| 210-220 | 95-100 | 111 | 7.7 |
| 220-230 | 100-104 | 116 | 8.0 |
| 230-240 | 104-109 | 121 | 8.3 |
| 240-250 | 109-113 | 126 | 8.7 |

### Air pressure — 32mm Rhythm (no catalog node, transcribed for completeness)

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 65 | 4.5 |
| 130-140 | 59-64 | 70 | 4.8 |
| 140-150 | 64-68 | 74 | 5.1 |
| 150-160 | 68-73 | 80 | 5.5 |
| 160-170 | 73-77 | 85 | 5.9 |
| 170-180 | 77-82 | 90 | 6.2 |
| 180-190 | 82-86 | 96 | 6.6 |
| 190-200 | 86-91 | 101 | 7.0 |
| 200-210 | 91-95 | 106 | 7.3 |
| 210-220 | 95-100 | 111 | 7.7 |
| 220-230 | 100-104 | 116 | 8.0 |
| 230-240 | 104-109 | 121 | 8.3 |
| 240-250 | 109-113 | 126 | 8.7 |

### Air pressure — 34mm FLOAT

`fork/fox/34/factory`, `/performance-elite`, `/performance`

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 64 | 4.4 |
| 130-140 | 59-64 | 69 | 4.8 |
| 140-150 | 64-68 | 74 | 5.1 |
| 150-160 | 68-73 | 78 | 5.4 |
| 160-170 | 73-77 | 83 | 5.7 |
| 170-180 | 77-82 | 88 | 6.1 |
| 180-190 | 82-86 | 92 | 6.3 |
| 190-200 | 86-91 | 97 | 6.7 |
| 200-210 | 91-95 | 102 | 7.0 |
| 210-220 | 95-100 | 106 | 7.3 |
| 220-230 | 100-104 | 111 | 7.7 |
| 230-240 | 104-109 | 116 | 8.0 |
| 240-250 | 109-113 | 120 | 8.3 |

### Air pressure — 34mm Rhythm

`fork/fox/34/rhythm`

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 58 | 4.0 |
| 130-140 | 59-64 | 63 | 4.3 |
| 140-150 | 64-68 | 68 | 4.7 |
| 150-160 | 68-73 | 72 | 5.0 |
| 160-170 | 73-77 | 77 | 5.3 |
| 170-180 | 77-82 | 82 | 5.7 |
| 180-190 | 82-86 | 86 | 6.0 |
| 190-200 | 86-91 | 91 | 6.3 |
| 200-210 | 91-95 | 96 | 6.6 |
| 210-220 | 95-100 | 100 | 6.9 |
| 220-230 | 100-104 | 105 | 7.2 |
| 230-240 | 104-109 | 110 | 7.6 |
| 240-250 | 109-113 | 114 | 7.9 |

### Rebound — 32mm Taper-Cast (GRIP, GRIP SL)

Source direction: from closed (clockwise to the stop, then counter-clockwise). Catalog: `grip` `rebound`,
`dial_ccw`, max 10; `grip_sl` `rebound`, `dial_ccw`, max 17 → same direction, encode as published.
**Conflict:** GRIP values 11-22 exceed the catalog `grip` max 10 (rows 120-210 lb). GRIP SL fits (max 17).

| Rider weight (lb) | Rider weight (kg) | GRIP (`damper: grip`) | GRIP SL (`damper: grip_sl`) |
|---|---|---|---|
| 120-130 | 54-59 | 22 | 17 |
| 130-140 | 59-64 | 21 | 16 |
| 140-150 | 64-68 | 20 | 15 |
| 150-160 | 68-73 | 19 | 14 |
| 160-170 | 73-77 | 18 | 13 |
| 170-180 | 77-82 | 17 | 12 |
| 180-190 | 82-86 | 16 | 11 |
| 190-200 | 86-91 | 15 | 10 |
| 200-210 | 91-95 | 13 | 9 |
| 210-220 | 95-100 | 11 | 8 |
| 220-230 | 100-104 | 10 | 7 |
| 230-240 | 104-109 | 9 | 6 |
| 240-250 | 109-113 | 8 | 5 |

### Rebound — 32mm Step-Cast (GRIP / GRIP SL, one column)

Same direction. Applies to `damper: grip_sl` and `damper: grip`. **Conflict:** values 11-13 exceed `grip`
max 10 (rows 120-150 lb); `grip_sl` (max 17) fits.

| Rider weight (lb) | Rider weight (kg) | GRIP / GRIP SL |
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

### Rebound — 32mm Rhythm (no catalog node)

The 32mm Rhythm GRIP column is identical to the 32mm Step-Cast column above (13 … 1).

### Rebound — 34mm FLOAT/Rhythm (GRIP)

Same direction; `damper: grip` on `fork/fox/34/performance` and `/rhythm`. **Conflict:** 11-13 exceed `grip`
max 10 (rows 120-150 lb).

| Rider weight (lb) | Rider weight (kg) | GRIP |
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
| `hsc` | 10 | from closed; catalog `grip_x` `hsc` `dial_ccw` max 15 → same | `damper: grip_x` (34 Factory, Performance Elite) |
| `lsc` | 10 | from closed; catalog `grip_x` `lsc` `dial_ccw` max 16 → same | `damper: grip_x` |

GRIP X2 (5 HSC / 10 LSC) is printed too but no catalog 32/34 product carries `grip_x2`. GRIP and GRIP SL:
no recommended lever position (the sag procedure only says to set Open while measuring).

### SAG

15-20 % of fork travel ("15 % Firm", "20 % Plush"), `display` band for every 32/34 node.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 40mm/ 1.6 in (TC) | 6mm/ 0.2 in | 8mm/ 0.3 in |
| 50mm/ 2.0 in (TC) | 7.5mm/ 0.3 in | 10mm/ 0.4 in |
| 60mm/ 2.4 in | 9mm/ 0.35in | 12mm/ 0.47 in |
| 80mm/ 3.1 in | 12mm/ 0.5 in | 16mm/ 0.6 in |
| 90mm/ 3.5 in | 13mm/ 0.5 in | 18mm/ 0.7 in |
| 100mm/ 3.9 in | 15mm/ 0.6 in | 20 mm/ 0.8 in |
| 110mm/ 4.3 in | 17mm/ 0.7 in | 22mm/ 0.9 in |
| 120mm/ 4.7 in | 18mm/ 0.7 in | 24mm/ 0.9 in |
| 130mm/ 5.1 in | 20 mm/ 0.8 in | 26mm/ 1.0 in |
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |
| 150mm/ 5.9 in | 23mm/ 0.9 in | 30mm/ 1.2 in |

### Volume spacers

Factory-installed count = recommended starting count (target `volume_spacers`, `when: { travel_mm: … }`).

32 TC (`fork/fox/32-taper-cast/*`):

| Travel | Factory installed | Max |
|---|---|---|
| 50 mm | 2 | 4 |
| 40 mm | 3 | 4 |

32 Rhythm (no catalog node):

| Travel | Factory installed | Max |
|---|---|---|
| 120 mm | 0 | 4 |
| 110 mm | 0 | 4 |
| 100 mm | 0 | 5 |
| 80 mm | 0 | 6 |

32 Step-Cast FLOAT (`fork/fox/32-step-cast/*`; catalog has 100 mm only):

| Travel | Factory installed | Max |
|---|---|---|
| 100 mm | 1 | 4 |
| 60 mm | 7 | 7 |

34 FLOAT (`fork/fox/34/factory`, `/performance-elite`, `/performance`; catalog travels 130/140):

| Travel | Factory installed | Max |
|---|---|---|
| 140 mm | 1 | 5 |
| 130 mm | 2 | 5 |
| 120 mm | 3 | 6 |

34 Rhythm (`fork/fox/34/rhythm`; catalog travels 130/150):

| Travel | Factory installed | Max |
|---|---|---|
| 150 mm | 0 | 4 |
| 140 mm | 0 | 4 |
| 130 mm | 1 | 5 |
| 120 mm | 2 | 5 |

### Pressure limits

| Variant | Published max | Catalog `max` |
|---|---|---|
| 32 TC | 150 psi / 10.3 bar | 150 ✓ |
| 32 Step-Cast and Rhythm | 140 psi / 9.6 bar | 32 Step-Cast 140 ✓ |
| 34 FLOAT and 34 Rhythm | 120 psi / 8.3 bar | 120 ✓ |

No minimum published. Pressures are specified at 70-75 °F ambient.

### Does not fit B3

- Nothing beyond the gaps above.

## Guide `fox_34sl_2027` — FORK- 2027 34SL

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3163/fork--2027-34sl
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Tuning with Air Volume Spacers"
- Retrieved: 2026-10-11
- The 2026 manual (owners-manuals/3087) is identical except the GRIP X base tune (10 clicks each in 2026,
  5 in 2027); irrelevant here because no catalog 34 SL trim has GRIP X.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/34-sl/factory` | `damper: grip_sl` | travel 120/130 |
| `fork/fox/34-sl/performance-elite` | `damper: grip_sl` | travel 120 |
| `fork/fox/34-sl/performance` | `damper: grip` | travel 120 |

Gaps: the manual's 110 mm sag/spacer row has no catalog travel.

### Air pressure — 34SL

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 64 | 4.4 |
| 130-140 | 59-64 | 69 | 4.8 |
| 140-150 | 64-68 | 74 | 5.1 |
| 150-160 | 68-73 | 78 | 5.4 |
| 160-170 | 73-77 | 83 | 5.7 |
| 170-180 | 77-82 | 88 | 6.1 |
| 180-190 | 82-86 | 92 | 6.3 |
| 190-200 | 86-91 | 97 | 6.7 |
| 200-210 | 91-95 | 102 | 7.0 |
| 210-220 | 95-100 | 106 | 7.3 |
| 220-230 | 100-104 | 111 | 7.7 |
| 230-240 | 104-109 | 116 | 8.0 |
| 240-250 | 109-113 | 120 | 8.3 |

### Rebound — 34SL (GRIP / GRIP SL / GRIP X, one column)

Source direction: from closed. Catalog `grip_sl` `rebound` max 17, `grip` `rebound` max 10, both `dial_ccw`
→ same direction. **Conflict:** 11-13 exceed `grip` max 10 (rows 120-150 lb).

| Rider weight (lb) | Rider weight (kg) | GRIP / GRIP SL / GRIP X |
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

None for the catalog dampers (GRIP SL/GRIP have only the lever; GRIP X 5/5 printed but not in the catalog for 34 SL).

### SAG

15-20 % of fork travel.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 110mm/ 4.3 in | 17mm/ 0.7 in | 22mm/ 0.9 in |
| 120mm/ 4.7 in | 18mm/ 0.7 in | 24mm/ 0.9 in |
| 130mm/ 5.1 in | 20 mm/ 0.8 in | 26mm/ 1.0 in |

### Volume spacers

| Travel | Factory installed | Max |
|---|---|---|
| 110 mm | 3 | 5 |
| 120 mm | 2 | 5 |
| 130 mm | 1 | 4 |

### Pressure limits

34SL max 120 psi / 8.3 bar; catalog 120 ✓.

## Guide `fox_36sl_2027` — FORK- 2027 36SL

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3165/fork--2027-36sl
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Adjusting Grip X Compression Damping", "Adjusting Fork Compression Ratio with Air Volume Spacers"
- Retrieved: 2026-10-11
- 2026 manual (owners-manuals/3088): identical tables; GRIP X base tune 10 clicks each instead of 5.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/36-sl/factory` | `damper: grip_x` | travel 130/140 |
| `fork/fox/36-sl/performance-elite` | `damper: grip_x` | travel 140 |
| `fork/fox/36-sl/performance` | `damper: grip` | travel 140 |

Gaps: the rebound table also has GRIP SL and GRIP X2 columns (no catalog 36 SL trim uses them); 120 mm rows have no catalog travel.

### Air pressure — 36SL FLOAT (all trims)

The manual adds that some riders need up to 10 psi over or under the table value (a `note`).

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 120-130 | 54-59 | 65 |
| 130-140 | 59-64 | 68 |
| 140-150 | 64-68 | 72 |
| 150-160 | 68-73 | 76 |
| 160-170 | 73-77 | 79 |
| 170-180 | 77-82 | 83 |
| 180-190 | 82-86 | 87 |
| 190-200 | 86-91 | 90 |
| 200-210 | 91-95 | 94 |
| 210-220 | 95-100 | 97 |
| 220-230 | 100-104 | 101 |
| 230-240 | 104-109 | 105 |
| 240-250 | 109-113 | 108 |

### Rebound — 36SL

Source direction: from closed. Catalog `grip_x` `rebound` max 17, `grip` `rebound` max 10, `dial_ccw` → same
direction. **Conflict:** GRIP column 11-13 exceeds `grip` max 10 (rows 120-150 lb).

| Rider weight (lb) | Rider weight (kg) | GRIP (`damper: grip`) | GRIP SL (no catalog) | GRIP X (`damper: grip_x`) | GRIP X2 LSR (no catalog) | GRIP X2 HSR (no catalog) |
|---|---|---|---|---|---|---|
| 120-130 | 54-59 | 13 | 13 | 16 | 9 | 8 |
| 130-140 | 59-64 | 12 | 12 | 14 | 8 | 7 |
| 140-150 | 64-68 | 11 | 11 | 12 | 7 | 7 |
| 150-160 | 68-73 | 10 | 10 | 10 | 7 | 6 |
| 160-170 | 73-77 | 9 | 9 | 9 | 7 | 6 |
| 170-180 | 77-82 | 8 | 8 | 8 | 7 | 5 |
| 180-190 | 82-86 | 7 | 7 | 7 | 6 | 4 |
| 190-200 | 86-91 | 6 | 6 | 6 | 5 | 4 |
| 200-210 | 91-95 | 5 | 5 | 5 | 4 | 3 |
| 210-220 | 95-100 | 4 | 4 | 4 | 3 | 2 |
| 220-230 | 100-104 | 3 | 3 | 3 | 3 | 1 |
| 230-240 | 104-109 | 2 | 2 | 2 | 2 | 0 |
| 240-250 | 109-113 | 1 | 1 | 1 | 1 | 0 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 5 (2026 manual: 10) | from closed; `grip_x` `hsc` max 15 → same | `damper: grip_x` |
| `lsc` | 5 (2026 manual: 10) | from closed; `grip_x` `lsc` max 16 → same | `damper: grip_x` |

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 120mm/ 4.7 in | 18mm/ 0.7 in | 24mm/ 0.9 in |
| 130mm/ 5.1 in | 20mm/ 0.8 in | 26mm/ 1.0 in |
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |

### Volume spacers

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 140 | 1 | 6 |
| 130 | 2 | 7 |
| 120 | 4 | 8 |

### Pressure limits

36SL max 120 psi / 8.3 bar; catalog 120 ✓.

## Guide `fox_36_2027` — FORK- 2027 36mm

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3164/fork--2027-36mm
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Adjusting Grip X / Grip X2 Compression Damping", "Adjusting Fork Compression Ratio with Air Volume Spacers"
- Retrieved: 2026-10-11
- 2026 manual (owners-manuals/3089): identical tables; GRIP X base tune 10 each instead of 5. The 36 Rhythm
  pressure column and spacer table are only in the 2025 36/38 manual, see `fox_36_38_2025`.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/36/2025/factory` | `damper: grip_x2` / `damper: grip_x` | FLOAT pressure; travel 150/160 |
| `fork/fox/36/2025/performance-elite` | `damper: grip_x` | FLOAT pressure; travel 160 |
| `fork/fox/36/2025/performance` | `damper: grip` | FLOAT pressure; travel 160 |
| `fork/fox/36/2025/rhythm` | `damper: grip` | pressure + spacers from `fox_36_38_2025`; rebound GRIP column here |

Gaps: "36 FLOAT E-Bike+" pressure column and spacer table have no catalog option (Q3: not encoded).
140 mm rows have no catalog travel.

### Air pressure — 36 FLOAT (and E-Bike+)

Note in the manual: up to ±10 psi off the table may be needed.

| Rider weight (lb) | Rider weight (kg) | 36 FLOAT psi | 36 FLOAT E-Bike+ psi (no catalog option) |
|---|---|---|---|
| 120-130 | 54-59 | 66 | 71 |
| 130-140 | 59-64 | 70 | 76 |
| 140-150 | 64-68 | 74 | 81 |
| 150-160 | 68-73 | 78 | 85 |
| 160-170 | 73-77 | 82 | 90 |
| 170-180 | 77-82 | 86 | 95 |
| 180-190 | 82-86 | 89 | 99 |
| 190-200 | 86-91 | 94 | 104 |
| 200-210 | 91-95 | 99 | 109 |
| 210-220 | 95-100 | 105 | 113 |
| 220-230 | 100-104 | 109 | 115 |
| 230-240 | 104-109 | 113 | 117 |
| 240-250 | 109-113 | 117 | 120 |

### Rebound — 36

Source direction: from closed. Catalog `grip` rebound max 10, `grip_x` rebound max 17, `grip_x2` `lsr` max 16 /
`hsr` max 8, all `dial_ccw` → same direction. **Conflict:** GRIP 11-13 exceeds `grip` max 10 (rows 120-150 lb).

| Rider weight (lb) | Rider weight (kg) | GRIP | GRIP X | GRIP X2 `lsr` | GRIP X2 `hsr` |
|---|---|---|---|---|---|
| 120-130 | 54-59 | 13 | 16 | 9 | 8 |
| 130-140 | 59-64 | 12 | 14 | 8 | 7 |
| 140-150 | 64-68 | 11 | 12 | 7 | 7 |
| 150-160 | 68-73 | 10 | 10 | 7 | 6 |
| 160-170 | 73-77 | 9 | 9 | 7 | 6 |
| 170-180 | 77-82 | 8 | 8 | 7 | 5 |
| 180-190 | 82-86 | 7 | 7 | 6 | 4 |
| 190-200 | 86-91 | 6 | 6 | 5 | 4 |
| 200-210 | 91-95 | 5 | 5 | 4 | 3 |
| 210-220 | 95-100 | 4 | 4 | 3 | 2 |
| 220-230 | 100-104 | 3 | 3 | 3 | 1 |
| 230-240 | 104-109 | 2 | 2 | 2 | 0 |
| 240-250 | 109-113 | 1 | 1 | 1 | 0 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 5 (2026 manual: 10) | from closed; `grip_x` `hsc` max 15 → same | `damper: grip_x` |
| `lsc` | 5 (2026 manual: 10) | from closed; `grip_x` `lsc` max 16 → same | `damper: grip_x` |
| `hsc` | 5 | from closed; `grip_x2` `hsc` max 8 → same | `damper: grip_x2` |
| `lsc` | 10 | from closed; `grip_x2` `lsc` max 18 → same | `damper: grip_x2` |

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |
| 150mm/ 5.9 in | 23mm/ 0.9 in | 30mm/ 1.2 in |
| 160mm/ 6.3 in | 24mm/ 0.9 in | 32mm/ 1.3 in |

### Volume spacers

36mm (FLOAT):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 140 | 4 | 8 |
| 150 | 2 | 7 |
| 160 | 1 | 6 |

36mm E-Bike+ (no catalog option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 140 | 4 | 8 |
| 150 | 4 | 7 |
| 160 | 3 | 6 |

### Pressure limits

36mm max 120 psi / 8.3 bar; catalog 120 ✓.

## Guide `fox_36_38_2025` — FORK- 2025 36mm/38mm (36 Rhythm columns only)

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/2979/fork--2025-36mm-or-38mm
- Document: FOX owner's manual, model year 2025, English (HTML)
- Section / page: "Setting Fork Air Pressure" (36mm table), "Adjusting Fork Compression Ratio with Air Volume Spacers"
- Retrieved: 2026-10-11
- Every other number in this manual equals the 2026 36/38 manuals (GRIP X base tune 10 each). Only the 36
  Rhythm data is recorded here because the 2026/2027 36mm manuals dropped it.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/36/2025/rhythm` | `damper: grip` | pressure + spacers; rebound from `fox_36_2027` GRIP column |

### Air pressure — 36 Rhythm

Columns FLOAT and FLOAT E-Bike+ of this table equal `fox_36_2027`.

| Rider weight (lb) | Rider weight (kg) | FLOAT psi | FLOAT E-Bike+ psi | Rhythm psi |
|---|---|---|---|---|
| 120-130 | 54-59 | 66 | 71 | 55 |
| 130-140 | 59-64 | 70 | 76 | 59 |
| 140-150 | 64-68 | 74 | 81 | 63 |
| 150-160 | 68-73 | 78 | 85 | 67 |
| 160-170 | 73-77 | 82 | 90 | 72 |
| 170-180 | 77-82 | 86 | 95 | 76 |
| 180-190 | 82-86 | 89 | 99 | 80 |
| 190-200 | 86-91 | 94 | 104 | 85 |
| 200-210 | 91-95 | 99 | 109 | 89 |
| 210-220 | 95-100 | 105 | 113 | 93 |
| 220-230 | 100-104 | 109 | 115 | 97 |
| 230-240 | 104-109 | 113 | 117 | 102 |
| 240-250 | 109-113 | 117 | 120 | 106 |

### Volume spacers — 36 RHYTHM

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 170 | 1 | 6 |
| 160 | 2 | 7 |
| 150 | 3 | 7 |
| 140 | 4 | 8 |
| 130 | 5 | 8 |

### Pressure limits

"2025 36 FLOAT/Rhythm/E-bike+" max 120 psi; catalog 120 ✓.

## Guide `fox_38_2026` — FORK- 2026 38mm

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3103/fork--2026-38mm
- Document: FOX owner's manual, model year 2026, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Adjusting Grip X / Grip X2 Compression Damping", "Adjusting Fork Compression Ratio with Air Volume Spacers"
- Retrieved: 2026-10-11
- Chosen over the 2027 manual for the catalog node `fork/fox/38/2025` (years 2025-2026) because the 2027
  manual changes the pressure table and the spacer system (see `fox_38_2027`). The 2025 36/38 manual
  (2979) has the same 38 numbers as this one.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/38/2025/factory` | `damper: grip_x2` | FLOAT pressure; travel 160/170/180 |
| `fork/fox/38/2025/performance-elite` | `damper: grip_x2` | FLOAT pressure; travel 170 |
| `fork/fox/38/2025/rhythm` | `damper: grip` | RHYTHM pressure; travel 160/170/180 |

Gaps: FLOAT E-Bike+ and RHYTHM E-Bike+ / E-Optimized columns have no catalog option; the GRIP X column and
base tune have no catalog 38 trim; 150 mm rows have no catalog travel.

### Air pressure — 38

Note in the manual: up to ±10 psi off the table may be needed.

| Rider weight (lb) | Rider weight (kg) | FLOAT psi | FLOAT E-Bike+ psi (no option) | RHYTHM psi | RHYTHM E-Bike+ psi (no option) |
|---|---|---|---|---|---|
| 120-130 | 54-59 | 72 | 81 | 59 | 54 |
| 130-140 | 59-64 | 76 | 85 | 63 | 58 |
| 140-150 | 64-68 | 80 | 89 | 67 | 62 |
| 150-160 | 68-73 | 84 | 93 | 72 | 67 |
| 160-170 | 73-77 | 89 | 98 | 76 | 71 |
| 170-180 | 77-82 | 93 | 102 | 80 | 75 |
| 180-190 | 82-86 | 97 | 106 | 84 | 79 |
| 190-200 | 86-91 | 102 | 111 | 88 | 83 |
| 200-210 | 91-95 | 106 | 115 | 92 | 87 |
| 210-220 | 95-100 | 110 | 119 | 97 | 92 |
| 220-230 | 100-104 | 114 | 123 | 101 | 96 |
| 230-240 | 104-109 | 119 | 128 | 105 | 100 |
| 240-250 | 109-113 | 123 | 132 | 109 | 104 |

### Rebound — 38

Source direction: from closed. Catalog `grip` rebound max 10, `grip_x2` `lsr` 16 / `hsr` 8, `dial_ccw` → same.
**Conflict:** GRIP 11-13 exceeds `grip` max 10 (rows 120-150 lb).

| Rider weight (lb) | Rider weight (kg) | GRIP | GRIP X (no catalog 38 trim) | GRIP X2 `lsr` | GRIP X2 `hsr` |
|---|---|---|---|---|---|
| 120-130 | 54-59 | 13 | 16 | 9 | 8 |
| 130-140 | 59-64 | 12 | 14 | 8 | 7 |
| 140-150 | 64-68 | 11 | 12 | 7 | 7 |
| 150-160 | 68-73 | 10 | 10 | 7 | 6 |
| 160-170 | 73-77 | 9 | 9 | 7 | 6 |
| 170-180 | 77-82 | 8 | 8 | 7 | 5 |
| 180-190 | 82-86 | 7 | 7 | 6 | 4 |
| 190-200 | 86-91 | 6 | 6 | 5 | 4 |
| 200-210 | 91-95 | 5 | 5 | 4 | 3 |
| 210-220 | 95-100 | 4 | 4 | 3 | 2 |
| 220-230 | 100-104 | 3 | 3 | 3 | 1 |
| 230-240 | 104-109 | 2 | 2 | 2 | 0 |
| 240-250 | 109-113 | 1 | 1 | 1 | 0 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 5 | from closed; `grip_x2` `hsc` max 8 → same | `damper: grip_x2` |
| `lsc` | 10 | from closed; `grip_x2` `lsc` max 18 → same | `damper: grip_x2` |

(GRIP X: 10 each — no catalog 38 trim.)

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 130mm/ 5.1 in | 20mm/ 0.8 in | 26mm/ 1.0 in |
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |
| 150mm/ 5.9 in | 23mm/ 0.9 in | 30mm/ 1.2 in |
| 160mm/ 6.3 in | 24mm/ 0.9in | 32mm/ 1.3 in |
| 170mm/ 6.7 in | 25mm/ 1.0 in | 34mm/ 1.3 in |
| 180mm/ 7.1 in | 27mm/ 1.1 in | 36mm/ 1.4 in |

### Volume spacers

38 FLOAT (`factory`, `performance-elite`):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 1 | 4 |
| 170 | 2 | 5 |
| 160 | 3 | 6 |
| 150 | 4 | 6 |

38 FLOAT E-Bike+ (no option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 2 | 4 |
| 170 | 3 | 5 |
| 160 | 4 | 6 |
| 150 | 5 | 6 |

38 RHYTHM (`rhythm`):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 0 | 4 |
| 170 | 1 | 5 |
| 160 | 2 | 6 |
| 150 | 3 | 7 |

38 RHYTHM E-Optimized (no option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 1 | 4 |
| 170 | 2 | 5 |
| 160 | 3 | 6 |
| 150 | 4 | 7 |

### Pressure limits

38 FLOAT/E-Bike+ max 140 psi (9.6 bar), 38 Rhythm max 120 psi (8.3 bar); catalog 140 / 120 ✓.

## Guide `fox_38_2027` — FORK- 2027 38mm

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3166/fork--2027-38mm
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: as `fox_38_2026`
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| — | — | Not mapped yet. FLOAT pressures are 18-19 psi lower than 2026 and spacers switch to 10 cc + 5 cc parts, which points to a revised air spring. A `2027` generation node (or a decision that it replaces 2025-2026) is needed first. |

Differences vs `fox_38_2026`: FLOAT and FLOAT E-Bike+ merged into one "FLOAT/E-Bike+" column with new values;
RHYTHM and RHYTHM E-Bike+ unchanged; rebound table unchanged; GRIP X base tune 5/5 (was 10/10); GRIP X2
base tune unchanged (5 HSC / 10 LSC); FLOAT spacer tables now mixed 10 cc/5 cc with no 150 mm row; max
pressures unchanged (the page still labels them "2026 38").

### Air pressure — 38 (2027)

| Rider weight (lb) | Rider weight (kg) | FLOAT/E-Bike+ psi | RHYTHM psi | RHYTHM E-Bike+ psi |
|---|---|---|---|---|
| 120-130 | 54-59 | 54 | 59 | 54 |
| 130-140 | 59-64 | 58 | 63 | 58 |
| 140-150 | 64-68 | 62 | 67 | 62 |
| 150-160 | 68-73 | 67 | 72 | 67 |
| 160-170 | 73-77 | 71 | 76 | 71 |
| 170-180 | 77-82 | 75 | 80 | 75 |
| 180-190 | 82-86 | 80 | 84 | 79 |
| 190-200 | 86-91 | 84 | 88 | 83 |
| 200-210 | 91-95 | 88 | 92 | 87 |
| 210-220 | 95-100 | 93 | 97 | 92 |
| 220-230 | 100-104 | 97 | 101 | 96 |
| 230-240 | 104-109 | 100 | 105 | 100 |
| 240-250 | 109-113 | 104 | 109 | 104 |

### Rebound — 38 (2027)

Identical to `fox_38_2026`.

### Volume spacers — 38 FLOAT (10 cc + 5 cc)

| Travel (mm) | Factory 10 cc | Factory 5 cc | Max total |
|---|---|---|---|
| 180 | 0 | 1 | 4 |
| 170 | 1 | 0 | 5 |
| 160 | 1 | 1 | 6 |

38 FLOAT E-Optimized:

| Travel (mm) | Factory 10 cc | Factory 5 cc | Max total |
|---|---|---|---|
| 180 | 1 | 1 | 4 |
| 170 | 2 | 0 | 5 |
| 160 | 2 | 1 | 6 |

38 RHYTHM and RHYTHM E-Optimized: identical to `fox_38_2026`.

### Does not fit B3

- The FLOAT spacer recommendation is two counts of two spacer sizes; the catalog's `volume_spacers` is
  one count. Proposed: `display_only` note ("1 × 10 cc + 1 × 5 cc") until the catalog models spacer sizes.

## Guide `fox_40_2027` — FORK- 2027 40mm

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3167/fork--2027-40mm
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Adjusting Grip X2 Compression Damping", "Tuning with Air Volume Spacers"
- Retrieved: 2026-10-11
- The 2026 (3102) and 2025 (2980) 40mm manuals are identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/40/factory` | `damper: grip_x2` | travel 203 |

Gaps: GRIP column and GRIP base tune (LSC 4 clicks from closed) have no catalog 40 trim; 190 mm rows have no catalog travel.

### Air pressure — 40mm FLOAT (bands with ranges)

Input: rider weight in 30-lb bands · Output: psi **range** (`range` rule, not a single value).

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-150 | 54-68 | 52-64 | 3.6-4.4 |
| 150-180 | 68-82 | 64-76 | 4.4-5.2 |
| 180-210 | 82-95 | 76-87 | 5.2-6.0 |
| 210-250 | 95-113 | 87-101 | 6.0-7.0 |

### Rebound — 40

Source direction: from closed. Catalog `grip_x2` `lsr` max 16, `hsr` max 8, `dial_ccw` → same direction.
**Conflict:** HSR 10 and 9 (rows 120-140 lb) exceed `hsr` max 8. LSR and HSR columns are identical in the
source.

| Rider weight (lb) | Rider weight (kg) | GRIP (no catalog) | GRIP X2 `lsr` | GRIP X2 `hsr` |
|---|---|---|---|---|
| 120-130 | 54-59 | 13 | 10 | 10 |
| 130-140 | 59-64 | 12 | 9 | 9 |
| 140-150 | 64-68 | 11 | 8 | 8 |
| 150-160 | 68-73 | 10 | 8 | 8 |
| 160-170 | 73-77 | 9 | 7 | 7 |
| 170-180 | 77-82 | 8 | 7 | 7 |
| 180-190 | 82-86 | 7 | 6 | 6 |
| 190-200 | 86-91 | 6 | 5 | 5 |
| 200-210 | 91-95 | 5 | 5 | 5 |
| 210-220 | 95-100 | 4 | 4 | 4 |
| 220-230 | 100-104 | 3 | 3 | 3 |
| 230-240 | 104-109 | 2 | 3 | 3 |
| 240-250 | 109-113 | 1 | 2 | 2 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 5 | from closed; `grip_x2` max 8 → same | `damper: grip_x2` |
| `lsc` | 10 | from closed; `grip_x2` max 18 → same | `damper: grip_x2` |

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 190mm | 28.5mm (1.1in) | 38mm (1.5in) |
| 203mm | 30mm (1.2in) | 41mm (1.6in) |

### Volume spacers

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 203 | 2 | 5 |
| 190 | 3 | 7 |

### Pressure limits

40 FLOAT max 120 psi / 8.3 bar; catalog 120 ✓.

## Guide `fox_podium_2027` — FORK- 2027 Podium

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3169/fork--2027-podium-
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Sag Setting", "Rebound Adjustment", "Compression Adjustment", volume spacer tables
- Retrieved: 2026-10-11
- The 2026 Podium manual (3108) is identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/podium/factory` | `damper: grip_x2` | "Podium" columns; travel 150/160/170 |

Gaps: "Podium E-Bike+" columns (pressure, pressure-keyed rebound, spacers) have no catalog option.

### Air pressure — Podium

Weight printed as one cell "120-130 lb (54-59 kg)"; split into lb and kg when encoding.

| Rider weight | Podium pressure | Podium E-Bike+ pressure (no option) |
|---|---|---|
| 120-130 lb (54-59 kg) | 55 psi (3.8 bar) | 55 psi (3.8 bar) |
| 130-140 lb (59-64 kg) | 61 psi (4.2 bar) | 61 psi (4.2 bar) |
| 140-150 lb (64-68 kg) | 67 psi (4.6 bar) | 68 psi (4.7 bar) |
| 150-160 lb (68-73 kg) | 73 psi (5.0 bar) | 74 psi (5.1 bar) |
| 160-170 lb (73-77 kg) | 78 psi (5.4 bar) | 80 psi (5.5 bar) |
| 170-180 lb (77-82 kg) | 84 psi (5.8 bar) | 86 psi (5.9 bar) |
| 180-190 lb (82-86 kg) | 90 psi (6.2 bar) | 93 psi (6.4 bar) |
| 190-200 lb (86-91 kg) | 96 psi (6.6 bar) | 99 psi (6.8 bar) |
| 200-210 lb (91-95 kg) | 102 psi (7.0 bar) | 105 psi (7.2 bar) |
| 210-220 lb (95-100 kg) | 108 psi (7.4 bar) | 111 psi (7.7 bar) |
| 220-230 lb (100-104 kg) | 113 psi (7.8 bar) | 118 psi (8.1 bar) |
| 230-240 lb (104-109 kg) | 119 psi (8.2 bar) | 124 psi (8.5 bar) |
| 240-250 lb (109-113 kg) | 125 psi (8.6 bar) | 130 psi (9.0 bar) |

### Rebound — Podium (keyed on air pressure)

Input: air pressure (literal points, the values of the pressure table) · Output: LSR/HSR. Source direction:
from closed (clockwise to the stop). Catalog `grip_x2` `lsr` max 16, `hsr` max 8 → same direction.

| Pressure | GRIP X2 `lsr` | GRIP X2 `hsr` |
|---|---|---|
| 55 psi (3.8 bar) | 15 | 8 |
| 61 psi (4.2 bar) | 13 | 7 |
| 67 psi (4.6 bar) | 13 | 7 |
| 73 psi (5.0 bar) | 12 | 6 |
| 78 psi (5.4 bar) | 10 | 6 |
| 84 psi (5.8 bar) | 9 | 5 |
| 90 psi (6.2 bar) | 8 | 4 |
| 96 psi (6.6 bar) | 6 | 4 |
| 102 psi (7.0 bar) | 5 | 3 |
| 108 psi (7.4 bar) | 5 | 2 |
| 113 psi (7.8 bar) | 3 | 1 |
| 119 psi (8.2 bar) | 2 | 0 |
| 125 psi (8.6 bar) | 1 | 0 |

Podium E-Bike+ (no option):

| Pressure | GRIP X2 LSR | GRIP X2 HSR |
|---|---|---|
| 55 psi (3.8 bar) | 15 | 8 |
| 61 psi (4.2 bar) | 13 | 7 |
| 68 psi (4.7 bar) | 12 | 7 |
| 74 psi (5.1 bar) | 11 | 6 |
| 80 psi (5.5 bar) | 9 | 6 |
| 86 psi (5.9 bar) | 8 | 5 |
| 93 psi (6.4 bar) | 7 | 4 |
| 99 psi (6.8 bar) | 5 | 4 |
| 105 psi (7.2 bar) | 4 | 3 |
| 111 psi (7.7 bar) | 4 | 2 |
| 118 psi (8.1 bar) | 2 | 1 |
| 124 psi (8.5 bar) | 1 | 0 |
| 130 psi (9.0 bar) | 0 | 0 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 6 | from closed; `grip_x2` max 8 → same | `damper: grip_x2` |
| `lsc` | 8 | from closed; `grip_x2` max 18 → same | `damper: grip_x2` |

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 150mm (5.9in) | 22mm (0.9in) | 30mm (1.20in) |
| 160mm (6.3in) | 24mm (0.94in) | 32mm (1.26in) |
| 170mm (6.7in) | 26mm (1.0in) | 34mm (1.34in) |

### Volume spacers

Podium:

| Travel | Factory installed | Max |
|---|---|---|
| 170mm | 2 | 8 |
| 160mm | 3 | 8 |
| 150mm | 4 | 8 |

Podium E-Bike+ (no option):

| Travel | Factory installed | Max |
|---|---|---|
| 170mm | 3 | 8 |
| 160mm | 4 | 8 |
| 150mm | 5 | 8 |

### Pressure limits

Podium max 130 psi; catalog 130 ✓ (E-Bike+ column reaches 130 at 240-250 lb).

### Does not fit B3

- Rebound is keyed on pressure (`input: pressure`, literal points). Between printed points the rule needs
  nearest/bracket semantics; propose half-open brackets between consecutive points.

## Guide `fox_awl_2027` — FORK- 2027 AWL/AWL Sport and AWL HD/AWL HD Sport

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3168/fork--2027-awl-or-awl-sport-and-awl-hd-or-awl-hd-sport
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Tuning with Air Volume Spacers"
- Retrieved: 2026-10-11
- The 2026 (3101) and 2025 (2971) AWL manuals are identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/awl/standard` | `damper: rail` | "34mm AWL and AWL Sport" tables |
| `fork/fox/awl/hd` | `damper: rail` | "36mm AWL HD and AWL HD Sport" tables |

Gaps: AWL Sport / AWL HD Sport share the tables but are not catalog trims.

### Air pressure — 34mm AWL / AWL Sport

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 65 | 4.5 |
| 130-140 | 59-64 | 70 | 4.8 |
| 140-150 | 64-68 | 74 | 5.1 |
| 150-160 | 68-73 | 80 | 5.5 |
| 160-170 | 73-77 | 85 | 5.9 |
| 170-180 | 77-82 | 90 | 6.2 |
| 180-190 | 82-86 | 96 | 6.6 |
| 190-200 | 86-91 | 101 | 7.0 |
| 200-210 | 91-95 | 106 | 7.3 |
| 210-220 | 95-100 | 111 | 7.7 |
| 220-230 | 100-104 | 116 | 8.0 |
| 230-240 | 104-109 | 121 | 8.3 |
| 240-250 | 109-113 | 126 | 8.7 |

### Air pressure — 36mm AWL HD / AWL HD Sport

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-130 | 54-59 | 71 | 4.9 |
| 130-140 | 59-64 | 76 | 5.2 |
| 140-150 | 64-68 | 81 | 5.6 |
| 150-160 | 68-73 | 85 | 5.9 |
| 160-170 | 73-77 | 90 | 6.2 |
| 170-180 | 77-82 | 95 | 6.5 |
| 180-190 | 82-86 | 99 | 6.8 |
| 190-200 | 86-91 | 104 | 7.2 |
| 200-210 | 91-95 | 109 | 7.5 |
| 210-220 | 95-100 | 113 | 7.8 |
| 220-230 | 100-104 | 115 | 7.9 |
| 230-240 | 104-109 | 117 | 8.1 |
| 240-250 | 109-113 | 120 | 8.3 |

### Rebound — 34mm AWL / AWL Sport

Source direction: from closed. Catalog `rail` `rebound` `dial_ccw` max 9 → same direction. **Conflict:** 10
(120-130 lb) exceeds max 9.

| Rider weight (lb) | Rider weight (kg) | Rebound |
|---|---|---|
| 120-130 | 54-59 | 10 |
| 130-140 | 59-64 | 9 |
| 140-150 | 64-68 | 9 |
| 150-160 | 68-73 | 8 |
| 160-170 | 73-77 | 8 |
| 170-180 | 77-82 | 7 |
| 180-190 | 82-86 | 7 |
| 190-200 | 86-91 | 6 |
| 200-210 | 91-95 | 5 |
| 210-220 | 95-100 | 3 |
| 220-230 | 100-104 | 2 |
| 230-240 | 104-109 | 1 |
| 240-250 | 109-113 | 1 |

### Rebound — 36mm AWL HD / AWL HD Sport

Same direction. **Conflict:** 10-13 (rows 120-160 lb) exceed `rail` max 9 — the HD column equals the GRIP
column of the 36 manual, so the HD probably carries a different rebound range than the AWL.

| Rider weight (lb) | Rider weight (kg) | Rebound |
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

None (RAIL 2-position sweep lever, no recommended setting).

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 100mm/ 3.9 in | 15mm/ 0.6 in | 20 mm/ 0.8 in |
| 110mm/ 4.3 in | 17mm/ 0.7 in | 22mm/ 0.9 in |
| 120mm/ 4.7 in | 18mm/ 0.7 in | 24mm/ 0.9 in |
| 130mm/ 5.1 in | 20 mm/ 0.8 in | 26mm/ 1.0 in |
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |
| 150mm/ 5.9 in | 23mm/ 0.9 in | 30mm/ 1.2 in |
| 160mm/ 6.2in | 24mm/ 1.0 in | 32mm/ 1.3 in |

### Volume spacers

34mm AWL / AWL Sport (`fork/fox/awl/standard`):

| Travel | Factory installed | Max |
|---|---|---|
| 150 mm | 2 | 4 |
| 140 mm | 3 | 4 |
| 130 mm | 4 | 5 |
| 120 mm | 4 | 5 |
| 110 mm | 5 | 6 |
| 100 mm | 6 | 6 |

36mm AWL HD / AWL HD Sport (`fork/fox/awl/hd`):

| Travel | Factory installed | Max |
|---|---|---|
| 160 mm | 3 | 6 |
| 150 mm | 4 | 7 |
| 140 mm | 4 | 8 |
| 130 mm | 5 | 9 |

### Pressure limits

AWL / AWL Sport max 140 psi; AWL HD / HD Sport max 120 psi; catalog 140 / 120 ✓.

## Guide `fox_36_2020` — FORK- 2020 36mm

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/1040/fork--2020-36mm
- Document: FOX owner's manual, model year 2020, English (HTML); the page labels the pressure limit "2019 36 FLOAT"
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", "Factory and Performance Elite FIT4 Compression Adjusters", "Factory and Performance-Elite Series GRIP2 Compression Adjusters", "Adjusting GRIP Compression Damping", "Adjusting Fork Compression Ratio with Air Volume Spacers"
- Retrieved: 2026-10-11
- The 2019 36mm manual (owners-manuals/938) is identical. The 2018 manual (owners-manuals/822) predates GRIP2:
  it prints a per-10-lb pressure table (below), a FIT4 / "GRIP/RC2" rebound table with the same values, and
  base tunes for RC2 HSC/LSC (15/15) and a Performance LSC (12) that have no catalog damper.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/36/2018/factory` | `damper: grip2_2018` / `damper: fit4_2018` | travel 140-180 |
| `fork/fox/36/2018/performance-elite` | `damper: grip2_2018` / `damper: fit4_2018` | travel 140-180 |
| `fork/fox/36/2018/performance` | `damper: grip_2018` | travel 140-180 |

Gaps: E-Bike+ pressure/spacer tables and the 831 spacer row (100 mm) have no catalog option; the
Performance Elite LSC adjuster section gives no starting value.

### Air pressure — 36mm FLOAT and Rhythm (30-lb bands, psi ranges)

`range` output.

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-150 | 54-68 | 55-63 | 3.8-4.4 |
| 150-180 | 68-82 | 67-76 | 4.6-5.2 |
| 180-210 | 82-95 | 80-89 | 5.5-6.1 |
| 210-250 | 95-113 | 93-106 | 6.4-7.3 |

36mm E-Bike+ (no option):

| Rider weight (lb) | Rider weight (kg) | psi | bar |
|---|---|---|---|
| 120-150 | 54-68 | 58-68 | 4.0-4.7 |
| 150-180 | 68-82 | 72-82 | 5.0-5.7 |
| 180-210 | 82-95 | 86-96 | 5.9-6.6 |
| 210-250 | 95-113 | 100-114 | 6.9-7.9 |

2018 manual, per-10-lb table (FLOAT only; single values — the rebound table below is keyed on exactly these
points; "75" at 160-170 lb and "76" at 170-180 lb are as printed):

| Rider weight (lb) | Rider weight (kg) | FLOAT pressure |
|---|---|---|
| 120-130 | 54-59 | 55psi/ 3.8 bar |
| 130-140 | 59-64 | 59psi/ 4.1 bar |
| 140-150 | 64-68 | 63psi/ 4.3 bar |
| 150-160 | 68-73 | 67psi/ 4.6 bar |
| 160-170 | 73-77 | 75psi/ 5.1 bar |
| 170-180 | 77-82 | 76psi/ 5.2 bar |
| 180-190 | 82-86 | 80psi/ 5.5 bar |
| 190-200 | 86-91 | 85psi/ 5.9 bar |
| 200-210 | 91-95 | 89psi/ 6.1 bar |
| 210-220 | 95-100 | 93psi/ 6.4 bar |
| 220-230 | 100-104 | 97psi/ 6.7 bar |
| 230-240 | 104-109 | 102psi/ 7.0 bar |
| 240-250 | 109-113 | 106psi/ 7.3 bar |

### Rebound — 36mm (keyed on air pressure)

Input: FLOAT/Rhythm air pressure (literal points) · Source direction: from closed. Catalog `fit4_2018`
`rebound` max 8, `grip_2018` `rebound` max 13, `grip2_2018` `lsr` max 9 / `hsr` max 8, all `dial_ccw`
(maxima are estimates taken from this very table) → same direction, encode as published.

| Pressure (psi) | FIT4 (`fit4_2018`) | GRIP (`grip_2018`) | GRIP2 `lsr` | GRIP2 `hsr` |
|---|---|---|---|---|
| 55 | 8 | 13 | 9 | 8 |
| 59 | 8 | 12 | 8 | 7 |
| 63 | 7 | 11 | 7 | 6 |
| 67 | 7 | 10 | 7 | 6 |
| 75 | 6 | 9 | 6 | 5 |
| 76 | 6 | 8 | 6 | 5 |
| 80 | 5 | 7 | 5 | 4 |
| 85 | 5 | 6 | 4 | 3 |
| 89 | 4 | 5 | 4 | 3 |
| 93 | 4 | 4 | 3 | 2 |
| 97 | 3 | 3 | 2 | 1 |
| 102 | 2 | 2 | 2 | 1 |
| 106 | 1 | 1 | 1 | 0 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open | categorical | `damper: fit4_2018` |
| `open_mode_adjust` | 18 | from closed; `fit4_2018` `open_mode_adjust` max 22, `dial_ccw` → same | `damper: fit4_2018` |
| `hsc` | 10 | from closed; `grip2_2018` `hsc` max 16 → same | `damper: grip2_2018` |
| `lsc` | 6 | from closed; `grip2_2018` `lsc` max 12 → same | `damper: grip2_2018` |
| `compression_mode` | Open | categorical | `damper: grip_2018` |

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |
| 150mm/ 5.9 in | 23mm/ 0.9 in | 30mm/ 1.2 in |
| 160mm/ 6.3 in | 24mm/ 0.9in | 32mm/ 1.3 in |
| 170mm/ 6.7 in | 25mm/ 1.0 in | 34mm/ 1.3 in |
| 180mm/ 7.1 in | 27mm/ 1.1 in | 36mm/ 1.4 in |

### Volume spacers

36 FLOAT:

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 0 | 4 |
| 170 | 0 | 5 |
| 160 | 1 | 6 |
| 150 | 2 | 7 |
| 140 | 4 | 8 |
| 100 (831) | 9 | 10 |

36mm E-Bike+ (no option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 160 | 3 | 5 |
| 150 | 4 | 6 |
| 140 | 4 | 6 |
| 130 | 5 | 7 |
| 120 | 6 | 7 |

### Pressure limits

36 FLOAT max 120 psi / 8.3 bar; catalog 120 ✓.

### Does not fit B3

- Rebound keyed on pressure points (see Podium).
- The 2019-2020 pressure rows are bands with psi ranges; the 2018 per-10-lb table gives single values for
  the same chassis. Proposed: encode the 2018 table as the `pressure` rule (finer), keep the 2020 ranges as a
  `note`. They agree (2018 values sit inside the 2020 ranges).

## Guide `fox_36_38_2024` — FORK- 2024 36mm/38mm

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/2930/fork--2024-36mm-or-38mm
- Document: FOX owner's manual, model year 2024, English (HTML); the page labels its limits "2023"
- Section / page: "Setting Fork Air Pressure", "Adjusting Rebound", FIT4 / GRIP2 / GRIP compression sections, spacer tables
- Retrieved: 2026-10-11
- The 2023 manual (2830) is identical. The 2021 manual (1082, the catalog's `setup_guide`) has the same 36
  tables and rebound table, but its 38 pressure table has one "FLOAT and E-Bike+" column (= the FLOAT values
  below), no 38 Rhythm data, and an extra 36 RHYTHM spacer row 180 mm: 1 factory / 5 max. The 2022 manual
  (1144) adds the 38 E-Optimized column, still no Rhythm.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/fox/36/2021/factory` | `damper: grip2_vvc_2021` / `damper: fit4_2021` | 36 FLOAT pressure |
| `fork/fox/36/2021/performance-elite` | `damper: grip2_vvc_2021` / `damper: fit4_2021` | 36 FLOAT pressure |
| `fork/fox/36/2021/performance` | `damper: grip_2018` | 36 FLOAT pressure |
| `fork/fox/36/2021/rhythm` | `damper: grip_2018` | 36 Rhythm pressure |
| `fork/fox/38/2021/factory` | `damper: grip2_vvc_2021` | 38 FLOAT pressure |
| `fork/fox/38/2021/performance-elite` | `damper: grip2_vvc_2021` | 38 FLOAT pressure |
| `fork/fox/38/2021/performance` | `damper: grip_2018` | 38 FLOAT pressure |
| `fork/fox/38/2021/rhythm` | `damper: grip_2018` | 38 RHYTHM pressure (2023+ manuals only) |

Gaps: E-Bike+ / E-Optimized columns have no catalog option.

### Air pressure — 36mm

| Rider weight (lb) | Rider weight (kg) | FLOAT psi | FLOAT E-Bike+ psi (no option) | Rhythm psi |
|---|---|---|---|---|
| 120-130 | 54-59 | 66 | 71 | 55 |
| 130-140 | 59-64 | 70 | 76 | 59 |
| 140-150 | 64-68 | 74 | 81 | 63 |
| 150-160 | 68-73 | 78 | 85 | 67 |
| 160-170 | 73-77 | 82 | 90 | 72 |
| 170-180 | 77-82 | 86 | 95 | 76 |
| 180-190 | 82-86 | 89 | 99 | 80 |
| 190-200 | 86-91 | 94 | 104 | 85 |
| 200-210 | 91-95 | 99 | 109 | 89 |
| 210-220 | 95-100 | 105 | 113 | 93 |
| 220-230 | 100-104 | 109 | 115 | 97 |
| 230-240 | 104-109 | 113 | 117 | 102 |
| 240-250 | 109-113 | 117 | 120 | 106 |

### Air pressure — 38mm

| Rider weight (lb) | Rider weight (kg) | FLOAT psi | FLOAT E-Optimized psi (no option) | RHYTHM psi | RHYTHM E-Optimized psi (no option) |
|---|---|---|---|---|---|
| 120-130 | 54-59 | 72 | 81 | 59 | 54 |
| 130-140 | 59-64 | 76 | 85 | 63 | 58 |
| 140-150 | 64-68 | 80 | 89 | 67 | 62 |
| 150-160 | 68-73 | 84 | 93 | 72 | 67 |
| 160-170 | 73-77 | 89 | 98 | 76 | 71 |
| 170-180 | 77-82 | 93 | 102 | 80 | 75 |
| 180-190 | 82-86 | 97 | 106 | 84 | 79 |
| 190-200 | 86-91 | 102 | 111 | 88 | 83 |
| 200-210 | 91-95 | 106 | 115 | 92 | 87 |
| 210-220 | 95-100 | 110 | 119 | 97 | 92 |
| 220-230 | 100-104 | 114 | 123 | 101 | 96 |
| 230-240 | 104-109 | 119 | 128 | 105 | 100 |
| 240-250 | 109-113 | 123 | 132 | 109 | 104 |

### Rebound — 36/38

Source direction: from closed. Catalog `fit4_2021` `rebound` max 14, `grip_2018` `rebound` max 13,
`grip2_vvc_2021` `lsr` max 9 / `hsr` max 8, all `dial_ccw` (estimates from this table) → same direction.

| Rider weight (lb) | Rider weight (kg) | FIT4 (`fit4_2021`) | GRIP (`grip_2018`) | GRIP2 `lsr` | GRIP2 `hsr` |
|---|---|---|---|---|---|
| 120-130 | 54-59 | 14 | 13 | 9 | 8 |
| 130-140 | 59-64 | 13 | 12 | 8 | 7 |
| 140-150 | 64-68 | 12 | 11 | 7 | 6 |
| 150-160 | 68-73 | 11 | 10 | 7 | 6 |
| 160-170 | 73-77 | 9 | 9 | 6 | 5 |
| 170-180 | 77-82 | 8 | 8 | 6 | 5 |
| 180-190 | 82-86 | 7 | 7 | 5 | 4 |
| 190-200 | 86-91 | 6 | 6 | 4 | 3 |
| 200-210 | 91-95 | 5 | 5 | 4 | 3 |
| 210-220 | 95-100 | 4 | 4 | 3 | 2 |
| 220-230 | 100-104 | 3 | 3 | 2 | 1 |
| 230-240 | 104-109 | 2 | 2 | 2 | 1 |
| 240-250 | 109-113 | 1 | 1 | 1 | 0 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open | categorical | `damper: fit4_2021` |
| `open_mode_adjust` | 18 | from closed; `fit4_2021` max 22 → same | `damper: fit4_2021` |
| `hsc` | 5 | from closed; `grip2_vvc_2021` `hsc` max 8 → same | `damper: grip2_vvc_2021` |
| `lsc` | 10 | from closed; `grip2_vvc_2021` `lsc` max 16 → same | `damper: grip2_vvc_2021` |
| `compression_mode` | Open | categorical | `damper: grip_2018` |

### SAG

15-20 %.

| Travel | 15 % sag (Firm) | 20 % sag (Plush) |
|---|---|---|
| 130mm/ 5.1 in | 20mm/ 0.8 in | 26mm/ 1.0 in |
| 140mm/ 5.5 in | 21mm/ 0.8 in | 28mm/ 1.1 in |
| 150mm/ 5.9 in | 23mm/ 0.9 in | 30mm/ 1.2 in |
| 160mm/ 6.3 in | 24mm/ 0.9in | 32mm/ 1.3 in |
| 170mm/ 6.7 in | 25mm/ 1.0 in | 34mm/ 1.3 in |
| 180mm/ 7.1 in | 27mm/ 1.1 in | 36mm/ 1.4 in |

### Volume spacers

36 FLOAT (`36/2021` factory, performance-elite, performance):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 170 | 0 | 5 |
| 160 | 1 | 6 |
| 150 | 2 | 7 |
| 140 | 4 | 8 |
| 130 | 5 | 9 |

36 FLOAT E-Bike+ (no option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 160 | 3 | 6 |
| 150 | 4 | 7 |
| 140 | 4 | 8 |
| 130 | 5 | 9 |

36 RHYTHM (`36/2021/rhythm`):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 170 | 1 | 6 |
| 160 | 2 | 7 |
| 150 | 3 | 7 |
| 140 | 4 | 8 |
| 130 | 5 | 8 |

38 FLOAT (`38/2021` factory, performance-elite, performance):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 1 | 4 |
| 170 | 2 | 5 |
| 160 | 3 | 6 |
| 150 | 4 | 6 |

38 FLOAT E-Bike+ (no option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 2 | 4 |
| 170 | 3 | 5 |
| 160 | 4 | 6 |
| 150 | 5 | 6 |

38 RHYTHM (`38/2021/rhythm`):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 0 | 4 |
| 170 | 1 | 5 |
| 160 | 2 | 6 |
| 150 | 3 | 7 |

38 RHYTHM E-Optimized (no option):

| Travel (mm) | Factory installed | Max |
|---|---|---|
| 180 | 1 | 4 |
| 170 | 2 | 5 |
| 160 | 3 | 6 |
| 150 | 4 | 7 |

### Pressure limits

36 FLOAT 120 psi, 38 FLOAT 140 psi, 38 RHYTHM 120 psi; catalog 120 / 140 / 120 ✓. (No 36 Rhythm limit printed; catalog 120.)

---

# Shocks

## Formula shared by every FOX air shock

All FOX air-shock manuals in scope (FLOAT, FLOAT SL, FLOAT X, FLOAT X2 2016-2027, FLOAT DPS/DPX2) say: start
with an air pressure in psi equal to your body weight in pounds, then adjust to the SAG band. No rider range
is stated, so the calculated rows use 50-120 kg (calculated from the published formula, 1 kg = 2.20462 lb,
rounded to whole psi):

| Rider weight (kg) | psi (calculated) |
|---|---|
| 50 | 110 |
| 55 | 121 |
| 60 | 132 |
| 65 | 143 |
| 70 | 154 |
| 75 | 165 |
| 80 | 176 |
| 85 | 187 |
| 90 | 198 |
| 95 | 209 |
| 100 | 220 |
| 105 | 231 |
| 110 | 243 |
| 115 | 254 |
| 120 | 265 |

Encode as `target: pressure`, `input: rider_weight`, formula psi = lb (or the rows above), with a note that
SAG decides the final pressure.

## Guide `fox_float_2027` — SHOCK- 2027 FLOAT

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3172/shock--2027-float
- Rebound table image: https://tech.ridefox.com/img/help/page2932-V3AP/inline/rebound1.jpg
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Shock Air Pressure", "Adjusting Rebound", "Adjusting Compression Damping"
- Retrieved: 2026-10-11
- The 2024 (2932), 2025 (2982) and 2026 (3099) FLOAT manuals are identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/float/factory` | `damper: float` | |
| `shock/fox/float/performance-elite` | `damper: float` | |
| `shock/fox/float/performance` | `damper: float` | |
| `shock/fox/float/rhythm` | `damper: float` | |

### Air pressure

Formula (see above). No table.

### Rebound — FLOAT (keyed on air pressure bands)

Source direction: from closed. Catalog `float` `rebound` max 12, `dial_ccw` → same direction.

| Air pressure (psi) | Air pressure (bar) | Rebound |
|---|---|---|
| <100 | <6,9 | 10 |
| 100-120 | 6,9-8,3 | 10 |
| 120-140 | 8,3-9,7 | 9 |
| 140-160 | 9,7-11 | 8 |
| 160-180 | 11-12,4 | 7 |
| 180-200 | 12,4-13,8 | 6 |
| 200-220 | 13,8-15,2 | 5 |
| 220-240 | 15,2-16,5 | 4 |
| 240-260 | 16,5-17,9 | 3 |
| 260-280 | 17,9-19,3 | 2 |
| 280-300 | 19,3-20,7 | 1 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open | categorical | `damper: float` |
| `open_mode_adjust` | 1 | categorical ("1" plushest) | `damper: float` (manual: Factory and Performance Elite non-remote only) |

### SAG

25-30 % of shock travel (25 % Firm, 30 % Plush).

| Travel | 25 % sag (Firm) | 30 % sag (Plush) |
|---|---|---|
| 25 mm (1.0 in) | 6 mm (0.25 in) | 7 mm (0.30 in) |
| 32 mm (1.25 in) | 8 mm (0.31 in) | 10 mm (0.37 in) |
| 38 mm (1.5 in) | 10 mm (0.38 in) | 11 mm (0.45 in) |
| 44 mm (1.75 in) | 11 mm (0.44 in) | 13 mm (0.53 in) |
| 51 mm (2.0 in) | 13 mm (0.50 in) | 15 mm (0.60 in) |
| 57 mm (2.25 in) | 14 mm (0.56 in) | 17 mm (0.68 in) |
| 63 mm (2.5 in) | 16 mm (0.63 in) | 19 mm (.75 in) |
| 76 mm (3.0 in) | 19 mm (0.75 in) | 23 mm (0.90 in) |

The same table is printed in the FLOAT SL/FLOAT X and DPS/DPX2 manuals.

### Volume spacers

Volume-graded spacer kit (803-01-938); no count, no recommendation.

### Pressure limits

FLOAT max 350 psi (24.1 bar); catalog 350 ✓.

## Guide `fox_float_sl_float_x_2027` — SHOCK- 2027 FLOAT SL and FLOAT X

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3173/shock--2027-float-sl-and-float-x
- Rebound table images: FLOAT SL https://tech.ridefox.com/img/help/page555-V15S/inline/DPS-rebound-setup.jpg ;
  FLOAT X https://tech.ridefox.com/img/help/page1147-Z52T/inline/FLOAT-X-rebound.jpg
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Shock Air Pressure", "Adjusting Rebound", "Adjusting Compression Damping"
- Retrieved: 2026-10-11
- The 2024 (2927), 2025 (2983) and 2026 (3098) manuals are identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/float-sl/factory` | `damper: float_sl` | FLOAT SL table |
| `shock/fox/float-sl/performance` | `damper: float_sl` | FLOAT SL table |
| `shock/fox/float-x/factory` | `damper: float_x` | FLOAT X table |
| `shock/fox/float-x/performance-elite` | `damper: float_x` | FLOAT X table |
| `shock/fox/float-x/performance` | `damper: float_x` | FLOAT X table |

### Air pressure

Formula (see above).

### Rebound — FLOAT SL (image shared with the DPS)

Source direction: from closed; the image's scale runs Open · 11 … 3 · Closed. Catalog `float_sl` `rebound`
max 12, `dial_ccw` → same direction.

| Air pressure (psi) | Rebound |
|---|---|
| <100 | Open (counter-clockwise) |
| 100-120 | 11 |
| 120-140 | 10 |
| 140-160 | 9 |
| 160-180 | 8 |
| 180-200 | 7 |
| 200-220 | 6 |
| 220-240 | 5 |
| 240-260 | 4 |
| 260-280 | 3 |
| 280-300 | Closed (clockwise) |

### Rebound — FLOAT X

Source direction: from closed. Catalog `float_x` `rebound` max 16, `dial_ccw` → same direction.

| Air pressure (psi) | Rebound |
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

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open | categorical | `damper: float_sl` |
| `open_mode_adjust` | 1 | categorical | `damper: float_sl` |

FLOAT X: the LSC knob ("Compression") has no starting value; the 2-position lever has no stated start.

### SAG

25-30 %, same mm table as `fox_float_2027`.

### Volume spacers

Volume-graded kits (803-01-250 FLOAT SL, 803-01-725 FLOAT X); no count.

### Pressure limits

FLOAT SL EVOL and FLOAT X 350 psi; FLOAT SL non-EVOL 300 psi; catalog 350 with the 300 psi note on FLOAT SL ✓.

### Does not fit B3

- "Open" / "Closed" cells: propose `display_only` for "Open" (fully open), and value 0 for "Closed"
  (0 = fully closed is the catalog convention), or `display_only` for both.

## Guide `fox_float_x2_2027` — SHOCK- 2027 FLOAT X2

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3183/shock--2027-float-x2
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Shock Air Pressure", "Recommended Damper Settings", "Using the 2-Pos Compression Lever"
- Retrieved: 2026-10-11
- The 2026 manual (3023, the catalog `setup_guide`) is identical. The 2025 FLOAT X2 manual (2984) still
  prints the 2021-2024 table and 300 psi limit (see `fox_float_x2_2024`).

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/float-x2/2025/factory` | `damper: vvc2` | all four columns |
| `shock/fox/float-x2/2025/performance-elite` | `damper: vvc2` | manual: HSR/HSC are Factory only |
| `shock/fox/float-x2/2025/performance` | `damper: vvc2` | manual: HSR/HSC are Factory only |

Gaps: the catalog gives Performance Elite and Performance the 4-way `vvc2`; the manual says only Factory has
HSR/HSC. Encode `lsr`/`lsc` for all, `hsr`/`hsc` with `when: { trim: factory }` until the catalog splits the damper.

### Air pressure

Formula (see above).

### Damper settings (keyed on air pressure)

Source direction: "Count clicks out from fully closed (0=Closed)". Catalog `vvc2` `lsr` max 16, `hsr` max 8,
`lsc` max 16, `hsc` max 8, `dial_ccw` → same direction. LSC and HSC are click **ranges** (`range` rule).

| Air pressure (psi) | `lsr` | `hsr` | `lsc` | `hsc` |
|---|---|---|---|---|
| <100 | 13 | 7 | 11-13 | 6-7 |
| 100-120 | 12 | 7 | 11-13 | 6-7 |
| 120-140 | 11 | 6 | 11-13 | 6-7 |
| 140-160 | 10 | 6 | 9-10 | 4-5 |
| 160-180 | 9 | 5 | 9-10 | 4-5 |
| 180-200 | 8 | 4 | 9-10 | 4-5 |
| 200-220 | 7 | 4 | 9-10 | 4-5 |
| 220-240 | 6 | 3 | 9-10 | 4-5 |
| 240-260 | 5 | 2 | 7-8 | 2-3 |
| 260-280 | 4 | 2 | 7-8 | 2-3 |
| 280-300 | 3 | 1 | 7-8 | 2-3 |

### Constants / base tune

2-position lever: begin in Open (no catalog adjuster on `vvc2`).

### SAG

~30 % of shock travel.

| Travel | 30 % sag |
|---|---|
| 55mm/ 2.25in | 17mm/ 0.68in |
| 65mm/ 2.50in | 19mm/ 0.75in |
| 75mm/ 3.00in | 22mm/ 0.90in |

### Volume spacers

1 cc and 2 cc spacers, maximum set by ribs inside the XV sleeve; no count, no recommendation.

### Pressure limits

FLOAT X2 max 350 psi (24.1 bar); catalog 350 ✓.

## Guide `fox_float_x2_2020` — SHOCK- 2020 FLOAT X2

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/1036/shock--2020-float-x2
- Document: FOX owner's manual, model year 2020, English (HTML)
- Section / page: "Setting Shock Air Pressure", "Recommended Damper Settings", spacer table
- Retrieved: 2026-10-11
- The 2019 manual (941) is identical. Older editions differ:
  - 2018 (owners-manuals/825, table image https://tech.ridefox.com/img/help/page825-CWUN/inline/FX2-damper-suggestions-for-2018-2019xxx.jpg):
    same values from 90 to 250 psi (table ends at 250, the 2018 limit), except HSC at 200 psi = 12-14.
  - 2016 / 2017 (owners-manuals/556 and 695, image https://tech.ridefox.com/img/help/page556-T8A6/inline/FLOAT-X2-recommended-settings2.jpg): a different table, transcribed below.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/float-x2/2016/factory` | `damper: x2_2016` | targets `lsr`, `hsr`, `lsc`, `hsc` |
| `shock/fox/float-x2/2016/performance-elite` | `damper: x2_2016_ls` | LSR → `rebound`, LSC → `compression` (HSR/HSC Factory only) |

Gaps: the catalog generation spans 2016-2020 without a year option, but the 2016-2017 table differs; the
2019-2020 table is proposed as the encoded one (matches the catalog `setup_guide`), the others as notes.

### Air pressure

Formula (see above).

### Damper settings 2019-2020 (keyed on air pressure)

Source direction: "Count clicks out from fully closed (0=Closed)". Catalog `x2_2016` `lsr` max 24, `hsr` max 23,
`lsc` max 24, `hsc` max 23 (estimates, partly from this table); `x2_2016_ls` `rebound`/`compression` max 24;
all `dial_ccw` → same direction. Every cell is a range; "22-Open" runs to the open stop. HSC at 200 psi is
printed "10-14" (2018 image: 12-14).

| Air pressure (psi) | LSR | HSR | LSC | HSC |
|---|---|---|---|---|
| 90 | 22-Open | 17-19 | 20-22 | 21-23 |
| 100 | 22-24 | 16-18 | 19-21 | 19-21 |
| 110 | 19-21 | 15-17 | 18-20 | 18-20 |
| 120 | 18-20 | 14-16 | 18-20 | 17-19 |
| 130 | 18-20 | 13-15 | 17-19 | 16-18 |
| 140 | 17-19 | 12-14 | 17-19 | 16-18 |
| 150 | 16-18 | 12-14 | 16-18 | 15-17 |
| 160 | 16-18 | 11-13 | 16-18 | 15-17 |
| 170 | 15-17 | 11-13 | 15-17 | 14-16 |
| 180 | 15-17 | 10-12 | 14-16 | 13-15 |
| 190 | 14-16 | 10-12 | 14-16 | 13-15 |
| 200 | 13-15 | 9-11 | 13-15 | 10-14 |
| 210 | 12-14 | 9-11 | 12-14 | 11-13 |
| 220 | 11-13 | 8-10 | 12-14 | 11-13 |
| 230 | 10-12 | 8-10 | 11-13 | 10-12 |
| 240 | 9-11 | 7-9 | 10-12 | 10-12 |
| 250 | 8-10 | 7-9 | 10-12 | 9-11 |
| 260 | 7-9 | 6-8 | 9-11 | 9-11 |
| 270 | 6-8 | 6-8 | 8-10 | 8-10 |
| 280 | 5-7 | 5-7 | 8-10 | 8-10 |
| 290 | 4-6 | 5-7 | 7-9 | 7-9 |
| 300 | 3-5 | 4-6 | 6-8 | 7-9 |

### Damper settings 2016-2017 (image, same direction)

| Air pressure (psi) | LSR | HSR | LSC | HSC |
|---|---|---|---|---|
| 90 | Open | 21-23 | Open | Open |
| 100 | 22-Open | 20-22 | 23-Open | 22-Open |
| 110 | 21-23 | 19-21 | 22-24 | 21-23 |
| 120 | 20-22 | 18-20 | 22-24 | 20-22 |
| 130 | 20-22 | 17-19 | 21-23 | 19-21 |
| 140 | 19-21 | 16-18 | 21-23 | 19-21 |
| 150 | 18-20 | 16-18 | 20-22 | 18-20 |
| 160 | 18-20 | 15-17 | 20-22 | 18-20 |
| 170 | 17-19 | 15-17 | 19-21 | 17-19 |
| 180 | 17-19 | 14-16 | 18-20 | 16-18 |
| 190 | 16-18 | 14-16 | 18-20 | 16-18 |
| 200 | 15-17 | 13-15 | 17-19 | 15-17 |
| 210 | 14-16 | 13-15 | 16-18 | 14-16 |
| 220 | 13-15 | 12-14 | 16-18 | 14-16 |
| 230 | 12-14 | 12-14 | 15-17 | 13-15 |
| 240 | 11-13 | 11-13 | 14-16 | 13-15 |
| 250 | 10-12 | 11-13 | 14-16 | 12-14 |

### Constants / base tune

2-position lever (some shocks): begin in Open — no catalog adjuster.

### SAG

~30 % of shock travel.

| Travel | 30 % sag |
|---|---|
| 51mm/ 2.00in | 15mm/ 0.60in |
| 57mm/ 2.25in | 17mm/ 0.68in |
| 63mm/ 2.50in | 19mm/ 0.75in |
| 76mm/ 3.00in | 23mm/ 0.90in |
| 89mm/ 3.50in | 25mm/ 1.00in |

### Volume spacers

Maximum spacer pairs per size only (already in the catalog `notes`); no factory/recommended count.

### Pressure limits

2019-2020: 300 psi; 2016-2018: 250 psi; catalog 300 with the 250 psi note ✓.

### Does not fit B3

- "Open" and "22-Open"/"23-Open" cells: `display_only` (the catalog maxima are estimates, so "Open" cannot be
  turned into a number).

## Guide `fox_float_x2_2024` — SHOCK- 2024 FLOAT X2

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/2926/shock--2024-float-x2
- Document: FOX owner's manual, model year 2024, English (HTML)
- Section / page: "Recommended Damper Settings", "Setting Shock Air Pressure"
- Retrieved: 2026-10-11
- The 2021 (1078), 2022 (1148), 2023 (2834) and 2025 (2984) FLOAT X2 manuals are identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/float-x2/2021/factory` | `damper: x2_vvc_2021` | `lsr`, `hsr`, `lsc`, `hsc` |
| `shock/fox/float-x2/2021/performance-elite` | `damper: x2_vvc_2021_ls` | LSR → `rebound`, LSC → `compression` |

### Air pressure

Formula (see above).

### Damper settings (keyed on air pressure)

Source direction: "Count clicks out from fully closed (0=Closed)". Catalog `x2_vvc_2021` `lsr` 18, `hsr` 8,
`lsc` 18, `hsc` 8; `x2_vvc_2021_ls` `rebound` 18 / `compression` 18 (estimates from this table), `dial_ccw` →
same direction. All cells are ranges.

| Air pressure (psi) | LSR | HSR | LSC | HSC |
|---|---|---|---|---|
| 90 | 16-18 | 7-8 | 16-18 | 7-8 |
| 100 | 15-17 | 7-8 | 16-18 | 7-8 |
| 110 | 14-16 | 6-7 | 15-17 | 7-8 |
| 120 | 13-15 | 6-7 | 15-17 | 7-8 |
| 130 | 12-14 | 5-6 | 14-16 | 6-7 |
| 140 | 11-13 | 5-6 | 14-16 | 6-7 |
| 150 | 10-12 | 5-6 | 13-15 | 6-7 |
| 160 | 9-11 | 4-5 | 13-15 | 6-7 |
| 170 | 8-10 | 4-5 | 12-14 | 5-6 |
| 180 | 7-9 | 4-5 | 11-13 | 5-6 |
| 190 | 7-9 | 3-4 | 10-12 | 5-6 |
| 200 | 6-8 | 3-4 | 9-11 | 4-5 |
| 210 | 6-8 | 3-4 | 8-10 | 4-5 |
| 220 | 5-7 | 2-3 | 7-9 | 4-5 |
| 230 | 4-6 | 2-3 | 6-8 | 4-5 |
| 240 | 3-5 | 2-3 | 5-7 | 3-4 |
| 250 | 2-4 | 2-3 | 4-6 | 3-4 |
| 260 | 2-4 | 1-2 | 2-4 | 3-4 |
| 270 | 1-3 | 1-2 | 2-4 | 3-4 |
| 280 | 1-3 | 1-2 | 2-4 | 2-3 |
| 290 | 1-3 | 0-1 | 1-3 | 2-3 |
| 300 | 1-2 | 0-1 | 1-3 | 2-3 |

### SAG

~30 % of shock travel.

| Travel | 30 % sag |
|---|---|
| 51mm/ 2.00in | 15mm/ 0.60in |
| 55mm/ 2.25in | 17mm/ 0.68in |
| 65mm/ 2.50in | 19mm/ 0.75in |
| 70mm/ 2.75in | 21mm/ 0.82in |
| 75mm/ 3.00in | 23mm/ 0.90in |
| 89mm/ 3.50in | 25mm/ 1.00in |

### Volume spacers

Maximum spacer counts per size only (in the catalog `notes`); no recommendation.

### Pressure limits

300 psi; catalog 300 ✓.

## Guide `fox_dhx2_2027` — SHOCK- 2027 DHX2

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3171/shock--2027-dhx2
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Coil Spring Preload", "Recommended Starting Damper Settings (DHX2)"
- Retrieved: 2026-10-11
- The 2026 manual (3090, the catalog `setup_guide`) is identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/dhx2/2025/factory` | `damper: vvc2` | all four columns |
| `shock/fox/dhx2/2025/performance-elite` | `damper: vvc2` | manual: HSR and HSC are "Factory Series only" (LSC section is headed Factory and Performance Elite) |
| `shock/fox/dhx2/2025/performance` | `damper: vvc2` | manual names no Performance adjusters; HSR/HSC Factory only |

### Damper settings (keyed on coil spring rate)

Input: spring rate (header printed "SRING RATE"; lb/in implied, the catalog `Spring Rate` unit). Source
direction: not restated in this manual; the table follows the FOX convention (all earlier DHX2 manuals and
the 2027 FLOAT X2 table: clicks out from fully closed). Catalog `vvc2` max 16/8/16/8, `dial_ccw` → same
direction (flagged as inferred). LSC/HSC are ranges.

| Spring rate | `lsr` | `hsr` | `lsc` | `hsc` |
|---|---|---|---|---|
| 200 | 14 | 8 | 11-12 | 6-7 |
| 225 | 14 | 8 | 11-12 | 6-7 |
| 250 | 13 | 7 | 11-12 | 6-7 |
| 275 | 13 | 7 | 11-12 | 6-7 |
| 300 | 12 | 7 | 11-12 | 6-7 |
| 325 | 11 | 6 | 11-12 | 6-7 |
| 350 | 11 | 6 | 9-10 | 4-5 |
| 375 | 10 | 5 | 9-10 | 4-5 |
| 400 | 10 | 5 | 9-10 | 4-5 |
| 425 | 9 | 5 | 9-10 | 4-5 |
| 450 | 8 | 4 | 9-10 | 4-5 |
| 475 | 8 | 4 | 9-10 | 4-5 |
| 500 | 7 | 3 | 9-10 | 4-5 |
| 525 | 6 | 3 | 7-8 | 2-3 |
| 550 | 6 | 2 | 7-8 | 2-3 |
| 575 | 5 | 2 | 7-8 | 2-3 |
| 600 | 4 | 2 | 7-8 | 2-3 |
| 625 | 4 | 1 | 7-8 | 2-3 |
| 650 | 4 | 1 | 7-8 | 2-3 |
| 675 | 3 | 1 | 7-8 | 2-3 |
| 700 | 2 | 1 | 7-8 | 2-3 |
| 725 | 2 | 0 | 7-8 | 2-3 |

### Constants / base tune

2-position lever: begin in Open (no catalog adjuster). Preload: tighten until the spring stops moving, then 8
clicks; never more than two full turns to reduce sag — no catalog preload adjuster.

### SAG

~30 % of shock travel; outside reach of preload → change spring.

| Travel | 30 % sag |
|---|---|
| 55mm/ 2.16in | 17mm/ 0.67in |
| 65mm/ 2.56in | 19mm/ 0.75in |
| 70mm/ 2.75in | 21mm/ 0.83in |
| 75mm/ 2.95in | 22mm/ 0.86in |

### Does not fit B3

- Input `spring_rate` (the catalog's `Spring Rate` adjuster value) is not in the B3 input list. Proposed: add
  `spring_rate` as an input (same mechanics as `pressure`), literal points 200-725 in steps of 25.
- No spring-rate recommendation per rider weight; SAG is the only spring guide.

## Guide `fox_dhx_2027` — SHOCK- 2027 DHX

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/3170/shock--2027-dhx-
- Document: FOX owner's manual, model year 2027, English (HTML)
- Section / page: "Setting Coil Spring Preload", "Adjusting Rebound", "Adjusting Compression Damping"
- Retrieved: 2026-10-11
- The 2026 manual (3100) is identical.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/dhx/factory` | `damper: dhx_coil` | SAG only |

### SAG

~30 % of shock travel.

| Travel | 30 % sag |
|---|---|
| 51mm/ 2.00in | 15mm/ 0.60in |
| 57mm/ 2.25in | 17mm/ 0.68in |
| 63mm/ 2.50in | 19mm/ 0.75in |
| 70mm/ 2.75in | 21mm/ 0.83in |
| 76mm/ 3.00in | 23mm/ 0.90in |
| 89mm/ 3.50in | 25mm/ 1.00in |

No rebound or compression starting values (adjuster descriptions only).

## Guide `fox_coil_2020` — SHOCK- 2020 All Coil Shocks (DHX2 and VAN models)

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/1038/shock--2020-all-coil-shocks-(dhx2-and-van-models)
- Images: selector https://tech.ridefox.com/img/help/page557-XBUZ/inline/DHX2-compression-ratio-chart.jpg ,
  tables https://tech.ridefox.com/img/help/page557-XBUZ/inline/DHX2-table-A.jpg , `-table-B.jpg`, `-table-C.jpg`
- Document: FOX owner's manual, model year 2020, English (HTML)
- Section / page: "Setting Coil Spring Preload", "Recommended Starting Damper Settings (Factory and Performance Elite Series)"
- Retrieved: 2026-10-12
- The 2016 (557), 2017 (693), 2018 (826) and 2019 (939) coil manuals use the same images.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/dhx2/2016/factory` | `damper: x2_2016` | one value range for all four adjusters |
| `shock/fox/dhx2/2016/performance-elite` | `damper: x2_2016` | manual: Performance Elite uses only LSC and LSR |

### Table selector (shock stroke × rear-wheel travel)

| Shock travel | 130 mm | 140 mm | 150 mm | 160 mm | 170 mm | 180 mm | 190 mm | 200 mm | 210 mm |
|---|---|---|---|---|---|---|---|---|---|
| 51 mm (2 in) | B | B | B | C | C | N/A | N/A | N/A | N/A |
| 57 mm (2.25 in) | A | A | B | B | B | C | C | N/A | N/A |
| 63 mm (2.5 in) | A | A | A | B | B | B | B | C | N/A |
| 70 mm (2.75 in) | N/A | A | A | A | A | B | B | B | C |
| 76 mm (3 in) | N/A | N/A | N/A | A | A | A | A | B | B |
| 89 mm (3.5 in) | N/A | N/A | N/A | N/A | N/A | A | A | A | A |

### Damper settings (keyed on spring rate; one range for HSC, LSC, HSR, LSR)

Source direction: from closed (fully clockwise, then counter-clockwise). Catalog `x2_2016` max 23/24/23/24,
`dial_ccw` → same direction. "20-Open" → `display_only`.

| Spring rate | Table A | Table B | Table C |
|---|---|---|---|
| 200 | 20-Open | 14-17 | 11-14 |
| 225 | 20-23 | 14-17 | 11-14 |
| 250 | 19-23 | 13-16 | 10-13 |
| 275 | 19-22 | 13-16 | 10-13 |
| 300 | 18-22 | 12-15 | 9-12 |
| 325 | 18-21 | 12-15 | 9-12 |
| 350 | 17-21 | 11-14 | 8-11 |
| 375 | 17-20 | 11-14 | 8-11 |
| 400 | 16-20 | 10-13 | 7-10 |
| 425 | 16-19 | 10-13 | 7-10 |
| 450 | 15-19 | 9-12 | 6-9 |
| 475 | 15-18 | 9-12 | 6-9 |
| 500 | 14-18 | 8-11 | 5-8 |
| 525 | 14-17 | 8-11 | 5-8 |
| 550 | 13-17 | 7-10 | 4-7 |
| 575 | 13-16 | 7-10 | 4-7 |
| 600 | 12-16 | 6-9 | 3-6 |
| 625 | 12-15 | 6-9 | 3-6 |
| 650 | 11-15 | 5-8 | 2-5 |
| 675 | 11-14 | 5-8 | 2-5 |
| 700 | 10-14 | 4-7 | 1-4 |
| 725 | 10-13 | 4-7 | 0-4 |

### Constants / base tune

Preload: snug, then one more full turn (2020 manual); no catalog preload adjuster.

### SAG

~30 % of shock travel; same mm table as `fox_dhx_2027`.

### Does not fit B3

- Needs two bike inputs (shock stroke, rear-wheel travel) to pick A/B/C, plus `spring_rate`. The catalog has
  no `size` option on `dhx2/2016` and no rear-wheel-travel input. Proposed: a `table` selector rule keyed on
  `stroke_mm` × `rear_travel_mm`, or `display_only` A/B/C tables until those inputs exist.

## Guide `fox_coil_2024` — SHOCK- 2024 All Coil Shocks (DHX2 and DHX models)

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/2928/shock--2024-all-coil-shocks-(dhx2-and-dhx-models)
- Images: selector https://tech.ridefox.com/img/help/page1080-8XBE/inline/dhx2-comp-ratio-chart.jpg ,
  tables https://tech.ridefox.com/img/help/page1080-8XBE/inline/21dhx2-table-a.jpg , `-table-b.jpg`, `-table-c.jpg`
- Document: FOX owner's manual, model year 2024, English (HTML)
- Section / page: "Recommended Starting Damper Settings (DHX2)"
- Retrieved: 2026-10-12
- The 2021 (1080), 2022 (1146), 2023 (2832) and 2025 (2981) coil manuals use the same images. The catalog
  `setup_guide` of `shock/fox/dhx2/2021` points at the 2021 FLOAT X2 manual (1078) instead (see Follow-ups).

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/dhx2/2021/factory` | `damper: x2_vvc_2021` | all four columns |
| `shock/fox/dhx2/2021/performance-elite` | `damper: x2_vvc_2021` | manual: Performance Elite uses only LSC and LSR |

### Table selector

Identical to `fox_coil_2020` (same cells, legend "Table A (page 7) / B (page 8) / C (page 9)").

### Damper settings (keyed on spring rate)

Source direction: from closed. Catalog `x2_vvc_2021` `lsr` 18, `hsr` 8, `lsc` 18, `hsc` 8, `dial_ccw` → same
direction. All cells are ranges. Table A HSC at 475 reads 7-8 (between 6-7 and 5-6), as printed.

Table A:

| Spring rate | LSR | HSR | LSC | HSC |
|---|---|---|---|---|
| 200 | 15-16 | 7-8 | 16-17 | 7-8 |
| 225 | 14-15 | 7-8 | 16-17 | 7-8 |
| 250 | 13-14 | 7-8 | 15-16 | 7-8 |
| 275 | 12-13 | 7-8 | 15-16 | 7-8 |
| 300 | 11-12 | 7-8 | 14-15 | 7-8 |
| 325 | 10-11 | 6-7 | 14-15 | 6-7 |
| 350 | 9-10 | 6-7 | 13-14 | 6-7 |
| 375 | 8-9 | 6-7 | 13-14 | 6-7 |
| 400 | 7-8 | 6-7 | 12-13 | 6-7 |
| 425 | 6-7 | 6-7 | 11-12 | 6-7 |
| 450 | 6-7 | 5-6 | 11-12 | 6-7 |
| 475 | 5-6 | 5-6 | 11-12 | 7-8 |
| 500 | 5-6 | 5-6 | 10-11 | 5-6 |
| 525 | 4-5 | 5-6 | 10-11 | 5-6 |
| 550 | 4-5 | 4-5 | 9-10 | 4-5 |
| 575 | 4-5 | 4-5 | 9-10 | 4-5 |
| 600 | 3-4 | 3-4 | 8-9 | 3-4 |
| 625 | 2-3 | 2-3 | 7-8 | 2-3 |
| 650 | 2-3 | 1-2 | 6-7 | 1-2 |
| 675 | 1-2 | 1-2 | 5-6 | 1-2 |
| 700 | 1-2 | 0-1 | 4-5 | 0-1 |
| 725 | 0-1 | 0-1 | 3-4 | 0-1 |

Table B:

| Spring rate | LSR | HSR | LSC | HSC |
|---|---|---|---|---|
| 200 | 13-14 | 7-8 | 16-17 | 7-8 |
| 225 | 13-14 | 7-8 | 16-17 | 7-8 |
| 250 | 12-13 | 7-8 | 15-16 | 7-8 |
| 275 | 11-12 | 7-8 | 15-16 | 7-8 |
| 300 | 10-11 | 6-7 | 14-15 | 6-7 |
| 325 | 9-10 | 6-7 | 14-15 | 6-7 |
| 350 | 8-9 | 6-7 | 13-14 | 6-7 |
| 375 | 7-8 | 6-7 | 13-14 | 6-7 |
| 400 | 6-7 | 5-6 | 12-13 | 5-6 |
| 425 | 6-7 | 6-7 | 11-12 | 5-6 |
| 450 | 5-6 | 4-5 | 10-11 | 5-6 |
| 475 | 5-6 | 4-5 | 9-10 | 4-5 |
| 500 | 4-5 | 4-5 | 8-9 | 4-5 |
| 525 | 4-5 | 3-4 | 7-8 | 3-4 |
| 550 | 3-4 | 3-4 | 6-7 | 3-4 |
| 575 | 3-4 | 2-3 | 5-6 | 2-3 |
| 600 | 2-3 | 2-3 | 5-6 | 2-3 |
| 625 | 2-3 | 1-2 | 4-5 | 1-2 |
| 650 | 1-2 | 1-2 | 4-5 | 1-2 |
| 675 | 1-2 | 1-2 | 3-4 | 1-2 |
| 700 | 1-2 | 0-1 | 3-4 | 0-1 |
| 725 | 0-1 | 0-1 | 2-3 | 0-1 |

Table C:

| Spring rate | LSR | HSR | LSC | HSC |
|---|---|---|---|---|
| 200 | 11-12 | 7-8 | 16-17 | 7-8 |
| 225 | 10-11 | 7-8 | 16-17 | 7-8 |
| 250 | 9-10 | 7-8 | 15-16 | 7-8 |
| 275 | 8-9 | 6-7 | 15-16 | 7-8 |
| 300 | 7-8 | 6-7 | 14-15 | 6-7 |
| 325 | 7-8 | 6-7 | 14-15 | 6-7 |
| 350 | 6-7 | 5-6 | 13-14 | 5-6 |
| 375 | 6-7 | 5-6 | 13-14 | 5-6 |
| 400 | 5-6 | 5-6 | 12-13 | 5-6 |
| 425 | 5-6 | 4-5 | 11-12 | 4-5 |
| 450 | 4-5 | 4-5 | 10-11 | 4-5 |
| 475 | 4-5 | 3-4 | 9-10 | 3-4 |
| 500 | 3-4 | 3-4 | 8-9 | 3-4 |
| 525 | 3-4 | 2-3 | 7-8 | 2-3 |
| 550 | 2-3 | 2-3 | 6-7 | 2-3 |
| 575 | 2-3 | 1-2 | 5-6 | 1-2 |
| 600 | 2-3 | 1-2 | 5-6 | 1-2 |
| 625 | 1-2 | 0-1 | 4-5 | 0-1 |
| 650 | 1-2 | 0-1 | 4-5 | 0-1 |
| 675 | 1-2 | 0-1 | 3-4 | 0-1 |
| 700 | 0-1 | 0 | 2-3 | 0-1 |
| 725 | 0-1 | 0 | 1-2 | 0-1 |

### SAG

~30 % of shock travel; same mm table as `fox_dhx_2027`. Preload: snug, then 8 clicks.

### Does not fit B3

- Same as `fox_coil_2020`: A/B/C selector on stroke × rear-wheel travel, plus `spring_rate` input.

## Guide `fox_float_dps_dpx2_2021` — SHOCK- 2021 FLOAT DPS and DPX2

### Source

- URL: https://tech.ridefox.com/bike/owners-manuals/1079/shock--2021-float-dps-and-dpx2
- Rebound image: https://tech.ridefox.com/img/help/page555-V15S/inline/DPS-rebound-setup.jpg
- Document: FOX owner's manual, model year 2021, English (HTML)
- Section / page: "Setting Shock Air Pressure", "Adjusting Rebound", "Adjusting Compression Damping"
- Retrieved: 2026-10-11
- The 2020 (1037) manual is identical; 2018 (824) and 2019 (940) add a 300 psi limit for non-EVOL DPS and
  lack the DPX2 Comp Adj paragraph.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/fox/float-dps/factory` | `damper: dps_2016` | rebound table, constants |
| `shock/fox/float-dps/performance-elite` | `damper: dps_2016` | |
| `shock/fox/float-dps/performance` | `damper: dps_2016` | open-mode adjust is Factory/Performance Elite only |
| `shock/fox/float-dpx2/factory` | `damper: dpx2_2018` | formula + SAG only |
| `shock/fox/float-dpx2/performance-elite` | `damper: dpx2_2018` | formula + SAG only |
| `shock/fox/float-dpx2/performance` | `damper: dpx2_2018` | formula + SAG only |

### Air pressure

Formula (see above).

### Rebound — FLOAT DPS

Same image and values as the FLOAT SL table in `fox_float_sl_float_x_2027` (<100 Open, 100-120 11 … 260-280 3,
280-300 Closed). Source direction: from closed; catalog `dps_2016` `rebound` max 11 (estimate from this table),
`dial_ccw` → same direction. The DPX2 has no rebound table (`dpx2_2018` rebound is `max: ~`).

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open | categorical | `damper: dps_2016`, `damper: dpx2_2018` |
| `open_mode_adjust` | 1 | categorical | `damper: dps_2016` (Factory/Performance Elite non-remote) |

### SAG

25-30 %; same mm table as `fox_float_2027`.

### Pressure limits

DPS EVOL / DPX2 EVOL 350 psi; non-EVOL DPS 300 psi (2018-2019 manuals); catalog 350 with the 300 psi note on DPS ✓.

---

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `shock/fox/dhx/factory` | 2026/2027 DHX manuals give only the ~30 % SAG band and mm table; no rebound/LSC starting values, no spring-rate chart (checked 3100, 3170, and the DHX sections of the 2022-2025 coil manuals) |
| `shock/fox/float-dpx2/*` | No rebound or Comp Adj starting value in the 2018-2021 manuals; formula + SAG band only |
| `fork/fox/34/factory`, `fork/fox/34/performance-elite` (rebound only) | 2025-2027 32/34 manuals have no GRIP X rebound column for the 34 |

## Follow-ups

- **`grip` rebound max 10 vs tables up to 13** (32 Step-Cast, 34, 34 SL, 36 SL, 36, 38; 32 Taper-Cast up to
  22). Every FOX manual since 2018 tabulates GRIP rebound to 13 counted from closed. Either the product-page
  "10" is wrong or the GRIP tables include clicks past the useful range; check a physical GRIP dial. Until
  resolved, rows above 10 cannot be encoded.
- **`rail` rebound max 9 vs AWL 10 / AWL HD 13**. The AWL HD table equals the GRIP table; the HD may have a
  different rebound cartridge.
- **40 `grip_x2` HSR max 8 vs table 10** (identical LSR/HSR columns, possibly a copy error in the manual).
- **38 2027**: decide whether the 2027 tables (lower FLOAT pressures, 10 cc/5 cc spacers) need a `2027`
  generation node or replace `fork/fox/38/2025`.
- **GRIP X base tune changed 10 → 5** (both HSC and LSC) in the 2027 34SL/36/36SL/38 manuals, while the 2027
  32/34 manual keeps 10. Proposed: encode 5 for 36 SL and 36 (newest), keep 10 for the 34.
- **DHX2 2025-2027 direction** is not restated in the 2026/2027 text; inferred from-closed. Confirm.
- **FLOAT X2 2025 manual** (2984) prints the 2021-2024 table and a 300 psi limit, the 2026 manual a new table
  and 350 psi. If 2025 shocks are the older damper, the catalog generation split (2021-2024 vs 2025-2026)
  may be one year off.
- **Trim vs damper mismatch**: manuals reserve HSR/HSC for Factory on FLOAT X2 (2025+) and LSC/LSR-only for
  Performance Elite on DHX2 (2016-2025), but the catalog gives those trims the 4-way damper.
- **Catalog `setup_guide`** of `shock/fox/dhx2/2021` points at the 2021 FLOAT X2 manual (1078); the coil
  manual is owners-manuals/1080 (or 2928 for 2024).
- E-Bike+ / E-Optimized columns exist for 36, 38, Podium and the 2018-2020 36; no catalog option.
- 36 Rhythm max pressure is not printed in the 2026/2027 manuals (the 2025 manual: 120 psi for "36 FLOAT/Rhythm/E-bike+").
