# SR SUNTOUR — setup guide research

Catalog files: `data/component_presets/fork/suntour.yaml`, `data/component_presets/shock/suntour.yaml`
Researched: 2026-10-12

Catalog ids use the brand slug `sr-suntour` (`fork/sr-suntour/...`). This
file is named after the YAML filename (`suntour`).

## Summary

- **Forks:** the MY26 general fork manual covers every catalog fork with
  three tables:
  1. a **rider weight (kg) → air pressure (psi)** table with one column per
     model group. It also gives a factory pressure and a maximum pressure per
     column;
  2. a **SAG band by fork travel** (% and mm). Its travel brackets overlap at
     their bounds;
  3. **volume spacers by travel**, with a "Factory setting" count and a "Max.
     possible spacers" count per travel (and per wheel size for AION 38X).
- The MY26 numbers are identical to MY25 for every catalog column, except
  that the spacer table adds rows (AURON 36 140 mm, DUROLUX 36X 140 mm,
  AXON 34 Elite) and drops two non-catalog columns.
- **Shocks:** the MY27 general rear-shock manual gives **no rider-weight
  table**. It gives:
  - a SAG band per **shock stroke** (25-35 / 25-30 / 20-25 %);
  - factory, maximum and minimum pressures per family. TRIAIR2 also has a
    reservoir (IFP) chamber;
  - a rebound starting rule: start fully closed (clockwise), then open in
    two-click steps.
- No dial click tables are published for any fork.
- Gaps for B3:
  - value cells with an open end (`< 40`, `85 +`) and an open bracket
    (`95 <`);
  - overlapping travel brackets in the fork SAG table;
  - in-between strokes (52.5 / 57.5 mm) and 27.5 mm in the shock SAG table;
  - a second air chamber (the TRIAIR2 reservoir) the catalog does not model;
  - AXON 34 Elite has spacer data but no `volume_spacers` adjuster;
  - catalog `max` mismatches: AION 36 pressure, AURON 36 spacers.

## Guide `suntour_forks_my26` — SR SUNTOUR General Fork Manual MY26

### Source

- URL: https://www.srsuntour.com/fileadmin/user_upload/Downloads/Consumer/Bike/Owners%20manuals/MY_26_Suspension_Fork_Manuals/MY26_General_Fork_Manual_English_20250930.pdf
  (listed at https://www.srsuntour.com/general-fork-manual-22/my26/)
- Document: SR SUNTOUR General Fork Manual, MY26, English, dated 2025-09-30.
  The catalog's current `setup_guide` is the MY25 edition (2024-06-28). Its
  numbers were compared column by column and are identical, except for the
  spacer differences noted below.
- Section / page: "Air pressure adjust" p. 13, "Setting SAG" p. 14,
  "Air volume adjust" pp. 15–16. The MY25 pages are 14, 13 and 15–16.
- Retrieved: 2026-10-12

### Catalog mapping

Pressure table columns ("< EQ air system forks >"; product pages confirm
"AIR(EQ)" for RAIDON 34 and AXON 34):

| Catalog path | `when:` | Manual column |
|---|---|---|
| `fork/sr-suntour/rux/boost` | — | RUX38 / DUROLUX38 |
| `fork/sr-suntour/durolux-38/standard` | — | RUX38 / DUROLUX38 |
| `fork/sr-suntour/durolux-38/e-bike` | — | DUROLUX38X / AION38X |
| `fork/sr-suntour/aion-38x/boost` | — | DUROLUX38X / AION38X |
| `fork/sr-suntour/durolux-36x/boost` | — | DUROLUX36X / DUROLUX36 / AURON36 |
| `fork/sr-suntour/auron-36/boost` | — | DUROLUX36X / DUROLUX36 / AURON36 |
| `fork/sr-suntour/aion-36/boost` | — | AION36 / ZERON36X / ZERON36 / MOBIE36 / MOBIE34 |
| `fork/sr-suntour/zeron-36/boost` | — | same column |
| `fork/sr-suntour/zeron-36x/boost` | — | same column |
| `fork/sr-suntour/axon-34-werx/werx` | — | AXON34-werx / AXON34-elite |
| `fork/sr-suntour/axon-34-werx/elite` | — | AXON34-werx / AXON34-elite |
| `fork/sr-suntour/axon-34/boost` | — | AXON34 |
| `fork/sr-suntour/raidon-34/boost` | — | RAIDON34 |

The pressure table has no damper, travel or wheel dependence.

Gaps:
- These columns have no catalog node: AION36X, RAIDON34-JR-24"/-20",
  GVX32-(E/S)/NRX32IL-E, and the whole non-EQ "< Air system forks > " tables
  (XCR, NCX, NRX, MOBIE, AXON32, EPIXON32, RAIDON32 …).
- MY25 also printed a non-EQ "AXON34 / RAIDON34" column (40-55 … 100+,
  factory 95 psi, max 130 psi). MY26 dropped it, and the catalog forks are EQ,
  so it is not encoded.
- DUROLUX 38 E-Bike = "DUROLUX38X" in the manual.

### Air pressure — all EQ columns

Input: rider weight (kg only) · Output: psi · `when:` the product paths per column above

| Rider weight (kg) | RUX38 / DUROLUX38 | DUROLUX38X / AION38X | DUROLUX36X / DUROLUX36 / AURON36 | AION36 / ZERON36X / ZERON36 | AXON34-werx / -elite | AXON34 | RAIDON34 |
|---|---|---|---|---|---|---|---|
| < 55 | < 40 | < 40 | 35 - 50 | 50 - 70 | 40 - 55 | 35 - 50 | 35 - 50 |
| 55 - 65 | 40 - 50 | 40 - 50 | 50 - 60 | 70 - 80 | 55 - 65 | 50 - 60 | 50 - 60 |
| 65 - 75 | 50 - 60 | 50 - 60 | 60 - 70 | 80 - 90 | 65 - 75 | 60 - 70 | 60 - 70 |
| 75 - 85 | 60 - 70 | 60 - 70 | 70 - 85 | 90- 100 | 75 - 85 | 70 - 80 | 70 - 85 |
| 85 - 95 | 70 - 85 | 70 - 85 | 85 - 105 | 100 - 125 | 85 - 100 | 80 - 100 | 85 - 105 |
| 95 < | 85 + | 85 + | 105 + | 125 + | 100 + | 100 + | 105 + |

`95 <` means above 95 kg. `90- 100` is printed with that spacing.

Not encoded (no catalog node). AION36X: 40 - 55 / 55 - 65 / 65 - 75 / 75 - 85 /
85 - 100 / 100 +, factory 100 psi, max 130 psi.

### Constants / base tune

Factory air pressure is what the fork ships with, not a rider
recommendation. Proposal: `display_only` note on `pressure`.

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `pressure` (factory) | 70 psi | — | `rux/boost`, `durolux-38/standard` |
| `pressure` (factory) | 75 psi | — | `durolux-38/e-bike`, `aion-38x/boost` |
| `pressure` (factory) | 85 psi | — | `durolux-36x/boost`, `auron-36/boost` |
| `pressure` (factory) | 125 psi | — | `aion-36/boost`, `zeron-36/boost`, `zeron-36x/boost` |
| `pressure` (factory) | 95 psi | — | `axon-34-werx/werx`, `axon-34-werx/elite` |
| `pressure` (factory) | 90 psi | — | `axon-34/boost` |
| `pressure` (factory) | 95 psi | — | `raidon-34/boost` |

The manual says to set SAG with the compression knob OPEN. In catalog terms
that is `compression_mode` = `Open` on `cr3_pcs` / `cr2_pcs` / `r_2cr_pcs`,
as a precondition note.

### SAG

SAG is "of total fork travel", with compression open. As printed:

| Fork travel | SAG (%) | SAG (mm) |
|---|---|---|
| 200 - 180mm | 30 - 35% | 70 - 54mm |
| 180 - 160mm | 25 - 30% | 54 - 40mm |
| 160 - 140mm | 20 - 25% | 40 - 28mm |
| 140 - 120mm | 20 - 25% | 35 - 24mm |
| 120 - 100mm | 15 - 20% | 24 - 15mm |
| 100 - 80mm | 15 - 20% | 20 - 12mm |
| 80 - 63mm | 10 - 15% | 12 - 6mm |

The brackets share their bounds, so catalog travels 180, 160 and 120 sit in
two rows with different bands. The mm column is the upper % × upper travel to
the lower % × lower travel of each row (e.g. 35 % × 200 = 70, 30 % × 180 = 54).
Row 140-120 breaks that pattern (35 mm = 25 % × 140).

Resolution per catalog travel (input `travel_mm`, target `sag`, `range` in %):

| `travel_mm` | Candidate rows | Band(s) |
|---|---|---|
| 200 | 200-180 | 30-35 |
| 180 | 200-180 / 180-160 | 30-35 or 25-30 (ambiguous) |
| 170 | 180-160 | 25-30 |
| 160 | 180-160 / 160-140 | 25-30 or 20-25 (ambiguous) |
| 150 | 160-140 | 20-25 |
| 140 | 160-140 / 140-120 | 20-25 (both agree) |
| 130 | 140-120 | 20-25 |
| 120 | 140-120 / 120-100 | 20-25 or 15-20 (ambiguous) |
| 110 | 120-100 | 15-20 |
| 100 | 120-100 / 100-80 | 15-20 (both agree) |

Proposal: encode the six unambiguous travels. For 180 / 160 / 120, either
pick a half-open convention (`[lower, upper)` puts 180 → 30-35, 160 → 25-30,
120 → 20-25), or encode the union band (180 → 25-35, 160 → 20-30,
120 → 15-25) with a note. This is a data-editor decision (follow-up).

### Volume spacers

Rubber-clip spacers. The **factory setting** is the guide value. The maximum
is shown for comparison with the catalog `max`. Input `travel_mm`, target
`volume_spacers`.

| Catalog path | `when:` | Travel | Factory | Max (manual) |
|---|---|---|---|---|
| `fork/sr-suntour/rux/boost` | `travel_mm: 200` | 200mm | 5 | 7 |
| `fork/sr-suntour/durolux-38/standard`, `/e-bike` | `travel_mm: 180` | 180mm | 2 | 6 |
| same | `travel_mm: 170` | 170mm | 3 | 7 |
| same | `travel_mm: 160` | 160mm | 4 | 8 |
| `fork/sr-suntour/durolux-36x/boost` | `travel_mm: 160` | 160mm | 4 | 9 |
| same | `travel_mm: 150` | 150mm | 5 | 10 |
| `fork/sr-suntour/aion-38x/boost` | `wheel_size: 29`, `travel_mm: 180` | 180mm | 2 | 6 |
| same | `wheel_size: 29`, `travel_mm: 170` | 170mm | 3 | 7 |
| same | `wheel_size: 29`, `travel_mm: 160` | 160mm | 4 | 8 |
| same | `wheel_size: 27.5`, `travel_mm: 170` | 170mm | 1 | 5 |
| same | `wheel_size: 27.5`, `travel_mm: 160` | 160mm | 2 | 6 |
| `fork/sr-suntour/aion-36/boost`, `fork/sr-suntour/zeron-36/boost` | `travel_mm: 160` | 160mm | 3 | 12 |
| same | `travel_mm: 150` | 150mm | 4 | 13 |
| same | `travel_mm: 140` | 140mm | 5 | 14 |
| same | `travel_mm: 130` | 130mm | 6 | 15 |
| same | `travel_mm: 120` | 120mm | 7 | 16 |
| `fork/sr-suntour/auron-36/boost` | `travel_mm: 160` | 160mm | 3 | 4 |
| same | `travel_mm: 150` | 150mm | 4 | 5 |
| same | `travel_mm: 140` | 140mm | 5 | 6 (MY26 only) |
| `fork/sr-suntour/zeron-36x/boost` | `travel_mm: 160` | 160mm | 3 | 9 |
| same | `travel_mm: 150` | 150mm | 4 | 10 |
| same | `travel_mm: 140` | 140mm | 5 | 11 |
| same | `travel_mm: 130` | 130mm | 6 | 12 |
| `fork/sr-suntour/axon-34-werx/werx` (and `/elite`, see gaps) | `travel_mm: 120` | 120mm | 3 | 9 |
| same | `travel_mm: 110` | 110mm | 4 | 10 |
| same | `travel_mm: 100` | 100mm | 5 | 11 |
| `fork/sr-suntour/axon-34/boost` | `travel_mm: 140` | 140mm | 2 | 10 |
| same | `travel_mm: 130` | 130mm | 3 | 11 |
| same | `travel_mm: 120` | 120mm | 4 | 12 |
| same | `travel_mm: 100` | 100mm | 6 | 13 |
| `fork/sr-suntour/raidon-34/boost` | `travel_mm: 140` | 140mm | 1 | 5 |
| same | `travel_mm: 130` | 130mm | 2 | 6 |
| same | `travel_mm: 120` | 120mm | 3 | 7 |
| same | `travel_mm: 100` | 100mm | 5 | 9 |

Manual column headers: SF25-RUX38; SF25-DUROLUX38X / SF25-DUROLUX38;
SF25-DUROLUX36X; SF25-AION38X-29" and -27.5"; SF25-AION36; SF25-AURON36;
SF26-ZERON36X / SF26-MOBIE36; SF25-ZERON36; SF25-AXON 34 Werk [sic] /
SF25-AXON 34 Elite; SF25-AXON 34; SF25-Raidon 34.

Not encoded (no catalog node or option):
- DUROLUX36X 140mm: 6 / 11 (MY26 only; the catalog has 150/160).
- SF26-AION36X: 160mm 7/8, 150mm 8/9, 140mm 8/10, 130mm 8/11, 120mm 8/12.
  MY25 also had 110mm 8/13.
- MOBIE34 columns, Raidon 34 JR 24"/20", GVX32, NRX32IL-E.
- MY25 only: SF24-DUROLUX38-27.5" (resin spacer 3/3, rubber 170mm 1/5,
  160mm 2/6, 150mm 3/6). The catalog DUROLUX 38 is 29" only.

Differences MY25 → MY26 for catalog products:
- AURON 36 gains 140mm 5/6.
- AXON 34 Elite is named explicitly; MY25 had Werx only.
- Every other value is the same.

### Pressure limits

| Catalog path | Manual max | Catalog `max` | Match |
|---|---|---|---|
| `rux/boost` | 105psi | 105 | yes |
| `durolux-38/standard` | 105psi | 105 | yes |
| `durolux-38/e-bike` | 110psi | 110 | yes |
| `aion-38x/boost` | 110psi | 110 | yes |
| `durolux-36x/boost` | 120psi | 120 | yes |
| `auron-36/boost` | 120psi | 120 | yes |
| `aion-36/boost` | **145psi** | **130** | **no** — 130 is the AION36X column |
| `zeron-36/boost` | 145psi | 145 | yes |
| `zeron-36x/boost` | 145psi | 145 | yes |
| `axon-34-werx/werx` | 130psi | 130 | yes |
| `axon-34-werx/elite` | 130psi | 130 | yes |
| `axon-34/boost` | 120psi | 120 | yes |
| `raidon-34/boost` | 130psi | 130 | yes |

No minimum pressure is printed for forks.

### Formulas

None.

### Rebound / compression

No click recommendations, and no click counts in the catalog, so there is no
direction comparison. Coil preload is described (clockwise = more preload),
but no catalog fork is coil.

### Does not fit B3

- **Open-ended values**: `< 40` (upper bound only) and `85 +` (lower bound
  only). The weight bracket `95 <` maps to `95+`, and `< 55` maps to `<55`.
  A value with only one bound needs a schema decision: `range` with one
  missing end, or `display_only`.
- **Overlapping SAG travel brackets**: see the resolution table under SAG.
- **AXON 34 Elite** has a spacer row (MY26) but the catalog trim has no
  `Volume Spacers` adjuster, so it can't be encoded until the adjuster is
  added (max 11).
- Factory pressure is a constant that is not a recommendation. Proposal:
  `display_only`.

## Guide `suntour_shocks_my27` — SR SUNTOUR General Rear Shock Manual MY27

### Source

- URL: https://www.srsuntour.com/fileadmin/user_upload/Downloads/Consumer/Bike/Owners%20manuals/MY_27_Rear_Shock_Manuals/SRS-2602-MY27-General-Rear-Shock-Manual-English-Web_Final.pdf
  (listed at https://www.srsuntour.com/general-rear-shock-manual-22/my27/)
- Document: SR SUNTOUR General Rear Shock Manual, MY27, English (SRS-2602).
  The catalog's current `setup_guide` is the MY19 manual. MY25 and MY26
  editions also exist; differences are noted below.
- Section / page: "Setting SAG and air pressure" p. 7, "Air pressure adjust"
  p. 9, "Rebound damping adjust" p. 10.
- Retrieved: 2026-10-12

### Catalog mapping

| Catalog path | `when:` | Manual column |
|---|---|---|
| `shock/sr-suntour/triair2/3cr` | `damper: triair2_3cr` | TRIAIR2 |
| `shock/sr-suntour/triair2/2cr` | `damper: triair2_2cr` | TRIAIR2 |
| `shock/sr-suntour/triair2/r` | `damper: triair2_r` | TRIAIR2 |
| `shock/sr-suntour/edge-evo/2cr` | `damper: edge_2cr` | EDGE-EVO |
| `shock/sr-suntour/edge-evo/r` | `damper: edge_r` | EDGE-EVO |
| `shock/sr-suntour/edge-evo/r-2cr` | `damper: edge_evo_r_2cr` | EDGE-EVO |
| `shock/sr-suntour/edge-x/2cr` | `damper: edge_2cr` | EDGEX |
| `shock/sr-suntour/edge-x/r` | `damper: edge_r` | EDGEX |
| `shock/sr-suntour/raidon/r` | `damper: raidon_shock_r` | RAIDON |
| `shock/sr-suntour/raidon/lo` | `damper: raidon_shock_lo` | RAIDON |

Gaps: the TRIAIR (first generation) and MB columns have no catalog node. The
TRIAIR2 reservoir (IFP) chamber has no catalog adjuster.

### Air pressure

There is no rider-weight table. Only factory, maximum and minimum pressures
are given (see Constants and Pressure limits).

### Rebound

There is no click table. Source direction: clockwise = slower (more rebound
damping). Starting rule: start fully closed (full clockwise), then open in
two-click increments to taste. No target click is given.

Catalog: `rebound` is `type: step, max: 8` on `edge_r`, `edge_2cr`,
`edge_evo_r_2cr` and `triair2_*`, with no `visualization` or notes stating the
counting origin. The direction cannot be compared, and there is no value to
encode. At most this is a `display_only` note ("start closed, open 2 clicks at
a time"). `raidon_shock_r` has no rebound adjuster.

### Constants / base tune

Factory settings, `display_only`:

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `pressure` (main body, factory) | 180 psi | — | `triair2/*` |
| reservoir (IFP) pressure (factory) | 180 psi | — | `triair2/*`, no catalog target |
| `pressure` (factory) | 110 psi | — | `edge-evo/*`, `edge-x/*`, `raidon/*` |

Not mapped: TRIAIR main 180 / reservoir 190, MB 110.

Set SAG with the compression lever OPEN. In catalog terms that is
`compression_mode` = `Open` on 2CR/3CR dampers, as a precondition note.

### SAG

The overall range is 20 % - 35 %, depending on the stroke (shock travel). As
printed:

| Shock travel | SAG (%) | SAG (mm) |
|---|---|---|
| 75mm | 25 - 35% | 18.75 – 26.25mm |
| 70mm | 25 - 35% | 17.50 - 24.50mm |
| 65mm | 25 - 35% | 16.25 - 22.75mm |
| 60mm | 25 - 35% | 15.00 - 21.00mm |
| 55mm | 25-30% | 13.75 - 16.50mm |
| 50mm | 20 - 25% | 10.00 - 12.50mm |
| 45mm | 20 - 25% | 9.00 - 11.25mm |
| 40mm | 20 - 25% | 8.00 - 10.00mm |
| 35mm | 20 - 25% | 7.00 – 8.75mm |
| 30mm | 20 - 25% | (blank) |

The SAG % cell is merged over rows 75-60 and over rows 50-30. In MY26 the
30mm row reads 6.00 - 7.50mm. MY27 leaves it blank.

Encoding by catalog `size` id (the stroke is the number after `x`; target
`sag`, `range` in %):

| `size` ids | Stroke | Band |
|---|---|---|
| `250x75`, `250x70`, `230x65`, `230x60` | listed | 25-35 |
| `250x72.5`, `250x67.5`, `230x62.5` | between two 25-35 rows | 25-35 |
| `210x55` | listed | 25-30 |
| `210x50`, `190x45`, `190x40`, `170x35`, `170x30` | listed | 20-25 |
| `190x42.5`, `190x37.5`, `170x32.5`, `210x47.5` | between two 20-25 rows | 20-25 |
| `230x57.5` | between 55 (25-30) and 60 (25-35) | ambiguous |
| `210x52.5` | between 50 (20-25) and 55 (25-30) | ambiguous |
| `170x27.5` | below the table | not covered |

These are all `size` option values of the catalog shock products; which
products carry which sizes is in ids.lock.

### Volume spacers

The manual describes air volume spacers (TRIAIR / EDGE) without counts. The
catalog has no `volume_spacers` adjuster for SR SUNTOUR shocks.

### Pressure limits

| Variant | Max | Min | Catalog |
|---|---|---|---|
| TRIAIR2 main body | 300 | — | `pressure` max 300, match |
| TRIAIR2 reservoir (IFP) | 200 | 170 | no adjuster |
| EDGE-EVO main body | 300 | — | max 300, match |
| EDGEX main body | 300 | — | max 300, match |
| RAIDON main body | 300 | — | max 300, match |
| (TRIAIR reservoir, MB: not in catalog) | 240 / 300 | 190 / — | — |

### Formulas

None.

### Does not fit B3

- **Two air chambers:** the TRIAIR2 reservoir (IFP) has its own factory /
  min / max pressure (180 / 170 / 200 psi). It needs a catalog adjuster
  (e.g. `Reservoir Pressure`) before it can be encoded.
- **Stroke as input:** the SAG band depends on stroke, which is only reachable
  through the `size` option id. In-between strokes 52.5 and 57.5 are
  ambiguous, and 27.5 is not covered.
- **Rebound start rule** ("closed, then out in 2-click steps") is a
  procedure, not a value. `display_only` at most.

### Older editions (for reference)

- **MY26** (2025-04-17): same as MY27 except the 30mm row prints
  6.00 - 7.50mm, the MB column is absent, and the SAG % cells are laid out
  the same.
- **MY19** (the current catalog `setup_guide`) is superseded. Its numbers
  differ:
  - SAG is 30-45mm stroke → 15-25 % and 50-75mm stroke → 20-25 %;
  - factory TRIAIR main 180 / reservoir 200, EDGE-TT 200, EDGE 110,
    RAIDON 110;
  - max 300 everywhere, except TRIAIR reservoir 240.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| (none, forks) | Every catalog fork is covered by the MY26 tables |
| `shock/sr-suntour/*` (all) | No rider-weight → pressure table and no click values in MY19, MY25, MY26 or MY27. SAG band and factory constants only (partial) |

Also checked with no setup data: the consumer-download booklets (AXON34,
DUROLUX36, Durolux38, TRIAIR1). They are image-only marketing PDFs with no
text layer and were not read further. Product pages were checked only for
the spring type (AIR(EQ)).

## Follow-ups

- **Catalog AION 36 `max: 130`** conflicts with the MY25/MY26 manual (145
  psi, in the same column as ZERON 36). 130 is the AION36X column. Fix the
  YAML.
- **Catalog AURON 36 volume spacers `max: 5`**: MY26 adds 140mm with max 6.
  Update `max` and the notes ("140mm 6").
- **Catalog AXON 34 Elite** lacks `Volume Spacers`. MY26 names it in the
  Werx column (max 11).
- **Catalog setup_guide URLs** point to MY25 (fork) and MY19 (shock). Newer
  editions are MY26 (fork) and MY27 (shock).
- **Fork SAG brackets** overlap: decide the convention for 180 / 160 / 120 mm.
- **Shock SAG** for strokes 52.5 / 57.5 / 27.5: decide whether to interpolate,
  take the union band, or skip.
- **One-sided values** (`< 40`, `85 +`) need a schema decision.
- **TRIAIR2 reservoir pressure** needs a catalog adjuster before its constants
  and limits can be encoded.
