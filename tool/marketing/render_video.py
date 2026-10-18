"""Turns screen recordings into marketing videos, GIFs and website loops with ffmpeg (Windows and macOS).

Library for build_kit.py. Backgrounds, captions and end cards are HTML templates rendered with
headless Chrome (render_images.py), not ffmpeg text: common ffmpeg builds (Homebrew's among
them) have neither libass nor drawtext, and Chrome draws the same fonts as the images. A
template marks the phone that plays the recording with data-video; with ?video it hides that
phone and reports where it sits (docs/marketing/templates/template.js).
"""

import html
import json
import math
import re
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlencode, urlparse
from urllib.request import url2pathname

import render_images

FPS = 30
CAPTION_FADE = 0.25
# Callouts (brand.md, Callouts): ease in and out over CALLOUT_EASE s; a lift is shown LIFT_SCALE×
# its size in the phone (template.js uses the same factor for stills).
CALLOUT_EASE = 0.4
LIFT_SCALE = 1.6
INK = "0x0A0A0A"
END_CARD_SECONDS = 2.0
END_CARD_FADE = 0.4
MUSIC_CROSSFADE = 4.0
GIF_LIMIT = 8 * 1024 * 1024
# (fps, width) tried in order until a GIF fits GIF_LIMIT.
GIF_STEPS = [(15, 360), (12, 320), (10, 270)]
# Website loops: lossy animated WebP, about a quarter of the GIF's size.
WEB_FPS = 12
WEB_WIDTH = 400
WEB_QUALITY = 55
WEB_STILL_QUALITY = 75

# Near-lossless intermediates; only the final files are encoded for delivery.
INTERMEDIATE = ["-c:v", "libx264", "-preset", "fast", "-crf", "12", "-pix_fmt", "yuv420p"]
DELIVERY = ["-c:v", "libx264", "-preset", "medium", "-crf", "18", "-profile:v", "high", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart"]


def ffmpeg(*args):
    result = subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *map(str, args)],
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise RuntimeError(f"ffmpeg failed:\n{result.stderr.strip()[-3000:]}")


def libwebp(tool, *args, cwd=None):
    result = subprocess.run([tool, *map(str, args)], capture_output=True, text=True, cwd=cwd)
    if result.returncode:
        raise RuntimeError(f"{tool} failed:\n{result.stderr.strip()[-3000:]}")


def ffprobe(path, *args):
    return subprocess.run(
        ["ffprobe", "-v", "error", *args, "-of", "csv=p=0", str(path)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout


def duration(path):
    return float(ffprobe(path, "-show_entries", "format=duration"))


def video_size(path):
    width, height = ffprobe(path, "-select_streams", "v:0", "-show_entries", "stream=width,height").split(",")
    return int(width), int(height)


def has_audio(path):
    return bool(ffprobe(path, "-select_streams", "a", "-show_entries", "stream=index").strip())


def recording_end(path):
    """Where a demo clip ends, before the key press of _stop_recording.yaml.

    The encoder only writes a frame when the screen changes. The flow holds its final screen
    (a gap of at least 1 s between frames), then presses Volume Up (Android) or Home (iOS); the
    first frame of the volume panel or home animation ends that gap. A lone frame written after
    it settles is ignored.
    """
    times = [float(t.strip(",")) for t in ffprobe(path, "-select_streams", "v:0", "-show_entries", "frame=pts_time").split()]
    times = times[:-1]
    ends = [b for a, b in zip(times, times[1:]) if b - a >= 1.0]
    if not ends:
        raise ValueError(f"{path}: no final hold before the volume panel found")
    return ends[-1]


class Edit:
    """Which parts of a recording to keep and how fast.

    segments: (start, end, speed) in recording seconds; anything outside them is cut.
    captions: (recording second, text); each shows until the next one or the end of the clip.
    callouts: {"t0", "t1", "rect": [x, y, w, h], "mode": "zoom" | "lift"}, in recording seconds and
    recording pixels.
    """

    def __init__(self, segments, captions=(), callouts=()):
        self.segments = [(float(a), float(b), float(s)) for a, b, s in segments]
        self.captions = [(float(t), text) for t, text in captions]
        self.callouts = list(callouts)

    def out_time(self, t):
        """Maps a recording second to the edited clip; a cut second maps to the next kept one."""
        elapsed = 0.0
        for start, end, speed in self.segments:
            if t < start:
                return elapsed
            if t <= end:
                return elapsed + (t - start) / speed
            elapsed += (end - start) / speed
        return elapsed

    def callout_spans(self, mode):
        """(start, end, rect) in edited seconds of the callouts of one mode."""
        return [(self.out_time(c["t0"]), self.out_time(c["t1"]), c["rect"])
                for c in self.callouts if c["mode"] == mode]

    def caption_spans(self, length):
        """(start, end, text) in edited seconds, without empty captions."""
        starts = [(self.out_time(t), text) for t, text in self.captions]
        spans = []
        for i, (start, text) in enumerate(starts):
            end = starts[i + 1][0] if i + 1 < len(starts) else length
            if text and end - start > 0.05:
                spans.append((start, min(end, length), text))
        return spans


def prepare(source, edit, out):
    """Cuts and speeds up a recording into a constant-frame-rate clip without audio."""
    n = len(edit.segments)
    graph = [f"[0:v]fps={FPS},split={n}" + "".join(f"[s{i}]" for i in range(n))]
    for i, (start, end, speed) in enumerate(edit.segments):
        graph.append(f"[s{i}]trim=start={start}:end={end},setpts=(PTS-STARTPTS)/{speed}[v{i}]")
    graph.append("".join(f"[v{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=0,fps={FPS}[out]")
    out.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg("-i", source, "-filter_complex", ";".join(graph), "-map", "[out]", *INTERMEDIATE, out)
    return duration(out)


def ease(start, end):
    """ffmpeg expression of t: 0 outside [start, end], rising to 1 over CALLOUT_EASE at both ends."""
    p = f"clip(min(t-{start:.3f},{end:.3f}-t)/{CALLOUT_EASE},0,1)"
    return f"({p}*{p}*(3-2*{p}))"


def zoom(clip, spans, out):
    """Eases into each (start, end, [x, y, w, h]) rect of the clip and back out, at the clip's size.

    The zoom fits the rect with a 10 % margin. scale runs per frame, so the zoom is smooth rather
    than stepping by whole source pixels like zoompan.
    """
    width, height = video_size(clip)
    z, cx, cy = "1", f"{width / 2}", f"{height / 2}"
    for start, end, (x, y, w, h) in spans:
        e = ease(start, end)
        target = max(1.0, 0.9 * min(width / w, height / h))
        z += f"+{target - 1:.4f}*{e}"
        cx += f"+{x + w / 2 - width / 2:.1f}*{e}"
        cy += f"+{y + h / 2 - height / 2:.1f}*{e}"
    z = f"({z})"
    # The rect's center moves to the frame's center, as far as the zoomed frame allows.
    crop_x = f"clip(({cx})*{z}-{width / 2},0,{width}*{z}-{width})"
    crop_y = f"clip(({cy})*{z}-{height / 2},0,{height}*{z}-{height})"
    ffmpeg("-i", clip, "-vf",
           f"scale=w='2*trunc({width}*{z}/2)':h='2*trunc({height}*{z}/2)':eval=frame:flags=bicubic,"
           f"crop=w={width}:h={height}:x='{crop_x}':y='{crop_y}':exact=1",
           *INTERMEDIATE, out)
    return duration(out)


def load_layout(chrome, template, size, query):
    """Asks the template where its data-video phone sits (template.js, ?video)."""
    url = render_images.page_url(template, size, query)
    dom = subprocess.run(
        [str(chrome), "--headless", "--hide-scrollbars", "--force-device-scale-factor=1",
         f"--window-size={size[0]},{size[1]}", "--virtual-time-budget=5000", "--dump-dom", url],
        capture_output=True,
        text=True,
        timeout=120,
    ).stdout
    match = re.search(r'data-layout="([^"]*)"', dom)
    if not match:
        raise RuntimeError(f"{template}: no data-layout; does a .phone have data-video and load template.js?")
    layout = json.loads(html.unescape(match.group(1)))
    layout["frame"] = Path(url2pathname(urlparse(layout["frame"]).path))
    return layout


def make_mask(path, width, height, radius):
    """White rounded rectangle on black: the alpha of the phone screen."""
    r = max(radius, 0.5)
    inside = f"lte(hypot(max(0,max({r}-X,X-{width - 1 - r})),max(0,max({r}-Y,Y-{height - 1 - r}))),{r})"
    ffmpeg("-f", "lavfi", "-i", f"color=c=black:s={width}x{height}",
           "-vf", f"format=gray,geq=lum='255*{inside}'", "-frames:v", "1", path)


def compose(chrome, template, size, clip, params, captions, out, out_size=None, lifts=()):
    """Puts a clip into the template's phone, over the rendered background.

    params: URL parameters of the background; captions: (start, end, extra parameters) layers,
    each a full background render faded in and out over the base; lifts: (start, end, rect) lift
    callouts in clip seconds and recording pixels. Writes a video-only intermediate and returns
    its length.
    """
    work = out.with_suffix("")
    work.mkdir(parents=True, exist_ok=True)
    length = duration(clip)

    def query(extra=None):
        return "?" + urlencode({**params, **(extra or {}), "video": ""})

    layout = load_layout(chrome, template, size, query())
    pngs = {work / "base.png": query()}
    for i, (_, _, extra) in enumerate(captions):
        pngs[work / f"layer{i}.png"] = query(extra)
    problems = render_images.render(chrome, template, size, pngs)
    if problems:
        raise RuntimeError("; ".join(problems))

    scale = layout["scale"]
    phone_w, phone_h = (round(v * scale) for v in layout["size"])
    sx, sy, sw, sh = (round(v * scale) for v in layout["screen"])
    mask = work / "mask.png"
    make_mask(mask, sw, sh, layout["radius"] * scale)

    still = ["-loop", "1", "-framerate", FPS, "-t", f"{length:.3f}", "-i"]
    inputs = [*still, work / "base.png", "-i", clip, "-loop", "1", "-i", layout["frame"], "-loop", "1", "-i", mask]
    graph = [
        f"[1:v]split={1 + len(lifts)}[recording]" + "".join(f"[lift_src{i}]" for i in range(len(lifts))),
        f"[recording]scale={sw}:{sh}:force_original_aspect_ratio=increase,crop={sw}:{sh},format=rgba[screen]",
        "[3:v]format=gray[mask]",
        "[screen][mask]alphamerge[screen_alpha]",
        f"[2:v]scale={phone_w}:{phone_h},format=rgba[frame]",
        f"color=c=black@0:s={phone_w}x{phone_h}:r={FPS},format=rgba[blank]",
        f"[blank][screen_alpha]overlay={sx}:{sy}:shortest=1[phone_screen]",
        "[phone_screen][frame]overlay=0:0[phone_flat]",
    ]
    if abs(layout["angle"]) > 0.01:
        a = math.radians(layout["angle"])
        graph.append(f"[phone_flat]rotate={a:.5f}:c=none:ow=rotw({a:.5f}):oh=roth({a:.5f})[phone]")
    else:
        graph.append("[phone_flat]null[phone]")

    current = "0:v"
    for i, (start, end, _) in enumerate(captions):
        inputs += [*still, work / f"layer{i}.png"]
        fades = ""
        if start > 0:
            fades += f",fade=t=in:st={start:.3f}:d={CAPTION_FADE}:alpha=1"
        if end < length - 0.05:
            fades += f",fade=t=out:st={end - CAPTION_FADE:.3f}:d={CAPTION_FADE}:alpha=1"
        graph.append(f"[{4 + i}:v]format=rgba{fades}[layer{i}]")
        graph.append(f"[{current}][layer{i}]overlay=enable='between(t,{start:.3f},{end:.3f})'[bg{i}]")
        current = f"bg{i}"

    cx, cy = layout["center"]
    graph.append(f"[{current}][phone]overlay=x={cx:.1f}-overlay_w/2:y={cy:.1f}-overlay_h/2:shortest=1[composed]")
    current = "composed"
    if lifts:
        if abs(layout["angle"]) > 0.01:
            raise ValueError(f"{template}: lift callouts need an unrotated phone")
        current = add_lifts(graph, current, lifts, size,
                            (cx - phone_w / 2 + sx, cy - phone_h / 2 + sy, sw / video_size(clip)[0]))
    final = f"[{current}]null"
    if out_size:
        final += f",scale={out_size[0]}:{out_size[1]}:flags=lanczos"
    graph.append(final + f",fps={FPS},format=yuv420p[out]")
    ffmpeg(*inputs, "-filter_complex", ";".join(graph), "-map", "[out]", "-t", f"{length:.3f}", *INTERMEDIATE, out)
    return duration(out)


def add_lifts(graph, current, lifts, size, screen):
    """Appends one lift layer per (start, end, [x, y, w, h]) to the filter graph; returns its output.

    screen: (left, top, scale) of the phone screen in the frame. The element grows from its size
    in the phone to LIFT_SCALE× (less if that doesn't fit the safe area) while it fades in, with a
    2 px ink border and a soft shadow, and stays centered on the element, inside the format's safe
    area.
    """
    left, top, scale = screen
    safe = render_images.SAFE_AREAS.get(tuple(size), {}).get("safe", (24, 24, size[0] - 48, size[1] - 48))
    blur = max(4, round(size[0] * .025))
    for i, (start, end, (x, y, w, h)) in enumerate(lifts):
        # A wide element grows less, so it still fits the safe area.
        lift = min(LIFT_SCALE, (safe[2] - 4) / (w * scale), (safe[3] - 4) / (h * scale))
        lw, lh = (2 * round(v * scale * lift / 2) for v in (w, h))
        bw, bh = lw + 4, lh + 4
        cx = min(max(left + (x + w / 2) * scale, safe[0] + bw / 2), safe[0] + safe[2] - bw / 2)
        cy = min(max(top + (y + h / 2) * scale, safe[1] + bh / 2), safe[1] + safe[3] - bh / 2)
        e = ease(start, end)
        grow = f"({1 / lift:.4f}+{1 - 1 / lift:.4f}*{e})"
        graph += [
            f"[lift_src{i}]crop={w}:{h}:{x}:{y},scale={lw}:{lh}:flags=lanczos,pad={bw}:{bh}:2:2:color={INK},"
            f"format=rgba[lift_box{i}]",
            f"color=c=black@0.28:s={bw}x{bh}:r={FPS},format=rgba,pad={bw + 4 * blur}:{bh + 4 * blur}:"
            f"{2 * blur}:{2 * blur + blur // 2}:color=black@0,boxblur=luma_radius=0:chroma_radius=0:"
            f"alpha_radius={blur}:alpha_power=2[lift_shadow{i}]",
            f"[lift_shadow{i}][lift_box{i}]overlay={2 * blur}:{2 * blur}:shortest=1,"
            f"scale=w='2*trunc(iw*{grow}/2)':h='2*trunc(ih*{grow}/2)':eval=frame,"
            f"fade=t=in:st={start:.3f}:d={CALLOUT_EASE}:alpha=1,"
            f"fade=t=out:st={end - CALLOUT_EASE:.3f}:d={CALLOUT_EASE}:alpha=1[lift{i}]",
            f"[{current}][lift{i}]overlay=x='{cx:.1f}-overlay_w/2':y='{cy:.1f}-overlay_h/2':eval=frame:"
            f"enable='between(t,{start:.3f},{end:.3f})'[lifted{i}]",
        ]
        current = f"lifted{i}"
    return current


def render_still(chrome, template, size, params, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    problems = render_images.render(chrome, template, size, {out: "?" + urlencode(params)})
    if problems:
        raise RuntimeError("; ".join(problems))


def assemble(segments, out, end_card=None, music=None, audio=True):
    """Joins video-only segments, crossfades into the end card still and adds audio.

    audio: the music bed (looped, faded, loudness-normalized) if music is given, else a silent
    stereo track. Returns the length.
    """
    inputs = []
    for segment in segments:
        inputs += ["-i", segment]
    n = len(segments)
    total = sum(duration(s) for s in segments)
    graph = ["".join(f"[{i}:v]" for i in range(n)) + f"concat=n={n}:v=1:a=0,settb=AVTB,fps={FPS}[main]"]
    if end_card:
        inputs += ["-loop", "1", "-framerate", FPS, "-t", END_CARD_SECONDS + END_CARD_FADE, "-i", end_card]
        graph.append(f"[{n}:v]format=yuv420p,settb=AVTB,fps={FPS}[card]")
        graph.append(f"[main][card]xfade=transition=fade:duration={END_CARD_FADE}:offset={total - END_CARD_FADE:.3f}[v]")
        total += END_CARD_SECONDS
        n += 1
    else:
        graph.append("[main]null[v]")

    maps = ["-map", "[v]"]
    if audio:
        if music:
            # A video longer than the track repeats it. Silence at both ends is cut and the
            # repeats crossfade, so the seam has no gap.
            copies = max(1, math.ceil((total + MUSIC_CROSSFADE) / (duration(music) - 2 * MUSIC_CROSSFADE)))
            trim_silence = "silenceremove=start_periods=1:start_threshold=-50dB"
            inputs += ["-i", music]
            graph.append(f"[{n}:a]{trim_silence},areverse,{trim_silence},areverse,asplit={copies}"
                         + "".join(f"[m{i}]" for i in range(copies)))
            looped = "m0"
            for i in range(1, copies):
                graph.append(f"[{looped}][m{i}]acrossfade=d={MUSIC_CROSSFADE}[loop{i}]")
                looped = f"loop{i}"
            graph.append(f"[{looped}]atrim=0:{total:.3f},asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1.5,"
                         f"afade=t=in:d=0.5,afade=t=out:st={total - 2:.3f}:d=2,"
                         "aformat=sample_rates=48000:channel_layouts=stereo[a]")
        else:
            graph.append(f"anullsrc=r=48000:cl=stereo,atrim=0:{total:.3f}[a]")
        maps += ["-map", "[a]", "-c:a", "aac", "-b:a", "192k"]
    out.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg(*inputs, "-filter_complex", ";".join(graph), *maps, "-t", f"{total:.3f}", *DELIVERY, out)
    return duration(out)


def animate(chrome, template, size, steps, out, out_size=None):
    """A video of template renders that crossfade into each other, for pages without a recording.

    steps: (URL parameters, seconds shown) in order; the video then fades back into the first
    step, so it loops without a jump. Writes a video-only intermediate and returns its length.
    """
    work = out.with_suffix("")
    work.mkdir(parents=True, exist_ok=True)
    pngs = {work / f"step{i}.png": "?" + urlencode(params) for i, (params, _) in enumerate(steps)}
    problems = render_images.render(chrome, template, size, pngs)
    if problems:
        raise RuntimeError("; ".join(problems))
    inputs = []
    for path, (_, seconds) in zip([*pngs, next(iter(pngs))], [*steps, (None, 0)]):
        inputs += ["-loop", "1", "-framerate", FPS, "-t", f"{seconds + CAPTION_FADE:.3f}", "-i", path]
    graph = [f"[{i}:v]format=yuv420p,settb=AVTB,fps={FPS}[s{i}]" for i in range(len(steps) + 1)]
    current, offset = "s0", 0.0
    for i, (_, seconds) in enumerate(steps, 1):
        offset += seconds
        graph.append(f"[{current}][s{i}]xfade=transition=fade:duration={CAPTION_FADE}:offset={offset:.3f}[x{i}]")
        current = f"x{i}"
    scale = f",scale={out_size[0]}:{out_size[1]}:flags=lanczos" if out_size else ""
    graph.append(f"[{current}]null{scale}[out]")
    length = offset + CAPTION_FADE
    ffmpeg(*inputs, "-filter_complex", ";".join(graph), "-map", "[out]", "-t", f"{length:.3f}", *INTERMEDIATE, out)
    return duration(out)


def join(clips, out, fade=0.4):
    """Crossfades prepared clips of the same size into one video-only intermediate; returns its length."""
    out.parent.mkdir(parents=True, exist_ok=True)
    if len(clips) == 1:
        shutil.copyfile(clips[0], out)
        return duration(out)
    inputs = []
    for clip in clips:
        inputs += ["-i", clip]
    graph = [f"[{i}:v]settb=AVTB,fps={FPS}[c{i}]" for i in range(len(clips))]
    current, offset = "c0", 0.0
    for i, clip in enumerate(clips[1:], 1):
        offset += duration(clips[i - 1]) - fade
        graph.append(f"[{current}][c{i}]xfade=transition=fade:duration={fade}:offset={offset:.3f}[j{i}]")
        current = f"j{i}"
    graph.append(f"[{current}]null[out]")
    ffmpeg(*inputs, "-filter_complex", ";".join(graph), "-map", "[out]", *INTERMEDIATE, out)
    return duration(out)


def appstore_preview(clip, out, size=(886, 1920)):
    """App Store app preview: full-screen recording, H.264 High 4.0, silent stereo AAC track."""
    width, height = size
    out.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg("-i", clip, "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
           "-vf", f"scale={width}:{height}:force_original_aspect_ratio=increase:flags=lanczos,"
                  f"crop={width}:{height},fps={FPS},format=yuv420p",
           "-c:v", "libx264", "-profile:v", "high", "-level", "4.0", "-b:v", "10M", "-maxrate", "12M",
           "-bufsize", "24M", "-c:a", "aac", "-b:a", "256k", "-shortest", "-movflags", "+faststart", out)
    return duration(out)


def gif(clip, out):
    """Palette GIF of the screen alone; returns (fps, width) of the first step under GIF_LIMIT,
    or None if even the smallest is too big."""
    out.parent.mkdir(parents=True, exist_ok=True)
    for fps, width in GIF_STEPS:
        ffmpeg("-i", clip, "-filter_complex",
               f"[0:v]fps={fps},scale={width}:-2:flags=lanczos,split[a][b];"
               "[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle",
               out)
        if out.stat().st_size <= GIF_LIMIT:
            return fps, width
    return None


def web_loop(clip, work, out, still):
    """Animated WebP of the screen alone for the website, plus a still of its last frame that
    the page shows instead with prefers-reduced-motion. Needs img2webp and cwebp (libwebp)."""
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    ffmpeg("-i", clip, "-vf", f"fps={WEB_FPS},scale={WEB_WIDTH}:-2:flags=lanczos", work / "%04d.png")
    frames = sorted(p.name for p in work.glob("*.png"))
    # An argument file keeps the command line short enough for Windows.
    args = ["-loop", "0", "-lossy", "-q", WEB_QUALITY, "-d", round(1000 / WEB_FPS), *frames, "-o", out.resolve()]
    (work / "args.txt").write_text(" ".join(map(str, args)), encoding="utf-8")
    libwebp("img2webp", "args.txt", cwd=work)
    libwebp("cwebp", "-quiet", "-q", WEB_STILL_QUALITY, work / frames[-1], "-o", still)
