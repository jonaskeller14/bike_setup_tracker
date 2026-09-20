# Component preset database — schema

Human-editable source of truth for factory component specs, so the app can offer
"pick your exact fork → auto-add the right adjustments" flows.

One directory per `component_type` (`fork/`, `shock/`, …), one YAML file per
brand inside it, e.g. `fork/fox.yaml`, `shock/fox.yaml`, `fork/ohlins.yaml`.

## Why dampers are separate from forks/shocks

Click ranges (rebound/compression) are a property of the **damper cartridge**, not
the fork/shock model. A FOX 36, 38 and 40 all share the GRIP X2 damper (and FOX
FLOAT X2/DHX2 share the VVC2 damper) — same click counts. So dampers are defined
once under `dampers:` and each model's trim references them by key. Fix a number
in one place, every model that uses it gets it.

## Top-level fields

| Field | Meaning |
|---|---|
| `brand` | Manufacturer, e.g. `FOX` |
| `component_type` | Maps to `ComponentType` enum (`fork`, `shock`, …) |
| `sources` | List of URLs the data was collected from (landing page + individual product pages) |
| `updated` | ISO date of last verification |
| `dampers` | Map of `damper_key` → damper definition |
| `forks` / `shocks` | List of models (key name matches `component_type`) |

### Sourcing policy

Every number in this catalog must be traceable to a named source. Two tiers:

1. **Primary — the manufacturer.** Product pages, spec tables, official PDF
   owner's/tuning manuals, service manuals, archived spec sheets
   (e.g. `tech.ridefox.com/bike/list/spec-sheets`, `sram.com` service manuals,
   `service.ohlins.com`). Always prefer these.
2. **Secondary — serious editorial reviews**, when the manufacturer publishes
   no number at all. Allowed outlets: Pinkbike, Vital MTB, BikeRadar, MBR,
   Enduro-MTB, Flow Mountain Bike, Bike Magazine, NSMB, Singletracks and
   comparable staff-written publications. Only the **article's own body text**
   counts — never reader comments, forum posts, YouTube, retailer listings,
   or AI summaries.

Both tiers must be cited (see [Citing a source](#citing-a-source)). Never
guess, interpolate, or infer a click count from a setup-recommendation chart's
column count — an omitted number plus a follow-up note is always better than a
wrong one.

### Citing a source

- Put every URL you used in the file's top-level `sources:` list.
- Attach the specific source to the specific number:
  - **Dampers** take a freeform `source:` key (string or list of URLs). It
    lands in the damper's `info` map — human-readable, never shown in the app.
  - **Models/trims** already carry `url:`; when a spec came from a different
    page than the product page (a tuning-guide PDF, say), add a `#` comment on
    the line or a `source:` key alongside `url:`.
- When a figure comes from a secondary (magazine) source rather than the
  manufacturer, say so in the damper's `source:`/`note:` — **not** in its
  `description`, which is user-facing (see below).

```yaml
grip2_2019:
  name: GRIP2 (2019-2024)
  description: Four-way adjustable descent damper with VVC high-speed circuits.
  adjustments:
    - { name: HSC, type: step, max: 8, notes: High-Speed Compression }
    # ...
  source:
    - https://www.ridefox.com/dl/bike/2020-FOX-Tuning-Guide.pdf
  note: Click counts read off the 2020 FOX Tuning Guide, p. 12.
```

## Top-level example

```yaml
brand: FOX
component_type: fork
sources:
  - https://ridefox.com/pages/bike-forks
  - https://ridefox.com/pages/fox-36
  - https://ridefox.com/pages/fox-38
  # ... individual product pages
updated: 2026-07-05
```

## Adjustments — sparse literal lists

Dampers, models and trims all carry an `adjustments:` list. Each entry is a
**sparse** map that maps 1:1 to one of the app's `Adjustment` subclasses via the
strict `Adjustment.fromYaml` factory (`lib/models/adjustment/adjustment.dart`).
"Sparse" means: write only what deviates from the defaults below. Any **unknown
key throws** at parse time — the CI catalog test doubles as a typo detector, so
misspelling `viz:` for `visualization:` fails CI rather than being ignored.

### Fields & defaults

| Field | Applies to | Required? | Default |
|---|---|---|---|
| `name` | all | **yes** | — |
| `type` | all | **yes** | — (`step` \| `numerical` \| `categorical` \| `boolean`) |
| `notes` | all | no | none |
| `unit` | all | no | none (e.g. `psi`, `bar`, `lbs/in`, `mm`, `°`; blessed customs `clicks`, `%`, `turns`, `tokens`) |
| `min` | step, numerical | no | `0` (step), unbounded (numerical) |
| `max` | step, numerical | step: **yes** · numerical: no | step: — · numerical: unbounded |
| `step` | step | no | `1` |
| `visualization` | step | no | `dial_ccw` |
| `dialColor` | step | no | `blue` (`blue` \| `red` \| `green` \| `brown` \| `orange` \| `purple` \| `grey`) |
| `dialSize` | step | no | `normal` (`normal` \| `small`) |
| `options` | categorical | **yes** (non-empty) | — |
| `multiSelect` | categorical | no | `false` |

`text` and `duration` adjustments are intentionally **not** supported in data.

### `visualization` values (step only)

| YAML value | App enum | When to use |
|---|---|---|
| `dial_ccw` (default) | `sliderWithCounterclockwiseDial` | Clicks counted from fully **closed** (firmest = 0); opening = counterclockwise. The FOX convention. |
| `dial_cw` | `sliderWithClockwiseDial` | Increasing value turns the dial **clockwise**, e.g. RockShox Charger from-middle adjusters where `-2` lies counterclockwise of the `0` detent. |
| `stepper` | `minusButtonValuePlusButton` | Discrete counts, no dial — e.g. Volume Spacers. |
| `slider` | `slider` | Plain slider, no dial. |

### `dialColor` and `dialSize` (step only)

Match the **physical dial knob** on the real damper — the app renders the
adjustment's dial in that color/size so it looks like the part the rider is
actually turning. Source these from official product photos, tuning guides or
manuals; when a knob's color/size isn't confirmed, omit the field (defaults to
`blue`/`normal`) rather than guessing.

High-speed and low-speed circuits sharing one damper are typically the same
color (the brand's compression color vs. its rebound color) with the
high-speed adjuster as the larger primary dial (`normal`) and the low-speed
adjuster as a smaller nested dial (`small`) — e.g. FOX GRIP X2:

```yaml
adjustments:
  - { name: HSC, type: step, max: 8, notes: High-Speed Compression, dialColor: blue }
  - { name: LSC, type: step, max: 18, notes: Low-Speed Compression, dialColor: blue, dialSize: small }
  - { name: HSR, type: step, max: 8, notes: High-Speed Rebound, dialColor: red }
  - { name: LSR, type: step, max: 16, notes: Low-Speed Rebound, dialColor: red, dialSize: small }
```

### Click ranges & counting conventions

`clicks: N` in the old schema is now `type: step, max: N` (min defaults to 0).
Where a brand counts **from the middle** (RockShox Charger 3.1/3.2: HSC `-2..+2`,
LSC `-7..+7`), write the real `min`/`max` literally and set
`visualization: dial_cw`. Where the count runs **from fully open** (e.g. rebound
on many RockShox dampers), keep `min: 0` and record the direction in `notes` so
it reaches the user. Öhlins versions cartridges (`m.2`/`m.3`) with different
ranges — give each generation its own damper key.

### Combine order

At application time the app concatenates, in this order and preserving each
list's authored order (which is the on-screen order):

1. trim/model `adjustments` (the spring: pressure, spacers, spring-rate …)
2. auto-injected **SAG** (parser/prefill-injected for fork/shock only — it is
   universal and carries app-specific discipline guidance, so it never lives in
   brand data)
3. damper `adjustments` (compression/rebound clicks, mode categoricals …)

### Anchor reuse

Identical spring lists (e.g. every air FOX trim repeating Pressure) can be
written once with a YAML anchor and reused with an alias — the `yaml` package
resolves these before the parser sees them:

```yaml
adjustments: &air_spring
  - { name: Pressure, type: numerical, unit: psi, min: 0 }
# … later …
adjustments: *air_spring
```

Anchors are sugar for **identical** lists only; YAML cannot extend an aliased
list. A trim that deviates in any way (extra chamber, published spacer count,
different max) simply writes its own literal list instead of the alias.

## User-facing text: `description` and `note`

Two fields in this catalog are copied verbatim into the notes of the component
the user ends up with (see `_buildNotes` in
`lib/utils/component_preset_application.dart`):

| Field | Where |
|---|---|
| damper `description` | rendered as `Damper: <name> — <description>` |
| model/trim `note` | rendered on its own line |

Write them **for the rider, not for the next data editor.** They describe the
part: what the damper does, how its adjusters behave, what makes the chassis
distinctive. Keep them short — one to three facts.

**Never** put research meta in them:

| ❌ Don't write | ✅ Where it belongs instead |
|---|---|
| "confirmed by a Flow MTB first-ride review" | damper `source:` / `note:` |
| "not published on the product page" | Follow-ups footer |
| "verify before relying on it", "flagged as follow-up" | Follow-ups footer |
| "exact internals not independently confirmed" | Follow-ups footer |
| "search results only mentioned Ultimate and Select+" | Follow-ups footer |

The one exception is a short, actionable heads-up when adjusters are missing
from the data — the rider needs to know they have to add them by hand:

```yaml
    description: >-
      Lightweight XC damper for marathon racing. Adjustments incomplete:
      please add Rebound and Compression yourself.
```

Everything meta stays in `#` comments, in the damper's freeform `note:`/
`source:` keys (collected into `info`, never displayed), or in the file's
Follow-ups footer.

### Bullet points

When a description or note carries more than about two distinct facts, write
it as a dash list — it reads far better in the app's notes field than one long
paragraph:

```yaml
    note: |-
      - Inverted (USD) single-crown chassis, 44mm offset
      - Crown heights 58HT / 68HT
      - Custom steel 20mm axle
      - Float EVOL GlideCore air spring
```

Use the **literal** block scalar `|-` for bullet lists: the folded scalar `>`
collapses newlines into spaces and would run the bullets together on one line.
Use `>-` (or a plain scalar) only for flowing prose that is meant to be a
single paragraph.

## Legacy / older model years

Older generations are wanted — riders keep forks for a decade — but a
generation is only worth adding when its numbers can actually be sourced.

- **One block per generation, all sharing the model name.** Never suffix
  `model:` with years — every FOX 36 generation is `model: "36"`. The picker
  groups by brand + model, so the blocks merge into a single `36` row whose
  trim list holds all of them, each trim badged with its own years
  (`FOX › 36 › Factory (2021-2024)`).
- **`year_range:` is required on any block that shares its name.** It is the
  only thing keeping two generations of `Factory` apart, both in the picker and
  when deriving a new trim's `key:`. The model row shows the span across
  generations (`2018–2026`) as its subtitle.
- **Author newest generation first.** The merged trim list follows file order;
  put older generations below the current one, under a comment footer (see
  `fork/rockshox.yaml`).
- **Generation-level fields stay on their own block.** `url`, `wheel_size`,
  `complete` and `note` describe one generation and are not shared — so
  `complete: false` hides just that generation's trims, and the rest of the
  model stays in the picker. `category:` is the exception: it labels the merged
  row, so same-named blocks must agree on it (CI checks this).
- **Give each generation its own damper key** (`fit4_2016`, `grip2_2019`,
  `charger_2_1`, `ttx18_m2`) even when the cartridge kept its name — brands
  revise internals and click counts under an unchanged badge.
- **Don't inherit numbers across generations.** If the older damper's counts
  aren't published, define it with `adjustments: []`, mark the models that use
  it `complete: false`, and record the gap in the Follow-ups footer.

## Trim `key:` — permanent identity

Every trim carries a required `key:`. It is **persisted on every component a
user creates from that preset** (`Component.presetKey`, plus the chosen damper
in `Component.presetDamperKey`), which is what lets the app later offer setup
guides and service intervals for that exact product.

- **Never edit a key that has shipped.** Renaming `model:` or `trim:`, fixing a
  typo, or extending `year_range: "2025-2026"` to `"2025-2027"` must leave the
  key untouched — otherwise every component already saved against it is
  orphaned. The key is authored once and then frozen.
- **Format:** `<component_type>-<brand>-<model>-<trim>[-<first year>]`,
  lowercase, ASCII, hyphen-separated — `fork-fox-36-factory-2025`. The year is
  the generation's *first* year, so extending the range never changes it.
  Accented characters are spelled out (`Öhlins` → `ohlins`).
- **Globally unique** across all brand files; CI enforces uniqueness and shape.
- **Splitting a generation:** the surviving block keeps its key, the new block
  gets a fresh one.
- **Generating one:** `dart run tool/preset_keys.dart --write` derives and
  inserts a key for every trim that lacks one, and never touches existing keys.
  Run it bare to check for missing or duplicate keys.

Damper keys (`grip_x2`, `charger_3_1`) are a separate, file-scoped namespace and
are also persisted, so they are frozen the same way.

## Damper definition

```yaml
grip_x2:
  name: GRIP X2               # display name
  description: ...            # short blurb
  adjustments:                # each maps 1:1 to an Adjustment via fromYaml
    - { name: HSC, type: step, max: 8, notes: High-Speed Compression }
    - { name: LSC, type: step, max: 18, notes: Low-Speed Compression }
    - { name: HSR, type: step, max: 8, notes: High-Speed Rebound }
    - { name: LSR, type: step, max: 16, notes: Low-Speed Rebound }
  valves: 23                  # informational (freeform key → damper.info)
```

```yaml
charger_3_1:
  name: Charger 3.1
  adjustments:
    - { name: HSC, type: step, min: -2, max: 2, visualization: dial_cw, notes: High-Speed Compression }
    - { name: LSC, type: step, min: -7, max: 7, visualization: dial_cw, notes: Low-Speed Compression }
    - { name: Rebound, type: step, max: 18, notes: Counted from fully open (fastest) }
```

When a damper has both a high-speed and a low-speed circuit for compression or
rebound, name the adjustment with the abbreviation (`HSC`/`LSC`/`HSR`/`LSR`)
and put the spelled-out name in `notes` (prefixed before any other note text,
separated by `; `) — see the examples above.

When a damper has only a single compression or rebound circuit, skip the speed
qualifier in `name` and just use `Compression` / `Rebound` — but if the source
material itself calls that single circuit "Low-Speed" (or "High-Speed"), keep
that qualifier as the first clause of `notes`, same `; `-separated convention:

```yaml
helm_damper:
  name: Helm Damper
  adjustments:
    - { name: HSC, type: step, max: 10, notes: High-Speed Compression }
    - { name: LSC, type: step, max: 17, notes: Low-Speed Compression }
    - { name: Rebound, type: step, max: 10, notes: "Low-Speed Rebound; Cane Creek labels this the fork's single rebound circuit (no separate high-speed rebound adjuster)" }
```

An on-the-fly compression lever (old `compression_positions`) is now a
categorical:

```yaml
    - { name: Compression Mode, type: categorical, options: [Open, Medium, Firm] }
```

A damper whose external click counts weren't published lists an empty
`adjustments: []` (or omits the uncertain entry) and explains it in
`description`/`note` — **never guess a number**.

All keys other than `name`, `description` and `adjustments` (e.g. `valves`,
`firm_mode`, `remote`, `note`, `lockout`) are freeform informational metadata,
collected into the damper's `info` map for humans; they are not consumed as
adjustments.

## Fork entry

```yaml
- model: "36"                 # model name
  complete: true              # optional; omit or set to true if all click counts published
  category: All-Mountain      # discipline (informational/grouping)
  year_range: "2025-2026"     # model years this generation's specs apply to
  url: https://ridefox.com/pages/fox-36   # source page for this model
  wheel_size: [29, 27.5]
  trims:                      # user-facing sub-models
    - trim: Factory
      key: fork-fox-36-factory-2025   # permanent identity — never edit (see below)
      travel_mm: [150, 160]   # offered travels
      stanchion: Kashima
      spring: Air             # informational metadata (Air | Coil)
      dampers: [grip_x2, grip_x]   # damper key(s); >1 = buyer-selectable
      adjustments: *air_spring     # trim-level spring adjustments (see anchor reuse)
      note: ...               # optional (e.g. "OEM complete bikes only")
```

The trim-level `adjustments:` list holds the **spring** adjustments (air
pressure, published volume-spacer count, coil spring-rate/preload). Add only
what is certain: every air spring has a Pressure; every coil has a Spring Rate.
Volume spacers are listed **only where the max is published** — otherwise omit
them and add a follow-up note rather than guessing a range. `spring: Air | Coil`
is informational only; it no longer drives adjustment generation.

## Shock entry

Shocks are sold by eye-to-eye/stroke length to fit a given frame rather than a
fixed "travel" like forks, so `stroke_mm` (when known) lists commonly offered
strokes instead of an exhaustive per-frame spec. The model-level `spring:`
default (`Air` | `Coil`) decides whether trims carry a Pressure or a Spring
Rate; a trim may also carry its own `spring:` for the spring **variant** name
(`DebonAir+`, `SoloAir`, …), which is informational only.

```yaml
- model: "DHX2"                # model name
  category: Downhill / Enduro  # discipline (informational/grouping)
  spring: Coil                 # Air | Coil (model-level default)
  year_range: "2025-2026"
  url: https://ridefox.com/pages/fox-dhx2
  trims:
    - trim: Factory
      key: shock-fox-dhx2-factory-2025   # permanent identity — never edit
      stanchion: Kashima
      dampers: [vvc2]
      adjustments:
        - { name: Spring Rate, type: numerical, unit: lbs/in, min: 0 }
      stroke_mm: [55, 60, 62.5, 65]   # optional, when a spec page lists them
      mount: [Metric, Metric Trunnion]  # optional
      note: ...
```

## How a selection becomes adjustments

When a user selects **brand › model › trim › damper**, the app concatenates the
adjustment specs in the **combine order** above — trim spring adjustments,
auto-injected SAG, then the chosen damper's adjustments — and instantiates each
via `Adjustment.fromYaml` (fresh UUIDs). Nothing generic is added that the data
doesn't declare: no default Lockout/Pressure/Spacers/0–20-click adjusters. The
variant's `url` is surfaced in the generated component's notes as its source
reference.

## Optional fields / escape hatches

The formats above aren't rigid — small deviations are expected as brands don't
all publish specs the same way:

- **`complete: false`**: set on a model when any damper it uses has unpublished
  click counts (`adjustments: []`). The UI will not show incomplete models in
  the preset picker — they're excluded until the data is complete. Omit the
  field or set to `true` if all click counts are published.
- **Per-trim `url` override**: if a trim/variant has its own product page
  (e.g. a "Coil" version sold separately from the "Air" version), give it its
  own `url:` inside that trim instead of relying on the model-level one.
- **Per-trim `year_range` override**: only for the rare model where one trim
  ran different years than its siblings. The normal way to express a
  generation is a separate model block (see [Legacy / older model
  years](#legacy--older-model-years)).
- **`adjustments: []`**: leave empty (or omit specific entries) when a damper is
  externally adjustable but the exact click count wasn't published — note
  this in a `description` and/or the file's "Follow-ups" footer instead of
  guessing a number.
- **Freeform informational keys** (`valves`, `firm_mode`, `remote`, `lockout`,
  `open_mode_micro_adjust`, `offset_mm`, `mount`, …): add whatever extra
  key(s) best capture a damper/model's distinguishing spec. On a damper these
  land in its `info` map; they are not consumed as adjustments — they're for
  humans and future schema growth.
- **Same physical damper, different click counts across generations**: give
  each generation its own damper key (e.g. `ttx18_m2` vs `ttx18_m3`) rather
  than picking one number — brands sometimes revise a cartridge's internals
  under the same name.
