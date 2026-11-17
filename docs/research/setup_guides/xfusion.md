# X-Fusion — setup guide research

Catalog files: `data/component_presets/fork/xfusion.yaml`, `data/component_presets/shock/xfusion.yaml`
Researched: 2026-11-17

Catalog ids use the brand slug `x-fusion` (`fork/x-fusion/...`). This file is
named after the YAML filename (`xfusion`).

## Summary

- **Forks:** X-Fusion publishes one set-up guide PDF per stanchion diameter
  (32, 34, 36, 38 mm, 2025 edition, linked from
  https://www.xfusionshox.com/help_detail/15.htm) and a one-page "Fork Pressure
  and Spring Rate Chart". Each guide gives:
  1. a **SAG** recommendation of 25-30 % (all four guides);
  2. a **rebound** starting rule: turn the red knob fully clockwise (slowest),
     then open N clicks, "approximately" M clicks of total range;
  3. the **approximate click counts** of the compression knobs, where the
     fork has them;
  4. a printed **rider weight (lb / kg) → air pressure (psi / bar)** table;
  5. a service interval of 80 hours of ride time or annually.
- The guides head their pressure table "Spring / Coil" but the chart PDF prints
  the same 32/34 and 36 mm values under "Air Pressure", so they are air
  pressures.
- The chart has four columns: 32/34mm (RC/RL), 34mm RoughCut, 36mm and an "RV-1
  (Coil Spring)" column (spring color by rider weight). The 38mm table is only
  in the 38mm guide.
- No guide names a volume-spacer count or a damper-click table keyed on
  weight; compression has no base setting.
- Gaps for B3: the Rezza (Finecut dampers) is not named in the chart; the
  G.E.T. 30 and the Roamin youth forks have no guide; the RV-1 coil column has
  no catalog spring adjuster.

## Guide `xfusion_forks_2025` — Fork pressure chart and set-up guides (2025)

### Source

- Chart: https://www.xfusionshox.com/upload/files/Air%20%26%20Coil%20Spring%20Rate-v2.pdf
  (one A4 page, image only)
- Set-up guides (7 pages each, English, "2025" in the file name):
  - https://www.xfusionshox.com/upload/files/32mm%20Fork%20Set%20Up%20Guide%202025.pdf
  - https://www.xfusionshox.com/upload/files/34mm%20Fork%20Set%20Up%20Guide%202025.pdf
  - https://www.xfusionshox.com/upload/files/36mm%20Fork%20Set%20Up%20Guide%202025.pdf
  - https://www.xfusionshox.com/upload/files/38mm%20Fork%20Set%20Up%20Guide%202025.pdf
- Section / page: "Setting Sag" p. 1, "Rebound Damping" pp. 2-3, "Compression
  Damping" pp. 3-5, "Service" p. 5, pressure chart p. 6 (32mm p. 4).
- Retrieved: 2026-11-17

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/x-fusion/velvet/rl`, `fork/x-fusion/rc32/*` | `model: [velvet, rc32]` | 32mm guide, chart column "32/34mm (RC/RL)". RC32 is draft |
| `fork/x-fusion/{sweep-boost,slide-boost,slant}/rc` | `model: [...], trim: rc` | chart column "32/34mm (RC/RL)" |
| `fork/x-fusion/{sweep-boost,slide-boost,slant}/{hlr,rcp}` | `model: [...], trim: [hlr, rcp]` | 34mm guide table = chart column "34mm Stanchion (RoughCut)". RCP is draft |
| `fork/x-fusion/trace-36/*` | `model: trace-36` | 36mm guide, chart column "36mm Stanchion" |
| `fork/x-fusion/vengeance-38/hlr`, `fork/x-fusion/rv1-38-dh/hlr` | `model: [vengeance-38, rv1-38-dh]` | 38mm guide only |
| `fork/x-fusion/rezza/*` | none for pressure | SAG and rebound base setting only, from the 34mm guide |

Gaps: the chart's 34mm RoughCut column and the 34mm guide's table are the same.
The chart has no 38mm column. Rezza (Finecut RL2 / RCP) is on the 34mm guide's
"all 34mm forks" rebound text but no pressure column names it.

### Air pressure — 32/34mm (RC/RL)

Input: rider weight (lb, kg also printed) · Output: psi (bar also printed) ·
`when: { model: [velvet, rc32] }` and `{ model: [sweep-boost, slide-boost, slant], trim: rc }`

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 100 | 45 | 55 |
| 110 | 50 | 57.5 |
| 120 | 54 | 60 |
| 130 | 59 | 65 |
| 140 | 63 | 70 |
| 150 | 68 | 75 |
| 160 | 73 | 80 |
| 170 | 77 | 85 |
| 180 | 82 | 90 |
| 190 | 86 | 95 |
| 200 | 90 | 100 |
| 220+ | 100+ | 110 |

### Air pressure — 34mm RoughCut

`when: { model: [sweep-boost, slide-boost, slant], trim: [hlr, rcp] }`

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 100 | 45 | 47.5 |
| 110 | 50 | 50 |
| 120 | 54 | 55 |
| 130 | 59 | 60 |
| 140 | 63 | 65 |
| 150 | 68 | 70 |
| 160 | 73 | 75 |
| 170 | 77 | 80 |
| 180 | 82 | 85 |
| 190 | 86 | 90 |
| 200 | 90 | 95 |
| 220+ | 100+ | 110 |

### Air pressure — 36mm

`when: { model: trace-36 }`

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 100 | 45 | 45 |
| 110 | 50 | 47.5 |
| 120 | 54 | 50 |
| 130 | 59 | 52.5 |
| 140 | 63 | 55 |
| 150 | 68 | 57.5 |
| 160 | 73 | 60 |
| 170 | 77 | 65 |
| 180 | 82 | 70 |
| 190 | 86 | 75 |
| 200 | 90 | 80 |
| 220+ | 100+ | 85 |

### Air pressure — 38mm

`when: { model: [vengeance-38, rv1-38-dh] }`

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 100 | 45 | 55 |
| 110 | 50 | 60 |
| 120 | 54 | 65 |
| 130 | 59 | 70 |
| 140 | 63 | 75 |
| 150 | 68 | 80 |
| 160 | 73 | 85 |
| 170 | 77 | 90 |
| 180 | 82 | 95 |
| 190 | 86 | 100 |
| 200 | 90 | 105 |
| 220+ | 100+ | 110 |

The `220+` row is encoded as the point 220: all rows are points, so a heavier
rider is outside the table (no extrapolation).

### Rebound

Source direction: knob fully clockwise (slowest) = closed, then counter-clockwise.
Catalog: `rebound`, default `dial_ccw`, counted from fully closed → same
direction, encode as published.

| Fork group | Base setting (clicks from closed) | Approx. total clicks |
|---|---|---|
| 32mm, 34mm, 36mm | 8 | 16 |
| 38mm (Finecut HLR) | 12 | 25 |

Encoded as `{ target: rebound, value: 8 }` for velvet, rc32, rezza, sweep-boost,
slide-boost, slant, trace-36 and `value: 12` for vengeance-38, rv1-38-dh.
Adjust in steps of 2 clicks (all four guides).

### Compression click counts (catalog adjusters, not guide rules)

| Guide | LSC (blue knob) | HSC (gold knob) | Notes |
|---|---|---|---|
| 34mm, 36mm | about 13 | about 15 (HLR only) | "RC" knob: low-speed compression only |
| 38mm (Finecut HLR) | about 14 | about 7 | |
| 32mm | not given | — | only the RL2 knob (open / lockout) is described |

Clockwise (in) increases compression damping, so the counts run from closed
and need no range reference.

### SAG

25-30 % for all four guides ("personal preference and riding conditions also
play a role"). Encoded as `range: [25, 30], comfort_at: max`.

### Volume spacers

None published.

### Pressure limits

Owner's manual (English, https://www.xfusionshox.com/upload/files/Owner's%20Manual-English(1).pdf,
"Installing a XFUSION Fork"):

- Max: 140 psi for Velvet, Migo, RC32, Bruno 30, Slant, Sweep Boost, Slide
  Boost, E-Slide Boost, Mcqueen Boost, Vengeance 38 and Rezza 29 Boost; 120 psi
  for Trace36, Metric and RV1 38. The catalog `max` follows this.
- Min: 50 psi for every fork listed. The 36mm table starts at 45 psi (100 lb),
  below that minimum, so the catalog keeps `min: 0`.
- G.E.T. 30 and Roamin appear in no pressure list (`max` unset).

### Formulas

None.

### Does not fit B3

- Chart column "RV-1 (Coil Spring)": spring color by rider weight (Soft (Red)
  100-110 lb, Stock (Green) 120-150 lb, Firm (Blue) 160-180 lb, Extra Firm
  190 lb and over). The product page says the RV1 38 DH has an air spring, so
  the catalog models air only; there is no spring-rate adjuster to key.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `fork/x-fusion/rezza/*` | SAG and rebound base only; no pressure column names the Finecut dampers |
| `fork/x-fusion/get-30/*` | 30mm gravel fork; no guide, not in the owner's manual pressure list |
| `fork/x-fusion/roamin/*` | youth forks; no guide |

## Catalog changes before encoding (R8, R9)

None open: the guide was encoded together with the catalog.

## Follow-ups

- Read the "Oil & Air Value" page (https://www.xfusionshox.com/help_detail/6.htm)
  for volume or oil figures.
- Ask X-Fusion whether the Finecut RL2 / RCP (Rezza) share the 16 rebound clicks
  and which pressure column applies, and what RLR / RCPR add over RCP.
- Ask X-Fusion for click counts of the 3-position platform (RCP), the RC32
  compression and the Roamin RC dampers.
- Service: the owner's manual's service table is ride-based (dust seals, oil
  seals and damper oil every 100 rides or every year; remote lockout and axle
  sleeve every 25 rides); the guides say 80 hours or annually. The catalog uses
  the guides' interval for `fork:full_service`.

## Shocks

No shock guide is encoded (`shock/xfusion.yaml` has no `guides:` block).

### Sources

- Rear-shock set-up page: https://www.xfusionshox.com/help_detail/14.htm, with
  three PDFs (O2, Vector, H3C):
  - https://www.xfusionshox.com/upload/files/2012O2Setupguide1.pdf (7 pages)
  - https://www.xfusionshox.com/upload/files/2012vector_setup_guide1.pdf (not in the catalog)
  - https://www.xfusionshox.com/upload/files/H3C%20Setup%20guide1.pdf (10 pages)
- Oil and air values: https://www.xfusionshox.com/upload/files/XFUSION%20OIL%26AIR%20VALUE-v2.pdf
  (damper / air-sleeve oil volumes only, no pressures or spacers)
- Owner's manual, "Installing XFUSION Rear Suspension": 300 psi maximum,
  60 psi minimum gas spring pressure.
- Retrieved: 2026-11-17

### What the guides publish

| Item | O2 guide (2012) | H3C guide |
|---|---|---|
| Starting air pressure | "start with 80 % of your body weight", no unit | coil: no |
| SAG | 20-25 % XC / Trail, 25-35 % Enduro / All-Mountain, 30-40 % DH / Freeride | the same three bands |
| Rebound | red dial, clockwise = slower; no count | red knob, about 14 clicks |
| Low-speed compression | blue lever: O2 RL / RLR Open / Lockout, RLX Open / Firm / Lockout, RCX Open / Firm / Firmer / Firmest | about 14 clicks |
| High-speed compression | — | about 10 clicks (HLR) |
| Platform | — | 3 clicks: 1 soft, 2 mid, 3 firm (RCP) |
| Preload | — | flush + 1 turn is the minimum, then up to 5 more turns |
| Service | air sleeve and seals every 40 h (25 h extreme), damper rebuild every 80 h or annually | damper rebuild every 80 h or annually |

Why nothing is encoded as a rule: the SAG bands are by discipline (not a
riding style), and the pressure start has no stated unit or weight range. The
click counts and positions are catalog adjusters (`h3c_rcp`, `h3c_hlr`); the
intervals are `tasks`.

### Product facts (pages)

- Rezza RL / RLX / RLR / RLXR: Metric 170x30, 170x35, 190x40, 190x45, 210x50,
  210x55; Trunnion 145x30, 145x35, 165x40, 165x45, 185x50, 185x55; 250 g; no
  pressure range, damper, click count or colors.
- O2 Pro R / RL / RLR / RLX: Standard 165/38, 184/44, 190/51, 200/51, 200/56,
  215/63; Metric 190/40, 190/45, 210/50, 210/55, 230/60, 230/65; Trunnion
  165/40, 165/45, 185/50, 185/55, 205/60, 205/65; 60-300 psi.
- H3A RCP / HLR (air) and H3C RCP / HLR (coil): Metric 210/50, 210/55, 230/60,
  230/65, 250/75; Trunnion 185/50, 185/55, 205/60, 205/65, 225/75; H3A 60-300 psi;
  H3C maximum strut length by stroke (40-45 mm 118, 50-55 mm 98, 60-65 mm 72,
  70-75 mm 37).

### Follow-ups

- Ask X-Fusion for rebound / compression counts of the Rezza, O2 Pro and H3A,
  the platform positions of the H3A RCP, and the spring rates offered for the H3C.
- The O2 guide is from 2012; whether it applies unchanged to the O2 Pro is assumed
  because the O2 Pro pages link it.
