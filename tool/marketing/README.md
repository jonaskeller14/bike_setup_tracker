# Marketing tooling

Scripts for the marketing plan in [#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69).
Working docs live in [`docs/marketing/`](../../docs/marketing/README.md).

## Requirements

- Python 3 (standard library only).
- Google Chrome. On other paths, set `CHROME` to the binary.
- Network access: the templates load Google Fonts.

## `render_images.py`

Renders HTML templates to PNG with headless Chrome, then checks size and that there's no alpha
channel. Works on Windows and macOS.

```
python tool/marketing/render_images.py                      # all assets
python tool/marketing/render_images.py appstore-search      # one asset
```

| Asset | Template | Output |
|---|---|---|
| `appstore-search` | `assets/store/app-store/creative/search_3x2.html` | `search_{en-US,de-DE}.png` next to the template, 3840×2560 |
| `appstore-header` | `assets/store/app-store/creative/header_21x9.html` | `header_{en-US,de-DE}.png` next to the template, 3840×1646 |

New template: add an entry to `ASSETS` (template, size, output file → URL query).
