# Setup guide research

Raw material for the setup guides feature (#37). Each brand file collects the
manufacturer's published rider setup data (rider weight → air pressure, clicks,
spacers, SAG) for the forks and shocks in `data/component_presets/`. A file
holds **everything** the `guides:` YAML needs, so encoding a brand later is
pure transcription with no second round of research.

These files are working notes for data editors. Nothing here ships in the app.

## Rules

- **Facts only.** Re-type numbers, units, bracket bounds and counting
  directions. Never copy manual prose, images or PDFs. Notes are in our own
  words.
- **Sourcing** follows `data/component_presets/SCHEMA.md` (manufacturer first).
  A setup recommendation needs a tier-1 source: owner's manual, tuning guide or
  official setup page/app. A number seen only in a review or a shop listing is
  not a guide and is not recorded as one.
- **Transcribe completely.** Every row of every column, bracket bounds exactly
  as printed (`120-130`, `<120`, `250+`), units as printed. When the source
  prints both lb and kg, record both columns. Do not round, re-bracket or
  convert in the table itself.
- **Catalog ids are exact.** Node paths and option values are written the way
  `ids.lock` lists them (`fork/fox/38/2025/factory`, `damper: grip_x2`,
  `travel_mm: 170`). Every id must exist in the brand YAML.
- **Adjuster targets** use the adjuster id the catalog will derive: the slug of
  the catalog adjustment `name` with underscores (`Pressure` → `pressure`,
  `Volume Spacers` → `volume_spacers`, `HSC` → `hsc`, `Rebound` → `rebound`).
  The auto-injected SAG adjuster is `sag`. A target the catalog lacks is
  flagged in the gaps.
- **Counting direction** (Q5 of #37): guide values are encoded in the catalog
  adjuster's own direction. For every click table, state the source direction
  and compare it with the catalog adjuster (`visualization`, `max`, `notes`):
  - same direction → encode as published;
  - opposite direction, `max` known → pre-compute `max − N` here, column by
    column, and say so;
  - opposite direction, `max: ~` → `display_only`, keep the source's wording
    ("5 from closed").
- **Formulas** (Q1): record the formula verbatim (in our words), plus a
  calculated table at 5 kg steps across the source's stated rider range (or
  50–120 kg when none is stated), marked "calculated from the published
  formula".
- **E-bike / chassis columns** (Q3): transcribe them, and note whether the
  catalog has a matching node or option. If not, they are not encoded.
- **Riding-style columns** (Q2): transcribe per style; they become
  `when: { riding_style: … }` rules.

## Brand file template

Copy this structure for `docs/research/setup_guides/<brand>.md` (brand slug as
in the YAML filename).

````markdown
# <Brand> — setup guide research

Catalog files: `data/component_presets/fork/<brand>.yaml`, `data/component_presets/shock/<brand>.yaml`
Researched: YYYY-MM-DD

## Summary

- Guides found, the shapes they use (weight → psi, pressure → clicks, constants,
  formula, SAG band …), and anything B3 doesn't cover.

## Guide `<brand>_<product>_<year>` — <document title>

### Source

- URL: …
- Document: <title>, <manual year / version>, <language>
- Section / page: …
- Retrieved: YYYY-MM-DD

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/<brand>/<model>/<gen>/<trim>` | `damper: <id>` | … |

Gaps: variants the guide names that the catalog lacks (and vice versa).

### Air pressure — <column / variant>

Input: rider weight (lb, kg also printed) · Output: psi · `when: { … }`

| Rider weight (lb) | Rider weight (kg) | psi |
|---|---|---|
| 120-130 | 54-59 | 54 |

### Rebound — <damper / column>

Source direction: from closed. Catalog: `<damper id>` `lsr`, `dial_ccw`, max 16 → same direction, encode as published.

| Rider weight (lb) | LSR | HSR |
|---|---|---|

### Constants / base tune

| Target | Value | Direction | `when:` |
|---|---|---|---|

### SAG

Band, travel or style dependence, as published.

### Volume spacers

Factory-installed count per travel/chassis (the recommended starting count, not the maximum).

### Pressure limits

Max/min pressure per variant; compare with the catalog `max`.

### Formulas

Verbatim formula (our words), source range, calculated rows.

### Does not fit B3

Second-order inputs, two air chambers, coil spring rates … with a proposed encoding.

## Products without a structured guide

| Catalog path | Reason |
|---|---|

## Follow-ups

- …
````

## Coverage

One row per product family. **found** = a structured table we can encode,
**partial** = some targets only (e.g. SAG band or base tune, no weight table),
**none** = no published starting-point data.

| Brand | Type | Product | Status | Guide / reason |
|---|---|---|---|---|
| INTEND | fork | Samurai XC 29 / XC 32 | partial | `intend_fork_setup_2025`: 1.0 psi/kg formula; no click target |
| INTEND | fork | Samurai Super TR | partial | `intend_fork_setup_2025`: 1.0 psi/kg formula, compression 6 from closed |
| INTEND | fork | Hero | partial | `intend_fork_setup_2025`: 1.0 psi/kg formula, compression 6 from closed |
| INTEND | fork | Edge | partial | `intend_fork_setup_2025`: 1.0 psi/kg formula, compression 6 from closed |
| INTEND | fork | Flash 35 / Flash 38 | partial | `intend_fork_setup_2025`: 1.0 psi/kg formula, compression 6 from closed |
| INTEND | fork | Infinity EN | partial | `intend_fork_setup_2025`: 1.3 psi/kg formula, compression 6 from closed |
| INTEND | fork | Bandit | partial | `intend_fork_setup_2025`: 1.3 psi/kg formula, compression 6 from closed |
| INTEND | fork | Essential | partial | `intend_fork_setup_2025`: compression 6 only; spacer position has no catalog target |
| Cannondale | fork | Lefty Ocho | found | `cannondale_lefty_ocho_2018`: weight → psi + rebound, SAG 25 % |
| Cannondale | fork | Lefty Ocho 120 | found | `cannondale_lefty_ocho_120_2021`: weight → psi + rebound, SAG 25 % |
| Cannondale | fork | Lefty Oliver | found | `cannondale_lefty_oliver_2020`: weight → psi + rebound, SAG 0 % |
| Cannondale | fork | Lefty 2.0 (PBR/XLR) | found | `cannondale_lefty_2_0_2016`: weight → psi per travel/wheel, SAG mm band; no rebound |
| BOS | fork | Deville 35 | found | `bos_deville35_2025`: table conflicts with the Quickstart's own 115–350 psi window, don't encode until clarified |
| BOS | fork | Kyll 39 | found | `bos_kyll39_2025` |
| BOS | fork | Idylle 39 | found | `bos_idylle39_2025` |
| BOS | fork | Obsys 42 | found | `bos_obsys42_2025` |
| BOS | fork | Toxik | none | no Quickstart or manual on the BOS manuals page or product page |
| BOS | shock | Stoy 4 | none | no user manual or Quickstart (placeholder links the Stoy 3 FR manual) |
| BOS | shock | Void 4 | none | FR service manual only; settings table is a blank log |
| BOS | shock | Syors 2 | none | FR service manual only; settings table is a blank log |
| DT Swiss | fork | F 535 ONE | found | `dtswiss_f535_2023` |
| DT Swiss | fork | F 535 | found | `dtswiss_f535_2023` |
| DT Swiss | fork | F 232 ONE | found | `dtswiss_f232one_2021` |
| DT Swiss | shock | R 535 ONE | found | `dtswiss_r535_2023` |
| DT Swiss | shock | R 535 | found | `dtswiss_r535_2023` |
| DT Swiss | shock | R 232 ONE | found | `dtswiss_r232one_2021` |
| Formula | fork | Selva V | found | `formula_selva_v_2025` |
| Formula | fork | Selva S | found | `formula_selva_s_2018` |
| Formula | fork | Selva R | found | `formula_selva_r_2023` |
| Formula | fork | Selva C | none | coil options and preload only, no weight chart |
| Formula | fork | Belva | found | `formula_belva_2024` |
| Formula | fork | Nero R | found | `formula_nero_r_2017` |
| Formula | fork | Nero C | none | spring options only, no weight chart |
| Formula | shock | Nebbia | found | `formula_nebbia_2024` |
| Formula | shock | MOD | partial | `formula_mod_2020`: SAG target, base clicks, preload window; no spring chart |
| Formula | shock | MOD DH | partial | `formula_mod_2020`: DH page links the MOD manual |
| Öhlins | fork | RXC34 m.1 | found | `ohlins_rxc34_m1_2023` |
| Öhlins | fork | RXF34 m.2 | found | `ohlins_rxf34_m2_2026` |
| Öhlins | fork | RXF34 m.1 / RXF36 m.1 (TTX22, STX22) | found | `ohlins_rxf34_rxf36_m1` |
| Öhlins | fork | RXF36 m.2 (Air, Coil) | found | `ohlins_rxf36_m2_2023` |
| Öhlins | fork | RXF36 m.3 (Air, Coil) | found | `ohlins_rxf36_m3_2026`: click table only in edition 07258-12_2 |
| Öhlins | fork | RXF38 m.2 (Air, Coil) | found | `ohlins_rxf38_m2_2024` |
| Öhlins | fork | RXF38 m.3 (Air, Coil) | found | `ohlins_rxf38_m3_2025` |
| Öhlins | fork | DH38 m.1 / m.2 | partial | `ohlins_dh38_m2_2025`: SAG band + m.2 coil chart, no pressure table |
| Öhlins | fork | RXFDJ m.1 | none | no owner's manual, workshop manuals only |
| Öhlins | shock | TTX1Air / TTX2Air (first generation) | partial | `ohlins_ttx_air_m1_2020`: start psi, SAG, HSC delivery, max psi |
| Öhlins | shock | TTX1Air / TTX2Air m.2 | partial | `ohlins_ttx_air_m2_2025`: start psi, SAG, HSC delivery, TTX1Air spacers, max psi |
| Öhlins | shock | TXC1Air / TXC2Air | partial | `ohlins_txc_air_2023`: start psi, SAG, max psi |
| Öhlins | shock | TTX22 m.2 | partial | `ohlins_ttx22_m2_2022`: SAG, HSC delivery |
| Öhlins | shock | TTX22M (m1) | none | discontinued, no owner's manual published |
| Marzocchi | fork | Bomber Z1 (Air) | found | `marzocchi_z1_2024` |
| Marzocchi | fork | Bomber Z1 Coil | partial | `marzocchi_z1_2024`: spring colour/label only, no rate; 2020 and 2024 editions disagree |
| Marzocchi | fork | Bomber Z2 | found | `marzocchi_z2_2019` |
| Marzocchi | fork | Bomber DJ | found | `marzocchi_z1_dj_2020` |
| Marzocchi | fork | Bomber 58 | found | `marzocchi_58_2017` |
| Marzocchi | shock | Bomber Air | found | `marzocchi_bomber_air_2022`: formula + pressure → rebound |
| Marzocchi | shock | Bomber CR | partial | `marzocchi_bomber_cr_2018`: 30 % SAG; spring-rate formula needs rear-wheel travel |
| DVO | fork | 38 (D1, D1 SL, D2, D3) | found | `dvo_onyx38_2024` |
| DVO | fork | Diamond 36 D1 SL | found | `dvo_diamond36_2024` |
| DVO | fork | Diamond 36 CORE | found | `dvo_diamond36core_2026` |
| DVO | fork | Diamond (D3, E3) | found | `dvo_fork_2020` |
| DVO | fork | Sapphire 34 D1 | found | `dvo_fork_2020` |
| DVO | fork | Sapphire 32 D1 | partial | `dvo_fork_2018`: air chart only; damping charts predate the catalog damper |
| DVO | fork | Onyx SC D2 | found | `dvo_fork_2020`: internal OTT has no catalog adjuster |
| DVO | fork | Onyx DC D1 | found | `dvo_fork_2020` |
| DVO | fork | Emerald (Inverted) | found | `dvo_emerald_tech` |
| DVO | shock | Jade X (T3, Prime) | partial | `dvo_jadex_2024`: bladder, SAG, T3 chart; no spring/damping chart |
| DVO | shock | Jade X WP CV | partial | `dvo_jadexwp_2023`: spring rate, bladder, SAG; damping display-only |
| DVO | shock | Jade | found | `dvo_jade_tech`: base tune for 3 of 19 catalog sizes, bladder chart |
| DVO | shock | Topaz (Pro, Prime) | found | `dvo_topaz_2024` |
| DVO | shock | Topaz WP CV | partial | `dvo_topazwp_2023`: air, bladder, SAG; damping display-only |
| DVO | shock | Topaz 2 (T3Air, Maestro HV) | found | `dvo_topaz_2020` |
| DVO | shock | Opal HV T3 | none | no guide PDF; setup page 404; product page has no settings |
| Manitou | fork | Mezzer G2 Pro / Mezzer LT Pro | found | `manitou_mezzer_g2_pro_2025` |
| Manitou | fork | Mezzer G2 Expert | found | `manitou_mezzer_g2_expert_2025` |
| Manitou | fork | Mezzer LT Comp | found | `manitou_mezzer_g2_ltcomp_2025` |
| Manitou | fork | Mezzer Pro (2019) | found | `manitou_mezzer_pro_2019` |
| Manitou | fork | Mezzer Expert (2019) | found | `manitou_mezzer_expert_2021` |
| Manitou | fork | Mattoc Pro | found | `manitou_mattoc_pro_2023` |
| Manitou | fork | Mattoc Expert | found | `manitou_mattoc_expert_2023` |
| Manitou | fork | Mattoc Comp | found | `manitou_mattoc_comp_2023` |
| Manitou | fork | R8 Pro | found | `manitou_r8_pro_2024`: 100 and 120 mm columns only |
| Manitou | fork | Dorado Pro | found | `manitou_dorado_pro_2021` |
| Manitou | fork | Dorado Expert | found | `manitou_dorado_expert_2020` |
| Manitou | fork | Dorado Comp Coil | found | `manitou_dorado_comp_2021` |
| Manitou | fork | Mastodon Pro | found | `manitou_mastodon_pro_2023` |
| Manitou | fork | Mastodon Comp | found | `manitou_mastodon_comp_2023` |
| Manitou | shock | Mara Gen 2 Pro Piggyback / PB DH | partial | `manitou_mara_pb_2024`: constants for a 170 lb rider, SAG, max psi; no weight chart |
| Manitou | shock | Mara Gen 2 Inline Pro / Pro XC / Comp | partial | `manitou_mara_il_2024`: rebound constant only |
| Manitou | shock | Mara Pro Piggyback (2019) | partial | `manitou_mara_pb_2019`: constants only |
| RST | fork | ROGUE V2 | found | `rst_highend_forks` Table A: weight (kg) → psi, SAG 15–25 % |
| RST | fork | SLOPE | found | `rst_highend_forks` Table A |
| RST | fork | F1RST / F1RST 110 | found | `rst_highend_forks` Table A |
| RST | fork | AERIAL / AERIAL 110 | found | `rst_highend_forks` Table A |
| RST | fork | STITCH / STITCH 29 / STITCH 29 Limited Edition | found | `rst_highend_forks` Table B: last row looks misprinted |
| RST | fork | SPACE (Jump) | found | `rst_dirtjump_forks`: conflicts with `rst_highend_forks` Table B, don't encode until decided |
| RST | fork | SPACE (Free) | none | coil, no spring chart in any manual |
| RST | fork | KILLAH, R.EVO 29, VIBE V2, REBEL V2, BLADE PRO, BLADE, STORM, SNYPER, RENEGADE | partial | `rst_highend_forks`: SAG 15–25 % only |
| RST | fork | GUIDE, OMEGA, BLAZE, CAPA, DIRT | none | manuals give no pressure, SAG or spring values |
| RST | fork | SHINE, VIVO | none | not named in any RST manual |
| RST | shock | MONO | found | `rst_mono_shock`: weight (kg) → psi, SAG 18–40 %; max pressure contradicts itself (300 vs 400 psi) |
| RST | shock | MEZZO | none | no manual; product page lists springs only |
| SR Suntour | fork | RUX | found | `suntour_forks_my26`: weight → psi, SAG by travel, factory spacers |
| SR Suntour | fork | DUROLUX 36X | found | `suntour_forks_my26` |
| SR Suntour | fork | DUROLUX 38 | found | `suntour_forks_my26` |
| SR Suntour | fork | AION 36 | found | `suntour_forks_my26`: manual max 145 psi vs catalog 130 |
| SR Suntour | fork | AION 38X | found | `suntour_forks_my26`: spacers per wheel size |
| SR Suntour | fork | AURON 36 | found | `suntour_forks_my26`: MY26 spacer max 6 vs catalog 5 |
| SR Suntour | fork | ZERON 36 | found | `suntour_forks_my26` |
| SR Suntour | fork | ZERON 36X | found | `suntour_forks_my26` |
| SR Suntour | fork | AXON 34 | found | `suntour_forks_my26` |
| SR Suntour | fork | AXON 34 Werx / Elite | found | `suntour_forks_my26`: Elite spacer row has no catalog adjuster |
| SR Suntour | fork | RAIDON 34 | found | `suntour_forks_my26` |
| SR Suntour | shock | EDGE Evo | partial | `suntour_shocks_my27`: SAG by stroke, factory/max psi |
| SR Suntour | shock | EDGE X | partial | `suntour_shocks_my27`: SAG by stroke, factory/max psi |
| SR Suntour | shock | TRIAIR2 | partial | `suntour_shocks_my27`: SAG by stroke, main/reservoir factory, min, max |
| SR Suntour | shock | RAIDON | partial | `suntour_shocks_my27`: SAG by stroke, factory/max psi |
| Cane Creek | fork | Helm MKII (Air / Coil) | found | `canecreek_helm_mkii_2025`: air 30–40 % formula, SAG bands, coil spring chart; factory volume setting conflicts |
| Cane Creek | fork | Helm Works Series | partial | `canecreek_helm_mkii_2025`: air formula, SAG |
| Cane Creek | fork | Helm DJ | partial | `canecreek_helm_dj_2025`: 95–125 psi window, rebound 5–10 from closed |
| Cane Creek | fork | Helm MK1 (Air / Coil) | partial | `canecreek_helm_mk1_2018`: air 50 % formula, SAG; no spring chart |
| Cane Creek | shock | Air IL | partial | `canecreek_air_coil_il_g2_2025`: 120 % formula, SAG 25–35 % |
| Cane Creek | shock | Coil IL | partial | `canecreek_air_coil_il_g2_2025` SAG + `canecreek_coil_springs_2026` spring formula (needs rear travel) |
| Cane Creek | shock | Kitsuma (Air) | partial | `canecreek_kitsuma_g2_2025`: 75–100 % formula, SAG, spacer max |
| Cane Creek | shock | Kitsuma Coil | partial | `canecreek_kitsuma_g2_2025`: SAG, preload + spring formula |
| Cane Creek | shock | Tigon | partial | `canecreek_tigon_2025`: spring formula, SAG, RAMP tube start 0 psi |
| Cane Creek | shock | DB Air IL G1 | partial | `canecreek_db_il_g1_2022`: 100 % formula, SAG |
| Cane Creek | shock | DBcoil IL G1 | partial | `canecreek_db_il_g1_2022`: SAG, preload |
| Cane Creek | shock | DB Kitsuma Air G1 | partial | `canecreek_db_kitsuma_g1_2022`: 75–100 % formula, SAG |
| Cane Creek | shock | DB Kitsuma Coil G1 | partial | `canecreek_db_kitsuma_g1_2022`: SAG + spring formula |
| Cane Creek | shock | DB Air CS | found | `canecreek_double_barrel_tfg`: base tune (from open → max − N), weight − 20 psi formula, SAG 28–33 % |
| Cane Creek | shock | DBcoil | found | `canecreek_double_barrel_tfg`: base tune (from open → max − N), SAG 28–33 % |
| Cane Creek | shock | DB Inline | partial | `canecreek_double_barrel_tfg`: base tune blocked (18-click scale vs catalog 25); air formula + SAG usable |
| EXT | fork | Era V2.1 | found | `ext_era_v2_2023`: weight → + / ++ psi + HSC/LSC/R, SAG 15–20 % |
| EXT | fork | Era V2 LT | found | `ext_era_v2_2023` |
| EXT | fork | Vaia | partial | `ext_vaia_2024`: SAG 15–20 % + 250 psi limit only |
| EXT | shock | Aria | found | `ext_aria_2023`: equivalent spring rate → + / ++ psi + clicks (input is not rider weight) |
| EXT | shock | Aria V2 / Aria V2 DH | found | `ext_ridemaster_2026`: RideMaster formula chain |
| EXT | shock | Vecta | found | `ext_ridemaster_2026`: RideMaster formula → spring rate + clicks |
| EXT | shock | Storia V3 | partial | `ext_arma_storia_v3_2023`: constants conflict between V3 and V3-S manuals |
| EXT | shock | Arma V3 | partial | `ext_arma_storia_v3_2023`: constants |
| EXT | shock | Storia V4 | partial | `ext_arma_storia_v4_2024`: constants + spring calculator |
| EXT | shock | Arma V4 | partial | `ext_arma_storia_v4_2024`: constants + spring calculator |
| EXT | shock | e-Storia | none | no starting clicks or table; generic spring calculator only |
| FOX | fork | 32 Taper-Cast | found | `fox_32_34_2027`: GRIP rebound rows above catalog max 10 |
| FOX | fork | 32 Step-Cast | found | `fox_32_34_2027` |
| FOX | fork | 34 | found | `fox_32_34_2027`: no GRIP X rebound column for the 34 |
| FOX | fork | 34 SL | found | `fox_34sl_2027` |
| FOX | fork | 36 SL | found | `fox_36sl_2027` |
| FOX | fork | 36 (2025–2026) | found | `fox_36_2027` + `fox_36_38_2025` (Rhythm pressure/spacers) |
| FOX | fork | 36 (2018–2020) | found | `fox_36_2020`: pressure bands, pressure-keyed rebound |
| FOX | fork | 36 (2021–2024) | found | `fox_36_38_2024` |
| FOX | fork | 38 (2025–2026) | found | `fox_38_2026`; 2027 manual (`fox_38_2027`) changed the table, not mapped |
| FOX | fork | 38 (2021–2024) | found | `fox_36_38_2024` |
| FOX | fork | 40 | found | `fox_40_2027`: weight → psi range; HSR above catalog max 8 |
| FOX | fork | Podium | found | `fox_podium_2027`: weight → psi, pressure → LSR/HSR |
| FOX | fork | AWL | found | `fox_awl_2027`: rebound rows above `rail` max 9 |
| FOX | shock | FLOAT | found | `fox_float_2027`: psi = lb formula, pressure → rebound, SAG 25–30 % |
| FOX | shock | FLOAT SL | found | `fox_float_sl_float_x_2027`: formula, pressure → rebound (Open/Closed cells) |
| FOX | shock | FLOAT X | found | `fox_float_sl_float_x_2027` |
| FOX | shock | FLOAT X2 (2025–2026) | found | `fox_float_x2_2027`: pressure → LSR/HSR/LSC/HSC ranges |
| FOX | shock | FLOAT X2 (2016–2020) | found | `fox_float_x2_2020` (+ 2018, 2016/17 variants) |
| FOX | shock | FLOAT X2 (2021–2024) | found | `fox_float_x2_2024` |
| FOX | shock | DHX2 (2025–2026) | found | `fox_dhx2_2027`: spring rate → 4 adjusters |
| FOX | shock | DHX2 (2016–2020) | found | `fox_coil_2020`: A/B/C by stroke × rear travel, spring rate |
| FOX | shock | DHX2 (2021–2024) | found | `fox_coil_2024`: A/B/C by stroke × rear travel, spring rate |
| FOX | shock | DHX | partial | `fox_dhx_2027`: ~30 % SAG table only |
| FOX | shock | FLOAT DPS | found | `fox_float_dps_dpx2_2021`: formula, pressure → rebound, constants |
| FOX | shock | FLOAT DPX2 | partial | `fox_float_dps_dpx2_2021`: formula + SAG only |
| RockShox | fork | Pike | found | `rockshox_pike_2025`, `rockshox_pike_2023`: weight → psi per travel, rebound formula, HSC/LSC, factory tokens |
| RockShox | fork | Lyrik | found | `rockshox_lyrik_2027`, `rockshox_lyrik_2025`, `rockshox_lyrik_2023` |
| RockShox | fork | ZEB | found | `rockshox_zeb_2027`, `rockshox_zeb_2025`, `rockshox_zeb_2023` |
| RockShox | fork | BoXXer | found | `rockshox_boxxer_2027`, `rockshox_boxxer_2024`, `rockshox_boxxer_2019`: printed max 300 psi vs catalog 260 |
| RockShox | fork | SID SL | found | `rockshox_sid_sl_2025` (E1 and D1 charts differ), `rockshox_sid_sl_2021`; 80 mm not covered |
| RockShox | fork | SID | found | `rockshox_sid_2025`, `rockshox_sid_2021`; 100 mm (2021) not covered |
| RockShox | fork | Reba | found | `rockshox_reba_2024` |
| RockShox | fork | Psylo | found | `rockshox_psylo_2027` |
| RockShox | fork | Domain | found | `rockshox_domain_2027` |
| RockShox | fork | Rudy XPLR | found | `rockshox_rudy_xplr_2027`: SAG 5 % |
| RockShox | fork | Rudy XL | found | `rockshox_rudy_xl_2027` |
| RockShox | fork | Yari | found | `rockshox_yari_2024`: 29+ and Dual Position Air rows not encoded |
| RockShox | fork | Revelation | found | `rockshox_revelation_2024` |
| RockShox | fork | Recon Gold | found | `rockshox_recon_gold_2027`: one typo cell flagged |
| RockShox | shock | Deluxe, Super Deluxe (Air/Coil/Ultimate DH), Vivid (Air/Coil), SIDLuxe, Monarch, Monarch Plus | partial | `rockshox_rear_shock_um`: psi = lb formula, SAG per spring type, HSC/LSC base, generic rebound formula; per-model charts need a serial number |
