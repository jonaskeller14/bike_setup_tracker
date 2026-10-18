"""Builds a marketing content kit (Phase 3 of #69). Works on Windows and macOS.

Usage: python tool/marketing/build_kit.py <kit> [part ...]

Reads docs/marketing/kits/<kit>.json and writes build/marketing/<kit>/. Parts: shorts,
walkthrough, gifs, web, images, appstore; the default is every part the kit defines. Only a full
run clears the kit folder and writes POST.md, including the channel posts from
docs/marketing/kits/<kit>.posts.md, and the contact sheet sheet.html. The parts `post` and `sheet`
run alone and rewrite POST.md or sheet.html from the last full run.

Needs ffmpeg and ffprobe on PATH, plus Chrome and network access (see render_images.py). The web
part also needs img2webp and cwebp (libwebp).
Exits 1 if an output misses its spec (size, length, chapter length, GIF or loop size) or a post breaks
its channel's rules (see posts.py).
"""

import datetime
import html
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
CREATIVE = "docs/store/app-store/creative"

SHORT = (f"{TEMPLATES}/video_9x16.html", (1080, 1920))
WALKTHROUGH = (f"{TEMPLATES}/video_16x9.html", (1920, 1080))
ENDCARD = f"{TEMPLATES}/endcard.html"
# Kit key: (template, size, output folder) of a list of post slides; {"kind": "endcard"} is the end card.
POSTS_SLIDES = {
    "carousel": (f"{TEMPLATES}/post_4x5.html", (1080, 1350), "carousel"),
    "square": (f"{TEMPLATES}/post_1x1.html", (1080, 1080), "square"),
}
# Kit key: (template, size, output file).
BANNERS = {
    "thumbnail": (f"{TEMPLATES}/banner.html", (1280, 720), "thumb.png"),
    "og": (f"{TEMPLATES}/banner.html", (1200, 630), "og.png"),
    "og_de": (f"{TEMPLATES}/banner.html", (1200, 630), "og_de-DE.png"),
    "forum_header": (f"{TEMPLATES}/banner.html", (1920, 640), "forum_header.png"),
}
# App Store creative videos: template, template size, video size. 3840×2560 is over H.264's
# largest frame size (level 5.2), so the search video uses 2880×1920 within Apple's 3:2 range.
# The header has no phone since #77 (brand.md), so no recording to play in it.
CREATIVE_VIDEOS = {
    "search": (f"{CREATIVE}/search_3x2.html", (3840, 2560), (2880, 1920)),
}
LOCALES = {"en-US": "en", "de-DE": "de"}

SHORT_MAX = 60
CHAPTER_MIN = 10  # YouTube ignores chapters shorter than 10 s.
CAROUSEL_MAX = 10  # Instagram's limit; YouTube community posts allow 5.
WEB_LIMIT_MB = 2  # Per website loop; the landing page shows nine.
PREVIEW_SIZE = (886, 1920)
PREVIEW_LENGTH = (15, 30)
CREATIVE_LENGTH = (5, 30)
PARTS = ["shorts", "walkthrough", "gifs", "web", "images", "appstore"]
POST = "post"
SHEET = "sheet"
SHEET_FRAMES = (0.15, 0.5, 0.97)  # Where the contact sheet samples each video, as a share of its length.
POSTS = "posts"  # Folder with one Markdown file per post.
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
            edit = rv.Edit(segments, spec.get("captions", []), spec.get("callouts", []))
            path = self.work / "clips" / f"{name}.mp4"
            print(f"Cut  {rel(source)}")
            length = rv.prepare(source, edit, path)
            zooms = edit.callout_spans("zoom")
            if zooms:
                zoomed = path.with_name(f"{name}_zoom.mp4")
                length = rv.zoom(path, zooms, zoomed)
                path = zoomed
            self._clips[name] = (path, edit, length)
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

    def params(self):
        """URL parameters every template of the kit gets: the device (iphone or android)."""
        return {"device": self.spec["device"]} if "device" in self.spec else {}

    def end_card(self, size, file_name):
        path = self.work / file_name
        rv.render_still(self.chrome, ENDCARD, size, self.spec.get("endcard", {}), path)
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
        card = self.end_card(size, "end_9x16.png")
        for name, short in self.spec["shorts"].items():
            segments = []
            for i, clip_name in enumerate(short["clips"]):
                clip, edit, length = self.clip(clip_name)
                layers = self.caption_layers(edit, length, short.get("hook") if i == 0 else None)
                segment = self.work / "shorts" / name / f"{i}_{clip_name}.mp4"
                rv.compose(self.chrome, template, size, clip, self.params(), layers, segment,
                           lifts=edit.callout_spans("lift"))
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
            params = {**self.params(), "chapter": f"{i} / {len(names)}", "title": title}
            length = rv.compose(self.chrome, template, size, clip, params, self.caption_layers(edit, length), segment,
                                lifts=edit.callout_spans("lift"))
            if i == len(names):
                length += rv.END_CARD_SECONDS
            if length < CHAPTER_MIN:
                self.problems.append(f"walkthrough chapter '{title}': {length:.1f} s, YouTube needs {CHAPTER_MIN} s")
            self.chapters.append((start, title))
            start += length
            segments.append(segment)
        out = self.out / "walkthrough_16x9.mp4"
        rv.assemble(segments, out, end_card=self.end_card(size, "end_16x9.png"), music=self.music())
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

    def build_web(self):
        missing = [tool for tool in ("img2webp", "cwebp") if shutil.which(tool) is None]
        if missing:
            self.problems.append(f"web: {', '.join(missing)} not found on PATH (libwebp)")
            return
        for name in self.spec["web"]:
            clip, _, _ = self.clip(name)
            out = self.out / "web" / f"{name}.webp"
            still = self.out / "web" / f"{name}_still.webp"
            rv.web_loop(clip, self.work / "web" / name, out, still)
            size_mb = out.stat().st_size / 1024 / 1024
            if size_mb > WEB_LIMIT_MB:
                self.problems.append(f"{rel(out)}: {size_mb:.1f} MB, limit {WEB_LIMIT_MB} MB")
            self.files.append((out, f"{rv.WEB_WIDTH} px wide, {rv.WEB_FPS} fps, {size_mb:.1f} MB"))
            self.files.append((still, f"{rv.WEB_WIDTH} px wide, last frame"))
            print(f"OK   {rel(out)} ({rv.WEB_WIDTH} px, {rv.WEB_FPS} fps, {size_mb:.1f} MB)")

    def build_images(self):
        images = self.spec["images"]
        renders = []
        for key, (template, size, folder) in POSTS_SLIDES.items():
            slides = images.get(key, [])
            if len(slides) > CAROUSEL_MAX:
                self.problems.append(f"{key}: {len(slides)} slides, Instagram allows {CAROUSEL_MAX}")
            for i, slide in enumerate(slides, 1):
                (self.out / folder).mkdir(parents=True, exist_ok=True)
                if slide.get("kind") == "endcard":
                    page, params = ENDCARD, {k: v for k, v in slide.items() if k != "kind"}
                else:
                    page, params = template, {**self.params(), **slide}
                renders.append((page, size, {self.out / folder / f"{i:02d}.png": "?" + urlencode(params)}))
        for key, (template, size, file_name) in BANNERS.items():
            if key in images:
                renders.append((template, size, {self.out / file_name: "?" + urlencode({**self.params(), **images[key]})}))
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
            clip, edit, _ = self.clip(spec["creative"])
            for kind, (template, size, video_size) in CREATIVE_VIDEOS.items():
                for locale, lang in LOCALES.items():
                    segment = self.work / "appstore" / f"{kind}_{locale}.mp4"
                    out_size = video_size if video_size != size else None
                    rv.compose(self.chrome, template, size, clip, {"lang": lang}, [], segment, out_size,
                               lifts=edit.callout_spans("lift"))
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
            files = [path.relative_to(self.out).as_posix() for path, _ in self.files]
            rendered, problems = posts.render(source.read_text(encoding="utf-8"), chapters, files)
            self.problems += problems
            shutil.rmtree(self.out / POSTS, ignore_errors=True)
            (self.out / POSTS).mkdir()
            lines += ["", "## Posts", "", f"App version {posts.app_version()}. One file per post with its checklist; "
                      f"drafts: `{rel(source)}`; posting rules: `docs/marketing/channels.md`.", ""]
            for number, (heading, text) in enumerate(rendered, 1):
                name = posts.slug(heading, number)
                (self.out / POSTS / name).write_text(text, encoding="utf-8")
                lines.append(f"- [{heading}]({POSTS}/{name})")
        (self.out / "POST.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"OK   {rel(self.out / 'POST.md')}")

    def write_sheet(self):
        """sheet.html: every image, and three frames per video, with a safe-area toggle. The
        maintainer's review page."""
        frames = self.out / SHEET
        shutil.rmtree(frames, ignore_errors=True)
        frames.mkdir(parents=True)
        sections = {}
        for path, spec in self.files:
            name = path.relative_to(self.out).as_posix()
            if path.suffix == ".mp4":
                length = rv.duration(path)
                shots = []
                for i, share in enumerate(SHEET_FRAMES, 1):
                    shot = frames / f"{name.replace('/', '_')[:-4]}_{i}.jpg"
                    rv.ffmpeg("-ss", f"{length * share:.2f}", "-i", path, "-frames:v", "1", "-q:v", "3", shot)
                    shots.append(shot.relative_to(self.out).as_posix())
            else:
                shots = [name]
            imgs = "".join(f'<a href="{html.escape(shot)}"><span class="shot"><img src="{html.escape(shot)}" alt=""></span></a>'
                           for shot in shots)
            caption = f"<code>{html.escape(name)}</code> {html.escape(spec)}"
            sections.setdefault(name.split("/")[0] if "/" in name else "", []).append(
                f'<figure><div class="shots">{imgs}</div><figcaption>{caption}</figcaption></figure>')
        safe = {f"{w}x{h}": area for (w, h), area in render_images.SAFE_AREAS.items()}
        body = "".join(f"<h2>{html.escape(folder or 'Kit')}</h2><div class=\"grid\">{''.join(items)}</div>"
                       for folder, items in sorted(sections.items()))
        page = SHEET_PAGE.replace("{title}", html.escape(self.name)).replace("{body}", body).replace(
            "{safe}", json.dumps(safe))
        (self.out / f"{SHEET}.html").write_text(page, encoding="utf-8")
        print(f"OK   {rel(self.out / f'{SHEET}.html')}")


SHEET_PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Contact sheet: {title}</title>
<style>
  body { margin: 24px; font: 14px/1.4 system-ui, sans-serif; background: #f4f4f4; color: #0a0a0a; }
  header { position: sticky; top: 0; z-index: 2; display: flex; gap: 24px; align-items: center; padding: 12px 0; background: #f4f4f4; }
  h1 { margin: 0; font-size: 20px; }
  h2 { margin: 32px 0 12px; font-size: 16px; text-transform: uppercase; letter-spacing: .06em; }
  .grid { display: flex; flex-wrap: wrap; gap: 24px; align-items: flex-start; }
  figure { margin: 0; }
  .shots { display: flex; gap: 8px; }
  .shot { position: relative; display: block; }
  .shot img { display: block; height: var(--h, 320px); background: #fff; box-shadow: 0 1px 4px rgba(0, 0, 0, .2); }
  figcaption { margin-top: 6px; max-width: 640px; color: #555; }
  .area { position: absolute; display: none; outline: 2px dashed #e0245e; pointer-events: none; }
  .area.avoid { outline-style: solid; background: rgba(224, 36, 94, .18); }
  .area.guide { outline-color: #2563eb; }
  .show-safe .area { display: block; }
</style>
</head>
<body>
<header>
  <h1>Contact sheet: {title}</h1>
  <label><input type="checkbox" id="safe"> Safe areas</label>
  <label>Height <select id="height"><option>200</option><option selected>320</option><option>480</option><option>720</option></select> px</label>
</header>
{body}
<script>
  // Safe areas per WxH (tool/marketing/render_images.py SAFE_AREAS), drawn over each image.
  const SAFE = {safe};
  for (const img of document.querySelectorAll('.shot img')) {
    img.addEventListener('load', () => {
      const area = SAFE[`${img.naturalWidth}x${img.naturalHeight}`];
      if (!area) return;
      const boxes = [['safe', [area.safe]], ['avoid', area.avoid || []], ['guide', area.guides || []]];
      for (const [kind, rects] of boxes) {
        for (const [x, y, w, h] of rects) {
          const box = document.createElement('div');
          box.className = `area ${kind}`;
          Object.assign(box.style, {
            left: `${x / img.naturalWidth * 100}%`, top: `${y / img.naturalHeight * 100}%`,
            width: `${w / img.naturalWidth * 100}%`, height: `${h / img.naturalHeight * 100}%`,
          });
          img.parentElement.append(box);
        }
      }
    });
  }
  document.getElementById('safe').addEventListener('change', (e) => document.body.classList.toggle('show-safe', e.target.checked));
  document.getElementById('height').addEventListener('change', (e) => document.body.style.setProperty('--h', `${e.target.value}px`));
</script>
</body>
</html>
"""


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    name, parts = argv[0], argv[1:]
    if not (KITS / f"{name}.json").is_file():
        known = ", ".join(sorted(p.stem for p in KITS.glob("*.json")))
        print(f"Unknown kit '{name}'. Known: {known}")
        return 2
    unknown = [part for part in parts if part not in PARTS + [POST, SHEET]]
    if unknown:
        print(f"Unknown part(s): {', '.join(unknown)}. Known: {', '.join(PARTS + [POST, SHEET])}")
        return 2
    alone = [part for part in parts if part in (POST, SHEET)]
    if alone:
        if len(parts) != 1:
            print(f"The part '{alone[0]}' runs alone.")
            return 2
        kit = Kit(name, None)
        if not kit.load_manifest():
            print(f"No {rel(kit.out / MANIFEST)}. Run a full build first.")
            return 1
        if alone == [POST]:
            kit.write_post()
        else:
            kit.write_sheet()
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
        kit.write_sheet()
    shutil.rmtree(kit.work, ignore_errors=True)

    for problem in kit.problems:
        print(f"FAIL {problem}")
    return 1 if kit.problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
