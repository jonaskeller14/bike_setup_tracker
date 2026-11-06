"""Voiceover takes for marketing videos: splits a speechma batch into its lines (#77).

A batch is `<name>.md` (the text pasted into speechma, in its ```text block) and `<name>.mp3` (what
it generated) in tool/marketing/assets/voice/<folder>/. The text is paragraphs separated by blank lines; a paragraph
"Clip N." is a slate that starts take N. speechma pauses about 1.2 s at a blank line and less inside
a paragraph, so a batch with P paragraphs is split at its P - 1 longest pauses. Slates are dropped.

A line is referenced as `<batch>#<clip>` (every paragraph of the take) or `<batch>#<clip>.<n>`
(its n-th paragraph, from 1).

Usage: python tool/marketing/voice.py <folder>/<batch>   e.g. 03_features/batch-2
Prints every take with its paragraphs, their times in the batch and their length.

With --words it also runs whisper-cli (`brew install whisper-cpp`; the model is WHISPER_MODEL, by default
~/.cache/whisper/ggml-small.en.bin) and writes <batch>.words.json next to the MP3: when each word of the pasted
text starts, in batch seconds. Whisper only supplies the times, so a word it mishears still shows as written, and
its misses are listed. The file is tracked, so a build needs neither Whisper nor a new run.
"""

import difflib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import render_images
import render_video as rv

VOICE = render_images.REPO_ROOT / "tool/marketing/assets/voice"
SILENCE = "silencedetect=noise=-40dB:d=0.25"
# Finer than SILENCE: the pause after a comma, where a word's start can be measured instead of estimated.
SHORT_PAUSE = "silencedetect=noise=-35dB:d=0.06"
WHISPER_MODEL = Path(os.environ.get("WHISPER_MODEL", Path.home() / ".cache/whisper/ggml-small.en.bin"))
WHISPER_DTW = "small.en"
SLATE = re.compile(r"Clip (\d+)\.")
REF = re.compile(r"(?P<batch>[\w.-]+)#(?P<clip>\d+)(?:\.(?P<line>\d+))?")
TEXT_BLOCK = re.compile(r"^```text\n(.*?)^```", re.MULTILINE | re.DOTALL)


def paragraphs(text):
    return [" ".join(p.split()) for p in re.split(r"\n\s*\n", text.strip()) if p.strip()]


def silence_marks(mp3, detect):
    result = rv.subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(mp3), "-af", detect, "-f", "null", "-"],
        capture_output=True, text=True)
    return re.findall(r"silence_(start|end): ([0-9.]+)", result.stderr)


def speech_spans(mp3):
    """(start, end) of every stretch of speech between pauses, in batch seconds."""
    marks = silence_marks(mp3, SILENCE)
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


def spoken_key(word):
    return re.sub(r"[^\w]", "", word).lower()


ONES = "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen".split()
TENS = "- - twenty thirty forty fifty sixty seventy eighty ninety".split()


def spoken_number(digits):
    """The keys of a whole number under 1000 as a voice says it; ninety-three stays one word, as written."""
    n = int(digits)
    keys = []
    if n >= 100:
        keys += [ONES[n // 100], "hundred"]
        n %= 100
    if n >= 20:
        keys.append(TENS[n // 10] + (ONES[n % 10] if n % 10 else ""))
    elif n or not keys:
        keys.append(ONES[n])
    return keys


def heard_keys(word):
    """What Whisper's word sounds like as script keys: it writes numbers in digits, "2.4" for "two point four"."""
    number = re.fullmatch(r"(\d{1,3})(?:\.(\d+))?\W*", word)
    if not number:
        return [spoken_key(word)]
    keys = spoken_number(number[1])
    if number[2]:
        keys += ["point", *(ONES[int(d)] for d in number[2])]
    return keys


def heard_words(mp3):
    """[(word, end)] as Whisper hears them. DTW times mark where a token ends; plain Whisper times can be a second off."""
    if not WHISPER_MODEL.is_file():
        raise SystemExit(f"Missing the Whisper model {WHISPER_MODEL}. See tool/marketing/README.md, Voiceover.")
    with tempfile.TemporaryDirectory() as folder:
        wav = Path(folder) / "voice.wav"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(mp3), "-ar", "16000", "-ac", "1", str(wav)], check=True)
        subprocess.run(["whisper-cli", "-m", str(WHISPER_MODEL), "--dtw", WHISPER_DTW, "-nfa", "-f", str(wav),
                        "-ojf", "-of", str(wav.with_suffix("")), "-np"], check=True, capture_output=True)
        result = json.loads(wav.with_suffix(".json").read_text(encoding="utf-8"))
    words = []
    for segment in result["transcription"]:
        for token in segment["tokens"]:
            text = token["text"]
            if text.startswith("["):
                continue
            if text.startswith(" ") or not words:
                words.append([text.strip(), token["t_dtw"] / 100])
            else:
                words[-1][0] += text
                # A comma's own time can lie far behind the word.
                if re.search(r"\w", text):
                    words[-1][1] = token["t_dtw"] / 100
    return words


def word_starts(line_start, line_end, ends, pauses):
    """When each word of a line starts: where the word before it ended, or where a pause between them ends.
    ends: each word's end, None where Whisper missed it; a missed word is spread evenly between its neighbours."""
    starts = [line_start] + [None] * (len(ends) - 1)
    for i in range(1, len(ends)):
        if ends[i - 1] is None:
            continue
        start = ends[i - 1]
        limit = (ends[i] if ends[i] is not None else line_end) - 0.08
        starts[i] = next((p for p in pauses if start - 0.02 < p < limit), start)
    i = 1
    while i < len(starts):
        if starts[i] is not None:
            i += 1
            continue
        j = next((k for k in range(i, len(starts)) if starts[k] is not None), None)
        right = starts[j] if j is not None else line_end
        stop = j if j is not None else len(starts)
        for k in range(i, stop):
            starts[k] = starts[i - 1] + (right - starts[i - 1]) * (k - i + 1) / (stop - i + 1)
        i = stop
    for i in range(1, len(starts)):
        starts[i] = min(max(starts[i], starts[i - 1]), line_end)
    return [round(start, 3) for start in starts]


def align(batch):
    """({clip: [[(word, start)] per line]}, words Whisper missed), in batch seconds."""
    heard = heard_words(batch.mp3)
    pauses = [float(t) for kind, t in silence_marks(batch.mp3, SHORT_PAUSE) if kind == "end"]
    script = [word for lines in batch.takes.values() for _, _, text in lines for word in text.split()]
    # Only a number's last word has a time of its own; the words before it are spread evenly.
    keys, key_ends = [], []
    for word, end in heard:
        said = heard_keys(word)
        keys += said
        key_ends += [None] * (len(said) - 1) + [end]
    matcher = difflib.SequenceMatcher(None, [spoken_key(w) for w in script], keys, autojunk=False)
    ends = [None] * len(script)
    found = [False] * len(script)
    for block in matcher.get_matching_blocks():
        for k in range(block.size):
            ends[block.a + k] = key_ends[block.b + k]
            found[block.a + k] = True
    words, missed, i = {}, [], 0
    for clip, lines in batch.takes.items():
        words[clip] = []
        for start, end, text in lines:
            line = text.split()
            line_ends = ends[i:i + len(line)]
            missed += [w for w, heard_it in zip(line, found[i:i + len(line)]) if not heard_it]
            words[clip].append(list(zip(line, word_starts(start, end, line_ends, pauses))))
            i += len(line)
    return words, missed


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

    def words_of(self, clip, index):
        """[(word, seconds after the line starts)] of a take's line, or None without a words file."""
        path = self.mp3.with_suffix(".words.json")
        if not path.is_file():
            return None
        saved = json.loads(path.read_text(encoding="utf-8"))
        if saved["mp3Bytes"] != self.mp3.stat().st_size:
            raise SystemExit(f"{path.name} doesn't belong to this MP3. Run voice.py {self.mp3.parent.name}/{self.name} --words.")
        line_start = self.takes[clip][index][0]
        return [(word, start - line_start) for word, start in saved["clips"][str(clip)][index]]


class Voice:
    """Resolves line references of one folder; batches are split once."""

    def __init__(self, folder):
        self.folder = VOICE / folder
        self._batches = {}

    def batch(self, name):
        if name not in self._batches:
            self._batches[name] = Batch(self.folder / name)
        return self._batches[name]

    def resolved(self, refs):
        """(batch, clip, line index in the take) for each line the references name, in order."""
        out = []
        for ref in refs:
            match = REF.fullmatch(ref)
            if not match:
                raise ValueError(f"voice line '{ref}': expected <batch>#<clip> or <batch>#<clip>.<n>")
            batch = self.batch(match["batch"])
            clip = int(match["clip"])
            take = batch.takes.get(clip)
            if take is None:
                raise ValueError(f"voice line '{ref}': {batch.name} has no clip {match['clip']}")
            indices = range(len(take))
            if match["line"]:
                n = int(match["line"])
                if not 1 <= n <= len(take):
                    raise ValueError(f"voice line '{ref}': clip {match['clip']} has {len(take)} paragraphs")
                indices = [n - 1]
            out += [(batch, clip, i) for i in indices]
        return out

    def lines(self, refs):
        """[(mp3, start, end, text)] in batch seconds, for each reference in order."""
        return [(batch.mp3, *batch.takes[clip][i]) for batch, clip, i in self.resolved(refs)]

    def words(self, refs):
        """Per line of lines(refs): [(word, seconds after the line starts)], or None without a words file."""
        return [batch.words_of(clip, i) for batch, clip, i in self.resolved(refs)]


def main(argv):
    with_words = "--words" in argv
    argv = [arg for arg in argv if arg != "--words"]
    if len(argv) != 1:
        print(__doc__)
        return 2
    batch = Batch(VOICE / argv[0])
    words, missed = align(batch) if with_words else ({}, [])
    for clip, lines in batch.takes.items():
        length = lines[-1][1] - lines[0][0]
        print(f"Clip {clip}: {length:.1f} s")
        for n, (start, end, text) in enumerate(lines, 1):
            print(f"  {n}. {start:7.2f}–{end:7.2f} ({end - start:4.1f} s)  {text}")
            if with_words:
                print("      " + " ".join(f"{word}@{at:.2f}" for word, at in words[clip][n - 1]))
    if with_words:
        out = batch.mp3.with_suffix(".words.json")
        out.write_text(json.dumps({"mp3Bytes": batch.mp3.stat().st_size, "clips": {str(c): w for c, w in words.items()}},
                                  ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"Wrote {out.name}. Whisper missed: {', '.join(missed) or 'nothing'}. Listen to a take where it missed a lot.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
