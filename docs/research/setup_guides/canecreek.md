# Cane Creek — setup guide research

Catalog files: `data/component_presets/fork/canecreek.yaml`, `data/component_presets/shock/canecreek.yaml` (catalog brand slug in `ids.lock`: `cane-creek`)
Researched: 2026-10-12

## Summary

- Cane Creek publishes **no rider-weight → psi tables**. Its manuals give the air pressure as a **percentage of rider weight in lb**, read as psi. The factor differs per product and generation: Helm MKII 30–40 %, Helm MK1 50 %, Air IL G2 120 %, Kitsuma G2/G1 75–100 %, DB Air IL G1 100 %, classic Double Barrel "weight with gear − 20 psi". Each is encoded as calculated rows (see Formulas).
- **SAG bands** are printed in every manual. Helm air 15–25 %, Helm coil 10–25 %, every current/G1 shock 25–35 % with 30 % as the start, classic Double Barrel 28–33 %.
- **One weight → spring table**: Helm MKII Coil (product page), rider lb → 35/45/55/65 lb spring.
- **Click constants**:
  - The classic Double Barrel Tuning Field Guide has a **factory base tune** per model (DBcoil, DBair, DBair CS, DBinline). It counts **from fully open**, the opposite of the catalog. DBcoil and DBair CS are pre-computed as `max − N` below. DBinline is blocked by a catalog damper mismatch.
  - Helm DJ: a rebound window "5–10 clicks from closed" and a 95–125 psi pressure window, neither indexed by weight.
- Current shocks (Air IL, Coil IL, Kitsuma, Kitsuma Coil, Tigon): no click starting points in the manuals. Cane Creek moved tuning help to the ShockTuner / ForkTuner web apps, which are question-driven troubleshooters with no tables, and to frame-specific "Base Tunes" (by bike model, not encodable).
- Coil spring rate is a **formula** with a second-order input B3 doesn't have: rate ≈ rear wheel travel ÷ shock stroke × rider weight (Tigon set-up page and the coil-spring knowledge article).
- Not covered by B3: rear-wheel-travel input (coil formula), from-open base tunes on a catalog whose `max` doesn't match the source (DBinline), weight-free value windows (Helm DJ), riding-style SAG from a generic article.

## Guide `canecreek_helm_mkii_2025` — Helm MKII instruction manual

### Source

- URL: https://cdn.shopify.com/s/files/1/0579/5987/4639/files/HelmMKII_UserManual_04_03_2025.pdf
- Document: Helm MKII User Manual, rev. 04/03/2025, English. It covers Helm MKII Air and Coil (27.5" and 29/27.5+).
- Section / page: Spring Specifications table (p. 11); Air Spring Set Up (pp. 14–16); Coil Spring Set Up (pp. 24–25)
- Supplementary (manufacturer):
  - Helm MKII Coil product page, "Spring Recommendations": https://www.canecreek.com/products/helm-mkii-coil (the same block is on https://www.canecreek.com/products/helm-mkii)
  - Fork support FAQ: https://www.canecreek.com/pages/forks-product-support
  - Launch journal post "Helm Yeah": https://www.canecreek.com/blogs/journal/helm-yeah
  - Support article "Helm MKII Air Volume Adjustment": https://support.canecreek.com/support/solutions/articles/62000210355-helm-mkii-air-volume-adjustment
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cane-creek/helm-mkii/air` | `damper: helm_mkii_damper` | Air formula, SAG 15–25 %, volume default |
| `fork/cane-creek/helm-works-series/air` | `damper: helm_mkii_damper` | Same manual (node `setup_guide`). The Works Series is a Helm MKII Air special edition, so the same air rules apply. |
| `fork/cane-creek/helm-mkii/coil` | `damper: helm_mkii_damper` | Spring chart (product page), coil SAG 10–25 % |

Gaps: none of the guides index by travel or wheel size. 27.5" and 29" share one rule.

### Air pressure — formula (no table)

Input: rider weight (lb) · Output: psi (positive chamber) · target `pressure`

The manual recommends 30–40 % of body weight in lb as psi. Its worked example: 150 lb rider → 45–60 psi. This is a band, so encode it as `range`. Rows: see Formulas.

### Coil spring — rider weight → spring (Helm MKII Coil product page)

Input: rider weight (lb, no kg printed) · Output: spring rate (lb/in) · target `spring_rate` · `when: { }` on `fork/cane-creek/helm-mkii/coil`

| Rider weight (lb) | Spring (lb) | Colour / part number |
|---|---|---|
| 90-120 | 35 | Red, AAG0421 |
| 120-160 | 45 | Black, AAG0422 |
| 160-200 | 55 | Green, AAG0424 — factory-installed |
| 200-240 | 65 | Blue, AAG0426 |

The bounds overlap at 120/160/200 as printed. Encode them as half-open brackets. The FAQ repeats that the 55 lb (green) spring is stock and "ideal for a 160 - 200 lb rider", and gives the units as lbs/in. The manual itself (p. 25) gives no weight mapping, only the four spring rates.

### Rebound / compression

No starting clicks are published for the Helm MKII.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `volume_adjustment` | 2 (of 8 notches) | notches down the indexed rod (catalog stepper, higher = more progressive) | Helm MKII Air — **conflicting sources, see Follow-ups** |
| `spring_rate` | 55 | — | Helm MKII Coil, factory spring |

### SAG

- Air: 15–25 % of travel (spec table and step 6; illustration example "24mm-40mm for 160mm travel"). Set with compression fully open.
- Coil: 10–25 % of travel. Add preload at 20–25 % sag or more. Go stiffer if sag is still above 25 % at maximum preload. Go softer below 10 %.

### Volume spacers

Not spacers: an indexed air-volume piston, 8 positions (catalog `Volume Adjustment`, max 8). Factory position, two conflicting manufacturer statements:
- Journal post "Helm Yeah" (launch): set at the factory 2 notches down, out of 8 possible positions.
- Support article (current): "Helm MKII Air is set up at the factory without the air volume piston installed".

### Pressure limits

Air: minimum 30 psi, maximum 150 psi, for both wheel sizes. Matches catalog `pressure` min 30 / max 150.

### Formulas

psi = 0.30–0.40 × rider weight (lb). The source states no rider range, so rows use 50–120 kg. **Calculated from the published formula** (lb = kg × 2.20462, 1 decimal).

| Rider weight (kg) | Rider weight (lb, calc.) | psi band (30–40 %) |
|---|---|---|
| 50 | 110.2 | 33.1-44.1 |
| 55 | 121.3 | 36.4-48.5 |
| 60 | 132.3 | 39.7-52.9 |
| 65 | 143.3 | 43-57.3 |
| 70 | 154.3 | 46.3-61.7 |
| 75 | 165.3 | 49.6-66.1 |
| 80 | 176.4 | 52.9-70.5 |
| 85 | 187.4 | 56.2-75 |
| 90 | 198.4 | 59.5-79.4 |
| 95 | 209.4 | 62.8-83.8 |
| 100 | 220.5 | 66.1-88.2 |
| 105 | 231.5 | 69.4-92.6 |
| 110 | 242.5 | 72.8-97 |
| 115 | 253.5 | 76.1-101.4 |
| 120 | 264.6 | 79.4-105.8 |

All within the 30–150 psi limits.

### Does not fit B3

- The air pressure is a band (`range`) from a formula. Encode it as calculated rows with `range` per bracket, or add a formula rule type.
- Negative chamber: equalised via a button, not a separate pressure, so there is no extra target.

## Guide `canecreek_helm_mk1_2018` — Helm (original) instruction manual

### Source

- URL: https://cdn.shopify.com/s/files/1/0579/5987/4639/files/Helm_UserManual_1_12_18_FINAL_4a8c4476-2bc0-4f03-ae32-0ced7f5f3137.pdf
- Document: Helm User Manual, rev. 01/12/2018, English
- Section / page: Spring Specifications (p. 5); Air Spring Set Up (pp. 14–16); Coil Spring Set Up (pp. 24–25)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cane-creek/helm-mk1/air` | `damper: helm_mk1_damper` | Air formula 50 %, SAG 15–25 % |
| `fork/cane-creek/helm-mk1/coil` | `damper: helm_mk1_damper` | Coil SAG 10–25 %; no spring chart |

### Air pressure — formula

psi = half of body weight in lb (worked example: 150 lb → 75 psi). Target `pressure`. This differs from the MKII (30–40 %), so don't share the rule.

| Rider weight (kg) | Rider weight (lb, calc.) | psi (50 %) |
|---|---|---|
| 50 | 110.2 | 55.1 |
| 55 | 121.3 | 60.6 |
| 60 | 132.3 | 66.1 |
| 65 | 143.3 | 71.7 |
| 70 | 154.3 | 77.2 |
| 75 | 165.3 | 82.7 |
| 80 | 176.4 | 88.2 |
| 85 | 187.4 | 93.7 |
| 90 | 198.4 | 99.2 |
| 95 | 209.4 | 104.7 |
| 100 | 220.5 | 110.2 |
| 105 | 231.5 | 115.7 |
| 110 | 242.5 | 121.3 |
| 115 | 253.5 | 126.8 |
| 120 | 264.6 | 132.3 |

Calculated from the published formula; no rider range stated, so 50–120 kg.

### SAG

Air 15–25 % (example 24–40 mm at 160 mm); coil 10–25 %. Same preload rules as the MKII.

### Pressure limits

30–150 psi; matches catalog.

### Coil spring

Same four springs (35 red / 45 black / 55 green / 65 blue). The manual says explicitly that it does not define spring rates by rider weight. The MKII product-page chart is **not** applied to the MK1 (see Follow-ups).

## Guide `canecreek_helm_dj_2025` — Helm DJ product page, "Helm DJ Setup Recommendations"

### Source

- URL: https://www.canecreek.com/products/helm-dj
- Document: product page, setup recommendations block, English (no manual exists)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/cane-creek/helm-dj/standard` | `damper: helm_dj_damper` | Trim is `draft: true` |

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `pressure` | range 95–125 psi | — | none; "based on rider weight and sag / ride-height preference", but no weight mapping |
| `rebound` | range 5–10 | from closed | `damper: helm_dj_damper` |

Counting direction: the source counts from closed. The catalog `helm_dj_damper` `rebound` notes say "Counted from fully closed", default `dial_ccw`, max 10 (estimated from this same window). Same direction, so encode as published.

## Guide `canecreek_air_coil_il_g2_2025` — Air IL & Coil IL instruction manual

### Source

- URL: https://cdn.shopify.com/s/files/1/0579/5987/4639/files/DB_IL_G2_Manual_2025_04_01.pdf
- Document: DB IL G2 (Air IL / Coil IL) manual, rev. 04/01/2025, English
- Section / page: Features Overview (p. 6); Air installation step (p. 13); Setting Sag (pp. 16–17, coil p. 18); Coil Installation (p. 21)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/cane-creek/air-il/standard` | `damper: il_twin_tube` | 120 % formula, SAG |
| `shock/cane-creek/air-il/trunnion` | `damper: il_twin_tube` | same |
| `shock/cane-creek/coil-il/standard` | `damper: il_twin_tube` | SAG; spring rate → see `canecreek_coil_springs` |
| `shock/cane-creek/coil-il/trunnion` | `damper: il_twin_tube` | same |

### Air pressure — formula

Starting pressure = 120 % of rider body weight (lb) as psi. Worked example: 180 lb × 1.2 = 216 psi. The manual adds that it varies with shock size and kinematics. Target `pressure`.

| Rider weight (kg) | Rider weight (lb, calc.) | psi (120 %) |
|---|---|---|
| 50 | 110.2 | 132.3 |
| 55 | 121.3 | 145.5 |
| 60 | 132.3 | 158.7 |
| 65 | 143.3 | 172 |
| 70 | 154.3 | 185.2 |
| 75 | 165.3 | 198.4 |
| 80 | 176.4 | 211.6 |
| 85 | 187.4 | 224.9 |
| 90 | 198.4 | 238.1 |
| 95 | 209.4 | 251.3 |
| 100 | 220.5 | 264.6 |
| 105 | 231.5 | 277.8 |
| 110 | 242.5 | 291 |
| 115 | 253.5 | 304.2 |
| 120 | 264.6 | 317.5 |

Calculated from the published formula; no rider range stated, so 50–120 kg. All within 50–350 psi.

### SAG

Recommended 25–35 % of shock stroke, starting point 30 %. Worked examples: 15 / 16.5 / 18 / 19.5 mm at 50 / 55 / 60 / 65 mm stroke. Encode as `sag` `range` 25–35 with `value` 30.

### Constants / base tune

No click base tune is printed. Coil preload (Coil IL, catalog `preload`, 3–18 clicks): keep at least 1 turn (3 clicks). Above 3 turns, the next stiffer spring is likely better. The page also says "more than 2 turns (3 clicks)", which is internally inconsistent; treat it as a note only.

### Volume spacers

Air IL: the installation procedure is described (p. 19ff), but no count, no factory count and no maximum. The catalog has no `volume_spacers` on Air IL.

### Pressure limits

Air 50–350 psi; matches catalog `pressure` 50/350. Coil preload 1 turn = 3 clicks, 6 turns = 18 clicks max; matches catalog.

## Guide `canecreek_kitsuma_g2_2025` — Kitsuma instruction manual

### Source

- URL: https://cdn.shopify.com/s/files/1/0579/5987/4639/files/Kitsuma_Manual_2025_04_01.pdf
- Document: Kitsuma (G2) manual, rev. 04/01/2025, English. It covers Kitsuma Air and Kitsuma Coil.
- Section / page: Features Overview (p. 5); Setting Sag (pp. 15–17); Air Volume Adjustment (pp. 18–19)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/cane-creek/kitsuma/standard` | `damper: kitsuma_g2` | 75–100 % formula, SAG, spacer max per size |
| `shock/cane-creek/kitsuma/trunnion` | `damper: kitsuma_g2` | same |
| `shock/cane-creek/kitsuma-coil/standard` | `damper: kitsuma_g2` | SAG, preload 1–3 turns |
| `shock/cane-creek/kitsuma-coil/trunnion` | `damper: kitsuma_g2` | same |

### Air pressure — formula

Starting point: 75–100 % of rider weight (lb) as psi. Worked example: 180 lb → 135–180 psi. Target `pressure`, `range`.

| Rider weight (kg) | Rider weight (lb, calc.) | psi band (75–100 %) |
|---|---|---|
| 50 | 110.2 | 82.7-110.2 |
| 55 | 121.3 | 90.9-121.3 |
| 60 | 132.3 | 99.2-132.3 |
| 65 | 143.3 | 107.5-143.3 |
| 70 | 154.3 | 115.7-154.3 |
| 75 | 165.3 | 124-165.3 |
| 80 | 176.4 | 132.3-176.4 |
| 85 | 187.4 | 140.5-187.4 |
| 90 | 198.4 | 148.8-198.4 |
| 95 | 209.4 | 157.1-209.4 |
| 100 | 220.5 | 165.3-220.5 |
| 105 | 231.5 | 173.6-231.5 |
| 110 | 242.5 | 181.9-242.5 |
| 115 | 253.5 | 190.1-253.5 |
| 120 | 264.6 | 198.4-264.6 |

Calculated from the published formula, 50–120 kg. All within 50–300 psi.

### SAG

25–35 % of stroke, start at 30 %. Worked example: 16.5 mm / 55 mm = 30 %.

### Constants / base tune

No click base tune. Coil preload (catalog `preload`, turns 1–6): use at least 1 full turn past the no-play point. Above 3 turns, change to a stiffer spring. Usable as a `range` 1–3 note.

### Volume spacers

Maximum 9 single-width strips for 185/205/210/230 eye-to-eye, 11 for 225/250 (matches catalog notes). One band = 5 single-width strips is **included** with the shock. The manual doesn't say it is installed at the factory, so there is no factory count → no `volume_spacers` default.

### Pressure limits

Air 50–300 psi; matches catalog.

## Guide `canecreek_tigon_2025` — Tigon instruction manual + Tigon set-up procedure page

### Source

- URLs:
  - https://cdn.shopify.com/s/files/1/0579/5987/4639/files/Tigon_Manual_2025_04_01.pdf
  - https://www.canecreek.com/pages/tigon-set-up-procedure (the node `setup_guide`)
- Document: Tigon manual rev. 04/01/2025 (Features Overview p. 6, spring spacer chart p. 14, Setting Sag pp. 15–16, Ramp Tube pp. 17–18), plus the set-up procedure web page (Steps 1–5), English
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/cane-creek/tigon` | `damper: tigon_damper` | Spring formula, SAG, RAMP Tube start 0 psi |

### SAG

25–35 % of shock travel, start at 30 %. The manual prints a mm table:

| Stroke (mm) | Percentage (%) | Sag (mm) |
|---|---|---|
| 50mm | 25-35% | 12.5mm-17.5mm |
| 55mm | 25-35% | 13.75mm-19.25 |
| 60mm | 25-35% | 15mm-21mm |
| 65mm | 25-35% | 16.25mm-22.75mm |

Input `size` (stroke). Cleaner to encode as `sag` `range` 25–35 %.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `ramp_tube_pressure` | 0 psi | — | set sag and damping at 0 psi first, then add 5–10 psi at a time, max 30 |
| `preload` | range 1–3 turns | — | at least 1 full turn; above 3 → next spring rate up |

### Coil spring — formula

Spring rate = rear wheel travel ÷ shock stroke × rider weight (lb), then **round down** to the nearest available spring (this maximises the RAMP Tube's effect). Allowed range: minimum 350, maximum 650 lb/in (catalog `spring_rate` 350/650 ✓). No table is possible without the bike's rear travel; see Does not fit B3.

### Spring spacer chart (hardware, not a setup value)

Manual p. 14 ("Coil Installation"), checked against the page image. Spacers go on before the spring:

| Shock | 350 | 400 | 450 | 500 | 550 | 600 | 650 |
|---|---|---|---|---|---|---|---|
| 210 Standard / 185 Trunnion (ships with 1× 2 mm) | 2mm | 2mm | 2mm | 2mm | 2mm | 2mm | 2mm |
| 230 Standard / 205 Trunnion (ships with 2× 2 mm + 1× 8 mm) | 2mm 2mm 8mm | 2mm 2mm 8mm | 8mm | 2mm 2mm | 2mm 2mm | 2mm | — (not listed) |

This is an installation note, not a guide target. 650 lb/in is listed only for the 210/185 sizes.

### Pressure limits

RAMP Tube 0–30 psi; matches catalog. Preload 1–6 turns; matches catalog.

## Guide `canecreek_db_il_g1_2022` — DB Air IL / DBcoil IL (G1) instruction manual

### Source

- URL: https://cdn.shopify.com/s/files/1/0579/5987/4639/files/DB-IL-Manual_2022_02_25_1_d8229608-3c4e-406c-bf6f-5b97afc6b6f8.pdf
- Document: DB IL manual rev. 02/25/2022, English
- Section / page: Features Overview (p. 6); air step (p. 13); Setting Sag (pp. 16–18)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/cane-creek/db-air-il-g1` | `damper: il_twin_tube_g1` | 100 % formula, SAG |
| `shock/cane-creek/dbcoil-il-g1` | `damper: il_twin_tube_g1` | SAG, preload 1–2 turns |

### Air pressure — formula

Start with psi equal to rider weight in lb (example: 180 lb → 180 psi). Target `pressure`.

| Rider weight (kg) | psi (= lb, calc.) |
|---|---|
| 50 | 110.2 |
| 55 | 121.3 |
| 60 | 132.3 |
| 65 | 143.3 |
| 70 | 154.3 |
| 75 | 165.3 |
| 80 | 176.4 |
| 85 | 187.4 |
| 90 | 198.4 |
| 95 | 209.4 |
| 100 | 220.5 |
| 105 | 231.5 |
| 110 | 242.5 |
| 115 | 253.5 |
| 120 | 264.6 |

Calculated from the published formula, 50–120 kg. Within 50–300 psi.

### SAG

25–35 %, start at 30 % (same worked examples as G2).

### Constants

DBcoil IL G1 preload (catalog `preload` turns 1–6): use at least 1 turn. Above 2 turns, change to a stiffer spring. Range 1–2 as a note.

### Pressure limits

50–300 psi; matches catalog.

## Guide `canecreek_db_kitsuma_g1_2022` — DB Kitsuma (G1) instruction manual

### Source

- URL: https://cdn.shopify.com/s/files/1/0579/5987/4639/files/DBKitsuma-Manual_2022_02_25_1_c25c4778-7d40-4977-a021-ac43a3c30070.pdf
- Document: DB Kitsuma manual rev. 02/25/2022, English
- Section / page: Features Overview (p. 5); air step (p. 12); Setting Sag (pp. 15–17)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/cane-creek/db-kitsuma-air-g1` | `damper: kitsuma_g1` | 75–100 % formula (identical to G2; same rows as `canecreek_kitsuma_g2_2025`), SAG |
| `shock/cane-creek/db-kitsuma-coil-g1` | `damper: kitsuma_g1` | SAG; preload: at least 1 turn, above 6 turns → stiffer spring |

### SAG / limits

SAG 25–35 %, start at 30 %. Air 50–300 psi; matches catalog. No click base tune, no spacer count.

## Guide `canecreek_double_barrel_tfg` — Double Barrel Tuning Field Guide (+ 2014 owner's manual)

### Source

- URLs:
  - https://cdn.shopify.com/s/files/1/0579/5987/4639/files/tfg_english_30a0cfe9-1830-4f4f-8436-09f3bfd14390.pdf
  - https://cdn.shopify.com/s/files/1/0579/5987/4639/files/DB_owners-manual_2014_v11-web_8703fe9e-d4d7-4766-b7db-3350db90bbfb.pdf
- Document: Double Barrel Tuning Field Guide, PN AAC0117 (undated), English; Double Barrel owner's manual 2014 v11, PN AAC0106
- Section / page: TFG "Factory Tune" pp. 4–6 (range bars with the base tune marked), "Prior to Run 1 – Set Sag" p. 7, sag p. 8; manual "Setting Sag" p. 14
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `shock/cane-creek/dbcoil/standard` | `damper: db_classic` | "DBcoil Factory Base Tune" |
| `shock/cane-creek/db-air-cs/standard` | `damper: db_classic_cs` | "DBair CS Factory Base Tune"; air formula |
| `shock/cane-creek/db-inline/standard` | `damper: db_classic_cs` | "DBinline Factory Base Tune" — **range mismatch, do not encode** |

Gaps:
- The TFG also prints a **DBair** (non-CS) base tune: HSC 2 turns, LSC 12, HSR 2 turns, LSR 12, from open. The catalog has no plain DBair node, so it is not encoded.
- DBair CS XV and DBcoil CS are not in the catalog.
- Bike-specific "Base Tune cards" (canecreek.com, by frame) are not encodable.

### Base tune — source as printed (counted from fully open)

The TFG reset procedure: turn every adjuster fully counter-clockwise (open), then turn clockwise by the printed number. Every bar scale starts at 0 on the soft side (PLUSH / SUPPLE / LIVELY POP), so these are **from open**.

| Model (as printed) | HSC (turns) | LSC (clicks) | HSR (turns) | LSR (clicks) | Range printed |
|---|---|---|---|---|---|
| DBcoil | 2 | 12 | 2 | 12 | 0–4 turns / 0–25 clicks |
| DBair | 2 | 12 | 2 | 12 | 0–4 turns / 0–25 clicks |
| DBair CS | 2 | 13 | 2 | 15 | 0–4 turns / 0–25 clicks |
| DBinline | 2 | 7 | 2 | 10 | 0–4.5 turns / 0–18 clicks |

### Constants / base tune — catalog direction

Catalog `db_classic` / `db_classic_cs`: `hsc` and `hsr` are numerical turns 0–4, notes "counted from fully closed". `lsc` and `lsr` are steps with max 25 and default `dial_ccw` (counted from closed). Opposite direction with `max` known, so pre-compute `max − N` column by column:

| Target | Value (catalog direction) | Computation | `when:` |
|---|---|---|---|
| `hsc` | 2 | 4 − 2 | `damper: db_classic` (DBcoil) |
| `lsc` | 13 | 25 − 12 | `damper: db_classic` |
| `hsr` | 2 | 4 − 2 | `damper: db_classic` |
| `lsr` | 13 | 25 − 12 | `damper: db_classic` |
| `hsc` | 2 | 4 − 2 | path `shock/cane-creek/db-air-cs/standard` (DBair CS) |
| `lsc` | 12 | 25 − 13 | same |
| `hsr` | 2 | 4 − 2 | same |
| `lsr` | 10 | 25 − 15 | same |

DBinline: the TFG range is 4.5 turns / 18 clicks, but the catalog maps `db-inline` to `db_classic_cs` (4 turns / 25 clicks). Using catalog max gives LSC 18 / LSR 15, which would be wrong. Using the source range gives HSC 2.5, LSC 11, HSR 2.5, LSR 8. **Do not encode** until the catalog gets its own DBinline damper (see Follow-ups). The DBair CS base tune is keyed by path, not by damper, because `db_classic_cs` is shared with DB Inline.

### Air pressure — formula (DBair / DBair CS / DBinline)

Start at rider weight **with gear** (lb) minus 20 psi. Target `pressure`.

| Rider weight with gear (kg) | lb (calc.) | psi |
|---|---|---|
| 50 | 110.2 | 90.2 |
| 55 | 121.3 | 101.3 |
| 60 | 132.3 | 112.3 |
| 65 | 143.3 | 123.3 |
| 70 | 154.3 | 134.3 |
| 75 | 165.3 | 145.3 |
| 80 | 176.4 | 156.4 |
| 85 | 187.4 | 167.4 |
| 90 | 198.4 | 178.4 |
| 95 | 209.4 | 189.4 |
| 100 | 220.5 | 200.5 |
| 105 | 231.5 | 211.5 |
| 110 | 242.5 | 222.5 |
| 115 | 253.5 | 233.5 |
| 120 | 264.6 | 244.6 |

Calculated from the published formula, 50–120 kg. Applies to `db-air-cs/standard` and `db-inline/standard`. No pressure limits are published for the classic DB (the catalog `pressure` is unbounded).

### SAG

TFG: 28–33 % of available travel as a starting point. The 2014 manual points to the bike's Base Tune card for the exact value.

### Volume spacers

Included spacers are described, with no count and no factory count.

## Guide `canecreek_coil_springs_2026` — "Everything You Need To Know About Coil Springs" (knowledge article)

### Source

- URL: https://www.canecreek.com/pages/everything-you-need-to-know-about-coil-springs
- Document: Cane Creek knowledge page (undated, retrieved 2026), English
- Section: "What Spring Rate Do I Need", "Spring Rate Calculation Method #1 / #2"
- Retrieved: 2026-10-11

### Catalog mapping

Applies to every Cane Creek coil shock with a `spring_rate` target: `shock/cane-creek/coil-il/standard`, `shock/cane-creek/coil-il/trunnion`, `shock/cane-creek/kitsuma-coil/standard`, `shock/cane-creek/kitsuma-coil/trunnion`, `shock/cane-creek/dbcoil-il-g1`, `shock/cane-creek/db-kitsuma-coil-g1`, `shock/cane-creek/dbcoil/standard` (`shock/cane-creek/tigon` has its own page with the same formula plus round-down).

### Formulas

- Method #2 (average leverage): rate (lb/in) ≈ (rear wheel travel ÷ shock stroke) × rider weight with gear (lb). Worked example: 150 mm / 55 mm = 2.72; × 185 lb = 503.2 → 500 lb spring. Choose the lighter spring when between two rates.
- Method #1: leverage ratio read off the bike's curve at the sag point (rear travel × sag %) × rider weight.
- No calculated table: the result depends on the bike's rear travel, which the catalog doesn't know.

### SAG

25–35 % of wheel travel. Per style: **DH 35 %, XC 25 %, most trail bikes 30 %** → `sag` rules `when: { riding_style: … }` (style ids to be fixed by the encoder: proposed `xc`, `trail`, `dh`).

### Does not fit B3

- Rear wheel travel (and the bike's leverage curve) is a bike-level input, not a component option. Proposed encoding: a `formula` rule with inputs `rider_weight` + `rear_travel_mm` + stroke (from `size`). Alternatively a `display_only` note quoting the formula until the bike's rear travel is captured.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| — | Every Cane Creek catalog product has at least a SAG band or a pressure formula. None has a weight-indexed click table. |

## Follow-ups

- Helm MKII air-volume factory position: the launch post says 2 of 8 notches down, the current support article says the piston isn't installed at the factory. Ask Cane Creek or check a new fork before encoding `volume_adjustment`.
- Helm MKII Coil spring chart is on the product page only. Whether it applies to the MK1 Coil (same four springs) is not stated, so it is not applied.
- DBinline: the TFG prints 18-click / 4.5-turn ranges for DBinline. The catalog maps `db-inline` to `db_classic_cs` (25 clicks / 4 turns). The catalog likely needs a separate DBinline damper (the 2014 manual's p. 36 range chart shows only the 25/4 scale). Fix that before encoding its base tune.
- Catalog `db_classic` / `db_classic_cs` notes say HSC/HSR are "counted from fully closed". The TFG and the 2014 range chart put 0 at the soft (open) end, so the catalog's own counting note may be wrong. If the catalog is flipped to from-open, encode the TFG numbers as printed instead of `max − N`.
- Tigon: the manual's spacer chart lists 650 lb/in for 210/185 only, while the catalog `spring_rate` max 650 applies to every size. Consider a per-size note.
- Coil IL G2 preload text contradicts itself ("more than 2 turns (3 clicks)" vs "more than 3 turns"). Use only as a note.
- Riding-style ids for the coil-article SAG split need to match the app's `riding_style` values.
