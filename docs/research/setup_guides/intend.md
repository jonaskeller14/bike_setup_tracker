# INTEND — setup guide research

Catalog files: `data/component_presets/fork/intend.yaml` (INTEND makes no rear shocks in the catalog; there is no `shock/intend.yaml`)
Researched: 2026-10-11

## Summary

- INTEND publishes one setup page for all its forks (`intend-bc.com/fork-setup/`). There are no per-model owner's manuals or PDFs.
- **Pressure is a formula**, not a table: psi per kg of rider weight, with one factor per model group (1.0 or 1.3). It covers Samurai, Hero, Edge, Flash, Infinity EN and Bandit. Essential is not listed.
- **Compression has one starting click** (6, counted from fully closed). It is the same for every model and matches the catalog `Compression` direction (`max: ~`, counted from closed).
- **Rebound** guidance is only "start in the middle of the range". The catalog has no Rebound adjuster (`missing_adjustments`), so this can only be a `display_only` note.
- No SAG target, no pressure limits and no rider-weight click tables are published.
- **Volume:** the factory pre-installed progression cap/spacer position is known (Essential: mid position of 3), but the catalog has no `volume_spacers` adjuster.
- Shapes B3 doesn't cover: the formula (encode as calculated rows), and the Linearizer accessory (a third air chamber whose pressure is a ratio of the main pressure; not in the catalog).

## Guide `intend_fork_setup_2025` — Fork Setup Guide & Instructions

### Source

- URL: https://www.intend-bc.com/fork-setup/
- Document: "Fork Setup Guide & Instructions" web page (footer © 2025), English
- Section / page: "Air Spring" (pressure table), "Damping", "Progression Tuning"
- Retrieved: 2026-10-11

### Catalog mapping

| Catalog path | `when:` | Notes |
|---|---|---|
| `fork/intend/samurai-xc-29/standard` | `damper: energizer` or `damper: rs_charger_raceday` | "Samurai" row, 1.0 psi/kg. Pressure applies to both dampers. There is no compression click target (Energizer has only a categorical `Mode`; Charger has no adjusters in the catalog). |
| `fork/intend/samurai-xc-32/standard` | `damper: energizer` or `damper: rs_charger_raceday` | "Samurai" row, 1.0 psi/kg. Same compression note as above. |
| `fork/intend/samurai-super-tr/standard` | `damper: closed_cartridge` | "Samurai" row, 1.0 psi/kg; compression 6 |
| `fork/intend/hero/standard` | `damper: closed_cartridge` | "Hero, Edge, Flash" row, 1.0 psi/kg; compression 6 |
| `fork/intend/edge/standard` | `damper: closed_cartridge` | "Hero, Edge, Flash" row, 1.0 psi/kg; compression 6 |
| `fork/intend/flash-35/standard` | `damper: closed_cartridge` | "Flash" (the guide doesn't split 35/38), 1.0 psi/kg; compression 6 |
| `fork/intend/flash-38/standard` | `damper: closed_cartridge` | "Flash", 1.0 psi/kg; compression 6 |
| `fork/intend/infinity-en/standard` | `damper: closed_cartridge` | "Infinity EN, Bandit" row, 1.3 psi/kg; compression 6 |
| `fork/intend/bandit/standard` | `damper: closed_cartridge` | "Infinity EN, Bandit" row, 1.3 psi/kg; compression 6 |
| `fork/intend/essential/standard` | `damper: open_bath` | Not in the pressure table. The generic damping section (compression 6) applies, because Essential's open-bath damper also has an LSC dial counted from closed. |

Gaps:
- Essential has no pressure factor.
- The guide's travel table lists "Samurai TR 100-130 mm" and "Samurai XC 90-120 mm". These don't match the catalog travels (Super TR 140-170, XC 29 100-130, XC 32 120-130). This affects travel only, not pressure. The YAML Follow-ups already note it.

### Air pressure — formula (no table published)

Input: rider weight (kg) · Output: psi · no `when:` beyond the catalog path

| Fork model (as printed) | Factor (as printed) | Catalog paths |
|---|---|---|
| Hero, Edge, Flash | 1,0 PSI/Kg rider weight | `hero`, `edge`, `flash-35`, `flash-38` |
| Infinity EN, Bandit | 1,3 PSI/Kg rider weight | `infinity-en`, `bandit` |
| Samurai | 1,0 PSI/Kg rider weight | `samurai-xc-29`, `samurai-xc-32`, `samurai-super-tr` |

See Formulas below for the calculated rows.

### Rebound

The source gives no click number: start mid-range, then adjust until the front wheel doesn't lift when the fork is pushed down and released quickly. The catalog has no `rebound` adjuster on `closed_cartridge` or `open_bath` (it is listed in `missing_adjustments`), so this can only be encoded as a `display_only` note.

### Constants / base tune

Source direction: clicks counted from fully closed. Catalog: `closed_cartridge` and `open_bath` `compression` are `type: step`, `max: ~`, notes "Counted from fully closed (firmest)". Same direction → encode as published. A `max: ~` placeholder doesn't block encoding here, because the directions match.

| Target | Value | Direction | `when:` |
|---|---|---|---|
| `compression` | 6 | from fully closed | `damper: closed_cartridge` |
| `compression` | 6 | from fully closed | `damper: open_bath` |

The page explains two click zones. Clicks 1-6 from closed are coarsely spaced and meant for racers. From 6 to fully open the spacing is fine and meant for comfort riders. Both zones use 6 as the start point. Racers may close the dial fully for maximum support. Useful as a `note`.

### SAG

Not published.

### Volume spacers

- Hero / Edge / Flash 35 / Flash 38 (product pages): two alternative progression bottom caps ship in the box, one fitted. There is no count or cc value, only "less/more progression".
- Essential (product page https://www.intend-bc.com/products/essentials/): a volume spacer in the bottom cap with 3 positions (without = less, mid = mid progression, max = max progression). **Mid is factory-installed.**
- Setup page: try the stock setting before changing progression.
- Catalog: no `volume_spacers` adjuster on any INTEND trim → cannot be encoded (see gaps).

### Pressure limits

Not published. The catalog has `Pressure` `min: 0` and no `max`, which matches.

### Formulas

psi = factor × rider weight in kg (factor 1.0 or 1.3, see the table above). The source gives no rider-weight range, so these rows use 50–120 kg. They are **calculated from the published formula**, not printed by INTEND.

| Rider weight (kg) | psi @ 1.0 psi/kg (Samurai, Hero, Edge, Flash) | psi @ 1.3 psi/kg (Infinity EN, Bandit) |
|---|---|---|
| 50 | 50 | 65 |
| 55 | 55 | 71.5 |
| 60 | 60 | 78 |
| 65 | 65 | 84.5 |
| 70 | 70 | 91 |
| 75 | 75 | 97.5 |
| 80 | 80 | 104 |
| 85 | 85 | 110.5 |
| 90 | 90 | 117 |
| 95 | 95 | 123.5 |
| 100 | 100 | 130 |
| 105 | 105 | 136.5 |
| 110 | 110 | 143 |
| 115 | 115 | 149.5 |
| 120 | 120 | 156 |

### Does not fit B3

- **Formula.** B3 has no multiplier rule. Proposal: encode as `rows` at 5 kg steps from the table above, with a `note` naming the formula. Alternatively, B3 could add a `factor` rule (`value = k × input`).
- **Linearizer (retrofit 3-chamber air spring)**, https://www.intend-bc.com/products/linearizer/. It adds a second positive chamber. The published starting point is a chamber ratio of 1:2: Linearizer chamber = regular pressure × 1.8, main chamber = half of the Linearizer pressure. Worked example on the page: 80 psi regular → 144 psi Linearizer / 72 psi main. Alternatives are also printed for an 80 kg rider (65/144 and 70/130 psi). The catalog has no Linearizer option and no second pressure adjuster → not encodable. If it is added later, use `input: pressure` (regular) → `target: linearizer_pressure`.
- **Rebound "middle of range"** has no adjuster and no click total → `display_only` text only.

## Products without a structured guide

| Catalog path | Reason |
|---|---|
| `fork/intend/essential/standard` | The setup page's pressure table has no Essential row. The product page gives only the factory volume-spacer position (mid of 3) and no pressure. Only the generic compression start point applies. |
| `fork/intend/samurai-xc-29/standard` `damper: rs_charger_raceday` | Pressure follows the "Samurai" factor. Damper settings are RockShox's own (out of scope, as in the YAML). |
| `fork/intend/samurai-xc-32/standard` `damper: rs_charger_raceday` | Same as above. |

Checked: the setup page, all product pages (Bandit and Infinity EN product URLs in the YAML return "Page not found"; the setup page covers both), the fork chart, the Smooth Operator guide (installation steps only, no settings) and the Linearizer page. INTEND links no PDF manuals.

## Follow-ups

- The Bandit and Infinity EN product URLs in `fork/intend.yaml` (`/products/bandit/`, `/products/infinity-en/`) now return 404. The live pages are linked from the site menu via `?post_type=product-pages&p=…` ids, which also returned "Not Found" to curl. Recheck in a browser.
- Essential pressure: ask INTEND, or check whether a later version of the setup page adds an Essential row.
- If the catalog gains a `volume_spacers` (or "progression cap") adjuster, encode Essential's factory mid position. Hero/Edge/Flash need a named cap position rather than a count.
