"""Renders the store screenshots from docs/store/screenshots.html (#77 Phase 12).

Usage: python tool/marketing/render_images.py store-screenshots [device ...] [screens] [options]

  device    iphone, ipad, phone (Play phone), tablet (Play 10" tablet); default all
  screens   screen numbers, e.g. 4 or 3,7; default all captions of the locale
  --out D   write under D (laid out like docs/store/) instead of docs/store/, e.g. for a dry run
  --captions-dir D   captions files, one <locale>.md each; default docs/store/captions
  --safe    also write the safe-area overlays to build/marketing/safe/

One file per screen, device and locale, into the paths the uploads read (tool/store/ios.sh
screenshots, the Play `screenshots` lane). The locales are the captions files present. A locale's
raws are read from <raw folder>/<locale>/0N_raw.png when that exists, else <raw folder>/0N_raw.png.
Also writes the review page build/marketing/store-screenshots/sheet.html: every render, with the
export from before the first render next to it. Exits 1 if a caption doesn't fit or text leaves
the safe area; a caption that had to shrink only prints a WARN (rewrite it, so a set keeps one size).
"""

import html
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlencode

import render_images

REPO_ROOT = render_images.REPO_ROOT
STORE = REPO_ROOT / "docs/store"
TEMPLATE = "docs/store/screenshots.html"
SHEET_DIR = REPO_ROOT / "build/marketing/store-screenshots"

# key: (template device, raw folder, export size, export path under docs/store/ with {locale} and {n})
DEVICES = {
    "iphone": ("iphone", "app-store/iPhone-17-Pro-Max", (1206, 2622), "app-store/screenshots/{locale}/iphone_{n}.png"),
    "ipad": ("ipad", "app-store/iPad-Pro-13-inch_M5", (2064, 2752), "app-store/screenshots/{locale}/ipad_{n}.png"),
    "phone": ("android", "play-store/phone", (1080, 1920), "play-store/metadata/{locale}/images/phoneScreenshots/{n}.png"),
    "tablet": ("android-tablet", "play-store/tablet_10-inch", (1800, 2650), "play-store/metadata/{locale}/images/tenInchScreenshots/{n}.png"),
}


def captions(path):
    """{"01": (label, caption)} from the table in a captions file."""
    rows = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\|\s*(\d\d)\s*\|([^|]*)\|([^|]*)\|\s*$", line)
        if match:
            rows[match[1]] = (match[2].strip(), match[3].strip())
    return rows


def safe_area(size):
    margin = round(72 * size[0] / 1080)
    return (margin, margin, size[0] - 2 * margin, size[1] - 2 * margin)


def raw_path(folder, locale, n):
    localized = STORE / folder / locale / f"{n}_raw.png"
    return localized if localized.is_file() else STORE / folder / f"{n}_raw.png"


def export_path(root, key, locale, n):
    return root / DEVICES[key][3].format(locale=locale, n=n)


def render_set(chrome, key, locale, rows, root, safe):
    """Renders one device set of a locale; returns (problems, [(n, label, caption, file)])."""
    device, folder, size, _ = DEVICES[key]
    outputs, done = {}, []
    for n, (label, caption) in rows.items():
        out = export_path(root, key, locale, n)
        out.parent.mkdir(parents=True, exist_ok=True)
        query = urlencode({
            "device": device,
            "lang": locale[:2],
            "label": label,
            "caption": caption,
            "shots": raw_path(folder, locale, n).relative_to(REPO_ROOT).as_posix(),
        })
        outputs[str(out)] = "?" + query
        done.append((n, label, caption, out))
    problems = render_images.render(chrome, TEMPLATE, size, outputs, safe=safe, safe_area={"safe": safe_area(size)},
                                    safe_prefix=f"{key}_{locale}_", warn=True, exact=True)
    return problems, done


def snapshot_before(root, keys, locales):
    """Copies the current exports to build/…/before/ once, so the review page can show them as the old ones."""
    for key in keys:
        for locale in locales:
            pattern = export_path(root, key, locale, "[0-9][0-9]")
            for old in pattern.parent.glob(pattern.name):
                target = SHEET_DIR / "before" / old.relative_to(root)
                if not target.exists():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(old.read_bytes())


def write_sheet(root, results):
    """results: {(key, locale): [(n, label, caption, file)]}."""
    def src(path):
        return html.escape(Path(os.path.relpath(path, SHEET_DIR)).as_posix())

    sections = []
    for (key, locale), items in results.items():
        cells = []
        for n, label, caption, out in items:
            old = SHEET_DIR / "before" / out.relative_to(root)
            old_img = f'<img src="{src(old)}" alt="">' if old.is_file() else '<div class="none">no old export</div>'
            cells.append(f'<figure><div class="pair"><div><span>old</span>{old_img}</div>'
                         f'<div><span>new</span><a href="{src(out)}"><img src="{src(out)}" alt=""></a></div></div>'
                         f'<figcaption>{n} · {html.escape(label)} · {html.escape(caption)}</figcaption></figure>')
        sections.append(f"<h2>{key} · {locale}</h2><div class=grid>{''.join(cells)}</div>")
    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Store screenshots</title>
<style>
  body {{ font: 14px system-ui, sans-serif; margin: 24px; background: var(--bg, #fff); color: var(--fg, #111); }}
  body.dark {{ --bg: #111; --fg: #eee; }}
  .bar {{ position: sticky; top: 0; padding: 8px 0; background: var(--bg, #fff); display: flex; gap: 16px; align-items: center; }}
  .grid {{ display: flex; flex-wrap: wrap; gap: 24px; }}
  .pair {{ display: flex; gap: 8px; }}
  .pair span {{ display: block; font-size: 11px; text-transform: uppercase; color: #888; }}
  img {{ display: block; height: var(--h, 640px); width: auto; outline: 1px solid #8884; }}
  .none {{ height: var(--h, 640px); width: 120px; display: grid; place-items: center; color: #888; outline: 1px dashed #8884; }}
  figcaption {{ max-width: 600px; margin-top: 4px; }}
</style></head><body>
<div class="bar"><b>Store screenshots</b>
<label><input type="checkbox" onchange="document.body.classList.toggle('dark', this.checked)"> dark surround</label>
<label>image height <select onchange="document.body.style.setProperty('--h', this.value)">
<option>640px</option><option>320px</option><option>1000px</option><option>2000px</option></select></label>
<span>click a new image to open the file</span></div>
{''.join(sections)}
</body></html>"""
    SHEET_DIR.mkdir(parents=True, exist_ok=True)
    (SHEET_DIR / "sheet.html").write_text(page, encoding="utf-8")


def main(argv):
    keys, screens, root, captions_dir, safe = [], [], STORE, STORE / "captions", False
    args = iter(argv)
    for arg in args:
        if arg == "--out":
            root = (REPO_ROOT / next(args)).resolve()
        elif arg == "--captions-dir":
            captions_dir = (REPO_ROOT / next(args)).resolve()
        elif arg == "--safe":
            safe = True
        elif arg in DEVICES:
            keys.append(arg)
        elif re.fullmatch(r"\d+(,\d+)*", arg):
            screens += [f"{int(n):02d}" for n in arg.split(",")]
        else:
            print(f"Unknown argument: {arg}. Devices: {', '.join(DEVICES)}")
            return 2
    keys = keys or list(DEVICES)

    chrome = render_images.find_chrome()
    if chrome is None:
        print("Chrome not found. Install Google Chrome or set CHROME to its binary.")
        return 1
    files = sorted(captions_dir.glob("*.md"))
    if not files:
        print(f"No captions files in {captions_dir}")
        return 1

    locales = [file.stem for file in files]
    snapshot_before(STORE, keys, locales)
    problems, results = [], {}
    for file in files:
        rows = captions(file)
        if screens:
            rows = {n: row for n, row in rows.items() if n in screens}
        if not rows:
            print(f"No matching captions in {file}")
            return 1
        for key in keys:
            found, done = render_set(chrome, key, file.stem, rows, root, safe)
            problems += found
            results[(key, file.stem)] = done
    write_sheet(root, results)
    print(f"Review page: {SHEET_DIR / 'sheet.html'}")
    for problem in problems:
        print(f"FAIL {problem}")
    return 1 if problems else 0
