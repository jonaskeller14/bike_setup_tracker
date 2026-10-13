# Öhlins — setup guide research

Catalog files: `data/component_presets/fork/ohlins.yaml`, `data/component_presets/shock/ohlins.yaml`
Researched: 2026-10-11

## Summary

- Sources are Öhlins owner's manuals (ohlins.eu `download/db` and ohlins.com `storage`). The manuals
  keep identical numbers across languages and most reprints; the edition used is named per guide.
- Fork shapes:
  - rider weight (kg with lb printed) → air pressure as a **band** per bracket (`80-90 psi`), not a single
    value;
  - on two-chamber forks (RXF34/36 m.1, RXF36 m.2/m.3, RXF38 m.2/m.3), one band each for the **main** and
    the **ramp-up chamber**;
  - SAG bands;
  - base-tune click ranges (`14-16 clicks`) counted from closed;
  - high-speed compression delivery positions (constants);
  - recommended volume-spacer counts per travel (RXC34, RXF34 m.2);
  - coil spring charts that give spring rate → **one** rider weight point.
- Shock shapes:
  - SAG bands (25-35 % TTX, 20-30 % TXC);
  - a constant start pressure before sag (170 psi TTX Air, 200 psi TXC Air);
  - delivery positions of the three-position high-speed dial;
  - factory spacer volume by part number;
  - max pressures.
  - No rider-weight → pressure or click tables for any shock.
- The manuals point riders to Öhlins' **Performance Suspension Guide** (PSG, ohlins.com) for bike-specific
  base pressure and spacers. It is keyed by bike model, not by rider data, so nothing from it is encodable.
- Encoding (R3, R9):
  - the two-chamber forks where the catalog lists a single `pressure` (RXF34 m.1, RXF36 m.1/m.2/m.3,
    DH38) switch to the catalog's main + ramp-up adjusters (catalog change), then both bands are encoded;
  - coil charts keyed by a weight point are literal `rider_weight` points on `spring_rate`; spring rates
    take the nearest point and never interpolate (R3);
  - RXF34 m.2 spacer charts keyed by chassis part number: the 140 mm-max chart is encoded (it covers every
    catalog travel), the 130 mm-max values go into the `note`;
  - the high-speed dial labelled 1/2/P or I/II/III becomes a categorical `hsc` with those positions as
    options (catalog change), so the delivery position is an option.
- No rule until the catalog maps part numbers to sizes: shock spacer production volumes keyed by part
  number. The reducer configurations (A … E+4F) would then be categorical options (R9).
- Two count conflicts with the catalog:
  - RXF36 m.2 TTX18 rebound/LSC "14-16" is above the catalog max 15 (`ttx18_m2`);
  - RXF34/RXF36 m.1 TTX22 "Compression high 7-8 clicks" is above the 0-5 range the same manual describes.

## Guide `ohlins_rxc34_m1_2023` — Betriebsanleitung RXC34 m.1

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-rxc34-m1--00003982.pdf
- Document: Öhlins Betriebsanleitung RXC34 m.1, Art. Nr. 07258-13_1, issued 2023-03-06, German (no English edition found on ohlins.eu)
- Section / page: p. 9 (pressure table), p. 10 (sag), p. 11 (volume spacers), p. 16 (ride modes)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxc34/m1/aluminum-remote` | `damper: otx14_r` | |
| `fork/ohlins/rxc34/m1/carbon-crown-remote` | `damper: otx14_r` | |
| `fork/ohlins/rxc34/m1/carbon-crown-manual` | `damper: otx14_r` | |

Gaps:
- The spacer table has a 130 mm row; the catalog travel options are 100/110/120.
- Negative-chamber spacers (1 ml) have no catalog adjuster.

### Air pressure

Input: rider weight (kg, lb also printed) · Output: psi band (`range`) · no `when` beyond the nodes. The manual also says to check the pressure label on the fork.

| Rider weight (kg) | Rider weight (lbs) | psi |
|---|---|---|
| 50 - 55 | 110 - 121 | 58 - 73 |
| 55 - 60 | 121 - 132 | 63 - 77 |
| 60 - 65 | 132 - 143 | 67 - 82 |
| 65 - 70 | 143 - 154 | 72 - 86 |
| 70 - 75 | 154 - 165 | 76 - 91 |
| 75 - 80 | 165 - 176 | 81 - 95 |
| 80 - 85 | 176 - 187 | 85 - 100 |
| 85 - 90 | 187 - 198 | 90 - 104 |
| 90 - 95 | 198 - 209 | 94 - 109 |
| 95 - 100 | 209 - 220 | 99 - 113 |
| 100 - 105 | 220 - 232 | 103 - 118 |
| 105 - 110 | 232 - 243 | 108 - 122 |
| 110 - 115 | 243 - 254 | 112 - 127 |
| 115 - 120 | 254 - 265 | 117 – 131 |

### Rebound / compression

No click recommendations. The manual describes directions only: clockwise is more damping on the gold
rebound and blue LSC dials, both counted from closed. LSC works only in ride mode 1 (Open).

### Constants / base tune

None.

### SAG

Band 15-25 % of travel (p. 10). Encoding: `sag` `range: [15, 25]`.

### Volume spacers

Positive chamber (8 ml spacers, top cap) and negative chamber (1 ml, dealer-only):

| Stroke (mm) | Positive recommended | Positive max | Negative recommended | Negative max |
|---|---|---|---|---|
| 100 | 1 x 8ml | 4 x 8ml | 4 x 1ml | 7 x 1ml |
| 110 | 3 x 8ml | 5 x 8ml | 4 x 1ml | 7 x 1ml |
| 120 | 2 x 8ml | 5 x 8ml | 4 x 1ml | 7 x 1ml |
| 130 | 1 x 8ml | 4 x 8ml | 4 x 1ml | 7 x 1ml |

`volume_spacers` rows on `travel_mm`: 100 → 1, 110 → 3, 120 → 2. The catalog maxima in the notes (4/5/5)
match ✓.

### Pressure limits

None stated. Catalog has no max ✓.

### Formulas

None.

### Does not fit B3

- Negative-chamber spacers: no catalog adjuster. Leave as a note.

## Guide `ohlins_rxf34_m2_2026` — Owner's Manual RXF34 m.2

### Source

- URL: https://www.ohlins.com/storage/B9AC95E58353CFA82EC9840F30F16E6AD76B61BF05DB8A5B7CDE65BC9E15C8D0/469d00f818d54e0ca34230baa6eaa34e/pdf/media/fa74b243c1a34513a89ddb391dd8a5c7/Owners%20manual%20RXF34%20m2.pdf
- Document: Öhlins Owner's Manual RXF34 m.2, Part No. 07258-11_5, issued 2026-05-18, English
- Section / page: p. 8 (pressure), p. 9 (sag), p. 10 (volume spacers), p. 15 (HSC delivery)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxf34/m2/air-otx18` | `damper: otx18` | single main chamber |

Gaps: the spacer chart depends on the chassis part number (forks with a 130 mm vs 140 mm maximum travel).
The catalog has no option for that.

### Air pressure

Input: rider weight (kg, lb) · Output: psi band · `when: { damper: otx18 }`

| Rider weight (kg) | Rider weight (lbs) | psi |
|---|---|---|
| 50 - 55 | 110 - 121 | 48 - 63 |
| 55 - 60 | 121 - 132 | 53 - 67 |
| 60 - 65 | 132 - 143 | 57 - 72 |
| 65 - 70 | 143 - 154 | 62 - 76 |
| 70 - 75 | 154 - 165 | 66 - 81 |
| 75 - 80 | 165 - 176 | 71 - 85 |
| 80 - 85 | 176 - 187 | 75 - 90 |
| 85 - 90 | 187 - 198 | 80 - 94 |
| 90 - 95 | 198 - 209 | 84 - 99 |
| 95 - 100 | 209 - 220 | 89 - 103 |
| 100 - 105 | 220 - 232 | 93 - 108 |
| 105 - 110 | 232 - 243 | 98 - 112 |
| 110 - 115 | 243 - 254 | 102 - 117 |
| 115 - 120 | 254 - 265 | 107 – 121 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 2 (delivery setting, fully open) | 0 = fully closed, 2 = fully open; catalog `otx18` `hsc` max 2, `dial_ccw` → same, encode as published | `damper: otx18` |

No rebound or LSC recommendation.

### SAG

Band 15-25 % (p. 9).

### Volume spacers

Recommended (factory) count, by chassis:

Forks with max travel 130 mm (FGxxx 34xx 223x):

| Stroke | Recommended | Maximum |
|---|---|---|
| 120 | 4 x 8 ml | 6 x 8 ml |
| 130 | 3 x 8 ml | 5 x 8 ml |

Forks with max travel 140 mm (FGxxx 34xx 233x):

| Stroke | Recommended | Maximum |
|---|---|---|
| 120 | 5 x 8 ml | 7 x 8 ml |
| 130 | 4 x 8 ml | 6 x 8 ml |
| 140 | 3 x 8 ml | 5 x 8 ml |

### Pressure limits

None stated.

### Formulas

None.

### Does not fit B3

- Spacer rows depend on the chassis part number (130 mm-max vs 140 mm-max fork), a second input the
  catalog lacks. Encode the 140 mm-max chart (the only one covering all three catalog travels) keyed by
  `travel_mm`, with a `note` naming the 130 mm-max values (one spacer fewer). The spacers are one size
  (8 ml), so they stay a step count.

## Guide `ohlins_rxf34_rxf36_m1` — Front Fork RXF34/RXF36 Owner's Manual (TTX22 / STX22)

### Source

- URL: https://ohlins.pl/sites/default/files/mtb_rxf34_rxf36_27.5-29-1.pdf (Öhlins document hosted by Öhlins Poland; no longer on ohlins.com)
- Document: Öhlins Front Fork RXF34/RXF36 Owner's Manual / Mounting Instructions, English. No issue date printed.
- Section / page: p. 6 (pressure table, sag), p. 10 (TTX22 HSC), p. 11 (STX22 delivery), p. 13 (setup data)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxf34/m1/air-ttx22` | `damper: ttx22_fork` | catalog has single `pressure` |
| `fork/ohlins/rxf36/m1/air-ttx22` | `damper: ttx22_fork` | catalog has single `pressure` |
| `fork/ohlins/rxf36/m1/air-stx22` | `damper: stx22_fork` | catalog has single `pressure` |

Gaps: the fork has a main and a ramp-up chamber, but the catalog lists one `pressure` (see Does not fit).

### Air pressure — main chamber and ramp-up chamber

Input: rider weight (kg, lb) · Output: psi band per chamber

| Rider weight (kg) | Rider weight (lbs) | Main chamber | Ramp up chamber |
|---|---|---|---|
| 50-60 | 110-132 | 80-90 psi | 160-170 psi |
| 60-70 | 132-154 | 90-100 psi | 170-180 psi |
| 70-80 | 154-176 | 100-110 psi | 180-190 psi |
| 80-90 | 176-198 | 110-120 psi | 190-200 psi |
| 90-100 | 198-220 | 120-130 psi | 200-210 psi |
| 100-110 | 220-243 | 130-140 psi | 210-220 psi |
| 110-120 | 243-265 | 140-150 psi | 220-230 psi |

These main-chamber values are 10 psi higher than the m.2/m.3 table below. The ramp-up values are identical.

### Rebound / compression — setup data

Source direction: from closed ("turn clockwise to fully closed, then count clicks counter-clockwise").

| Target | RXF34/RXF36 TTX22 | RXF36 STX22 |
|---|---|---|
| Rebound | 7-8 clicks | 7-8 clicks |
| Compression low | 7-8 clicks | 7-8 clicks |
| Compression high | 7-8 clicks | — |

Catalog comparison:
- `ttx22_fork` `rebound` and `lsc`: `dial_ccw`, max 8 (estimated from this very table) → same direction,
  encode `range: [7, 8]`.
- `stx22_fork` `rebound` and `compression`: same, `range: [7, 8]`.
- `ttx22_fork` `hsc` "7-8 clicks" contradicts the manual's own HSC text (positions 0-5, delivered at 5) and
  the catalog max 5 → **not encoded**. Use the delivery constant below.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 5 (delivery, fully open) | 0 closed … 5 open; catalog `ttx22_fork` `hsc` max 5 `dial_ccw` → same | `damper: ttx22_fork` |
| `compression` | 7 (delivery) | from closed; catalog `stx22_fork` `compression` → same | `damper: stx22_fork` |
| `rebound` | 7 (delivery) | from closed; same | `damper: stx22_fork` |

The STX22 delivery value of 7 sits inside the 7-8 setup range.

### SAG

Band 10-15 % (p. 6). The "Recommended sag" row in the setup-data table is blank.

### Volume spacers

None. The manual tells riders to contact a service centre for more progression.

### Pressure limits

None stated.

### Formulas

None.

### Does not fit B3

- Two chambers on a catalog node that has one `pressure`. Switch these trims to the catalog's
  `&dual_chamber_air` (main + ramp-up) first (catalog change, R9), then encode both columns as band cells.
  The ramp-up band is a value the rider sets, so it is a rule, not a note.

## Guide `ohlins_rxf36_m2_2023` — Owner's Manual RXF36 m.2 Air/Coil TTX18

### Source

- URL: https://ohlins.com/storage/B799A00056AAEF9DE3E7BAB002F50562A6D1BA21B2998148273DF3D42E6199C0/4def7de90bca493cb2a999f99d34bdbf/pdf/media/fe3f1b241587489f98caf3f73ccd9139/OM_07258-07_7_MI_RXF36_m.2_AirCoil_TTX18.pdf
- Document: Öhlins Owner's Manual RXF36 m.2 Air/Coil TTX18, Part no. 07258-07_7, issued 2023-01-19, English. The YAML's `setup_guide` (00003012) is edition 07258-07_5 (2020-04-30); numbers are identical.
- Section / page: p. 6 (air pressure, sag), p. 8 (coil chart, sag), p. 11 (HSC delivery), p. 13 (setup data)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxf36/m2/air-ttx18` | `damper: ttx18_m2` | catalog single `pressure` |
| `fork/ohlins/rxf36/m2/coil` | `damper: ttx18_m2` | |

Gaps:
- Two air chambers vs one catalog `pressure`.
- Setup data lists air strokes 150-180 mm; the catalog (from the product page) has 140-170.

### Air pressure — main chamber and ramp-up chamber

| Rider weight (kg) | Rider weight (lbs) | Main chamber | Ramp up chamber |
|---|---|---|---|
| 50-60 | 110-132 | 70-80 psi | 160-170 psi |
| 60-70 | 132-154 | 80-90 psi | 170-180 psi |
| 70-80 | 154-176 | 90-100 psi | 180-190 psi |
| 80-90 | 176-198 | 100-110 psi | 190-200 psi |
| 90-100 | 198-220 | 110-120 psi | 200-210 psi |
| 100-110 | 220-243 | 120-130 psi | 210-220 psi |
| 110-120 | 243-265 | 130-140 psi | 220-230 psi |

### Rebound / compression — setup data (RXF36 m.2 TTX18)

Source direction: from closed.

| Target | Value |
|---|---|
| Rebound | 14-16 clicks |
| Compression low | 14-16 clicks |
| Compression high | 3 clicks |

Catalog comparison:
- `ttx18_m2` `rebound` / `lsc`: `dial_ccw`, **max 15**, from the product page "15-fach". Same direction,
  but the range top of 16 exceeds max. Encode `range: [14, 15]` clamped, or fix the max; see Follow-ups.
- `hsc` 3 (max 3) → encode `value: 3`.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 3 (delivery, fully open) | 0 closed … 3 open; same as catalog | `damper: ttx18_m2` |

### Coil spring chart (RXF36 m.2 Coil)

No rider weight, so no lookup rule. Spring rate → tube colour, travel, part number; only the factory spring
below is encoded. The list itself is fitment information for a `note`:

| Spring rate [N/mm] | Tube color | Travel [mm] | Part no |
|---|---|---|---|
| 6.1 | Red (3x) | 130-165 | 18651-01 |
| 7 | Yellow (3x) | 130-165 | 18651-02 |
| 7.9 | Green (3x) | 130-165 | 18651-03 |
| 8.8 | Blue (3x) | 130-165 | 18651-04 |
| 9.7 | White (3x) | 130-165 | 18651-05* |
| 10.6 | Black (3x) | 130-160 | 18651-06 |
| 11.5 | Red, Black, Red | 130-160 | 18651-07 |

\* Standard AM fork. The 9.7 N/mm spring is the factory spring → `spring_rate` `value: 9.7` on
`fork/ohlins/rxf36/m2/coil` (a constant, not rider-dependent). The travel column is a fitment limit: 10.6
and 11.5 cannot run 165 mm.

### SAG

Air 10-15 %; coil 15-20 %. Coil procedure: preload knob to minimum first.

### Volume spacers

None (ramp-up chamber instead).

### Pressure limits

None stated.

### Does not fit B3

- Two chambers vs single catalog `pressure` (same proposal as RXF34/36 m.1).

## Guide `ohlins_rxf36_m3_2026` — Owner's Manual RXF36 m.3 (Air / Coil)

### Source

- URL: https://ohlins.com/storage/F1FD2667BEF6A26936BBE79CBD7BC4023A47B74CEF08518C26294D2B1AFF0A33/24e7fcb03154439ea9ae0b6150bcede7/pdf/media/55239c8bd8da48c19d511823f9b1c5c6/OM_07258-12_4_RXF36%20m3%20air%20front%20fork.pdf
- Document: Öhlins Owner's Manual RXF36 m.3, Part No. 07258-12_4, issued 2026-05-18, English (covers air and coil)
- Section / page: p. 9 (air pressure, sag), p. 12 (coil chart, sag), p. 15 (HSC delivery)
- Retrieved: 2026-10-11
- Older editions:
  - 07258-12_2 (2023-01-19, https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-federgabel-rxf36--00004180.pdf,
    the YAML's air `setup_guide`): same air table, plus a **setup-data click table** (p. 13) that later
    editions dropped.
  - 07258-12_3 (2025-04-04, …00004297, the YAML's coil `setup_guide`): same air table and coil chart as _4,
    no click table.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxf36/m3/air-ttx18` | `damper: ttx18_m3` | catalog single `pressure` |
| `fork/ohlins/rxf36/m3/coil` | `damper: ttx18_m3` | |

Gaps: two air chambers vs one catalog `pressure`.

### Air pressure — main chamber and ramp-up chamber

Identical to `ohlins_rxf36_m2_2023`:

| Rider weight (kg) | Rider weight (lbs) | Main chamber | Ramp up chamber |
|---|---|---|---|
| 50-60 | 110-132 | 70-80 psi | 160-170 psi |
| 60-70 | 132-154 | 80-90 psi | 170-180 psi |
| 70-80 | 154-176 | 90-100 psi | 180-190 psi |
| 80-90 | 176-198 | 100-110 psi | 190-200 psi |
| 90-100 | 198-220 | 110-120 psi | 200-210 psi |
| 100-110 | 220-243 | 120-130 psi | 210-220 psi |
| 110-120 | 243-265 | 130-140 psi | 220-230 psi |

### Rebound / compression — setup data (edition 07258-12_2 only)

Source direction: from closed. Catalog `ttx18_m3`: `rebound` max 16, `lsc` max 16, `hsc` max 3, `dial_ccw`
→ same direction, encode as published.

| Target | Value |
|---|---|
| Rebound | 14-16 clicks |
| Compression low | 14-16 clicks |
| Compression high | 3 clicks |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 3 (delivery, fully open) | 0 closed … 3 open; same as catalog | `damper: ttx18_m3` |

The text says "five positions" next to the 0-3 endpoints, a wording conflict carried in every RXF36 m.2/m.3
edition. The catalog max 3 follows the endpoints.

### Coil spring chart (RXF36 m.3 Coil)

Input: rider weight (kg, single point per spring) · Output: spring rate N/mm

| Spring rate [N/mm] | Tube color | Rider weight (kg) | Part no |
|---|---|---|---|
| 7.0 | Yellow (3x) | 55 | 19622-01 |
| 7.9 | Green (3x) | 64 | 19622-02 |
| 8.8 | Blue (3x) | 72 | 19622-03 |
| 9.7 | White (3x) | 82 | 19622-04* |
| 10.6 | Black (3x) | 91 | 19622-05 |
| 11.5 | Red, Black, Red | 100 | 19622-06 |
| 12.4 | Yellow, Black, Yellow | 109 | 19622-07 |

\* Standard AM fork.

### SAG

Air 10-15 %; coil 15-20 %.

### Volume spacers

None.

### Pressure limits

None stated. Maximum system weight is 135 kg (rider + bike + gear), per editions _2 and _3.

### Does not fit B3

- Two chambers vs single catalog `pressure`.
- Coil chart: one weight **point** per rate, no brackets. Encode `rows` with literal points: `spring_rate`
  takes the nearest point and never interpolates (R3). Do not invent bracket bounds.

## Guide `ohlins_rxf38_m2_2024` — Owner's Manual RXF38 m.2 Air/Coil

### Source

- URL: https://ohlins.com/storage/4D81EA83A21214EDFB4A57331844F3692B56F2CCA1ED9BD1BE95A5CDFE6D1B1E/9bd7e6402a3e42ff93f357c6b15e645b/pdf/media/0377e17f271d4af39560e027d515d36d/Owners%20manual%20RXF38%20m.2.pdf
- Document: Öhlins Owner's Manual RXF38 m.2 Air/Coil, Part No. 07258-17_1, issued 2024-02-29, English
- Section / page: p. 9 (air pressure, sag), p. 12 (coil chart, sag), p. 15 (HSC)
- Retrieved: 2026-10-11
- Older edition: 07258-10_2 (2021-03-16, air only, https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-federgabel-rxf38--00003536.pdf,
  the YAML's `setup_guide`). Same air table and sag; it also states delivery HSC = position 3.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxf38/m2/air` | `damper: ttx18_m2` | `main_chamber_pressure` + `ramp_up_chamber_pressure` ✓ |
| `fork/ohlins/rxf38/m2/coil` | `damper: ttx18_m2` | |

Gaps: none. The catalog already has both chambers. Target ids are the slug of "Main Chamber Pressure" and
"Ramp-up Chamber Pressure"; check that the slugger maps `-` to `_`.

### Air pressure — main chamber and ramp-up chamber

Identical to RXF36 m.2/m.3:

| Rider weight (kg) | Rider weight (lbs) | `main_chamber_pressure` | `ramp_up_chamber_pressure` |
|---|---|---|---|
| 50-60 | 110-132 | 70-80 psi | 160-170 psi |
| 60-70 | 132-154 | 80-90 psi | 170-180 psi |
| 70-80 | 154-176 | 90-100 psi | 180-190 psi |
| 80-90 | 176-198 | 100-110 psi | 190-200 psi |
| 90-100 | 198-220 | 110-120 psi | 200-210 psi |
| 100-110 | 220-243 | 120-130 psi | 210-220 psi |
| 110-120 | 243-265 | 130-140 psi | 220-230 psi |

### Rebound / compression

No click table in any RXF38 edition.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 3 (delivery, fully open; stated in the 2021 edition) | 0 closed … 3 open ("four positions"); catalog `ttx18_m2` max 3 → same | `damper: ttx18_m2` |

### Coil spring chart (RXF38 m.2 Coil)

| Spring rate [N/mm] | Tube color | Rider weight (kg) | Part no |
|---|---|---|---|
| 7.0 | Yellow (3x) | 55 | 19286-01 |
| 7.9 | Green (3x) | 64 | 19286-02 |
| 8.8 | Blue (3x) | 72 | 19286-03 |
| 9.7 | White (3x) | 82 | 19286-04* |
| 10.6 | Black (3x) | 91 | 19286-05 |
| 11.5 | Red, Black, Red | 100 | 19286-06 |
| 12.4 | Yellow, Black, Yellow | 109 | 19286-07 |

\* Standard AM fork.

### SAG

Air 10-15 %; coil 15-20 %. The manual also says to check the pressure recommendations printed on the fork.

### Volume spacers / pressure limits

None stated.

### Does not fit B3

- Coil chart keyed by a weight point (as RXF36 m.3).

## Guide `ohlins_rxf38_m3_2025` — Owner's Manual RXF38 m.3

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-federgabel-rxf38--00004275.pdf
- Document: Öhlins Owner's Manual RXF38 m.3, Part No. 07258-19_1, issued 2025-02-21, English
- Section / page: p. 9 (air pressure, sag), p. 12 (coil chart, sag), p. 15 (HSC)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/rxf38/m3/air` | `damper: ttx18_m3` | both chambers ✓ |
| `fork/ohlins/rxf38/m3/coil` | `damper: ttx18_m3` | |

### Air pressure, coil chart, SAG

Numerically identical to `ohlins_rxf38_m2_2024`:
- the same main/ramp-up table;
- the same coil chart, 7.0-12.4 N/mm against 55/64/72/82/91/100/109 kg, part nos 19286-01…07, 9.7 standard;
- air sag 10-15 %, coil sag 15-20 %.

Encode the same rows with `when: { damper: ttx18_m3 }` on the m3 nodes.

### Constants / base tune

`hsc` 0-3 ("four positions"). This edition states no delivery position, so no constant is sourced for m.3.
The m.2 2021 edition's "delivered at 3" is not carried over.

### Does not fit B3

- Coil chart keyed by a weight point.

## Guide `ohlins_dh38_m2_2025` — Owner's Manual DH38 m.2 (and DH38 m.1, 2020)

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-downhillgabel-dh38--00004274.pdf
- Document: Öhlins Owner's Manual DH38 m.2, Part No. 07258-20_0, issued 2025-02-25, English
- DH38 m.1: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-doppelbrueckengabel-dh38--00002991.pdf, Part No. 07258-06_7, issued 2020-04-29, English
- Section / page: p. 10 (air sag), p. 13 (coil chart, sag) in m.2; p. 10 (sag) in m.1
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/ohlins/dh38/m1/air` | `damper: ttx18_dh38_m1` | SAG only |
| `fork/ohlins/dh38/m2/air` | `damper: ttx18_m3` | SAG only |
| `fork/ohlins/dh38/m2/coil` | `damper: ttx18_m3` | coil chart + SAG |

Gaps:
- Both DH38 manuals describe a main and a ramp-up chamber, but give **no pressure table**. The catalog lists
  one `pressure`.

### Coil spring chart (DH38 m.2 Coil)

| Spring rate [N/mm] | Tube color | Rider weight (kg) | Part no |
|---|---|---|---|
| 7.0 | Yellow (3x) | 55 | 19287-01 |
| 7.9 | Green (3x) | 64 | 19287-02 |
| 8.8 | Blue (3x) | 73 | 19287-03 |
| 9.7 | White (3x) | 82 | 19287-04* |
| 10.6 | Black (3x) | 91 | 19287-05 |
| 11.5 | Red, Black, Red | 100 | 19287-06 |
| 12.4 | Yellow, Black, Yellow | 109 | 19287-07 |

\* Standard AM fork. The 8.8 N/mm row reads 73 kg here vs 72 kg in the RXF36/RXF38 charts, as printed.

### SAG

Air 20-25 % (m.1 and m.2); coil 15-20 % (m.2).

### Rebound / compression / constants

None: no click recommendation and no delivery position.

### Does not fit B3

- Two chambers vs single catalog `pressure` (no values to encode anyway).
- Coil chart keyed by a weight point.

## Guide `ohlins_ttx_air_m1_2020` — TTX Air shock owner's manual (first generation)

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-ttx-air--00002997.pdf
- Document: Öhlins TTX Air owner's manual, Part no. MI_TTX Air_AM_6, issued 2020-09-11, English
- Section / page: p. 3 (max pressure), p. 4 (start pressure, sag), p. 5-6 (HSC positions, delivery), p. 11 (volume reducers)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ohlins/ttx1air/m1/universal` | `damper: ttx1air_m1` | single-tube air spring (MTBM 1950-1955) |
| `shock/ohlins/ttx2air/m1/universal` | `damper: ttx2air_m1` | double-tube air spring |

Gaps:
- The Specialized OEM sag table (article numbers SBC 2045/2046/2047/2065) has no catalog node.
- The production reducer volume depends on the part number; the catalog has no part-number option and no
  spacer adjuster for m1.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `pressure` | 170 psi (start value before setting sag) | — | `damper: ttx1air_m1` / `ttx2air_m1` |
| `hsc` | position 2 "Medium" (delivery) | dial labelled 1 Soft / 2 Medium / P Pedaling platform; catalog `hsc` step max 3 counted from closed doesn't fit → `hsc` becomes categorical [`1`, `2`, `P`] (R9), `value: "2"` | both dampers |

Set sag with the HSC in position 1 or 2, not P. No rebound or LSC recommendation.

### SAG

Aftermarket: 25-35 % of stroke. Specialized OEM, in mm (no catalog node, not encoded):

| Article No | Shock length/stroke (mm) | Recommended SAG (mm) |
|---|---|---|
| SBC 2045 | 210x50 | 13-17 |
| SBC 2046 | 210x52.5 | 13-18 |
| SBC 2047 | 190x42.5 | 11-15 |
| SBC 2065 | 216x57 | 15-19 |

### Volume spacers

Production reducer volume by part number (no count; reducers are sized parts A-F):

| Part no. | Production setting | Additional reducers in box | Maximum reducer volume |
|---|---|---|---|
| MTBM 1950, 1951, 1952, 1953, 1954, 1955 | 2 000 mm3 (A) | B+C | 12 000 mm3 (E) |
| MTBM 1962 & MTBM 1982 | 8 000 mm3 (D) | E+2F | 16 000 mm3 (E+2F) |
| MTBM 1965 & MTBM 1985 | 10 000 mm3 (D+F) | E+2F | 18 000 mm3 (E+3F) |
| MTBM 1969 & MTBM 1989 | 12 000 mm3 (D+2F) | E+2F | 20 000 mm3 (E+4F) |
| SBC 2045, 2047, 2048 | 2 000 mm3 (A) | B | 12 000 mm3 (E) |
| SBC 2046 | 2 000 mm3 (A) | B+D+E | 12 000 mm3 (E) |

Not encodable: there is no catalog spacer adjuster and no part-number option.

### Pressure limits

Max 300 psi (single tube, TTX1Air) / 325 psi (double tube, TTX2Air). The catalog m1 `pressure` has no max.

### Does not fit B3

- The HSC position names (1/2/P) don't fit the catalog's 0-3 step → categorical `hsc` (R9).
- Spacer production volume keyed by part number: no rule until part numbers map to catalog sizes.

## Guide `ohlins_ttx_air_m2_2025` — TTXAir m.2 owner's manual

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-ttx-air--00004276.pdf
- Document: Öhlins Owner's Manual TTXAir m.2, Part no. OM_07258-18, issued 2025-04-17, English
- Section / page: p. 3 (max pressure), p. 4 (start pressure, sag), p. 6 (HSC delivery), p. 7 (PSG), pp. 8-9 (spacers)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ohlins/ttx1air/m2/universal` | `damper: ttx1air_m2` | |
| `shock/ohlins/ttx2air/m2/universal` | `damper: ttx2air_m2` | |

Gaps: the TTX2Air production spacer volume is given by part number (MTBM 2565/2585 vs 2569/2589). The
catalog sizes are not mapped to those part numbers.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `pressure` | 170 psi (start before sag) | — | `damper: ttx1air_m2` / `ttx2air_m2` |
| `hsc` | position 2 "Medium" (delivery) | dial 1 Soft / 2 Medium / P → categorical `hsc` [`1`, `2`, `P`] (R9), `value: "2"` | both dampers |
| `volume_spacers` | 1 (production 2000 mm3, MTBM 255X; 2000 mm3 per spacer; max 5) | — | `damper: ttx1air_m2` |

The TTX2Air m.2 production setting is 10 000 mm3 (MTBM 2565 & 2585; max 16 000 mm3) or 12 000 mm3 (MTBM 2569
& 2589; max 18 000 mm3). At 2000 mm3 per spacer that is 5 or 6 spacers, with maxima of 8 or 9. Not encoded
until part numbers are mapped to catalog sizes.

### SAG

25-35 % of shock stroke.

### Pressure limits

300 psi single tube / 325 psi double tube. The catalog `pressure` has no max for either m.2 shock. The
TTX2Air m.2 product page also says 325 psi.

### Does not fit B3

- HSC position names → categorical `hsc` (R9).
- TTX2Air spacer production volume keyed by part number: no rule until part numbers map to catalog sizes.

## Guide `ohlins_txc_air_2023` — TXC Air owner's manual

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-txc-air--00003880.pdf
- Document: Öhlins Owner's Manual TXC Air, Part no. OM_07258-14, issued 2023-03-09, English
- Section / page: p. 3 (max pressure), p. 4 (start pressure, sag), p. 10 (max spacers)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ohlins/txc1air/universal` | `damper: txc1air` | |
| `shock/ohlins/txc2air/universal` | `damper: txc2air` | |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `pressure` | 200 psi (start before sag) | — | both |
| `ride_mode` | Open (position 1) while setting sag | — | both; procedure, so no rule, `note` only (R9) |

### SAG

20-30 % of shock stroke.

### Volume spacers

The manual gives maxima per stroke only (spacer holder 1 ml plus end-eye 0.7 ml), with no
production/recommended count. Nothing to encode.

### Pressure limits

Max 350 psi (catalog `max: 350` ✓).

## Guide `ohlins_ttx22_m2_2022` — Owner's Manual TTX22m.2

### Source

- URL: https://www.ohlins.eu/download/db/Ohlins_DTC_benutzerhandbuch-oehlins-mtb-ttx22m2-englisch--00003682.pdf
- Document: Öhlins Owner's Manual TTX22m.2, Part No. 07254-05_0, issued 2022-03-21, English
- Section / page: p. 6 (preload max), p. 8 (HSC positions), p. 9 (sag), p. 10 (HSC delivery)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/ohlins/ttx22/m2/piggyback` | `damper: ttx22_m2` | |
| `shock/ohlins/ttx22/m2/side-by-side` | `damper: ttx22_m2` | |
| `shock/ohlins/ttx22/m2/trunnion-piggyback` | `damper: ttx22_m2` | |
| `shock/ohlins/ttx22/m2/trunnion-side-by-side` | `damper: ttx22_m2` | |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | position II "medium" (delivery) | dial I soft / II medium / III hard (pedal platform on some models); catalog `hsc` max 3 from closed doesn't fit → categorical `hsc` [`I`, `II`, `III`] (R9), `value: II` | `damper: ttx22_m2` |

No rebound or LSC numbers. Preload at most 2 full turns (catalog `preload` max 2 ✓). No spring chart.

### SAG

25-35 % of stroke ("depends on bike model").

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `fork/ohlins/rxfdj/m1/air-ttx18` | No owner's manual published; the product page and ohlins.eu list workshop manuals only |
| `shock/ohlins/ttx22/m1/side-by-side` | Discontinued TTX22M; no owner's manual on ohlins.eu or ohlins.com. The TTX22 m.2 manual is not carried over |
| `fork/ohlins/dh38/m1/air`, `fork/ohlins/dh38/m2/air` | partial: SAG band only, no pressure table |

## Catalog changes before encoding (R8, R9)

R8 fixes:
- `ttx18_m2` rebound / LSC max 15 → at least 16 (the "14-16" base tune).
- RXF34/RXF36 m.1 TTX22 "Compression high 7-8": conflicts with the 0-5 range
  in the same manual, so it stays out until resolved.
- Shock `pressure` maxima: TTX1Air 300, TTX2Air 325 psi (m.1 and m.2).

R9 type changes:
- RXF34 m.1, RXF36 m.1/m.2/m.3 and DH38: main + ramp-up chamber adjusters
  (`&dual_chamber_air`) instead of a single `pressure`.
- TTX Air m.1/m.2 `hsc`: categorical [`1`, `2`, `P`]; TTX22 m.2 `hsc`:
  categorical [`I`, `II`, `III`].
- Shock reducer volumes stay a follow-up: categorical configurations once
  part numbers map to catalog sizes.

## Follow-ups

- **Catalog air springs:** RXF34 m.1, RXF36 m.1/m.2/m.3 and DH38 are two-chamber (main + ramp-up) per their
  manuals, but the catalog gives them a single `pressure` (`&air_spring`). Switch them to
  `&dual_chamber_air` before encoding, or encode the main chamber only.
- **`ttx18_m2` max 15** (product page "15-fach") vs the RXF36 m.2 manual's 14-16 click base tune. Either the
  page counts adjustment steps (16 positions = 15 steps) or the manual is generous. Decide before encoding
  (clamp to 15 or raise the max).
- **TTX22 fork HSC** "7-8 clicks" in the RXF34/RXF36 setup data contradicts the 0-5 dial. Not encoded.
- **TTX Air / TTX22 m.2 HSC:** the manuals name 3 positions (1/2/P, I/II/III), but the catalog `hsc` has
  `max: 3`, which implies 4 positions. Re-check the catalog HSC for these shocks.
- **TTX2Air m.2** part numbers MTBM 2565/2585 and 2569/2589: map them to catalog sizes to encode the 5/6
  production spacers.
- **RXF38 m.1** (`ttx18_rxf38_m1`): its manual (07258-09_3, 2023) has the same main/ramp-up table, 10-15 %
  sag and HSC delivery 3. There is no catalog node, so it is not recorded as a guide.
- **Performance Suspension Guide** (ohlins.com): bike-specific base pressure and spacers. Out of scope for
  rider-input rules; it could be linked from notes.
