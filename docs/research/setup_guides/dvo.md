# DVO — setup guide research

Catalog files: `data/component_presets/fork/dvo.yaml`, `data/component_presets/shock/dvo.yaml`
Researched: 2026-10-11

## Summary

- **Forks.** Every current and legacy DVO fork in the catalog has a chart except the
  Sapphire 32, which has only an air chart. DVO's fork charts share a few shapes:
  - **Air pressure:** a band per rider-weight bracket. Each row shades a "Plush" to
    "Firm" span of psi columns, so it is encoded as a `range`. lb and kg are both printed.
  - **Rebound:** a band of clicks counted from closed. The input is **air pressure**,
    not rider weight. That is a second-order input (`input: pressure`).
  - **HSC:** full rotations from open. The input is air pressure (single values in the
    2024+ guides, 2-turn bands in the 2020 guide).
  - **OTT:** rotations from open. The Onyx 38 guide keys it to air pressure; the 2020
    guide keys it to rider weight.
  - **Constants:** the Diamond CORE LSC starts at 7.
  - **SAG band:** 15–30 % for forks.
  - **Factory volume spacers:** 0 on the Onyx 38, Diamond 36 and CORE.
- **Emerald (legacy):** one base-tune table, rider weight → psi, OTT rotations, rebound,
  HSC and LSC clicks, all counted clockwise from wide open.
- **Shocks.**
  - **Air pressure** (Topaz): weight → psi band.
  - **Bladder pressure:** a weight → psi chart (a gradient chart on the 2023+ guides, a
    cell chart on the 2020 Topaz guide, a literal table for the Jade).
  - **Rebound** (Topaz): the clicks chart is labelled "Air Pressure PSI", but its rows
    look like rider-weight brackets. See Does not fit B3.
  - **T3 lever:** a trail-style chart (riding-style input, categorical target).
  - **Coil spring rate:** a weight → lb/in chart for the Jade X WP1. The Jade gives one
    rate per **shock size**.
  - **Jade:** full base tunes **per shock size** (rider weight → bladder psi, rebound,
    HSC, LSC, spring rate).
  - **SAG:** 20–30 % (Topaz), 25–30 % (Jade, Jade X).
- **Not covered by B3:**
  - pressure as an input (rebound, HSC, OTT);
  - E-bike and E1/E2 columns that have no catalog option;
  - an internal 3-position OTT that has no catalog adjuster;
  - a size-keyed coil table;
  - trail-style columns whose names are not riding-style ids;
  - targets on WP CV shocks, which declare `missing_adjustments`;
  - gradient bladder charts with no exact bounds.

---

## Guide `dvo_onyx38_2024` — Onyx 38 Series Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2024/08/38-Setup-Guide-v1.1.pdf (the catalog's `setup_guide`)
- Document: Onyx 38 Series Set-Up Guide, Version 1.1 (2024), English
- Section / page: OTT p.6–7, SAG/air p.8–9, rebound p.10–11, HSC p.12–13, LSC p.14, volume spacers p.18–20
- Retrieved: 2026-10-11
- Older version: Version 1.0, https://dvosuspension.com/wp-content/uploads/2023/09/onyx38setupguide-v1.pdf. Its OTT, rebound and HSC rows differ; see "Differences vs. v1.0" below.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dvo/38/d1` | `damper: onyx38_d1e1` | air, rebound, HSC, OTT, spacers |
| `fork/dvo/38/d1-sl` | `damper: onyx38_d1e1` | air, rebound, HSC, spacers (no OTT) |
| `fork/dvo/38/d2` | `damper: onyx38_d2e2` | air, rebound (no HSC, no OTT) |
| `fork/dvo/38/d3` | `damper: onyx38_d3e3` | air, rebound (no HSC, no OTT) |

Gaps:
- The air and rebound charts are captioned "for all onyx 38 models"; they apply to
  `travel_mm: 160 | 170 | 180` alike.
- OTT is external on the D1 only (p.6 table), which matches the catalog.
- p.18: volume spacers "should only be used in 'SL' model forks". The catalog declares
  `volume_spacers` (max 4) on D1, D2 and D3 too. Flag for the catalog.
- The guide has no LSC chart, only directions (D1 5 settings, D2 3, D3 full-turn).

### Air pressure — all Onyx 38 models

Input: rider weight (lb, kg also printed) · Output: psi `range` (Plush → Firm) · applies to all four paths

| Rider weight (lb) | Rider weight (kg) | psi Plush | psi Firm |
|---|---|---|---|
| 120-139 | 54-63 | 50 | 60 |
| 140-159 | 64-72 | 55 | 65 |
| 160-179 | 73-81 | 60 | 70 |
| 180-199 | 82-90 | 65 | 75 |
| 200-219 | 91-100 | 70 | 80 |
| 220-239 | 101-108 | 75 | 85 |
| 240-249 | 109-113 | 80 | 90 |
| 250-259 | 114-117 | 90 | 100 |

The psi axis is 50, 55, …, 95, "100 MAX". Each band covers three columns. The last
row jumps a column (90–100), as printed.

E-bike tip (p.9): "+5-10 PSI from the recommended setting". The catalog has no e-bike
option, so this is a `note` only.

### Rebound — all Onyx 38 models

Source direction: clicks out from closed (clockwise = closed; scale strip "Open 25 … 1 Closed").
Catalog: `rebound`, max 25, "Counted from fully closed" (all three dampers) → **same
direction, encode as published.**

Input: air pressure (psi) · Output: clicks `range` (Fast → Slow)

| Air pressure (psi) | Clicks Fast | Clicks Slow |
|---|---|---|
| 50-55 | 24 | 20 |
| 55-60 | 22 | 18 |
| 60-65 | 20 | 16 |
| 65-70 | 18 | 14 |
| 70-75 | 16 | 12 |
| 75-80 | 14 | 10 |
| 80-85 | 12 | 8 |
| 90-95 | 10 | 6 |
| 100+ | 8 | 4 |

The chart axis is 25, 24, 22, 20, …, 2, 0. There is **no 85-90 row** (printed
that way).

### HSC — D1 (`onyx38_d1e1`)

Source direction: full rotations (NOT clicks) from fully open, clockwise = firmer.
Catalog: `hsc` numerical `turns`, min 0, "Start fully open … clockwise = firmer" →
**same direction, encode as published.**

Input: air pressure (psi) · Output: rotations (single value)

| Air pressure (psi) | HSC rotations |
|---|---|
| 50-55 | 0 |
| 55-60 | 0 |
| 60-65 | 1 |
| 65-70 | 1 |
| 70-75 | 2 |
| 75-80 | 2 |
| 80-85 | 3 |
| 85-90 | 3 |
| 90-95 | 4 |
| 100+ | 4 |

Axis 0–5. There is no 95-100 row.

### OTT — D1 only (`fork/dvo/38/d1`)

Source direction: full rotations from open (counter-clockwise). Catalog: `ott` numerical
`turns`, min 0, "more OTT = plusher" → **same direction, encode as published.**

Input: air pressure (psi) · Output: rotations `range`

| Air pressure (psi) | OTT rotations |
|---|---|
| 50-55 | 1-4 |
| 55-60 | 3-5 |
| 60-65 | 4-6 |
| 65-70 | 5-7 |
| 70-75 | 6-8 |
| 75-80 | 7-9 |
| 85-90 | 8-10 |
| 90-100 | 9-12 |

There is **no 80-85 row** (printed that way). Axis 1–12.

### Differences vs. v1.0 (2023)

The air chart and SAG table are identical. These charts differ:

| Chart | Row | v1.0 | v1.1 |
|---|---|---|---|
| OTT | 50-55 / 55-60 / 60-65 / 65-70 | 1-3 / 3-5 / 5-7 / 7-9 | 1-4 / 3-5 / 4-6 / 5-7 |
| OTT | 70-75 | (no row) | 6-8 |
| OTT | 75-80 / 85-90 / 90-100 | 9-11 / 11-12 / 12 | 7-9 / 8-10 / 9-12 |
| Rebound | rows | 50-55 … 70-75 as v1.1; then 80-85: 14-10, 90-95: 12-8, 100+: 10-6 (no 75-80 row) | see table above |
| HSC | rows | 50-55, 55-60: 0; 60-65, 65-70: 1; 70-75, 80-85: 2; 90-95, 100+: 3 (no 75-80, 85-90) | see table above |

Encode v1.1.

### Constants / base tune

None. The guide gives no LSC chart.

### SAG

15 %–30 % (p.8). Less SAG suits high-speed stability; around 30 % suits comfort and
cornering. The mm table is printed:

| Max travel | 15 % | 20 % | 30 % |
|---|---|---|---|
| 160mm | 24mm | 32mm | 48mm |
| 170mm | 26mm | 34mm | 51mm |
| 180mm | 27mm | 36mm | 54mm |

### Volume spacers

| Travel | Factory installed | Max |
|---|---|---|
| 160-180mm | 0 | 4 |

The 0 applies to `fork/dvo/38/d1-sl`. The guide says the other trims should not use
spacers.

### Pressure limits

Max 100 psi (p.8). This matches the catalog `pressure` max 100.

### Formulas

None. The only offset is the e-bike tip, +5–10 psi (a note).

### Does not fit B3

- Rebound, HSC and OTT take **air pressure** as the input (`input: pressure`), which
  is second-order. They need the rider's current pressure value.
- The last air band skips a column (90–100), as printed.

---

## Guide `dvo_diamond36_2024` — Diamond 36 Series Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2024/05/DVO-Diamond-36-Setup-Guide-May16.pdf
- Document: Diamond 36 Series Set-Up Guide, Version 1.1 (May 2024), English
- Section / page: SAG/air p.6–7, rebound p.8–9, HSC p.10–11, LSC p.12, volume spacers p.16–18
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dvo/diamond-36/d1-sl` | `damper: diamond36_d1e1` | air, rebound, HSC, spacers |

Gaps:
- There is no OTT chart, which matches the catalog (no OTT declared).
- The guide has no LSC chart.

### Air pressure — "Diamond 36"

**Identical to `dvo_onyx38_2024`, row for row:** 120-139: 50–60 · 140-159: 55–65 ·
160-179: 60–70 · 180-199: 65–75 · 200-219: 70–80 · 220-239: 75–85 · 240-249: 80–90 ·
250-259: 90–100. lb and kg columns are as in the Onyx 38 table. The axis is 50…95,
"100 MAX".

E-bike tip: +5–10 psi (note only).

### Rebound — `diamond36_d1e1`

Source direction: clicks out from closed (scale strip "Open 25 … 1 Closed"). Catalog:
`rebound` max 25, from closed → **same direction, encode as published.**

Input: air pressure (psi)

| Air pressure (psi) | Fast | Slow |
|---|---|---|
| 50-55 | 24 | 20 |
| 55-60 | 22 | 18 |
| 60-65 | 20 | 16 |
| 65-70 | 18 | 14 |
| 70-75 | 16 | 12 |
| 75-80 | 14 | 10 |
| 80-85 | 12 | 8 |
| 90-95 | 10 | 6 |
| 100+ | 8 | 4 |

### HSC — `diamond36_d1e1`

Source direction: full rotations from open, clockwise = firmer. Catalog: `hsc`
numerical turns from open → **same direction.**

| Air pressure (psi) | HSC rotations |
|---|---|
| 50-55 | 0 |
| 55-60 | 0 |
| 60-65 | 1 |
| 65-70 | 1 |
| 70-75 | 2 |
| 75-80 | 2 |
| 80-85 | 3 |
| 85-90 | 3 |
| 90-95 | 4 |
| 100+ | 4 |

### SAG

15 %–30 %.

| Max travel | 15 % | 20 % | 30 % |
|---|---|---|---|
| 140mm | 21mm | 28mm | 42mm |
| 150mm | 22.5mm | 30mm | 45mm |
| 160mm | 24mm | 32mm | 48mm |

### Volume spacers

| Travel | Factory installed | Max |
|---|---|---|
| 140-160mm | 0 | 6 |

The text on p.16 says "maximum of 4". The table says 6 (the catalog uses 6).

### Pressure limits

Max 100 psi. This matches the catalog max 100.

### Does not fit B3

The rebound and HSC charts take a pressure input, as in the Onyx 38 guide.

---

## Guide `dvo_diamond36core_2026` — Diamond CORE Series Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2026/05/V3Diamond-CORE-Set-up-Guide.pdf
- Document: Diamond CORE Series Set-Up Guide. The cover says "Version 1.1"; the file name says V3 (2026/05). English.
- Section / page: SAG/air p.6–7, rebound p.8–9, LSC p.10, volume spacers p.16
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dvo/diamond-36/core` | `damper: diamond_core` | air, rebound, compression constant, spacers |

### Air pressure

Captioned "(Diamond 36)". **Identical to the Diamond 36 / Onyx 38 air table** (same 8
rows, same bands). Axis 50…95, "100 MAX".

Dual-chamber note: after inflating, compress about 25 mm to equalise, then reset the
pressure. This is not a target.

### Rebound — `diamond_core`

Source direction: clicks out from closed. The strip reads "Open 28 27 26 25 24 … 1
Closed". The chart axis runs 25…0 only. Catalog: `rebound` max 28, from closed →
**same direction, encode as published.**

| Air pressure (psi) | Fast | Slow |
|---|---|---|
| 50-55 | 24 | 20 |
| 55-60 | 22 | 18 |
| 60-65 | 20 | 16 |
| 65-70 | 18 | 14 |
| 70-75 | 16 | 12 |
| 75-80 | 14 | 10 |
| 80-85 | 12 | 8 |
| 90-95 | 10 | 6 |
| 100 | 8 | 4 |

The last row is printed "100" (not "100+").

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression` | 7 | from closed (strip "Open 14 … 1 Closed", 7 highlighted; text: start in the middle of the range) | `damper: diamond_core` |

Catalog: `compression` max 14, "Counted from fully closed" → **same direction.**

### SAG

15 %–30 %.

| Max travel | 15 % | 20 % | 30 % |
|---|---|---|---|
| 140mm | 21mm | 28mm | 42mm |
| 150mm | 22.5mm | 30mm | 45mm |
| 160mm | 24mm | 32mm | 48mm |
| 170mm | 25.5mm | 34mm | 51mm |

### Volume spacers

| Travel | Factory installed | Max |
|---|---|---|
| 140-170mm | 0 | 6 |

### Pressure limits

Max 100 psi. This matches the catalog.

---

## Guide `dvo_fork_2020` — DVO Fork Set-Up Guide 2020

### Source

- URL: https://tech.dvosuspension.com/wp-content/uploads/2020/09/DVO-Set-Up-Guide-2020-v4.pdf
- Document: Fork Set Up Guide 2020, v4, English. The back cover is stamped 910800-17 / 2017-07-18 (template).
- Section / page:
  - OTT p.4–5
  - air pressure and max pressure p.6–7
  - SAG p.8
  - rebound p.10
  - HSC p.12
  - LSC p.14 (text only)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dvo/sapphire-34/d1` | `damper: quick_range_d1e1` | air, OTT (D1/E1 chart), rebound, HSC |
| `fork/dvo/onyx-sc/d2` | `damper: quick_range_d2e2` | air (D1/D2 column), rebound; internal OTT display only |
| `fork/dvo/onyx-dc/d1` | `damper: quick_range_d1e1` | air, OTT (D1/E1 chart), rebound, HSC |
| `fork/dvo/diamond/d3` | `damper: diamond_d3e3` | air (D3 column), rebound (D3/E3) |
| `fork/dvo/diamond/e3` | `damper: diamond_d3e3` | air (E3 column), rebound (D3/E3) |

Gaps:
- **Diamond D1/D2/E1/E2** air, rebound and HSC charts are transcribed, but the catalog
  has no 2020-generation Diamond D1/D2 node (deliberately left out, see the YAML
  follow-ups). Not encoded.
- **Onyx SC E1/E2** air column: the catalog has only the Onyx SC D2. Not encoded.
- **Onyx SC D1 HSC** chart: the catalog's Onyx SC D2 has no HSC. Not encoded.
- **Sapphire 32**: not in this guide. See `dvo_fork_2018`.

### OTT — D1 / E1 (external)

Source direction: rotations from open (counter-clockwise). Catalog: `ott` numerical
turns, min 0 → **same direction.** Applies to `fork/dvo/sapphire-34/d1` and
`fork/dvo/onyx-dc/d1`, which carry `ott` in the catalog.

Input: rider weight (lb only) · Output: rotations `range`

| Rider weight (lb) | OTT rotations |
|---|---|
| 120-140 | 1-3 |
| 140-150 | 3-5 |
| 150-160 | 5-7 |
| 160-170 | 7-9 |
| 170-180 | 9-11 |
| 180-190 | 11-12 |
| 200+ | 12 |

There is no 190-200 row (as printed). The axis is 1–12.

### OTT — D2 / E2 (internal, 3 settings)

| Rider weight (lb) | OTT setting |
|---|---|
| 120-150 | Open Setting |
| 150-170 | Middle Setting |
| 170-200+ | Max Setting |

The catalog has no OTT adjuster on `fork/dvo/onyx-sc/d2`. The `onyx-sc/d2` YAML note
already says "OTT is set internally". Encode as `display_only` / `note`.

### Air pressure — Sapphire 34 D1 (`fork/dvo/sapphire-34/d1`)

Input: rider weight · Output: psi `range` (Plush → Firm)

| Rider weight (lb) | Rider weight (kg) | Plush | Firm |
|---|---|---|---|
| 120-139 | 54-63 | 55 | 75 |
| 140-159 | 64-72 | 75 | 85 |
| 160-179 | 73-81 | 85 | 95 |
| 180-199 | 82-90 | 95 | 105 |
| 200-219 | 91-100 | 105 | 115 |
| 220-239 | 101-108 | 115 | 125 |
| 240+ | 109+ | 125 | 135 |

The axis is printed **55, 65, 75, 80, 85, …, 135**, so the first band spans three
uneven columns (55/65/75). Transcribed as printed. The 2018 guide has the same chart.

### Air pressure — Onyx SC (D1/D2 and E1/E2 columns)

| Rider weight (lb) | Rider weight (kg) | D1/D2 Plush | D1/D2 Firm | E1/E2 Plush | E1/E2 Firm |
|---|---|---|---|---|---|
| 120-139 | 54-63 | 60 | 65 | 70 | 75 |
| 140-159 | 64-72 | 70 | 75 | 80 | 85 |
| 160-179 | 73-81 | 75 | 80 | 85 | 90 |
| 180-199 | 82-90 | 80 | 85 | 90 | 95 |
| 200-219 | 91-100 | 85 | 90 | 95 | 100 |
| 220-239 | 101-108 | 90 | 95 | 100 | 110 |
| 240+ | 109+ | 95 | 100 | 110 | 120 |

The axis is 60, 65, …, 100, 110, 120, 130 (10-psi steps above 100).

- Encode the D1/D2 column for `fork/dvo/onyx-sc/d2`.
- E1/E2 has no catalog option, so it is not encoded.
- The chart is titled "ONYX SC D1" but carries D1/D2 and E1/E2 legends.

### Air pressure — Onyx DC (`fork/dvo/onyx-dc/d1`)

| Rider weight (lb) | Rider weight (kg) | Plush | Firm |
|---|---|---|---|
| 120-139 | 54-63 | 65 | 70 |
| 140-159 | 64-72 | 70 | 75 |
| 160-179 | 73-81 | 75 | 80 |
| 180-199 | 82-90 | 80 | 85 |
| 200-219 | 91-100 | 85 | 90 |
| 220-239 | 101-108 | 90 | 95 |
| 240+ | 109+ | 95 | 100 |

The axis labels are 65, 70, …, 100 with an unlabelled column between each pair. The
band covers three cells.

### Air pressure — Diamond D3 / E3

| Rider weight (lb) | Rider weight (kg) | D3 Plush | D3 Firm | E3 Plush | E3 Firm |
|---|---|---|---|---|---|
| 120-139 | 54-63 | 70 | 75 | 80 | 85 |
| 140-159 | 64-72 | 75 | 80 | 85 | 90 |
| 160-179 | 73-81 | 80 | 85 | 90 | 95 |
| 180-199 | 82-90 | 85 | 90 | 95 | 100 |
| 200-219 | 91-100 | 90 | 95 | 100 | 105 |
| 220-239 | 101-108 | 95 | 100 | 105 | 110 |
| 240+ | 109+ | 100 | 105 | 110 | 120 |

The D3 column goes to `fork/dvo/diamond/d3` and the E3 column to `fork/dvo/diamond/e3`.
The path tells them apart (both use `damper: diamond_d3e3`). In the E3 240+ row, Firm
sits at 120 with an unlabelled shaded 115 cell between.

### Air pressure — Diamond D1/D2, E1/E2 (not in catalog; transcribed for completeness)

These are shaded cells without Plush/Firm labels.

| Rider weight (lb) | Rider weight (kg) | D1/D2 | E1/E2 |
|---|---|---|---|
| 120-139 | 54-63 | 85-95 | 100-110 |
| 140-159 | 64-72 | 100-110 | 115-125 |
| 160-179 | 73-81 | 115-125 | 130-135 |
| 180-199 | 82-90 | 120-130 | 135-140 |
| 200-219 | 91-100 | 125-135 | 140-145 |
| 220-239 | 101-108 | 130-140 | 145-150 |
| 240+ | 109+ | 135-145 | 150 |

### Rebound

Source direction: "Rebound Clicks – Starting From Closed". Every chart has the axis
2, 4, …, 22. Catalog: `rebound` max 22 (an estimate) from closed, on
`quick_range_d1e1`, `quick_range_d2e2` and `diamond_d3e3` → **same direction, encode as
published.** The input is air pressure (psi). The values are a band, Slower → Faster;
"Slower" is the lower click count.

**Sapphire 34 D1** (`fork/dvo/sapphire-34/d1`)

| Air pressure (psi) | Slower | Faster |
|---|---|---|
| 125-135+ | 2 | 6 |
| 115-125 | 6 | 10 |
| 105-115 | 10 | 14 |
| 95-105 | 14 | 18 |
| 85-95 | 18 | 22 |
| 55-85 | 18 | 22 |

**Onyx SC D1/E1 – D2/E2** (`fork/dvo/onyx-sc/d2`)

| Air pressure (psi) | Slower | Faster |
|---|---|---|
| 95+ | 2 | 6 |
| 85-90 | 6 | 10 |
| 80-85 | 10 | 14 |
| 75-80 | 14 | 18 |
| 70-75 | 18 | 22 |
| 60-70 | 18 | 22 |

There is no 90-95 row (as printed).

**Onyx DC** (`fork/dvo/onyx-dc/d1`)

| Air pressure (psi) | Slower | Faster |
|---|---|---|
| 100+ | 2 | 6 |
| 85-90 | 6 | 10 |
| 80-85 | 10 | 14 |
| 75-80 | 14 | 18 |
| 70-75 | 18 | 22 |
| 60-70 | 18 | 22 |

There is no 90-100 row (as printed).

**Diamond D3/E3** (`fork/dvo/diamond/d3`, `fork/dvo/diamond/e3`)

| Air pressure (psi) | Slow | Fast |
|---|---|---|
| 100-110+ | 4 | 8 |
| 90-100 | 6 | 10 |
| 85-90 | 8 | 12 |
| 80-85 | 10 | 14 |
| 75-80 | 12 | 16 |
| 70-75 | 14 | 18 |

**Diamond D1/E1 – D2/E2** (not in catalog): 140-150+: 2–6 · 130-140: 6–10 · 120-130: 10–14 · 110-120: 14–18 · 100-110: 18–22 · 80-100: 18–22.

### HSC

Source direction: "Rotations (not clicks) clockwise" from fully open (p.12 tip).
Catalog: `hsc` numerical turns, min 0, from open on `quick_range_d1e1` → **same
direction.** The input is air pressure (psi). The output is a 2-rotation band.

| Sapphire 34 D1 (psi) | rot. | Onyx DC D1 (psi) | rot. |
|---|---|---|---|
| 55-70 | 0-1 | 60-70 | 0-1 |
| 70-85 | 0-1 | 70-80 | 0-1 |
| 85-100 | 2-3 | 80-90 | 2-3 |
| 100-115 | 2-3 | 90-95 | 2-3 |
| 115-130 | 4-5 | 95-100 | 4-5 |
| 130+ | 4-5 | 100-110+ | 4-5 |

Two charts are not encoded because the catalog has no matching adjuster or trim:
- Onyx SC D1 (no catalog D1 trim): 60-65 0-1 · 65-70 0-1 · 75-80 2-3 · 85-90 2-3 · 90-100 4-5 · 100+ 4-5.
- Diamond D1: 80-95 0-1 · 95-110 0-1 · 110-125 2-3 · 125-140 2-3 · 140-155 4-5 · 155+ 4-5.

### Constants / base tune

LSC (p.14) is text only, not a weight table:
- D1/E1 "Quick Range": 1 is wide open for descending, 6 is the firmest pedalling platform.
- D2/E2: "SOFT" for descending, "FIRM" for climbing.
- D3/E3: start from full open.

These could become `note`s. With a `riding_style` id for climbing, they could become
`lsc: 6` / `compression: 4` rules. See Follow-ups.

### SAG

15 %–30 % (p.8). Less SAG (around 15 %) suits pedalling; around 30 % suits comfort.
The table is printed per travel:

| Fork travel | 15 % (Firm) | 20 % (Plush) | 30 % (Super Plush) |
|---|---|---|---|
| 100 mm (3.9 in) | 15 mm (0.6 in) | 20 mm (0.8 in) | 30 mm (1.2 in) |
| 110 mm (4.3 in) | 17 mm (0.7 in) | 22 mm (0.9 in) | 33 mm (1.3 in) |
| 120 mm (4.7 in) | 18 mm (0.8 in) | 24 mm (0.9 in) | 36 mm (1.4 in) |
| 130 mm (5.1 in) | 20 mm (0.8 in) | 26 mm (1.0 in) | 39 mm (1.5 in) |
| 140 mm (5.5 in) | 21 mm (0.8 in) | 28 mm (1.1 in) | 42 mm (1.6 in) |
| 150 mm (5.9 in) | 23 mm (0.9 in) | 30 mm (1.2 in) | 45 mm (1.8 in) |
| 160 mm (6.3 in) | 24 mm (0.9 in) | 32 mm (1.3 in) | 48 mm (1.9 in) |
| 170 mm (6.7 in) | 26 mm (1.0 in) | 34 mm (1.3 in) | 51 mm (2.0 in) |
| 180 mm (7.1 in) | 27 mm (1.1 in) | 36 mm (1.4 in) | 54 mm (2.1 in) |
| 203 mm (8.0 in) | 30 mm (1.2 in) | 41 mm (1.6 in) | 61 mm (2.4 in) |

The pre-ride check on p.2 says "15-20%", which contradicts p.8. Use the p.8 band.

### Pressure limits

| Variant | Guide max | Catalog `max` |
|---|---|---|
| Diamond D1-D2-E1-E2 | 170 psi | (no node) |
| Diamond D3-E3 | 150 psi | 150 ✓ |
| Sapphire 34 D1 | 150 psi | 150 ✓ |
| Onyx SC D1-D2-E1-E2 | 130 psi | 130 ✓ |
| Onyx DC | 140 psi | 140 ✓ |

Inflation tip: go 10 psi over the target, then bleed down (note).

### Does not fit B3

- Rebound and HSC are keyed on pressure (second-order).
- The E1/E2 columns have no catalog option.
- The D2/E2 OTT is internal and has no adjuster.
- The axes are irregular (Sapphire 55/65/75; Onyx DC unlabelled half columns). The
  bands are recorded by their labelled ends.

---

## Guide `dvo_fork_2018` — DVO Fork Set-Up Guide (2018)

### Source

- URL: https://tech.dvosuspension.com/wp-content/uploads/2018/08/DVO-SET-UP-GUIDE_fork.pdf. It is linked from tech.dvosuspension.com/setup/sapphire-series/ and /onyx-dc-set-up/.
- Document: Fork Set-Up Guide, 2018 (upload 2018/08), English
- Section / page: air pressure p.6–7 (PDF page 4)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dvo/sapphire-32/d1` | `damper: quick_range_d1e1` | air only |

Gaps:
- This guide's rebound (1–20 clicks), HSC (1–29 **clicks**) and OTT (1–11) charts are
  generic and do not name a fork. Their HSC is in clicks, which contradicts the
  catalog's turn-based `quick_range_d1e1` (2019+). They predate the catalog damper, so
  they are **not used**.
- Its Sapphire 34 air chart is identical to the 2020 one.

### Air pressure — Sapphire 32mm stanchion

| Rider weight (lb) | Rider weight (kg) | Plush | Firm |
|---|---|---|---|
| 120-139 | 54-63 | 85 | 95 |
| 140-159 | 64-72 | 95 | 105 |
| 160-179 | 73-81 | 105 | 115 |
| 180-199 | 82-90 | 115 | 125 |
| 200-219 | 91-100 | 125 | 135 |
| 220-239 | 101-108 | 135 | 145 |
| 240+ | 109+ | 145 | 155 |

### SAG

The 2018 guide says 15 %–20 %. The 2020 guide (15–30 %) supersedes it.

### Pressure limits

Sapphire 32mm: 170 psi; Sapphire 34mm: 150 psi (p.6 banner). The catalog Sapphire 32
`pressure` has **no max**. Follow-up: consider `max: 170`.

---

## Guide `dvo_emerald_tech` — tech.dvosuspension.com Emerald set-up page

### Source

- URL: https://tech.dvosuspension.com/setup/emerald/
- Document: DVO Tech website, Emerald "Set Up" page (OTT Guide and Base Tune tabs), English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dvo/emerald-inverted/standard` | `damper: emerald_damper` | pressure, OTT, rebound, HSC, LSC |

### Base tune

Convention: start every adjuster at wide open (counter-clockwise until it stops). Every
value is counted **clockwise from wide open**.

Catalog:
- `hsc` (max 33), `lsc` (max 27) and `rebound` (max 40) are all "counted clockwise …
  from wide open".
- `ott` (step, max 15, turns) is counted from open.

→ **Same direction for all, encode as published.**

Input: rider weight (lb, kg)

| Rider weight (lb) | Rider weight (kg) | psi | OTT (rotations) | Rebound (clicks) | HSC (clicks) | LSC (clicks) |
|---|---|---|---|---|---|---|
| 120-139 | 54-63 | 60-65 | 0-2 | 3-7 | 0-1 | 0-1 |
| 140-159 | 64-72 | 65-70 | 3-4 | 5-8 | 0-2 | 0-2 |
| 160-179 | 73-81 | 70-75 | 5-6 | 6-10 | 2-3 | 2-3 |
| 180-199 | 82-90 | 75-80 | 6-7 | 7-11 | 2-4 | 2-4 |
| 200-219 | 91-100 | 85-90 | 8-10 | 8-12 | 3-5 | 3-5 |
| 220+ | 100+ | 95-100 | 11-14 | 10-14 | 5-7 | 5-7 |

The 200-219 → 220+ kg bounds overlap at 100 (as printed). The OTT Guide tab repeats
the psi and OTT columns identically.

### SAG

The page says to measure SAG standing in the ready position (DH fork). It gives no
percentage. The setup page's air section refers to the base tune.

### Pressure limits

"Air Pressure Range: 60-100psi". This matches the catalog `pressure` min 60 / max 100.

---

## Guide `dvo_jade_tech` — tech.dvosuspension.com Jade set-up page

### Source

- URL: https://tech.dvosuspension.com/setup/jade/
- Document: DVO Tech website, Jade "Set Up" page (Preload/SAG, Air Pressure, Base Tune tabs), English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dvo/jade/standard` | `damper: jade_coil`, `size: 200.025x57.15` or `215.9x63.5` | base tune table 1 |
| `shock/dvo/jade/standard` | `damper: jade_coil`, `size: 222.25x69.85` | base tune table 2 |
| `shock/dvo/jade/standard` | any size | bladder chart, SAG |

Gaps:
- Table 2 also covers 241×76 (9.5×3in), which is not a catalog size.
- Table 3 covers 267×89 (10.5×3.5in), which is not a catalog size.
- The catalog's metric and trunnion sizes (210x50 … 225x75, 250x70, 230x57.5 …) have
  **no base tune**. For them, only the bladder chart and SAG apply.

### Bladder pressure (Air Pressure tab)

Input: rider weight · Output: `bladder_pressure` psi (single value)

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 120-139 | 54-63 | 170 |
| 140-159 | 64-72 | 175 |
| 160-179 | 73-81 | 180 |
| 180-199 | 82-90 | 185 |
| 200-219 | 91-100 | 190 |
| 220+ | 100+ | 200 |

### Base tune — per shock size

Directions:
- Rebound: start fully clockwise (closed) and count CCW. Catalog `rebound` max 37,
  "Counted from fully closed" → **same direction.**
- HSC and LSC: start fully counter-clockwise (open) and count CW. Catalog `hsc` max 24
  and `lsc` max 22, "Counted from fully open" → **same direction.**

The PSI column is the bladder charge (`bladder_pressure`). Spring rate is lbs (lb/in),
target `spring_rate`.

**Table 1 — "200×57/7.875×2.25 & 215×63/8.5×2.5"**

| Rider weight | PSI | Rebound (CCW) | HSC (CW) | LSC (CW) | Spring rate |
|---|---|---|---|---|---|
| 120-140lbs/55-64kg | 170-175 | 34-32 | 3 | 1 | 400lbs |
| 140-160lbs/64-73kg | 175-180 | 33-31 | 4 | 2 | 450lbs |
| 160-180lbs/73-82kg | 180-185 | 32-29 | 4-6 | 3-5 | 500lbs |
| 180-200lbs/82-91kg | 185-190 | 31-28 | 6-9 | 5-8 | 550lbs |
| 200-220lbs/91-100kb [sic] | 190-200 | 29-26 | 6-9 | 5-8 | 600lbs |

**Table 2 — "221×68/8.75×2.75 & 241×76/9.5×3"**

| Rider weight | PSI | Rebound (CCW) | HSC (CW) | LSC (CW) | Spring rate |
|---|---|---|---|---|---|
| 120-140lbs/55-64kg | 170-175 | 34-32 | 2 | 1 | 350lbs |
| 140-160lbs/64-73kg | 175-180 | 33-31 | 3 | 2 | 400lbs |
| 160-180lbs/73-82kg | 180-185 | 32-29 | 3-5 | 2-5 | 450lbs |
| 180-200lbs/82-91kg | 185-190 | 31-28 | 5-8 | 5-8 | 500lbs |
| 200-220lbs/91-100kg | 190-200 | 29-26 | 5-8 | 5-8 | 550lbs |

In the 140-160 row, the HSC cell's HTML is "3&nbsp; CW". It may be a truncated "3½"
(follow-up).

**Table 3 — "267X89/10.5X3.5"** (not in catalog)

| Rider weight | PSI | Rebound (CCW) | HSC (CW) | LSC (CW) | Spring rate |
|---|---|---|---|---|---|
| 120-140lbs/55-64kg | 170-175 | 34-32 | 4 | 1 | NA |
| 140-160lbs/64-73kg | 175-180 | 33-31 | 5 | 2 | NA |
| 160-180lbs/73-82kg | 180-185 | 32-29 | 5-7 | 2-5 | 275lbs |
| 180-200lbs/82-91kg | 190-195 | 31-28 | 6-9 | 5-8 | 300lbs |
| 200-220lbs/91-100kg | 195-200 | 29-26 | 6-9 | 5-8 | 350lbs |

The rebound ranges are printed high → low ("34-32"). Encode them as `range` 32–34.

The base-tune PSI bands differ from the bladder-chart singles (170-175 vs. 170). Encode
the bladder chart as the size-independent rule and the base-tune band per size, or pick
one. That is an editor's decision.

### SAG

25–30 %, measured in the attack position. A per-size mm table is printed:

| Shock | 25 % | 30 % |
|---|---|---|
| 10.5 x 3.5″ (267 x 90mm) | .875″ (22mm) | 1.05″ (27mm) |
| 9.5 x 3.0″ (240 x 76mm) | .784″ (20mm) | .901″ (23mm) |
| 8.75 x 2.75″ (222 x 70mm) | .688″ (17mm) | .827″ (21mm) |
| 8.5 x 2.5″ (216 x 64mm) | .625″ (16mm) | .748″ (19mm) |
| 7.878 x 2.25″ (200 x 57mm) | .562″ (14mm) | .673″ (17mm) |

### Pressure limits

Bladder 170–200 psi, which matches the catalog `bladder_pressure` 170/200. Preload max
is 5 mm, which matches the catalog `preload` max 5.

### Does not fit B3

The base tune is keyed on **shock size × rider weight**. Most catalog sizes have no
table. The spring-rate target is a coil chart, which B3 can express as a weight → value
rule under `when: { size: … }`.

---

## Guide `dvo_jadex_2024` — Jade X Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2024/05/DVO-Jade-X-Setup-Guide-May16.pdf (catalog `setup_guide`)
- Document: Jade X Set-Up Guide, Version 2.0 (May 2024), English. The Nov 2023 copy (Jade-X-Setup-Guide-Nov20.pdf) has the same data; only an adjuster-page label differs.
- Section / page: bladder p.8, SAG p.9, preload p.10, Prime compression p.11, T3 chart p.12, rebound p.13
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dvo/jade-x/t3` | `damper: jade_x_t3` | bladder, SAG, T3 trail-style chart |
| `shock/dvo/jade-x/prime` | `damper: jade_x_prime` | bladder, SAG |

### Bladder pressure (gradient chart)

Input: rider weight (lb, kg) · Output: `bladder_pressure` psi. The axis is
140/150/160/170/180.

The rows are **gradient bars**, not cell-aligned. Values below are the approximate
positions of the PLUSH and FIRM labels on the axis.

| Rider weight (lb) | Rider weight (kg) | ≈ Plush | ≈ Firm |
|---|---|---|---|
| 120-139 | 54-63 | 140 | 150 |
| 140-159 | 64-72 | 145 | 155 |
| 160-179 | 73-81 | 150 | 160 |
| 180-199 | 82-90 | 155 | 165 |
| 200-219 | 91-100 | 160 | 170 |
| 220-239 | 101-108 | 165 | 175 |
| 240+ | 109+ | 170 | 180 |

This chart is the same one printed in the Topaz and WP1 guides. The intermediate values
are read off a gradient, so mark them approximate or encode them as `display_only`.

### T3 compression — trail style (`jade_x_t3`)

Target `compression_mode`; catalog options [Open, Mid, Firm] match the guide's
OPEN/MID/FIRM.

| Trail style | Open | Mid | Firm |
|---|---|---|---|
| Rough Descent | ✓ (Plush) | | |
| Smooth Descent | | ✓ (Supportive) | |
| Technical Climb | | ✓ | ✓ |
| Smooth Climb | | | ✓ |
| Sandy Descent | ✓ | ✓ | |
| Sandy Climb | | ✓ | ✓ |
| Mud Descent | ✓ | ✓ | |
| Mud Climb | | ✓ | ✓ |

### Rebound

There is no chart. The scale strip reads "Open 18+ 16 … 2 0 Closed". The tip says to
start fully closed and adjust out in 2-click steps. No values.

### Prime HSC / LSC

Scale strips only (HSC 1–10, LSC 1–5 from open). No recommendation.

### SAG

25 %–30 %.

| Stroke | 25 % | 30 % |
|---|---|---|
| 50mm | 12.5 | 15 |
| 52.5mm | 13.125 | 15.75 |
| 55mm | 13.75 | 16.5 |
| 57.5mm | 14.375 | 17.25 |
| 60mm | 15 | 18 |
| 62.5mm | 15.6 | 18.75 |
| 65mm | 16.25 | 19.5 |
| 2.5 inch | 15.8 | 19 |
| 2.25 inch | 14.25 | 17 |

### Pressure limits

Bladder 140–180 psi (do not exceed 180), which matches the catalog. Preload max 6 mm
(1 turn = 1 mm), which matches the catalog `preload` max 6.

### Does not fit B3

- The bladder chart is a gradient.
- The trail-style rows ("Sandy Climb", "Mud Descent", …) need riding-style ids the app
  may not have. Several rows give two acceptable positions.
- There is no spring-rate chart for the standard Jade X.

The older Jade X guide (tech site, 2019: https://tech.dvosuspension.com/wp-content/uploads/2019/09/Jade-X-Set-Up-Guide-2.pdf) gives a 170–200 psi bladder range. The same SAG table and the same T3 chart (with the label "DH" for Descent) are printed. The 2024 guide supersedes it; the catalog uses 140–180.

---

## Guide `dvo_jadexwp_2023` — Jade X WP1 Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2024/02/DVO-Jade-X-WP-Setup_Guide_Dec5_2023.pdf
- Document: Jade X WP1 Set-Up Guide (Dec 5, 2023), English
- Section / page: bladder p.8, SAG p.9, spring chart p.10, compression p.11, rebound p.12
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dvo/jade-x/wp-cv` | `size: 205x65` | spring rate, bladder, SAG |

Gaps: the catalog node declares `missing_adjustments: [Rebound, Compression]`, so the
HSC/LSC starting points below are display-only.

### Coil spring rate — "Spring Force Base Setting Chart"

Input: rider weight · Output: `spring_rate` (lb/in; kg/cm also printed)

| Rider weight (lb) | Rider weight (kg) | lbs/inch | kg/cm |
|---|---|---|---|
| 119-132 | 54-60 | 300 | 54 |
| 132-154 | 60-70 | 350 | 63 |
| 154-176 | 70-80 | 400 | 72 |
| 176-220 | 80-100 | 450 | 80 |
| 220+ | 100+ | 500 | 88 |

### Bladder pressure

The gradient chart is identical to `dvo_jadex_2024`.

### Constants / base tune (display only)

| Target | Value | Direction | `when:` |
|---|---|---|---|
| HSC | 4 ("Starting Point") | from closed; strip "Open 6 5 4 3 2 1 0 Closed", counted from fully clockwise | — |
| LSC | 6 ("Starting Point") | from closed; strip "Open 18 15 12 9 6 3 0 Closed" | — |

The catalog has no adjuster on this node, so encode these as a `note` / `display_only`.
The rebound strip "Open 18+ … 0 Closed" has no recommendation.

### SAG

25 %–30 %. Stroke 60mm: 15 / 18; 65mm: 16.25 / 19.5.

### Pressure limits

Bladder 140–180 psi, which matches the catalog. Preload max 6 mm.

---

## Guide `dvo_topaz_2024` — Topaz Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2024/05/DVO-Topaz-Setup-Guide-May9.pdf (catalog `setup_guide`)
- Document: Topaz Set-Up Guide, Version 2.1 (May 2024), English
- Section / page: bladder p.8, SAG p.9, air p.10, Prime compression p.11, T3 chart p.12, rebound p.13, spacers p.14
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dvo/topaz/pro` | `damper: topaz_pro` | air, bladder, rebound, T3 chart, SAG |
| `shock/dvo/topaz/prime` | `damper: topaz_prime` | air, bladder, rebound, SAG |

### Air pressure

Input: rider weight · Output: `pressure` psi `range` (Plush → Firm). The axis is 140,
145, 150, 160, 165, 170, 175, 180, 190, 200, 210, 220, 230, 240, 250+.

| Rider weight (lb) | Rider weight (kg) | Plush | Firm |
|---|---|---|---|
| 120-139 | 54-63 | 140 | 150 |
| 140-159 | 64-72 | 150 | 165 |
| 160-179 | 73-81 | 165 | 175 |
| 180-199 | 82-90 | 180 | 200 |
| 200-219 | 91-100 | 190 | 210 |
| 220-239 | 101-108 | 210 | 230 |
| 240+ | 109+ | 230 | 250+ |

The 180-199 and 200-219 bands overlap (180–200 / 190–210), as printed. The tip says
the leverage ratio changes the pressure a lot.

### Bladder pressure

The gradient chart is identical to `dvo_jadex_2024` (≈140–150 … ≈170–180).

### Rebound — "for all Topaz models"

Source direction: "Rebound Clicks from Closed (Fully Clockwise)". The axis is 1–9.
Catalog: `rebound` max 9, from closed (`topaz_pro`, `topaz_prime`) → **same direction.**

Input: the header says **"Air Pressure / PSI"** (see Does not fit B3)

| Row (as printed) | Clicks |
|---|---|
| 120-139 | 8-9 |
| 140-159 | 6-7 |
| 160-179 | 5-6 |
| 180-199 | 4-5 |
| 200-219 | 3-4 |
| 220-239 | 2-3 |
| 240+ | 1-2 |

Tip: start closed and adjust out in two-click steps.

### T3 compression — trail style (`topaz_pro`)

Target `compression_mode`, options [Open, Mid, Firm]. The table is identical to the
Jade X T3 table: Rough Descent Open · Smooth Descent Mid · Technical Climb Mid/Firm ·
Smooth Climb Firm · Sandy Descent Open/Mid · Sandy Climb Mid/Firm · Mud Descent
Open/Mid · Mud Climb Mid/Firm.

### Prime HSC / LSC

Strips only (HSC 1–10, LSC 1–5 from open). No values.

### SAG

20 %–30 %.

| Stroke (mm) | 20 % (Supportive) | 30 % (Plush) |
|---|---|---|
| 40 | 8mm | 12mm |
| 42.5 | 8.5mm | 12.75mm |
| 45 | 9mm | 13.5mm |
| 50 | 10mm | 15mm |
| 52.5 | 10.5mm | 15.75mm |
| 55 | 11mm | 16.5mm |
| 57.5 | 11.5mm | 17.25mm |
| 60 | 12mm | 18mm |
| 62.5 | 12.5mm | 18.75mm |
| 65 | 13mm | 19.5mm |

### Volume spacers

A symptom → solution table ("add 1-2 positive/negative spacers"). There is no factory
count and no max. Nothing to encode, and the catalog has no spacer adjuster.

### Pressure limits

Air max 300 psi and bladder 140–180 psi. Both match the catalog.

### Does not fit B3

- **Rebound input ambiguity:** the column header says "Air Pressure PSI", but the rows
  are the same brackets as the rider-weight column of the air chart. Read as psi, they
  would cover only 120–240+ psi, while the air chart recommends 140–250 psi. Ask DVO,
  or encode as `display_only`.
- The air bands overlap.
- The bladder chart is a gradient.

---

## Guide `dvo_topazwp_2023` — Topaz WP1 Set-Up Guide

### Source

- URL: https://dvosuspension.com/wp-content/uploads/2024/02/DVO-Topaz-WP-Setup_Guide_Dec5_2023.pdf
- Document: Topaz WP1 Set-Up Guide (Dec 5, 2023), English
- Section / page: bladder p.8, SAG p.9, air p.10, compression p.11, rebound p.12
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dvo/topaz/wp-cv` | `size: 205x60` | air, bladder, SAG |

Gaps: `missing_adjustments: [Rebound, Compression]` in the catalog, so the HSC, LSC and
rebound values are display-only.

### Air pressure (differs from the Topaz v2.1 chart)

| Rider weight (lb) | Rider weight (kg) | Plush | Firm |
|---|---|---|---|
| 120-139 | 54-63 | 145 | 160 |
| 140-159 | 64-72 | 160 | 170 |
| 160-179 | 73-81 | 170 | 180 |
| 180-199 | 82-90 | 190 | 210 |
| 200-219 | 91-100 | 200 | 220 |
| 220-239 | 101-108 | 220 | 240 |
| 240+ | 109+ | 240 | 250+ (no Firm label; 240 and 250+ shaded) |

The axis is the same as Topaz v2.1.

### Bladder pressure

The gradient chart is identical to `dvo_jadex_2024`. Its axis title reads "Bladder
Pressure (psi)".

### Constants (display only)

- HSC starting point 4 and LSC starting point 6, both counted from closed. Strips:
  HSC "Open 6 … 0 Closed", LSC "Open 18 15 12 9 6 3 0 Closed".
- The rebound chart is the same as the Topaz "for all Topaz models" chart (8-9 … 1-2).

### SAG

20 %–30 %. Stroke 60: 12mm / 18mm; 65: 13mm / 19.5mm.

### Pressure limits

Air 300 psi and bladder 140–180. Both match the catalog.

---

## Guide `dvo_topaz_2020` — Topaz Air Set Up Guide 2020

### Source

- URL: https://tech.dvosuspension.com/wp-content/uploads/2020/10/DVO-Set-Up-Guide-shock-2020.pdf
- Document: Topaz Air Set Up Guide 2020 ("Topaz Owner's Guide" footer), English
- Section / page: air p.6, SAG p.7, bladder p.8, rebound p.9, T3 p.10, spacers p.11
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dvo/topaz-2/t3air` | `damper: topaz_t3air` | air, bladder, rebound, T3, SAG |
| `shock/dvo/topaz-2/maestro-hv` | `damper: topaz_t3air` | same |

### Air pressure

| Rider weight (lb) | Rider weight (kg) | Plush | Firm |
|---|---|---|---|
| 120-139 | 54-63 | 140 | 150 |
| 140-159 | 64-72 | 150 | 165 |
| 160-179 | 73-81 | 165 | 175 |
| 180-199 | 82-90 | 175 | 190 |
| 200-219 | 91-100 | 190 | 210 |
| 220-239 | 101-108 | 210 | 230 |
| 240+ | 109+ | 230 | 250+ |

The axis is the same as Topaz v2.1. The 180-199 row differs from v2.1 (175–190 vs.
180–200).

### Bladder pressure (cell chart)

Axis 170/180/190/200. Single values:

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 120-139 | 54-63 | 170 |
| 140-159 | 64-72 | 170 |
| 160-179 | 73-81 | 180 |
| 180-199 | 82-90 | 180 |
| 200-219 | 91-100 | 190 |
| 220-239 | 101-108 | 190 |
| 240+ | 109+ | 200 |

### Rebound

"Rebound Clicks out from Closed (fully clockwise)", axis 1–9. Catalog `topaz_t3air`
`rebound` max 9, from closed → **same direction.** The rows are labelled "Air Pressure
PSI": 120-139: 8-9 · 140-159: 6-7 · 160-179: 5-6 · 180-199: 4-5 · 200-219: 3-4 ·
220-239: 2-3 · 240+: 1-2. The same input ambiguity applies as in `dvo_topaz_2024`.

### T3 compression — trail style

The guide's columns are OPEN / MID / FIRM. The **catalog `compression_mode` options are
[Open, Medium, Closed]**, taken from the tech page. Map MID → Medium and FIRM → Closed.

| Trail style | Open | Mid | Firm |
|---|---|---|---|
| Rough DH | ✓ (Plush) | | |
| Smooth DH | | ✓ (Supportive) | |
| Technical Climb | | ✓ | ✓ |
| Smooth Climb | | | ✓ |
| Sandy DH | ✓ | ✓ | |
| Sandy Climb | | ✓ | ✓ |
| Muddy DH | ✓ | ✓ | |
| Muddy Climb | | ✓ | ✓ |

### SAG

20 %–30 %. The stroke table's 30 % column is rounded differently from 2024:

| Stroke | 20 % | 30 % |
|---|---|---|
| 40 | 8mm | 12mm |
| 42.5 | 8.5mm | 13mm |
| 45 | 9mm | 14mm |
| 50 | 10mm | 15mm |
| 52.5 | 10.5mm | 16mm |
| 55 | 11mm | 17mm |
| 57.5 | 11.5mm | 18mm |
| 60 | 12mm | 19mm |
| 62.5 | 12.5mm | 20mm |
| 65 | 13mm | 21mm |

The tech page (tech.dvosuspension.com/setup/topaz-2) says 25–30 % in its pre-ride
check. The guide's SAG section (20–30 %) is used.

### Pressure limits

Air 300 psi and bladder max 200 psi. Both match the catalog (170–200).

---

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `shock/dvo/opal/hv-t3` | No set-up guide PDF and no tech page (/setup/opal/ is a 404 per the catalog note). The product page has no settings. `draft: true`. |

Partial only (see the coverage rows): `fork/dvo/sapphire-32/d1` has an air chart from
the 2018 guide. Its rebound, HSC and OTT charts in that guide predate the catalog damper
(HSC in clicks), so they are not used.

## Follow-ups

- **Topaz rebound charts (2020, 2023, 2024):** the input header says "Air Pressure PSI"
  but the rows look like rider-weight brackets. Confirm with DVO before encoding; until
  then use `display_only`.
- **Bladder gradient chart** (Jade X, Topaz, WP1): the intermediate values are read off
  a gradient. Ask DVO for exact numbers, or encode the ends only (120-139 ≈ 140–150,
  240+ ≈ 170–180) as `display_only`.
- **Onyx 38 volume spacers:** the guide says spacers are for SL forks only, but the
  catalog gives `volume_spacers` to D1, D2 and D3. Catalog editors should check.
- **Sapphire 32 max pressure:** the 2018 guide says 170 psi; the catalog has none.
- **Jade table 2:** the 140-160 HSC cell reads "3&nbsp;", possibly a truncated "3½".
- **Riding-style ids:**
  - T3 "trail style" rows (Rough/Smooth/Sandy/Mud × Descent/Climb);
  - 2020 LSC guidance (climb → firmest Quick Range setting).
  Both need riding-style ids, or they stay notes.
- **The 2018 generic fork rebound/HSC/OTT charts** (unnamed fork, HSC 1–29 clicks):
  they probably belong to the pre-2019 Diamond/Sapphire damper, which is not in the
  catalog. Not used.
