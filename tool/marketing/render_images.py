"""Renders the HTML image templates to PNG with headless Chrome (Windows and macOS).

Usage: python tool/marketing/render_images.py [--safe] [asset ...]

Assets are keys of ASSETS (e.g. appstore-search); default is all. --safe also writes each output
with its safe-area overlay to build/marketing/safe/. Set CHROME to the browser binary if it isn't
found automatically. Templates load Google Fonts, so rendering needs network access.
Exits 1 if Chrome fails, an output has an unexpected size or format, or text sits outside the
format's safe area (SAFE_AREAS, checked by template.js).
"""

import html
import json
import os
import platform
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SAFE_OUT = REPO_ROOT / "build/marketing/safe"

# Safe areas per format (brand.md, Grid and safe areas), all (x, y, width, height). Text must sit
# inside "safe" and outside every "avoid" area (what a platform covers); "guides" are only drawn.
# template.js draws them with ?safe= and checks the text with &check.
SAFE_AREAS = {
    # Search results asset: the headline may reach past Apple's art safe area (a guide here).
    (3840, 2560): {"safe": (160, 140, 3520, 2280), "guides": [(836, 765, 2168, 1030)]},
    # App Store header: Apple's art safe area; only the rules run full width.
    (3840, 1646): {"safe": (1097, 493, 1646, 661)},
    # Play feature graphic: 120 px side margins, central 784×400.
    (1024, 500): {"safe": (120, 50, 784, 400)},
    # Shorts, Reels, TikTok: below the top bar, above the caption block, left of the action buttons.
    (1080, 1920): {"safe": (60, 220, 960, 1180), "avoid": [(920, 760, 160, 640)]},
    (1080, 1350): {"safe": (72, 72, 936, 1206)},
    (1080, 1080): {"safe": (72, 72, 936, 936)},
    (1920, 1080): {"safe": (96, 64, 1728, 952)},
    # YouTube thumbnail: the duration badge covers the bottom-right corner.
    (1280, 720): {"safe": (64, 56, 1152, 608), "avoid": [(1060, 640, 220, 80)]},
    (1200, 630): {"safe": (48, 40, 1104, 550)},
    (1920, 640): {"safe": (64, 48, 1792, 544)},
    # YouTube channel banner: the part every device shows.
    (2560, 1440): {"safe": (507, 508, 1546, 424)},
    # Avatars are cropped to a circle.
    (800, 800): {"safe": (117, 117, 566, 566)},
}

# name: (template, (width, height), {output file name: URL query})
ASSETS = {
    "appstore-search": (
        "docs/store/app-store/creative/search_3x2.html",
        (3840, 2560),
        {"search_en-US.png": "?lang=en", "search_de-DE.png": "?lang=de"},
    ),
    "appstore-header": (
        "docs/store/app-store/creative/header_21x9.html",
        (3840, 1646),
        {"header_en-US.png": "?lang=en", "header_de-DE.png": "?lang=de"},
    ),
    # The device frame for Android recordings and raws; transparent outside the phone.
    "android-frame": (
        "tool/marketing/assets/frames/android.svg",
        (1184, 2504),
        {"android.png": ""},
        {"alpha": True},
    ),
    "play-feature": (
        "docs/store/play-store/feature_graphic.html",
        (1024, 500),
        {
            "metadata/en-US/images/featureGraphic.png": "?lang=en",
            "metadata/de-DE/images/featureGraphic.png": "?lang=de",
        },
    ),
}

CHROME_CANDIDATES = {
    "Windows": [
        Path(os.environ.get("PROGRAMFILES", r"C:\Program Files")) / "Google/Chrome/Application/chrome.exe",
        Path(os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)")) / "Google/Chrome/Application/chrome.exe",
        Path(os.environ.get("LOCALAPPDATA", "")) / "Google/Chrome/Application/chrome.exe",
    ],
    "Darwin": [
        Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
        Path.home() / "Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        Path("/Applications/Chromium.app/Contents/MacOS/Chromium"),
    ],
}


def find_chrome():
    if os.environ.get("CHROME"):
        return Path(os.environ["CHROME"])
    for candidate in CHROME_CANDIDATES.get(platform.system(), []):
        if candidate.is_file():
            return candidate
    for name in ("google-chrome", "chromium", "chrome"):
        found = shutil.which(name)
        if found:
            return Path(found)
    return None


def png_info(path):
    """Returns (width, height, color type); color type 2 is RGB without alpha."""
    with path.open("rb") as f:
        header = f.read(26)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("not a PNG")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[25]


def safe_query(size):
    """The ?safe= parameters of a format, or "" if it has no safe area."""
    area = SAFE_AREAS.get(tuple(size))
    if not area:
        return ""
    parts = {"safe": [area["safe"]], "avoid": area.get("avoid", []), "guides": area.get("guides", [])}
    return "&".join(f"{key}=" + ";".join(",".join(map(str, r)) for r in rects)
                    for key, rects in parts.items() if rects)


def with_query(query, extra):
    return f"{query}&{extra}" if query.startswith("?") else f"?{extra}"


def page_url(template, size, query=""):
    """file:// URL of a template; pages that load template.js also get their size (see there)."""
    page = (REPO_ROOT / template).resolve()
    if "template.js" in page.read_text(encoding="utf-8"):
        query = with_query(query, f"size={size[0]}x{size[1]}")
    return page.as_uri() + query


def chrome_args(chrome, size):
    return [str(chrome), "--headless", "--hide-scrollbars", "--force-device-scale-factor=1",
            f"--window-size={size[0]},{size[1]}",
            # Gives the web fonts time to load before the screenshot.
            "--virtual-time-budget=5000"]


def screenshot(chrome, size, url, out, alpha=False):
    out.unlink(missing_ok=True)
    extra = ["--default-background-color=00000000"] if alpha else []
    # Chrome occasionally hangs (e.g. on a stalled font request); one retry is enough.
    for _ in range(2):
        try:
            subprocess.run([*chrome_args(chrome, size), *extra, f"--screenshot={out}", url],
                           capture_output=True, timeout=120)
            return
        except subprocess.TimeoutExpired:
            out.unlink(missing_ok=True)


def page_problems(chrome, size, url):
    """Problems template.js reports with &check: text outside the safe area, text that doesn't fit."""
    dom = ""
    for _ in range(2):
        try:
            dom = subprocess.run([*chrome_args(chrome, size), "--dump-dom", url],
                                 capture_output=True, text=True, timeout=60).stdout
            break
        except subprocess.TimeoutExpired:
            pass
    match = re.search(r'data-problems="([^"]*)"', dom)
    if not match:
        return ["the page set no data-problems; does it load template.js?"]
    return json.loads(html.unescape(match.group(1)))


def render(chrome, template, size, outputs, alpha=False, safe=False):
    """Renders each output (file name relative to the template, or an absolute path: URL query).

    Templates that load template.js are checked against their format's safe area. safe also writes
    each output with the overlay to build/marketing/safe/.
    """
    page = (REPO_ROOT / template).resolve()
    uses_template_js = "template.js" in page.read_text(encoding="utf-8")

    def url(query):
        return page_url(template, size, query)

    overlay = safe_query(size)
    problems = []
    for file_name, query in outputs.items():
        out = page.parent / file_name
        rel = out.relative_to(REPO_ROOT).as_posix()
        screenshot(chrome, size, url(query), out, alpha)
        if not out.is_file():
            problems.append(f"{rel}: Chrome wrote no file")
            continue
        width, height, color_type = png_info(out)
        if (width, height) != tuple(size):
            problems.append(f"{rel}: {width}x{height}, expected {size[0]}x{size[1]}")
            continue
        if color_type != (6 if alpha else 2):
            problems.append(f"{rel}: " + ("no alpha channel" if alpha else "has an alpha channel, the stores need RGB"))
            continue
        if uses_template_js:
            check = with_query(query, f"{overlay}&check" if overlay else "check")
            found = page_problems(chrome, size, url(check))
            problems += [f"{rel}: {problem}" for problem in found]
            if found:
                continue
        if safe and overlay:
            SAFE_OUT.mkdir(parents=True, exist_ok=True)
            screenshot(chrome, size, url(with_query(query, overlay)), SAFE_OUT / out.name)
        print(f"OK   {rel} ({width}x{height})")
    return problems


def main(argv):
    safe = "--safe" in argv
    argv = [arg for arg in argv if arg != "--safe"]
    names = argv or list(ASSETS)
    unknown = [name for name in names if name not in ASSETS]
    if unknown:
        print(f"Unknown asset(s): {', '.join(unknown)}. Known: {', '.join(ASSETS)}")
        return 2

    chrome = find_chrome()
    if chrome is None:
        print("Chrome not found. Install Google Chrome or set CHROME to its binary.")
        return 1

    problems = []
    for name in names:
        template, size, outputs, *options = ASSETS[name]
        problems += render(chrome, template, size, outputs, safe=safe, **(options[0] if options else {}))
    for problem in problems:
        print(f"FAIL {problem}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
