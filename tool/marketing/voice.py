"""Voiceover takes for marketing videos: splits a speechma batch into its lines (#77).

A batch is `<name>.md` (the text pasted into speechma, in its ```text block) and `<name>.mp3` (what
it generated) in tool/marketing/assets/voice/<folder>/. The text is paragraphs separated by blank lines; a paragraph
"Clip N." is a slate that starts take N. speechma pauses about 1.2 s at a blank line and less inside
a paragraph, so a batch with P paragraphs is split at its P - 1 longest pauses. Slates are dropped.

A line is referenced as `<batch>#<clip>` (every paragraph of the take) or `<batch>#<clip>.<n>`
(its n-th paragraph, from 1).

Usage: python tool/marketing/voice.py <folder>/<batch>   e.g. 03_features/batch-2
Prints every take with its paragraphs, their times in the batch and their length.
"""

import re
import sys
from pathlib import Path

import render_images
import render_video as rv

VOICE = render_images.REPO_ROOT / "tool/marketing/assets/voice"
SILENCE = "silencedetect=noise=-40dB:d=0.25"
SLATE = re.compile(r"Clip (\d+)\.")
REF = re.compile(r"(?P<batch>[\w.-]+)#(?P<clip>\d+)(?:\.(?P<line>\d+))?")
TEXT_BLOCK = re.compile(r"^```text\n(.*?)^```", re.MULTILINE | re.DOTALL)


def paragraphs(text):
    return [" ".join(p.split()) for p in re.split(r"\n\s*\n", text.strip()) if p.strip()]


def speech_spans(mp3):
    """(start, end) of every stretch of speech between pauses, in batch seconds."""
    result = rv.subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(mp3), "-af", SILENCE, "-f", "null", "-"],
        capture_output=True, text=True)
    marks = re.findall(r"silence_(start|end): ([0-9.]+)", result.stderr)
    total = rv.duration(mp3)
    spans, start = [], 0.0
    for kind, t in marks:
        if kind == "start":
            if float(t) > start:
                spans.append((start, float(t)))
        else:
            start = float(t)
    if start < total - 0.05:
        spans.append((start, total))
    return spans


class Batch:
    """The takes of one batch: {clip number: [(start, end, text)]} in batch seconds."""

    def __init__(self, path):
        self.name = path.name
        self.mp3 = path.with_suffix(".mp3")
        md = path.with_suffix(".md")
        for file in (self.mp3, md):
            if not file.is_file():
                raise SystemExit(f"Missing {file.relative_to(render_images.REPO_ROOT).as_posix()}.")
        block = TEXT_BLOCK.search(md.read_text(encoding="utf-8"))
        if not block:
            raise ValueError(f"{md.name}: no ```text block with the pasted text")
        texts = paragraphs(block[1])
        spans = speech_spans(self.mp3)
        if len(spans) < len(texts):
            raise ValueError(f"{self.name}: {len(spans)} stretches of speech for {len(texts)} paragraphs")
        # The longest pauses are the paragraph breaks.
        pauses = sorted(range(1, len(spans)), key=lambda i: spans[i][0] - spans[i - 1][1], reverse=True)
        breaks = sorted(pauses[:len(texts) - 1])
        starts = [0, *breaks]
        ends = [*breaks, len(spans)]
        timed = [(spans[a][0], spans[b - 1][1], text) for a, b, text in zip(starts, ends, texts)]
        self.takes = {}
        current = None
        for start, end, text in timed:
            slate = SLATE.fullmatch(text)
            if slate:
                current = int(slate[1])
                self.takes[current] = []
            elif current is None:
                raise ValueError(f"{self.name}: text before the first slate")
            else:
                self.takes[current].append((start, end, text))
        if any(not lines for lines in self.takes.values()):
            raise ValueError(f"{self.name}: a slate without text")


class Voice:
    """Resolves line references of one folder; batches are split once."""

    def __init__(self, folder):
        self.folder = VOICE / folder
        self._batches = {}

    def batch(self, name):
        if name not in self._batches:
            self._batches[name] = Batch(self.folder / name)
        return self._batches[name]

    def lines(self, refs):
        """[(mp3, start, end, text)] in batch seconds, for each reference in order."""
        out = []
        for ref in refs:
            match = REF.fullmatch(ref)
            if not match:
                raise ValueError(f"voice line '{ref}': expected <batch>#<clip> or <batch>#<clip>.<n>")
            batch = self.batch(match["batch"])
            take = batch.takes.get(int(match["clip"]))
            if take is None:
                raise ValueError(f"voice line '{ref}': {batch.name} has no clip {match['clip']}")
            if match["line"]:
                n = int(match["line"])
                if not 1 <= n <= len(take):
                    raise ValueError(f"voice line '{ref}': clip {match['clip']} has {len(take)} paragraphs")
                take = [take[n - 1]]
            out += [(batch.mp3, start, end, text) for start, end, text in take]
        return out


def main(argv):
    if len(argv) != 1:
        print(__doc__)
        return 2
    batch = Batch(VOICE / argv[0])
    for clip, lines in batch.takes.items():
        length = lines[-1][1] - lines[0][0]
        print(f"Clip {clip}: {length:.1f} s")
        for n, (start, end, text) in enumerate(lines, 1):
            print(f"  {n}. {start:7.2f}–{end:7.2f} ({end - start:4.1f} s)  {text}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
