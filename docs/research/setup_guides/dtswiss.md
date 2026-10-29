# DT Swiss — setup guide research

Catalog files: `data/component_presets/fork/dtswiss.yaml`, `data/component_presets/shock/dtswiss.yaml`
Researched: 2026-10-11

Catalog node paths use the brand slug `dt-swiss` (as in `ids.lock`).

## Summary

- **Forks (F 535 ONE, F 535, F 232 ONE):** the user manuals print a weight → air
  pressure table per travel (bar and psi), a pressure → rebound-click table
  (counted from fully open, same direction as the catalog), the factory APT
  spacer count and the per-travel maximum pressure. No SAG target is printed for
  the forks. Compression: DT Swiss recommends fully open (constant).
- **Shocks (R 535 ONE, R 535, R 232 ONE):** the user manuals print a rider weight
  → air pressure table (one column, no stroke/size dependence), a SAG band of
  20–35 % with riding-style sub-bands (XC 20–25 %, downhill 25–35 %), and the
  maximum pressure. No rebound recommendation.
- Not covered by B3: the fork rebound table carries a temperature correction
  (second-order input), the shock pressure table assumes a mean leverage ratio of
  2.5 (frame-dependent), and the F 535 / F 535 ONE pressure table is keyed by
  "system weight" while the F 232 ONE and shock tables use rider weight with
  gear.
- `setupguide.dtswiss.com` (official interactive setup app) sits behind a
  consent gate and serves no static data; not scraped (see Follow-ups).

## Guide `dtswiss_f535_2023` — F 535 / F 535 ONE 44 mm user manual

### Source

- URL: https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/04/85/7/MAN_FXD10000004857S_WEB_ZZ_001.pdf
- Document: F 535 / F 535 ONE 44 MM User Manual, V2023.05, multilingual (EN section used)
- Section / page: 4.1 Adjusting the air pressure (p. 23), 4.4 Adjusting the compression (p. 26), 4.5 Adjusting the rebound (p. 27), 5.1 APT (p. 28)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dt-swiss/f-535-one/standard` | `damper: incontrol_odl_plushport_2023`, `travel_mm: 120 / 130 / 140 / 150 / 160` | "F 535 ONE" columns |
| `fork/dt-swiss/f-535/standard` | `damper: incontrol_ol_2023`, `travel_mm: 120 / 130 / 140 / 150 / 160` | "F 535" columns |

Gaps: none. Every travel column (120–160 mm) exists as a `travel_mm` option on
both nodes; the catalog only lists 29", the manual's table is not wheel-size
specific.

### Air pressure — F 535 ONE

Input: system weight (kg only; the manual does not define "system weight" in
this section, see Does not fit B3) · Output: bar and psi per travel ·
`when: { damper: incontrol_odl_plushport_2023, travel_mm: … }`. Literal points
at 5 kg steps. Decimal commas in the source (rows 135–150 kg) are written as
dots here.

| System weight (kg) | 120 mm bar | 120 mm psi | 130 mm bar | 130 mm psi | 140 mm bar | 140 mm psi | 150 mm bar | 150 mm psi | 160 mm bar | 160 mm psi |
|---|---|---|---|---|---|---|---|---|---|---|
| 50 | 3.2 | 46 | 2.9 | 42 | 2.6 | 38 | 2.4 | 35 | 2.3 | 33 |
| 55 | 3.7 | 54 | 3.3 | 48 | 3 | 44 | 2.8 | 41 | 2.6 | 38 |
| 60 | 4.1 | 59 | 3.7 | 54 | 3.4 | 49 | 3.2 | 46 | 3 | 44 |
| 65 | 4.6 | 67 | 4.2 | 61 | 3.8 | 55 | 3.6 | 52 | 3.3 | 48 |
| 70 | 5 | 73 | 4.6 | 67 | 4.2 | 61 | 3.9 | 57 | 3.7 | 54 |
| 75 | 5.5 | 80 | 5 | 73 | 4.6 | 67 | 4.3 | 62 | 4 | 58 |
| 80 | 5.9 | 86 | 5.4 | 78 | 5 | 73 | 4.7 | 68 | 4.4 | 64 |
| 85 | 6.4 | 93 | 5.8 | 84 | 5.4 | 78 | 5 | 73 | 4.7 | 68 |
| 90 | 6.8 | 99 | 6.3 | 91 | 5.8 | 84 | 5.4 | 78 | 5.1 | 74 |
| 95 | 7.3 | 106 | 6.7 | 97 | 6.2 | 90 | 5.8 | 84 | 5.4 | 78 |
| 100 | 7.7 | 112 | 7.1 | 103 | 6.6 | 96 | 6.2 | 90 | 5.8 | 84 |
| 105 | 8.2 | 119 | 7.5 | 109 | 7 | 102 | 6.5 | 94 | 6.1 | 88 |
| 110 | 8.6 | 125 | 7.9 | 115 | 7.4 | 107 | 6.9 | 100 | 6.5 | 94 |
| 115 | 9.1 | 132 | 8.4 | 122 | 7.8 | 113 | 7.3 | 106 | 6.8 | 99 |
| 120 | 9.5 | 138 | 8.8 | 128 | 8.1 | 117 | 7.6 | 110 | 7.2 | 104 |
| 125 | 10 | 145 | 9.2 | 133 | 8.5 | 123 | 8 | 116 | 7.5 | 109 |
| 130 | 10.4 | 151 | 9.6 | 139 | 8.9 | 129 | 8.4 | 122 | 7.9 | 115 |
| 135 | 10.9 | 158 | 10 | 145 | 9.3 | 135 | 8.8 | 128 | 8.2 | 119 |
| 140 | 11.3 | 164 | 10.5 | 152 | 9.7 | 141 | 9.1 | 132 | 8.6 | 125 |
| 145 | 11.8 | 171 | 10.9 | 158 | 10.1 | 146 | 9.5 | 138 | 8.9 | 129 |
| 150 | 12.2 | 177 | 11.3 | 164 | 10.5 | 152 | 9.9 | 144 | 9.3 | 135 |
| max. air pressure | 13.6 | 197 | 12.8 | 186 | 12.1 | 175 | 11.3 | 164 | 10.6 | 154 |

### Air pressure — F 535

Input: system weight (kg) · Output: bar and psi per travel ·
`when: { damper: incontrol_ol_2023, travel_mm: … }`. Literal points.

| System weight (kg) | 120 mm bar | 120 mm psi | 130 mm bar | 130 mm psi | 140 mm bar | 140 mm psi | 150 mm bar | 150 mm psi | 160 mm bar | 160 mm psi |
|---|---|---|---|---|---|---|---|---|---|---|
| 50 | 2.8 | 41 | 2.5 | 36 | 2.2 | 32 | 2 | 29 | 1.9 | 28 |
| 55 | 3.3 | 48 | 2.9 | 42 | 2.6 | 38 | 2.4 | 35 | 2.2 | 32 |
| 60 | 3.7 | 54 | 3.3 | 48 | 3 | 44 | 2.8 | 41 | 2.6 | 38 |
| 65 | 4.2 | 61 | 3.8 | 55 | 3.4 | 49 | 3.2 | 46 | 2.9 | 42 |
| 70 | 4.6 | 67 | 4.2 | 61 | 3.8 | 55 | 3.5 | 51 | 3.3 | 48 |
| 75 | 5.1 | 74 | 4.6 | 67 | 4.2 | 61 | 3.9 | 57 | 3.6 | 52 |
| 80 | 5.5 | 80 | 5 | 73 | 4.6 | 67 | 4.3 | 62 | 4 | 58 |
| 85 | 6 | 87 | 5.4 | 78 | 5 | 73 | 4.6 | 67 | 4.3 | 62 |
| 90 | 6.4 | 93 | 5.9 | 86 | 5.4 | 78 | 5 | 73 | 4.7 | 68 |
| 95 | 6.9 | 100 | 6.3 | 91 | 5.8 | 84 | 5.4 | 78 | 5 | 73 |
| 100 | 7.3 | 106 | 6.7 | 97 | 6.2 | 90 | 5.8 | 84 | 5.4 | 78 |
| 105 | 7.8 | 113 | 7.1 | 103 | 6.6 | 96 | 6.1 | 88 | 5.7 | 83 |
| 110 | 8.2 | 119 | 7.5 | 109 | 7 | 102 | 6.5 | 94 | 6.1 | 88 |
| 115 | 8.7 | 126 | 8 | 116 | 7.4 | 107 | 6.9 | 100 | 6.4 | 93 |
| 120 | 9.1 | 132 | 8.4 | 122 | 7.7 | 112 | 7.2 | 104 | 6.8 | 99 |
| 125 | 9.6 | 139 | 8.8 | 128 | 8.1 | 117 | 7.6 | 110 | 7.1 | 103 |
| 130 | 10 | 145 | 9.2 | 133 | 8.5 | 123 | 8 | 116 | 7.5 | 109 |
| 135 | 10.5 | 152 | 9.6 | 139 | 8.9 | 129 | 8.4 | 122 | 7.8 | 113 |
| 140 | 10.9 | 158 | 10.1 | 146 | 9.3 | 135 | 8.7 | 126 | 8.2 | 119 |
| 145 | 11.4 | 165 | 10.5 | 152 | 9.7 | 141 | 9.1 | 132 | 8.5 | 123 |
| 150 | 11.8 | 171 | 10.9 | 158 | 10.1 | 146 | 9.5 | 138 | 8.9 | 129 |
| max. air pressure | 13.2 | 191 | 12.4 | 180 | 11.7 | 170 | 10.9 | 158 | 10.2 | 148 |

### Rebound — pressure → clicks (both dampers)

Input: fork air pressure (bar and psi printed as from–to bands) · Output:
rebound clicks. Source direction: "Rebound clicks (from fully opened)",
clockwise adds damping. Catalog: `incontrol_odl_plushport_2023` and
`incontrol_ol_2023` `rebound`, max 29, notes "Counted from fully open (fastest)"
→ same direction, encode as published. Valid for approx. 25 °C ambient (see
Does not fit B3). Adjacent bands share their boundary value as printed
(e.g. 30–32 / 32–35 psi); decimal commas in the last row written as dots.

| Rebound clicks | F 535 ONE bar from | to | F 535 ONE psi from | to | F 535 bar from | to | F 535 psi from | to |
|---|---|---|---|---|---|---|---|---|
| 10 | 2.1 | 2.2 | 30 | 32 | 1.7 | 1.8 | 25 | 26 |
| 11 | 2.2 | 2.4 | 32 | 35 | 1.8 | 2 | 26 | 29 |
| 12 | 2.4 | 2.6 | 35 | 38 | 2 | 2.2 | 29 | 32 |
| 13 | 2.6 | 3 | 38 | 44 | 2.2 | 2.6 | 32 | 38 |
| 14 | 3 | 3.4 | 44 | 49 | 2.6 | 3 | 38 | 44 |
| 15 | 3.4 | 4 | 49 | 58 | 3 | 3.6 | 44 | 52 |
| 16 | 4 | 4.6 | 58 | 67 | 3.6 | 4.2 | 52 | 61 |
| 17 | 4.6 | 5.3 | 67 | 77 | 4.2 | 4.9 | 61 | 71 |
| 18 | 5.3 | 6.1 | 77 | 88 | 4.9 | 5.7 | 71 | 83 |
| 19 | 6.1 | 6.9 | 88 | 100 | 5.7 | 6.5 | 83 | 94 |
| 20 | 6.9 | 7.9 | 100 | 115 | 6.5 | 7.5 | 94 | 109 |
| 21 | 7.9 | 8.9 | 115 | 129 | 7.5 | 8.5 | 109 | 123 |
| 22 | 8.9 | 10 | 129 | 145 | 8.5 | 9.6 | 123 | 139 |
| 23 | 10 | 12.2 | 145 | 177 | 9.6 | 11.8 | 139 | 171 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression` | 0 (fully open), regardless of rider weight and bike | from fully open (counterclockwise to the stop); catalog notes "Counted from fully open (softest)" → same | `damper: incontrol_odl_plushport_2023` and `damper: incontrol_ol_2023` |
| `compression_mode` | Open (factory-set, "most sensitive") | — | both dampers |
| `volume_spacers` | 1 | count | both nodes |

### SAG

None published for the forks (the manual has no SAG section).

### Volume spacers

One APT spacer fitted as delivered, two more in the box. The manual names the
settings −1 (0 spacers, linear/comfort, light riders), stock (1), +1 (2,
sporty) and +2 (3, aggressive). Maximum three (APT spacer manual V2019.06:
"never mount more than three"); catalog `volume_spacers` max 3 matches.

### Pressure limits

Per travel, as printed (bar / psi): F 535 ONE 120 mm 13.6/197, 130 mm 12.8/186,
140 mm 12.1/175, 150 mm 11.3/164, 160 mm 10.6/154; F 535 120 mm 13.2/191,
130 mm 12.4/180, 140 mm 11.7/170, 150 mm 10.9/158, 160 mm 10.2/148. Catalog
`pressure` max 197 (F 535 ONE) / 191 (F 535) with the per-travel maxima in
`notes` — matches.

### Formulas

None.

### Does not fit B3

- **Temperature correction:** the rebound table is for approx. 25 °C; at 0 °C
  open the rebound by 6 clicks versus the table (open at cold, close at hot).
  A relative offset by temperature, which is no input: `note` on the rebound
  rule (R8 "unchanged").
- **"System weight":** the table's input is labelled "system weight" without a
  definition in §4.1; elsewhere in the manual "system weight" means rider + bike
  + equipment + luggage, which would not match a 50 kg first row. Treat as
  `rider_weight` and add a `note`; see Follow-ups.
- Pressure → rebound uses `input: pressure` with bands; the bands share their
  edges, so half-open brackets `[from, to)` reproduce the table.

## Guide `dtswiss_f232one_2021` — F 232 ONE user manual

### Source

- URL: https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/02/81/9/MAN_FXD10000002819S_WEB_ZZ_001.pdf
- Document: F 232 ONE User Manual, V2021.09, multilingual (EN section used)
- Section / page: 4.1 Adjusting the air pressure (p. 24), 4.3 Adjusting the compression (p. 26), 4.4 Adjusting the rebound (p. 27), 5.1 APT (p. 28)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dt-swiss/f-232-one/standard` | `damper: incontrol_odl_232_2020`, `travel_mm: 100 / 110 / 120` | one table per travel column |

Gaps: none.

### Air pressure

Input: rider weight (rider with equipment, without bike), kg and lbs printed ·
Output: bar and psi per travel · `when: { travel_mm: … }`. Literal points.

| Rider weight (kg) | Rider weight (lbs) | 100 mm bar | 100 mm psi | 110 mm bar | 110 mm psi | 120 mm bar | 120 mm psi |
|---|---|---|---|---|---|---|---|
| 40 | 88 | 2.8 | 41 | 2.7 | 39 | 2.5 | 37 |
| 45 | 99 | 3.3 | 47 | 3.1 | 45 | 2.9 | 42 |
| 50 | 110 | 3.7 | 54 | 3.5 | 51 | 3.3 | 48 |
| 55 | 121 | 4.1 | 60 | 3.9 | 57 | 3.7 | 54 |
| 60 | 132 | 4.5 | 66 | 4.3 | 63 | 4.1 | 60 |
| 65 | 143 | 5.0 | 72 | 4.7 | 69 | 4.5 | 66 |
| 70 | 154 | 5.4 | 78 | 5.1 | 75 | 4.9 | 71 |
| 75 | 165 | 5.8 | 84 | 5.6 | 81 | 5.3 | 77 |
| 80 | 176 | 6.2 | 90 | 6.0 | 87 | 5.7 | 83 |
| 85 | 187 | 6.7 | 97 | 6.4 | 93 | 6.1 | 89 |
| 90 | 198 | 7.1 | 103 | 6.8 | 98 | 6.5 | 94 |
| 95 | 210 | 7.5 | 109 | 7.2 | 104 | 6.9 | 100 |
| 100 | 220 | 7.9 | 115 | 7.6 | 110 | 7.3 | 106 |
| 105 | 232 | 8.4 | 121 | 8.0 | 116 | 7.7 | 112 |
| 110 | 245 | 8.8 | 127 | 8.4 | 122 | 8.1 | 118 |
| max. air pressure | — | 10.5 | 152 | 10.3 | 149 | 10 | 145 |

### Rebound — pressure → clicks

Input: fork air pressure (literal points, bar and psi printed) · Output: rebound
clicks. Source direction: "Rebound klicks (from fully opened)", clockwise adds
damping. Catalog: `incontrol_odl_232_2020` `rebound`, max 25 (estimate), notes
"Counted from fully open (fastest)" → same direction, encode as published.
Valid for approx. 25 °C ambient.

| Pressure (bar) | Pressure (psi) | Rebound clicks |
|---|---|---|
| 2 | 29 | 11 |
| 2.5 | 36 | 12 |
| 3 | 44 | 13 |
| 3.5 | 51 | 15 |
| 4 | 58 | 16 |
| 4.5 | 65 | 17 |
| 5 | 73 | 18 |
| 5.5 | 80 | 20 |
| 6 | 87 | 21 |
| 6.5 | 94 | 22 |
| 7 | 102 | 23 |
| 7.5 | 109 | 24 |
| 8 | 116 | 24 |
| 8.5 | 123 | 25 |
| 9 | 131 | 25 |
| 9.5 | 138 | 25 |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open (factory-set, "most sensitive") | — | `damper: incontrol_odl_232_2020` |
| `volume_spacers` | 2 | count | `fork/dt-swiss/f-232-one/standard` |

The blue compression adjuster (Open mode only) has no recommended setting; the
manual only says fully open (counterclockwise to the stop) is the most
sensitive. Catalog `compression` is `max: ~` and has no stated counting
convention, so nothing is encoded.

### SAG

None published.

### Volume spacers

Two APT spacers fitted as delivered, one more in the box. Settings named in the
manual: −2 (0 spacers, linear/comfort, lighter riders), −1 (1, average rider),
stock (2, sporty), +1 (3, aggressive). Max three; catalog max 3 matches.

### Pressure limits

100 mm 10.5 bar / 152 psi, 110 mm 10.3 / 149, 120 mm 10 / 145. Catalog
`pressure` max 152 with per-travel notes — matches.

### Formulas

None.

### Does not fit B3

- Same temperature correction as the F 535 (0 °C → open 6 clicks versus the
  table). Proposed: `note`.

## Guide `dtswiss_r535_2023` — R 535 / R 535 ONE user manual

### Source

- URL: https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/04/86/2/MAN_CXD10000004862S_WEB_ZZ_001.pdf
- Document: R 535 / R 535 ONE User Manual, V2023.03, multilingual (EN section used)
- Section / page: 4.1 Setting the SAG (p. 14), 4.2 Adjusting the air pressure (p. 15), 4.7 Adjusting the rebound (p. 17)
- Retrieved: 2026-10-11
- Older edition checked: R 535 ONE User Manual V2021.09
  (https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/01/87/3/MAN_CXD10000001873S_WEB_ZZ_001.pdf,
  §5.1–5.2, pp. 18–19) — identical SAG text and identical pressure table.

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dt-swiss/r-535-one/standard-mount` | `damper: r535_one_standard` | all sizes |
| `shock/dt-swiss/r-535-one/trunnion-mount` | `damper: r535_one_trunnion` | all sizes |
| `shock/dt-swiss/r-535/standard-mount` | `damper: r535_standard` | all sizes |
| `shock/dt-swiss/r-535/trunnion-mount` | `damper: r535_trunnion` | all sizes |

Gaps: none; the table has no size or mount dependence.

### Air pressure

Input: rider weight (kg / lbs printed) · Output: bar / psi · no `when:` beyond
the node. Literal points. Table assumes a mean leverage ratio of 2.5.

| Rider weight (kg) | Rider weight (lbs) | bar | psi |
|---|---|---|---|
| 40 | 88 | 9.9 | 143 |
| 45 | 99 | 10.8 | 157 |
| 50 | 110 | 11.8 | 171 |
| 55 | 121 | 12.7 | 184 |
| 60 | 132 | 13.6 | 198 |
| 65 | 143 | 14.6 | 211 |
| 70 | 154 | 15.5 | 225 |
| 75 | 165 | 16.5 | 239 |
| 80 | 176 | 17.4 | 252 |
| 85 | 187 | 18.3 | 266 |
| 90 | 198 | 19.3 | 279 |
| 95 | 210 | 20.2 | 293 |
| 100 | 220 | 21.1 | 307 |
| 105 | 232 | 22.1 | 320 |
| 110 | 245 | 23 | 330 |

### Rebound

No recommendation. The manual only gives the dial range ("around 40 clicks"
standard mount, "22 clicks" trunnion) and that clockwise adds damping.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open (factory-set, "most sensitive") | — | all four dampers |

### SAG

20–35 % of shock stroke (`sag`, `range`). Riding-style sub-bands as printed:
cross country / firmer ride 20–25 %, best downhill performance 25–35 %. They
mix disciplines and firmness and don't map 1:1 (R7), so encode `range: [20, 35]`
with `comfort_at: max` (a firmer rider gets the 20 % end) and name the
sub-bands in the `note`. The
manual's SAG chart plots the 20 % and 35 % lines in mm against the sizes
165×40/190×40 … 205×65/230×65 (graphic only, no printed mm values).

### Volume spacers

Not applicable (no user-changeable spacers in the manual; catalog has none).

### Pressure limits

23 bar / 333 psi. Catalog `pressure` max 333 — matches. Note the table's last
row is 330 psi.

### Formulas

None.

### Does not fit B3

- **Leverage ratio:** the pressure table is valid for a mean leverage ratio of
  2.5 and "can vary considerably" by frame. No catalog input; proposed `note`.
- **SAG riding style:** XC 20–25 % and downhill 25–35 % are `riding_style`
  bands; the overall 20–35 % is the default band.

## Guide `dtswiss_r232one_2021` — R 232 ONE user manual

### Source

- URL: https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/03/02/9/MAN_CXD10000003029S_WEB_ZZ_001.pdf
- Document: R 232 ONE User Manual, V2021.10, multilingual (EN section used)
- Section / page: 4.1 Setting the SAG (p. 16), 4.2 Adjusting the air pressure (p. 17), 4.6 Adjusting the rebound (p. 18)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/dt-swiss/r-232-one/standard-mount` | `damper: r232_one_standard` | all sizes |
| `shock/dt-swiss/r-232-one/trunnion-mount` | `damper: r232_one_trunnion` | all sizes |

Gaps: none.

### Air pressure

Input: rider weight (kg / lbs printed) · Output: bar / psi. Literal points.

| Rider weight (kg) | Rider weight (lbs) | bar | psi |
|---|---|---|---|
| 40 | 88 | 5.7 | 83 |
| 45 | 99 | 6.3 | 92 |
| 50 | 110 | 6.9 | 100 |
| 55 | 121 | 7.5 | 109 |
| 60 | 132 | 8.1 | 117 |
| 65 | 143 | 8.7 | 126 |
| 70 | 154 | 9.2 | 134 |
| 75 | 165 | 9.8 | 142 |
| 80 | 176 | 10.4 | 151 |
| 85 | 187 | 11 | 159 |
| 90 | 198 | 11.6 | 168 |
| 95 | 210 | 12.1 | 176 |
| 100 | 220 | 12.7 | 185 |
| 105 | 232 | 13.3 | 193 |
| 110 | 245 | 13.9 | 201 |

### Rebound

No recommendation (same "around 40 / 22 clicks" wording as the R 535).

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression_mode` | Open (factory-set, "most sensitive") | — | both dampers |

### SAG

20–35 % of stroke; cross country 20–25 %, downhill 25–35 % (same wording as
the R 535). The SAG chart covers 165/40 … 185/55 and 190/40 … 210/55 (graphic
only).

### Volume spacers

Not applicable.

### Pressure limits

17.9 bar / 260 psi. Catalog `pressure` max 260 — matches.

### Formulas

None.

### Does not fit B3

- The manual says the values vary considerably with the frame's chainstay
  characteristics (no leverage figure given). Proposed `note`.

## Guides `dtswiss_f132one_2026` / `dtswiss_f132_2026` — F 132 ONE / F 132 user manuals

### Source

- F 132 ONE: https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/06/17/6/MAN_FXD10000006176S_WEB_ZZ_001.pdf (User Manual V2026.03, multilingual, EN section used; sec. 4.1 p. 45, 4.2 p. 47, 4.3 p. 48)
- F 132: https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/07/78/8/MAN_FXD10000007788S_WEB_ZZ_001.pdf (User Manual V2026.07, sec. 4.1 p. 30)
- Technical manual (F 132 ONE, V2026.03): https://d2a13k6araex7u.cloudfront.net/pmt/00/00/00/00/00/00/00/10/00/00/06/17/7/MAN_FXD10000006177S_WEB_EN_001.pdf (service intervals, fixed volume spacer)
- Retrieved: 2026-10-22

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/dt-swiss/f-132-one/2026/standard` | none | one pressure table, rebound table, `compression_mode: Open` |
| `fork/dt-swiss/f-132/2026/standard` | none | pressure table only; "compression and rebound settings are preset" |

### Air pressure (identical in both manuals)

Input: rider weight (rider with equipment, without bike), kg · Output: bar and
psi, non-e-bike column. 40 kg 58 psi, then +5 kg steps up to 120 kg 178 psi
(4 bar at 40 kg to 12.3 bar at 120 kg). The second, higher e-bike column is not
encoded. Max. air pressure 18 bar / 261 psi.

### Rebound — pressure → clicks (F 132 ONE)

Source direction: "Rebound klicks (from fully opened)", `+` closes the damping.
Literal points, psi column: 29 → 0, 36 → 1, 44 → 1, 51 → 2, 58 → 2, 65 → 3,
73 → 3, 80 → 4, 87 → 4, 94 → 5, 102 → 5, 109 → 6, 116 → 6, 123 → 7, 131 → 7,
138 → 8, 145 → 8, 152 → 9, 160 → 9, 167 → 10, 174 → 10, 181 → 10, 189 → 10.
No temperature correction is printed. Catalog `rebound` is `max: 10`, an
estimate: Rennrad-News and Tour-Magazin state 9 clicks, which contradicts the
manual's own 10-click rows.

### Constants / SAG / spacers

`compression_mode` Open (factory-set, "most sensitive"). No SAG target. The
volume spacer is a fixed part inside the stanchion, no user setting, so
`volume_spacers` is not in the catalog.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| — | Every catalog product is covered by one of the guides above. |

## Catalog changes before encoding (R8, R9)

R8 fixes: none found; the click tables fit the catalog maxima.

R9 type changes: none. `compression: 0` (fully open) and `compression_mode:
Open` use existing adjusters.

## Follow-ups

- `setupguide.dtswiss.com/en/` is DT Swiss's interactive setup guide (linked
  from every manual's §4). The page requires accepting a consent form and loads
  configurations server-side; no static data could be fetched. Check it in a
  browser for numbers that differ from the manuals (e.g. a rebound
  recommendation for the shocks).
- F 535 / F 535 ONE pressure table input "system weight": confirm whether this
  is rider with gear (as in the F 232 ONE table) or rider + bike.
- Pre-2023 F 535 ONE and legacy R 414 / SAB shocks are not in the catalog, so
  their manuals were not transcribed.
