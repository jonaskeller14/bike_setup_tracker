# BOS — setup guide research

Catalog files: `data/component_presets/fork/bos.yaml`, `data/component_presets/shock/bos.yaml`
Researched: 2026-10-11

## Summary

- **Forks (Deville 35, Kyll 39, Idylle 39, Obsys 42):** each 2025 Quickstart
  (EN, 2 pages) prints a rider weight → psi table and "standard settings"
  (starting clicks counted from fully closed, the catalog's direction). Kyll 39
  adds a travel dimension (160/170/180/190 mm) and a separate e-MTB ("VTTAE")
  block. Grabber Quickstarts also give the token maximum (5) and the stock
  token (1). All say pressures may be adjusted ±5 psi by use and riding style.
- **Toxik:** no manual or Quickstart on the BOS manuals page — none.
- **Shocks (Stoy 4, Void 4, Syors 2):** the BOS manuals page lists only French
  service manuals and spare-parts lists for these; the service manuals end with
  a blank "Tableau de réglages" log. No setup data — none. (The Stoy 3 user
  manual linked nearby is a different generation; see Follow-ups.)
- Not covered by B3: the Kyll e-MTB columns (no catalog option), the Obsys
  separate preload valve (no catalog adjuster), and the Deville table that
  contradicts the Quickstart's own pressure window.

## Guide `bos_deville35_2025` — Deville 35 Grabber Quickstart

### Source

- URL: https://www.bos-suspension.com/Files/125448/Quickstart_DEVILLE__35_GRABBER_EN.pdf
- Document: Deville 35 Grabber Quickstart, 2025 range, English
- Section / page: p. 2 — Air pressure, Standard settings, Token installation
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/bos/deville-35/grabber` | `damper: grabber_2025` | all `travel_mm` (140/150/160/170); the table has no travel column |

Gaps: none.

### Air pressure

Input: rider weight (kg/lbs printed together) · Output: psi · target
`pressure`. Literal points.

| Rider weight (kg) | Rider weight (lbs) | psi |
|---|---|---|
| 55 | 121 | 55 |
| 60 | 132 | 61 |
| 65 | 143 | 67 |
| 70 | 154 | 73 |
| 75 | 165 | 79 |
| 80 | 176 | 85 |
| 85 | 187 | 91 |
| 90 | 198 | 97 |
| 95 | 209 | 103 |
| 100 | 220 | 109 |
| 105 | 231 | 115 |
| 110 | 242 | 121 |

The same page states "whatever your weight, the air pressure should be between
115 and 350 psi" — every table value below 105 kg is under 115 psi. The two
statements contradict each other (see Follow-ups); do not encode until
resolved.

### Rebound / compression — standard settings

Source direction: turn clockwise to the stop = click 0, count
counter-clockwise (from closed). Catalog: `grabber_2025` `hsc` max 25, `lsc`
max 27, `rebound` max 30, default `dial_ccw` (from closed) → same direction,
encode as published.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `lsc` | 11 | from closed | `damper: grabber_2025` |
| `hsc` | 10 | from closed | `damper: grabber_2025` |
| `rebound` | 10 | from closed | `damper: grabber_2025` |
| `volume_spacers` | 1 | count (stock token) | `fork/bos/deville-35/grabber` |

### SAG

None published.

### Volume spacers

Comes with one stock token; maximum 5 tokens. 0 = linear/comfort, 1 = balanced,
2 = firmer end-stroke. Catalog `volume_spacers` max 5 — matches.

### Pressure limits

115–350 psi window printed (but see contradiction above). Catalog `pressure`
max 350.

### Formulas

None stated. (Table steps 6 psi per 5 kg.)

### Does not fit B3

- "±5 psi according to use and riding style" → `note`, or a ±5 `range`
  around each point.

## Guide `bos_kyll39_2025` — Kyll 39 Grabber Quickstart

### Source

- URL: https://www.bos-suspension.com/Files/125448/Quickstart_KYLL_39_GRABBER_EN.pdf
- Document: Kyll 39 Grabber Quickstart, 2025 range, English (same table also in the French service manual `Batch/04/KYLL_manuel_de_service.pdf`, p. 22)
- Section / page: p. 2 — Air pressure ("Usage VTT" and "Usage VTTAE" blocks), Standard settings, Token installation
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/bos/kyll-39/grabber` | `damper: grabber_2025`, `travel_mm: 160 / 170 / 180 / 190` | "Usage VTT" (MTB) block |

Gaps: the "Usage VTTAE" (e-MTB) block has no matching catalog node or option
→ transcribed, not encoded.

### Air pressure — Usage VTT (MTB)

Input: rider weight (kg/lbs) · Output: psi per travel · `when: { travel_mm: … }`.

| Rider weight (kg) | Rider weight (lbs) | 160 mm | 170 mm | 180 mm | 190 mm |
|---|---|---|---|---|---|
| 60 | 132 | 167 | 159 | 150 | 142 |
| 65 | 143 | 182 | 171 | 162 | 153 |
| 70 | 154 | 196 | 184 | 173 | 164 |
| 75 | 165 | 210 | 196 | 185 | 175 |
| 80 | 176 | 224 | 208 | 197 | 186 |
| 85 | 187 | 237 | 220 | 208 | 197 |
| 90 | 198 | 251 | 233 | 220 | 208 |
| 95 | 209 | 265 | 245 | 231 | 220 |
| 100 | 220 | 279 | 257 | 243 | 231 |
| 105 | 231 | 293 | 269 | 255 | 242 |
| 110 | 242 | 307 | 282 | 266 | 253 |

### Air pressure — Usage VTTAE (e-MTB, not encoded)

| Rider weight (kg) | Rider weight (lbs) | 160 mm | 170 mm | 180 mm | 190 mm |
|---|---|---|---|---|---|
| 60 | 132 | 195 | 184 | 173 | 164 |
| 65 | 143 | 207 | 196 | 185 | 175 |
| 70 | 154 | 219 | 208 | 197 | 186 |
| 75 | 165 | 231 | 220 | 208 | 197 |
| 80 | 176 | 243 | 233 | 220 | 208 |
| 85 | 187 | 255 | 245 | 231 | 220 |
| 90 | 198 | 267 | 257 | 243 | 231 |
| 95 | 209 | 279 | 269 | 255 | 242 |
| 100 | 220 | 291 | 282 | 266 | 253 |
| 105 | 231 | 303 | 294 | 278 | 264 |
| 110 | 242 | 315 | 306 | 290 | 275 |

### Rebound / compression — standard settings

Source direction: from closed (clockwise to the stop = 0). Catalog
`grabber_2025` `dial_ccw` → same direction.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `lsc` | 11 | from closed | `damper: grabber_2025` |
| `hsc` | 10 | from closed | `damper: grabber_2025` |
| `rebound` | 10 | from closed | `damper: grabber_2025` |
| `volume_spacers` | 1 | count (stock token) | `fork/bos/kyll-39/grabber` |

### SAG

None published.

### Volume spacers

Stock token 1, maximum 5 (catalog max 5 — matches).

### Pressure limits

115–350 psi. Catalog `pressure` max 350 — matches. All table values lie in the
window.

### Formulas

None.

### Does not fit B3

- E-MTB block: no catalog option (`ebike` axis or node) to filter on.
- ±5 psi by use/riding style → `note`.

## Guide `bos_idylle39_2025` — Idylle 39 Grabber Quickstart

### Source

- URL: https://www.bos-suspension.com/Files/125448/Quickstart_IDYLLE_39_GRABBER_EN.pdf
- Document: Idylle 39 Grabber Quickstart, 2025 range, English
- Section / page: p. 2 — Crown heights, Air pressure, Standard settings, Token installation
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/bos/idylle-39/grabber` | `damper: grabber_dh_2025`, `travel_mm: 208` | single travel |

Gaps: none.

### Air pressure

Input: rider weight (kg/lbs) · Output: psi · target `pressure`.

| Rider weight (kg) | Rider weight (lbs) | psi |
|---|---|---|
| 60 | 132 | 151 |
| 65 | 143 | 164 |
| 70 | 154 | 177 |
| 75 | 165 | 190 |
| 80 | 176 | 203 |
| 85 | 187 | 217 |
| 90 | 198 | 230 |
| 95 | 209 | 243 |
| 100 | 220 | 256 |
| 105 | 231 | 270 |
| 110 | 242 | 283 |

### Rebound / compression — standard settings

Source direction: from closed. Catalog `grabber_dh_2025` `hsc` max 25, `lsc`
max 27, `rebound` max 30, `dial_ccw` → same direction.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `lsc` | 11 | from closed | `damper: grabber_dh_2025` |
| `hsc` | 10 | from closed | `damper: grabber_dh_2025` |
| `rebound` | 10 | from closed | `damper: grabber_dh_2025` |
| `volume_spacers` | 1 | count (stock token) | `fork/bos/idylle-39/grabber` |

### SAG

None published. (Crown height: 217 mm from top of the leg seal to the bottom
of the lower crown — fitting instruction, not a setup target.)

### Volume spacers

Stock token 1, maximum 5 (catalog max 5 — matches).

### Pressure limits

115–350 psi. Catalog max 350 — matches.

### Formulas

None.

### Does not fit B3

- ±5 psi by use/riding style → `note`.

## Guide `bos_obsys42_2025` — Obsys Quickstart

### Source

- URL: https://www.bos-suspension.com/Files/125448/Quickstart_Obsys-EN.pdf
- Document: Obsys Quickstart, English (undated; linked as the Obsys 42 setup guide)
- Section / page: p. 1 — Air pressure table, preload valve; p. 2 — Starting point adjustments
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/bos/obsys-42/air` | `damper: obsys_2025`, `travel_mm: 200` | single travel |

Gaps: the Quickstart's separate PRELOAD valve has no catalog adjuster.

### Air pressure

Input: rider weight (kg and lbs as separate printed rows) · Output: psi
("Pression (psi)") · target `pressure`.

| Rider weight (kg) | Rider weight (lbs) | psi |
|---|---|---|
| 55 | 120 | 149 |
| 60 | 132 | 160 |
| 65 | 143 | 169 |
| 70 | 154 | 179 |
| 75 | 165 | 187 |
| 80 | 176 | 195 |
| 85 | 187 | 202 |
| 90 | 198 | 209 |
| 95 | 210 | 216 |
| 100 | 220 | 221 |
| 105 | 231 | 226 |
| 110 | 242 | 231 |
| 115 | 254 | 235 |
| 120 | 265 | 238 |

### Rebound / compression — starting point

Source direction: clockwise to the stop = click 0, count counter-clockwise
(from closed). Catalog `obsys_2025` `compression` max 20, `rebound` max 28,
`dial_ccw` → same direction, encode as published. (Compression 20 equals the
catalog maximum, i.e. fully open.)

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression` | 20 | from closed | `damper: obsys_2025` |
| `rebound` | 13 | from closed | `damper: obsys_2025` |

### SAG

None published.

### Volume spacers

None (the catalog has no spacer adjuster; progression via air pressure).

### Pressure limits

"Between 135 and 250 psi". Catalog `pressure` max 250 — matches. All table
values lie in the window.

### Formulas

None.

### Does not fit B3

- **Preload valve:** set independently "in a range from 0 to 500 gr" — unit as
  printed (grams), no catalog adjuster. Not encoded; `note` at most.
- ±5 psi by use/riding style → `note`.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `fork/bos/toxik/air` | No Quickstart, user manual or setup data for the Toxik on the BOS manuals page (https://www.bos-suspension.com/PBCPPlayer.asp?ID=2252919) or product page (ID=2422893). |
| `shock/bos/stoy-4/standard` | Manuals page lists no user manual or Quickstart for the Stoy 4 (its row links a placeholder "x" to the Stoy 3 FR user manual `22906548229023.pdf`). |
| `shock/bos/void-4/standard`, `shock/bos/void-4/lever` | Only the French service manual (`Batch/17/VOID_manuel_de_service.pdf`) and spare parts; the service manual's p. 20 "Tableau de réglages" is a blank log (terrain / compression / rebound / psi). |
| `shock/bos/syors-2/standard`, `shock/bos/syors-2/lever` | Only the French service manual (`Batch/01/SYORS_manuel_de_service.pdf`, blank settings log p. 19) and spare parts. The older Syors user manual / Quickstart covers the first-generation Syors. |

## Follow-ups

- **Deville 35 contradiction:** the Quickstart's table (55–121 psi) conflicts
  with its own "115 to 350 psi" window and with the catalog `pressure` max 350
  derived from it. The window looks copied from the 39 mm forks. The French
  Quickstart (`Quickstart_DEVILLE_35_GRABBER_FR.pdf`) prints the same table and
  the same window, so it does not resolve it. Ask BOS before encoding either
  the table or the catalog note "Air pressure range 115-350 psi".
- **Stoy 3 user manual (FR, `22906548229023.pdf`):** recommends SAG 25–35 %
  (Enduro 25–30 %, DH 30–35 %), 30 % as the target, coil preload 0–4 mm, and
  base clicks 10/10/10 from closed. It is the previous generation; only usable
  for the Stoy 4 if BOS confirms the same guidance.
- Kyll e-MTB pressures need a catalog e-bike axis before they can be encoded.
