# Component catalog — schema

Human-editable source of truth for factory component specs, so the app can offer
"pick your exact fork → auto-add the right adjustments" flows.

One directory per `component_type` (`fork/`, `shock/`, …), one YAML file per
brand inside it, e.g. `fork/fox.yaml`, `fork/ohlins.yaml`.

## The two concepts: nodes and options

A product is described by two things, and every new dimension goes into
exactly one of them:

- **Nodes say what the product is.** A tree per brand, as deep as that brand
  needs: `model › generation › trim` for FOX, `model › version › trim` for
  Öhlins, `model › generation › mount` for Cane Creek shocks. Every model that
  has model years has a generation (or version) level, even when only one
  generation exists. A node without `children` is a selectable **product**, at
  whatever level it sits: a model without years that is sold in one version
  only is itself the product.
- **Chassis variants are options, never nodes.** An e-bike chassis, a travel
  variant or a size is an option axis of the product, because moving a node
  changes the path every saved component stores.
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

A rider may also name the exact model year, persisted as `year: 2025`. The
picker offers it when the product's `years` cover more than one year. When a
later catalog update splits a generation, a component that stores a `year`
resolves to the generation whose `years` contain it; one without a `year` stays
on the generation it names.

The map also carries the brand file's `revision` the component is up to date
with, as `revision: 2`; it is left out at revision 1. See
[Catalog revisions](#catalog-revisions-revision-and-changes).

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
| `guides` | Map of guide id → structured setup guide, referenced from nodes by `guide:`, see [Setup guides](#setup-guides-guides) |
| `moved` | Map of old node path → new node path after a restructure, see [Moved paths](#moved-paths-moved) |
| `revision` | Whole number, the file's data revision; `1` when absent, see [Catalog revisions](#catalog-revisions-revision-and-changes) |
| `changes` | Append-only list of what each revision changed for existing components |
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

3. **Tertiary — retailer listings**, only for facts neither the manufacturer
   nor a magazine states: shock sizes (eye-to-eye × stroke, mount), travel
   options, wheel sizes and published click counts. Use the retailer's
   structured spec table or variant list, preferably from a well-known shop
   (Bike24, Bike-Components, Chain Reaction, Jenson, Canyon, ...). Never take a
   damper range from a shop's marketing text when a manufacturer page exists.

All tiers must be cited (see [Citing a source](#citing-a-source)); state the
tier in the damper's or node's `note:`/`source:` when it is not the
manufacturer. Never guess. When a click range is published nowhere, use the
estimate rule below, and when even that is impossible declare it with
`max: ~` (see [Unknown click range](#unknown-click-range-max-)).

### Estimating a click range from a setup table

Manufacturers often publish a setup table (air pressure / rider weight →
recommended clicks) but no total range. Such a table is evidence for the
**minimum** total: the recommended values are counted from the closed end stop,
so the dial has at least as many clicks as the largest value in the table.

- Set `max` to the **highest value that occurs in the table** for that adjuster
  (the top of the widest range, e.g. `16-18` → `18`). It is an estimate, the
  true total may be higher.
- Put the warning in the adjustment's rider-facing `notes`, after the circuit
  name: `"High-Speed Compression; estimated maximum, check your dial and edit it
  if it differs"`. Use this exact wording so it stays greppable.
- Say how the number came about in the damper's `source:`/`note:` (document,
  pressure span, counting direction). Never in `notes`.
- Only for adjusters counted from the closed end stop. A table that counts from
  open, from the middle or in turns is not usable; use `max: ~` / draft.
- A table that is absent, or lists only a lever position, gives no estimate:
  `max: ~`.

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
| `years` | no | nearest | Model years the specs apply to: `"2026"` or `"2021-2025"` (ASCII hyphen, ascending, quoted). The parser rejects every other format. Written on a generation or version node, never on a model |
| `url` | no | nearest | Product page, for data editors; not shown to the rider |
| `setup_guide` | no | nearest | Official rider setup or tuning guide (page or PDF), linked at the end of the generated component's notes |
| `guide` | no | nearest | Id of an entry under `guides`: the guide's numbers as data, see [Setup guides](#setup-guides-guides) |
| `note` | no | nearest | User-facing text, see [User-facing text](#user-facing-text-description-and-note) |
| `missing_adjustments` | no | nearest | Adjusters the product has but that cannot be declared, see [Missing adjusters](#missing-adjusters-missing_adjustments) |
| `specs` | no | merged per key | Typed facts, see [Specs](#specs) |
| `adjustments` | no | nearest | The spring adjustments, see [Adjustments](#adjustments--sparse-literal-lists) |
| `options` | no | nearest | The option axes, see [Options](#options) |
| `tasks` | no | per key | Manufacturer task intervals, see [Task intervals](#task-intervals-tasks) |

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
not call a level `damper`, `travel_mm`, `wheel_size`, `size`, `year` or
`revision` (the last two are reserved for the model year and the catalog
revision a component stores), and do not repeat a level name on one path; the
parser rejects both.

### Inheritance

A node hands its fields down to its subtree, so a value is written once at the
highest node it holds for:

- `draft`, `category`, `years`, `url`, `setup_guide`, `guide`, `note`,
  `missing_adjustments`, `adjustments` and `options` use
  the **nearest** declaration: a child that writes the field replaces the
  inherited value as a whole. `options` is replaced as one map, not per axis.
- `specs` are **merged per key**: a child adds to and overrides single keys.
- `tasks` are **merged per key** too, and `<key>: ~` removes an inherited
  entry.
- An explicit `~` clears an inherited text field (`note: ~`) or guide
  (`guide: ~`).

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
- adjuster ids (the `id:` of an adjustment, or the slug of its `name`), because
  every adjustment built from the catalog stores `<type>:<id>` as its
  `presetKey`; adding an adjuster is fine, renaming or dropping one is not
- brand-only task keys (`fork:air_spring_service`), which every task rule
  created from them stores, see [Task intervals](#task-intervals-tasks)

Labels, names, descriptions and notes stay free to change. Renaming a `label`
whose id is derived from it therefore needs an explicit `id:` that keeps the old
slug. Extending `years: "2025-2026"` to `"2025-2027"` must leave a generation's
`id: "2025"` untouched.

Moving a node to another place in the tree changes its path. Without a
`moved:` entry, a component saved against the old path resolves only as far as
the path still matches (the resolver returns the deepest matching node), so
restructure before rollout where you can, and record the move after it.

### Moved paths (`moved`)

`moved:` is the escape hatch for a restructure after rollout. It maps an old
node path to the new one, as `/`-joined node ids from the top-level node down:

```yaml
moved:
  36/factory: 36/2025/factory   # a generation level was inserted
  rxf36: ohlins-rxf36           # a whole model subtree was renamed
```

- Matching is by node id, in the order the component stored them, whatever the
  old level names were. The longest matching prefix wins and the rest of the
  path is kept.
- The old path must no longer exist, the new one must, and entries never chain.
  The parser rejects anything else.
- A redirect only rewrites how a stored component is read; the next save writes
  the new path.
- Never reuse a retired id for something else while a redirect names it.

`ids.lock` lists every node path, every option value
(`fork/fox/36/2025/factory#damper=grip_x2`), every adjuster id (per product:
`fork/fox/36/2025/factory#adjuster=pressure`; per option value, once per brand:
`fork/fox#damper=grip_x2#adjuster=hsc`) and every brand-only task key
(`fork/fox#task=fork:air_spring_service`). `test/component_catalog_ids_test.dart`
fails when a locked id disappears, unless a [`moved:`](#moved-paths-moved)
entry covers its node path; new ids are fine. After adding data,
regenerate the lockfile:

```
UPDATE_CATALOG_IDS=1 flutter test test/component_catalog_ids_test.dart
```

Until the feature flag is rolled out, ids may still change freely: regenerate
the lockfile after a deliberate rename. After rollout the lockfile is
append-only, and a failing test means an id must be restored.

### Generations

Older generations are wanted — riders keep forks for a decade — but a
generation is only worth adding when its numbers can actually be sourced.

- **Every model with model years nests them as `generation` nodes**, even a
  model with a single generation: inserting the level later would change the
  path of every existing trim. The label is the year span with an en dash
  (`"2025–2026"`), the `id` is the generation's *first* year (`"2025"`), and
  `years` repeats the span in ASCII (`"2025-2026"`). A single-year generation
  needs no explicit id (`"2026"`). The picker skips a level with a single
  child, so a model with one generation costs the rider no extra tap.
- **A step the brand's riders know by name is a `version` instead** (Öhlins
  `m.2` / `m.3`), with the same year rules.
- **A model without known years has no generation node** and stays a plain
  `model › trim` tree until its years are researched; it is listed as a
  follow-up, not exempt. Generation fields (`years`, `url`, `setup_guide`,
  `guide`, `note`) belong on the generation node, never on the model.
- **A generation is left out of the component's name**: `FOX 36 Factory`, not
  `FOX 36 2025–2026 Factory`. Its years reach the user as a badge and a `Year:`
  line in the notes. A step that users know by name is a `version` instead.
- **Author newest generation first.** Children are shown in file order, and CI
  fails when sibling generations or versions are not ordered newest first.
  YAML anchors must be defined before they are aliased, so when reordering
  move the shared anchor to the model's own fields (for `tasks`) or into the
  new first block.
- **`category` sits on the model node**, the generation-level fields (`years`,
  `url`, `draft`, `note`) on the generation node.
- **Trims that are not generations of each other are siblings.** Where a model
  grew by trims launched in different years (Formula Selva V / R / C / S), keep
  them as direct children of the model and give each its own `years` and `url`.
- **A generation starts where the owner's manuals change something the
  catalog encodes, not at every model year.** Compare the manuals of
  consecutive years: pressure and click tables, base tunes, damper ranges,
  pressure limits, spacer tables. Years that match on all of it share one
  generation, and `years` spans them (`"2021-2025"`); one changed number, a
  base tune included, starts a new one. The generation's `setup_guide` and
  `guide` are the **latest manual of its span**.
- **A trim that exists for only part of a generation's years carries its own
  `years`** (a 38 Rhythm that first appears in the 2023 manual of a 2021-2024
  generation: `years: "2023-2024"`). A model year with no manual has no source,
  so a generation never starts or ends on a year the manuals do not show.
- **Trims two generations have in common are written once**: anchor the trim
  (`- &fox_36_factory` before `label:`) in the first generation and alias it in
  the other (`- *fox_36_factory`). Only the generation's own `years`, `guide`
  and extra trims differ.
- **Give each generation its own damper id** (`fit4_2019`, `grip2_vvc_2021`,
  `charger_2_1`, `ttx18_m2`) even when the cartridge kept its name — brands
  revise internals and click counts under an unchanged badge.
- **Don't inherit numbers across generations.** If the older damper's counts
  aren't published, see [Draft entries](#draft-entries).

## Catalog revisions (`revision` and `changes`)

A component keeps the adjustments it was built with; later data does not
change them by itself. A brand file therefore records, per revision, what a
correction means for components built before it:

```yaml
revision: 3
changes:
  - revision: 2
    when: { damper: grip_x2_2021 }
    fix: { adjuster: lsc, field: notes, from: Low-Speed Compression, to: "Low-Speed Compression; 18 clicks" }
  - revision: 3
    when: { model: "36", generation: "2025" }
    review: Adds the bottom-out adjuster.
```

- **`fix`** changes one cosmetic field of one adjuster: `name`, `notes`,
  `visualization`, `dialColor` or `dialSize`. The app applies it on startup,
  without asking, to every matching adjustment whose field still holds what
  the catalog built from `from`; a field the rider edited is left alone.
  `from: ~` / `to: ~` stand for no notes. The last fix of an adjuster field
  must end at what the data builds now; the parser checks it.
- **`review`** is everything else: a new or removed adjuster, a range, a type,
  an option of a categorical. Its text is rider-facing (see
  [User-facing text](#user-facing-text-description-and-note)); the component page
  shows it as "Update available", and the rider merges the new adjusters in the
  merge sheet or dismisses the update.
- **`when:`** scopes the entry like a guide rule's `when:`: level names and
  option axes of this file, a value or a list of values. Without it the entry
  applies to every component of the file. It must match at least one product.
- **Append only.** Each entry's `revision` lies between 2 and the file's
  `revision`, entries never go back in revision, and the newest entry is the
  file's `revision`. Several entries may share one revision.
- A component stores the revision it is up to date with. Accepting or
  dismissing an update raises it to the file's revision; the startup fixes raise
  it as far as no pending review holds it back.

`adjusters.lock` holds every file's revision and a signature of the adjusters
a rider gets per product and choice of its required axes
(`fork/fox/36/2025/factory#damper=grip_x2 3f2a9c0d1e2b`).
`test/component_catalog_adjusters_test.dart` fails when a signature changed and
no change newer than the locked revision covers that product, and when the
lockfile is out of date. Any change to what an adjuster builds, a renamed
`notes` included, needs a `changes:` entry. Regenerate the lockfile with

```
UPDATE_CATALOG_ADJUSTERS=1 flutter test test/component_catalog_adjusters_test.dart
```

which refuses to while a change has no revision. Until the feature is rolled
out, `UPDATE_CATALOG_ADJUSTERS=reset` regenerates it unconditionally.

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
All keys other than `name`, `description`, `specs`, `adjustments`,
`missing_adjustments` and `tasks` (e.g.
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

- Set it on the **narrowest node it applies to**: one generation, one trim. A
  model or generation only carries it when every product below it is draft.
- Use it when a damper the product ships with has an adjuster that cannot be
  declared: the adjuster list is unknown (`adjustments: []`), a from-middle
  range is unknown, or the adjuster's type is not documented (a lever whose
  positions are not named, a dial that may not be click-indexed).
- A product whose only gaps are `max: ~` adjusters is not draft.
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
them and add a follow-up note rather than guessing a range. A size option cannot
carry its own adjustments, so where the maximum depends on the size (shocks) or
travel (forks), `max` is the highest value and `notes` lists the per-size
maxima: `Maximum depends on the size: metric 210x50/55 3, 230x57.5/60/65 4`.
Always write them as `{ name: Volume Spacers, type: step, max: N, visualization: stepper }`.

### Fields & defaults

| Field | Applies to | Required? | Default |
|---|---|---|---|
| `name` | all | **yes** | — |
| `id` | all | no | the slug of `name`, see [Adjuster ids](#adjuster-ids) |
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

### Adjuster ids

Every adjuster has an id. It is stamped onto the adjustment the rider gets as
`Adjustment.presetKey` (`<type>:<id>`, e.g. `fork:hsc`) and survives renames, so
setup guides can find "the HSC" of a component no matter what the rider calls it.

- It defaults to the slug of `name`: lowercase ASCII, **underscore**-separated
  (`HSC` → `hsc`, `Volume Spacers` → `volume_spacers`). That is the id space of
  the generic template keys (`fork:hsc`, `shock:volume_spacers`), so a
  component built by hand from templates resolves to the same ids.
- Write an explicit `id:` when the slug would mislead: the name is the
  manufacturer's, but the circuit is another one (a FOX GRIP `Rebound` that is
  technically the low-speed rebound is `id: lsr`), or the name has no usable
  slug (`"2-Step"`).
- Ids are unique within what a rider ends up with: the product's adjusters plus
  one value of each required axis. `sag` is reserved for the SAG adjuster the
  app adds to every fork and shock.
- Ids stay free to change until the lockfile rollout, like guide ids.

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
- The adjuster's *existence* has to be sourced like any other fact, and so has
  its being click-indexed and counted from an end stop: a click count in a
  setup table, a stated counting convention for the brand or damper. Where
  the source leaves that open, leave the adjuster out.
- The placeholder caps input at 20 until the rider edits it, also where a
  setup table already suggests a higher setting.

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

Anchors are sugar for **identical** lists (or whole trims, see
[Generations](#generations)) only; YAML cannot extend an aliased list. A trim
that deviates in any way (extra chamber, published spacer count, different
max) simply writes its own literal list instead of the alias. An
anchor has to be defined above its first alias, so moving a node can require
moving the definition with it.

Where every trim of a model or generation shares one list, write `adjustments`
once on that node instead and let the trims inherit it.

## Task intervals (`tasks`)

The app suggests ready-made task rules for a new component: generic templates
per component type (`lib/utils/task_presets.dart`), each with a role key such as
`fork:lower_leg_service`. A node or a damper can replace a generic template's
interval with the manufacturer's, or add a task that only this brand has.

```yaml
nodes:
  - label: "36"
    level: model
    tasks:
      fork:full_service:
        interval: { moving_time_h: 125 }
        fallback: { days: 365 }
        source: FOX 36 owner's manual
      fork:air_spring_service:                     # brand-only
        name: Air spring service
        interval: { moving_time_h: 125 }
        preselected: true
        source: FOX 36 owner's manual
```

| Field | Required? | Meaning |
|---|---|---|
| `interval` | **yes** | The service interval, as one `unit: value` entry (see below) |
| `fallback` | no | Time-based interval (`months`/`days`) used without Strava, only for a ride-based `interval`. Only write the manufacturer's own time interval. Without one, the override applies only with Strava: without Strava, the generic template applies unchanged, and a brand-only task is hidden |
| `source` | **yes** | Where the interval comes from: the document's name, its URL, or both |
| `name` | brand-only: **yes** | The task's name |
| `priority` | brand-only | `low`, `medium` (default), `high` or `critical` |
| `preselected` | brand-only | `true` checks the suggestion by default; defaults to `false` |

| Unit | Interval | Needs Strava |
|---|---|---|
| `distance_km` | distance ridden, in km | yes |
| `moving_time_h` | moving time, in hours | yes |
| `elapsed_time_h` | elapsed time, in hours | yes |
| `elevation_m` | elevation gain, in m | yes |
| `activities` | number of rides (whole number) | yes |
| `kj` | work, in kJ | yes |
| `months` | months of 30 days (whole number) | no |
| `days` | days (whole number) | no |

- **A key is `<type>:<snake_case>`**, where `<type>` is the one the generic
  keys of the file's component type use (`fork:`, `shock:`).
- **A generic key overrides its template**: only `interval`, `fallback` and
  `source` change. Name, notes, priority and preselection stay generic, so a
  generic key rejects `name`, `priority` and `preselected`.
- **Any other key is brand-only** and needs a `name`. It is frozen once rolled
  out, like a node id.
- **Inheritance is per key.** The nearest declaration wins, and a chosen
  damper's `tasks` override the product's. `<key>: ~` removes an inherited
  entry, so the generic template applies again (or the brand-only task is no
  longer offered). Write an interval at the highest node it holds for, usually
  the brand's model family.
- **Only the manufacturer's published interval counts**: an owner's manual or
  an official service page (tier 1 of the [Sourcing policy](#sourcing-policy)).
  A brand that publishes none gets no `tasks`, and the generic template applies.
  The same goes for a single service: when the manufacturer publishes only a
  full service, override `full_service` alone and leave the lower-leg or
  air-can template generic.
- **`source` reaches the rider**: under the suggestion and at the end of the
  created rule's notes ("Recommended interval: every 125 h — FOX 36 owner's
  manual"). Name the document; no research meta.

## Setup guides (`guides`)

A manufacturer's setup guide says "at this rider weight, run this pressure and
this many clicks". `guides` holds those numbers as data, so the app can show the
rider **recommended values** for their own component. Nothing in it is specific
to suspension: any component type with adjusters (an e-bike motor's assist
levels, a chain guide's settings) can carry a guide. The raw material for every
brand is collected in `docs/research/setup_guides/`; encoding a guide is
transcribing that file.

`setup_guide:` and `guide:` are two different things:

- `setup_guide:` is the **link** to the document. It ends up in the component
  notes, and stays the fallback for every product without structured data.
- `guide:` names an entry under `guides`, the document's **numbers**. A node
  can have the link without the data, which is the common case.

```yaml
guides:
  fox_38_2027:
    label: FOX 38 owner's manual (2027)
    source: https://tech.ridefox.com/bike/owners-manuals/3166/fork--2027-38mm
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: lb
        when: { trim: [factory, performance-elite] }
        rows: { 120-130: 54, 130-140: 58, 140-150: 62 }
      - { target: hsc, value: 5, when: { damper: grip_x2 } }
      - { target: sag, range: [15, 20], comfort_at: max }
nodes:
  - label: "38"
    level: model
    setup_guide: https://tech.ridefox.com/bike/owners-manuals/3166/fork--2027-38mm
    guide: fox_38_2027
```

- **One entry per document** (manual and year). The id is lower_snake_case,
  `<brand>_<product>_<year>` as in the research files. Several generations can
  share one guide, and a new manual year is a new entry.
- `label` names the document neutrally; the app shows it as the basis of a
  recommendation. `source` is its URL, shown next to it.
- `guide:` is inherited like `setup_guide`, and `guide: ~` clears it. Every
  entry must be referenced by at least one product.

### Rules

Each rule recommends one value for one adjuster, as one published column does.
Write one rule per column, so a review against the manual stays easy.

**Every rule must give a value the rider can apply.** Advice that can't be
applied ("Open while setting sag", "Firm for tarmac climbs") goes into a
`note`, or is left out.

| Field | Required? | Meaning |
|---|---|---|
| `target` | **yes** | The adjuster id, see [Adjuster ids](#adjuster-ids). `sag` is the injected SAG adjuster |
| `value` / `rows` / `range` | exactly one | A constant, a lookup table, or a band (below) |
| `input` | with `rows` | What the rows are keyed by (below) |
| `unit` | see [Units](#units) | The unit the values are written in |
| `input_unit` | see [Units](#units) | The unit numeric row keys are written in |
| `when` | no | The products and options the rule applies to (below) |
| `comfort_at` | no, `range` only | `min` or `max`: the end of the band a `comfort` rider gets |
| `note` | no | One short line for the rider, in our words |

Outputs:

- **`value`** is a constant cell, e.g. a base tune (`value: 5`).
- **`rows`** is a lookup table from input to cell.
- **`range: [min, max]`** is a numeric band such as SAG 15–20 %. Its midpoint
  is applied, and the full band counts as on guide. With `comfort_at`, the
  rider's riding style picks a point in it: `comfort` gets that end, `race` the
  other, `balanced` the midpoint. Which end is the comfortable one depends on
  the adjuster (more SAG is plusher, `comfort_at: max`), so the rule has to say.

### Cells

A cell is what `value` and each row hold. It must fit the target adjuster's
type; the parser checks this on every product the rule applies to.

| Cell | Example | Target | Applied as |
|---|---|---|---|
| number | `76`, `5` | step, numerical | the number, converted and rounded |
| band | `[85, 95]` | step, numerical | its midpoint; the band counts as on guide |
| range reference | `min`, `max`, `min+2`, `max-3`, `mid`, `mid-0.5` | step, numerical with a published range | resolved against the rider's adjuster range |
| band with range references | `[22, max]`, `[min, 3]` | step, numerical with a published range | as a band |
| option | `Open`, `"1× 10cc + 1× 5cc"` | categorical | that option; it must be one of the adjuster's `options` |
| boolean | `true`, `false` | boolean | that state |

- **Range references** point into the target adjuster's own range: `min`,
  `max`, `mid` (the middle), each with an optional offset in the rule's `unit`
  (`max-3`, `min+2`, `mid+0.5`). On a damper dial counted from closed, `min` is
  fully closed and `max` fully open. The app resolves them against the rider's
  adjustment, so a corrected `max` corrects the recommendation.
  - The referenced bound must be published: a numerical adjuster without a
    `max` cannot take `max` or `mid`.
  - While a `max: ~` adjuster still has its placeholder max, the app asks the
    rider for the real count instead of recommending.
  - `min-2` and `max+1` lie outside every range and are rejected.
- **Numbers and band ends must lie inside the adjuster's `min`/`max`**, after
  converting the cell's `unit` into the adjuster's. An adjuster with `max: ~`
  has no upper limit to check. SAG authored in mm is not checked.
- A band ascends: `[95, 85]`, `[max, 3]` and `[2, min]` are rejected.
- `min`, `max` and `mid` are lowercase keywords. Any other text is an option,
  so a categorical option that reads `max` would need another spelling.

### Inputs

| `input` | Row keys | Reads |
|---|---|---|
| `rider_weight` | brackets or points, in `input_unit` (`kg` or `lb`) | the rider's weight |
| `riding_style` | `comfort`, `balanced`, `race` | the rider's style |
| an option axis with numeric values (`travel_mm`) | brackets or points, in the spec's unit | the selected value |
| any other option axis (`wheel_size`, `size`, `damper`) | value ids of this file (`29`, `210x55`) | the selected value |
| a numeric spec key (`stroke_mm`) | brackets or points, in the spec's unit | the product's spec, merged with the selected options' specs |
| any adjuster id | brackets or points, in `input_unit` where the adjuster has a unit | the adjuster's current value |

Option axes and spec keys are the ones registered in
`lib/models/component/preset_spec_keys.dart` for the file's component type, so
a new axis or spec becomes a guide input without schema changes. Text specs
(`stanchion`) are not inputs.

An adjuster id as `input` reads that adjuster's current value: rebound keyed by
air pressure (`input: pressure`), clicks keyed by spring rate (`input:
spring_rate`). Every product the rule applies to must have that adjuster. The
app evaluates the rule after the rules that target its input, so a cycle
(`pressure` keyed by `rebound` keyed by `pressure`) is rejected.

Row keys of a numeric input:

| Key | Meaning |
|---|---|
| `120-130` | A bracket from 120 up to, but not including, 130 |
| `<120` | Everything below 120 (only at the lower edge) |
| `250+` | 250 and above (only at the upper edge) |
| `160` | A single point |

- Brackets must be **contiguous**: no gap, no overlap. Write the bounds exactly
  as published, even where the manual prints `120-129`, `130-139`: then they
  are `120-130`, `130-140`.
- Don't mix brackets and points in one rule. An open-ended row continues the
  table at its edge (`<120` next to `120-130`, or next to the point `120`).
- A cell that is itself an inequality becomes a band to a limit (see
  [Authoring rules](#authoring-rules)).

How the app reads a table (for reviewing a rule, not for authoring): between two
rows it interpolates linearly, bracket midpoints being the points. Inside the
outermost brackets the bracket value applies, and an open-ended row applies its
value beyond the edge. Outside the table there is no recommendation; the app
never extrapolates. `spring_rate` and `volume_spacers` never interpolate: a value
between two springs or spacer counts doesn't exist.

### `when`

`when` restricts a rule to some products or options of the products the guide
is attached to. Keys are the file's level names (`model`, `trim`), its option
axes (`damper`, `travel_mm`, `wheel_size`, `size`) and `riding_style`. Values
are ids of the same file, one or a list:

```yaml
when: { trim: [factory, performance-elite], damper: grip_x2, travel_mm: 170 }
```

- Without `when` the rule applies to every product the guide is attached to.
- A rule must match at least one product the guide is attached to, and its
  `target` must exist on one of them.
- An option the rider skipped never matches a rule that names it.
- **The most specific rule wins**: the one with more `when` keys. Two rules for
  the same target with the same number of keys that can both match are an
  error. A general `{ target: sag, range: [15, 20] }` next to a
  `{ target: sag, value: 15, when: { riding_style: race } }` is fine.

### Units

- A target with a convertible unit (pressure, spring rate) needs `unit` of the
  same quantity: `psi` or `bar` for a pressure, `lbs/in` or `N/mm` for a spring
  rate. Write the unit of the source; the app converts.
- A target without one (clicks, spacer counts) takes no convertible unit.
  `unit: clicks` is allowed but optional.
- `sag` is in `%` (the default) or a length (`mm`).
- `input_unit` follows the same rule for an adjuster input. `rider_weight`
  always needs one (`kg` or `lb`); the other inputs take none.

### Authoring rules

- **Facts only.** Re-type the numbers, never copy manual prose, images or
  PDFs. `note` is in our own words and reaches the rider: what the value
  means, not where it comes from.
- **Counting direction.** Numbers are written in the catalog adjuster's
  direction, counted up from its `min` (for a damper dial: from closed). A
  source that counts from the other end is written with range references:
  "5 clicks from open" is `max-5`, never a precomputed number.
- **End-of-range cells** keep the source's meaning: `Closed` → `min`, `Open` →
  `max`, `22-Open` → `[22, max]`, "middle of the range" → `mid`.
- **Inequality cells** (`<71`, `>20`, `215 or more`) become a band to the end
  of the range: `>20` → `[20, max]`, `<71` → `[min, 71]`. That needs the
  bound to be published (a Lefty's 50 psi minimum); where it isn't, leave the
  row out, so that rider is outside the table.
  - Leave the row out as well where the value keeps growing with the input,
    such as a pressure decal's `110+` edge cell: `[110, max]` would apply its
    midpoint, far above where the table is heading. Say so in a YAML comment.
- **The catalog adjuster's type follows the guide**, decided per brand or
  model by what the manufacturer publishes:
  - spacers of one size: a step count (`2`);
  - spacer configurations of mixed sizes (FOX 38 2027: 10 cc + 5 cc) or by
    part number: categorical, with the published configurations as options
    (`"1× 10cc + 1× 5cc"`);
  - named dial positions (`1 / 2 / P`, clock face): categorical;
  - a lever or lockout: its categorical or boolean adjuster.
- **Formulas** ("pressure = rider weight in lb"): write rows calculated at
  5 kg steps across the source's stated rider range (or 50–120 kg when none is
  stated), with `note: Calculated from the manufacturer's formula`. A linear
  formula is reproduced exactly by interpolation, and a percentage band
  becomes `[min, max]` cells.
- **Riding styles.** A guide that publishes values per style gets one rule per
  style with `when: { riding_style: … }`. Map the brand's wording:

  | Brand wording | `riding_style` |
  |---|---|
  | Plush, Soft, Comfort | `comfort` |
  | Balanced, Medium, Standard | `balanced` |
  | Firm, Stiff, Aggressive, Race | `race` |
  | Discipline names (XC, Trail, Enduro, DH) | none: they say what is ridden, not how firm. No rule; a `note` at most |

  Say in `note` which brand term a rule stands for ("Firm").
- **E-bike columns** (E-Bike+, E-Optimized) are not encoded while the catalog
  has no e-bike option for the product. Relative offsets (e-bike +10 psi) are
  a `note` or left out.
- **Fix the catalog first.** A cell outside the adjuster's range is rejected,
  so apply the catalog fixes the brand's research file lists (maxima below the
  table, missing adjusters, adjuster types, damper ids) before its guide.
- **Skip conflicting sources.** A guide the research file lists under "don't
  encode until resolved" stays out until the conflict is settled.

## User-facing text: `description` and `note`

Three kinds of text in this catalog reach the rider:

| Field | Where |
|---|---|
| damper `description` | under the damper in the picker, to choose between dampers |
| node `note` | in the generated component notes: a dash list keeps its lines, prose becomes one bullet |
| adjustment `notes` | next to the adjustment on every setup; keep it to one short line |
| guide rule `note` | next to the recommended value; one short line |

The generated component notes are a short dash list the app builds from the
selection: the chosen options, the spring and stanchion, the model years, the
node `note`, the missing adjusters, then the `setup_guide` link. Skipped
options, the damper `description` and the product page are left out.

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

### Missing adjusters (`missing_adjustments`)

When an adjuster exists but cannot be declared (see [Draft entries](#draft-entries)),
name it in `missing_adjustments` on the damper, or on the node when the product
has no damper axis. The app tells the rider to add it by hand, in the picker and
in the component notes. Never write that heads-up as prose. Name only the
adjusters that could not be declared; one declared with `max: ~` already
carries its own warning:

```yaml
    charger_race_day:
      name: Charger Race Day
      description: Lightweight XC damper for marathon racing.
      missing_adjustments: [Compression lever]
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
parser the app uses and fails when a file does not parse, a model carries
`years` instead of a generation or version, sibling generations are not newest
first, `component_type` does
not match its directory, an adjustment spec does not build, a shock size is not
in mm, a `url` is not http(s), two files claim the same product path, or a
non-draft product offers a damper with `adjustments: []`, an adjustment counts
`clicks` without being a `step`, or rider-facing text contains research wording
(links, sources, reviews, "confirmed", "not published", "add … yourself").

A task interval is rejected for an unknown unit, a value that is not positive
(or not whole for `activities`, `months` and `days`), a key that is not
`<type>:<snake_case>`, a brand-only key without `name`, a generic key with
`name`/`priority`/`preselected`, a missing `source`, or a `fallback` that is
ride-based or sits on a time-based interval.

A setup guide is rejected for an unknown key, a missing `label` or `source`, a
guide no product references, or a `guide:` naming an undefined entry. A rule is
rejected for a gap or an overlap between brackets, an open-ended row that is not
at an edge, an unknown target, input or `when` id, a unit of the wrong quantity,
a cell the target adjuster cannot take (an option on a step adjuster, an option
that is not offered, a range reference to an unpublished bound), a number or
range reference outside the adjuster's range, a `comfort_at` other than `min` or
`max`,
two rules that can both match with equal specificity, an adjuster input that
an applicable product lacks, or a cycle between adjuster inputs. Guide sources
must be http(s), and rule notes follow the rider-facing text rules.

A `changes:` entry is rejected for an unknown key, a `revision` outside 2 and
the file's revision or older than the entry before it, a file `revision` the
newest entry does not reach, a `when:` that names an unknown id or matches no
product, not exactly one of `fix` and `review`, a `fix` of another field or of
an adjuster no matching product has, `from` equal to `to`, a value the adjuster
cannot take, a last fix that does not end at what the data builds, or a `step`
that is not registered.
`test/component_catalog_adjusters_test.dart` guards `adjusters.lock`, see
[Catalog revisions](#catalog-revisions-revision-and-changes).
