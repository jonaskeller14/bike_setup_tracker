# Motion compositions

Every new Short renders with [Hyperframes](https://github.com/heygen-com/hyperframes): HTML and a GSAP
timeline, rendered frame by frame in headless Chrome. The kit's `"motion"` names the composition; clip
cuts, voice, music and the end card stay in `build_kit.py`. The look is in
[`../brand.md`](../brand.md), Motion; the tooling in
[`tool/marketing/README.md`](../../../tool/marketing/README.md), Motion.

## Which composition

| `"motion"` | When | Work |
|---|---|---|
| `standard.html` | The screen explains itself: brand row, captions word by word, the whole phone, lift callouts | None beyond the kit: filled in from its clips, voice, captions and callouts; with a `.words.json` its captions follow the voice |
| `<short>.html` | A concept needs explaining before the phone makes sense, or the Short needs a camera move, boxes or an arrow | Hand-written, one file per Short, like [`restore.html`](restore.html) |

Start from `standard.html`. Write a custom one only when the Short needs it. Kits without `"motion"`,
which are older kits only, keep the previous look. Zoom callouts are cut into the clip, so they work in
both; a custom composition draws its own lifts and boxes.

## Writing a custom one

1. Record the flow and get the voice first (`/marketingkit`). Times come from the MP3 and the recording.
2. Read the line and word times: `python3 tool/marketing/voice.py <kit>/batch-N --words`, which also writes the
   tracked `batch-N.words.json`. Set the kit's `voice.at` with gaps of about 0.3 s, shorter than the take's pauses.
3. Sample the recording on the cut's timeline: `-vf "fps=30,trim=A:B,setpts=PTS-STARTPTS,fps=10,…"`.
   Input seeking is about a second off on these recordings. Then choose `segments` so each tap lands on the
   word that names it.
4. Set `data-start` and `data-duration` of `#recording` and the root's `data-duration` to match; the build
   fails if the cut's length differs.
5. Look at it: `python3 tool/marketing/build_kit.py <kit> preview [short]`, the picture only.
6. Build it, then check the frames at 1–2 fps and at full size. Write every number down in the file's
   header comment, so the next change doesn't start from zero.

### Contract

- Load `marketing.css`, `motion.css`, `gsap.min.js` and `motion.js` from `assets/`. `Motion.create()` gives
  `tl`, `word`, `words`, `caption`, `leave` and `finish`; call `finish()` last.
- For words in sync with the voice, add `<script>window.VOICE = {{VOICE}};</script>` before `motion.js`. Then
  `say(target, line, end, start)` shows a caption's words as voice line `line` says them (`start: 0` for a hook, whose
  first word sits on frame 0), and `when(line, word, nth)` gives the second a word is said, to time a drawing to it.
  Times then follow the kit's `voice.at`, so they don't need rewriting.
- A caption's words match the voice line in order; a word the voice doesn't say follows the one before it. Use the
  spoken words where they're short enough, especially in hooks. A sentence not worth reading stays voice only.
- A Short with several clips joins them with a crossfade into the one `recording.mp4`.
- One paused timeline, and everything visible depends only on its time: no `Date.now()`, timers, unseeded
  `Math.random()`, network or `repeat: -1`. Finite repeats are fine.
- Animate transforms and opacity, never `left`, `top`, `width` or `height`, and don't put a CSS `transform`
  on an element GSAP moves. `.phone` scales itself, so move its parent `#move`.
- Time the `<video>`, not a wrapper. It stays `muted`: the build adds the sound.
- Text outside the safe area fails the build at any moment of the timeline, overshoots included. Mark
  decoration with `data-decor`.
- No template literals in `querySelector` in a composition: `hyperframes check` treats them as an error.

### What this has taught us

- **Draw a line with `clip-path`:** `inset(-40px 100% -40px 0)` to `inset(-40px 0% -40px 0)`. A
  `strokeDashoffset` tween with `pathLength` popped in all at once.
- **Shake with `immediateRender: false`** on a `fromTo`, or the element sits at its start value until the
  shake begins. Shake a whole line: shaking one part of it opens a gap.
- **Pop a right-aligned value towards the left** (`transformOrigin: 'right bottom'`), or it overshoots into
  the platforms' button zone.
- **Recording pixels to the frame:** `phone left + (75 + x) × s` and `phone top + (66 + y) × s`, with
  `s = pw / 1470 × camera scale`. Inside `.screen`, boxes use recording pixels directly and follow the phone.
- **Keep the moves few.** Show the real screen instead of a drawn copy: a list of names without context
  confused viewers. Boxes on the real tiles and one arrow said it better than camera pans.
- **Hold the payoff.** Leave at least 0.6 s after a value lands before the scene leaves: 9→10 for 0.35 s read as a flicker.
- **A word's sync shows the gap before it.** A caption that starts on a word said late sits empty until then. Keep the line's first words in it.
- **Write for the ear.** A take trails off at the end of a long line; a short clause there gets lost.
- **Check every direction a line claims.** Clicks count from closed: fewer compression clicks are firmer.
