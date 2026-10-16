"""Turns a kit's post drafts into the channel sections of POST.md (Phase 4 of #69).

Drafts live in docs/marketing/kits/<kit>.posts.md. Each `## <channel> · <label>` section is one
post; its `### <Field>` headings are followed by a ```text block with the text to paste. Prose
around the blocks is kept as posting notes. Placeholders anywhere in a section:

  {ios:<channel>} {android:<channel>}  campaign links from docs/marketing/links.md
  {smart:<channel>}                    the website smart link
  {version}                            the app version from pubspec.yaml
  {chapters}                           the walkthrough chapter timestamps

`[[...]]` marks something the maintainer fills in before posting. The limits below are the ones
documented in docs/marketing/channels.md.
"""

import re

import render_images

REPO_ROOT = render_images.REPO_ROOT
LINKS = REPO_ROOT / "docs/marketing/links.md"
PUBSPEC = REPO_ROOT / "pubspec.yaml"
SMART_LINK = "https://jonaskeller14.com/bike_setup_tracker/get?c={}"

# Channel id prefix: platform.
PLATFORMS = {"reddit-": "reddit", "yt-": "youtube", "ig-": "instagram", "tiktok": "tiktok"}
# Platform: {field: max characters}.
LIMITS = {
    "reddit": {"Title": 300, "Body": 40000},
    "youtube": {"Title": 100, "Description": 5000, "Tags": 500, "Post": 5000},
    "instagram": {"Bio": 150, "Caption": 2200},
    "tiktok": {"Bio": 80, "Caption": 2200},
}
# Platform: max hashtags per post (all fields of a section).
MAX_HASHTAGS = {"instagram": 5, "youtube": 60}

LINK_ROW = re.compile(r"^\| `([a-z0-9-]+)` \|.*?\]\((https://apps\.apple\.com[^)]+)\).*?\]\((https://play\.google\.com[^)]+)\)")
PLACEHOLDER = re.compile(r"\{(ios|android|smart):([a-z0-9-]+)\}")
LEFTOVER = re.compile(r"\{[a-z]+(?::[^}\s]*)?\}")
STORE_URL = re.compile(r"https://(?:apps\.apple\.com|play\.google\.com)[^\s)\]>]*")
FIELD = re.compile(r"^### ([^\n]+)\n((?:(?!#|```)[^\n]*\n)*?)```text\n(.*?)\n```", re.MULTILINE | re.DOTALL)
FILL_IN = re.compile(r"\[\[(.+?)\]\]")
HASHTAG = re.compile(r"(?<![\w&/])#\w+")


def load_links():
    """{channel: (iOS link, Android link)} from links.md."""
    links = {}
    for line in LINKS.read_text(encoding="utf-8").splitlines():
        match = LINK_ROW.match(line)
        if match:
            links[match[1]] = (match[2], match[3])
    return links


def app_version():
    match = re.search(r"^version: (\d+\.\d+\.\d+)", PUBSPEC.read_text(encoding="utf-8"), re.MULTILINE)
    return match[1]


def platform(channel):
    return next((name for prefix, name in PLATFORMS.items() if channel.startswith(prefix)), None)


def render(source, chapters):
    """(Markdown for POST.md, problems). Headings move down one level to nest under '## Posts'."""
    links = load_links()
    allowed = {url for pair in links.values() for url in pair}
    version = app_version()
    problems = []
    sections = re.split(r"^(?=## )", source, flags=re.MULTILINE)[1:]
    out = []
    for section in sections:
        heading = section.splitlines()[0]
        channel = heading[3:].split()[0]
        if channel not in links:
            problems.append(f"posts '{heading[3:]}': channel '{channel}' isn't in {LINKS.name}")

        def link(match):
            kind, target = match[1], match[2]
            if target not in links:
                return match[0]
            return SMART_LINK.format(target) if kind == "smart" else links[target][kind == "android"]

        text = PLACEHOLDER.sub(link, section).replace("{version}", version).replace("{chapters}", chapters)
        problems += [f"posts '{heading[3:]}': unresolved placeholder {p} (unknown name or channel)" for p in LEFTOVER.findall(text)]
        problems += [f"posts '{heading[3:]}': store link isn't a campaign link from {LINKS.name}: {url}"
                     for url in STORE_URL.findall(text) if url not in allowed]

        name = platform(channel)
        limits = LIMITS.get(name, {})
        hashtags = 0

        def annotate(match):
            nonlocal hashtags
            field, notes, value = match[1].strip(), match[2], match[3]
            hashtags += len(HASHTAG.findall(value))
            limit = limits.get(field)
            if limit and len(value) > limit:
                problems.append(f"posts '{heading[3:]}': {field} has {len(value)} characters, limit {limit}")
            if name == "youtube" and re.search(r"[<>]", value):
                problems.append(f"posts '{heading[3:]}': YouTube rejects < and > in the {field}")
            count = f"{len(value)}/{limit}" if limit else f"{len(value)} characters"
            return f"### {field} ({count})\n{notes}```text\n{value}\n```"

        text = FIELD.sub(annotate, text)
        if name in MAX_HASHTAGS and hashtags > MAX_HASHTAGS[name]:
            problems.append(f"posts '{heading[3:]}': {hashtags} hashtags, {name} allows {MAX_HASHTAGS[name]}")

        body = text.split("\n", 1)[1] if "\n" in text else ""
        lines = [heading, "", "- [ ] Posted"]
        lines += [f"- [ ] Fill in: {slot}" for slot in dict.fromkeys(FILL_IN.findall(body))]
        out.append("\n".join(lines) + "\n" + body.rstrip() + "\n")

    return demote("\n".join(out)), problems


def demote(markdown):
    """Adds one level to every heading outside fenced blocks."""
    lines, fenced = [], False
    for line in markdown.splitlines():
        if line.startswith("```"):
            fenced = not fenced
        lines.append("#" + line if not fenced and re.match(r"#{1,5} ", line) else line)
    return "\n".join(lines)
