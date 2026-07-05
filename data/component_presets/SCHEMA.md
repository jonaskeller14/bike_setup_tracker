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
| `source` (or `source1`/`source2`, …) | Landing URL(s) the data was collected from |
| `updated` | ISO date of last verification |
| `dampers` | Map of `damper_key` → damper definition |
| `forks` / `shocks` | List of models (key name matches `component_type`) |

## Damper definition

```yaml
grip_x2:
  name: GRIP X2               # display name
  description: ...            # short blurb
  adjusters:                  # each becomes a StepAdjustment
    high_speed_compression: { clicks: 8 }
    low_speed_compression:  { clicks: 18 }
    high_speed_rebound:     { clicks: 8 }
    low_speed_rebound:      { clicks: 16 }
  valves: 23                  # informational
  compression_positions: [Open, Medium, Firm]   # optional → CategoricalAdjustment
  firm_mode: at final HSC click                  # optional note
  remote: 2-position                             # optional note
```

`adjusters` keys → adjustment name mapping:

| key | Adjustment name | unit |
|---|---|---|
| `high_speed_compression` | High-Speed Compression | (clicks) |
| `low_speed_compression` | Low-Speed Compression | (clicks) |
| `high_speed_rebound` | High-Speed Rebound | (clicks) |
| `low_speed_rebound` | Low-Speed Rebound | (clicks) |
| `rebound` | Rebound | (clicks) |
| `compression` | Compression | (clicks) |

`clicks: N` → `StepAdjustment(min: 0, max: N, step: 1)`. Clicks are counted from
fully closed (firmest = 0).

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
      dampers: [grip_x2, grip_x]   # damper key(s); >1 = buyer-selectable
      note: ...               # optional (e.g. "OEM complete bikes only")
```

## Shock entry

Shocks are sold by eye-to-eye/stroke length to fit a given frame rather than a
fixed "travel" like forks, so `stroke_mm` (when known) lists commonly offered
strokes instead of an exhaustive per-frame spec:

```yaml
- model: "DHX2"                # model name
  category: Downhill / Enduro  # discipline (informational/grouping)
  spring: Coil                 # Air | Coil
  year_range: "2025-2026"
  url: https://ridefox.com/pages/fox-dhx2
  trims:
    - trim: Factory
      stanchion: Kashima
      dampers: [vvc2]
      stroke_mm: [55, 60, 62.5, 65]   # optional, when a spec page lists them
      mount: [Metric, Metric Trunnion]  # optional
      note: ...
```

## How a selection becomes adjustments

When a user selects **brand › model › trim › damper**, the app generates the
`Adjustment` presets (see `lib/widgets/sheets/component_add_adjustment.dart`):

1. Start with the generic `ComponentType.fork` presets — Lockout, Pressure, SAG,
   Volume Spacers.
2. Replace the generic Rebound/Compression with a `StepAdjustment` per damper
   `adjusters` entry, using the real click range (`min: 0, max: clicks`) and
   `sliderWithCounterclockwiseDial` visualization.
3. If the damper has `compression_positions`, add a `CategoricalAdjustment`
   (e.g. Open/Medium/Firm) instead of/alongside compression clicks.

The fork's `url` should be stored on the component as its source reference.

## Optional fields / escape hatches

The formats above aren't rigid — small deviations are expected as brands don't
all publish specs the same way:

- **Per-trim `url` override**: if a trim/variant has its own product page
  (e.g. a "Coil" version sold separately from the "Air" version), give it its
  own `url:` inside that trim instead of relying on the model-level one.
- **`adjusters: {}`**: leave empty (or omit specific keys) when a damper is
  externally adjustable but the exact click count wasn't published — note
  this in a `description` and/or the file's "Follow-ups" footer instead of
  guessing a number.
- **Freeform informational keys** (`valves`, `firm_mode`, `remote`, `lockout`,
  `open_mode_micro_adjust`, `offset_mm`, `mount`, …): add whatever extra
  key(s) best capture a damper/model's distinguishing spec. These aren't
  consumed by the click-range → `StepAdjustment` mapping, they're for humans
  and future schema growth.
- **Same physical damper, different click counts across generations**: give
  each generation its own damper key (e.g. `ttx18_m2` vs `ttx18_m3`) rather
  than picking one number — brands sometimes revise a cartridge's internals
  under the same name.
