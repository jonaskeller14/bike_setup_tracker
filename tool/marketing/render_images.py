"""Renders the HTML image templates to PNG with headless Chrome (Windows and macOS).

Usage: python tool/marketing/render_images.py [asset ...]

Assets are keys of ASSETS (e.g. appstore-search); default is all. Set CHROME
to the browser binary if it isn't found automatically. Templates load Google
Fonts, so rendering needs network access.
Exits 1 if Chrome fails or an output has an unexpected size or format.
"""

import os
import platform
import shutil
import struct
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

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
    "play-feature": (
        "docs/store/play-store/feature_graphic.html",
        (1024, 500),
        {"feature_graphic_en-US.png": "?lang=en", "feature_graphic_de-DE.png": "?lang=de"},
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


def render(chrome, template, size, outputs):
    page = (REPO_ROOT / template).resolve()
    problems = []
    for file_name, query in outputs.items():
        out = page.parent / file_name
        out.unlink(missing_ok=True)
        # Chrome occasionally hangs (e.g. on a stalled font request); one retry is enough.
        for _ in range(2):
            try:
                subprocess.run(
                    [
                        str(chrome),
                        "--headless",
                        "--hide-scrollbars",
                        "--force-device-scale-factor=1",
                        f"--window-size={size[0]},{size[1]}",
                        # Gives the web fonts time to load before the screenshot.
                        "--virtual-time-budget=5000",
                        f"--screenshot={out}",
                        page.as_uri() + query,
                    ],
                    capture_output=True,
                    timeout=120,
                )
                break
            except subprocess.TimeoutExpired:
                out.unlink(missing_ok=True)
        rel = out.relative_to(REPO_ROOT).as_posix()
        if not out.is_file():
            problems.append(f"{rel}: Chrome wrote no file")
            continue
        width, height, color_type = png_info(out)
        if (width, height) != size:
            problems.append(f"{rel}: {width}x{height}, expected {size[0]}x{size[1]}")
        elif color_type != 2:
            problems.append(f"{rel}: has an alpha channel, the App Store needs RGB")
        else:
            print(f"OK   {rel} ({width}x{height})")
    return problems


def main(argv):
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
        problems += render(chrome, *ASSETS[name])
    for problem in problems:
        print(f"FAIL {problem}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
