# Marketing tooling

Scripts for the marketing plan in [#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69).
Working docs live in [`docs/marketing/`](../../docs/marketing/README.md).

## Requirements

- Python 3 (standard library only).
- Google Chrome. On other paths, set `CHROME` to the binary.
- Network access: the templates load Google Fonts.
- For videos: `ffmpeg` and `ffprobe` on `PATH` (`brew install ffmpeg`, `winget install Gyan.FFmpeg`).
  No libass or drawtext needed: captions are rendered by Chrome.
- For the `web` part: `img2webp` and `cwebp` from libwebp on `PATH` (`brew install webp`; Windows: [libwebp downloads](https://developers.google.com/speed/webp/download)).

## `build_kit.py`

Builds a content kit from `docs/marketing/kits/<kit>.json` into `build/marketing/<kit>/`.

```
python tool/marketing/build_kit.py launch                   # everything the kit defines
python tool/marketing/build_kit.py launch shorts gifs       # some parts only
python tool/marketing/build_kit.py launch web               # website loops (copy them to the website repo)
python tool/marketing/build_kit.py appstore                 # App Store preview + creative videos
python tool/marketing/build_kit.py launch post              # only rewrite POST.md after editing posts
```

Parts: `shorts`, `walkthrough`, `gifs`, `web`, `images`, `appstore`. A full run clears the kit folder and
writes `POST.md` (file list, Shorts titles, YouTube chapter timestamps, warnings, links to the
`posts/` files) and `manifest.json`. A partial run replaces only its own files. `post` runs alone and
rewrites `POST.md` and `posts/` from `manifest.json`, so edited posts don't need a rebuild. The script exits 1 and prints `FAIL` lines when an output misses its
spec. The launch kit takes about 10 minutes on an M-series Mac.

| Part | Output | Spec checked |
|---|---|---|
| `shorts` | `shorts/<name>_9x16.mp4` | 1080×1920, ≤60 s, audio track |
| `walkthrough` | `walkthrough_16x9.mp4` | 1920×1080, every chapter ≥10 s |
| `gifs` | `gif/<clip>.gif` | ≤8 MB (steps down from 360 px / 15 fps) |
| `web` | `web/<clip>.webp`, `web/<clip>_still.webp` | lossy animated WebP, 400 px, 12 fps, ≤2 MB each; the still is the last frame |
| `images` | `carousel/NN.png`, `thumb.png`, `og.png`, `og_de-DE.png`, `forum_header.png` | size, RGB, ≤10 slides |
| `appstore` | `preview_iphone.mp4`, `{search,header}_{en-US,de-DE}.mp4` | 886×1920 15–30 s with audio; 2880×1920 / 3840×1646, 5–30 s |

### Recordings

- Demo clips: `tool/screenshots/run_ios.sh iphone --demo` → `build/marketing/raw/ios/demo_*.mp4`
  (the `launch` kit's `recordings` folder). The templates use the iPhone frame, whose screen hole
  is exactly the Simulator's 1320×2868, so nothing is cropped. `run_android.sh --demo` records the
  same flows to `build/marketing/raw/` (1080×2400), which doesn't fit the iPhone frame.
- App Store preview: `tool/screenshots/run_ios.sh iphone --preview` →
  `build/store_previews/iphone/*.mp4`; the `appstore` kit points `source` at it.
- Maestro needs Java 17+ on `PATH` (see `tool/screenshots/README.md`).

The simulators only write a frame when the screen changes, and the last frames before a still
screen can be missing. That's why demo flows end with `_stop_recording.yaml`, which presses
Volume Up (Android) or Home (iOS). `render_video.recording_end` finds where the volume panel or
home animation starts (the end of the last frame gap of ≥1 s) and every demo clip is cut there.
`preview_setup.yaml` doesn't end that way, so its last transition is missing; edit around it.

### Kit file

```jsonc
{
  "endcard": { "title": "…", "tagline": "…", "link": "…" },  // end card of Shorts and walkthrough
  "music": "track.mp3",          // in tool/marketing/assets/music/ (gitignored); missing → silent track
  "recordings": "build/marketing/raw/ios",  // where clips without "source" are read; default build/marketing/raw
  "clips": {
    "demo_add_setup": {
      "source": "build/…/x.mp4",  // optional; default <recordings>/<name>.mp4
      "title": "Record a Setup",  // walkthrough chapter
      "segments": [[0, 4, 1.5], [4, 11, 2.5]],  // [start, end, speed] in recording seconds; the rest is cut
      "captions": [[0, "Log Your *Setup*"], [4, "…"]]  // [recording second, text]; *word* is highlighted
    }
  },
  "shorts": { "core": { "title": "…", "clips": ["…"], "hook": "replaces the first caption" } },
  "walkthrough": ["clip", "…"],
  "gifs": ["clip", "…"],
  "web": ["clip", "…"],         // website loops, see the website repo's CLAUDE.md
  "images": {
    "carousel": [{ "kind": "cover|screen|cta", "title": "…", "sub": "…", "shots": "04,03" }],
    "thumbnail": { "title": "…", "shots": "04,03" }, "og": { … }, "og_de": { … }, "forum_header": { … }
  },
  "appstore": { "preview": "clip", "creative": "clip" }
}
```

### Posts

`docs/marketing/kits/<kit>.posts.md` holds the post drafts; `posts.py` renders each one into its
own file `build/marketing/<kit>/posts/NN-<channel>-<label>.md`, and `POST.md` links them. One
`## <channel> · <label>` section per post, where `<channel>` is an id from `docs/marketing/links.md`.
Each `### <Field>` is followed by a ```` ```text ```` block that is pasted as is; prose around the
blocks stays as posting notes. A post's file starts with its checklist: upload the video named in
the heading, the `[[…]]` fill-ins, the `- [ ]` lines from the prose, and "Posted".

| Placeholder | Becomes |
|---|---|
| `{ios:<channel>}`, `{android:<channel>}` | The channel's campaign link from `links.md` |
| `{smart:<channel>}` | `https://jonaskeller14.com/bike_setup_tracker/get?c=<channel>` |
| `{version}` | The app version from `pubspec.yaml` |
| `{chapters}` | The walkthrough chapter timestamps |
| `[[…]]` | Left as is, and listed as a "Fill in" checkbox |

The build fails on an unresolved placeholder, a store link that isn't a campaign link, a field
over its platform's length limit, too many hashtags, or `<`/`>` in YouTube text. The limits are
documented in [`docs/marketing/channels.md`](../../docs/marketing/channels.md).

To time an edit, make a contact sheet with one frame per second and read the times off it:

```
ffmpeg -i build/marketing/raw/ios/demo_tasks.mp4 -vf "fps=2,scale=150:-2,tile=10x6" -frames:v 1 sheet.png
```

Segments and captions use recording seconds, so they stay valid when the speed of another
segment changes.

### Music

Save the chosen track in `tool/marketing/assets/music/` and name it in the kit's `music`. The
folder is gitignored because music licenses don't allow redistributing the file. The bed is
loudness-normalized (−16 LUFS) and faded out. A video longer than the track repeats it: silence at
both ends is cut and the repeats crossfade over 4 s. Check the track's license for every platform
you post to.

| File | Used in | Source | License |
|---|---|---|---|
| `the_mountain-app-184141.mp3` | `launch` | ["App" by The_Mountain](https://pixabay.com/music/beats-app-184141/), Pixabay, 2:00 | Pixabay Content License: commercial use, no attribution required |

The track is registered with Content ID. If YouTube or another platform flags an upload, dispute
the claim with the Pixabay license certificate, `beats-app-184141-license.txt` next to the track
(gitignored like the track; download it again from the track page if it's missing).

## `render_video.py`

The ffmpeg side of `build_kit.py`: cutting and speed ramps, compositing a clip into a template's
phone, caption crossfades, end card, audio, App Store preview encoding, GIFs and website loops.

Templates are plain HTML (`docs/marketing/templates/`, `docs/store/app-store/creative/`) that load
[`template.js`](../../docs/marketing/templates/template.js). For each video it renders the template
once as a background and once per caption, and asks the template (`?video`) where its
`data-video` phone sits, including scale and rotation. A template needs no other changes to get a
video variant.

## `posts.py`

Renders a kit's post drafts for `build_kit.py` (see [Posts](#posts)). It has no command line of
its own.

## `render_images.py`

Renders HTML templates to PNG with headless Chrome, then checks size and that there's no alpha
channel. Works on Windows and macOS.

```
python tool/marketing/render_images.py                      # all assets
python tool/marketing/render_images.py appstore-search      # one asset
```

| Asset | Template | Output |
|---|---|---|
| `appstore-search` | `docs/store/app-store/creative/search_3x2.html` | `search_{en-US,de-DE}.png` next to the template, 3840×2560 |
| `appstore-header` | `docs/store/app-store/creative/header_21x9.html` | `header_{en-US,de-DE}.png` next to the template, 3840×1646 |

New template: add an entry to `ASSETS` (template, size, output file → URL query). Kit images
(carousel, thumbnail, OG image, forum header) are rendered by `build_kit.py` instead.

## `assets/`

- `badges/`: the official "Download on the App Store" and "Get it on Google Play" badges (English),
  used unmodified on end cards and the carousel.
- `music/`: the music bed, gitignored.
