# Marketing tooling

Scripts for the marketing plan in [#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69)
and its follow-up [#77](https://github.com/jonaskeller14/bike_setup_tracker/issues/77). Working docs
live in [`docs/marketing/`](../../docs/marketing/README.md); the look is in
[`docs/marketing/brand.md`](../../docs/marketing/brand.md).

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
python tool/marketing/build_kit.py appstore                 # App Store previews + header and search videos
python tool/marketing/build_kit.py launch post              # only rewrite POST.md after editing posts
python tool/marketing/build_kit.py launch sheet             # only rewrite the contact sheet
```

Parts: `shorts`, `walkthrough`, `gifs`, `web`, `images`, `appstore`. A full run clears the kit folder and
writes `POST.md` (file list, Shorts titles, YouTube chapter timestamps, warnings, links to the
`posts/` files), `manifest.json` and the contact sheet `sheet.html`. A partial run replaces only its own files. `post` and `sheet` run alone
from `manifest.json`: `post` rewrites `POST.md` and `posts/`, so edited posts don't need a rebuild; `sheet` rewrites `sheet.html`. The script exits 1 and prints `FAIL` lines when an output misses its
spec. The launch kit takes about 10 minutes on an M-series Mac.

**Contact sheet** (`sheet.html`, the maintainer's review page): every image of the kit, and three
frames of every video (at 15 %, 50 % and the end card), grouped by folder. A checkbox draws each
format's safe areas (`render_images.SAFE_AREAS`); a click opens the full file.

| Part | Output | Spec checked |
|---|---|---|
| `shorts` | `shorts/<name>_9x16.mp4` | 1080×1920, ≤60 s, audio track |
| `walkthrough` | `walkthrough_16x9.mp4` | 1920×1080, every chapter ≥10 s |
| `gifs` | `gif/<clip>.gif` | ≤8 MB (steps down from 360 px / 15 fps) |
| `web` | `web/<clip>.webp`, `web/<clip>_still.webp` | lossy animated WebP, 400 px, 12 fps, ≤2 MB each; the still is the last frame |
| `images` | `carousel/NN.png` (4:5), `square/NN.png` (1:1), `thumb.png`, `og.png`, `og_de-DE.png`, `forum_header.png` | size, RGB, ≤10 slides, text inside the safe area |
| `appstore` | `preview_N.mp4` (also copied to `docs/store/app-store/app_previews/en-US/iphone_65/` when it passes), `header_{en-US,de-DE}.mp4`, `search_{en-US,de-DE}.mp4` | 886×1920 15–30 s with audio; 3840×1646 and 2880×1920, 5–30 s |

Every still the kit renders, video backgrounds and caption layers included, goes through
`render_images.render`, so a caption that doesn't fit its box or leaves the safe area fails the
build.

### Recordings

- Demo clips: `tool/screenshots/run_ios.sh iphone --demo` → `build/marketing/raw/ios/demo_*.mp4`
  (the `launch` kit's `recordings` folder). The templates use the iPhone frame, whose screen hole
  is exactly the Simulator's 1320×2868, so nothing is cropped. `run_android.sh --demo` records the
  same flows to `build/marketing/raw/` (1080×2400); a kit plays them in the Android frame with
  `"recordings": "build/marketing/raw"` and `"device": "android"`.
- App Store previews and the search video: the `appstore` kit cuts the same demo clips
  (`"recordings": "build/marketing/raw/ios"`). `run_ios.sh iphone --preview` still records the
  `preview_*.yaml` flows to `build/store_previews/iphone/`, for a kit that sets `source`.
- Maestro needs Java 17+ on `PATH` (see `tool/screenshots/README.md`).

The simulators only write a frame when the screen changes, and the last frames before a still
screen can be missing. That's why demo flows end with `_stop_recording.yaml`, which presses
Volume Up (Android) or Home (iOS). `render_video.recording_end` finds where the volume panel or
home animation starts (the end of the last frame gap of ≥1 s) and every demo clip is cut there.
`preview_setup.yaml` doesn't end that way, so its last transition is missing; edit around it.

### Kit file

```jsonc
{
  "device": "android",           // optional: Android frame and Play raws in every template; default iPhone
  "endcard": { "signature": "…", "note": "…" },  // optional; defaults "78 psi. 4 clicks. Saved." / "Free on iOS and Android"
  "music": "track.mp3",          // in tool/marketing/assets/music/ (gitignored); missing → silent track
  "recordings": "build/marketing/raw/ios",  // where clips without "source" are read; default build/marketing/raw
  "clips": {
    "demo_add_setup": {
      "source": "build/…/x.mp4",  // optional; default <recordings>/<name>.mp4
      "title": "Record a Setup",  // walkthrough chapter
      "segments": [[0, 4, 1.5], [4, 11, 2.5]],  // [start, end, speed] in recording seconds; the rest is cut
      "captions": [[0, "Log Your *Setup*"], [4, "…"]],  // [recording second, text]; *key phrase* teal, {10} a changed value
      "callouts": [  // optional, brand.md Callouts; recording seconds and recording pixels
        {"t0": 3, "t1": 6, "rect": [560, 1100, 500, 160], "mode": "zoom"},   // eases into the rect and out
        {"t0": 12, "t1": 16, "rect": [30, 1000, 1020, 160], "mode": "lift"}  // floats the element, 1.6×, above the phone
      ]
    }
  },
  "shorts": { "core": { "title": "…", "clips": ["…"], "hook": "replaces the first caption" } },
  "walkthrough": ["clip", "…"],
  "gifs": ["clip", "…"],
  "web": ["clip", "…"],         // website loops, see the website repo's CLAUDE.md
  "images": {
    // Slides: URL parameters of post_4x5.html (carousel) or post_1x1.html (square); {"kind": "endcard"} is the end card.
    "carousel": [{ "kind": "cover|screen|changed|tip|release", "title": "…", "sub": "…", "shots": "04" }],
    "square": [ … ],
    // banner.html at 1280×720, 1200×630, 1920×640.
    "thumbnail": { "title": "…", "shots": "04", "lift": "x,y,w,h", "dark": "" }, "og": { … }, "og_de": { … }, "forum_header": { … }
  },
  "appstore": {
    "previews": [["clip", "clip"], ["clip"]],  // preview_1, preview_2, …: clips crossfaded into one, 15–30 s
    "header": [[0, 1.5], [1, 0.8], [3, 5]],    // header video: [step, seconds] frames of header_21x9.html?step=N, crossfaded, looping
    "creative": "clip"                         // plays in the search asset's phone
  }
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

The ffmpeg side of `build_kit.py`: cutting and speed ramps, callouts, compositing a clip into a
template's phone, caption crossfades, end card, audio, App Store preview encoding, GIFs and website
loops.

Templates are plain HTML (`docs/marketing/templates/`, `docs/store/app-store/creative/`) that load
[`template.js`](../../docs/marketing/templates/template.js). For each video it renders the template
once as a background and once per caption, and asks the template (`?video`) where its
`data-video` phone sits, including scale and rotation. A template needs no other changes to get a
video variant.

A template without a phone (the App Store header) is animated instead: `animate` renders it once
per `?step=N` and crossfades the frames, then fades back to the first so the video loops.
`[data-step]` elements above N are hidden but keep their space, so nothing reflows between frames.
`join` crossfades several cut clips (0.4 s) into one take, e.g. an App Store preview.

Callouts (`brand.md`, Callouts) ease in and out over 0.4 s:
- `zoom` runs on the cut clip, before compositing, so GIFs and web loops zoom too. It scales every
  frame (smooth, unlike `zoompan`'s whole-pixel steps) and fits the rect with a 10 % margin; a rect
  as wide as the screen doesn't zoom.
- `lift` runs in the composite: the element is cropped from the live recording, grows from its size
  in the phone to 1.6× (less if it wouldn't fit the safe area), with a 2 px ink border and a soft
  shadow, centered on the element and kept inside the format's safe area. Needs an unrotated phone.

## `posts.py`

Renders a kit's post drafts for `build_kit.py` (see [Posts](#posts)). It has no command line of
its own.

## `render_images.py`

Renders HTML templates to PNG with headless Chrome, then checks size, that there's no alpha
channel (RGB, as the stores need), and, for pages that load `template.js`, that all text fits its
box and sits inside the format's safe area. Works on Windows and macOS.

```
python tool/marketing/render_images.py                      # all assets
python tool/marketing/render_images.py appstore-search      # one asset
python tool/marketing/render_images.py --safe play-feature  # plus overlay renders in build/marketing/safe/
```

| Asset | Template | Output |
|---|---|---|
| `appstore-search` | `docs/store/app-store/creative/search_3x2.html` | `search_{en-US,de-DE}.png` next to the template, 3840×2560 |
| `appstore-header` | `docs/store/app-store/creative/header_21x9.html` | `header_{en-US,de-DE}.png` next to the template, 3840×1646 |
| `play-feature` | `docs/store/play-store/feature_graphic.html` | `metadata/{en-US,de-DE}/images/featureGraphic.png`, 1024×500 |
| `android-frame` | `tool/marketing/assets/frames/android.svg` | `android.png` next to it, 1184×2504 with transparency |

The store assets render into tracked files; commit them only once they're live (see
`docs/store/app-store/creative/README.md`). New template: add an entry to `ASSETS` (template, size,
output file → URL query). Kit images are rendered by `build_kit.py` instead.

**Safe areas** (`SAFE_AREAS`, per format; brand.md, Grid and safe areas): text must sit inside
`safe` and outside every `avoid` area (what a platform covers, e.g. the Shorts action buttons);
`guides` are only drawn (Apple's art safe area on the search asset). `template.js` draws them with
`?safe=` and reports problems with `&check`; text marked `data-decor` (the brand row on 9:16, which
a platform's top bar may cover) is exempt. Glyph boxes include side bearings, so the check allows
3 % of the font size at the edges.

Headless Chrome's viewport is 87 px shorter than `--window-size`, so templates never read the
window size: `render_images.page_url` passes `size=WxH`, and `template.js` sizes the page from it.

## Templates

In `docs/marketing/templates/`, styled by `marketing.css` (the brand tokens) and filled by
`template.js` (URL parameters, device frame, callouts on stills, safe-area check). Each file's
header lists its parameters.

| Template | Sizes | Use |
|---|---|---|
| `video_9x16.html` | 1080×1920 | Shorts, Reels, TikTok background |
| `video_16x9.html` | 1920×1080 | YouTube walkthrough background |
| `endcard.html` | 1080×1920, 1920×1080, 1080×1350, 1080×1080 | End card of every video and the last slide |
| `post_4x5.html` | 1080×1350 | Instagram carousel and feed: `cover`, `screen`, `changed`, `tip`, `release` |
| `post_1x1.html` | 1080×1080 | YouTube community posts, X, Mastodon: the same kinds, the phone always whole |
| `banner.html` | 1280×720, 1200×630, 1920×640 | Thumbnail v2 (`?dark`, `?lift=`, `?bg=`), OG image, forum header |
| `channel_art.html` | 2560×1440, 800×800, 1080×1080 | YouTube banner, avatar, Instagram highlight cover |

Shared parameters: `device=android`, `shots=04`, `bg=<repo path>` (background image slot),
`zoom=`/`lift=x,y,w,h` (still callouts, raw-screenshot pixels), `lang=de`, `kind=`, `size=`.
Preview one in Chrome, e.g.
`docs/marketing/templates/post_4x5.html?kind=changed&field=Fork%20·%20Rebound&from=9&to=10`.

## `assets/`

- `badges/`: the official "Download on the App Store" and "Get it on Google Play" badges (English),
  used unmodified on end cards.
- `frames/`: the Android phone frame (`android.svg`, rendered to `android.png`), current Pixel
  style with a 1080×2400 screen hole for the phone AVD's recordings and the Play raws. Its display
  corners match the SDK's `pixel_8` emulator skin (same display size). The iPhone frame is
  `docs/store/app-store/iPhone-17-Pro-Max/frame.png`.
- `music/`: the music bed, gitignored.
