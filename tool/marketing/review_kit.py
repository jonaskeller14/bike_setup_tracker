"""Writes a review checklist for a built content kit: build/marketing/<kit>/review.html.

Usage: python tool/marketing/review_kit.py <kit> [--compare <kit>] [--items <file.json>] [--open]

Reads what the last full `build_kit.py <kit>` run wrote (manifest.json) plus the kit file, and shows
every output as one item: Shorts with their hook, captions and callouts, the walkthrough, App Store
videos, images, GIFs, website loops (next to the same loop of the --compare kit) and the post
drafts, grouped by video. Hooks are looked up in docs/marketing/messaging.md; the ones missing from
its committed version are listed as new. --items adds kit-specific entries, such as open decisions:
a JSON list of {"key", "title", "html"}.

The maintainer ticks what's fine and writes notes, which stay in the browser (localStorage).
"Copy feedback" puts the whole list on the clipboard as Markdown, with each item's key, so the
feedback can be pasted to Claude Code (see .claude/commands/reviewkit.md). The page is temporary:
build/ is gitignored.
"""

import html
import json
import re
import subprocess
import sys
import webbrowser

import render_images
import render_video as rv

REPO_ROOT = render_images.REPO_ROOT
KITS = REPO_ROOT / "docs/marketing/kits"
BUILD = REPO_ROOT / "build/marketing"
MESSAGING = "docs/marketing/messaging.md"
BANK_ROW = re.compile(r"^\| ([A-Z]\d+) \| (.+?) \| (.+?) \|$", re.MULTILINE)
CAPTION_MARKUP = re.compile(r"[*{}]")


def esc(text):
    return html.escape(str(text))


def styled(text):
    """Caption markup as the templates show it: *key phrase* teal, {10} orange."""
    out = esc(text.replace(" ", " "))
    out = re.sub(r"\*(.+?)\*", r'<span class="teal">\1</span>', out)
    return re.sub(r"\{(.+?)\}", r'<span class="orange">\1</span>', out)


def plain(text):
    return CAPTION_MARKUP.sub("", text).replace(" ", " ").strip()


def bank(text):
    """{EN headline: (id, DE headline)} from a messaging.md text."""
    return {en.strip(): (hid, de.strip()) for hid, en, de in BANK_ROW.findall(text)}


def committed_bank():
    result = subprocess.run(["git", "show", f"HEAD:{MESSAGING}"], cwd=REPO_ROOT, capture_output=True, text=True)
    return bank(result.stdout) if result.returncode == 0 else {}


def size_mb(path):
    return path.stat().st_size / 1024 / 1024


def item(key, title, body, kind=""):
    return f"""
<article class="item {kind}" data-key="{esc(key)}">
  <header><label class="check"><input type="checkbox" data-ok> <span>{title}</span></label><span class="state"></span></header>
  <div class="body">{body}</div>
  <textarea data-note placeholder="Feedback (empty = fine)"></textarea>
</article>"""


class Review:
    def __init__(self, kit, compare=None, extra_items=()):
        self.kit = kit
        self.spec = json.loads((KITS / f"{kit}.json").read_text(encoding="utf-8"))
        self.out = BUILD / kit
        manifest = self.out / "manifest.json"
        if not manifest.is_file():
            raise SystemExit(f"No {manifest.relative_to(REPO_ROOT)}. Run a full `build_kit.py {kit}` first.")
        self.files = [name for name, _ in json.loads(manifest.read_text(encoding="utf-8"))["files"]]
        self.compare = compare
        self.extra_items = list(extra_items)
        self.bank = bank((REPO_ROOT / MESSAGING).read_text(encoding="utf-8"))
        self.old_bank = committed_bank()
        self.sections = []

    def matching(self, pattern):
        return [name for name in self.files if re.fullmatch(pattern, name)]

    def add(self, sid, title, intro, cards):
        if cards:
            self.sections.append((sid, title, intro, "".join(cards)))

    def video(self, name, extra=""):
        path = self.out / name
        return (f'<video src="{esc(name)}#t=1" controls preload="auto" playsinline></video>'
                f'<p class="muted">{rv.duration(path):.1f} s{extra}</p>')

    def clip_rows(self, clip):
        spec = self.spec.get("clips", {}).get(clip, {})
        rows = [f'<li class="clip">{esc(clip)}</li>']
        rows += [f"<li><code>{t:g}s</code> {styled(text)}</li>" for t, text in spec.get("captions", [])]
        rows += [f'<li class="muted">{esc(c["mode"])} {c["t0"]:g}–{c["t1"]:g} s, rect {esc(c["rect"])}</li>'
                 for c in spec.get("callouts", [])]
        return rows

    def hook_line(self, hook):
        hid = self.bank.get(plain(hook), ("not in the bank", ""))[0]
        return f"<li><b>Hook ({esc(hid)}):</b> {styled(hook)}</li>"

    def shorts(self):
        cards = []
        for name, short in self.spec.get("shorts", {}).items():
            file = f"shorts/{name}_9x16.mp4"
            if file not in self.files:
                continue
            rows = [self.hook_line(short["hook"])] if short.get("hook") else []
            for clip in short["clips"]:
                rows += self.clip_rows(clip)
            body = f"""<div class="split"><div class="player">{self.video(file)}</div><div class="meta">
<p class="muted">Title: <b>{esc(short.get("title", ""))}</b></p><ol class="captions">{"".join(rows)}</ol>
<p class="muted">Times are seconds in each clip's recording. Check the hook, captions, callout, payoff and end card.</p></div></div>"""
            cards.append(item(f"short:{name}", f"Short · {esc(name)}", body, "video"))
        self.add("shorts", f"Shorts ({len(cards)})", "Watch each one, ideally on a phone in daylight.", cards)

    def walkthrough(self):
        if "walkthrough_16x9.mp4" not in self.files:
            return
        rows = []
        for clip in self.spec.get("walkthrough", []):
            rows += self.clip_rows(clip)
        body = f'{self.video("walkthrough_16x9.mp4")}<ol class="captions">{"".join(rows)}</ol>'
        self.add("walkthrough", "Walkthrough", "", [item("walkthrough", "Walkthrough 16:9", body, "wide")])

    def appstore(self):
        cards = []
        previews = self.spec.get("appstore", {}).get("previews", [])
        for name in self.matching(r"(preview_\d+|header_[\w-]+|search_[\w-]+)\.mp4"):
            match = re.fullmatch(r"preview_(\d+)\.mp4", name)
            rows = []
            if match and int(match[1]) <= len(previews):
                for clip in previews[int(match[1]) - 1]:
                    rows += self.clip_rows(clip)
            body = f'{self.video(name)}<ol class="captions">{"".join(rows)}</ol>'
            cards.append(item(f"appstore:{name}", esc(name), body, "video"))
        self.add("appstore", f"App Store videos ({len(cards)})", "Previews, header and search asset videos.", cards)

    def hooks(self):
        cards = []
        seen = set()
        for name, short in self.spec.get("shorts", {}).items():
            hook = plain(short.get("hook", ""))
            if not hook or hook in seen:
                continue
            seen.add(hook)
            hid, de = self.bank.get(hook, ("?", ""))
            new = hook not in self.old_bank
            body = (f"<p><b>EN</b> {esc(hook)}<br><b>DE</b> {esc(de) or '—'}</p>"
                    f'<p class="muted">Used by the {esc(name)} Short.{" New in messaging.md." if new else ""}'
                    f'{" Not in the headline bank yet." if hid == "?" else ""}</p>')
            cards.append(item(f"hook:{hid if hid != '?' else name}", f"Hook {esc(hid)}{' (new)' if new else ''}", body, "compact"))
        self.add("hooks", f"Hooks ({len(cards)})", f"From <code>{MESSAGING}</code>: bike context in every line.", cards)

    def posts(self):
        posts = sorted((self.out / "posts").glob("*.md"))
        if not posts:
            return
        groups = {}
        for path in posts:
            text = path.read_text(encoding="utf-8")
            heading = text.splitlines()[0].lstrip("# ").strip()
            video = re.search(r"(\w+)_(?:9x16|16x9)\.mp4", heading)
            group = video[1] if video else heading
            fields = [(f, t) for f, t in re.findall(r"^## (.+?)\n```text\n(.*?)\n```", text, re.MULTILINE | re.DOTALL)
                      if not f.startswith("Pinned comment")]
            inner = "".join(f"<h4>{esc(f)}</h4><pre>{esc(t)}</pre>" for f, t in fields)
            groups.setdefault(group, []).append(f"<details><summary>{esc(heading)}</summary>{inner}</details>")
        cards = [item(f"posts:{group}", f"Posts · {esc(group)} ({len(blocks)})", "".join(blocks)) for group, blocks in groups.items()]
        self.add("posts", f"Post drafts ({len(posts)})",
                 f"Source: <code>docs/marketing/kits/{esc(self.kit)}.posts.md</code>. Pinned comments (campaign links) "
                 "aren't shown. Check tone, claims (a logbook, not a tuner), opt-in and Strava notes.", cards)

    def images(self):
        cards = []
        for name in self.matching(r"[^/]+\.png|(carousel|square)/\d+\.png"):
            cards.append(item(f"image:{name}", esc(name), f'<img class="still" src="{esc(name)}" alt="" loading="lazy">', "media"))
        self.add("images", f"Images ({len(cards)})", "", cards)

    def gifs(self):
        cards = []
        for name in self.matching(r"gif/[\w-]+\.gif"):
            body = f'<img class="gif" src="{esc(name)}" alt="" loading="lazy"><p class="muted">{size_mb(self.out / name):.1f} MB</p>'
            cards.append(item(f"gif:{name[4:-4]}", esc(name[4:-4]), body, "media"))
        self.add("gifs", f"GIFs ({len(cards)})", "Screen only, no captions.", cards)

    def web(self):
        names = [n for n in self.matching(r"web/[\w-]+\.webp") if not n.endswith("_still.webp")]
        cards, total = [], 0.0
        for name in names:
            total += size_mb(self.out / name)
            new = f'<figure><img src="{esc(name)}" alt="" loading="lazy"><figcaption>{esc(self.kit)} · {size_mb(self.out / name):.1f} MB</figcaption></figure>'
            old = ""
            if self.compare:
                path = BUILD / self.compare / name
                old = (f'<figure><img src="../{esc(self.compare)}/{esc(name)}" alt="" loading="lazy"><figcaption>{esc(self.compare)} · {size_mb(path):.1f} MB</figcaption></figure>'
                       if path.is_file() else f'<figure class="none"><figcaption>not in {esc(self.compare)}</figcaption></figure>')
            body = f'<div class="pair">{old}{new}</div><p class="muted">Zoom in (⌘+ / Ctrl+) to judge edges and small text.</p>'
            cards.append(item(f"web:{name[4:-5]}", esc(name[4:-5]), body, "media wide" if self.compare else "media"))
        self.add("web", f"Website loops ({len(cards)}, {total:.1f} MB together)",
                 f"{rv.WEB_WIDTH} px, {rv.WEB_FPS} fps, q{rv.WEB_QUALITY}.", cards)

    def extra(self):
        cards = [item(entry["key"], esc(entry["title"]), entry["html"], "compact") for entry in self.extra_items]
        self.add("other", "Decisions and other changes", "", cards)

    def write(self):
        for part in (self.shorts, self.walkthrough, self.appstore, self.hooks, self.posts, self.images, self.gifs,
                     self.web, self.extra):
            part()
        nav = "".join(f'<a href="#{sid}">{esc(title.split(" (")[0])}</a>' for sid, title, _, _ in self.sections)
        content = "".join(f'<section id="{sid}"><h2>{esc(title)}</h2><p class="intro">{intro}</p><div class="grid">{cards}</div></section>'
                          for sid, title, intro, cards in self.sections)
        built = (self.out / "manifest.json").stat().st_mtime_ns
        page = (PAGE.replace("{kit}", esc(self.kit)).replace("{nav}", nav).replace("{content}", content)
                .replace("{storage_key}", f"review-{self.kit}-{built}"))
        path = self.out / "review.html"
        path.write_text(page, encoding="utf-8")
        return path


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kit review: {kit}</title>
<style>
  :root { --bg: #f6f6f4; --card: #fff; --ink: #0a0a0a; --muted: #666; --line: #ddd; --teal: #106681; --orange: #ef6c00; --ok: #2e7d32; --note: #b26a00; }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #141414; --card: #1e1e1e; --ink: #f2f2f2; --muted: #a0a0a0; --line: #333; --teal: #5bb8d4; --orange: #ffb74d; --ok: #81c784; --note: #ffb74d; }
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--ink); font: 15px/1.45 system-ui, -apple-system, sans-serif; }
  .top { position: sticky; top: 0; z-index: 5; background: var(--bg); border-bottom: 1px solid var(--line); padding: 12px 16px; display: flex; flex-wrap: wrap; gap: 8px 16px; align-items: center; }
  .top h1 { margin: 0; font-size: 18px; }
  .top nav { display: flex; flex-wrap: wrap; gap: 4px 12px; font-size: 14px; }
  .top nav a { color: var(--teal); text-decoration: none; }
  .progress { font-variant-numeric: tabular-nums; color: var(--muted); }
  .actions { margin-left: auto; display: flex; gap: 8px; }
  button { font: inherit; padding: 6px 12px; border: 1px solid var(--ink); background: var(--card); color: var(--ink); cursor: pointer; }
  button.primary { background: var(--ink); color: var(--bg); }
  main { max-width: 1400px; margin: 0 auto; padding: 8px 16px 64px; }
  h2 { margin: 32px 0 4px; font-size: 20px; }
  .intro { margin: 0 0 12px; color: var(--muted); }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 420px), 1fr)); gap: 16px; }
  #shorts .grid { grid-template-columns: repeat(auto-fill, minmax(min(100%, 560px), 1fr)); }
  .item { background: var(--card); border: 1px solid var(--line); padding: 12px; display: flex; flex-direction: column; gap: 8px; min-width: 0; }
  .item.wide { grid-column: span 2; }
  @media (max-width: 900px) { .item.wide { grid-column: auto; } }
  .item.ok { border-color: var(--ok); }
  .item.has-note { border-color: var(--note); }
  .item header { display: flex; align-items: center; gap: 8px; }
  .check { display: flex; gap: 8px; align-items: center; font-weight: 600; cursor: pointer; }
  .check input { width: 18px; height: 18px; }
  .state { margin-left: auto; font-size: 12px; text-transform: uppercase; letter-spacing: .05em; }
  .item.ok .state::after { content: "approved"; color: var(--ok); }
  .item.has-note .state::after { content: "feedback"; color: var(--note); }
  textarea { width: 100%; min-height: 56px; resize: vertical; font: inherit; padding: 8px; background: var(--bg); color: var(--ink); border: 1px solid var(--line); }
  video { width: 100%; max-width: 220px; background: #000; display: block; }
  .wide video, #appstore video { max-width: 100%; }
  .split { display: flex; gap: 12px; align-items: flex-start; flex-wrap: wrap; }
  .player { flex: 0 0 220px; max-width: 100%; }
  .meta { flex: 1 1 240px; min-width: 0; }
  .captions { margin: 8px 0; padding-left: 0; list-style: none; }
  .captions li { margin: 2px 0; }
  .captions li.clip { margin-top: 8px; font: 12px ui-monospace, monospace; color: var(--muted); }
  .teal { color: var(--teal); font-weight: 700; }
  .orange { color: var(--orange); font-weight: 700; }
  .muted { color: var(--muted); font-size: 13px; margin: 4px 0; }
  code { font-size: 12px; }
  details { border-top: 1px solid var(--line); padding: 6px 0; }
  summary { cursor: pointer; font-weight: 600; }
  h4 { margin: 8px 0 2px; font-size: 13px; color: var(--muted); }
  pre { white-space: pre-wrap; word-break: break-word; margin: 0; padding: 8px; background: var(--bg); font: 13px/1.4 ui-monospace, monospace; }
  .gif { width: 100%; max-width: 240px; display: block; }
  .still { width: 100%; display: block; border: 1px solid var(--line); }
  .pair { display: flex; gap: 12px; flex-wrap: wrap; }
  .pair figure { margin: 0; flex: 1 1 200px; min-width: 0; }
  .pair img { width: 100%; max-width: 320px; display: block; }
  .pair figcaption { color: var(--muted); font-size: 13px; }
  .pair .none { display: grid; place-items: center; min-height: 120px; border: 1px dashed var(--line); }
  #out { position: fixed; inset: auto 16px 16px 16px; max-height: 50vh; display: none; background: var(--card); border: 1px solid var(--ink); padding: 12px; z-index: 10; }
  #out.show { display: flex; flex-direction: column; gap: 8px; }
  #out textarea { min-height: 30vh; font: 13px ui-monospace, monospace; }
</style>
</head>
<body>
<div class="top">
  <h1>Kit review: {kit}</h1>
  <nav>{nav}</nav>
  <span class="progress" id="progress"></span>
  <div class="actions">
    <button id="reset" type="button">Reset</button>
    <button id="export" class="primary" type="button">Copy feedback</button>
  </div>
</div>
<main>
<p class="muted">Temporary page (<code>build/</code> is gitignored), written by <code>tool/marketing/review_kit.py</code>. Tick what's fine, write notes where it isn't, then <b>Copy feedback</b> and paste it into Claude Code. Your input is kept in this browser until the kit is rebuilt.</p>
{content}
</main>
<div id="out"><b>Feedback (copied to the clipboard)</b><textarea id="outText" readonly></textarea><button type="button" id="close">Close</button></div>
<script>
  const KEY = '{storage_key}';
  let state = {};
  try { state = JSON.parse(localStorage.getItem(KEY) || '{}'); } catch (e) { state = {}; }
  const items = [...document.querySelectorAll('.item')];
  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} }
  function paint(el) {
    const s = state[el.dataset.key] || {};
    el.classList.toggle('ok', !!s.ok && !s.note);
    el.classList.toggle('has-note', !!s.note);
  }
  function progress() {
    const done = items.filter((el) => { const s = state[el.dataset.key] || {}; return s.ok || s.note; }).length;
    document.getElementById('progress').textContent = `${done} / ${items.length} reviewed`;
  }
  for (const el of items) {
    const s = state[el.dataset.key] || {};
    const box = el.querySelector('[data-ok]');
    const note = el.querySelector('[data-note]');
    box.checked = !!s.ok;
    note.value = s.note || '';
    box.addEventListener('change', () => { state[el.dataset.key] = { ...state[el.dataset.key], ok: box.checked }; save(); paint(el); progress(); });
    note.addEventListener('input', () => { state[el.dataset.key] = { ...state[el.dataset.key], note: note.value.trim() }; save(); paint(el); progress(); });
    paint(el);
  }
  progress();
  document.getElementById('export').addEventListener('click', async () => {
    const lines = [`Review feedback, kit {kit}`, ''];
    let section = '';
    for (const el of items) {
      const h = el.closest('section').querySelector('h2').textContent;
      if (h !== section) { section = h; lines.push(`## ${h}`); }
      const s = state[el.dataset.key] || {};
      const title = el.querySelector('.check span').textContent;
      const mark = s.note ? 'FEEDBACK' : s.ok ? 'ok' : 'not reviewed';
      lines.push(`- [${mark}] ${title} (${el.dataset.key})${s.note ? ': ' + s.note.replace(/\\n+/g, ' / ') : ''}`);
    }
    const text = lines.join('\\n');
    document.getElementById('outText').value = text;
    document.getElementById('out').classList.add('show');
    try { await navigator.clipboard.writeText(text); } catch (e) {}
  });
  document.getElementById('close').addEventListener('click', () => document.getElementById('out').classList.remove('show'));
  document.getElementById('reset').addEventListener('click', () => {
    if (!confirm('Clear all ticks and notes?')) return;
    state = {}; save();
    for (const el of items) { el.querySelector('[data-ok]').checked = false; el.querySelector('[data-note]').value = ''; paint(el); }
    progress();
  });
</script>
</body>
</html>
"""


def main(argv):
    args = list(argv)
    if not args or args[0].startswith("-"):
        print(__doc__)
        return 2
    kit, compare, items_file, open_page = args.pop(0), None, None, False
    while args:
        flag = args.pop(0)
        if flag == "--compare" and args:
            compare = args.pop(0)
        elif flag == "--items" and args:
            items_file = args.pop(0)
        elif flag == "--open":
            open_page = True
        else:
            print(f"Unknown argument: {flag}")
            return 2
    if not (KITS / f"{kit}.json").is_file():
        print(f"Unknown kit '{kit}'. Known: {', '.join(sorted(p.stem for p in KITS.glob('*.json')))}")
        return 2
    extra = json.loads(open(items_file, encoding="utf-8").read()) if items_file else []
    path = Review(kit, compare, extra).write()
    print(f"OK   {path.relative_to(REPO_ROOT).as_posix()}")
    if open_page:
        webbrowser.open(path.as_uri())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
