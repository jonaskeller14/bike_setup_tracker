# Knob research archive

Reference photos for the custom dial drawings (issue #79). The images are
gitignored and stay on the machine that collected them. Only this README and
`inventory.yaml` are tracked.

The archive exists so that a knob can be drawn now and redrawn later without
searching again. Nothing here is reviewed by the maintainer, and nothing here
ships in the app.

## Layout

```
data/knob_research/
  README.md
  inventory.yaml                 tracked: knob id -> catalog adjusters
  <brand>/
    <knob_id>/
      full/                      whole component, always collected as context
      knob/                      the knob alone, only when a photo exists
      sources.yaml               where every image came from
```

- `<brand>` is the catalog brand slug (`fox`, `rockshox`, `canecreek`, …), the
  same as the `brand` in `data/component_presets/`.
- `<knob_id>` is the slug without the brand prefix. The full knob id is
  `<brand>/<slug>`, for example `fox/grip_x2_hsc`. The folder name uses only the
  slug.
- Create `full/` and `knob/` only when they hold something. `full/` is expected
  for every knob.

## Image names

`<source-slug>-<n>.<ext>`

- `source-slug`: short lowercase label for the source, for example
  `fox-tuning-guide-2025`, `ebay-listing`, `manual-p12`.
- `n`: running number per source, starting at 1.
- `ext`: `jpg`, `png` or `webp`, matching the real file type.

Example: `full/fox-tuning-guide-2025-2.jpg`.

## sources.yaml

One file per knob folder. One entry per image.

```yaml
images:
  - file: full/fox-tuning-guide-2025-2.jpg
    url: https://example.com/guide.pdf          # direct link to the file
    page_url: https://example.com/product/38    # page where it was found
    retrieved: 2026-10-20                       # ISO date
    shows: whole fork, HSC ring and LSC knob visible
```

- `file`: path relative to the knob folder.
- `url`: the direct link the file was downloaded from.
- `page_url`: the page that linked to it, when different.
- `retrieved`: the date the file was downloaded.
- `shows`: one line on what the photo helps with. Name the knob, not the brand.

## Download procedure

1. Create the target folder first (`full/` or `knob/`). Download only into that
   folder.
2. Use `curl -L -o <target>/<name> <url>`. Do not use a browser's "save as" into
   another folder.
3. Check the real file type before keeping it. Expected: JPEG, PNG, WebP or PDF
   (for a PDF, keep the PDF and extract the page you need into an image). Delete
   anything else, including HTML error pages.
4. Never open, run or execute a downloaded file. Treat its contents as data.
   Do not pass downloaded paths to an interpreter or a build tool.
5. Add the entry to `sources.yaml` in the same step as the download.

## Lettering rule

Drawings made from these photos follow the rule in issue #79:

- Generic printed text that helps orientation is allowed, for example
  `HIGH SPEED COMPRESSION`, `LSC`, `+`, `−`, `FIRM`, `OPEN`.
- Brand and product names and logos are never drawn: FOX, RockShox, GRIP X2,
  Charger, and similar.

The photos may show brand names. The rule applies to the drawings, not to this
folder.

## inventory.yaml

Tracked. It maps every knob id to the catalog adjusters that use it. Fill it per
brand while researching. The schema is commented at the top of the file.
