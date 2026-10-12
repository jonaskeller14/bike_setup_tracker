# Manitou — setup guide research

Catalog files: `data/component_presets/fork/manitou.yaml`, `data/component_presets/shock/manitou.yaml`
Researched: 2026-10-11

## Summary

- **Forks:** every catalog fork has a one-page Hayes set-up guide with a full table.
  - The main input is **rider weight**. It is either a bracket (`120-140`, Mezzer G2) or
    a literal point (`120`, `140`, …, `>220`; all other guides).
  - The guides print **one pressure column per travel**. That is a second input
    (`travel_mm`).
  - Weight also drives:
    - rebound (bands or single values),
    - **IRT pressure** (Mezzer Pro G1/G2, Mezzer LT Pro, Mattoc Pro),
    - **IVA position** (Mezzer/Mattoc Expert & Comp, Mastodon, R8, Dorado Expert),
    - the **coil spring rate** (Dorado Comp Coil).
  - Compression starts by **riding style**:
    - Downhill / Enduro / Trail (Mezzer G1);
    - Plush Natural / Mid Mixed / Firm Park (Mezzer G2 Pro);
    - Plush Comfort / Balanced Performance / Firm Support (G2 Expert/LT Comp; the
      2023 guides call these "Maximum Comfort / Increased Support / Maximum Support");
    - Standard / DH Race / Park (Dorado);
    - Aggressive / Compliant tune (Mattoc Pro).
  - **Dorado Pro and Expert** add a third axis, Min / Mid / Max-Progressive. It sets IRT
    pressure (Pro) or IVA position (Expert) together with main pressure.
  - **Offsets:** E-bike/downhill +3–5 psi main and +5–10 psi IRT; trail −3–5 psi main
    and −5–10 psi IRT; Mezzer G1 IRT ±10 psi; Mattoc Pro IRT ±10 %.
- **Counting direction:** every Manitou click guide counts **"ccw from max"**, i.e. from
  fully closed. The catalog dampers count the same way (from closed), so encode as
  published. The exceptions:
  - VTT-6 is a position 1–6, counted cw from minimum. It matches the catalog
    `dial_cw` min 1 / max 6.
  - The Mara PB HSC is counted from open. It matches the catalog `dial_cw`.
- **IRT** is a genuinely separate chamber. The catalog models it as `irt_pressure`, and
  the guides give a value per weight × travel. B3 can express it as its own target.
- **Shocks (Mara):** no weight → pressure chart exists anywhere. The guides give only
  constants for a 170 lb rider (rebound, HSC, LSC), the SAG band and the max pressure.
- **Not covered by B3:**
  - the progression-preference axis (Dorado);
  - **IVA position on trims whose catalog has no IVA adjuster** (Mezzer Expert G1/G2,
    LT Comp, Mattoc Expert/Comp, Mastodon);
  - clock-face rebound on non-detented knobs;
  - "120 mm no IVA" (an IVA "none" state);
  - the travel columns missing for some catalog `travel_mm` values;
  - the riding-style ids.

All PDFs come from the Hayes Performance Systems help center (hayesbicycle.zendesk.com),
the same attachments the catalog links. Retrieved 2026-10-11.

---

## Guide `manitou_mezzer_g2_pro_2025` — Mezzer G2 Pro & LT Pro Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/43742231652503
- Document: Mezzer G2 Pro & LT Pro Set-Up Guide, © Hayes Performance Systems 2025, 2 pages, English
- Section / page: p.1 spring table and damper starts; p.2 technology notes
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mezzer/2026/pro` | `damper: mc2_pro_x_2026`, `travel_mm: 140 \| 150 \| 160 \| 170` | 140–170 columns |
| `fork/manitou/mezzer-lt/pro` | `damper: mc2_pro_x_2026`, `travel_mm: 150 \| 160 \| 170 \| 180 \| 190` | 150–170 columns are shared; 180/190 are "LT ONLY" |

Gaps: none. The 140 column applies only to the Mezzer Pro, whose catalog travel
includes 140; the Mezzer LT Pro starts at 150.

### Air pressure and IRT — per travel

Input: rider weight (lb, kg printed) × `travel_mm` · Output: `pressure` (MAIN) and
`irt_pressure` (IRT), psi, single values

| lbs | Kg | 140 MAIN | 140 IRT | 150 MAIN | 150 IRT | 160 MAIN | 160 IRT | 170 MAIN | 170 IRT | 180 (LT) MAIN | 180 (LT) IRT | 190 (LT) MAIN | 190 (LT) IRT |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120-140 | 54-64 | 40 | 61 | 39 | 59 | 38 | 57 | 37 | 55 | 35 | 53 | 34 | 51 |
| 140-160 | 64-73 | 49 | 74 | 48 | 72 | 47 | 70 | 45 | 68 | 44 | 66 | 42 | 64 |
| 160-180 | 73-82 | 59 | 87 | 57 | 85 | 55 | 83 | 54 | 81 | 52 | 79 | 51 | 77 |
| 180-200 | 82-91 | 68 | 100 | 66 | 98 | 64 | 96 | 62 | 94 | 61 | 92 | 59 | 90 |
| 200-220 | 91-100 | 77 | 113 | 75 | 111 | 73 | 109 | 71 | 107 | 69 | 105 | 67 | 103 |
| 220-240 | 100-110 | 86 | 126 | 84 | 124 | 82 | 122 | 80 | 120 | 77 | 118 | 75 | 116 |
| 240-260 | 110-118 | 95 | 139 | 93 | 137 | 91 | 135 | 88 | 133 | 86 | 131 | 83 | 129 |

The brackets share their end points (120-140 / 140-160), as printed. The encoder needs
the half-open rule.

### Rebound — LSR / HSR

Source direction: "CCW FROM MAX"; the knob is fully cw at max ("zero"). The range strip
reads "MIN 10 – 0 MAX" (LSR) and "8 – 0" (HSR). Catalog `mc2_pro_x_2026`: `lsr` max 10
and `hsr` max 8, "Counted from fully closed" → **same direction, encode as published.**

Input: rider weight

| lbs | Kg | LSR (lo-speed) | HSR (hi-speed) |
|---|---|---|---|
| 120-140 | 54-64 | 9 - 10 | 7 - 8 |
| 140-160 | 64-73 | 8 - 9 | 6 - 8 |
| 160-180 | 73-82 | 7 - 8 | 5 - 7 |
| 180-200 | 82-91 | 6 - 7 | 4 - 6 |
| 200-220 | 91-100 | 4 - 5 | 3 - 6 |
| 220-240 | 100-110 | 3 - 4 | 2 - 5 |
| 240-260 | 110-118 | 2 - 3 | 1 - 4 |

### Compression — riding style

Source direction: "CCW FROM MAX". Ranges: LSC "10 – 0", HSC "8 – 0". Catalog `lsc` max
10 and `hsc` max 8. The catalog notes give no direction; the file header convention is
from closed (`dial_ccw` default) → **same direction.**

| Target | Plush Natural | Mid Mixed | Firm Park |
|---|---|---|---|
| `lsc` | 6-9 | 4-6 | 2-4 |
| `hsc` | 5-7 | 4-6 | 2-4 |

The HSC table header is printed "RECOMMENDED LO-SPEED START SETTING", a copy error. It
sits under the hi-speed section, so it is read as HSC.

### Offsets (riding style / use)

- E-bike or downhill: main +3~4 psi, IRT +5~10 psi.
- Trail: main −3~4 psi, IRT −5~10 psi.

### SAG

20–25 % (forks unweighted when inflating; fill IRT first).

### Pressure limits

Main 120 psi and IRT 150 psi. The catalog states these only in the `notes` text
("Max 120 psi" / "max 150 psi") and has no numeric `max` on `pressure` /
`irt_pressure`. Suggest `max: 120` / `max: 150`.

### Does not fit B3

- There are two air chambers. Each needs its own rule, both keyed on weight × travel.
- The E-bike/downhill and trail offsets are relative to the table value; B3 has no
  "delta" shape. Encode as a `note`, or as style-specific pre-computed rows.
- "Plush Natural / Mid Mixed / Firm Park" need riding-style ids.

---

## Guide `manitou_mezzer_g2_expert_2025` — Mezzer G2 Expert Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/41067689282071
- Document: Mezzer G2 Expert Set-Up Guide, © Hayes Performance Systems 2025, English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mezzer/2026/expert` | `damper: vtt6_mezzer_g2`, `travel_mm: 140 \| 150 \| 160 \| 170` | |

Gaps: the guide gives an IVA position per travel. **The catalog has no IVA adjuster on
this trim** (see the YAML follow-up about the unknown IVA max), so IVA is
`display_only`.

### Air pressure, IVA and rebound

Input: rider weight × `travel_mm`

| lbs | Kg | 140 MAIN | 140 IVA | 150 MAIN | 150 IVA | 160 MAIN | 160 IVA | 170 MAIN | 170 IVA | Rebound (ccw from max) |
|---|---|---|---|---|---|---|---|---|---|---|
| 120-140 | 54-64 | 46 | 4 | 44 | 4 | 44 | 3 | 40 | 3 | 9 - 10 |
| 140-160 | 64-73 | 57 | 4 | 54 | 4 | 55 | 3 | 50 | 3 | 8 - 9 |
| 160-180 | 73-82 | 68 | 4 | 64 | 4 | 65 | 3 | 59 | 3 | 7 - 8 |
| 180-200 | 82-91 | 79 | 4 | 74 | 4 | 75 | 3 | 69 | 3 | 6 - 7 |
| 200-220 | 91-100 | 90 | 4 | 84 | 4 | 85 | 3 | 78 | 3 | 4 - 5 |
| 220-240 | 100-110 | 101 | 4 | 94 | 4 | 96 | 3 | 88 | 3 | 3 - 4 |
| 240-260 | 110-118 | 112 | 4 | 104 | 4 | 106 | 3 | 97 | 3 | 2 - 3 |

The 160 mm column is higher than the 150 mm column in every row, as printed.

Rebound: source "ccw from max", range "12 – 0". Catalog `rebound` max 12, from closed →
**same direction.**

### Compression — VTT-6, riding style

The source header says "CCW FROM MAX". The set-up notes, however, say VTT-6 is set
fully ccw to **position 1 (min)** and counted cw up to 6 (max); the range strip is
"MIN 1 – 6 MAX". The values are absolute positions. Catalog `compression` min 1, max
6, `dial_cw` → **same scale, encode as published.**

| Target | Plush Comfort | Balanced Performance | Firm Support |
|---|---|---|---|
| `compression` | 1 - 2 | 3 - 4 | 5 - 6 |

### Offsets

E-bike or downhill: main +3~4 psi. Trail: main −3~4 psi.

### SAG / limits

SAG 20–25 %. Max main 120 psi (catalog: notes only).

---

## Guide `manitou_mezzer_g2_ltcomp_2025` — Mezzer G2 LT Comp Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/43742211211927
- Document: Mezzer G2 LT Comp Set-Up Guide, © Hayes Performance Systems 2025, English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mezzer-lt/comp` | `damper: abs_plus_mezzer_lt_2026`, `travel_mm: 140 … 190` | all six columns present |

Gaps: IVA has no catalog adjuster, so it is `display_only`.

### Air pressure, IVA and rebound

| lbs | Kg | 140 MAIN | IVA | 150 MAIN | IVA | 160 MAIN | IVA | 170 MAIN | IVA | 180 MAIN | IVA | 190 MAIN | IVA | Rebound (ccw from max) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120-140 | 54-64 | 56 | 3 | 55 | 3 | 54 | 2 | 51 | 2 | 49 | 1 | 46 | 1 | 8 - 10 |
| 140-160 | 64-73 | 67 | 3 | 65 | 3 | 64 | 2 | 61 | 2 | 59 | 1 | 56 | 1 | 7 - 10 |
| 160-180 | 73-82 | 77 | 3 | 76 | 3 | 74 | 2 | 71 | 2 | 68 | 1 | 65 | 1 | 6 - 9 |
| 180-200 | 82-91 | 88 | 3 | 86 | 3 | 84 | 2 | 81 | 2 | 78 | 1 | 74 | 1 | 5 - 8 |
| 200-220 | 91-100 | 98 | 3 | 96 | 3 | 94 | 2 | 91 | 2 | 88 | 1 | 83 | 1 | 4 - 7 |
| 220-240 | 100-110 | 108 | 3 | 106 | 3 | 104 | 2 | 100 | 2 | 97 | 1 | 92 | 1 | 3 - 6 |
| 240-260 | 110-118 | 119 | 3 | 116 | 3 | 114 | 2 | 110 | 2 | 107 | 1 | 102 | 1 | 2 - 5 |

Rebound: "10 – 0", ccw from max. Catalog `rebound` max 10, from closed → **same.**

### Compression — ABS+, riding style

Source "CCW FROM MAX", range "10 – 0". Catalog `compression` max 10, "Counted from fully
closed (firmest)" → **same direction.**

| Target | Plush Comfort | Balanced Performance | Firm Support |
|---|---|---|---|
| `compression` | 6 - 9 | 3 - 6 | 1 - 3 |

### Offsets / SAG / limits

- E-bike or downhill: main +3~5 psi. Trail: main −3~5 psi.
- SAG 20–25 %.
- Max main 120 psi (catalog: notes only).

---

## Guide `manitou_mezzer_pro_2019` — Mezzer Pro Set-Up Guide (Gen 1)

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/43742473560727
- Document: Mezzer Pro Set-Up Guide, HBG part no. 46-37659 Rev A [3/21/2019], English (psi and bar)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mezzer/2019/pro` | `damper: mc2_mezzer_2019`, `travel_mm: 140 … 180` | all five columns present; no wheel-size split |

### Air pressure and IRT — per travel

Input: rider weight as **literal points** (lbs / kg) · Output: `pressure` and
`irt_pressure`, psi [bar]

| lbs | Kg | 140 Main | 140 IRT | 150 Main | 150 IRT | 160 Main | 160 IRT | 170 Main | 170 IRT | 180 Main | 180 IRT |
|---|---|---|---|---|---|---|---|---|---|---|---|
| >220 | >100 | 82 [5.7] | 116 [8.0] | 77 [5.3] | 109 [7.5] | 73 [5.0] | 105 [7.2] | 68 [4.7] | 100 [6.7] | 64 [4.4] | 92 [6.3] |
| 200 | 91 | 75 [5.2] | 107 [7.4] | 70 [4.8] | 101 [7.0] | 66 [4.6] | 97 [6.7] | 62 [4.3] | 91 [6.3] | 58 [4.0] | 85 [5.9] |
| 180 | 82 | 68 [4.7] | 97 [6.7] | 63 [4.3] | 93 [6.4] | 59 [4.1] | 90 [6.2] | 56 [3.9] | 83 [5.7] | 52 [3.6] | 78 [5.4] |
| 160 | 73 | 60 [4.1] | 90 [6.2] | 56 [3.8] | 85 [5.9] | 52 [3.6] | 84 [5.8] | 50 [3.4] | 77 [5.3] | 46 [3.2] | 73 [5.0] |
| 140 | 64 | 52 [3.6] | 84 [5.8] | 49 [3.4] | 77 [5.3] | 46 [3.2] | 76 [5.2] | 44 [3.0] | 71 [4.9] | 41 [2.8] | 67 [4.6] |
| 120 | 54 | 44 [3.0] | 79 [5.4] | 42 [2.9] | 72 [5.0] | 40 [2.8] | 70 [4.8] | 38 [2.6] | 65 [4.5] | 35 [2.4] | 60 [4.1] |

The table is printed heaviest first. These are literal points; the guide says to adjust
up or down to match the rider's weight. Encode as literal-point `rows`, or interpolate.

### Damping — riding style

Source direction: "[OPEN-CLOSED] MIN 10 - 0 MAX", i.e. counted from max/closed. Catalog
`mc2_mezzer_2019`: `rebound` max 10 from closed, `hsc` max 4, `lsc` max 10 (file header:
counted from closed) → **same direction.**

| Target | Downhill | Enduro | Trail |
|---|---|---|---|
| `rebound` (10-0) | 3-6 | 4-7 | 5-8 |
| `hsc` (outer, 4-0) | 1-2 | 2-3 | 3-4 |
| `lsc` (inner, 10-0) | 2-5 | 3-7 | 1-4 |

The rebound is for an average 170 lb [77 kg] rider.

### Offsets

IRT +10 psi [+0.7 bar] for downhill; IRT −10 psi [−0.7 bar] for trail.

### SAG / limits

- SAG 20–25 %, standing with weight 70 % on the pedals and 30 % on the bars.
- Max main 120 psi [8.3 bar] and IRT 200 psi [13.8 bar]. The catalog notes say "max
  120" / "max 200", which matches; there is no numeric max.

---

## Guide `manitou_mezzer_expert_2021` — Mezzer Expert Set-Up Guide (Gen 1)

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/43742488803479
- Document: Mezzer Expert Set-Up Guide, HBG part no. 46-39586 Rev A [5/6/2021], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mezzer/2019/expert` | `damper: vtt6_mezzer_g1`, `travel_mm: 140 … 180` | IVA is display_only (no catalog adjuster) |

### Air pressure and IVA

| lbs | Kg | 140 Air | IVA | 150 Air | IVA | 160 Air | IVA | 170 Air | IVA | 180 Air | IVA |
|---|---|---|---|---|---|---|---|---|---|---|---|
| >220 | >100 | 83 [5.7] | 4 | 79 [5.4] | 4 | 75 [5.2] | 3 | 71 [4.9] | 3 | 67 [4.6] | 2 |
| 200 | 91 | 73 [5.0] | 4 | 69 [4.8] | 4 | 66 [4.6] | 3 | 62 [4.3] | 3 | 59 [4.1] | 2 |
| 180 | 82 | 64 [4.4] | 4 | 60 [4.1] | 4 | 57 [3.9] | 3 | 54 [3.7] | 3 | 51 [3.5] | 2 |
| 160 | 73 | 55 [3.8] | 4 | 52 [3.6] | 4 | 49 [3.4] | 3 | 46 [3.2] | 3 | 43 [3.0] | 2 |
| 140 | 64 | 47 [3.2] | 4 | 44 [3.0] | 4 | 41 [3.8] | 3 | 38 [2.6] | 3 | 36 [2.5] | 2 |
| 120 | 54 | 40 [2.8] | 4 | 37 [2.6] | 4 | 35 [2.4] | 3 | 32 [2.2] | 3 | 30 [2.1] | 2 |

The 140 lb / 160 mm cell is printed "41 [3.8]". 41 psi is 2.8 bar, so the bar value is
a typo. Encode the psi.

### Damping — riding style

- `rebound` (TPC, "MIN 10 - 0 MAX", from closed). Catalog max 10, from closed →
  **same.** Downhill 3-6 · Enduro 4-7 · Trail 5-8 (170 lb rider).
- `compression` (VTT-6, "MIN 1 - 6 MAX" positions). Catalog min 1 / max 6 `dial_cw` →
  **same.** Maximum Comfort 1-2 · Increased Support 3-4 · Maximum Support 5-6.

### SAG / limits

SAG 20–25 % (standing, 70/30). Max 120 psi [8.3 bar].

---

## Guide `manitou_mattoc_pro_2023` — Mattoc Pro Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/14639548710935
- Document: Mattoc Pro Set-Up Guide, HBG part no. 46-41234 Rev 1 [2/10/2023], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mattoc/pro` | `damper: mc2_mattoc_2023`, `travel_mm: 110 … 150` | all five columns present; no wheel-size split |

### Air pressure, IRT and rebound

Input: rider weight (literal points)

| lbs | Kg | 110 MAIN | 110 IRT | 120 MAIN | 120 IRT | 130 MAIN | 130 IRT | 140 MAIN | 140 IRT | 150 MAIN | 150 IRT | Rebound (ccw from max) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120 | 54 | 44 | 59 | 42 | 56 | 42 | 56 | 38 | 51 | 38 | 51 | 14 |
| 140 | 64 | 54 | 74 | 51 | 70 | 52 | 72 | 48 | 65 | 48 | 65 | 12 |
| 160 | 73 | 65 | 90 | 61 | 85 | 62 | 86 | 56 | 78 | 56 | 78 | 10 |
| 180 | 82 | 75 | 101 | 70 | 95 | 71 | 96 | 66 | 88 | 66 | 88 | 8 |
| 200 | 91 | 86 | 124 | 80 | 116 | 81 | 117 | 74 | 107 | 74 | 107 | 6 |
| 220 | 100 | 96 | 141 | 89 | 132 | 91 | 134 | 84 | 123 | 84 | 123 | 4 |
| 240 | 109 | 112 | 150 | 104 | 148 | 106 | 150 | 97 | 138 | 97 | 138 | 2 |

Rebound: "FAST - SLOW 20 - 0", ccw from max. Catalog `rebound` max 20, from closed →
**same.**

### Compression — tune style

Source "ccw from max". Catalog `hsc` max 4 and `lsc` max 10 (from closed) → **same.**

| Target | Aggressive tune | Compliant tune |
|---|---|---|
| `hsc` (outer, 4 - 0) | 1-2 | 4-5 |
| `lsc` (inner, 10 - 0) | 0-5 | 6-10 |

The HSC "Compliant 4-5" **exceeds the printed 4 - 0 range and the catalog `hsc` max 4**.
Clamp it to 4 or flag it (follow-up).

### Offsets

IRT +10 % for more mid/end-stroke support; IRT −10 % for a more linear rate. This is a
relative offset, so it is a `note`.

### SAG / limits

- SAG 20–25 % (standing, 70/30).
- Max main 120 psi and IRT 150 psi; the catalog notes match.
- Inflate IRT first (top of fork), then main (bottom).

---

## Guide `manitou_mattoc_expert_2023` — Mattoc Expert Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/14639542611479
- Document: Mattoc Expert Set-Up Guide, HBG part no. 46-41245 Rev 1 [2/17/2023], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mattoc/expert` | `damper: vtt6_2023`, `travel_mm: 110 … 150` | IVA display_only (no catalog adjuster) |

### Air pressure, IVA and rebound

| lbs | Kg | 110 MAIN | IVA | 120 MAIN | IVA | 130 MAIN | IVA | 140 MAIN | IVA | 150 MAIN | IVA | Rebound (ccw from max) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120 | 54 | 46 | 3 | 44 | 3 | 44 | 2 | 40 | 2 | 40 | 1 | 14 |
| 140 | 64 | 57 | 3 | 54 | 3 | 55 | 2 | 50 | 2 | 50 | 1 | 12 |
| 160 | 73 | 68 | 3 | 64 | 3 | 65 | 2 | 59 | 2 | 59 | 1 | 10 |
| 180 | 82 | 79 | 3 | 74 | 3 | 75 | 2 | 69 | 2 | 69 | 1 | 8 |
| 200 | 91 | 90 | 3 | 84 | 3 | 85 | 2 | 78 | 2 | 78 | 1 | 6 |
| 220 | 100 | 101 | 3 | 94 | 3 | 96 | 2 | 88 | 2 | 88 | 1 | 4 |
| 240 | 109 | 112 | 3 | 104 | 3 | 106 | 2 | 97 | 2 | 97 | 1 | 2 |

Rebound: "20 - 0" from max. Catalog `vtt6_2023` `rebound` max 20, from closed →
**same.**

### Compression — VTT-6, style

Positions "MIN 1 - 6 MAX". Catalog `compression` min 1 / max 6 `dial_cw` → **same.**

| Target | Maximum Comfort | Increased Support | Maximum Support |
|---|---|---|---|
| `compression` | 1-2 | 3-4 | 5-6 |

### SAG / limits

SAG 20–25 %. Max main 120 psi.

---

## Guide `manitou_mattoc_comp_2023` — Mattoc Comp Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/14639496469143
- Document: Mattoc Comp Set-Up Guide, HBG part no. 46-41244 Rev 1 [2/17/2023], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mattoc/comp` | `damper: abs_plus_2023`, `travel_mm: 110 … 150` | IVA display_only; rebound clock face display_only |

### Air pressure and IVA

**Identical to `manitou_mattoc_expert_2023`**: same MAIN and IVA values in every cell,
110–150 mm, weights 120–240.

### Rebound — clock face (not detented)

The knob is fully cw at max. The minimum is ½ turn ccw from max. The values are clock
positions:

| lbs | Kg | Rebound |
|---|---|---|
| 120 | 54 | MIN = 12 O'CLOCK |
| 140 | 64 | 1 O'CLOCK |
| 160 | 73 | 2 O'CLOCK |
| 180 | 82 | 3 O'CLOCK |
| 200 | 91 | 4 O'CLOCK |
| 220 | 100 | 5 O'CLOCK |
| 240 | 109 | MAX = 6 O'CLOCK |

Catalog `rebound` is numerical with no unit; its notes match ("12 o'clock (minimum) to
6 o'clock (maximum)"). Encode as `display_only` with the guide wording, unless the
catalog adopts an hour-hand unit.

### Compression — ABS+, style

Source "ccw from max", range "9 - 0". Catalog `compression` max 9, "Counted from fully
closed" → **same.**

| Target | Maximum Comfort | Increased Support | Maximum Support |
|---|---|---|---|
| `compression` | 6-9 | 3-5 | 2-0 |

"2-0" is printed high → low; encode it as `range` 0–2.

### SAG / limits

SAG 20–25 %. Max main 120 psi.

---

## Guide `manitou_r8_pro_2024` — R8 Pro Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/24504253740951
- Document: R8 Pro Set-Up Guide, © Hayes Performance Systems 2024, English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/r8/pro` | `damper: vtt_pro_x_r8`, `travel_mm: 100` | "100 mm" column |
| `fork/manitou/r8/pro` | `damper: vtt_pro_x_r8`, `travel_mm: 120` | "120 mm" (with IVA) column; "120 mm, NO IVA" alternative |

Gaps: the catalog travel options 80, 90 and 110 have **no column**. For them, only the
SAG band, the limits and rebound (which is weight-only) apply.

### Air pressure, IVA and rebound

| lbs | Kg | 100 MAIN | 100 IVA | 120 MAIN | 120 IVA | 120 NO IVA MAIN | Rebound (ccw from max) |
|---|---|---|---|---|---|---|---|
| 100 | 45 | 50 | 2 | 46 | 1 | 50 | 18 |
| 120 | 54 | 63 | 2 | 56 | 1 | 62 | 16 |
| 140 | 64 | 74 | 2 | 66 | 1 | 73 | 14 |
| 160 | 73 | 85 | 2 | 76 | 1 | 85 | 12 |
| 180 | 82 | 97 | 2 | 87 | 1 | NOT RECCOMENDED | 10 |
| 200 | 91 | 109 | 2 | 97 | 1 | NOT RECCOMENDED | 8 |
| 220 | 100 | 122 | 2 | 108 | 1 | NOT RECCOMENDED | 6 |

- The IVA column for "120 mm, NO IVA" is "-".
- Catalog `iva_position` (min 1, max 3, stepper) exists on this trim, so IVA is
  **encodable** for 100 and 120 mm.
- The "no IVA" state cannot be expressed (min 1). The guide says 120 mm travel is
  "optimized without IVA" and heavier riders benefit from IVA "1". This conflicts with
  the table, which lists IVA 1 for every 120 mm row. Encode the IVA column and add a
  `note` about the no-IVA option.

Rebound: "18 – 0", ccw from max. Catalog `rebound` max 18, from closed → **same.**

### Constants

Open Mode Adjust ("20 – 0", catalog `open_mode_compression` max 20, from closed): there
is no recommended value. Compression Mode (Open/Firm/Lock) is described per terrain:
Open for technical terrain, Firm for flow trails and technical climbs, Lock for smooth
climbs. These are riding-style notes only.

### SAG / limits

SAG **15–20 %**. Max 150 psi [10.3 bar] (catalog: notes only).

---

## Guide `manitou_dorado_pro_2021` — Dorado Pro Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/4404709083799
- Document: Dorado Pro Set-Up Guide, HBG part no. 46-39470 Rev 1 [2/26/2021], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/dorado/pro` | `damper: tpc_plus_dorado_2022` | any `travel_mm` (180/190/203); no travel columns |

Gaps: the table has **no travel axis**. Its third axis is a progression preference
(Min / Mid / Max-Progressive), which has no catalog option.

### Air pressure and IRT — progression preference

Input: rider weight (literal points) · Output: `pressure` (Main) and `irt_pressure`
(IRT), psi [bar]

| lbs | Kg | Min-Prog Main | Min-Prog IRT | Mid-Prog Main | Mid-Prog IRT | Max-Prog Main | Max-Prog IRT |
|---|---|---|---|---|---|---|---|
| >220 | >100 | 70 [4.8] | 90 [6.2] | 75 [5.2] | 110 [7.6] | 80 [5.5] | 155 [10.7] |
| 200 | 91 | 60 [4.1] | 79 [5.4] | 65 [4.5] | 98 [6.8] | 75 [5.2] | 140 [9.7] |
| 180 | 82 | 55 [3.8] | 73 [5.0] | 60 [4.1] | 91 [6.3] | 65 [4.5] | 130 [9.0] |
| 160 | 73 | 50 [3.4] | 67 [4.6] | 55 [3.8] | 84 [5.8] | 60 [4.1] | 120 [8.3] |
| 140 | 64 | 51 [3.1] | 61 [4.2] | 50 [3.4] | 77 [5.3] | 55 [3.8] | 110 [7.6] |
| 120 | 54 | 40 [2.8] | 55 [3.8] | 45 [3.1] | 70 [4.8] | 50 [3.4] | 100 [6.9] |

The 140 lb Min-Progressive Main is printed "51 [3.1]". 3.1 bar is 45 psi, and 51
breaks the monotonic sequence (50 at 160 lb). It is probably a typo for 45. Follow-up:
do not encode 51 without confirmation.

### Damping — riding style

Source "[OPEN-CLOSED] MIN 24 - 0 MAX" and "15 - 0", i.e. counted from max/closed.
Catalog `tpc_plus_dorado_2022`: `rebound` max 24, `hsc` max 15, `lsc` (TPC+ inner) max
15, all from closed → **same.**

| Target | Standard | DH Race | Park |
|---|---|---|---|
| `rebound` (24-0) | 6-10 | 7-12 | 5-9 |
| `hsc` (outer, 15-0) | 10-15 | 6-12 | 4-7 |
| `lsc` (TPC+ inner, 15-0) | 5-10 | 4-7 | 3-5 |

The rebound is for a 170 lb [77 kg] rider.

### SAG / limits

- SAG **20–30 %** (standing, 70/30).
- Max main 120 psi [8.3 bar] and IRT 200 psi [13.8 bar]; the catalog notes match.
- The air cap reads "Recommended air pressure 35-90 psi, max 120 psi".

---

## Guide `manitou_dorado_expert_2020` — Dorado Expert Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/4404701744407
- Document: Dorado Expert Set-Up Guide, HBG part no. 46-39219 Rev 1 [11/2/2020], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/dorado/expert` | `damper: tpc_plus_dorado_2022` | any travel; IVA encodable (`iva_position`, 1–3) |

### Air pressure and IVA — progression preference

| lbs | Kg | Min-Prog Main | IVA | Mid-Prog Main | IVA | Max-Prog Main | IVA |
|---|---|---|---|---|---|---|---|
| >220 | >100 | 89 [6.1] | 1 | 86 [5.9] | 2 | 83 [5.7] | 3 |
| 200 | 91 | 81 [5.6] | 1 | 78 [5.4] | 2 | 75 [5.2] | 3 |
| 180 | 82 | 72 [5.0] | 1 | 69 [4.8] | 2 | 66 [4.6] | 3 |
| 160 | 73 | 62 [4.3] | 1 | 59 [4.1] | 2 | 56 [3.9] | 3 |
| 140 | 64 | 51 [3.5] | 1 | 48 [3.3] | 2 | 45 [3.1] | 3 |
| 120 | 54 | 41 [2.8] | 1 | 38 [2.6] | 2 | 35 [2.4] | 3 |

IVA 1 means more volume (more linear) and 3 means less volume (more progressive). This
matches the catalog `iva_position` notes.

### Damping — riding style

The values are **identical to Dorado Pro**:
- rebound 6-10 / 7-12 / 5-9;
- HSC 10-15 / 6-12 / 4-7;
- TPC+ 5-10 / 4-7 / 3-5 (Standard / DH Race / Park).

Same direction as the catalog.

### SAG / limits

SAG 20–30 %. Max 120 psi [8.3 bar].

---

## Guide `manitou_dorado_comp_2021` — Dorado Comp Set-Up Guide (coil)

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/4404709071767
- Document: Dorado Comp Set-Up Guide, HBG part no. 46-39362 Rev 1 [1/12/2021], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/dorado/comp-coil` | `damper: abs_plus_dorado_2022` | spring rate, rebound, compression |

### Coil spring rate

Input: rider weight (lb, kg) · Output: `spring_rate` lb/in (kg/cm printed)

| lbs | Kg | Rate | lb/in [kg/cm] | Stripe colour | Service kit |
|---|---|---|---|---|---|
| >225 | >102 | XX-Firm | 52 [9.3] | Black | 141-38380-K032 |
| 200-225 | 91-102 | X-Firm | 45 [8.0] | Yellow | 141-38380-K031 |
| 175-200 | 79-91 | Firm | 40 [7.1] | Red | 141-38380-K030 |
| 150-175 | 68-79 | Medium | 35 [6.2] | Blue | 141-38380-K029 |
| 125-150 | 57-68 | Soft | 30 [5.3] | Green | 141-38380-K026 |
| <125 | <57 | X-Soft | 25 [4.5] | White | 141-38380-K041 |

The factory spring is "Medium" (35). This matches the catalog note ("ships with the
Medium (35 lb/in)"). The preload adjuster has no values.

### Damping — riding style

Source "[OPEN-CLOSED] MIN 20 - 0 MAX". Catalog `abs_plus_dorado_2022`: `rebound` max 20
and `compression` max 20, from closed → **same.**

| Target | Standard | DH Race | Park |
|---|---|---|---|
| `rebound` | 6-10 | 6-10 | 4-8 |
| `compression` (ABS+) | 13-17 | 9-13 | 6-10 |

### SAG

20–30 % (standing). Preload may be added to reduce sag.

---

## Guide `manitou_mastodon_pro_2023` — Mastodon Pro Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/17493411154967
- Document: Mastodon Pro Set-Up Guide, HBG part no. 46-41494 Rev 1 [6/14/2023], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mastodon/pro` | `damper: vtt6_2023`, `travel_mm: 80 \| 100 \| 120 \| 130 \| 140 \| 150 \| 160` | columns present |

Gaps:
- The catalog travel options 90 and 110 have **no column**.
- The catalog has **no IVA adjuster** on Mastodon (IVA → display_only). The YAML notes
  that the max IVA is unknown; this guide shows IVA values up to 5.

### Air pressure, IVA and rebound

| lbs | Kg | 80 MAIN | IVA | 100 MAIN | IVA | 120 MAIN | IVA | 130 MAIN | IVA | 140 MAIN | IVA | 150 MAIN | IVA | 160 MAIN | IVA | Rebound (ccw from max) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120 | 54 | 70 | 5 | 63 | 4 | 54 | 3 | 54 | 2 | 50 | 2 | 51 | 1 | 49 | 1 | 14 |
| 140 | 64 | 83 | 5 | 75 | 4 | 65 | 3 | 65 | 2 | 60 | 2 | 62 | 1 | 59 | 1 | 12 |
| 160 | 73 | 97 | 5 | 88 | 4 | 76 | 3 | 76 | 2 | 71 | 2 | 73 | 1 | 69 | 1 | 10 |
| 180 | 82 | 111 | 5 | 100 | 4 | 87 | 3 | 87 | 2 | 81 | 2 | 83 | 1 | 79 | 1 | 8 |
| 200 | 91 | 124 | 5 | 113 | 4 | 98 | 3 | 98 | 2 | 91 | 2 | 93 | 1 | 89 | 1 | 6 |
| 220 | 100 | 138 | 5 | 125 | 4 | 110 | 3 | 110 | 2 | 102 | 2 | 104 | 1 | 98 | 1 | 4 |
| 240 | 109 | 150 | 5 | 138 | 4 | 121 | 3 | 121 | 2 | 112 | 2 | 114 | 1 | 109 | 1 | 2 |

Rebound: "20 - 0". Catalog `vtt6_2023` `rebound` max 20, from closed → **same.**

### Compression — VTT-6

Positions 1–6 (`dial_cw`) → **same.** Maximum Comfort 1-2 · Increased Support 3-4 ·
Maximum Support 5-6.

### SAG / limits

SAG 20–25 %. Max main 150 psi (catalog: notes "Max 150 psi").

---

## Guide `manitou_mastodon_comp_2023` — Mastodon Comp Set-Up Guide

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/17493359414167
- Document: Mastodon Comp Set-Up Guide, HBG part no. 46-41495 Rev 1 [6/15/2023], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/manitou/mastodon/comp` | `damper: abs_plus_2023`, `travel_mm: 80 \| 100 \| 120 \| 130 \| 140` | 90/110 have no column; IVA display_only; rebound clock face display_only |

### Air pressure and IVA

| lbs | Kg | 80 MAIN | IVA | 100 MAIN | IVA | 120 MAIN | IVA | 130 MAIN | IVA | 140 MAIN | IVA | Rebound |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 120 | 54 | 79 | 5 | 70 | 4 | 59 | 3 | 59 | 2 | 54 | 2 | MIN = 12 O'CLOCK |
| 140 | 64 | 93 | 5 | 83 | 4 | 71 | 3 | 70 | 2 | 65 | 2 | 1 O'CLOCK |
| 160 | 73 | 108 | 5 | 96 | 4 | 83 | 3 | 82 | 2 | 75 | 2 | 2 O'CLOCK |
| 180 | 82 | 123 | 5 | 110 | 4 | 95 | 3 | 94 | 2 | 86 | 2 | 3 O'CLOCK |
| 200 | 91 | 138 | 5 | 124 | 4 | 106 | 3 | 105 | 2 | 97 | 2 | 4 O'CLOCK |
| 220 | 100 | 150 | 5 | 137 | 4 | 118 | 3 | 117 | 2 | 108 | 2 | 5 O'CLOCK |
| 240 | 109 | - | - | 150 | 4 | 130 | 3 | 129 | 2 | 119 | 2 | MAX = 6 O'CLOCK |

The 240 lb / 80 mm cell is "-" (no recommendation; the pressure would exceed 150).

### Compression — ABS+

"9 - 0", from max. Catalog `compression` max 9, from closed → **same.** Maximum Comfort
6-9 · Increased Support 3-5 · Maximum Support 2-0 (encode as 0–2).

### SAG / limits

SAG 20–25 %. Max main 150 psi.

---

## Guide `manitou_mara_pb_2024` — Mara Pro Set-Up Guide (Gen 2 piggyback)

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/28476110600727
- Document: Mara Pro Set-Up Guide, © Hayes Performance Systems 2024, English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/manitou/mara/2024/pro-piggyback` | `damper: mara_pb_g2` | constants |
| `shock/manitou/mara/2024/pro-piggyback-dh` | `damper: mara_pb_dh_g2` | same constants (platform not included) |

### Constants / base tune ("recommended settings based on 170 lb rider")

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `rebound` | 6 ("MAX -6") | from closed (guide: rebound counted from closed, ccw) | both dampers |
| `hsc` | 3 (Aggressive tune "+3"); 1 (Compliant tune "+1") | from open (guide: "counted from Open (Clockwise)") | both |
| `lsc` | 10 (Aggressive "-10"); 15 (Compliant "-15") | from closed | both |

Catalog direction:
- `rebound` (max 12) and `lsc` (max 30) count from closed.
- `hsc` (max 6) is `dial_cw`, counted from fully open.

→ **Same direction for all, encode as published.**

The aggressive/compliant pairs need a riding-style split. Otherwise, encode the HSC and
LSC as `range` 1–3 and 10–15.

### SAG

Use the frame maker's figure. If none is available, 25–30 % is a good start.

### Pressure limits

Max 350 psi, which matches the catalog `pressure` max 350. Raise the pressure in 75 psi
steps while cycling, which matches the catalog note. Change in 3 psi / 1 volume-ring
steps.

### Does not fit B3

There is no weight → pressure table at all. Only constants for a single 170 lb rider
are given.

---

## Guide `manitou_mara_il_2024` — Mara Inline Pro / Pro XC / Comp Set-Up Guides (Gen 2)

### Source

- URLs:
  - Inline Pro: https://hayesbicycle.zendesk.com/hc/article_attachments/25871616439319
  - Inline Pro XC: https://hayesbicycle.zendesk.com/hc/article_attachments/25871600341655
  - Inline Comp: https://hayesbicycle.zendesk.com/hc/article_attachments/25871643572375
- Document: three one-page set-up guides, © Hayes Performance Systems 2024, English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/manitou/mara/2024/pro-inline` | `damper: ipa_pro_g2` | rebound constant |
| `shock/manitou/mara/2024/pro-inline-xc` | `damper: ipa_xc_g2` | rebound constant |
| `shock/manitou/mara/2024/comp-inline` | `damper: ipa_comp_g2` | rebound constant (turns) |

### Constants (170 lb rider)

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `rebound` | 7 ("-7", 17 clicks available) | counted out from max (clockwise adds damping) | `damper: ipa_pro_g2`, `damper: ipa_xc_g2` |
| `rebound` | 0.5 turn ("- 1/2 turn", 360° available) | out from max | `damper: ipa_comp_g2` |

Catalog:
- `ipa_pro_g2` and `ipa_xc_g2` `rebound` are max 17, "Clockwise adds rebound damping".
  They have no explicit from-closed note, but the file convention counts from closed.
  "-7" means 7 clicks out from max → **same direction.**
- `ipa_comp_g2` `rebound` is numerical turns, max 1. Its zero end is not stated in the
  catalog. 0.5 is the midpoint either way.

IPA lever (target `ipa_compression`), described per terrain only:
- Aggressive Descend: plush, aggressive terrain.
- Trail Control: smooth flow, berms.
- Technical Climb: moderate platform.
- Aggressive Climb: firmest.
- The XC lever has three positions: Descend / Trail-Technical Climb / Climb.

These are riding-style notes; there are no rider-weight values.

### SAG / limits

- SAG 20–30 % (consult the frame maker).
- Max 350 psi, which matches the catalog. The Comp guide prints "[10.3 bar?]" after
  350 psi, a leftover; 350 psi is about 24 bar. Ignore the bar value.

---

## Guide `manitou_mara_pb_2019` — Mara Pro Set-Up Guide (Gen 1)

### Source

- URL: https://hayesbicycle.zendesk.com/hc/article_attachments/360066638914
- Document: Mara Pro Set-Up Guide, HBG part no. 46-38278 Rev B [2020.4.20], English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/manitou/mara/2019/pro-piggyback` | `damper: mara_pb_g1` | constants |

### Constants (170 lb rider)

| Target | Value | Direction |
|---|---|---|
| `rebound` | 5 ("MAX -5") | from closed (range "MIN 12 - 0 MAX") |
| `hsc` | 3 ("MIN +3") | from open (range "MIN 0 - 6 MAX") |
| `lsc` | 15 ("MAX-15") | from closed (range "MIN 24 - 0 MAX") |

Catalog `mara_pb_g1`:
- `rebound` max 12, from closed;
- `hsc` max 6, `dial_cw` from open;
- `lsc` max 24, from closed.

→ **Same direction for all.**

### SAG / limits

- SAG 20–30 % of travel, in the attack position, Party mode.
- Max 250 psi [17.2 bar], which matches the catalog `pressure` max 250.

---

## Products without a structured guide

None. Every catalog product has a Manitou guide. The Mara shocks are **partial**: no
weight → pressure chart exists in any Manitou/Hayes source checked (the set-up guide
PDFs above and a web search for a Mara pressure chart). They have constants only.

## Follow-ups

- **Dorado Pro typo:** the 140 lb Min-Progressive Main is printed "51 [3.1]" (3.1 bar ≈
  45 psi). Confirm before encoding.
- **Mezzer Expert G1 typo:** the 140 lb / 160 mm cell reads "41 [3.8]". The psi is
  plausible and the bar is a typo.
- **Mattoc Pro HSC "Compliant tune 4-5"** exceeds the 4-0 range and the catalog `hsc`
  max 4. Clamp it to 4 or check with Hayes.
- **IVA position without a catalog adjuster:** Mezzer G1/G2 Expert, Mezzer LT Comp,
  Mattoc Expert/Comp and Mastodon Pro/Comp. The guides show positions up to 5
  (Mastodon) and 4 (Mezzer). The catalog cannot encode them until an `IVA Position`
  adjuster with a known max exists. Until then, `display_only`.
- **Pressure maxima live only in `notes`** on the Manitou forks: 120/150/200 psi. The
  guides confirm the numbers; consider numeric `max` fields.
- **Missing travel columns:**
  - R8: 80, 90 and 110 (guide has only 100/120);
  - Mastodon Pro: 90 and 110;
  - Mastodon Comp: 90 and 110.
  Decide whether to interpolate (#37 plan) or leave them uncovered.
- **Riding-style ids needed:**
  - Downhill / Enduro / Trail;
  - Plush Natural / Mid Mixed / Firm Park;
  - Comfort / Balanced / Support;
  - Standard / DH Race / Park;
  - Aggressive / Compliant tune.
- **Dorado progression axis** (Min/Mid/Max-Progressive) has no catalog option. It could
  become a `riding_style`-like preference, or the encoder could pick Mid as the default.
- **Mara shocks:** ask Hayes whether a weight → pressure chart exists. The help-center
  article pages are bot-blocked; only the PDF attachments are reachable.
