"""Builds a marketing content kit (Phase 3 of #69). Works on Windows and macOS.

Usage: python tool/marketing/build_kit.py <kit> [part ...]

Reads docs/marketing/kits/<kit>.json and writes build/marketing/<kit>/. Parts: shorts,
walkthrough, gifs, images, appstore; the default is every part the kit defines. Only a full
run clears the kit folder and writes POST.md, including the channel posts from
docs/marketing/kits/<kit>.posts.md. The part `post` alone rewrites POST.md from the last full run,
for edited posts.

Needs ffmpeg and ffprobe on PATH, plus Chrome and network access (see render_images.py).
Exits 1 if an output misses its spec (size, length, chapter length, GIF size) or a post breaks
its channel's rules (see posts.py).
"""

import datetime
import json
import shutil
import sys
from urllib.parse import urlencode

import posts
import render_images
import render_video as rv

REPO_ROOT = render_images.REPO_ROOT
KITS = REPO_ROOT / "docs/marketing/kits"
RAW = "build/marketing/raw"  # Default "recordings" folder of a kit.
MUSIC = REPO_ROOT / "tool/marketing/assets/music"
TEMPLATES = "docs/marketing/templates"
CREATIVE = "assets/store/app-store/creative"

SHORT = (f"{TEMPLATES}/video_9x16.html", (1080, 1920))
WALKTHROUGH = (f"{TEMPLATES}/video_16x9.html", (1920, 1080))
CAROUSEL = (f"{TEMPLATES}/carousel.html", (1080, 1350))
# Kit key: (template, size, output file).
BANNERS = {
    "thumbnail": (f"{TEMPLATES}/banner.html", (1280, 720), "thumb.png"),
    "og": (f"{TEMPLATES}/banner.html", (1200, 630), "og.png"),
    "forum_header": (f"{TEMPLATES}/banner.html", (1920, 640), "forum_header.png"),
}
# App Store creative videos: template, template size, video size. 3840×2560 is over H.264's
# largest frame size (level 5.2), so the search video uses 2880×1920 within Apple's 3:2 range.
CREATIVE_VIDEOS = {
    "search": (f"{CREATIVE}/search_3x2.html", (3840, 2560), (2880, 1920)),
    "header": (f"{CREATIVE}/header_21x9.html", (3840, 1646), (3840, 1646)),
}
LOCALES = {"en-US": "en", "de-DE": "de"}

SHORT_MAX = 60
CHAPTER_MIN = 10  # YouTube ignores chapters shorter than 10 s.
CAROUSEL_MAX = 10
PREVIEW_SIZE = (886, 1920)
PREVIEW_LENGTH = (15, 30)
CREATIVE_LENGTH = (5, 30)
PARTS = ["shorts", "walkthrough", "gifs", "images", "appstore"]
POST = "post"
MANIFEST = "manifest.json"  # What a full run built, so `post` can rewrite POST.md without it.


def rel(path):
    return path.relative_to(REPO_ROOT).as_posix()


def timestamp(seconds):
    return f"{int(seconds) // 60}:{int(seconds) % 60:02d}"


class Kit:
    def __init__(self, name, chrome):
        self.name = name
        self.chrome = chrome
        self.spec = json.loads((KITS / f"{name}.json").read_text(encoding="utf-8"))
        self.out = REPO_ROOT / "build/marketing" / name
        self.work = self.out / ".work"
        self.problems = []
        self.files = []
        self.shorts = []
        self.chapters = []
        self._clips = {}
        self._music = None
        self.music_note = None

    def clip(self, name):
        """(prepared clip, Edit, length), cut once per run."""
        if name not in self._clips:
            spec = self.spec["clips"][name]
            if "source" in spec:
                source = REPO_ROOT / spec["source"]
            else:
                source = REPO_ROOT / self.spec.get("recordings", RAW) / f"{name}.mp4"
            if not source.is_file():
                raise SystemExit(f"Missing recording {rel(source)}. See tool/marketing/README.md.")
            # Demo clips end with the key press of _stop_recording.yaml.
            end = rv.duration(source) if "source" in spec else rv.recording_end(source)
            segments = [(a, end if b is None else min(b, end), speed)
                        for a, b, speed in spec.get("segments", [[0, None, 1]]) if a < end]
            edit = rv.Edit(segments, spec.get("captions", []))
            path = self.work / "clips" / f"{name}.mp4"
            print(f"Cut  {rel(source)}")
            self._clips[name] = (path, edit, rv.prepare(source, edit, path))
        return self._clips[name]

    def music(self):
        if self._music is None and self.music_note is None:
            name = self.spec.get("music")
            path = MUSIC / name if name else None
            if path and path.is_file():
                self._music = path
            else:
                self.music_note = (f"No music bed: `{rel(path)}` is missing, so the videos have a silent track."
                                   if path else "No music bed set in the kit, so the videos have a silent track.")
        return self._music

    def end_card(self, template, size, file_name):
        path = self.work / file_name
        rv.render_still(self.chrome, template, size, {"endcard": "", **self.spec["endcard"]}, path)
        return path

    def check(self, path, size, length_range=(0, None), audio=False):
        """Records the file for POST.md and its problems; returns its length."""
        length = rv.duration(path)
        width, height = rv.video_size(path)
        low, high = length_range
        if (width, height) != size:
            self.problems.append(f"{rel(path)}: {width}x{height}, expected {size[0]}x{size[1]}")
        if length < low or (high and length > high):
            self.problems.append(f"{rel(path)}: {length:.1f} s, expected {low}–{high} s")
        if audio and not rv.has_audio(path):
            self.problems.append(f"{rel(path)}: no audio track")
        self.files.append((path, f"{width}×{height}, {length:.1f} s"))
        print(f"OK   {rel(path)} ({width}x{height}, {length:.1f} s)")
        return length

    def caption_layers(self, edit, length, hook=None):
        spans = edit.caption_spans(length)
        if hook:
            if spans and spans[0][0] < 0.05:
                spans[0] = (spans[0][0], spans[0][1], hook)
            else:
                spans.insert(0, (0.0, spans[0][0] if spans else length, hook))
        return [(start, end, {"caption": text}) for start, end, text in spans]

    def build_shorts(self):
        template, size = SHORT
        card = self.end_card(template, size, "end_9x16.png")
        for name, short in self.spec["shorts"].items():
            segments = []
            for i, clip_name in enumerate(short["clips"]):
                clip, edit, length = self.clip(clip_name)
                layers = self.caption_layers(edit, length, short.get("hook") if i == 0 else None)
                segment = self.work / "shorts" / name / f"{i}_{clip_name}.mp4"
                rv.compose(self.chrome, template, size, clip, {}, layers, segment)
                segments.append(segment)
            out = self.out / "shorts" / f"{name}_9x16.mp4"
            rv.assemble(segments, out, end_card=card, music=self.music())
            self.shorts.append((out, short["title"], self.check(out, size, (0, SHORT_MAX), audio=True)))

    def build_walkthrough(self):
        template, size = WALKTHROUGH
        names = self.spec["walkthrough"]
        segments = []
        start = 0.0
        for i, name in enumerate(names, 1):
            clip, edit, length = self.clip(name)
            title = self.spec["clips"][name]["title"]
            segment = self.work / "walkthrough" / f"{i:02d}_{name}.mp4"
            params = {"chapter": f"{i} / {len(names)}", "title": title}
            length = rv.compose(self.chrome, template, size, clip, params, self.caption_layers(edit, length), segment)
            if i == len(names):
                length += rv.END_CARD_SECONDS
            if length < CHAPTER_MIN:
                self.problems.append(f"walkthrough chapter '{title}': {length:.1f} s, YouTube needs {CHAPTER_MIN} s")
            self.chapters.append((start, title))
            start += length
            segments.append(segment)
        out = self.out / "walkthrough_16x9.mp4"
        rv.assemble(segments, out, end_card=self.end_card(template, size, "end_16x9.png"), music=self.music())
        self.check(out, size, audio=True)

    def build_gifs(self):
        for name in self.spec["gifs"]:
            clip, _, _ = self.clip(name)
            out = self.out / "gif" / f"{name}.gif"
            step = rv.gif(clip, out)
            size_mb = out.stat().st_size / 1024 / 1024
            if step is None:
                self.problems.append(f"{rel(out)}: {size_mb:.1f} MB even at the smallest step, limit 8 MB")
                continue
            fps, width = step
            self.files.append((out, f"{width} px wide, {fps} fps, {size_mb:.1f} MB"))
            print(f"OK   {rel(out)} ({width} px, {fps} fps, {size_mb:.1f} MB)")

    def build_images(self):
        images = self.spec["images"]
        slides = images.get("carousel", [])
        if len(slides) > CAROUSEL_MAX:
            self.problems.append(f"carousel: {len(slides)} slides, Instagram allows {CAROUSEL_MAX}")
        renders = []
        if slides:
            (self.out / "carousel").mkdir(parents=True, exist_ok=True)
            template, size = CAROUSEL
            renders.append((template, size, {self.out / "carousel" / f"{i:02d}.png": "?" + urlencode(slide)
                                             for i, slide in enumerate(slides, 1)}))
        for key, (template, size, file_name) in BANNERS.items():
            if key in images:
                renders.append((template, size, {self.out / file_name: "?" + urlencode(images[key])}))
        self.out.mkdir(parents=True, exist_ok=True)
        for template, size, outputs in renders:
            self.problems += render_images.render(self.chrome, template, size, outputs)
            for path in outputs:
                if path.is_file():
                    self.files.append((path, f"{size[0]}×{size[1]} PNG"))

    def build_appstore(self):
        spec = self.spec["appstore"]
        if "preview" in spec:
            clip, _, _ = self.clip(spec["preview"])
            out = self.out / "preview_iphone.mp4"
            rv.appstore_preview(clip, out, PREVIEW_SIZE)
            self.check(out, PREVIEW_SIZE, PREVIEW_LENGTH, audio=True)
        if "creative" in spec:
            clip, _, _ = self.clip(spec["creative"])
            for kind, (template, size, video_size) in CREATIVE_VIDEOS.items():
                for locale, lang in LOCALES.items():
                    segment = self.work / "appstore" / f"{kind}_{locale}.mp4"
                    out_size = video_size if video_size != size else None
                    rv.compose(self.chrome, template, size, clip, {"lang": lang}, [], segment, out_size)
                    out = self.out / f"{kind}_{locale}.mp4"
                    rv.assemble([segment], out, audio=False)
                    self.check(out, video_size, CREATIVE_LENGTH)

    def save_manifest(self):
        manifest = {
            "files": [[path.relative_to(self.out).as_posix(), spec] for path, spec in self.files],
            "shorts": [[path.relative_to(self.out).as_posix(), title, length] for path, title, length in self.shorts],
            "chapters": self.chapters,
            "music_note": self.music_note,
        }
        (self.out / MANIFEST).write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    def load_manifest(self):
        path = self.out / MANIFEST
        if not path.is_file():
            return False
        manifest = json.loads(path.read_text(encoding="utf-8"))
        self.files = [(self.out / file, spec) for file, spec in manifest["files"]]
        self.shorts = [(self.out / file, title, length) for file, title, length in manifest["shorts"]]
        self.chapters = [tuple(chapter) for chapter in manifest["chapters"]]
        self.music_note = manifest["music_note"]
        return True

    def write_post(self):
        lines = [
            f"# Content kit: {self.name}",
            "",
            f"Built {datetime.date.today().isoformat()} by `tool/marketing/build_kit.py` from "
            f"`docs/marketing/kits/{self.name}.json`. Every store link in a post comes from "
            "`docs/marketing/links.md`.",
            "",
        ]
        if self.music_note:
            lines += [f"> ⚠️ {self.music_note}", ""]
        lines += ["## Files", "", "| File | Spec |", "|---|---|"]
        lines += [f"| `{path.relative_to(self.out).as_posix()}` | {spec} |" for path, spec in self.files]
        if self.shorts:
            lines += ["", "## Shorts / Reels / TikTok", "", "| File | Title |", "|---|---|"]
            lines += [f"| `{path.relative_to(self.out).as_posix()}` | {title} |" for path, title, _ in self.shorts]
        if self.chapters:
            lines += ["", "## YouTube walkthrough chapters", "", "Paste into the video description:", "", "```text"]
            lines += [f"{timestamp(start)} {title}" for start, title in self.chapters]
            lines += ["```"]
        source = KITS / f"{self.name}.posts.md"
        if source.is_file():
            chapters = "\n".join(f"{timestamp(start)} {title}" for start, title in self.chapters)
            text, problems = posts.render(source.read_text(encoding="utf-8"), chapters)
            self.problems += problems
            lines += ["", "## Posts", "", f"App version {posts.app_version()}. Drafts: `{rel(source)}`; "
                      "posting rules: `docs/marketing/channels.md`.", "", text.rstrip()]
        (self.out / "POST.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"OK   {rel(self.out / 'POST.md')}")


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    name, parts = argv[0], argv[1:]
    if not (KITS / f"{name}.json").is_file():
        known = ", ".join(sorted(p.stem for p in KITS.glob("*.json")))
        print(f"Unknown kit '{name}'. Known: {known}")
        return 2
    unknown = [part for part in parts if part not in PARTS + [POST]]
    if unknown:
        print(f"Unknown part(s): {', '.join(unknown)}. Known: {', '.join(PARTS + [POST])}")
        return 2
    if POST in parts:
        if parts != [POST]:
            print(f"The part '{POST}' runs alone.")
            return 2
        kit = Kit(name, None)
        if not kit.load_manifest():
            print(f"No {rel(kit.out / MANIFEST)}. Run a full build first.")
            return 1
        kit.write_post()
        for problem in kit.problems:
            print(f"FAIL {problem}")
        return 1 if kit.problems else 0
    for tool in ("ffmpeg", "ffprobe"):
        if shutil.which(tool) is None:
            print(f"{tool} not found on PATH.")
            return 1
    chrome = render_images.find_chrome()
    if chrome is None:
        print("Chrome not found. Install Google Chrome or set CHROME to its binary.")
        return 1

    kit = Kit(name, chrome)
    shutil.rmtree(kit.out if not parts else kit.work, ignore_errors=True)
    for part in parts or [part for part in PARTS if part in kit.spec]:
        getattr(kit, f"build_{part}")()
    if not parts:
        kit.save_manifest()
        kit.write_post()
    shutil.rmtree(kit.work, ignore_errors=True)

    for problem in kit.problems:
        print(f"FAIL {problem}")
    return 1 if kit.problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
