"""Builds the screenshots and app previews of each custom product page (#82 Phase 2).

Usage: python tool/store/custom_page_media.py [--check]

Each page folder in docs/store/app-store/custom-product-pages/ has a media_order.txt that lists
default files in page order, one line per device:

  iphone: preview_2, preview_1, 03, 04, ...   (preview_N from app_previews/en-US/iphone_61/,
  ipad: 03, 04, ...                            NN from screenshots/en-US/{iphone,ipad}_NN.png)

The script copies them to <page>/en-US/screenshots/ and <page>/en-US/app_previews/iphone_61/,
renamed to iphone_01, ipad_01, preview_1, ... in that order (App Store Connect uploads in filename
order), and deletes files there that the order no longer lists. Byte-identical copies share one
Git LFS object. --check writes nothing and exits 1 if a page's files differ from its order.
"""

import filecmp
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
APP_STORE_DIR = REPO_ROOT / "docs" / "store" / "app-store"
PAGES_DIR = APP_STORE_DIR / "custom-product-pages"
# Screens stay English in every localization until the app UI is translated (#18).
LOCALE = "en-US"
PREVIEW_FOLDER = "app_previews/iphone_61"
MANAGED_FOLDERS = ("screenshots", "app_previews")


def media_order(path):
    """{"iphone": ["preview_2", "03", ...], "ipad": [...]} from a media_order.txt."""
    order = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            device, names = line.split(":", 1)
            order[device.strip()] = [name.strip() for name in names.split(",") if name.strip()]
    return order


def expected_files(page_dir):
    """{path under <page>/<locale>/: source file} for one page."""
    order = media_order(page_dir / "media_order.txt")
    unknown_devices = set(order) - {"iphone", "ipad"}
    if unknown_devices:
        raise ValueError(f"unknown device(s) {', '.join(sorted(unknown_devices))}")

    files = {}
    for device, names in order.items():
        screenshot_count = preview_count = 0
        for name in names:
            if name.startswith("preview_"):
                if device != "iphone":
                    raise ValueError(f"{device}: app previews exist for iPhone only ({name})")
                source = APP_STORE_DIR / PREVIEW_FOLDER.replace("/", f"/{LOCALE}/") / f"{name}.mp4"
                preview_count += 1
                target = f"{PREVIEW_FOLDER}/preview_{preview_count}.mp4"
            else:
                source = APP_STORE_DIR / "screenshots" / LOCALE / f"{device}_{name}.png"
                screenshot_count += 1
                target = f"screenshots/{device}_{screenshot_count:02d}.png"
            if not source.is_file():
                raise ValueError(f"{device}: unknown name {name} ({source.relative_to(REPO_ROOT)} missing)")
            files[target] = source
    return files


def present_files(locale_dir):
    return {
        path.relative_to(locale_dir).as_posix()
        for folder in MANAGED_FOLDERS
        for path in (locale_dir / folder).rglob("*")
        if path.is_file()
    }


def remove_empty_folders(locale_dir):
    for folder in MANAGED_FOLDERS:
        root = locale_dir / folder
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*"), reverse=True):
            if path.is_dir() and not any(path.iterdir()):
                path.rmdir()
        if not any(root.iterdir()):
            root.rmdir()


def sync_page(page_dir, check):
    """Returns the differences; also fixes them unless check is set."""
    locale_dir = page_dir / LOCALE
    expected = expected_files(page_dir)
    problems = []
    for target, source in expected.items():
        path = locale_dir / target
        if path.is_file() and filecmp.cmp(source, path, shallow=False):
            continue
        state = "differs from" if path.is_file() else "missing, copy of"
        problems.append(f"{target}: {state} {source.relative_to(APP_STORE_DIR)}")
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, path)
    for target in sorted(present_files(locale_dir) - set(expected)):
        problems.append(f"{target}: not in media_order.txt")
        if not check:
            (locale_dir / target).unlink()
    if not check:
        remove_empty_folders(locale_dir)
    return problems


def main(argv):
    if any(arg != "--check" for arg in argv):
        print(__doc__)
        return 2
    check = "--check" in argv

    failed = False
    for page_dir in sorted(path.parent for path in PAGES_DIR.glob("*/media_order.txt")):
        try:
            problems = sync_page(page_dir, check)
        except ValueError as error:
            print(f"{page_dir.name}: {error}")
            failed = True
            continue
        if not problems:
            print(f"{page_dir.name}: up to date")
            continue
        print(f"{page_dir.name}: {'out of date' if check else 'updated'}")
        for problem in problems:
            print(f"  {problem}")
        failed = failed or check
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
