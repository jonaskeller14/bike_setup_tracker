# Component catalog — schema

Human-editable source of truth for factory component specs, so the app can offer
"pick your exact fork → auto-add the right adjustments" flows.

One directory per `component_type` (`fork/`, `shock/`, …), one YAML file per
brand inside it, e.g. `fork/fox.yaml`, `fork/ohlins.yaml`.

> **Staging directory.** This is the node/option schema of issue #25. The app
> still reads `data/component_presets/` (the flat model › trim schema) until
> the switch; this directory then replaces it.

## The two concepts: nodes and options

A product is described by two things, and every new dimension goes into
exactly one of them:

- **Nodes say what the product is.** A tree per brand, as deep as that brand
  needs: `model › generation › trim` for FOX, `model › version › trim` for
  Öhlins, `model › mount` for Cane Creek shocks, `model › trim` where a model
  has a single generation. A node without `children` is a selectable
  **product**, at whatever level it sits: a model sold in one version only is
  itself the product.
- **Options say how it is configured.** On the product, each option axis
  (`damper`, `travel_mm`, `wheel_size`, `size`) lists the values that product
  can be had with.

**Rule of thumb:** if it changes the part or the generation, it is a node. If
the buyer picks it, or it can be changed at home, it is an option.

A component created from the catalog persists one map with one entry per tree
level plus one per chosen option:

```
{brand: fox, component_type: fork, model: "36", generation: "2025", trim: factory, damper: grip_x2, travel_mm: 160}
```

## Why dampers are separate from the nodes

Click ranges (rebound/compression) are a property of the **damper cartridge**,
not the fork model. A FOX 36, 38 and 40 all share the GRIP X2 damper — same
click counts. So dampers are defined once under `option_values.damper` and each
product references them by id under `options.damper`. Fix a number in one place,
every product that uses it gets it.

## Top-level fields

| Field | Meaning |
|---|---|
| `brand` | Manufacturer, e.g. `FOX`. Its slug (`fox`, `ohlins`) is the persisted brand id |
| `component_type` | Maps to `ComponentType` enum (`fork`, `shock`, …); must match the directory |
| `sources` | List of URLs the data was collected from (landing page + individual product pages) |
| `updated` | ISO date of last verification |
| `option_values` | Map of axis id → value id → definition, for axes whose values are defined once and referenced (today: `damper`) |
| `nodes` | The product tree |

```yaml
brand: FOX
component_type: fork
sources:
  - https://ridefox.com/pages/bike-forks
  - https://ridefox.com/pages/fox-36
updated: 2026-07-05
option_values:
  damper:
    grip_x2: { name: GRIP X2, adjustments: [ ... ] }
    grip_x:  { name: GRIP X,  adjustments: [ ... ] }
nodes:
  - label: "36"
    level: model
    category: All-Mountain
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        years: "2025-2026"
        url: https://ridefox.com/pages/fox-36
        children:
          - label: Factory
            level: trim
            specs: { stanchion: Kashima, spring: Air }
            adjustments:
              - { name: Pressure, type: numerical, unit: psi, min: 0 }
            options:
              damper: [grip_x2, grip_x]
              travel_mm: [150, 160]
              wheel_size: [29, 27.5]
```

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
column count. When an adjuster exists but its range is not published, declare
it with `max: ~` (see [Unknown click range](#unknown-click-range-max-)); never
write a guessed number.

### Citing a source

- Put every URL you used in the file's top-level `sources:` list.
- Attach the specific source to the specific number:
  - **Dampers** take a freeform `source:` key (string or list of URLs). It is
    for humans only and never shown in the app.
  - **Nodes** carry `url:`; when a spec came from a different page than the
    product page (a tuning-guide PDF, say), add a `#` comment on the line or a
    `source:` key alongside `url:`.
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

## Nodes

| Field | Required? | Inherited? | Meaning |
|---|---|---|---|
| `label` | **yes** | — | Display name (`"36"`, `Factory`, `m.3`). Free to change at any time |
| `level` | **yes** | — | What this step of the tree is called: `model`, `generation`, `trim`, `version`, … lower_snake_case |
| `id` | no | — | Persisted identity of the node. Defaults to the slug of `label` |
| `children` | no | — | Child nodes. A node without it is a product |
| `draft` | no | nearest | `true` hides the node and its whole subtree from selection |
| `category` | no | nearest | Discipline (`Enduro`, `XC`, …), informational |
| `years` | no | nearest | Model years the specs apply to, `"2025-2026"` or `"2026"` |
| `url` | no | nearest | Product page, surfaced in the generated component's notes |
| `note` | no | nearest | User-facing text, see [User-facing text](#user-facing-text-description-and-note) |
| `specs` | no | merged per key | Typed facts, see [Specs](#specs) |
| `adjustments` | no | nearest | The spring adjustments, see [Adjustments](#adjustments--sparse-literal-lists) |
| `options` | no | nearest | The option axes, see [Options](#options) |

Any other key (`offset_mm`, `axle`, `source`, …) is freeform metadata for
humans and is ignored by the parser — **except** a registered spec key or
option axis id written directly on a node (`travel_mm: [150, 160]`), which is
rejected: it belongs under `specs` or `options`.

### Levels

`level` names are free per brand and name the picker stage. Use the same name
for the same step across one file:

| Level | Use for |
|---|---|
| `model` | The top-level product family (`36`, `Pike`, `RXF36`) |
| `generation` | A model-year generation of a model, see [Generations](#generations) |
| `version` | A manufacturer-named revision that users know by name (Öhlins `m.2` / `m.3`). An original that only got a successor badge later is `First generation` with `id: m1` |
| `trim` | The user-facing sub-model (`Factory`, `Ultimate`, `Air`, `Coil`). The default leaf level |
| `mount` | A shock that is sold as one product per mount (Cane Creek `Standard` / `Trunnion`). Only where the mount is all that tells the leaves apart |

Level names share one namespace with the option axis ids of their product and
with the two entries every persisted map has (`brand`, `component_type`). So do
not call a level `damper`, `travel_mm`, `wheel_size` or `size`, and do not
repeat a level name on one path; the parser rejects both.

### Inheritance

A node hands its fields down to its subtree, so a value is written once at the
highest node it holds for:

- `draft`, `category`, `years`, `url`, `note`, `adjustments` and `options` use
  the **nearest** declaration: a child that writes the field replaces the
  inherited value as a whole. `options` is replaced as one map, not per axis.
- `specs` are **merged per key**: a child adds to and overrides single keys.
- An explicit `~` clears an inherited text field (`note: ~`).

### Ids

Every node has an `id`, which is what a saved component stores as
`<level>: <id>`.

- It defaults to the slug of `label`: lowercase ASCII, hyphen-separated
  (`Performance Elite` → `performance-elite`, `Select+` → `select-plus`).
  Accented characters are spelled out (`Öhlins` → `ohlins`).
- Write an explicit `id:` only when the default does not fit: a label that was
  renamed after rollout, a label that would slug to something unwieldy
  (`"2025–2026"` → `id: "2025"`, `m.3` → `id: m3`), or a character the slug
  cannot transliterate (the parser then asks for an explicit id).
- Sibling ids must be unique; the parser rejects duplicates.
- A product's full path (`fork/fox/36/2025/factory`) must be unique across all
  brand files; CI checks this.

### Frozen ids

Ids are **persisted on every component a user creates from the catalog**, which
is what lets the app later offer setup guides and service intervals for that
exact product. Once the feature is rolled out to users, these are frozen:

- `level` names
- node `id`s (explicit or derived from the label)
- option axis ids (`damper`, `travel_mm`, …)
- option value ids (`grip_x2`, `160`, …)

Labels, names, descriptions and notes stay free to change. Renaming a `label`
whose id is derived from it therefore needs an explicit `id:` that keeps the old
slug. Extending `years: "2025-2026"` to `"2025-2027"` must leave a generation's
`id: "2025"` untouched.

Moving a node to another place in the tree changes its path. A component saved
against the old path then resolves only as far as the path still matches (the
resolver returns the deepest matching node), so restructure before rollout, not
after.

Until the feature flag is rolled out, ids may still change freely.

### Generations

Older generations are wanted — riders keep forks for a decade — but a
generation is only worth adding when its numbers can actually be sourced.

- **A model with more than one generation nests them as `generation` nodes.**
  The label is the year span with an en dash (`"2025–2026"`), the `id` is the
  generation's *first* year (`"2025"`), and `years` repeats the span in ASCII
  (`"2025-2026"`). A single-year generation needs no explicit id (`"2026"`).
- **A model with a single generation has no generation node.** Its `years` sit
  on the model node and the trims are its direct children. Adding a second
  generation later inserts the level, which changes the path of the existing
  trims — do it before rollout where an earlier generation is foreseeable.
- **A generation is left out of the component's name**: `FOX 36 Factory`, not
  `FOX 36 2025–2026 Factory`. Its years reach the user as a badge and a `Year:`
  line in the notes. A step that users know by name is a `version` instead.
- **Author newest generation first.** Children are shown in file order.
- **`category` sits on the model node**, the generation-level fields (`years`,
  `url`, `draft`, `note`) on the generation node.
- **Trims that are not generations of each other are siblings.** Where a model
  grew by trims launched in different years (Formula Selva V / R / C / S), keep
  them as direct children of the model and give each its own `years` and `url`.
- **Give each generation its own damper id** (`fit4_2018`, `grip2_vvc_2021`,
  `charger_2_1`, `ttx18_m2`) even when the cartridge kept its name — brands
  revise internals and click counts under an unchanged badge.
- **Don't inherit numbers across generations.** If the older damper's counts
  aren't published, see [Draft entries](#draft-entries).

## Specs

`specs` holds typed facts about a node. Every key must be registered in
`lib/models/component/preset_spec_keys.dart` with its value type, unit, label
and the component types it applies to; the parser rejects an unknown key or one
used on the wrong component type.

| Key | Type | Applies to | Example |
|---|---|---|---|
| `stanchion` | text | fork, shock | `Kashima`, `35mm` |
| `spring` | text | fork, shock | `Air`, `Coil`, `DebonAir+` (informational, does not drive adjustments) |
| `travel_mm` | number | fork | set by the `travel_mm` option |
| `wheel_size` | text | fork | set by the `wheel_size` option |
| `eye_to_eye_mm` | number | shock | set by the `size` option |
| `stroke_mm` | number | shock | set by the `size` option |
| `mount` | text | shock | `Standard`, `Trunnion`; on the product, or set by the `size` option |

```yaml
specs: { stanchion: "7000-series alloy, black anodized", spring: Air }
```

Quote a value that contains a comma inside the flow map. A fact with no
consumer in the app does not need a spec key — leave it as a freeform key.

`specs` are merged along the path, so a shock's `spring: Air` is written once on
the model node and a trim only repeats the key to name its spring variant
(`spring: DebonAir+`).

## Options

`options` lists, per axis, the values a product can be had with. Every axis id
must be registered next to the spec keys.

| Axis | Values | Applies to |
|---|---|---|
| `damper` | ids defined under `option_values.damper` | fork, shock |
| `travel_mm` | literal numbers, `[150, 160]` | fork |
| `wheel_size` | literal sizes, `[29, 27.5]`, `[700c, 650b]` | fork |
| `size` | eye-to-eye × stroke sizes, see [Shock sizes](#shock-sizes) | shock |

```yaml
options:
  damper: [grip_x2, grip_x]   # buyer-selectable damper
  travel_mm: [150, 160]
  wheel_size: [29, 27.5]
```

- **Always write a list**, also for a single value. An axis with one value is
  resolved automatically and never shown to the user.
- **An axis is required when any of its values carries `adjustments`** — today
  that is `damper`, because the adjustment list depends on the choice. This is
  derived, not authored. All other axes are optional and can be skipped by the
  user.
- **Leave an axis out when its values are not known**; an empty list is
  rejected.
- A literal value is its own id (`travel_mm: 160`), and a selected `travel_mm`
  becomes the SAG reference travel of the created fork.
- `options` is inherited as a whole. A product that writes `options` has to
  list every axis, so `wheel_size` is repeated on each trim rather than written
  once on the model.

### Shock sizes

A shock is sold by eye-to-eye × stroke length to match a frame, so its sizes
are one axis, `size`. Each value is one concrete size and carries up to three
specs: `stroke_mm` (always), `eye_to_eye_mm` and `mount`. The stroke of the
selected size becomes the SAG reference travel of the created shock.

```yaml
options:
  damper: [ttx1air_m2]
  size:
    - "210x50/52.5/55"                                  # three sizes, one eye-to-eye
    - 65                                                # stroke only
    - { size: "185x50/52.5/55", mount: Trunnion }       # the same, in a named mount
    - { size: "210x55", label: "210x55 (MTBM 2204)" }   # with a part number
    - { eye_to_eye_mm: 215.9, stroke_mm: 63.5, label: 8.5x2.5in }
```

| Form | Meaning |
|---|---|
| `"210x50/52.5/55"` | Shorthand: eye-to-eye, then every stroke that body is sold with. The parser expands it into one value per stroke |
| `65` | A stroke without an eye-to-eye, where the brand lists strokes only |
| `{ size: …, mount: … }` | The shorthand or a bare stroke, plus the mount of those sizes |
| `{ size: …, label: … }` | A single size with its own display text |
| `{ eye_to_eye_mm: …, stroke_mm: …, mount: …, label: … }` | The lengths spelled out; `eye_to_eye_mm`, `mount` and `label` are optional |

- **The id is `<eye-to-eye>x<stroke>`** (`210x55`), or the stroke alone (`65`).
  It is derived, never authored, and frozen like every option value id.
- **The mount joins the id only where it is needed** to tell two values of one
  product apart (`185x55-trunnion` next to `185x55-standard`).
- **Everything is in mm.** An imperial size is converted (× 25.4, not rounded
  to the nearest metric size) and keeps the manufacturer's inch figures as its
  `label`: `8.5x2.5in` is `215.9` × `63.5`. CI rejects a stroke of 20 or less
  as an unconverted inch figure.
- **`label` is for what belongs to the name of the size**: the inch figures, a
  part number. It needs a single size, so it cannot sit on a multi-stroke
  shorthand. Without it the value is shown as `210x55 mm`.
- **Where the mount goes** depends on what the manufacturer states:
  - every size of the product has the same mount → `specs: { mount: Trunnion }`
    on the product, plain sizes;
  - the mount is stated per size → `mount:` on those sizes;
  - several mounts are offered but not per size → the freeform key
    `mounts: [Standard, Trunnion]` on the product, plain sizes. Never guess the
    mount from the eye-to-eye length.
- **Leave `size` out when no sizes are published.** The user then enters the
  SAG travel by hand.

### Damper definition

```yaml
option_values:
  damper:
    grip_x2:
      name: GRIP X2               # display name
      description: ...            # short blurb, user-facing
      adjustments:                # each maps 1:1 to an Adjustment via fromYaml
        - { name: HSC, type: step, max: 8, notes: High-Speed Compression }
        - { name: LSC, type: step, max: 18, notes: Low-Speed Compression }
        - { name: HSR, type: step, max: 8, notes: High-Speed Rebound }
        - { name: LSR, type: step, max: 16, notes: Low-Speed Rebound }
      valves: 23                  # informational (freeform key)
```

```yaml
    charger_3_1:
      name: Charger 3.1
      adjustments:
        - { name: HSC, type: step, min: -2, max: 2, visualization: dial_cw, notes: High-Speed Compression }
        - { name: LSC, type: step, min: -7, max: 7, visualization: dial_cw, notes: Low-Speed Compression }
        - { name: Rebound, type: step, max: 18, notes: Counted from fully open (fastest) }
```

The map key (`grip_x2`) is the option value id and is frozen like a node id.
All keys other than `name`, `description`, `specs` and `adjustments` (e.g.
`valves`, `firm_mode`, `remote`, `source`, `note`) are freeform informational
metadata for humans; they are not consumed.

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

An on-the-fly compression lever is a categorical:

```yaml
    - { name: Compression Mode, type: categorical, options: [Open, Medium, Firm] }
```

## Draft entries

`draft: true` on a node hides it and its subtree from the picker. Only
non-draft products are selectable. A component that was saved against a node
keeps resolving after the node goes back to draft.

- Set it on the **narrowest node it applies to**: one generation, one trim.
- Use it when the adjuster list of a damper the product ships with is unknown
  (`adjustments: []`), or when a from-middle range is unknown.
- `draft` is a node property only. An option value cannot be draft.
- A child can opt out of an inherited draft with `draft: false`.

## Adjustments — sparse literal lists

Dampers and nodes carry an `adjustments:` list. Each entry is a **sparse** map
that maps 1:1 to one of the app's `Adjustment` subclasses via the strict
`Adjustment.fromYaml` factory (`lib/models/adjustment/adjustment.dart`).
"Sparse" means: write only what deviates from the defaults below. Any **unknown
key throws** at parse time — the CI catalog test doubles as a typo detector, so
misspelling `viz:` for `visualization:` fails CI rather than being ignored.

The node-level `adjustments:` list holds the **spring** adjustments (air
pressure, published volume-spacer count, coil spring-rate/preload). Add only
what is certain: every air spring has a Pressure; every coil has a Spring Rate.
Volume spacers are listed **only where the max is published** — otherwise omit
them and add a follow-up note rather than guessing a range.

### Fields & defaults

| Field | Applies to | Required? | Default |
|---|---|---|---|
| `name` | all | **yes** | — |
| `type` | all | **yes** | — (`step` \| `numerical` \| `categorical` \| `boolean`) |
| `notes` | all | no | none |
| `unit` | all | no | none (e.g. `psi`, `bar`, `lbs/in`, `mm`, `°`; blessed customs `clicks`, `%`, `turns`, `tokens`) |
| `min` | step, numerical | no | `0` (step), unbounded (numerical) |
| `max` | step, numerical | step: **yes** (a number or `~`) · numerical: no | step: — · numerical: unbounded |
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

An adjuster with "18 clicks" counted from fully closed is `type: step, max: 18`
(min defaults to 0). Where a brand counts **from the middle** (RockShox Charger
3.1/3.2: HSC `-2..+2`, LSC `-7..+7`), write the real `min`/`max` literally and
set `visualization: dial_cw`. Where the count runs **from fully open** (e.g.
rebound on many RockShox dampers), keep `min: 0` and record the direction in
`notes` so it reaches the user.

### Unknown click range (`max: ~`)

A step adjuster that is known to exist, but whose range the manufacturer does
not publish, is declared with an explicit null:

```yaml
- { name: Rebound, type: step, max: ~, dialColor: red }
```

- The app substitutes a placeholder maximum of **20** and appends a warning to
  that adjustment's notes ("Click count not published. Max is a placeholder,
  edit it to match your component."). The rider can edit the maximum at any
  time.
- **Never author a literal `max: 20` for an unknown range.** `~` is what keeps a
  placeholder distinguishable from a sourced number.
- Only for adjusters counted from 0 (`min` unset or `0`). A from-middle
  adjuster with an unknown range has no sensible placeholder: leave it out and
  keep the product `draft: true`.
- A missing `max` key is still an error.
- The adjuster's *existence* has to be sourced like any other fact.

### Combine order

At application time the app concatenates, in this order and preserving each
list's authored order (which is the on-screen order):

1. the product's `adjustments` (the spring: pressure, spacers, spring-rate …)
2. auto-injected **SAG** (injected for fork/shock only — it is universal and
   carries app-specific discipline guidance, so it never lives in brand data)
3. the chosen option values' `adjustments` (the damper: compression/rebound
   clicks, mode categoricals …)

Nothing generic is added that the data doesn't declare: no default
Lockout/Pressure/Spacers/0–20-click adjusters.

### Anchor reuse

Identical spring lists (e.g. every air trim repeating Pressure) can be written
once with a YAML anchor and reused with an alias — the `yaml` package resolves
these before the parser sees them:

```yaml
adjustments: &air_spring
  - { name: Pressure, type: numerical, unit: psi, min: 0 }
# … later …
adjustments: *air_spring
```

Anchors are sugar for **identical** lists only; YAML cannot extend an aliased
list. A trim that deviates in any way (extra chamber, published spacer count,
different max) simply writes its own literal list instead of the alias. An
anchor has to be defined above its first alias, so moving a node can require
moving the definition with it.

Where every trim of a model or generation shares one list, write `adjustments`
once on that node instead and let the trims inherit it.

## User-facing text: `description` and `note`

Two fields in this catalog are copied verbatim into the notes of the component
the user ends up with:

| Field | Where |
|---|---|
| damper `description` | rendered as `Damper: <name> — <description>` |
| node `note` | rendered on its own line |

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

Note the two different `note` keys: on a **node** it is user-facing; on a
**damper** it is a freeform key and never displayed. Everything meta stays in
`#` comments, in the damper's freeform `note:`/`source:` keys, or in the file's
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

## Optional fields / escape hatches

The formats above aren't rigid — small deviations are expected as brands don't
all publish specs the same way:

- **Per-node `url` override**: if a trim has its own product page (e.g. a
  "Coil" version sold separately from the "Air" version), give it its own
  `url:` instead of relying on the inherited one.
- **Per-node `years` override**: for the rare model where one trim ran
  different years than its siblings.
- **`adjustments: []`** on a damper: the adjuster list itself is unknown. Note
  it in the `description` and the file's Follow-ups footer, and keep the
  products that ship with it `draft: true`.
- **Freeform informational keys** (`valves`, `firm_mode`, `remote`, `lockout`,
  `offset_mm`, `axle`, `mounts`, `part_numbers`, …): add whatever extra key(s) best capture a
  distinguishing spec. They are for humans and future schema growth; promote
  one to a registered spec key when the app starts consuming it.
- **Same physical damper, different click counts across generations**: give
  each generation its own damper id (e.g. `ttx18_m2` vs `ttx18_m3`) rather
  than picking one number.

## CI

`test/component_catalog_test.dart` parses every file in this directory with the
parser the app uses and fails when a file does not parse, `component_type` does
not match its directory, an adjustment spec does not build, a shock size is not
in mm, a `url` is not http(s), or two files claim the same product path.
