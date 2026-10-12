# RockShox — setup guide research

Catalog files: `data/component_presets/fork/rockshox.yaml`, `data/component_presets/shock/rockshox.yaml`
Researched: 2026-10-12

## Summary

- **Forks: weight → psi decal tables.** SRAM prints one per fork family and model
  year in the yearly *Front Suspension Specifications* PDF (the same table as
  the air-pressure decal on the fork leg).
  - Rows are travel bands. Columns are rider-weight brackets with lb and kg
    printed.
  - Each cell is a psi band, encoded as a `range`. The edge cells are
    open-ended (`<60 psi`, `110+ psi`).
  - Each table gives a max psi.
  - Every table has the header "E-Bikes add 10 psi". The catalog has no e-bike
    option, so that offset is not encoded.
- **Forks: factory Bottomless Token count per travel and wheel.** It comes from
  the same PDFs' "Technical Specifications" pages (INSTALLED / MAX).
- **Forks: rebound.** No PDF prints rebound clicks. The official setup app,
  RockShox TrailHead (trailhead.rockshox.com), computes them from rider weight
  with a linear formula per model code and travel. Its coefficients are shipped
  in the page data. The result is **counted from closed** ("full
  clockwise/full slow"). Every catalog rebound adjuster counts from open, so:
  - Charger 3 / 3.1 / 3.2 (max 18), Rush RC / Rush RL and Isolator (max 16)
    get `max − N`.
  - Every `max: ~` damper becomes `display_only`.
  - Calculated tables at 5 kg steps are in
    [TrailHead rebound formulas](#guide-rockshox_trailhead_fork_rebound--trailhead-fork-rebound-formulas).
- **Forks: base tune constants** (SRAM Suspension User Manual):
  - Charger 3 / 3.1 / 3.2 RC2 start with HSC and LSC in the middle, which is `0`
    in the catalog's centre-detent ranges.
  - Charger RL / Charger 2 RL / Rush RL start with compression OPEN, which is
    `lockout: false`.
- **Fork SAG:**
  - DebonAir+ and Linear XL forks are set by pressure only. SRAM says no SAG
    procedure is needed.
  - Solo Air, DebonAir and Dual Position Air forks get the generic 10–30 % band
    (20–30 % for longer travel, 10–20 % for shorter).
  - Rudy XPLR: 5 %.
- **Shocks: no per-shock chart.** TrailHead only gives shock recommendations
  after a serial-number lookup. Its shock formula needs per-shock coefficients
  that model-code pages do not expose, plus the frame's rear-wheel travel and
  stroke. What is encodable:
  - starting pressure (psi) = rider weight in lb, including gear (User
    Manual), as a formula;
  - SAG targets: Solo Air ≈25 %, DebonAir ≈30 %, ±5 %; coil 25–35 % (manual)
    or 25–30 % (DH welcome guide); Vivid Air 30 %;
  - compression in the middle (`0`) on RC2T and Vivid Ultimate;
  - the generic TrailHead shock rebound formula, which needs only the damper's
    total click count.
- **Not covered by B3:**
  - an e-bike psi offset;
  - pressure bands whose edge cells are open-ended;
  - per-trim spring variants (DebonAir vs Dual Position Air, 29+ wheels) that
    are not catalog options;
  - a shock pressure formula keyed to rear-wheel travel, stroke and leverage;
  - coil spring-rate formulas;
  - several printed max psi values that disagree with the catalog (BoXXer
    2027: 300 vs 260);
  - one catalog generation (SID SL 2025–2026) that spans two lower-leg codes
    with different charts.

## Shared sources

All guide sections below cite these documents. Retrieved 2026-10-11/12.

| Key | Document | URL |
|---|---|---|
| SPEC2027 | 2027 Front Suspension Specifications (EN), "Air Spring Pressure" pp. 7–11, "Technical Specifications" pp. 13–24 | https://www.sram.com/globalassets/document-hierarchy/service-manuals/rockshox/front-suspension/2027-front-suspension-specifications.pdf |
| SPEC2026 | 2026 Front Suspension Specifications (EN), pressure pp. 8–12, tech specs pp. 14–25 | https://www.sram.com/globalassets/document-hierarchy/service-manuals/rockshox/front-suspension/2026-front-suspension-specifications.pdf |
| SPEC2025 | 2025 Front Suspension Specifications (EN), pressure pp. 8–12 | https://www.sram.com/globalassets/document-hierarchy/service-manuals/rockshox/front-suspension/2025-front-suspension-specifications.pdf |
| SPEC2024 | 2024 Front Suspension Specifications (EN), pressure pp. 8–13 | https://www.sram.com/globalassets/document-hierarchy/service-manuals/rockshox/front-suspension/2024-front-suspension-specifications.pdf |
| SPEC2023 | 2023 Front Suspension Oil, Air, Coil, Token Specifications (EN), pressure pp. 8–12, tech specs pp. 14–25 | https://www.sram.com/globalassets/document-hierarchy/service-manuals/rockshox/front-suspension/2023-front-suspension-oil-air-coil-token-specifications-english.pdf |
| SPEC2022 | 2022 Front Suspension Oil, Air, Coil, Token and Specifications (EN), pressure pp. 8–13 (cross-check only) | https://www.sram.com/globalassets/document-hierarchy/service-manuals/rockshox/front-suspension/2022-front-suspension-oil-air-coil-token-and-specifications-english.pdf |
| UM | RockShox Suspension User Manual (docs.sram.com), sections "Suspension Spring Setup", "Pressurize – DebonAir+ / Linear XL", "Suspension Sag", "Set Sag – Air / Coil Rear Suspension" | https://docs.sram.com/en-US/publications/5ODr3E6BhL1uWDnWhq4ATB |
| TH | RockShox TrailHead web app, `/en/product/<model code>/tuning/setup`. The tune coefficients (`tuneModels`) are in the page data, and the formula is in the page's client script. | https://trailhead.rockshox.com/ |
| C3 | "Charger 3 Setup" (SRAM Learn; served as the German edition from the EU region) | https://www.sram.com/en/rockshox/learn/charger-3-setup |
| SWG | "Suspension Welcome Guide" (German edition served) | https://www.sram.com/en/rockshox/learn/suspension-welcome-guide |
| DHWG | "Downhill Suspension Welcome Guide" (German edition served) | https://www.sram.com/en/rockshox/learn/downhill-suspension-welcome-guide |
| VAS | "Vivid Air Setup" (German edition served) | https://www.sram.com/en/rockshox/learn/vivid-air-setup |

Model-code → catalog generation, from the codes each PDF lists:

| Catalog generation | Model codes |
|---|---|
| `fork/rockshox/pike/2025` | FS-PIKE-ULT-C2, -UFA-C2, -SELP-C2; Base = FS-PIKE-BSE-C1 |
| `fork/rockshox/pike/2023` | FS-PIKE-ULT-C1, -SELP-C1, -BSE-C1 |
| `fork/rockshox/lyrik/2027` | FS-LYRK-ULT-E1, -UFA-E1, -SELP-E1 |
| `fork/rockshox/lyrik/2025` | FS-LYRK-ULT-D2, -UFA-D2, -SELP-D2; Base = FS-LYRK-BSE-D1 |
| `fork/rockshox/lyrik/2023` | FS-LYRK-ULT-D1, -SELP-D1, -BSE-D1 |
| `fork/rockshox/zeb/2027` | FS-ZEB-ULT-B1, -UFA-B1, -SELP-B1 |
| `fork/rockshox/zeb/2025` | FS-ZEB-ULT-A3, -UFA-A3, -SELP-A3; Base = FS-ZEB-BSE-A2 (SPEC2026) |
| `fork/rockshox/zeb/2023` | FS-ZEB-ULT-A2, -SELP-A2, -BSE-A2 |
| `fork/rockshox/boxxer/2027` | FS-BXR-ULT-D2, FS-BXR-SEL-D2 (TH), FS-BXR-BSE-D2 |
| `fork/rockshox/boxxer/2024` | FS-BXR-ULT-D1, FS-BXR-BSE-D1 |
| `fork/rockshox/boxxer/2019` | FS-BXR-ULT-C2, FS-BXR-SEL-C2 |
| `fork/rockshox/sid-sl/2025` | FS-SIDS-ULT2/ULT3/SLP2/SLP3-**D1** (MY24–25 PDFs) and **-E1** (MY26–27 PDFs) |
| `fork/rockshox/sid-sl/2021` | FS-SIDS-ULT-C1, -SELP-C1, -SEL-C1, -BSE-C1 |
| `fork/rockshox/sid/2025` | FS-SID-ULT2/ULT3/SLP2/SLP3-D1 |
| `fork/rockshox/sid/2021` | FS-SID-ULT-C1, -SELP-C1, -SEL-C1, -BSE-C1 |
| `fork/rockshox/reba` | FS-REBA-RL-A9 (PDF); TH data under FS-REBA-10B-A9 / -12B-A9 |
| `fork/rockshox/psylo` | FS-PSYL-GRC-A1 |
| `fork/rockshox/domain` | FS-DOMN-GRC-C1 |
| `fork/rockshox/rudy-xplr` | FS-RUDY-ULT-A1 / -A2 |
| `fork/rockshox/rudy-xl` | FS-RDYX-ULT-A1 |
| `fork/rockshox/yari` | FS-YARI-RC-B3 |
| `fork/rockshox/revelation` | FS-RVL-RC-A3 |
| `fork/rockshox/recon-gold` | FS-RCNG-RL-C1 |

All pressure tables below: input rider weight (lb, kg also printed), output psi band. Edge cells are open bands as printed. The header of every table reads "E-Bikes add 10 psi" (not encoded: the catalog has no e-bike option). TrailHead adds the same +10 psi when its E-Bike toggle is on.

---

## Guide `rockshox_pike_2025` — Front Suspension Specifications 2026/2027, Pike C2

### Source

- URL: SPEC2027 (also identical in SPEC2026 p. 9 and SPEC2025 p. 9)
- Document: 2027 Front Suspension Specifications, MY2027, English
- Section / page: Air Spring Pressure p. 8; Technical Specifications p. 17
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/pike/2025/ultimate` | `damper: charger_3_1` | FS-PIKE-ULT-C2 |
| `fork/rockshox/pike/2025/ultimate-flight-attendant` | `damper: charger_3_1` | FS-PIKE-UFA-C2 |
| `fork/rockshox/pike/2025/select-plus` | `damper: charger_3_1` | FS-PIKE-SELP-C2 |
| `fork/rockshox/pike/2025/base` | `damper: rush_rc` | FS-PIKE-BSE-C1, in the same table |

Gaps:
- The PDF also lists Pike Select (FS-PIKE-SEL-C1, Charger RC), which the
  catalog does not have.
- The PDF lists the Base damper as Rush RC, which matches the catalog.

### Air pressure — DebonAir+, 27.5" B / 29" B

Input: rider weight · Output: psi · `when: { travel_mm: … }`

| Rider weight (lb) | Rider weight (kg) | 120 mm | 130-140 mm |
|---|---|---|---|
| <120 | <55 | <60 | <50 |
| 120-140 | 55-63 | 60-70 | 50-60 |
| 140-160 | 63-72 | 70-80 | 60-70 |
| 160-180 | 72-81 | 80-90 | 70-80 |
| 180-200 | 81-90 | 90-100 | 80-90 |
| 200-220 | 90-99 | 100-110 | 90-100 |
| >220 | >99 | 110+ | 100+ |

TrailHead cross-check: psi = 0.5 × lb + b, with b = 0 at 120 mm and −10 at 130/140 mm. It reproduces every bracket bound.

### Rebound

Source: TH, from closed. Formulas `C3-A` (120 mm) and `C3-B` (130–140 mm) for ULT/UFA/SELP-C2; `RUSH-P120` / `RUSH-P130` for BSE-C1.
- Catalog `charger_3_1` `rebound`, `dial_ccw`, max 18, from open → opposite direction, use the precomputed `18 − N` columns.
- Catalog `rush_rc` `rebound`, max 16 → use `16 − N`.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 0 | middle detent (catalog −2..+2) | `damper: charger_3_1` |
| `lsc` | 0 | middle detent (catalog −7..+7); Flight Attendant: "middle (5 or 6)" on the FA scale | `damper: charger_3_1` |

Source: UM "Charger 3, 3.1 – RC2" step 11 and "Charger 3.1 Flight Attendant" step 11; C3 says the same. Rush RC: compression OPEN to start. The catalog has no compression adjuster for `rush_rc`, so it is not encoded.

### SAG

None. DebonAir+ is set by pressure. UM: "does not require the 'Set Sag' procedure".

### Volume spacers

Factory-installed Bottomless Tokens (SPEC2027 p. 17, same for 27.5" B and 29" B):

| travel_mm | Installed | Max |
|---|---|---|
| 120 | 1 | 6 |
| 130 | 0 | 6 |
| 140 | 0 | 5 |

### Pressure limits

163 psi for all travels. The catalog has no Pressure max; candidate `max: 163`.

---

## Guide `rockshox_pike_2023` — Front Suspension Specifications 2023, Pike C1

### Source

- URL: SPEC2023 (identical in SPEC2024 p. 10)
- Document: 2023 Front Suspension Oil, Air, Coil, Token Specifications, MY2023, English
- Section / page: Air Spring Pressure p. 10; Technical Specifications p. 19
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/pike/2023/ultimate` | `damper: charger_3` | FS-PIKE-ULT-C1 |
| `fork/rockshox/pike/2023/select-plus` | `damper: charger_3` | FS-PIKE-SELP-C1 |
| `fork/rockshox/pike/2023/base` | `damper: rush_rc` | FS-PIKE-BSE-C1 |

Gaps: the PDF also covers Pike Ultimate Flight Attendant C1 and Pike Select C1. The catalog has no 2023 FA or Select trim.

### Air pressure — DebonAir+, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 120 mm | 130-140 mm |
|---|---|---|---|
| <120 | <55 | <55 | <45 |
| 120-140 | 55-63 | 55-65 | 45-55 |
| 140-160 | 63-72 | 65-75 | 55-65 |
| 160-180 | 72-81 | 75-85 | 65-75 |
| 180-200 | 81-90 | 85-95 | 75-85 |
| 200-220 | 90-99 | 95-105 | 85-95 |
| >220 | >99 | 105+ | 95+ |

The values differ from the 2025 C2 table (5 psi lower). TrailHead uses b = −5 (120 mm) and −15 (130/140 mm) with 0.5 × lb.

### Rebound

TH: ULT-C1/SELP-C1 use `C3-A` (120) and `C3-B` (130–140). BSE-C1 uses `RUSH-P120` / `RUSH-P130`. Catalog `charger_3` max 18 → `18 − N`; `rush_rc` max 16 → `16 − N`.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 0 | middle | `damper: charger_3` |
| `lsc` | 0 | middle | `damper: charger_3` |

### SAG

None (DebonAir+).

### Volume spacers

SPEC2023 p. 19: 120 mm → 1 (max 6); 130 mm → 0 (max 6); 140 mm → 0 (max 5). Same for both wheels.

### Pressure limits

120 mm: 194 psi. 130-140 mm: 163 psi.

---

## Guide `rockshox_lyrik_2027` — Front Suspension Specifications 2027, Lyrik E1

### Source

- URL: SPEC2027
- Section / page: Air Spring Pressure p. 8; Technical Specifications p. 16
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/lyrik/2027/ultimate` | `damper: charger_3_2` | FS-LYRK-ULT-E1 |
| `fork/rockshox/lyrik/2027/ultimate-flight-attendant` | `damper: charger_3_2` | FS-LYRK-UFA-E1 |
| `fork/rockshox/lyrik/2027/select-plus` | `damper: charger_3_2` | FS-LYRK-SELP-E1 |

Gaps:
- The table also covers Lyrik Select E1 (Delta RC), which is not in the catalog.
- The PDF has a separate DebonAir+ table for Lyrik Base D2 (Delta RC, 140 /
  150-160 mm). Its values are identical to the 2025 table below. It is not in
  the catalog.

### Air pressure — Linear XL, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 140 mm | 150 mm | 160 mm | 170 mm |
|---|---|---|---|---|---|
| <120 | <55 | <114 | <104 | <94 | <84 |
| 120-140 | 55-63 | 114-133 | 104-123 | 94-113 | 84-103 |
| 140-160 | 63-72 | 133-150 | 123-140 | 113-130 | 103-120 |
| 160-180 | 72-81 | 150-163 | 140-153 | 130-143 | 120-133 |
| 180-200 | 81-90 | 163-174 | 153-164 | 143-154 | 133-144 |
| 200-220 | 90-99 | 174-181 | 164-171 | 154-161 | 144-151 |
| >220 | >99 | 181+ | 171+ | 161+ | 151+ |

TrailHead uses a quadratic: psi = −0.003646673·lb² + 1.91752141·lb + b, with b = −63.86131965 / −73.86 / −83.86132 / −93.86 at 140 / 150 / 160 / 170 mm.

### Rebound

TH: `C3-A` at 140/150 mm, `C3-B` at 160/170 mm. Catalog `charger_3_2` rebound max 18 is an **estimate**, so `18 − N` inherits that uncertainty. Encode it only once the 3.2 total is confirmed, otherwise use `display_only`.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `hsc` | 0 | middle | `damper: charger_3_2` |
| `lsc` | 0 | middle (FA: "middle (5 or 6)") | `damper: charger_3_2` |

UM "Charger 3.2 RC2" step 11, "Charger 3.2 Flight Attendant" step 11.

### SAG

None (Linear XL is set by pressure; UM).

### Volume spacers

SPEC2027 p. 16 (both wheels): 140 → installed 1 (max 5); 150 → 0 (max 4); 160 → 0 (max 4); 170 → 0 (max 3). **The catalog Lyrik 2027 has no `volume_spacers` adjuster**, so this is not encodable until one is added.

### Pressure limits

300 psi, which matches the catalog `max: 300`.

---

## Guide `rockshox_lyrik_2025` — Front Suspension Specifications 2026, Lyrik D2

### Source

- URL: SPEC2026 (identical in SPEC2025 p. 9)
- Section / page: Air Spring Pressure p. 9; Technical Specifications p. 17
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/lyrik/2025/ultimate` | `damper: charger_3_1` | FS-LYRK-ULT-D2 |
| `fork/rockshox/lyrik/2025/ultimate-flight-attendant` | `damper: charger_3_1` | FS-LYRK-UFA-D2 |
| `fork/rockshox/lyrik/2025/select-plus` | `damper: charger_3_1` | FS-LYRK-SELP-D2 |
| `fork/rockshox/lyrik/2025/base` | `damper: rush_rc` | FS-LYRK-BSE-D1 |

Gaps: Lyrik Select D1 (Charger RC) is not in the catalog.

### Air pressure — DebonAir+, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 140 mm | 150-160 mm |
|---|---|---|---|
| <120 | <55 | <60 | <50 |
| 120-140 | 55-63 | 60-70 | 50-60 |
| 140-160 | 63-72 | 70-80 | 60-70 |
| 160-180 | 72-81 | 80-90 | 70-80 |
| 180-200 | 81-90 | 90-100 | 80-90 |
| 200-220 | 90-99 | 100-110 | 90-100 |
| >220 | >99 | 110+ | 100+ |

### Rebound

TH: ULT/UFA/SELP-D2 use `C3-A` (140) and `C3-B` (150–160) → `18 − N`. BSE-D1 uses `BASE-A` (140) and `BASE-B` (150–160) → `16 − N` (`rush_rc`).

### Constants / base tune

`hsc` 0 and `lsc` 0 for `damper: charger_3_1` (middle).

### SAG

None.

### Volume spacers

SPEC2026 p. 17 (both wheels, all D2/D1 trims): 140 → 1; 150 → 0; 160 → 0; max 5.

### Pressure limits

163 psi (catalog has none).

---

## Guide `rockshox_lyrik_2023` — Front Suspension Specifications 2023, Lyrik D1

### Source

- URL: SPEC2023, Air Spring Pressure p. 9; Technical Specifications p. 18
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/lyrik/2023/ultimate` | `damper: charger_3` | FS-LYRK-ULT-D1 |
| `fork/rockshox/lyrik/2023/select-plus` | `damper: charger_3` | FS-LYRK-SELP-D1 |
| `fork/rockshox/lyrik/2023/base` | `damper: rush_rc` | FS-LYRK-BSE-D1 |

### Air pressure — DebonAir+

Numerically identical to the `rockshox_lyrik_2025` table (140 mm: <60 … 110+; 150-160 mm: <50 … 100+), max 163 psi.

### Rebound

As in 2025: `C3-A` / `C3-B` → `18 − N` (`charger_3`); BSE-D1 uses `BASE-A` / `BASE-B` → `16 − N`.

### Constants, SAG, spacers

- `hsc` 0 and `lsc` 0 (`damper: charger_3`). No SAG.
- Tokens (SPEC2023 p. 18): 140 → 1; 150 → 0; 160 → 0; max 5.

---

## Guide `rockshox_zeb_2027` — Front Suspension Specifications 2027, ZEB B1

### Source

- URL: SPEC2027, Air Spring Pressure p. 11; Technical Specifications p. 24
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/zeb/2027/ultimate` | `damper: charger_3_2` | FS-ZEB-ULT-B1 |
| `fork/rockshox/zeb/2027/ultimate-flight-attendant` | `damper: charger_3_2` | FS-ZEB-UFA-B1 |
| `fork/rockshox/zeb/2027/select-plus` | `damper: charger_3_2` | FS-ZEB-SELP-B1 |

Gaps:
- ZEB Select B1 (Charger 3.2 RC) is not in the catalog.
- ZEB Base A3 has its own DebonAir+ table (values = 2025 table, 150-160 /
  170-180 rows, max 148) and is not in the catalog for 2027.

### Air pressure — Linear XL, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 150 mm | 160 mm | 170 mm | 180 mm |
|---|---|---|---|---|---|
| <120 | <55 | <106 | <96 | <86 | <76 |
| 120-140 | 55-63 | 106-125 | 96-115 | 86-105 | 76-95 |
| 140-160 | 63-72 | 125-142 | 115-132 | 105-122 | 95-112 |
| 160-180 | 72-81 | 142-157 | 132-147 | 122-137 | 112-127 |
| 180-200 | 81-90 | 157-170 | 147-160 | 137-150 | 127-140 |
| 200-220 | 90-99 | 170-181 | 160-171 | 150-161 | 140-151 |
| >220 | >99 | 181+ | 171+ | 161+ | 151+ |

TrailHead: psi = −0.002435232·lb² + 1.576350766·lb + b, with b = −47.79695127 / −57.80 / −67.79695127 / −77.80 at 150–180 mm.

### Rebound

TH: `C3-A` at 150/160 mm, `C3-B` at 170/180 mm. `charger_3_2` max 18 is an estimate (see Lyrik 2027).

### Constants / base tune

`hsc` 0 and `lsc` 0 for `damper: charger_3_2`.

### SAG

None.

### Volume spacers

SPEC2027 p. 24 (both wheels):

| travel_mm | Installed | Max |
|---|---|---|
| 150 | 1 | 5 |
| 160 | 1 | 4 |
| 170 | 0 | 4 |
| 180 | 0 | 3 |

**The catalog ZEB 2027 has no `volume_spacers` adjuster.**

### Pressure limits

300 psi, which matches the catalog.

---

## Guide `rockshox_zeb_2025` — Front Suspension Specifications 2026, ZEB A3

### Source

- URL: SPEC2026, Air Spring Pressure p. 12; Technical Specifications p. 25 (SPEC2025 p. 12 identical)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/zeb/2025/ultimate` | `damper: charger_3_1` | FS-ZEB-ULT-A3 |
| `fork/rockshox/zeb/2025/ultimate-flight-attendant` | `damper: charger_3_1` | FS-ZEB-UFA-A3 |
| `fork/rockshox/zeb/2025/select-plus` | `damper: charger_3_1` | FS-ZEB-SELP-A3 |
| `fork/rockshox/zeb/2025/base` | `damper: rush_rc` | FS-ZEB-BSE-A2 |

Gaps:
- SPEC2023/2026 list the ZEB Base damper as **Charger R**, while the catalog
  has `rush_rc`. Flagged as a follow-up.
- The Dual Position Air rows (ZEB Select/Base A2, "Featured on E-MTB models
  only") have no catalog spring option. They are transcribed in the 2023 guide.

### Air pressure — DebonAir+, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 150-160 mm | 170-180 mm | 190 mm |
|---|---|---|---|---|
| <120 | <55 | <45 | <37 | <29 |
| 120-140 | 55-63 | 45-54 | 37-45 | 29-37 |
| 140-160 | 63-72 | 54-62 | 45-54 | 37-46 |
| 160-180 | 72-81 | 62-70 | 54-62 | 46-54 |
| 180-200 | 81-90 | 70-78 | 62-70 | 54-62 |
| 200-220 | 90-99 | 78-87 | 70-78 | 62-70 |
| >220 | >99 | 87+ | 78+ | 70+ |

### Rebound

TH:
- ULT/UFA/SELP-A3 use `C3-A` (150–160), `C3-B` (170–180) and `C3-C` (190)
  → `18 − N`. TH lists no 190 mm entry for UFA-A3.
- BSE-A2 uses `BASE-A` (150–160), `BASE-B` (170–180) and `BASE-C` (190)
  → `16 − N` if the damper really is `rush_rc`.

### Constants / base tune

`hsc` 0 and `lsc` 0 for `damper: charger_3_1`.

### SAG

None.

### Volume spacers

SPEC2026 p. 25 (both wheels):

| travel_mm | Installed | Max |
|---|---|---|
| 150 | 2 | 5 |
| 160 | 1 | 5 |
| 170 | 1 | 4 |
| 180 | 0 | 4 |
| 190 | 0 | 4 |

### Pressure limits

148 psi.

---

## Guide `rockshox_zeb_2023` — Front Suspension Specifications 2023, ZEB A2

### Source

- URL: SPEC2023, Air Spring Pressure p. 12; Technical Specifications p. 25
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/zeb/2023/ultimate` | `damper: charger_3` | FS-ZEB-ULT-A2 |
| `fork/rockshox/zeb/2023/select-plus` | `damper: charger_3` | FS-ZEB-SELP-A2 |
| `fork/rockshox/zeb/2023/base` | `damper: rush_rc` | FS-ZEB-BSE-A2 (PDF damper: Charger R) |

### Air pressure — DebonAir+

Numerically identical to `rockshox_zeb_2025` (three rows), max 148 psi.

### Air pressure — Dual Position Air (E-MTB only; no catalog option, not encoded)

| Rider weight (lb) | Rider weight (kg) | 160 mm | 170-180 mm |
|---|---|---|---|
| <120 | <55 | <55 | <47 |
| 120-140 | 55-63 | 55-64 | 47-55 |
| 140-160 | 63-72 | 64-72 | 55-64 |
| 160-180 | 72-81 | 72-80 | 64-72 |
| 180-200 | 81-90 | 80-88 | 72-80 |
| 200-220 | 90-99 | 88-97 | 80-88 |
| >220 | >99 | 97+ | 88+ |

Max 148 psi.

### Rebound, constants, spacers

- Rebound: ULT/SELP-A2 use `C3-A` / `C3-B` / `C3-C` → `18 − N`; BSE-A2 uses
  `BASE-A/B/C`.
- `hsc` 0 and `lsc` 0 (`damper: charger_3`).
- Tokens (SPEC2023 p. 25, DebonAir+): 150 → 2; 160 → 1; 170 → 1; 180 → 0;
  190 → 0; max 5 (150–160) and 4 (170–190).

---

## Guide `rockshox_boxxer_2027` — Front Suspension Specifications 2027, BoXXer D2

### Source

- URL: SPEC2027, Air Spring Pressure p. 7; Technical Specifications p. 13
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/boxxer/2027/ultimate` | `damper: charger_3_2` | FS-BXR-ULT-D2 |
| `fork/rockshox/boxxer/2027/select` | `damper: charger_3_2` | FS-BXR-SEL-D2 (in TH, not in the PDF) |

Gaps:
- The PDF names the springs per wheel: DebonAir+ for 27.5" B and Linear XL for
  29" B. Both share one pressure table.
- BoXXer Base D2 (Charger 3.2 RC) is in the PDF but not in the catalog.

### Air pressure — 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 180 mm | 190-200 mm |
|---|---|---|---|
| <120 | <55 | <115 | <90 |
| 120-140 | 55-63 | 115-140 | 90-110 |
| 140-160 | 63-72 | 140-165 | 110-130 |
| 160-180 | 72-81 | 165-190 | 130-150 |
| 180-200 | 81-90 | 190-215 | 150-170 |
| 200-220 | 90-99 | 215-240 | 170-190 |
| >220 | >99 | 240+ | 190+ |

TrailHead: 180 mm psi = 1.25 × lb − 35; 190/200 mm psi = 1.0 × lb − 30.

### Rebound

TH: `BXR-D-180` (180 mm) and `BXR-D-190` (190/200 mm). `charger_3_2` max 18 is an estimate.

### Constants / base tune

`hsc` 0 and `lsc` 0 (`damper: charger_3_2`). UM "Charger 3-3.2 RC2 – BoXXer Gen D" step 10. DHWG agrees.

### SAG

None (UM: DebonAir+ and Linear XL need no Set Sag procedure).

### Volume spacers

SPEC2027 p. 13: 180 → 1; 190 → 0; 200 → 0; max 6 (both wheels). **The catalog has no `volume_spacers` adjuster for this generation.**

### Pressure limits

The PDF prints **300 psi**, but the catalog has `max: 260` (from the support knowledge base). Conflict, see Follow-ups.

---

## Guide `rockshox_boxxer_2024` — Front Suspension Specifications 2026, BoXXer D1

### Source

- URL: SPEC2026, Air Spring Pressure p. 8; Technical Specifications p. 14 (SPEC2025 p. 8 identical)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/boxxer/2024/ultimate` | `damper: charger_3_1` / `damper: charger_3` | FS-BXR-ULT-D1 |
| `fork/rockshox/boxxer/2024/select` | `damper: charger_3_1` / `damper: charger_3` | No D1 Select code exists. The PDF has FS-BXR-BSE-D1 (Charger 3 RC). Assume the same chart. |

### Air pressure — DebonAir+, 27.5" B / 29" B

Numerically identical to the `rockshox_boxxer_2027` table (180 mm: <115 … 240+; 190-200 mm: <90 … 190+). Same TrailHead coefficients.

### Rebound

TH: `BXR-D-180` / `BXR-D-190` → `18 − N` (`charger_3`, `charger_3_1`, max 18).

### Constants, SAG, spacers

- `hsc` 0 and `lsc` 0. No SAG.
- Tokens (SPEC2026 p. 14): 180 → 1; 190 → 0; 200 → 0; max 6. No catalog
  `volume_spacers` adjuster for this generation.

### Pressure limits

The PDF prints 300 psi. The TrailHead serial page for FS-BXR-ULT-D1 states "Maximum air pressure should not exceed 260 psi" (attribute `Max Air Pressure (PSI)`: 260). Conflict, see Follow-ups. The catalog has no max.

---

## Guide `rockshox_boxxer_2019` — Front Suspension Specifications 2023, BoXXer C2

### Source

- URL: SPEC2023, Air Spring Pressure p. 8; Technical Specifications p. 16 (SPEC2022 p. 8 identical)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/boxxer/2019/ultimate` | `damper: charger_2_1_rc2` | FS-BXR-ULT-C2 (generation is `draft`) |
| `fork/rockshox/boxxer/2019/select` | `damper: charger_2_1_rc2` | FS-BXR-SEL-C2; the PDF lists its damper as Charger RC |

### Air pressure — DebonAir, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 180 mm | 190-200 mm |
|---|---|---|---|
| <120 | <55 | <105 | <95 |
| 120-140 | 55-63 | 105-115 | 95-105 |
| 140-160 | 63-72 | 115-125 | 105-115 |
| 160-180 | 72-81 | 125-135 | 115-125 |
| 180-200 | 81-90 | 135-145 | 125-135 |
| 200-220 | 90-99 | 145-155 | 135-145 |
| >220 | >99 | 155+ | 145+ |

### Rebound

TH: `BXR-C-180` / `BXR-C-190`. Catalog `charger_2_1_rc2` rebound has `max: ~`, so it is `display_only` ("N clicks from closed").

### SAG

DebonAir: generic fork band 10–30 % (UM). Not model-specific.

### Volume spacers

SPEC2023 p. 16: 180 → 2; 190 → 1; 200 → 0 (27.5" B 200 mm also 0); max 6. This matches the catalog `volume_spacers` max 6.

### Pressure limits

200 psi.

---

## Guide `rockshox_sid_sl_2025` — Front Suspension Specifications 2027, SID SL E1 (and D1)

### Source

- URL: SPEC2027 p. 10 (E1; identical in SPEC2026 p. 11); SPEC2025 p. 11 / SPEC2024 p. 11 (D1)
- Technical Specifications: SPEC2027 p. 23
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/sid-sl/2025/ultimate` | `damper: charger_race_day_2` | E1 = MY26+, D1 = MY24–25. The generation is `draft`. |
| `fork/rockshox/sid-sl/2025/select-plus` | `damper: charger_race_day_2` | as above |

Gaps:
- The catalog generation (2025–2026) spans two lower-leg codes with different
  charts. A `when:` cannot split them, so this needs a catalog decision, see
  Follow-ups.
- The catalog travel options are 100/110, and the PDFs print "100-110".

### Air pressure — 29" B, 100-110 mm

| Rider weight (lb) | Rider weight (kg) | E1, DebonAir+ (SPEC2026/2027) | D1, DebonAir (SPEC2024/2025) |
|---|---|---|---|
| <120 | <55 | <85 | <70 |
| 120-140 | 55-63 | 85-95 | 70-90 |
| 140-160 | 63-72 | 95-108 | 90-105 |
| 160-180 | 72-81 | 108-120 | 105-120 |
| 180-200 | 81-90 | 120-132 | 120-135 |
| >200 | >90 | 132+ | 135+ |

Max: 195 psi (both).

TrailHead: E1 uses 0.5457 × lb + b (b = 52.876 / 32.876 / 22.876 at 90 / 100 / 110 mm). This does **not** reproduce the E1 decal (120 lb → 98 psi vs "<85"). D1 uses 0.7851 × lb − 23.19 and matches the D1 decal. Encode the decal.

### Rebound

TH: E1 uses `SIDSL-E1`; D1 uses `SID-D1`. `charger_race_day_2` rebound has `max: ~`, so it is `display_only`.

### SAG / spacers

- No SAG (DebonAir+ for E1). D1 is DebonAir, so the generic 10–30 % band
  applies.
- Tokens (SPEC2027 p. 23): 0 installed, max 3. The catalog has no
  `volume_spacers` for this generation.

---

## Guide `rockshox_sid_sl_2021` — Front Suspension Specifications 2023, SID SL C1

### Source

- URL: SPEC2023, Air Spring Pressure p. 11; Technical Specifications p. 23 (SPEC2022 p. 12 identical)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/sid-sl/2021/ultimate` | `damper: charger_race_day` | FS-SIDS-ULT-C1 (`draft`) |
| `fork/rockshox/sid-sl/2021/select-plus` | `damper: charger_2_rl` | FS-SIDS-SELP-C1 |
| `fork/rockshox/sid-sl/2021/select` | `damper: charger_rl` | FS-SIDS-SEL-C1 |
| `fork/rockshox/sid-sl/2021/base` | `damper: rush_rl` | FS-SIDS-BSE-C1 |

Gaps: the PDF prints only 100 mm, while the catalog also offers `travel_mm: 80`. 80 mm is not covered (TrailHead also lists only 100).

### Air pressure — DebonAir, 29" B, 100 mm

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| <120 | <55 | <70 |
| 120-140 | 55-63 | 70-90 |
| 140-160 | 63-72 | 90-105 |
| 160-180 | 72-81 | 105-120 |
| 180-200 | 81-90 | 120-135 |
| >200 | >90 | 135+ |

Max 195 psi. `when: { travel_mm: 100 }`.

### Rebound

TH has a per-trim formula: ULT `SIDSL-C1-ULT`, SELP `SIDSL-C1-SELP`, SEL `SIDSL-C1-SEL`, BSE `SIDSL-C1-BSE`.
- `rush_rl` (max 16) → `16 − N`.
- Charger Race Day, Charger 2 RL and Charger RL have `max: ~` → `display_only`.

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `lockout` | false (open) | — | `damper: charger_2_rl`, `charger_rl`, `rush_rl` |

UM "Charger RC, RL, Race Day 2" and "Rush RC, Rush RL" step 11: compression adjuster OPEN to start.

### SAG

DebonAir: generic fork band 10–30 % (UM). The shorter-travel guidance is 10–20 %.

### Volume spacers

SPEC2023 p. 23: 100 mm → 0 installed, max 3. This matches the catalog max 3.

---

## Guide `rockshox_sid_2025` — Front Suspension Specifications 2027, SID D1

### Source

- URL: SPEC2027 p. 11 (identical in SPEC2024 p. 12, SPEC2025 p. 11, SPEC2026 p. 11); tech specs SPEC2027 p. 23
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/sid/2025/ultimate` | `damper: charger_race_day_2` | FS-SID-ULT2/ULT3-D1 (`draft`) |
| `fork/rockshox/sid/2025/select-plus` | `damper: charger_race_day_2` | FS-SID-SLP2/SLP3-D1 |

### Air pressure — DebonAir+, 29" B, 100-120 mm

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| <100 | <45 | <39 |
| 100-120 | 45-55 | 39-51 |
| 120-140 | 55-63 | 51-64 |
| 140-160 | 63-72 | 64-76 |
| 160-180 | 72-81 | 76-87 |
| 180-200 | 81-90 | 87-99 |
| >200 | >90 | 100+ |

Max 150 psi. Note that this table's first bracket is <100 lb, unlike most others.

### Rebound

TH `SID-D1` (all travels). `charger_race_day_2` has `max: ~` → `display_only`.

### SAG / spacers

- No SAG (DebonAir+).
- Tokens (SPEC2027 p. 23): 100 → 1; 110 → 1; 120 → 0; max 3. The catalog has
  no `volume_spacers` for this generation.

---

## Guide `rockshox_sid_2021` — Front Suspension Specifications 2023, SID C1

### Source

- URL: SPEC2023 p. 11; tech specs p. 23 (SPEC2022 p. 12 identical)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/sid/2021/ultimate` | `damper: charger_race_day` | FS-SID-ULT-C1 (`draft`) |
| `fork/rockshox/sid/2021/select-plus` | `damper: charger_2_rl` | FS-SID-SELP-C1 |
| `fork/rockshox/sid/2021/select` | `damper: charger_rl` | FS-SID-SEL-C1 |
| `fork/rockshox/sid/2021/base` | `damper: rush_rl` | FS-SID-BSE-C1 |

Gaps: the PDF prints 110-120 mm only. The catalog `travel_mm: 100` is not covered.

### Air pressure — DebonAir, 29" B, 110-120 mm

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| <120 | <55 | <45 |
| 120-140 | 55-63 | 45-59 |
| 140-160 | 63-72 | 59-73 |
| 160-180 | 72-81 | 73-87 |
| 180-200 | 81-90 | 87-101 |
| >200 | >90 | 101+ |

Max 146 psi.

### Rebound

TH per trim: `SID-C1-ULT`, `SID-C1-SELP`, `SID-C1-SEL`, `SID-C1-BSE`. `rush_rl` → `16 − N`; the others → `display_only`.

### Constants, SAG, spacers

- `lockout: false` for `charger_2_rl`, `charger_rl`, `rush_rl`.
- SAG: generic 10–30 %.
- Tokens (SPEC2023 p. 23): 110 → 1; 120 → 0; max 3.

---

## Guide `rockshox_reba_2024` — Front Suspension Specifications 2024, Reba A9

### Source

- URL: SPEC2024 p. 10 (identical in SPEC2023 p. 10, SPEC2022 p. 11); tech specs SPEC2023 p. 19
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/reba/rl` | `damper: motion_control_rl` | FS-REBA-RL-A9 |
| `fork/rockshox/reba/gold-rl` | `damper: motion_control_rl` | No separate Gold table for A-series. Assume the same chassis. |

Gaps:
- The 2026+ Reba B1 (DebonAir, 80 / 100-110 / 120-130) has its own table (SPEC2026 p. 10) and is not in the catalog.
- The table's spring is printed as Solo Air.

### Air pressure — Solo Air, 27.5" B / 29" B, 100-120 mm

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| <120 | <55 | <70 |
| 120-140 | 55-63 | 70-90 |
| 140-160 | 63-72 | 90-105 |
| 160-180 | 72-81 | 105-120 |
| 180-200 | 81-90 | 120-135 |
| >200 | >90 | 135+ |

Max 195 psi.

### Rebound

TH (FS-REBA-12B-A9 / -10B-A9): `REBA-100` (100 mm), `REBA-110` (110/120 mm). `motion_control_rl` has `max: ~` → `display_only`.

### Constants, SAG, spacers

- `lockout: false` is **not** stated for Motion Control in the UM's
  starting-setting list. Only the Set Sag procedure opens all dampers. Not
  encoded.
- SAG: Solo Air, generic 10–30 %.
- Tokens (SPEC2023 p. 19, both wheels): 100 → 0 (max 3); 110 → 1 (max 4);
  120 → 0 (max 4). This matches the catalog note "3 maximum at 100mm".

---

## Guide `rockshox_psylo_2027` — Front Suspension Specifications 2027, Psylo Gold A1

### Source

- URL: SPEC2027 p. 9 (identical in SPEC2026 p. 9, SPEC2025 p. 10); tech specs SPEC2027 p. 17
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/psylo/gold-rc` | `damper: isolator` | FS-PSYL-GRC-A1 / GRCF-A1 (ABS) |

Gaps: Psylo Silver (Solo Air) has its own table and is not in the catalog.

### Air pressure — DebonAir, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 130 mm "(100-120)" | 140-160 mm |
|---|---|---|---|
| <120 | <55 | <100 | <75 |
| 120-140 | 55-63 | 100-110 | 75-85 |
| 140-160 | 63-72 | 110-120 | 85-95 |
| 160-180 | 72-81 | 120-130 | 95-105 |
| 180-200 | 81-90 | 130-140 | 105-115 |
| 200-220 | 90-99 | 140-150 | 115-125 |
| >220 | >99 | 150+ | 125+ |

The travel cell is printed "130 (100-120)". The catalog offers 130–160. Use `travel_mm: 130` for the first column.

### Rebound

TH: `PSYL-130` (100/120/130 mm) and `PSYL-140` (140–160 mm). `isolator` max 16 → `16 − N`.

### Constants, SAG, spacers

- No starting compression position is stated for Isolator.
- SAG: DebonAir, generic 10–30 %.
- Tokens (SPEC2027 p. 17): 0 installed, max 2. The catalog has no
  `volume_spacers` for Psylo.

### Pressure limits

194 psi.

---

## Guide `rockshox_domain_2027` — Front Suspension Specifications 2027, Domain Gold RC C1

### Source

- URL: SPEC2027 p. 7 (identical in SPEC2026 p. 8, SPEC2025 p. 8); tech specs SPEC2027 p. 13
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/domain/gold-rc` | `damper: isolator` | FS-DOMN-GRC-C1 |

### Air pressure — DebonAir, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 130-150 mm | 160-180 mm |
|---|---|---|---|
| <120 | <55 | <45 | <37 |
| 120-140 | 55-63 | 45-54 | 37-45 |
| 140-160 | 63-72 | 54-62 | 45-54 |
| 160-180 | 72-81 | 62-70 | 54-62 |
| 180-200 | 81-90 | 70-78 | 62-70 |
| 200-220 | 90-99 | 78-87 | 70-78 |
| >220 | >99 | 87+ | 78+ |

The catalog travel is 150–180, so 150 falls in the first column.

### Rebound

TH: `DOMN-150` (130–150 mm), `DOMN-160` (160–180 mm). `isolator` max 16 → `16 − N`.

### SAG / spacers

- SAG: DebonAir, generic 10–30 %.
- Tokens (SPEC2027 p. 13, both wheels): 130–160 → 2; 170 → 1; 180 → 0;
  max 3. The catalog has no `volume_spacers` for Domain.

### Pressure limits

148 psi.

---

## Guide `rockshox_rudy_xplr_2027` — Front Suspension Specifications 2027, Rudy XPLR

### Source

- URL: SPEC2027 p. 10 (identical in SPEC2023 p. 11, SPEC2024–2026); UM "Set Sag – Air Spring – Front Suspension"
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/rudy-xplr/ultimate` | `damper: charger_race_day_2`, `damper: charger_race_day` | FS-RUDY-ULT-A1 / A2 (`draft`) |

### Air pressure — Solo Air, 700c, 30 / 40 mm (one column for both)

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| <120 | <55 | <90 |
| 120-140 | 55-63 | 90-110 |
| 140-160 | 63-72 | 110-130 |
| 160-180 | 72-81 | 130-150 |
| 180-200 | 81-90 | 150-170 |
| >200 | >90 | 170+ |

Max 200 psi.

### Rebound

TH `RUDY` → `display_only` (both dampers have `max: ~`).

### SAG

UM: "Rudy XPLR: Target sag is 5%." `sag` value 5 for all Rudy XPLR.

### Volume spacers

None ("-" in the PDF). This matches the catalog note.

---

## Guide `rockshox_rudy_xl_2027` — Front Suspension Specifications 2027, Rudy XL

### Source

- URL: SPEC2027 p. 10 (identical in SPEC2026 p. 11)
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/rudy-xl/ultimate` | `damper: charger_race_day_2` | FS-RDYX-ULT-A1 (`draft`) |

### Air pressure — Solo Air, 700c, 50 / 60 mm

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| <120 | <55 | <75 |
| 120-140 | 55-63 | 75-85 |
| 140-160 | 63-72 | 85-98 |
| 160-180 | 72-81 | 98-110 |
| 180-200 | 81-90 | 110-122 |
| >200 | >90 | 122+ |

Max 200 psi.

### Rebound / SAG / spacers

- Rebound: TH `RDYX` → `display_only`.
- SAG: the UM 5 % rule names only Rudy XPLR, so it is not applied here.
- Tokens: none.

---

## Guide `rockshox_yari_2024` — Front Suspension Specifications 2024, Yari RC B3

### Source

- URL: SPEC2024 p. 12 (identical in SPEC2023 p. 12, SPEC2022 p. 12); tech specs SPEC2023 pp. 23–24
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/yari/rc` | `damper: motion_control_rc` | FS-YARI-RC-B3 (`draft`; years 2016–2023) |

Gaps:
- The 29+ wheel rows (100–160 mm) and the Dual Position Air rows have no
  catalog option. They are transcribed but not encoded.
- Older Yari codes (A1, B1, B2) were not checked separately.

### Air pressure — DebonAir, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 150-160 mm | 170-180 mm |
|---|---|---|---|
| <120 | <55 | <55 | <45 |
| 120-140 | 55-63 | 55-65 | 45-55 |
| 140-160 | 63-72 | 65-75 | 55-65 |
| 160-180 | 72-81 | 75-85 | 65-75 |
| 180-200 | 81-90 | 85-95 | 75-85 |
| 200-220 | 90-99 | 95-105 | 85-95 |
| >220 | >99 | 105+ | 95+ |

Max: 163 psi (150-160), 148 psi (170-180).

### Air pressure — DebonAir, 29+ (not encoded)

| Rider weight (lb) | Rider weight (kg) | 100 | 110-120 | 130-140 | 150-160 |
|---|---|---|---|---|---|
| <120 | <55 | <85 | <75 | <65 | <55 |
| 120-140 | 55-63 | 85-95 | 75-85 | 65-75 | 55-65 |
| 140-160 | 63-72 | 95-105 | 85-95 | 75-85 | 65-75 |
| 160-180 | 72-81 | 105-115 | 95-105 | 85-95 | 75-85 |
| 180-200 | 81-90 | 115-125 | 105-115 | 95-105 | 85-95 |
| 200-220 | 90-99 | 125-135 | 115-125 | 105-115 | 95-105 |
| >220 | >99 | 135+ | 125+ | 115+ | 105+ |

Max: 194 psi (100, 110-120), 163 psi (130-140, 150-160).

### Air pressure — Dual Position Air (E-MTB only; not encoded)

| Rider weight (lb) | Rider weight (kg) | 160 mm | 170-180 mm |
|---|---|---|---|
| <120 | <55 | <65 | <55 |
| 120-140 | 55-63 | 65-75 | 55-65 |
| 140-160 | 63-72 | 75-85 | 65-75 |
| 160-180 | 72-81 | 85-95 | 75-85 |
| 180-200 | 81-90 | 95-105 | 85-95 |
| 200-220 | 90-99 | 105-115 | 95-105 |
| >220 | >99 | 115+ | 105+ |

Max: 163 psi (160), 148 psi (170-180).

### Rebound

TH: `YARI-150` (150/160 mm), `YARI-170` (170/180 mm). `motion_control_rc` has `max: ~` → `display_only`.

### SAG / spacers

- SAG: DebonAir, generic 10–30 %.
- Tokens (SPEC2023 p. 23, 27.5" B / 29" B): 150 → 2 (max 5); 160 → 2 (max 5);
  170 → 1 (max 4); 180 → 0 (max 4). This matches the catalog note.

---

## Guide `rockshox_revelation_2024` — Front Suspension Specifications 2024, Revelation RC A3

### Source

- URL: SPEC2024 p. 11 (identical in SPEC2023 p. 11, SPEC2022 p. 11); tech specs SPEC2023 p. 22
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/revelation/rc` | `damper: motion_control_rc` | FS-RVL-RC-A3 (`draft`) |

### Air pressure — DebonAir, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 120 mm | 130-140 mm | 150 mm (both), 160 mm (27.5" B) |
|---|---|---|---|---|
| <120 | <55 | <75 | <65 | <55 |
| 120-140 | 55-63 | 75-85 | 65-75 | 55-65 |
| 140-160 | 63-72 | 85-95 | 75-85 | 65-75 |
| 160-180 | 72-81 | 95-105 | 85-95 | 75-85 |
| 180-200 | 81-90 | 105-115 | 95-105 | 85-95 |
| 200-220 | 90-99 | 115-125 | 105-115 | 95-105 |
| >220 | >99 | 125+ | 115+ | 105+ |

Max: 194 psi (120), 163 psi (130-160).

### Rebound

TH: `RVL-120`, `RVL-130` (130/140), `RVL-150` (150/160). `motion_control_rc` → `display_only`.

### SAG / spacers

- SAG: DebonAir, generic 10–30 %.
- Tokens (SPEC2023 p. 22, 27.5" B and 29" B): 120 → 4 (max 6); 130 → 3
  (max 6); 140 → 2 (max 5); 150 → 1 (max 4); 160 → 0 (max 4, 27.5" B only).

---

## Guide `rockshox_recon_gold_2027` — Front Suspension Specifications 2027, Recon Gold RL C1

### Source

- URL: SPEC2027 p. 10 (also SPEC2026 p. 10; SPEC2024 p. 10 and SPEC2022 p. 11 differ in one cell, see below); tech specs SPEC2023 p. 20
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/rockshox/recon-gold/gold-rl` | `damper: motion_control_rl` | FS-RCNG-RL-C1 |

### Air pressure — DebonAir, 27.5" B / 29" B

| Rider weight (lb) | Rider weight (kg) | 80 mm | 100-120 mm | 130-150 mm |
|---|---|---|---|---|
| <140 | <63 | 90-110 | 50-70 | 130-150 [sic] |
| 140-160 | 63-72 | 110-125 | 70-85 | 60-75 |
| 160-180 | 72-81 | 125-140 | 85-100 | 75-90 |
| 180-200 | 81-90 | 140-160 | 100-120 | 90-105 |
| >200 | >90 | 160+ | 120+ | 105+ |

Max: 265 psi (80), 205 psi (100-120), 225 psi (130-150).

- The lightest-bracket cells are printed as closed bands (`90-110`), not as
  `<` values.
- The 130-150 mm / <140 lb cell reads "130-150 psi" in SPEC2026/2027 but
  "40-60 psi" in SPEC2022/2024. It is almost certainly a typo in the newer
  PDFs; encode 40-60 and note it.

### Rebound

TH: `RCNG-80`, `RCNG-100` (100/120), `RCNG-130`, `RCNG-140` (140/150). `motion_control_rl` → `display_only`. TH also has a 65 mm entry with no catalog travel.

### SAG / spacers

- SAG: DebonAir, generic 10–30 %.
- Tokens (SPEC2023 p. 20): 0 installed at every travel, max 2.

---

## Guide `rockshox_trailhead_fork_rebound` — TrailHead fork rebound formulas

### Source

- URL: https://trailhead.rockshox.com/en/product/<model code>/tuning/setup (e.g. `FS-PIKE-ULT-C2`)
- Document: RockShox TrailHead web app (official setup app). Coefficients are in the page's `tuneModels` data. The formula is in the setup page's client script (`page-e2d8199b5e7d6443.js`).
- Retrieved: 2026-10-11
- On-page statement: "Rebound suggestions are set from the full clockwise/full slow position."

### Formula (our words)

1. Rider weight is entered in lb, or in kg × 2.20462. Below 60 lb no
   recommendation is shown.
2. N = rs1 × weight_lb + rb.
3. Clamp N to the range −17 … 0 and round half up (JS `Math.round`).
4. TrailHead shows N as a negative click count. |N| is the number of clicks
   counted out (counter-clockwise) from fully closed.

E-bike mode does not change rebound; it only adds 10 psi. For pressure, TrailHead's model-code path caps the result at the value it computes for a 260 lb rider.

Counting-direction comparison: TrailHead counts from closed. Every catalog fork rebound adjuster is "Counted from fully open (fastest)" (`dial_ccw`, `min: 0`), which is the opposite direction:
- `charger_3`, `charger_3_1` (max 18) and `charger_3_2` (max 18, **estimated**)
  → encode `18 − N`.
- `rush_rc`, `rush_rl`, `isolator` (max 16) → `16 − N` (floored at 0).
- `charger_race_day`, `charger_race_day_2`, `charger_2_rl`, `charger_rl`,
  `charger_2_1_rc2`, `motion_control_rc`, `motion_control_rl` (`max: ~`)
  → `display_only`, worded "N clicks from closed".

Range: TrailHead states no upper weight limit, so the calculated rows cover 50–120 kg (README default). Calculated from the published formula:

Formula coefficients (rebound = rs1 × weight_lb + rb, clamped to [-17, 0], rounded; magnitude = clicks from closed):

| Formula | rb | rs1 |
|---|---|---|
| `C3-A` | -20.3897058823529 | 0.0654411764705882 |
| `C3-B` | -20.7352941176471 | 0.0595588235294118 |
| `C3-C` | -22.110294117647 | 0.0595588235294117 |
| `RUSH-P120` | -17.727941176470587 | 0.04308823529411765 |
| `RUSH-P130` | -18.419117647058822 | 0.0413235294117647 |
| `BASE-A` | -17.154411764705884 | 0.040882352941176474 |
| `BASE-B` | -17.544117647058822 | 0.03882352941176471 |
| `BASE-C` | -18.08823529411765 | 0.03764705882352941 |
| `BXR-D-180` | -21.919117647058822 | 0.07882352941176471 |
| `BXR-D-190` | -24.919117647058822 | 0.0863235294117647 |
| `BXR-C-180` | -16.125 | 0.0475 |
| `BXR-C-190` | -17.125 | 0.0475 |
| `SIDSL-E1` | -19.238 | 0.0717 |
| `SID-D1` | -18.877443609022556 | 0.06533834586466165 |
| `SIDSL-C1-ULT` | -14.349624060150376 | 0.05225563909774436 |
| `SIDSL-C1-SELP` | -27.79548872180451 | 0.08706766917293234 |
| `SIDSL-C1-SEL` | -23.506766917293234 | 0.059398496240601506 |
| `SIDSL-C1-BSE` | -14.061654135338346 | 0.04007518796992481 |
| `SID-C1-ULT` | -20.986466165413535 | 0.081203007518797 |
| `SID-C1-SELP` | -20.52406015037594 | 0.0656390977443609 |
| `SID-C1-SEL` | -18.568421052631578 | 0.049473684210526316 |
| `SID-C1-BSE` | -14.002255639097744 | 0.046466165413533836 |
| `REBA-100` | -20.981954887218045 | 0.06827067669172933 |
| `REBA-110` | -20.810526315789474 | 0.0668421052631579 |
| `PSYL-130` | -11.715037593984963 | 0.04977443609022556 |
| `PSYL-140` | -11.761654135338347 | 0.050075187969924814 |
| `DOMN-150` | -15.363157894736844 | 0.05105263157894737 |
| `DOMN-160` | -16.363157894736844 | 0.05105263157894737 |
| `RUDY` | -23.237593984962405 | 0.09443609022556392 |
| `RDYX` | -22 | 0.05 |
| `YARI-150` | -24.625 | 0.0725 |
| `YARI-170` | -25.816176470588236 | 0.07073529411764706 |
| `RVL-120` | -16.972932330827067 | 0.052406015037593984 |
| `RVL-130` | -17.206766917293233 | 0.059398496240601506 |
| `RVL-150` | -17.49699248120301 | 0.058045112781954886 |
| `RCNG-80` | -20.504511278195487 | 0.05293233082706767 |
| `RCNG-100` | -28.061654135338348 | 0.08007518796992481 |
| `RCNG-130` | -25.035338345864663 | 0.04796992481203007 |
| `RCNG-140` | -26.166917293233084 | 0.05849624060150376 |

#### Calculated from the published formula — Charger 3 / 3.1 / 3.2 RC2 family (clicks from closed)

| kg | lb (×2.20462) | `C3-A` N | `C3-A` → catalog (18 − N) | `C3-B` N | `C3-B` → catalog (18 − N) | `C3-C` N | `C3-C` → catalog (18 − N) |
|---|---|---|---|---|---|---|---|
| 50 | 110.2 | 13 | 5 | 14 | 4 | 16 | 2 |
| 55 | 121.3 | 12 | 6 | 14 | 4 | 15 | 3 |
| 60 | 132.3 | 12 | 6 | 13 | 5 | 14 | 4 |
| 65 | 143.3 | 11 | 7 | 12 | 6 | 14 | 4 |
| 70 | 154.3 | 10 | 8 | 12 | 6 | 13 | 5 |
| 75 | 165.3 | 10 | 8 | 11 | 7 | 12 | 6 |
| 80 | 176.4 | 9 | 9 | 10 | 8 | 12 | 6 |
| 85 | 187.4 | 8 | 10 | 10 | 8 | 11 | 7 |
| 90 | 198.4 | 7 | 11 | 9 | 9 | 10 | 8 |
| 95 | 209.4 | 7 | 11 | 8 | 10 | 10 | 8 |
| 100 | 220.5 | 6 | 12 | 8 | 10 | 9 | 9 |
| 105 | 231.5 | 5 | 13 | 7 | 11 | 8 | 10 |
| 110 | 242.5 | 5 | 13 | 6 | 12 | 8 | 10 |
| 115 | 253.5 | 4 | 14 | 6 | 12 | 7 | 11 |
| 120 | 264.6 | 3 | 15 | 5 | 13 | 6 | 12 |

#### Calculated from the published formula — Base-trim dampers (Rush RC / Charger R) (clicks from closed)

| kg | lb (×2.20462) | `RUSH-P120` N | `RUSH-P120` → catalog (16 − N) | `RUSH-P130` N | `RUSH-P130` → catalog (16 − N) | `BASE-A` N | `BASE-A` → catalog (16 − N) | `BASE-B` N | `BASE-B` → catalog (16 − N) | `BASE-C` N | `BASE-C` → catalog (16 − N) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 50 | 110.2 | 13 | 3 | 14 | 2 | 13 | 3 | 13 | 3 | 14 | 2 |
| 55 | 121.3 | 13 | 3 | 13 | 3 | 12 | 4 | 13 | 3 | 14 | 2 |
| 60 | 132.3 | 12 | 4 | 13 | 3 | 12 | 4 | 12 | 4 | 13 | 3 |
| 65 | 143.3 | 12 | 4 | 12 | 4 | 11 | 5 | 12 | 4 | 13 | 3 |
| 70 | 154.3 | 11 | 5 | 12 | 4 | 11 | 5 | 12 | 4 | 12 | 4 |
| 75 | 165.3 | 11 | 5 | 12 | 4 | 10 | 6 | 11 | 5 | 12 | 4 |
| 80 | 176.4 | 10 | 6 | 11 | 5 | 10 | 6 | 11 | 5 | 11 | 5 |
| 85 | 187.4 | 10 | 6 | 11 | 5 | 9 | 7 | 10 | 6 | 11 | 5 |
| 90 | 198.4 | 9 | 7 | 10 | 6 | 9 | 7 | 10 | 6 | 11 | 5 |
| 95 | 209.4 | 9 | 7 | 10 | 6 | 9 | 7 | 9 | 7 | 10 | 6 |
| 100 | 220.5 | 8 | 8 | 9 | 7 | 8 | 8 | 9 | 7 | 10 | 6 |
| 105 | 231.5 | 8 | 8 | 9 | 7 | 8 | 8 | 9 | 7 | 9 | 7 |
| 110 | 242.5 | 7 | 9 | 8 | 8 | 7 | 9 | 8 | 8 | 9 | 7 |
| 115 | 253.5 | 7 | 9 | 8 | 8 | 7 | 9 | 8 | 8 | 9 | 7 |
| 120 | 264.6 | 6 | 10 | 7 | 9 | 6 | 10 | 7 | 9 | 8 | 8 |

#### Calculated from the published formula — BoXXer (clicks from closed)

| kg | lb (×2.20462) | `BXR-D-180` N | `BXR-D-180` → catalog (18 − N) | `BXR-D-190` N | `BXR-D-190` → catalog (18 − N) | `BXR-C-180` N | `BXR-C-190` N |
|---|---|---|---|---|---|---|---|
| 50 | 110.2 | 13 | 5 | 15 | 3 | 11 | 12 |
| 55 | 121.3 | 12 | 6 | 14 | 4 | 10 | 11 |
| 60 | 132.3 | 11 | 7 | 14 | 4 | 10 | 11 |
| 65 | 143.3 | 11 | 7 | 13 | 5 | 9 | 10 |
| 70 | 154.3 | 10 | 8 | 12 | 6 | 9 | 10 |
| 75 | 165.3 | 9 | 9 | 11 | 7 | 8 | 9 |
| 80 | 176.4 | 8 | 10 | 10 | 8 | 8 | 9 |
| 85 | 187.4 | 7 | 11 | 9 | 9 | 7 | 8 |
| 90 | 198.4 | 6 | 12 | 8 | 10 | 7 | 8 |
| 95 | 209.4 | 5 | 13 | 7 | 11 | 6 | 7 |
| 100 | 220.5 | 5 | 13 | 6 | 12 | 6 | 7 |
| 105 | 231.5 | 4 | 14 | 5 | 13 | 5 | 6 |
| 110 | 242.5 | 3 | 15 | 4 | 14 | 5 | 6 |
| 115 | 253.5 | 2 | 16 | 3 | 15 | 4 | 5 |
| 120 | 264.6 | 1 | 17 | 2 | 16 | 4 | 5 |

#### Calculated from the published formula — SID / SID SL 2024+ (clicks from closed)

| kg | lb (×2.20462) | `SIDSL-E1` N | `SID-D1` N |
|---|---|---|---|
| 50 | 110.2 | 11 | 12 |
| 55 | 121.3 | 11 | 11 |
| 60 | 132.3 | 10 | 10 |
| 65 | 143.3 | 9 | 10 |
| 70 | 154.3 | 8 | 9 |
| 75 | 165.3 | 7 | 8 |
| 80 | 176.4 | 7 | 7 |
| 85 | 187.4 | 6 | 7 |
| 90 | 198.4 | 5 | 6 |
| 95 | 209.4 | 4 | 5 |
| 100 | 220.5 | 3 | 4 |
| 105 | 231.5 | 3 | 4 |
| 110 | 242.5 | 2 | 3 |
| 115 | 253.5 | 1 | 2 |
| 120 | 264.6 | 0 | 2 |

#### Calculated from the published formula — SID SL C1 (2021-2023) (clicks from closed)

| kg | lb (×2.20462) | `SIDSL-C1-ULT` N | `SIDSL-C1-SELP` N | `SIDSL-C1-SEL` N | `SIDSL-C1-BSE` N | `SIDSL-C1-BSE` → catalog (16 − N) |
|---|---|---|---|---|---|---|
| 50 | 110.2 | 9 | 17 | 17 | 10 | 6 |
| 55 | 121.3 | 8 | 17 | 16 | 9 | 7 |
| 60 | 132.3 | 7 | 16 | 16 | 9 | 7 |
| 65 | 143.3 | 7 | 15 | 15 | 8 | 8 |
| 70 | 154.3 | 6 | 14 | 14 | 8 | 8 |
| 75 | 165.3 | 6 | 13 | 14 | 7 | 9 |
| 80 | 176.4 | 5 | 12 | 13 | 7 | 9 |
| 85 | 187.4 | 5 | 11 | 12 | 7 | 9 |
| 90 | 198.4 | 4 | 11 | 12 | 6 | 10 |
| 95 | 209.4 | 3 | 10 | 11 | 6 | 10 |
| 100 | 220.5 | 3 | 9 | 10 | 5 | 11 |
| 105 | 231.5 | 2 | 8 | 10 | 5 | 11 |
| 110 | 242.5 | 2 | 7 | 9 | 4 | 12 |
| 115 | 253.5 | 1 | 6 | 8 | 4 | 12 |
| 120 | 264.6 | 1 | 5 | 8 | 3 | 13 |

#### Calculated from the published formula — SID C1 (2021-2023) (clicks from closed)

| kg | lb (×2.20462) | `SID-C1-ULT` N | `SID-C1-SELP` N | `SID-C1-SEL` N | `SID-C1-BSE` N | `SID-C1-BSE` → catalog (16 − N) |
|---|---|---|---|---|---|---|
| 50 | 110.2 | 12 | 13 | 13 | 9 | 7 |
| 55 | 121.3 | 11 | 13 | 13 | 8 | 8 |
| 60 | 132.3 | 10 | 12 | 12 | 8 | 8 |
| 65 | 143.3 | 9 | 11 | 11 | 7 | 9 |
| 70 | 154.3 | 8 | 10 | 11 | 7 | 9 |
| 75 | 165.3 | 8 | 10 | 10 | 6 | 10 |
| 80 | 176.4 | 7 | 9 | 10 | 6 | 10 |
| 85 | 187.4 | 6 | 8 | 9 | 5 | 11 |
| 90 | 198.4 | 5 | 8 | 9 | 5 | 11 |
| 95 | 209.4 | 4 | 7 | 8 | 4 | 12 |
| 100 | 220.5 | 3 | 6 | 8 | 4 | 12 |
| 105 | 231.5 | 2 | 5 | 7 | 3 | 13 |
| 110 | 242.5 | 1 | 5 | 7 | 3 | 13 |
| 115 | 253.5 | 0 | 4 | 6 | 2 | 14 |
| 120 | 264.6 | 0 | 3 | 5 | 2 | 14 |

#### Calculated from the published formula — Reba, Psylo, Domain, Rudy (clicks from closed)

| kg | lb (×2.20462) | `REBA-100` N | `REBA-110` N | `PSYL-130` N | `PSYL-130` → catalog (16 − N) | `PSYL-140` N | `PSYL-140` → catalog (16 − N) | `DOMN-150` N | `DOMN-150` → catalog (16 − N) | `DOMN-160` N | `DOMN-160` → catalog (16 − N) | `RUDY` N | `RDYX` N |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 50 | 110.2 | 13 | 13 | 6 | 10 | 6 | 10 | 10 | 6 | 11 | 5 | 13 | 16 |
| 55 | 121.3 | 13 | 13 | 6 | 10 | 6 | 10 | 9 | 7 | 10 | 6 | 12 | 16 |
| 60 | 132.3 | 12 | 12 | 5 | 11 | 5 | 11 | 9 | 7 | 10 | 6 | 11 | 15 |
| 65 | 143.3 | 11 | 11 | 5 | 11 | 5 | 11 | 8 | 8 | 9 | 7 | 10 | 15 |
| 70 | 154.3 | 10 | 10 | 4 | 12 | 4 | 12 | 7 | 9 | 8 | 8 | 9 | 14 |
| 75 | 165.3 | 10 | 10 | 3 | 13 | 3 | 13 | 7 | 9 | 8 | 8 | 8 | 14 |
| 80 | 176.4 | 9 | 9 | 3 | 13 | 3 | 13 | 6 | 10 | 7 | 9 | 7 | 13 |
| 85 | 187.4 | 8 | 8 | 2 | 14 | 2 | 14 | 6 | 10 | 7 | 9 | 6 | 13 |
| 90 | 198.4 | 7 | 8 | 2 | 14 | 2 | 14 | 5 | 11 | 6 | 10 | 4 | 12 |
| 95 | 209.4 | 7 | 7 | 1 | 15 | 1 | 15 | 5 | 11 | 6 | 10 | 3 | 12 |
| 100 | 220.5 | 6 | 6 | 1 | 15 | 1 | 15 | 4 | 12 | 5 | 11 | 2 | 11 |
| 105 | 231.5 | 5 | 5 | 0 | 16 | 0 | 16 | 4 | 12 | 5 | 11 | 1 | 10 |
| 110 | 242.5 | 4 | 5 | 0 | 16 | 0 | 16 | 3 | 13 | 4 | 12 | 0 | 10 |
| 115 | 253.5 | 4 | 4 | 0 | 16 | 0 | 16 | 2 | 14 | 3 | 13 | 0 | 9 |
| 120 | 264.6 | 3 | 3 | 0 | 16 | 0 | 16 | 2 | 14 | 3 | 13 | 0 | 9 |

#### Calculated from the published formula — Yari, Revelation, Recon Gold (clicks from closed)

| kg | lb (×2.20462) | `YARI-150` N | `YARI-170` N | `RVL-120` N | `RVL-130` N | `RVL-150` N | `RCNG-80` N | `RCNG-100` N | `RCNG-130` N | `RCNG-140` N |
|---|---|---|---|---|---|---|---|---|---|---|
| 50 | 110.2 | 17 | 17 | 11 | 11 | 11 | 15 | 17 | 17 | 17 |
| 55 | 121.3 | 16 | 17 | 11 | 10 | 10 | 14 | 17 | 17 | 17 |
| 60 | 132.3 | 15 | 16 | 10 | 9 | 10 | 14 | 17 | 17 | 17 |
| 65 | 143.3 | 14 | 16 | 9 | 9 | 9 | 13 | 17 | 17 | 17 |
| 70 | 154.3 | 13 | 15 | 9 | 8 | 9 | 12 | 16 | 17 | 17 |
| 75 | 165.3 | 13 | 14 | 8 | 7 | 8 | 12 | 15 | 17 | 16 |
| 80 | 176.4 | 12 | 13 | 8 | 7 | 7 | 11 | 14 | 17 | 16 |
| 85 | 187.4 | 11 | 13 | 7 | 6 | 7 | 11 | 13 | 16 | 15 |
| 90 | 198.4 | 10 | 12 | 7 | 5 | 6 | 10 | 12 | 16 | 15 |
| 95 | 209.4 | 9 | 11 | 6 | 5 | 5 | 9 | 11 | 15 | 14 |
| 100 | 220.5 | 9 | 10 | 5 | 4 | 5 | 9 | 10 | 14 | 13 |
| 105 | 231.5 | 8 | 9 | 5 | 3 | 4 | 8 | 10 | 14 | 13 |
| 110 | 242.5 | 7 | 9 | 4 | 3 | 3 | 8 | 9 | 13 | 12 |
| 115 | 253.5 | 6 | 8 | 4 | 2 | 3 | 7 | 8 | 13 | 11 |
| 120 | 264.6 | 5 | 7 | 3 | 1 | 2 | 7 | 7 | 12 | 11 |

#### Calculated from the published formula — rear shock rebound (clicks from closed; catalog value from open = total − N)

| kg | lb | N (15-click damper) | catalog `rebound` (15 − N) | N (20-click damper) | catalog `rebound` (20 − N) |
|---|---|---|---|---|---|
| 50 | 110.2 | 12 | 3 | 17 | 3 |
| 55 | 121.3 | 12 | 3 | 16 | 4 |
| 60 | 132.3 | 11 | 4 | 15 | 5 |
| 65 | 143.3 | 11 | 4 | 14 | 6 |
| 70 | 154.3 | 10 | 5 | 13 | 7 |
| 75 | 165.3 | 9 | 6 | 13 | 7 |
| 80 | 176.4 | 9 | 6 | 12 | 8 |
| 85 | 187.4 | 8 | 7 | 11 | 9 |
| 90 | 198.4 | 8 | 7 | 10 | 10 |
| 95 | 209.4 | 7 | 8 | 9 | 11 |
| 100 | 220.5 | 6 | 9 | 8 | 12 |
| 105 | 231.5 | 6 | 9 | 8 | 12 |
| 110 | 242.5 | 5 | 10 | 7 | 13 |
| 115 | 253.5 | 5 | 10 | 6 | 14 |
| 120 | 264.6 | 4 | 11 | 5 | 15 |

---

## Guide `rockshox_rear_shock_um` — Suspension User Manual (rear shocks) + TrailHead shock formulas

### Source

- URL: UM, sections "Set Sag – Air Rear Suspension", "Set Sag – Coil Rear Suspension", "Suspension Sag – Rear Suspension", "Bottomless Tokens and Rings"; SWG; DHWG; VAS; TH client script
- Document: RockShox Suspension User Manual (docs.sram.com, current web edition), English. The SRAM Learn pages were served in their German editions.
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Spring per catalog `specs.spring` |
|---|---|---|
| `shock/rockshox/deluxe/2023/ultimate` | `damper: rct` | DebonAir+ |
| `shock/rockshox/deluxe/2023/select-plus` | `damper: rct` | DebonAir |
| `shock/rockshox/deluxe/2023/select` | `damper: rct` | SoloAir |
| `shock/rockshox/deluxe/2017/ultimate` | `damper: deluxe_rt3` | DebonAir |
| `shock/rockshox/deluxe/2017/rt3` | `damper: deluxe_rt3` | DebonAir |
| `shock/rockshox/deluxe/2017/rl` | `damper: deluxe_rt3` | SoloAir |
| `shock/rockshox/super-deluxe/2027/ultimate` | `damper: super_deluxe_d1` | Linear XL |
| `shock/rockshox/super-deluxe/2027/select-plus` | `damper: super_deluxe_d1` | Linear XL |
| `shock/rockshox/super-deluxe/2027/select` | `damper: super_deluxe_d1` | Linear XL |
| `shock/rockshox/super-deluxe/2023/ultimate` | `damper: rc2t` | DebonAir+ |
| `shock/rockshox/super-deluxe/2023/select-plus` | `damper: rc2t` | DebonAir |
| `shock/rockshox/super-deluxe/2023/select` | `damper: rc2t` | SoloAir |
| `shock/rockshox/super-deluxe/2017/ultimate` | `damper: super_deluxe_rct` | DebonAir |
| `shock/rockshox/super-deluxe/2017/rct` | `damper: super_deluxe_rct` | DebonAir |
| `shock/rockshox/super-deluxe/2017/rc3` | `damper: super_deluxe_rct` | SoloAir |
| `shock/rockshox/super-deluxe-coil/2023/ultimate` | `damper: rc2t` | Coil |
| `shock/rockshox/super-deluxe-coil/2023/select-plus` | `damper: rc2t` | Coil |
| `shock/rockshox/super-deluxe-coil/2023/select` | `damper: rc2t` | Coil |
| `shock/rockshox/super-deluxe-coil/2017/ultimate` | `damper: super_deluxe_rct` | Coil |
| `shock/rockshox/super-deluxe-coil/2017/rct` | `damper: super_deluxe_rct` | Coil |
| `shock/rockshox/super-deluxe-ultimate-dh/ultimate-dh` | `damper: rc2` | DebonAir+ |
| `shock/rockshox/vivid-air/2024/ultimate` | `damper: vivid_ultimate` | Vivid Air Spring |
| `shock/rockshox/vivid-air/2024/ultimate-dh` | `damper: vivid_ultimate` | Vivid Air Spring |
| `shock/rockshox/vivid-air/2010/r2c` | `damper: vivid_air_r2c` | Air |
| `shock/rockshox/vivid-coil/ultimate` | `damper: vivid_ultimate` | Coil |
| `shock/rockshox/vivid-coil-ultimate-dh/ultimate-dh` | `damper: vivid_ultimate` | Coil |
| `shock/rockshox/sidluxe/ultimate-flight-attendant` | `damper: rct` | DebonAir+ |
| `shock/rockshox/sidluxe/ultimate` | `damper: rct` | DebonAir+ |
| `shock/rockshox/sidluxe/select-plus` | `damper: rct` | DebonAir |
| `shock/rockshox/monarch/rt3` | `damper: monarch_rt3` | SoloAir |
| `shock/rockshox/monarch/rl` | `damper: monarch_rt3` | DebonAir |
| `shock/rockshox/monarch/xx` | `damper: monarch_rt3` | SoloAir |
| `shock/rockshox/monarch/r` | `damper: monarch_rt3` | SoloAir |
| `shock/rockshox/monarch-plus/rc3` | `damper: monarch_plus_rc3` | DebonAir |
| `shock/rockshox/monarch-plus/r` | `damper: monarch_plus_rc3` | SoloAir |

Gaps: no per-model chart exists, so every rule below is generic and keyed by spring type (trim) or damper.

### Air pressure — formula (all air shocks)

UM "Set Sag – Air Rear Suspension" step 6: inflate to psi equal to the rider's total weight in lb, including gear (example: 160 lb → 160 psi). For Vivid Air (Gen C–D), build up to that value in 50 psi steps, equalizing in between. This is only the starting point; SAG is then set by adjusting pressure.

Calculated from the published formula (psi = kg × 2.20462, rounded to whole psi):

| Rider weight (kg) | psi |
|---|---|
| 50 | 110 |
| 55 | 121 |
| 60 | 132 |
| 65 | 143 |
| 70 | 154 |
| 75 | 165 |
| 80 | 176 |
| 85 | 187 |
| 90 | 198 |
| 95 | 209 |
| 100 | 220 |
| 105 | 232 |
| 110 | 243 |
| 115 | 254 |
| 120 | 265 |

### SAG

| Spring (trims) | Target | Band | Source |
|---|---|---|---|
| SoloAir | ≈25 % | ±5 % → 20-30 | UM step 11 |
| DebonAir / DebonAir+ | ≈30 % | ±5 % → 25-35 | UM step 11 |
| Vivid Air Spring (`vivid-air/2024/*`) | 30 % | — | VAS step 5 |
| Coil (`super-deluxe-coil/*`, `vivid-coil/*`, `vivid-coil-ultimate-dh/*`) | 25-35 % | ±5 % by style | UM "Set Sag – Coil" step 9 |
| Coil (DH guide) | 25-30 % | ±5 % by style; below 20 % fit a softer spring | DHWG |
| Linear XL (`super-deluxe/2027/*`) | — | — | no statement; fall back to the generic 20-30 % band |

Generic band (UM): more sag 20–30 % for longer travel, less 10–20 % for shorter travel. The "Air Spring Ramp and Sag%" figure marks 20–30 %. The coil sources disagree (25–35 vs 25–30). Prefer the UM.

### Constants / base tune

| Target | Value | Direction | `when:` | Source |
|---|---|---|---|---|
| `hsc` | 0 | middle (base tune) | `damper: rc2t` | SWG ("HSC and LSC in the middle position (0)") |
| `lsc` | 0 | middle | `damper: rc2t` | SWG |
| `hsc` | 0 | middle | `damper: vivid_ultimate` | VAS step 2, UM (Vivid Air Gen C–D: LSC and HSC to middle before sag), DHWG |
| `lsc` | 0 | middle | `damper: vivid_ultimate` | as above |

UM: other shocks start with all adjusters open or unlocked before sag. The catalog has no compression adjuster for them.

### Rebound — TrailHead shock formula (generic)

Source: TH client script. It applies only after a serial lookup, but the rebound part needs only the shock's total rebound clicks (`Rebound Clicks` attribute) and the rider weight. Formula:
1. a = total clicks − 1.
2. w = rider weight in lb, plus 15 lb in e-bike mode.
3. If w > 320, N = 1. If w < 80, N = a. Otherwise N = round(a + (w − 80) × (1 − a) / 240).
4. N is counted from closed (full slow).

Catalog dampers count from open: `rc2t` and `super_deluxe_d1` (max 15), `vivid_ultimate` (max 20) → encode `total − N`. All `max: ~` rebound dampers → `display_only`. The table at the end of the TrailHead section above gives N and `total − N` for 15 and 20 clicks.

Caveat: it is not verified that TrailHead's `Rebound Clicks` attribute equals the catalog totals (15 / 20). Shock model-code pages do not expose attributes. See Follow-ups.

### Does not fit B3

- **TrailHead shock air pressure:**
  `psi = b + s1 · (RWT / stroke · 1.125 · w · bias) + s2 · sag/100 + s3 · stroke`,
  where w is in lb (+15 for e-bike), RWT is rear-wheel travel in mm, and bias
  is a rear-wheel weight bias by RWT. b and s1–s3 are per-shock coefficients,
  only served after a serial lookup.
- **TrailHead coil spring rate:**
  `rate = (RWT / stroke · 1.125 · w · bias) / (sag/100 · stroke / 25.4)`,
  rounded to the nearest 50 lb/in, then minus 50.
- Both need inputs the catalog does not have (RWT, frame leverage) and are not
  encoded.
- TrailHead's default SAG / bias table by rear-wheel travel (mm → default
  sag %, rear-wheel bias %):
  - 80–100 → 25 / 55
  - 110–150 → 30 / 60
  - 160–190 → 30 / 65
  - 200–250 → 35 / 70

  It needs RWT, so it is recorded only.

### Volume spacers

The UM "Bottomless Tokens and Rings" table gives only min–max counts per stroke (e.g. 38.1 mm Ring 0-4, 44.5 mm Ring 0-5). No factory-installed counts were found, so nothing is encoded.

### Pressure limits

The UM Vivid Air table (360 psi with 0-4 tokens, 300 psi at 5-6 tokens or 67.5-75 stroke) matches the catalog notes. No other shock limits were found beyond those already in the catalog.

---

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `shock/rockshox/*` (all shocks) | No per-model chart. TrailHead shock tuning requires a serial number and per-shock coefficients that are not public. Only the generic UM formula, SAG targets and the generic rebound formula apply (`rockshox_rear_shock_um`). |
| `fork/rockshox/sid-sl/2021` at `travel_mm: 80` | SPEC2022/2023 and TrailHead cover 100 mm only. |
| `fork/rockshox/sid/2021` at `travel_mm: 100` | SPEC2022/2023 cover 110-120 only. |

## Follow-ups

- **BoXXer max psi:** SPEC2026/2027 print 300 psi for BoXXer D1 and D2, while
  TrailHead D1 and the catalog (D2, from the support KB) say 260. Confirm with
  SRAM before encoding a limit.
- **Charger 3.2 rebound total** (`max: 18` is an estimate). The `18 − N`
  conversion for Lyrik/ZEB 2027 and BoXXer 2027 depends on it. Until it is
  confirmed, encode those as `display_only`.
- **ZEB Base damper:** SPEC2023 and SPEC2026 name "Charger R" for
  FS-ZEB-BSE-A2, while the catalog has `rush_rc`. Re-check the service-manual
  exploded view.
- **SID SL 2025–2026:** one catalog generation covers D1 (MY24–25,
  DebonAir) and E1 (MY26+, DebonAir+), whose charts differ. Consider splitting
  the generation, or pick E1.
- **SID SL E1 TrailHead pressure** disagrees with the E1 decal (TH at 100 mm
  gives 98 psi at 120 lb vs decal "<85"). Encode the decal.
- **Recon Gold 130-150 mm lightest cell:** "130-150 psi" in SPEC2026/2027 vs
  "40-60 psi" in SPEC2022/2024. Treat 40-60 as correct.
- **Missing `volume_spacers` adjusters:** factory counts are known for Lyrik
  2027, ZEB 2027, BoXXer 2024/2027, SID/SID SL 2025, Psylo and Domain (see the
  guides). Adding the adjuster (with maxima) would make them encodable.
- **TrailHead shock `Rebound Clicks`:** confirm it equals 15 (RC2T, D1) and
  20 (Vivid Ultimate). A serial lookup on a real shock would show it.
- **Pressure maxima** printed for every fork (163 / 148 / 194 / 195 / 146 /
  150 / 200 / 265 psi …) are not yet in the catalog `Pressure` adjusters,
  except Lyrik/ZEB 2027.
- **Coil fork spring charts:** the specification PDFs have a coil-fork page
  (e.g. SPEC2023 p. 13) that was not transcribed, because the catalog has no
  coil forks.
