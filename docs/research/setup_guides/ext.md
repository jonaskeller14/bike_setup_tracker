# EXT — setup guide research

Catalog files: `data/component_presets/fork/ext.yaml`, `data/component_presets/shock/ext.yaml`
Researched: 2026-10-12

## Summary

- **Era V2 / Era V2 LT quick manual**: one rider-weight table (kg and lb). Each row gives both air chambers (+ and ++, bar and psi) and the HSC–LSC–R clicks from closed. It is the only weight-indexed fork table. The Vaia quick manual has no table.
- **Aria (V1) quick manual**: a table indexed by **equivalent coil spring rate** (lb/in), not by rider weight. Each row gives + / ++ pressure and BH–BL–R–H clicks. The input is second-order, so it doesn't fit B3.
- **Coil shocks**: the Storia V3 / Arma V3 / Storia V3-S / Arma–Storia V4 quick manuals each print **one starting click set** (constants). e-Storia prints none.
- **EXT RideMaster web app** (official, extremeshox.com/ridemaster) covers **Vecta** and **Aria V2 / Aria V2 DH**. Its calculator formulas are public in the widget config and are transcribed here:
  - spring rate (or air pressure for the Aria V2) from rider weight, bike weight, rear travel, stroke and a SAG target picked by trail steepness;
  - HSC / LSC / rebound (and HBC on the Aria V2) from the spring-rate bracket, shifted by trail type and riding level.
- **Spring Calculator** (extremeshox.com/spring-calculator): an older coil formula with SAG 28 / 30 / 33 %.
- **SAG**: fork 15–20 % of travel (Suspension Setup page). Shocks: no fixed band. RideMaster picks 28 / 30 / 33 % by trail steepness.
- Encoding: two-chamber pressure pairs are two targets on the same rows; open-ended pressure cells are R9 inequality bands where a limit is published, else the row is dropped for that target. No rule, note only: equivalent-spring-rate input (Aria V1) and multi-input formulas (bike weight, rear travel; #71), click offsets per trail type, RideMaster outputs above the published pressure limits (source conflict).

## Guide `ext_era_v2_2023` — Era V2 / Era V2 Long Travel quick manual

### Source

- URL: https://extremeshox.com/wp-content/uploads/2023/08/quick-manual-Era-v2_20x30.pdf
- Document: Era V2 quick manual (header: suitable for "ERA V2" and "ERA V2 Long Travel"), 2023 upload, English/Italian
- Section / page: p. 2, "Suggested setup / Setup consigliato"
- Retrieved: 2026-10-11. It is the manual linked from both the Era V2.1 and the Era V2 LT product pages (2026-10-11). EXT publishes no separate V2.1 manual.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ext/era-v2-1/standard` | `damper: era_cartridge` | No travel split in the table |
| `fork/ext/era-v2-lt/standard` | `damper: era_cartridge` | Same table (manual covers "Era V2 Long Travel") |

Gaps: the table has no travel or wheel-size dependence. The manual is for the "Era V2"; the catalog's "Era V2.1" uses it because EXT links it from the V2.1 page.

### Air pressure + clicks — rider weight table

Input: rider weight (kg, lb also printed) · Output: `main_chamber_pressure` (+), `secondary_chamber_pressure` (++), `hsc`, `lsc`, `rebound` · `when: { damper: era_cartridge }`

| Rider weight (kg) | Rider weight (lb) | + (bar) | + (psi) | ++ (bar) | ++ (psi) | HSC | LSC | R |
|---|---|---|---|---|---|---|---|---|
| < 60 | < 132 | < 3.1 | < 45 | < 4.9 | < 70 | 10 | 10 | 18 |
| 60 | 132 | 3.1 | 45 | 4.9 | 70 | 9 | 9 | 16 |
| 70 | 154 | 3.8 | 55 | 5.9 | 85 | 8 | 8 | 14 |
| 80 | 176 | 4.5 | 65 | 6.9 | 100 | 7 | 7 | 12 |
| 90 | 198 | 5.2 | 75 | 7.9 | 115 | 6 | 6 | 10 |
| > 100 | > 220 | > 5.9 | > 85 | > 9 | > 130 | 5 | 5 | 8 |

- Column order as printed: "[HSC – LSC – R]".
- Weights are **points** (60, 70, 80, 90), not brackets. There is no 100 kg row: the table jumps from 90 to "> 100".
- The first and last pressure rows are open bounds (`< 45`, `> 85`), not values. R9: the weight keys become open-ended rows `<60` and `100+` (R1). `> 85` → `[85, max]` and `> 130` → `[130, max]` against the 200 psi limit (set as each chamber's `max`, see Pressure limits). `< 45` / `< 70` have no published minimum, so the `<60` row is left out of both pressure rules. Clicks on those rows are plain numbers and keep the row.

Counting direction: the source says maximum clockwise = full closed = click 0, for all adjusters. Catalog `era_cartridge`: `lsc` max 16, `hsc` max 14, `rebound` max 20, default `dial_ccw` (from closed). Same direction → encode as published. All values are within the catalog max. Those maxima are secondary-source figures (Pinkbike / Enduro-MTB).

### SAG

Suspension Setup page (https://extremeshox.com/suspension-setup/, named for ERA V2.1 / ERA V2 LT / FERRO): fork SAG 15–20 % of total travel. → `sag` `range` 15–20 on both Era paths.

### Volume spacers

Travel is set with internal spacers. No volume-spacer counts are published, and the catalog has no `volume_spacers` target.

### Pressure limits

"Do not exceed 200 psi / 14 bar" (combined, not per chamber). The catalog has no per-chamber `max`. Neither chamber can exceed the combined limit, so set `max: 200` on both chamber adjusters (R8); the `> 85` / `> 130` bands resolve against it.

### Does not fit B3

- Two air chambers: fits as two separate targets keyed on the same rows.
- Open-ended rows (`< 45`, `> 85` psi): resolved above (R1 rows, R9 bands, `<60` dropped from the pressure rules).

## Guide `ext_vaia_2024` — Vaia quick manual

### Source

- URL: https://extremeshox.com/wp-content/uploads/2024/12/Vaia-Quick-Manual-1.pdf
- Document: Vaia quick manual (Dec 2024 upload), English
- Section / page: p. 2 "Suggested setup" (QR link only), "Porter tips" (QR) — product page https://extremeshox.com/product/vaia/ ("the porter tips for ext vaia", text only)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ext/vaia/standard` | `damper: vaia_cartridge` | No numbers except the limit and the general fork SAG band |

### SAG

General fork SAG 15–20 % (Suspension Setup page; Vaia not named there). The manual's "20/30 % of the travel" is the depth to compress the fork for chamber equalisation, **not** a SAG target.

### Pressure limits

"Do not exceed 250 psi / 17 bar" (combined); consistent with the catalog notes.

No weight table, no click starting point. The "Porter tips" on the product page are qualitative (what + / ++ pressure and volume do), with no numbers.

## Guide `ext_aria_2023` — Aria (V1) quick manual

### Source

- URL: https://extremeshox.com/wp-content/uploads/2023/08/Quick-manual-Aria-min.pdf
- Document: Aria quick manual, 2023 upload, English
- Section / page: p. 2 "Suggested setup"
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ext/aria/metric-standard` | `damper: aria` | |
| `shock/ext/aria/metric-trunnion` | `damper: aria` | |

### Suggested setup — equivalent spring rate table

Input: **EQ. RATE (lb)**, the equivalent coil spring rate, not rider weight · Outputs: `main_chamber_pressure`, `secondary_chamber_pressure`, `hsc` (BH), `lsc` (BL), `rebound` (R), `hbc` (H)

| EQ. rate (lb) | + (bar) | + (psi) | ++ (bar) | ++ (psi) | BH | BL | R | H |
|---|---|---|---|---|---|---|---|---|
| < 250 | < 9.6 | < 140 | < 18.6 | < 270 | 10 | 12 | 13 | 4 |
| 300 | 11 | 160 | 21.4 | 310 | 10 | 10 | 12 | 3 |
| 350 | 12,4 | 180 | 24.1 | 350 | 9 | 8 | 10 | 2 |
| 400 | 13.8 | 200 | 19.3 | 390 | 9 | 8 | 9 | 1 |
| 450 | 15.2 | 220 | 26.9 | 430 | 8 | 7 | 8 | 1 |
| 500 | 17.2 | 250 | 33 | 480 | 8 | 6 | 7 | 0 |
| > 600 | > 18.6 | > 270 | > 38 | > 550 | 8 | 6 | 6 | 0 |

- Click column header as printed: "[BH BL R – H]" (BH = HSC, BL = LSC, R = rebound, H = HBC).
- As printed, the ++ bar values for the 400 and 450 rows (19.3, 26.9) don't match their psi values: 390 psi ≈ 26.9 bar and 430 psi ≈ 29.6 bar, so the bar column looks shifted. Use the psi column.
- There is no 550 row; the table goes 500 → "> 600".

Counting direction: from closed (click 0 = full closed, maximum clockwise). Catalog `aria`: `hsc` max 10, `lsc` 12, `rebound` 13, `hbc` 4, default `dial_ccw`, all **estimated from this same table**. Same direction → encode as published.

### Pressure limits

+ chamber 280 psi / 19 bar, ++ chamber 600 psi / 41 bar; match catalog `main_chamber_pressure` max 280 and `secondary_chamber_pressure` max 600. The manual also prints a gauge-loss table for checking ++ with the EXT pump: 600→499, 550→457, 500→416, 450→374, 400→333, 350→291, 300→249, 250→208, 200→166, 150→125 psi. Then refill. A note, not a target.

### Does not fit B3

The input is an equivalent coil rate (a property of rider + bike), not `rider_weight`, and the air shock has no `spring_rate` adjuster to read it from (R4). It needs bike-level inputs (#71), so no rule until then; a `note` at most.

## Guide `ext_ridemaster_2026` — EXT RideMaster web app (Vecta; Aria V2 / Aria V2 DH)

### Source

- URLs:
  - https://extremeshox.com/ridemaster/ (index: "Vecta SETUP", "Aria V2 / DH SETUP")
  - https://extremeshox.com/vecta-ridemaster/ (Elfsight calculator widget 6c57808e-390a-48fd-bc80-92e42423e8f2)
  - https://extremeshox.com/aria-V2-ridemaster/ (widget faa9ede5-3a58-40b2-8a32-cc151cc81461, header "Aria V2 - Aria V2 DH")
- The Vecta and Aria V2 quick manuals both point to it under "Suggested setup": https://extremeshox.com/wp-content/uploads/2025/06/EXT-Vecta-Quick-Manual.pdf, https://extremeshox.com/wp-content/uploads/2026/09/Quick-manual-Aria-V2-3.pdf
- Document: calculator field and formula definitions read from the public widget configuration (page modified 2026-09-24), English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ext/vecta/metric-standard` | `damper: vecta` | Spring rate + HSC/LSC/R |
| `shock/ext/vecta/metric-trunnion` | `damper: vecta` | same |
| `shock/ext/aria-v2/metric-standard` | `damper: aria_v2` | + / ++ pressure + HSC/LSC/R/HBC |
| `shock/ext/aria-v2/metric-trunnion` | `damper: aria_v2` | same |
| `shock/ext/aria-v2-dh/metric-standard` | `damper: aria_v2_dh` | same widget as Aria V2 |
| `shock/ext/aria-v2-dh/metric-trunnion` | `damper: aria_v2_dh` | same |

### Inputs (as defined in the widget)

| Field | Range / options (option value) |
|---|---|
| Vehicle weight | 0–30 kg ("Your MTB/E-MTB weight") |
| Rider weight with gear | Vecta 0–150 kg, Aria V2 40–150 kg |
| Rear travel | mm |
| Shock stroke | mm |
| Riding level | Beginner (0), Intermediate (1), Expert (2) |
| Trail steepness | Low (0), Medium (2), High (1) |
| Trail type | Natural / technical (0), Mix (1), Jumps / flow (2) |
| Desired shock feeling (Aria V2 only) | Coil-like feeling (linear) (17), Poppy-lively (progressive) (18) |

### SAG

SAG target by trail steepness: **High → 33 %, Medium → 30 %, Low → 28 %**. Vecta shows it as the result "SAG recommended %". Trail steepness is no input and no riding style, so encode `sag` `range: [28, 33]`, `comfort_at: max`, with the steepness split in the `note`.

### Formulas — spring rate

k (lb/in) = 9.81 × (0.6 × rider_with_gear_kg + 0.35 × bike_kg) × rear_travel_mm ÷ (sag × stroke_mm²) × 5.7101471627692

The widget labels this intermediate "Spring rate [N/mm]", but the × 5.71 factor already converts it to lb/in.
- Vecta: rounded to the nearest 25, clamped to 325–800 lb/in. Caption: "Available spring rates range are from 325 to 800 lbs/inch."
- Aria V2: "Ideal spring rate" rounded to the nearest 25, capped at 800, no lower clamp.

Calculated example, **calculated from the published formula**: rider 50–120 kg with gear, with *assumed* bike 16 kg, rear travel 150 mm, stroke 60 mm. Vecta rounding/clamp. Shows the shape only; real values need the bike's numbers.

| Rider with gear (kg) | raw @ 28 % | Vecta @ 28 % | raw @ 30 % | Vecta @ 30 % | raw @ 33 % | Vecta @ 33 % |
|---|---|---|---|---|---|---|
| 50 | 296.8 | 325 | 277.0 | 325 | 251.8 | 325 |
| 55 | 321.8 | 325 | 300.3 | 325 | 273.0 | 325 |
| 60 | 346.8 | 350 | 323.7 | 325 | 294.2 | 325 |
| 65 | 371.8 | 375 | 347.0 | 350 | 315.4 | 325 |
| 70 | 396.8 | 400 | 370.3 | 375 | 336.7 | 325 |
| 75 | 421.8 | 425 | 393.7 | 400 | 357.9 | 350 |
| 80 | 446.8 | 450 | 417.0 | 425 | 379.1 | 375 |
| 85 | 471.8 | 475 | 440.4 | 450 | 400.3 | 400 |
| 90 | 496.8 | 500 | 463.7 | 475 | 421.5 | 425 |
| 95 | 521.8 | 525 | 487.0 | 475 | 442.8 | 450 |
| 100 | 546.8 | 550 | 510.4 | 500 | 464.0 | 475 |
| 105 | 571.8 | 575 | 533.7 | 525 | 485.2 | 475 |
| 110 | 596.8 | 600 | 557.1 | 550 | 506.4 | 500 |
| 115 | 621.9 | 625 | 580.4 | 575 | 527.6 | 525 |
| 120 | 646.9 | 650 | 603.7 | 600 | 548.8 | 550 |

### Formulas — Aria V2 air pressure (from the ideal spring rate)

- P+ = 0.4 × ideal_rate + 40, then + trail type: technical −10, mix 0, flow +10 (psi).
- P++ = round to 5 (P+ × ratio), with ratio 1.5 (linear) or 1.95 (progressive), capped at 610. Then + trail type: technical −20, mix 0, flow +20. P++ is computed from the already-adjusted P+. The published ++ formula is missing an operator between its last two IF terms; the intent reads as above.
- Caption: ++ must always be ≥ + pressure.

Lookup for trail type = Mix (no offsets), **calculated from the published formula**:

| Ideal rate (lb/in) | P+ (psi) | P++ linear (psi) | P++ progressive (psi) | HSC / LSC start | Rebound start |
|---|---|---|---|---|---|
| 325 | 170 | 255 | 330 | 8 | 12 |
| 350 | 180 | 270 | 350 | 8 | 12 |
| 375 | 190 | 285 | 370 | 8 | 11 |
| 400 | 200 | 300 | 390 | 8 | 11 |
| 425 | 210 | 315 | 410 | 7 | 10 |
| 450 | 220 | 330 | 430 | 7 | 10 |
| 475 | 230 | 345 | 450 | 7 | 9 |
| 500 | 240 | 360 | 470 | 7 | 9 |
| 525 | 250 | 375 | 490 | 6 | 8 |
| 550 | 260 | 390 | 505 | 6 | 8 |
| 575 | 270 | 405 | 525 | 6 | 7 |
| 600 | 280 | 420 | 545 | 6 | 7 |
| 625 | 290 | 435 | 565 | 5 | 6 |
| 650 | 300 | 450 | 585 | 5 | 6 |
| 675 | 310 | 465 | 605 | 5 | 5 |
| 700 | 320 | 480 | 610 | 5 | 5 |
| 725 | 330 | 495 | 610 | 4 | 4 |
| 750 | 340 | 510 | 610 | 4 | 4 |
| 775 | 350 | 525 | 610 | 4 | 3 |
| 800 | 360 | 540 | 610 | 4 | 3 |

Limits check against the Aria V2 manual (+ 300 psi / ++ 600 psi; catalog max 300 / 600):
- P+ exceeds 300 from rate 675 up (310–360 psi), and from 650 up with the flow offset.
- P++ reaches 605–630 psi (610 cap + 20 flow offset), above the 600 psi maximum.
- Encoding must clamp to the catalog `max` or flag these rows.

### Clicks (Vecta and Aria V2, identical)

Start values by spring-rate bracket (Vecta: the clamped rate; Aria V2: the ideal rate):

| Spring rate (lb/in) | HSC start | LSC start | Rebound start |
|---|---|---|---|
| 325-350 | 8 | 8 | 12 |
| 375-400 | 8 | 8 | 11 |
| 425-450 | 7 | 7 | 10 |
| 475-500 | 7 | 7 | 9 |
| 525-550 | 6 | 6 | 8 |
| 575-600 | 6 | 6 | 7 |
| 625-650 | 5 | 5 | 6 |
| 675-700 | 5 | 5 | 5 |
| 725-750 | 4 | 4 | 4 |
| 775-800 | 4 | 4 | 3 |

Offsets, added to the start value:

| Input | HSC | LSC | Rebound |
|---|---|---|---|
| Trail type: Natural / technical | +2 | +1 | +2 |
| Trail type: Mix | 0 | 0 | 0 |
| Trail type: Jumps / flow | −2 | −1 | −2 |
| Riding level: Beginner | +2 | +1 | −2 |
| Riding level: Intermediate | 0 | 0 | 0 |
| Riding level: Expert | −2 | −1 | +2 |

Final clamps: HSC 4–8, LSC 4–8, Rebound 3–12. Aria V2 only: HBC = 4 + (technical +2, mix 0, flow −2).

Counting direction: result captions say "adjustment from fully close". Catalog `vecta`: `lsc` 14, `hsc` 14, `rebound` 16 (secondary source), `dial_ccw`. Same direction, all outputs ≤ 12 → encode as published. `aria_v2` / `aria_v2_dh`: all `max: ~`, but the same direction (from closed), so encode as published.

### Does not fit B3

- Inputs B3 lacks: bike weight, rear wheel travel, trail steepness, trail type, riding level (only `riding_style` exists, as one axis), desired feeling.
- Second-order chain: rider → spring rate → clicks / pressure.
- Encoding:
  - Vecta: the click tables with `input: spring_rate`, read from the component's own `spring_rate` adjuster (R4). Trail-type and riding-level offsets stay a `note`: they are relative offsets (R8), and the riding level is skill (Beginner / Expert), not firmness, so it doesn't map onto `riding_style` (R7).
  - Aria V2 has no `spring_rate` adjuster: no rule until bike-level inputs exist (#71).

## Guide `ext_spring_calculator_2026` — EXT Spring Calculator (web)

### Source

- URL: https://extremeshox.com/spring-calculator/ (Calculated Fields Form, form 1), linked from https://extremeshox.com/suspension-setup/ ("How to find the correct spring rate for your shock?")
- Retrieved: 2026-10-11

### Catalog mapping

Generic for every EXT coil shock with a `spring_rate` target: `shock/ext/storia-v3/metric-standard`, `shock/ext/storia-v3/metric-trunnion`, `shock/ext/storia-v3/imperial`, `shock/ext/storia-v4/metric-standard`, `shock/ext/storia-v4/metric-trunnion`, `shock/ext/arma-v3/metric-standard`, `shock/ext/arma-v3/metric-trunnion`, `shock/ext/arma-v3/imperial`, `shock/ext/arma-v4/metric-standard`, `shock/ext/arma-v4/metric-trunnion`, `shock/ext/e-storia/metric-standard`, `shock/ext/e-storia/metric-trunnion` (Vecta: prefer RideMaster).

### Formulas

Rate (lb/in) = (bike_kg + rider_kg − 14) × 9.81 × 0.65 × 5.7 × rear_travel_mm ÷ (sag × stroke_mm²), rounded to 25, shown for sag 28 %, 30 % and 33 %. Reverse mode: SAG % for a given spring rate. This differs from the RideMaster weighting (0.6 × rider + 0.35 × bike). No calculated table: it needs the bike's rear travel and weight.

### Does not fit B3

Same bike-level inputs as RideMaster: no rule until #71; at most a `note` describing the formula in our words.

## Guide `ext_arma_storia_v3_2023` — Arma / Storia V3 quick manual (+ Storia V3-S quick manual)

### Source

- URLs:
  - https://extremeshox.com/wp-content/uploads/2023/09/ARMA-STORIA_V3_quick_manual.pdf (node `setup_guide` for Storia V3 and Arma V3; the PDF's xref table is damaged but it renders)
  - https://extremeshox.com/wp-content/uploads/2023/08/Storia_V3-S_Quick_Manual_1.1.pdf
- Section / page: p. 2 "Don't know where to start? Try these clics"
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ext/storia-v3/metric-standard`, `…/metric-trunnion`, `…/imperial` | `damper: storia_v3` | V3 manual: BH10 BL6 R4 — **conflicts with V3-S manual** |
| `shock/ext/arma-v3/metric-standard`, `…/metric-trunnion`, `…/imperial` | `damper: arma_v3` | V3 manual: BH10 BL6 R4 |

### Constants / base tune

| Source | `hsc` (BH) | `lsc` (BL) | `rebound` (R) |
|---|---|---|---|
| Arma / Storia V3 quick manual | 10 | 6 | 4 |
| Storia V3-S quick manual 1.1 | 7 | 6 | 7 |

Both count clic 0 = full close (clockwise). Catalog `storia_v3` has `hsc` max 14, `lsc` 14, `rebound` 10, `dial_ccw`: same direction, values in range. Catalog `arma_v3` is all `max: ~`, same direction → encode as published. Arma V3 has an HBC adjuster, but no HBC start is printed.

## Guide `ext_arma_storia_v4_2024` — Arma / Storia V4 quick manual

### Source

- URL: https://extremeshox.com/wp-content/uploads/2024/06/Arma-Storia-V4-Quick-Manual.pdf
- Section / page: p. 2 "Suggested setup / Setup consigliato"
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ext/storia-v4/metric-standard`, `…/metric-trunnion` | `damper: storia_v4` | |
| `shock/ext/arma-v4/metric-standard`, `…/metric-trunnion` | `damper: arma_v4` | |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 10 | from closed | `damper: storia_v4` / `damper: arma_v4` |
| `lsc` | 10 | from closed | same |
| `rebound` | 9 | from closed | same |
| `hbc` | 5 | from closed | same |

Catalog `arma_v4`: `lsc` 14, `hsc` 15, `rebound` 14, `hbc` 10 → same direction, in range. `storia_v4`: `hbc` 10, others `max: ~`, same direction → encode as published. The manual suggests setting rebound first, then LSC, then HSC, and closing HBC progressively on frequent bottom-outs (note). It also says the rebound must be set to 0–4 clicks from closed to fit the lower spring support during a spring change. That is an installation note, not a setup value.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `shock/ext/e-storia/metric-standard`, `shock/ext/e-storia/metric-trunnion` | e-Storia quick manual (https://extremeshox.com/wp-content/uploads/2023/09/e-Storia-quick-manual.pdf) prints no starting clicks and no table. Only the generic Spring Calculator applies; max preload 2 mm; high-rate springs (> 600 lb/in / 105 N/mm) need EXT adapters. |
| `fork/ext/vaia/standard` | Quick manual has no table or clicks (QR to the qualitative "Porter tips"). Only the generic fork SAG 15–20 % and the 250 psi limit. |

## Catalog changes before encoding (R8, R9)

R8 fixes:
- Era V2 chambers (`+` and `++`): `max: 200` psi each, the published combined
  limit, so the `> 85` / `> 130` bands have an end.
- Storia V3 vs V3-S constants: decide or split the node before encoding.

R9 type changes: none.

## Follow-ups

- Storia V3 vs V3-S starting clicks conflict (BH10 BL6 R4 vs BH7 BL6 R7) under one catalog node. The catalog note says it is sold as "V3-S". Decide which applies, or split the node.
- The Era V2 table is the V2 manual; check whether EXT publishes a V2.1-specific table (the full user manual is behind a QR code and wasn't found as a PDF).
- RideMaster Aria V2 outputs can exceed the published + 300 / ++ 600 psi limits. Clamp or confirm with EXT. The ++ formula has a missing operator.
- RideMaster's steepness option values are ordered Low 0 / High 1 / Medium 2. The mapping above follows the formula (value 1 → 33 %, 2 → 30 %, else 28 %), i.e. High 33 / Medium 30 / Low 28.
- Aria V1 table ++ bar typos (400 / 450 rows). Encode psi only.
- The Era V2S quick manual (https://extremeshox.com/wp-content/uploads/2023/09/ERA_V2S_quick_manual-5.pdf) isn't researched further: the Era V2S isn't in the catalog.
- Shock SAG has no fixed band on the EXT site (only a 30 % worked example). The RideMaster steepness values give the `range: [28, 33]` rule above.
