# Cannondale (Lefty) — setup guide research

Catalog files: `data/component_presets/fork/cannondale.yaml` (fork only; there is no `shock/cannondale.yaml`)
Researched: 2026-10-11

## Summary

- Every Lefty owner's manual supplement in the catalog has a table of **rider + gear weight → psi**, printed as single weight points in lb and kg. The Ocho, Ocho 120 and Oliver tables also give **rebound clicks out from closed (slow)**. All rebound columns match the catalog's direction (counted out from fully closed), so they encode as published.
- **SAG:** a published constant per product (25 % / mm per travel; 0 % on the Oliver). Lefty 2.0 gives a mm band per travel.
- **Lefty 2.0 (2016)** has a pressure table that depends on **travel/wheel** (four columns). It has no rebound clicks.
- **Lefty Oliver 40mm (2025)** has **Analog-Bike and E-Bike columns** and is a 40 mm / 700c-only fork. The catalog has neither a 40 mm Oliver nor an e-bike option, so this guide is not encoded.
- The Ocho 120 table prints 209 psi for 230 lb, which exceeds the 200 psi limit printed under the same table.
- Compression: none of the manuals gives a recommended click.

## Guide `cannondale_lefty_ocho_2018` — Lefty Ocho Owner's Manual Supplement

### Source

- URL: https://www.cannondale.com/-/media/files/manual-uploads/manuals/018_%20lefty%20ocho_134923_screen_en.pdf
- Document: Lefty Ocho Owner's Manual Supplement 134923 (2018), English
- Section / page: Specifications p.6, External Adjustments / Recommended Settings p.8, Sag p.9, Rebound p.10 (printed page numbers)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cannondale/lefty-ocho/carbon` | `damper: chamber_ocho_2018` | One table for carbon and alloy, 27.5 and 29 |
| `fork/cannondale/lefty-ocho/alloy` | `damper: chamber_ocho_2018` | Same table |

Gaps: none. Only one travel (100 mm) exists, matching `travel_mm: 100`.

### Air pressure + rebound

Input: rider + gear weight (lb, kg also printed), single points · Output: psi and rebound clicks

Rebound source direction: clicks out from closed (close clockwise toward SLOW, then count counter-clockwise toward FAST). Catalog: `chamber_ocho_2018` `rebound`, `max: 23`, "counted in clicks out from fully closed (slowest)" → same direction, encode as published.

| Rider + gear weight (lb) | Rider + gear weight (kg) | Air pressure (psi) | Rebound (clicks out from closed) |
|---|---|---|---|
| 100 | 45 | 81 | 16 |
| 110 | 50 | 89 | 15 |
| 120 | 55 | 97 | 14 |
| 130 | 59 | 105 | 13 |
| 140 | 64 | 112 | 11 |
| 150 | 68 | 120 | 10 |
| 160 | 73 | 128 | 9 |
| 170 | 77 | 136 | 8 |
| 180 | 82 | 143 | 7 |
| 190 | 86 | 151 | 6 |
| 200 | 91 | 159 | 5 |
| 210 | 95 | 167 | 4 |
| 220 | 100 | 174 | 3 |
| 230 | 105 | 182 | 2 |

(The rebound column skips 12 between 140 and 150 lb, as printed.)

### Constants / base tune

No compression start point. The manual describes only the direction: clockwise / "+" = firmer.

### SAG

Recommended sag 25 %, printed as 25 mm (100 mm travel). Target `sag`: 25 % for all `chamber_ocho_2018` trims.

### Volume spacers

The catalog has no `Volume Spacers` adjuster on the Ocho 100 trims. The manual mentions no Ramp Clamps.

### Pressure limits

Minimum 50 psi / 2.4 bar, maximum 250 psi / 17 bar (p.6). Matches catalog `min: 50`, `max: 250`. Max system weight is 305 lb / 138 kg (rider + all equipment).

## Guide `cannondale_lefty_ocho_120_2021` — Lefty Ocho 120 Owner's Manual

### Source

- URL: https://www.cannondale.com/en-gb/owners-manuals/-/media/files/manual-uploads/my21/021_138227_oms_lefty%20ocho_120_pdfs_021_138227_oms_lefty%20ocho_en.pdf
- Document: Lefty Ocho 120 Owner's Manual 138227 Rev 1 (01/21), English
- Section / page: Specifications p.9, Air Pressure/Rebound Recommendation p.10
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cannondale/lefty-ocho-120/carbon` | `damper: chamber_ocho120_2021` | One table for both travels (`travel_mm: 110`, `travel_mm: 120`) |

Gaps: none.

### Air pressure + rebound

Input: rider weight including riding gear (lb, kg also printed), single points · Output: psi and rebound clicks

Rebound source direction: clicks out from slow (closed). Catalog: `chamber_ocho120_2021` `rebound`, `max: 21`, "counted in clicks out from fully closed (slowest)" → same direction, encode as published.

| Rider weight (lb) | Rider weight (kg) | Air pressure (psi) | Rebound (clicks out from slow) |
|---|---|---|---|
| 120 | 55 | 68 | 17 |
| 130 | 59 | 81 | 16 |
| 140 | 64 | 94 | 15 |
| 150 | 68 | 107 | 14 |
| 160 | 73 | 120 | 13 |
| 170 | 77 | 132 | 11 |
| 180 | 82 | 145 | 10 |
| 190 | 86 | 158 | 9 |
| 200 | 91 | 171 | 8 |
| 210 | 95 | 184 | 7 |
| 220 | 100 | 197 | 6 |
| 230 | 105 | 209 | 5 |

(The rebound column skips 12 between 160 and 170 lb, as printed.)

### Constants / base tune

No compression start point.

### SAG

Recommended sag 25 %: 30 mm at 120 mm travel, 27.5 mm at 110 mm travel.

| Target | Value | `when:` |
|---|---|---|
| `sag` | 25 % (30 mm) | `travel_mm: 120` |
| `sag` | 25 % (27.5 mm) | `travel_mm: 110` |

### Volume spacers

The manual gives no stock Ramp Clamp count. The parts list sells "Lefty Oppo Ramp Clips Qty4" (K51041), which is a pack size, not a fitted count. The "four fitted" note in the catalog comes from BikeRadar (secondary), so it is not recorded as a guide value.

### Pressure limits

- Spec table (p.9): minimum 50 psi / 2.4 bar, maximum 250 psi / 17 bar.
- Pressure-table box (p.10, printed twice): minimum 50 psi / 3.5 bar, maximum 200 psi / 13.75 bar.
- The table's 230 lb row (209 psi) exceeds its own 200 psi limit.
- Catalog: `min: 50`, no `max` (the YAML already notes the conflict). Consistent.

### Does not fit B3

Nothing structural. When encoding, flag the 209 psi row (above the 200 psi limit printed on the same page) with a `note`.

## Guide `cannondale_lefty_oliver_2020` — Lefty Oliver Owner's Manual Supplement (MY21)

### Source

- URL: https://www.cannondale.com/-/media/files/manual-uploads/MY21/137390%20Rev%201%20CD%20OMS%20MY21%20Lefty%20Oliver%20Folder_137390%20Rev%201%20CD%20OMS%20MY21%20Lefty%20Oliver_EU_EN.pdf
- Document: Lefty Oliver Owner's Manual Supplement 137390 Rev 1 (05/20), English
- Section / page: Specifications p.9, Air Pressure/Rebound Recommendation p.10, Rebound p.11
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cannondale/lefty-oliver/carbon` | `damper: oliver`, `travel_mm: 30` | One table for all variants |

Gaps:
- The spec table lists Carbon and Alloy, and travel 30 mm (650b and 700c) and 40 mm (650b). The catalog has only `carbon` with `travel_mm: 30`. There is no alloy trim and no 40 mm option.
- Wheel sizes are printed as 650b / 700c. The catalog uses `wheel_size: 27.5` / `29`.

### Air pressure + rebound

Input: rider + gear weight (lb, kg also printed), single points · Output: psi and rebound clicks

Rebound source direction: clicks out from slow (closed clockwise toward SLOW, counted counter-clockwise toward FAST, p.11). Catalog: `oliver` `rebound`, `max: 10` (estimate), "counted in clicks out from fully closed (slowest)" → same direction, encode as published.

| Rider + gear weight (lb) | Rider + gear weight (kg) | Air pressure (psi) | Rebound (clicks out from slow) |
|---|---|---|---|
| 120 | 55 | 70 | 10 |
| 130 | 59 | 76 | 9 |
| 140 | 64 | 79 | 9 |
| 150 | 68 | 85 | 8 |
| 160 | 73 | 88 | 8 |
| 170 | 77 | 94 | 7 |
| 180 | 82 | 97 | 7 |
| 190 | 86 | 102 | 6 |
| 200 | 91 | 106 | 6 |
| 210 | 95 | 111 | 5 |
| 220 | 100 | 115 | 5 |
| 230 | 105 | 120 | 4 |
| 240 | 109 | 124 | 4 |
| 250 | 114 | 129 | 4 |

### SAG

Recommended sag 0 % / 0 mm (all variants). Target `sag`: 0 %.

### Volume spacers

Ramp Rings, from the p.9 spec table:

| Wheel / travel | Carbon stock | Carbon max | Alloy stock | Alloy max |
|---|---|---|---|---|
| 650b / 30 mm | 3 | 6 | 3 | 6 |
| 650b / 40 mm | 0 | 6 | 0 | 6 |
| 700c / 30 mm | 3 | 6 | 3 | 6 |

Encodable: `volume_spacers` = 3 for `fork/cannondale/lefty-oliver/carbon` `travel_mm: 30` (catalog `max: 6` matches).

### Pressure limits

Minimum 50 psi / 3.5 bar, maximum 200 psi / 13.75 bar. Matches catalog `min: 50`, `max: 200`. Max system weight is 304 lbs / 138 kg.

## Guide `cannondale_lefty_oliver_40mm_2025` — Lefty Oliver (40mm) Owner's Manual (not encodable yet)

### Source

- URL (viewer): https://dorelrl.widen.net/s/vmgmxdwmjn/025_195403-rev-0-cd-oms-lefty-oliver-40mm_en (linked from https://www.cannondale.com/en-us/owners-manuals/lefty). The PDF is downloadable through the viewer's preview link.
- Document: Lefty Oliver (40mm) Owner's Manual 195403 Rev 0 (03/25), English
- Section / page: Specifications p.9, Air Pressure/Rebound Recommendation p.10
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| — | — | No catalog node: the catalog Oliver has only `travel_mm: 30`. This fork is 40 mm and 700c only, in Carbon and Alloy. |

Gaps: a new generation/node (or a `travel_mm: 40` option) and an e-bike option would be needed.

### Air pressure + rebound — Analog-Bike and E-Bike columns

Input: rider + gear weight (lb, kg also printed), single points · Output: psi (bar also printed) and rebound clicks (REB, out from closed/SLOW, same procedure as above)

| Rider + gear weight (lb) | (kg) | Analog psi | Analog bar | Analog REB clicks | E-Bike psi | E-Bike bar | E-Bike REB clicks |
|---|---|---|---|---|---|---|---|
| 120 | 55 | 63 | 4.3 | 11 | 69 | 4.8 | 10 |
| 130 | 59 | 67 | 4.7 | 11 | 74 | 5.1 | 9 |
| 140 | 64 | 72 | 5.0 | 10 | 79 | 5.5 | 9 |
| 150 | 68 | 76 | 5.3 | 9 | 84 | 5.8 | 8 |
| 160 | 73 | 81 | 5.6 | 9 | 89 | 6.1 | 8 |
| 170 | 77 | 85 | 5.9 | 8 | 94 | 6.5 | 7 |
| 180 | 82 | 90 | 6.2 | 8 | 99 | 6.8 | 6 |
| 190 | 86 | 94 | 6.5 | 7 | 104 | 7.1 | 6 |
| 200 | 91 | 99 | 6.8 | 6 | 109 | 7.5 | 5 |
| 210 | 95 | 103 | 7.1 | 6 | 113 | 7.8 | 5 |
| 220 | 100 | 108 | 7.4 | 5 | 118 | 8.2 | 4 |
| 230 | 105 | 112 | 7.7 | 5 | 123 | 8.5 | 3 |
| 240 | 109 | 116 | 8.0 | 5 | 128 | 8.8 | 3 |
| 250 | 114 | 121 | 8.3 | 4 | 133 | 9.2 | 2 |

### SAG / limits

Recommended sag 0 % / 0 mm. Air pressure 50 psi / 3.5 bar to 200 psi / 13.75 bar. Max system weight 330 lbs / 150 kg. The spec table gives no Ramp Ring count; the parts list has "Lefty Iso Ramp Rings" (K53001).

### Does not fit B3

- E-Bike column: the catalog has no e-bike option, so it is not encoded.
- The rebound value 11 exceeds the `oliver` damper's estimated `max: 10`. If this generation is added, it needs its own damper (or the estimate raised to at least 11).

## Guide `cannondale_lefty_2_0_2016` — 2016 Lefty Owner's Manual Supplement

### Source

- URL: https://www.cannondale.com/-/media/files/manual-uploads/manuals/133095%20MY16%20LEFTY%20OMS_EN.pdf
- Document: Lefty Owner's Manual Supplement 133095 (09/15), MY16, English
- Section / page: Recommended Air Pressure p.15
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cannondale/lefty-2-0/pbr` | `damper: lefty_2_2016` + `travel_mm` / `wheel_size` per column | PBR and XLR share the table |
| `fork/cannondale/lefty-2-0/xlr` | same | |

Gaps: the same table also covers Supermax (140/27.5, 160/27.5) and Olaf (100/26). Neither is in the catalog, so those columns are transcribed below but not encoded. The catalog allows `travel_mm: 100/120/130` × `wheel_size: 27.5/29` freely, but the manual has only four combinations: 100/29, 100/27.5, 120/27.5 and 130/27.5. There are no 120/29 or 130/29 columns.

### Air pressure — Lefty 2.0 per travel/wheel

Input: rider weight including gear (lb, kg also printed), single points with open ends · Output: psi · `when: { travel_mm, wheel_size }`

| Rider weight (lb) | (kg) | 100/29 psi | 100/27.5 psi | 120/27.5 psi | 130/27.5 psi |
|---|---|---|---|---|---|
| <120 | <54 | <71 | <71 | 65 | 65 |
| 120 | 54 | 71 | 71 | 71 | 71 |
| 130 | 59 | 79 | 79 | 77 | 77 |
| 140 | 64 | 87 | 87 | 83 | 83 |
| 150 | 68 | 94 | 94 | 90 | 90 |
| 160 | 73 | 102 | 102 | 96 | 96 |
| 170 | 77 | 109 | 109 | 102 | 102 |
| 180 | 82 | 117 | 117 | 109 | 109 |
| 190 | 86 | 125 | 125 | 115 | 115 |
| 200 | 91 | 132 | 132 | 121 | 121 |
| 210 | 95 | 140 | 140 | 128 | 128 |
| 220 | 100 | 147 | 147 | 134 | 134 |
| 230 | 104 | 155 | 155 | 140 | 140 |
| 240 | 109 | 162 | 162 | 147 | 147 |
| >240 | >109 | >162 | >162 | >147 | >147 |

(Note: 230 lb is printed as 104 kg here, against 105 kg in the Ocho manuals.)

Not encoded (no catalog node) — same table:

| Rider weight (lb) | (kg) | Supermax 140/27.5 psi | Supermax 160/27.5 psi | Olaf 100/26 psi |
|---|---|---|---|---|
| <120 | <54 | <56 | <56 | 50 |
| 120 | 54 | 56 | 56 | 55 |
| 130 | 59 | 60 | 60 | 60 |
| 140 | 64 | 62 | 62 | 64 |
| 150 | 68 | 68 | 68 | 68 |
| 160 | 73 | 70 | 70 | 73 |
| 170 | 77 | 72 | 72 | 78 |
| 180 | 82 | 82 | 82 | 82 |
| 190 | 86 | 84 | 84 | 87 |
| 200 | 91 | 90 | 90 | 91 |
| 210 | 95 | 96 | 96 | 96 |
| 220 | 100 | 100 | 100 | 100 |
| 230 | 104 | 105 | 105 | 105 |
| 240 | 109 | 110 | 110 | 110 |
| >240 | >109 | >110 | >110 | 114 |

### Rebound

No click table; the dial is described only by direction ("+" slower, "−" faster). The catalog lists Rebound in `missing_adjustments`.

### SAG

Recommended sag (mm), as printed:

| Column | Sag (mm) | `when:` |
|---|---|---|
| Lefty 2.0 100/29, 100/27.5 | 25-30 | `travel_mm: 100` |
| Lefty 2.0 120/27.5, 130/27.5 | 30-35 | `travel_mm: 120` / `travel_mm: 130` |
| Supermax 140/27.5, 160/27.5 | 40-45 | not in catalog |
| Olaf 100/26 | 30-35 | not in catalog |

The `sag` target is a `range` in mm. The other Lefty guides give %.

### Pressure limits

Minimum 50 psi, maximum 225 psi. Matches catalog `min: 50`, `max: 225`.

### Does not fit B3

- Open-ended rows ("<120 → <71", ">240 → >162") print an inequality, not a value. Proposal: encode the bounded rows as points and the open ends as `display_only` notes, or clamp to the first/last value with a note. The 120/130 mm columns print a real value (65) on the "<120" row.
- Two inputs (rider weight × travel/wheel) are handled with `when: { travel_mm, wheel_size }` per column. That fits B3.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| — | All catalog Lefty nodes have a pressure table. Compression start points are missing for the Ocho and Ocho 120 (the manuals give direction only). |

## Follow-ups

- Lefty Ocho 120 stock Ramp Clamp count: not in the manual, only in BikeRadar. Keep it out of the guide until a Cannondale source states it.
- Lefty Oliver 40 mm (2025, manual 195403): add a catalog generation (700c, `travel_mm: 40`, Carbon/Alloy, rebound ≥ 11). E-bike columns would need an option before they can be encoded.
- Lefty Oliver 2020 Alloy trim and 650b/40 mm variant: not in the catalog.
- Possible newer Ocho / Ocho 120 manual revisions: the Cannondale owner's manual page (checked 2026-10-11) still lists only 134923 and 138227 Rev 1.
