# RST — setup guide research

Catalog files: `data/component_presets/fork/rst.yaml`, `data/component_presets/shock/rst.yaml`
Researched: 2026-10-11

## Summary

- RST publishes three structured fork tables and one shock table, all of the
  same shape: **rider weight (kg only) → air pressure (psi)**, five or six
  brackets, values printed as a psi band or a single psi value.
  - High-end fork manual (XC1800-123): four weight → psi tables, each headed by
    a list of model names. Two of them map to catalog products ("ROGUE … F1RST
    series, AERIAL series …" and "STITCH, SPACE Jump"). The other two (F1RST
    Platinum, VOGUE) have no catalog node.
  - Dirt Jump fork manual (XC1800-105): one table for "SPACE JUMP", which
    **contradicts** the high-end manual's "STITCH, SPACE Jump" table. See the
    follow-ups.
  - MONO shock manual (XC1800-301): weight → psi table, plus a SAG band of
    18–40 % of shock travel. The table prints "Maximum pressure is 400 psi"
    while the text says not to exceed 300 psi.
- SAG: the high-end fork manual gives 15–25 % of maximum travel for its forks.
  The MONO manual gives 18–40 % of shock travel.
- There are no click tables. RST publishes no click counts, and the catalog
  has no rebound or compression adjuster for any RST damper (the dampers carry
  `missing_adjustments`), so there is nothing to compare for counting
  direction. The manuals only give directions: fork rebound clockwise = more
  damping; MONO rebound "+" = more damping; coil preload clockwise = stiffer.
- There are no volume-spacer counts, coil spring-rate charts or formulas.
- Gaps for B3:
  - several printed value cells are open-ended (`215 +`) or bracket labels use
    arrows (`60 ↓`, `100 ↑`);
  - the brackets share their bounds (`40-60`, `60-80`), so they need a
    half-open convention;
  - the shock has two contradicting maxima;
  - two RST documents disagree on SPACE Jump.

## Guide `rst_highend_forks` — RST Owner's Manual, high-end models (XC1800-123)

### Source

- URL: https://rstsuspension.com/wp-content/uploads/2026/02/01-%E8%AA%AA%E6%98%8E%E6%9B%B8-XC1800-123%E9%AB%98%E9%9A%8E%E6%A9%9F%E7%A8%AE-%E8%8B%B1%E6%96%87ENGLISH_A4.pdf
- Document: RST Owner's Manual (English), code XC1800-123. It has no model
  year (uploaded 2026-02). The cover lists AERIAL, AVION, BLADE/PRO, F1RST,
  IGNITE 24, KILLAH, PULSE, REBEL, RENEGADE, REVEAL, REVO, ROGUE, SNYPER 24,
  SPARK 20, SPEX 20, STITCH, STORM, VIBE, VIVAIR, VIVAIR E, VOGUE, VOGUE E,
  VOLAIR E and VOLTA.
- Section / page: "Recommendation for air pressure" and "Measuring and setting
  SAG", printed page 6 (PDF page 7).
- Retrieved: 2026-10-11

### Catalog mapping

Table A, "ROGUE, TITAN/ TITAN 15, SLOPE, CHAMP series, F1RST series, AERIAL Rebound series, AERIAL series, VIVAir, PULSE AIR series":

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rst/rogue-v2/air` | — | ROGUE |
| `fork/rst/rogue-v2/air-trl` | — | ROGUE |
| `fork/rst/rogue-v2/air-w-o-lockout` | — | ROGUE |
| `fork/rst/slope/hc` | — | SLOPE (air) |
| `fork/rst/f1rst/air` | — | F1RST series |
| `fork/rst/f1rst/air-trl` | — | F1RST series |
| `fork/rst/f1rst-110/110-15-air` | — | F1RST series |
| `fork/rst/f1rst-110/110-15-air-trl` | — | F1RST series |
| `fork/rst/f1rst-110/110-9-air` | — | F1RST series |
| `fork/rst/f1rst-110/110-9-air-trl` | — | F1RST series |
| `fork/rst/aerial/rl` | — | AERIAL series (all AERIAL trims are air) |
| `fork/rst/aerial/tnl` | — | AERIAL series |
| `fork/rst/aerial/mlc` | — | AERIAL series |
| `fork/rst/aerial-110/110-15-tnl` | — | AERIAL series |
| `fork/rst/aerial-110/110-15-mlc` | — | AERIAL series |
| `fork/rst/aerial-110/110-9-tnl` | — | AERIAL series |
| `fork/rst/aerial-110/110-9-mlc` | — | AERIAL series |

Table B, "STITCH, SPACE Jump":

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rst/stitch/air` | — | STITCH |
| `fork/rst/stitch-29/air` | — | Assumed to be covered by "STITCH" (the same family name) |
| `fork/rst/stitch-29-limited-edition/air` | — | Assumed, as for STITCH 29 |
| `fork/rst/space/jump` | — | Conflicts with the Dirt Jump manual (guide `rst_dirtjump_forks`) |

SAG band: every air trim of a fork named in this manual. That covers the
paths above plus `fork/rst/killah/air`, `fork/rst/r-evo-29/air`,
`fork/rst/vibe-v2/air-ra`, `fork/rst/vibe-v2/air-rl`,
`fork/rst/rebel-v2/air`, `fork/rst/rebel-v2/air-trl`,
`fork/rst/rebel-v2/air-w-o-lockout`, `fork/rst/blade-pro/air`,
`fork/rst/blade-pro/air-trl`, `fork/rst/blade-pro/air-w-o-lockout`,
`fork/rst/blade/air-tnl-f`, `fork/rst/blade/air-tnl-r`,
`fork/rst/blade/air-rl`, `fork/rst/blade/air-rl-r`, `fork/rst/snyper/air`,
`fork/rst/snyper/trl`, `fork/rst/renegade/air` and
`fork/rst/renegade/air-trl`.

The manual describes the SAG procedure for every fork. The coil trims of the
same models (`fork/rst/killah/coil`, `fork/rst/r-evo-29/coil`,
`fork/rst/stitch/coil`, `fork/rst/stitch-29/coil`, `fork/rst/storm/ra`,
`fork/rst/vibe-v2/ra|rl|tnl`, `fork/rst/blade/tnl-f|tnl-r|rl|rl-r`,
`fork/rst/renegade/tnl`) are covered too. Only the remedy the manual gives
for a SAG outside the band is worded for air (change the air pressure).

Gaps:
- "F1RST Platinum" and "VOGUE" have their own tables, but the catalog has
  neither node. VOGUE is e-trekking, which is out of scope. F1RST Platinum is
  not a catalog trim. Not encoded.
- TITAN, CHAMP, VIVAir and PULSE AIR are not in the catalog. VIVAir is not
  the catalog's VIVO, so `fork/rst/vivo/air-*` gets no table.
- These models are named in the manual but have no pressure table: KILLAH,
  R.EVO, VIBE, REBEL, BLADE/PRO, SNYPER, RENEGADE, STORM.

### Air pressure — Table A (ROGUE / F1RST series / AERIAL series / SLOPE …)

Input: rider weight (kg only) · Output: psi · `when:` the product paths above (no option filter)

| Rider weight (kg) | psi |
|---|---|
| 40-60 | 60 |
| 60-80 | 60-80 |
| 80-100 | 80-100 |
| 100-110 | 100-120 |
| 110-120 | 120-150 |

### Air pressure — Table B (STITCH, SPACE Jump)

Input: rider weight (kg only) · Output: psi · `when:` the product paths above

| Rider weight (kg) | psi |
|---|---|
| 20-40 | 30-40 |
| 40-60 | 35-40 |
| 60-80 | 45-55 |
| 80-100 | 55-65 |
| 100-120 | 120 |

The jump from 55-65 to a single 120 in the last column is as printed. It
looks like a misprint, but the source prints it this way, so it is kept
(follow-up).

### Air pressure — not mapped (no catalog node)

F1RST Platinum:

| Rider weight (kg) | psi |
|---|---|
| 40-60 | 50-70 |
| 60-80 | 70-90 |
| 80-100 | 90-110 |
| 100-110 | 110-120 |
| 110-120 | 140 |

VOGUE:

| Rider weight (kg) | psi |
|---|---|
| 40-60 | 110 |
| 60-80 | 115-120 |
| 80-100 | 120-130 |
| 100-110 | 130-140 |
| 110-120 | 140-150 |

### Rebound

No click table exists. The manual gives only the direction: rebound adjuster
clockwise = more rebound damping (slower), counter-clockwise = less. The
catalog has no rebound adjuster for any RST fork damper, so there is no
direction to compare.

### Constants / base tune

None published.

### SAG

15–25 % of maximum travel, for all forks in this manual. No travel or
riding-style dependence. Below 15 % the fork is too stiff (lower the
pressure). Above 25 % it is too soft (raise the pressure). Encode as
`target: sag`, `range: 15-25` (%), `when:` the product paths listed under
the SAG band.

### Volume spacers

Not published.

### Pressure limits

No fork maximum or minimum pressure is printed. The catalog Pressure has
`min: 0` and no `max`, which is consistent.

### Formulas

None.

### Does not fit B3

- Some value cells are a single psi (`60`, `120`) and others a band
  (`60-80`). Encode a single value as `value` and a band as `range`.
- The weight brackets share their bounds (`40-60`, `60-80`). Encode them
  half-open (`40-60` = [40, 60)) per the generic rule, and note that the
  source is ambiguous at 60/80/100/110 kg.
- The tables are keyed by a free-text model list, not by catalog options, so
  each table becomes one guide applied to a list of product paths.

## Guide `rst_dirtjump_forks` — RST Owner's Manual, Dirt Jump (XC1800-105)

### Source

- URL: https://cdn.rstsuspension.com/image/2025/03/05135247/01-%E8%AA%AA%E6%98%8E%E6%9B%B8-XC1800-105-Dirt-Jump-%E8%8B%B1%E6%96%87ENGLISH_A4_O.pdf
- Document: RST Owner's Manual "Dirt Jump" (English), code XC1800-105, no
  model year (uploaded 2025-03). The file is a scanned image with no text
  layer. Its special-statements section covers SPACE, SLOPE and DIRT.
- Section / page: "Function" → Air spring system table, printed page 5 (PDF
  page 6).
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rst/space/jump` | — | Table headed "SPACE JU MP" (sic) |

Gaps: SLOPE and DIRT are covered by this manual but have no table here. SLOPE
is in Table A of the high-end manual. DIRT is coil.

### Air pressure — SPACE JUMP

Input: rider weight (kg only) · Output: psi · `when:` —

| Rider weight (kg) | psi |
|---|---|
| 45-60 | 5-10 |
| 60-75 | 10-25 |
| 75-90 | 25-35 |
| 90-105 | 35-45 |
| 105-120 | 45-60 |

### Rebound

No click table. RA rebound adjuster clockwise = more rebound damping. The
catalog has no rebound adjuster on `ra`.

### Constants / base tune · SAG · Volume spacers · Pressure limits · Formulas

- Constants / base tune: none.
- SAG: none (this manual has no SAG section).
- Volume spacers: none.
- Pressure limits: none.
- Formulas: none.
- Coil preload: clockwise = stiffer. No values.

### Does not fit B3

- This table conflicts with Table B of the high-end manual for the same
  product (at 80-100 kg, for example, 55-65 psi there against 35-45 / 45-60
  here). Only one can be encoded. Proposal: use the Dirt Jump manual, which is
  dedicated to the product and newer than the 2024 general manual, but leave
  it unencoded until a data editor decides (follow-up).

## Guide `rst_mono_shock` — RST Owner's Manual, MONO DPU / R / DU rear shock (XC1800-301)

### Source

- URL: https://rstsuspension.com/wp-content/uploads/2026/02/01-%E8%AA%AA%E6%98%8E%E6%9B%B8-XC1800-301%E5%BE%8C%E9%81%BF%E9%9C%87-MONO-%E8%8B%B1%E6%96%87ENGLISH_A4-1.pdf
- Document: RST Owner's Manual MONO DPU / R / DU, Trunnion / Standard
  (English), code XC1800-301, no model year (uploaded 2026-02).
- Section / page: "Measure and set SAG" and the pressure table, printed page 3
  (PDF page 4). Rebound and lockout are on printed page 4.
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/rst/mono/dpu-standard` | `damper: mono_dpu` | |
| `shock/rst/mono/dpu-trunnion` | `damper: mono_dpu` | |
| `shock/rst/mono/r-standard` | `damper: mono_r` | |
| `shock/rst/mono/r-trunnion` | `damper: mono_r` | |

Gaps: the manual also covers a "DU" variant (2-position lockout) that the
catalog lacks.

### Air pressure — MONO (all variants)

Input: rider weight (kg only) · Output: psi · `when:` —

| Rider weight (kg) | Recommended pressure (psi) |
|---|---|
| 60 ↓ | 105 ~ 135 |
| 60 ~ 70 | 135 ~ 155 |
| 70 ~ 80 | 155 ~ 175 |
| 80 ~ 90 | 175 ~ 195 |
| 90 ~ 100 | 195 ~ 215 |
| 100 ↑ | 215 + |

The table footer reads "Maximum pressure is 400 psi". The manual adds that
frames differ: a low-leverage design needs less pressure.

### Rebound

No click table. Turning toward "+" = more rebound damping. The catalog has no
rebound adjuster on `mono_dpu` / `mono_r`.

### Constants / base tune

- Before setting SAG, the lockout lever goes to DOWN HILL (DPU / DU only). In
  catalog terms that is `compression_mode` = `Downhill` on `mono_dpu`, as a
  setup precondition. A procedure, not a riding setting: no rule, a `note` at
  most (R9).
- The manual says to adjust pressure in 10 psi increments while setting SAG.

### SAG

18–40 % of shock travel (stroke). The manual's example is a 230/65 shock →
12–26 mm. No style dependence. The text also defers to the bicycle manual for
the recommended SAG. Encode `target: sag`, `range: 18-40` (%), `when:` the
four MONO paths.

### Volume spacers

Not published.

### Pressure limits

The source contradicts itself. The text says the air pressure should not
exceed 300 psi, and the table footer says the maximum is 400 psi. The catalog
`pressure` has no `max`, which matches the existing YAML follow-up. Do not
set either value until RST clarifies.

### Formulas

None.

### Does not fit B3

- `60 ↓` and `100 ↑` are open-ended weight brackets. They map to `<60` and
  `100+`.
- `215 +` is an inequality cell: `[215, max]` (R9), against the MONO's
  `pressure` max. That max is in conflict (300 vs 400 psi), so until it is
  settled the `100+` row is left out and those riders are outside the table.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `fork/rst/killah/air` | Named in XC1800-123, but no pressure table names KILLAH. SAG band only |
| `fork/rst/r-evo-29/air` | Named (REVO) in XC1800-123, no table. SAG band only |
| `fork/rst/vibe-v2/air-ra`, `fork/rst/vibe-v2/air-rl` | Named (VIBE) in XC1800-123, no table. SAG band only |
| `fork/rst/rebel-v2/air`, `/air-trl`, `/air-w-o-lockout` | Named (REBEL) in XC1800-123, no table. SAG band only |
| `fork/rst/blade-pro/air`, `/air-trl`, `/air-w-o-lockout` | Named (BLADE/PRO) in XC1800-123, no table. SAG band only |
| `fork/rst/blade/air-tnl-f`, `/air-tnl-r`, `/air-rl`, `/air-rl-r` | Named (BLADE/PRO) in XC1800-123, no table. SAG band only |
| `fork/rst/snyper/air`, `fork/rst/snyper/trl` | Named (SNYPER 24) in XC1800-123, no table. SAG band only |
| `fork/rst/renegade/air`, `fork/rst/renegade/air-trl` | Named in XC1800-123, no table. SAG band only |
| `fork/rst/guide/air-tnl`, `fork/rst/guide/air-mlc` | General manual XC1800-109 (A3 sheet, 2 pages, read visually): no pressure table, no SAG figure |
| `fork/rst/shine/ra` | Not named in any manual. The Dirt Jump manual covers SPACE / SLOPE / DIRT only |
| `fork/rst/vivo/air-tnl`, `/air-mlc`, `/air-hcr` | Not named in any manual. "VIVAir" in Table A is a different (e-trekking) fork |
| All coil trims (`fork/rst/killah/coil`, `fork/rst/r-evo-29/coil`, `fork/rst/stitch/coil`, `fork/rst/stitch-29/coil`, `fork/rst/storm/ra`, `fork/rst/vibe-v2/ra`, `/rl`, `/tnl`, `fork/rst/blade/tnl-f`, `/tnl-r`, `/rl`, `/rl-r`, `fork/rst/renegade/tnl`, `fork/rst/guide/tnl`, `/mlc`, `/t`, `fork/rst/omega/*`, `fork/rst/blaze/*`, `fork/rst/capa/*`, `fork/rst/dirt/*`, `fork/rst/space/free`, `fork/rst/vivo/tnl`, `/mlc`, `/t`) | No spring-rate chart or preload values in any manual (preload direction only). Coil trims of models named in XC1800-123 still get the 15–25 % SAG band |
| `shock/rst/mezzo/coil` | No MEZZO manual on rstsuspension.com/owner-manual/. The product page lists the springs offered (350–550 lb) but no rider-weight chart |

Also checked with no setup data: the 2026 catalogue
(https://rstsuspension.com/catalogues/2026.pdf, 80 pages) and the product
pages for KILLAH, STITCH, SPACE, VIVO, MONO DPU and MEZZO.

## Catalog changes before encoding (R8, R9)

R8 fixes:
- MONO `pressure` max: settle 300 vs 400 psi, then set it, so the `215 +`
  cell can become `[215, max]`.
- SPACE (Jump) and the Table B last row stay out until RST confirms them.

R9 type changes: none.

## Follow-ups

- **SPACE Jump conflict:** XC1800-123 Table B ("STITCH, SPACE Jump") and
  XC1800-105 ("SPACE JUMP") give different weight → psi tables. Ask RST, or
  decide which to encode. The proposal is XC1800-105 for `fork/rst/space/jump`
  and Table B for the STITCH family only.
- **Table B last column** (100-120 kg → 120 psi, after 55-65 psi) looks like a
  misprint. Confirm with RST before encoding that row.
- **STITCH 29 / STITCH 29 Limited Edition** are assumed to fall under
  "STITCH". The manual does not name the 29" chassis separately.
- **MONO max pressure** is 300 psi in the text and 400 psi in the table.
  Leave `max` unset.
- The open-ended value `215 +` is `[215, max]` (R9) once the MONO max is
  settled; until then its row is left out.
- A "DU" MONO variant exists in the manual but not in the catalog.
- No click tables means nothing for the counting-direction check. If RST ever
  publishes counts, the directions recorded above apply.
