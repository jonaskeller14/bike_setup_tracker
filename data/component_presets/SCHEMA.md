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

Prefer the manufacturer's own site (product pages, spec sheets, official PDF
manuals) for every number. When a brand simply doesn't publish a click-count
total anywhere official — common for boutique brands whose marketing copy only
gives a recommended starting position — a **pinkbike.com review article's own
body text** (the written review itself, not the reader comments below it) is
an allowed fallback source for that one number. Cite the article URL in
`sources:` same as any other source, and note in the damper's `description`
that the figure comes from a Pinkbike review rather than the manufacturer.
Other outlets (Vital MTB, Bikeradar, forums, YouTube, etc.) are still out of
scope — this exception is Pinkbike-body-text only.

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

## Damper definition

```yaml
grip_x2:
  name: GRIP X2               # display name
  description: ...            # short blurb
  adjustments:                # each maps 1:1 to an Adjustment via fromYaml
    - { name: High-Speed Compression, type: step, max: 8 }
    - { name: Low-Speed Compression,  type: step, max: 18 }
    - { name: High-Speed Rebound,     type: step, max: 8 }
    - { name: Low-Speed Rebound,      type: step, max: 16 }
  valves: 23                  # informational (freeform key → damper.info)
```

```yaml
charger_3_1:
  name: Charger 3.1
  adjustments:
    - { name: High-Speed Compression, type: step, min: -2, max: 2, visualization: dial_cw }
    - { name: Low-Speed Compression,  type: step, min: -7, max: 7, visualization: dial_cw }
    - { name: Rebound, type: step, max: 18, notes: Counted from fully open (fastest) }
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
  category: All-Mountain      # discipline (informational/grouping)
  year_range: "2025-2026"     # model years these specs apply to
  url: https://ridefox.com/pages/fox-36   # source page for this model
  wheel_size: [29, 27.5]
  trims:                      # user-facing sub-models
    - trim: Factory
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

- **Per-trim `url` override**: if a trim/variant has its own product page
  (e.g. a "Coil" version sold separately from the "Air" version), give it its
  own `url:` inside that trim instead of relying on the model-level one.
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
