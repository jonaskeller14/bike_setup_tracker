"""Checks store raw screenshots and lists which ones changed versus git HEAD.

Usage: python tool/screenshots/check_output.py [folder ...]

Folders are keys of EXPECTED_SIZES (e.g. play-store/phone); default is all.
Folders in FRAMED_EXPORTS also have their rendered store screenshots checked
(tool/marketing/render_images.py store-screenshots writes them).
Exits 1 if any raw or checked export is missing or has an unexpected size.
"""

import struct
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
STORE_DIR = REPO_ROOT / "docs" / "store"
SCREEN_COUNT = 8

# docs/store/screenshots.html puts these raws into its device frames, which
# assume exactly these pixel sizes.
EXPECTED_SIZES = {
    "play-store/phone": (1080, 2400),
    "play-store/tablet_10-inch": (1200, 1920),
    "app-store/iPhone-17-Pro-Max": (1320, 2868),
    "app-store/iPad-Pro-13-inch_M5": (2064, 2752),
}

# Raw folder -> (export folder, export file name, size) of the store screenshot
# rendered from it. App Store Connect's 6.1"/6.3" iPhone slot only accepts
# 1179x2556 and 1206x2622.
FRAMED_EXPORTS = {
    "app-store/iPhone-17-Pro-Max": ("app-store/screenshots/en-US", "iphone_{:02d}.png", (1206, 2622)),
    "app-store/iPad-Pro-13-inch_M5": ("app-store/screenshots/en-US", "ipad_{:02d}.png", (2064, 2752)),
    "play-store/phone": ("play-store/metadata/en-US/images/phoneScreenshots", "{:02d}.png", (1080, 1920)),
    "play-store/tablet_10-inch": ("play-store/metadata/en-US/images/tenInchScreenshots", "{:02d}.png", (1800, 2650)),
}


def png_size(path):
    with path.open("rb") as f:
        header = f.read(24)
    if header.startswith(b"version https://git-lfs"):
        raise ValueError("Git LFS pointer, run 'git lfs pull'")
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("not a PNG")
    return struct.unpack(">II", header[16:24])


def changed_raws(folders):
    paths = [str((STORE_DIR / folder).relative_to(REPO_ROOT)) for folder in folders]
    result = subprocess.run(
        ["git", "status", "--porcelain", "--", *paths],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [line[3:] for line in result.stdout.splitlines() if line.endswith("_raw.png")]


def main(argv):
    folders = argv or list(EXPECTED_SIZES)
    unknown = [folder for folder in folders if folder not in EXPECTED_SIZES]
    if unknown:
        print(f"Unknown folder(s): {', '.join(unknown)}. Known: {', '.join(EXPECTED_SIZES)}")
        return 2

    problems = []
    for folder in folders:
        checks = [(folder, "{:02d}_raw.png", EXPECTED_SIZES[folder])]
        if folder in FRAMED_EXPORTS:
            checks.append(FRAMED_EXPORTS[folder])
        for check_folder, name_format, expected in checks:
            for index in range(1, SCREEN_COUNT + 1):
                name = name_format.format(index)
                path = STORE_DIR / check_folder / name
                if not path.exists():
                    problems.append(f"{check_folder}/{name}: missing")
                    continue
                try:
                    size = png_size(path)
                except ValueError as error:
                    problems.append(f"{check_folder}/{name}: {error}")
                    continue
                if size != expected:
                    problems.append(
                        f"{check_folder}/{name}: {size[0]}x{size[1]}, "
                        f"expected {expected[0]}x{expected[1]}"
                    )

    changed = changed_raws(folders)
    print(f"Changed raws vs HEAD ({len(changed)}):")
    for path in changed:
        print(f"  {path}")

    if problems:
        print()
        print("!" * 72)
        print("SIZE CHECK FAILED - the device frames in docs/store/screenshots.html")
        print("assume the expected raw sizes. Fix the device/AVD, or adjust the")
        print("frames. Wrong store screenshots need rendering again with")
        print("python tool/marketing/render_images.py store-screenshots:")
        for problem in problems:
            print(f"  {problem}")
        print("!" * 72)
        return 1

    print(f"Size check passed for {len(folders)} folder(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
