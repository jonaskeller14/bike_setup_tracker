# Formula — setup guide research

Catalog files: `data/component_presets/fork/formula.yaml`, `data/component_presets/shock/formula.yaml`
Researched: 2026-10-11

## Summary

- **Air forks** (Selva V, Selva S, Selva R, Belva, Nero R): each owner's manual
  prints a rider weight → air pressure table. Shapes differ:
  - Selva V: weight points → psi **band** (`range`), with the bar/psi column
    headers swapped in print.
  - Selva S, Belva: weight points → single bar + psi values.
  - Selva R (2Air): weight → two chambers (Silver main, Bronze negative =
    Silver + 20), Bronze tunable ±10 psi.
  - Nero R (3Air): weight → three chambers (Gold, Silver, Bronze), plus
    inflation-order and inter-chamber rules.
  - No fork manual gives rebound/compression clicks or a SAG target. Neopos
    maxima (3) and stock counts are printed.
- **Coil forks** (Selva C, Nero C): no spring-by-weight chart in manual or on
  the product page — none.
- **Shocks:** Nebbia manual has a weight-band → psi-band table, base clicks
  (rebound 12, compression 10 from closed) and SAG-indicator positions by
  discipline. MOD manual (also the one linked for the MOD DH) has a SAG target
  (30 % Enduro/Gravity), a SAG mm table per stroke, base clicks (rebound 6,
  compression 9 from closed) and the preload window; no spring-rate chart.
- **CTS valves:** rideformula.com/technologies/cts describes the eight valves
  qualitatively (comfort → race, Titanium for e-bike racing); no numbers, and
  the catalog has no CTS adjuster. Not encodable.
- Encoding: multi-chamber pressures are one rule set per chamber, with the
  inter-chamber rules as `note`s (Selva R, Nero R); weight-band → pressure-band
  is brackets with band cells (Nebbia, R1/R2). No rule, note only:
  SAG-indicator marks (Nebbia), spring-rate → rebound offset (MOD), lever
  positions for descents vs climbs.

## Guide `formula_selva_v_2025` — Selva V user manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2025/06/Selva_V_User_Manual_EN-1.pdf
- Document: Selva V User Manual, 2025 (upload 2025/06), English
- Section / page: 7. Air Spring Setup (p. 9), 11. Adding Neopos (p. 13)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/formula/selva/v` | `damper: selva_v_2025` | all `travel_mm` (160/170/180) and `wheel_size` (27.5/29) — the table has no travel or wheel column |

Gaps: none.

### Air pressure

Input: rider weight (kg and lbs printed; lbs are rounded, not exact
conversions) · Output: psi band · target `pressure`.

The printed column headers are swapped: the column headed "PSI" holds bar-scale
values (3.1–7.9) and the column headed "BAR" holds psi-scale bands (40–50 …
110–120). The values below are as printed, re-labelled by magnitude; the bar
values match the Selva S table's bar column exactly.

| Rider weight (kg) | Rider weight (lbs) | Printed under "PSI" (bar values) | Printed under "BAR" (psi band) |
|---|---|---|---|
| 50 | 110 | 3.1 | 40-50 |
| 60 | 125 | 3.5 | 50-60 |
| 70 | 150 | 4.5 | 60-70 |
| 80 | 175 | 5.2 | 70-80 |
| 90 | 200 | 5.9 | 80-90 |
| 100 | 225 | 6.5 | 90-100 |
| 110 | 250 | 7.2 | 100-110 |
| 120 | 275 | 7.9 | 110-120 |

Encoding: `pressure` `[a, b]` band cells (psi) per weight point (R2).

### Rebound / compression

No recommended clicks. Rebound: clockwise adds damping. Compression: blue knob,
progressive; CTS valve choice by riding style (qualitative only).

### Constants / base tune

None published.

### SAG

None published.

### Volume spacers

Target `neopos`. "Between 0 and 3" Neopos; the first support is press-fitted
onto the cap. The manual does not state how many Neopos are fitted from the
factory (product page: "compatible with new dedicated supports").

### Pressure limits

None printed (table tops out at 110–120 psi). Catalog `pressure` has no max —
consistent.

### Formulas

None.

### Does not fit B3

- Swapped column headers (data quality; encode psi bands, keep bar as note).

## Guide `formula_selva_s_2018` — Selva S owner's manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2018/10/Manuale_SELVA_S_GB.pdf
- Document: Selva S owner's manual (GB), upload 2018/10, English
- Section / page: 3.3 Adjusting the air pressure (p. 10), table 1 (p. 11), Neopos (p. 15)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/formula/selva/s` | `damper: selva_2017` | all `travel_mm` (120/160/170/180) and wheel sizes |

Gaps: none.

### Air pressure

Input: rider weight (kg and lbs printed) · Output: bar and psi · target
`pressure`. Literal points. Decimal commas written as dots.

| Rider weight (kg) | Rider weight (lbs) | bar | psi |
|---|---|---|---|
| 50 | 110 | 3.1 | 45 |
| 60 | 125 | 3.5 | 55 |
| 70 | 150 | 4.5 | 65 |
| 80 | 175 | 5.2 | 75 |
| 90 | 200 | 5.9 | 85 |
| 100 | 225 | 6.5 | 95 |
| 110 | 250 | 7.2 | 105 |
| 120 | 275 | 7.9 | 115 |

### Constants / base tune

None published.

### SAG

None published.

### Volume spacers

Target `neopos`: max three "regardless of the fork stroke"; Neopos are optional
on the Selva S (product page "Neopos: Optional") → factory count 0.

### Pressure limits

"Maximum allowable pressure is 125psi". Catalog `pressure` max 125 — matches.

### Formulas

None.

### Does not fit B3

Nothing beyond the plain weight → pressure table.

## Guide `formula_selva_r_2023` — Selva R owner's manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2023/06/Manuale_SELVA_R_GB-Def.pdf
- Document: Selva R owner's manual (GB), upload 2023/06, English
- Section / page: 3.3 Adjusting the air pressure (p. 10), 3.4 Inflating procedure (p. 11), pressure table (p. 12), Neopos (p. 13)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/formula/selva/r` | `damper: selva_2017` | all `travel_mm` (120–180) and wheel sizes |

Gaps: none. Catalog targets: Silver → `main_chamber_pressure`, Bronze →
`negative_chamber_pressure`.

### Air pressure — Silver (main) and Bronze (negative)

Input: rider weight (kg and lbs printed) · Output: pressure per chamber. The
table header reads "AIR PRESSURE · SILVER · BRONZE" with no unit printed;
the values match the manual's psi-based limits (max 125 psi, Bronze ±10 psi),
so psi is assumed (see Follow-ups).

| Rider weight (kg) | Rider weight (lbs) | Silver (`main_chamber_pressure`) | Bronze (`negative_chamber_pressure`) |
|---|---|---|---|
| 60 | 132 | 60 | 80 |
| 70 | 154 | 70 | 90 |
| 80 | 176 | 80 | 100 |
| 90 | 198 | 90 | 110 |
| 100 | 220 | 100 | 120 |

Inflation order: Silver first, then (lockout closed) Bronze. Bronze may be
moved ±10 psi from the table value: +10 softer initial stroke, −10 firmer.

### Constants / base tune

None published.

### SAG

None published.

### Volume spacers

Target `neopos`: max three regardless of travel. Factory count 1 (product page:
"one is already included into the Selva R"; spec table "Neopos: Included").

### Pressure limits

"Maximum allowable pressure is 125psi" (stated once, not per chamber). Catalog
max 125 on both chamber adjusters — matches.

### Formulas

In the table Bronze = Silver + 20 psi on every row, and Silver (psi) equals
rider weight (kg). This is an observed pattern, not a stated formula; encode
the table rows, not a formula.

### Does not fit B3

- **Two chambers:** two targets from one input — fine as two rule sets. The
  ±10 psi Bronze tolerance becomes a band cell per row (`[v − 10, v + 10]`,
  R2): the table value is applied and the tolerance counts as on guide.

## Guide `formula_belva_2024` — Belva user manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2024/03/Manuale-Utente-Belva-ENG.pdf
- Document: Belva user manual, upload 2024/03, English
- Section / page: Pressure check (p. 10)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/formula/belva/air` | `damper: belva_2024` | `travel_mm` 170/180, both wheel sizes; no travel column |

Gaps: none.

### Air pressure

Input: rider weight (kg and lbs printed) · Output: bar and psi · target
`pressure`. Three literal points only.

| Rider weight (kg) | Rider weight (lbs) | bar | psi |
|---|---|---|---|
| 50 | 110 | 3.4 | 50 |
| 70 | 155 | 4.5 | 65 |
| 90 | 200 | 5.5 | 80 |

### Constants / base tune

None published.

### SAG

None published.

### Volume spacers

The manual says "for a stiffer fork change your CTS or add a Neopos"; product
page lists Neopos as optional. No limit printed; the catalog has no Neopos
adjuster on the Belva.

### Pressure limits

"Maximum suggested pressure is 85 psi". Catalog `pressure` max 85 — matches.

### Formulas

None.

### Does not fit B3

- Only three points (50/70/90 kg); interpolation outside 50–90 kg is not
  supported by the source.

## Guide `formula_nero_r_2017` — Nero R owner's manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2017/08/Nero-R-owner-manual.pdf
- Document: Nero R owner's manual, upload 2017/08, English
- Section / page: 3.3 Adjusting the air pressure (pp. 11–12), table p. 12, 3.4 Neopos (p. 13)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/formula/nero/r` | `damper: nero_2017` | `travel_mm` 180/190/200, both wheel sizes; no travel column |

Gaps: none. Catalog targets: Gold → `progressivity_chamber_pressure`, Silver →
`main_chamber_pressure`, Bronze → `sensitivity_chamber_pressure`.

### Air pressure — 3Air (psi)

Input: rider weight (kg and lbs printed) · Output: psi per chamber (header "AIR
PRESSURE (PSI)").

| Rider weight (kg) | Rider weight (lbs) | Gold (`progressivity_chamber_pressure`) | Silver (`main_chamber_pressure`) | Bronze (`sensitivity_chamber_pressure`) |
|---|---|---|---|---|
| 60 | 132 | 110 | 80 | 100 |
| 70 | 154 | 120 | 90 | 110 |
| 80 | 176 | 130 | 100 | 120 |
| 90 | 198 | 140 | 110 | 130 |
| 100 | 220 | 150 | 120 | 140 |

Rules printed with the table: inflate Gold → Silver → Bronze; Gold ≥ Silver;
Bronze at least 20 psi above Silver; Silver cannot be checked without first
deflating Bronze. Gold and Bronze curves are shown shifting ±10 psi (graphic).

### Constants / base tune

None published (HSC/LSC/rebound directions only).

### SAG

None published.

### Volume spacers

Target `neopos`: up to three regardless of travel. Factory count: product page
"Neopos: Included" without a number (see Follow-ups).

### Pressure limits

None printed. Catalog pressures unbounded — consistent.

### Formulas

Bronze ≥ Silver + 20 psi; Gold ≥ Silver (constraints, not a weight formula).
The table satisfies Bronze = Silver + 20 and Gold = Silver + 30 on every row.

### Does not fit B3

- **Three chambers with ordering/inequality constraints.** Encode the table as
  three weight → value rule sets; the constraints become a `note` (B3 has no
  cross-target constraint).

## Guide `formula_nebbia_2024` — Nebbia user manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2024/07/Manuale-Utente-Nebbia-ENG.pdf
- Document: Nebbia user manual, upload 2024/07, English
- Section / page: Shock installation / pressure table (p. 5), SAG setting (p. 6), Rebound adjuster (p. 7), Compression adjuster (p. 8), Lock-out lever (p. 9)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/formula/nebbia/air` | `damper: nebbia_2024` | all sizes; no size column |

Gaps: none.

### Air pressure

Input: rider weight band (kg and lbs printed) · Output: psi band ("a" = to) ·
target `pressure`. Formula notes frames can differ by as much as 30 psi.
Factory fill is 150 psi.

| Rider weight (kg) | Rider weight (lbs) | Pressure (psi) |
|---|---|---|
| 50 - 60 | 110 - 132 | 120 a 130 |
| 60 - 70 | 132 - 155 | 130 a 140 |
| 70 - 80 | 155 - 175 | 140 a 150 |
| 80 - 90 | 175 - 200 | 150 a 170 |
| 90 - 100 | 200 - 220 | 170 a 190 |
| 100+ | 220+ | 190 a 210 |

Encoding: half-open weight brackets `50-60`, `60-70`, … `100+` (R1) with `[a, b]`
band cells (R2).

### Rebound — base tune

Source direction: close fully clockwise, then open 12 clicks counter-clockwise
(= 12 from closed). Catalog: `nebbia_2024` `rebound`, max 23, default
`dial_ccw` (from closed) → same direction, encode 12.

### Compression — base tune

Source direction: fully clockwise, then 10 clicks counter-clockwise (= 10 from
closed). Catalog: `nebbia_2024` `compression`, max 21, `dial_ccw` → same
direction, encode 10.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `rebound` | 12 | from closed | `damper: nebbia_2024` |
| `compression` | 10 | from closed | `damper: nebbia_2024` |
| `compression_mode` | Open (descending); Platform (technical climbs); Firm (tarmac climbs) | — | situational: no rule, `note` only (R9) |

### SAG

No percentage. The O-ring SAG indicator has marked positions by discipline:
DH 1–2, Trail/AM/Enduro 3–4, XC/Down Country 5–6. These are marks on the
indicator, not % or mm, and the keys are disciplines, not riding styles (R7) → no
rule, a `note` at most.

### Volume spacers

Product page: volume spacers "Compatible"; no count in manual or page. No
catalog adjuster.

### Pressure limits

None printed (table tops at 190–210 psi; factory fill 150 psi). Catalog
`pressure` unbounded — consistent.

### Formulas

None.

### Does not fit B3

- Weight band → pressure band (both sides ranges): fine as brackets + `range`.
- SAG-indicator positions are not a SAG value.
- "Frames can vary by as much as 30 psi" → `note`.

## Guide `formula_mod_2020` — MOD owner's manual

### Source

- URL: https://www.rideformula.com/wp-content/uploads/2020/09/MOD-Owner-Manual.pdf
- Document: MOD owner's manual, upload 2020/09, English
- Section / page: 1.3 SAG and adjustments (pp. 9–10), 1.4.1 Rebound (p. 11), 1.4.2 Compression (p. 11), 1.4.3 Lockout (p. 12)
- Also checked: Italian MOD manual (https://www.rideformula.com/wp-content/uploads/2020/09/MOD-Manuale-utente.pdf), which the MOD DH page links — same numbers.
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/formula/mod/coil` | `damper: mod_2020` | all sizes |
| `shock/formula/mod-dh/coil` | `damper: mod_dh` | the MOD DH page links the (Italian) MOD manual; no DH-specific document exists. Lockout advice does not apply (no switch) |

Gaps: none.

### Air pressure / spring rate

No spring-rate-by-weight chart in the manual. Product pages list available
springs only (MOD 300–700 lbs/in, MOD DH 250–550 lbs/in, 50 lbs/in steps).

### Rebound — base tune

Source direction: close fully clockwise, then open 6 clicks anticlockwise
(= 6 from closed). Catalog: `mod_2020` / `mod_dh` `rebound`, max 13,
`dial_ccw` → same direction, encode 6.

### Compression — base tune

Source: close fully clockwise, then open 9 clicks anticlockwise (= 9 from
closed). Catalog: `mod_2020` / `mod_dh` `compression`, max 17, `dial_ccw` →
same direction, encode 9.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `rebound` | 6 | from closed | `damper: mod_2020`, `damper: mod_dh` |
| `compression` | 9 | from closed | `damper: mod_2020`, `damper: mod_dh` |
| `preload` | 2–5 mm permissible window (min 2, max 5; 1.25 mm per turn per catalog note) | — | both; `range` |
| `compression_mode` | Open for descents / technical climbs, Firm (closed) for pedalling | — | `damper: mod_2020` only; situational: no rule, `note` only (R9) |

### SAG

Target 30 % for Enduro / Gravity. MOD and MOD DH are enduro / gravity shocks and
the disciplines are no riding styles (R7), so encode `sag` `value: 30` without a
`when`. Formula SAG % = (eye-to-eye unloaded − loaded) / stroke × 100.
Reference table as printed (mm; decimal commas written as dots):

| Stroke | 15 % | 20 % | 25 % | 30 % | 35 % | 40 % |
|---|---|---|---|---|---|---|
| 55 mm | 8.25 mm | 11 mm | 13.75 mm | 16.5 mm | 19.25 mm | 22 mm |
| 65 mm | 9.75 mm | 13 mm | 16.25 mm | 19.5 mm | 22.75 mm | 26 mm |
| 75 mm | 11.25 mm | 15 mm | 18.75 mm | 22.5 mm | 26.75 mm | 30 mm |

The 75 mm / 35 % cell is printed 26,75 mm; 35 % of 75 mm is 26.25 mm (misprint,
same in the Italian manual).

To increase SAG reduce preload (not below 2 mm), otherwise fit a softer spring;
to decrease SAG add preload (not above 5 mm), otherwise a stiffer spring.

### Volume spacers

Not applicable (coil).

### Pressure limits

Not applicable. (Troubleshooting table mentions 95 psi in the reservoir.)

### Formulas

SAG % formula above (measurement, not a setting). No spring-rate formula.

### Does not fit B3

- **Spring rate → rebound offset:** going from 400 to 450 lbs/in needs 1–2
  clicks more rebound (clockwise) for the same feel. Second-order input
  (`spring_rate`); proposed `note`.
- SAG mm table is derivable from stroke × %; only the 30 % target needs
  encoding.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `fork/formula/selva/c` | Selva C manual (https://www.rideformula.com/wp-content/uploads/2018/10/2021_02-FORCEL_SELVA_C_GB.pdf, §3.3–3.4) describes preload direction and spring swap only; product page lists spring options (Hyper Soft/Super Soft, Soft, Medium default, Firm, Super Firm) and a 10-click preload with no weight ranges. No setup numbers. |
| `fork/formula/nero/c` | Nero C manual (https://www.rideformula.com/wp-content/uploads/2017/08/Nero-C-Owner-manual.pdf, §3.3–3.4) and product page give spring options (Medium default, Soft/Firm optional) without weight ranges. No setup numbers. |

## Catalog changes before encoding (R8, R9)

R8 fixes:
- Selva V: settle the swapped PSI / BAR headers before encoding.
- Selva R: confirm the table unit (psi assumed).

R9 type changes: none. Lever and CTS guidance stays `note` text.

## Follow-ups

- Selva R table prints no unit; psi assumed from the manual's psi limits.
  Confirm before encoding.
- Selva V table has swapped "PSI"/"BAR" headers; consider asking Formula or
  checking a newer manual revision.
- Neopos factory count: Selva R = 1 (page text); Nero R page says "Included"
  without a count; Selva V not stated. Only Selva R is safe to encode.
- CTS valve guidance (eight valves, qualitative) has no catalog adjuster and no
  recommended valve per rider, so it is no rule (R9). A CTS categorical would
  only be worth adding with a published recommendation.
- Coil spring charts (Selva C, Nero C, MOD, MOD DH): none published; re-check
  rideformula.com tutorials/downloads if a spring calculator appears.
