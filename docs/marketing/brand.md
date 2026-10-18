# Brand guide

How Bike Setup Tracker looks outside the app: store creative, Shorts, posts, thumbnails, the
website. Part of [#77](https://github.com/jonaskeller14/bike_setup_tracker/issues/77) Phase 1
(absorbs #69 Phase 10); what it says is in [`messaging.md`](messaging.md).

**Reference frames:** [`brand/reference/reference.html`](brand/reference/reference.html), the
direction picked on 2026-10-18 after two gallery rounds (renders attached to #77). Templates built
from Phase 2 on match these frames closely; this guide is the rulebook behind them. Open the page
in Chrome with `?surface=search|header|short|endcard|post|og` (add `&safe` for the safe area).

## The look in one paragraph

White paper, black ink, type-led. One heavy grotesk (Archivo) in sentence case, set very large
and tight, with small uppercase labels for metadata and black rules instead of boxes. The real
app screen sits in a real iPhone frame. Two colors, each with one job: **teal** for the key phrase
of a headline, **orange** for a value that changed, exactly as the app shows it. Lots of empty
space; nothing rounded that we draw ourselves. It should read like a bike magazine's data page,
not like an app ad.

## Where it comes from

The maintainer's references (2026-10-18). Links only; no third-party images in the repo.

| Reference | What we take |
|---|---|
| [BST Bazaine](https://fontsinuse.com/typefaces/230977/bst-bazaine) (Fonts In Use) | Neutral neo-grotesk, big lowercase wordmarks, black and white photography |
| [Install](https://fontsinuse.com/typefaces/247308/install) (Fonts In Use) | Heavy, compact display weight; posters where the type *is* the layout |
| [AC Youth](https://fontsinuse.com/typefaces/171194/ac-youth) (Fonts In Use) | Huge single words over a photo; covers in pure black and white |
| [Cartridge timeline portfolio](https://recent.design/i/a85mqyr-mobile-portfolio-with-cartridge-timeline) (recent.design) | A real phone on a neutral background; minimal UI chrome |
| [Zaro](https://land-book.com/websites/100967-zaro-make-your-company-ai-ready?view=mobile) (Land-book) | Tight sentence-case headlines, black square buttons, small labels |
| [The Raycast Keyboard](https://land-book.com/websites/100966-the-raycast-keyboard?view=mobile) (Land-book) | A product in focus, spec values as decoration, one accent |
| [Pip](https://land-book.com/websites/100833-pip-a-calm-to-do-list-and-notes-app-coming-soon?view=mobile) (Land-book) | Light page, very large tight headline, one small accent |
| [Nothin'](https://www.siteinspire.com/website/13633-nothin) (SiteInspire) | A wordmark that fills the width; corner metadata; black and white only |
| [The Future in Black](https://www.siteinspire.com/website/13635-the-future-in-black) (SiteInspire) | Heavy black headline as the main graphic element |
| [Banking app](https://dribbble.com/shots/25381404-Banking-Mobile-App), [Travel app](https://dribbble.com/shots/24911825-Travel-Mobile-App) (Dribbble) | Real screens in a device frame on a flat light background |
| [Button groups](https://www.cosmos.so/e/703012000) (Cosmos) | 1 px borders, square-ish components, one component in light and dark |
| The app icon | Black on white already; "78 PSI / 4 CLICKS" as the brand's own data voice |

What they share: monochrome first; sharp; extreme type contrast (huge headline, tiny labels);
flat, no gradients or glows; data as decoration. Not taken: rounded display faces (we take
Install's and AC Youth's weight, not their softness), dark backgrounds (round 2 moved to white:
store badges and screenshots read better on it), and illustrations (a drawn bike was tried twice
and dropped).

## Logo

- The clipboard mark from the app icon, black on white: `assets/icons/logo_1024.png`. It has a
  white background, so it sits on white paper only. On anything else use
  `logo_1024_white_transparent.png` (white), inverted with CSS `filter: invert(1)` for black.
- Next to the name: the mark is about 2× the name's cap height, with a gap of about ¼ mark width.
  The name is Archivo 800, −2 %.
- Minimum mark size: 56 px on 1080–1200 px wide frames, 96 px on the 3840 px header, 160 px on
  the 3840 px search asset.
- On end cards the bare mark is the hero, not the rounded icon tile.
- Never recolor the mark, add effects, or redraw it.

## Color

| Token | Value | Use |
|---|---|---|
| `paper` | `#FFFFFF` | Background. Always white; no dark variant of marketing assets |
| `ink` | `#0A0A0A` | Type, mark, rules, unchanged values |
| `muted` | `#6B6B6B` | Labels, the brand row's tagline, secondary lines |
| `headline` | `#106681` | **Only** the key phrase of a headline (the app's light primary) |
| `changed` | `#EF6C00` | **Only** a value that changed, e.g. the `10` in `9 → 10` (the app's `ValueHighlightColors.light.changed`) |

- A changed value is orange or ink, never teal, so it matches the orange the app screen shows next
  to it. The old value and the arrow stay `ink`.
- One teal phrase per headline: the bike-context words from messaging.md ("MTB suspension",
  "Fork and shock", "clicks"). The rest of the headline is `ink`.
- No other colors outside the screenshots: no gradients, no tinted backgrounds, no status colors.
- The App Store shows assets in light and dark mode; check every store asset on a dark surround
  too.

## Type

Archivo (Google Fonts), one family for everything.

| Role | Weight | Case | Tracking | Line height |
|---|---|---|---|---|
| Headline | 900 | Sentence case | −4.5 %, word spacing +8 % | 0.92 |
| Numbers (`9 → 10`) | 900, tabular | — | −4 % | 0.85 |
| Name / wordmark | 800 | Title case | −2 % | 1 |
| Label (metadata, value names) | 700 | UPPERCASE | +6 % | 1.2 |
| Body | 600 | Sentence case | 0 | 1.3 |

Uppercase is only for labels. Arrows are the `→` glyph, tight to the numbers on big numbers
(`9→10`), with spaces in body text (`9 → 10`).

**Minimum sizes** (readable on a phone at arm's length, and in a search result at ¼ size):

| Format | Headline | Body | Labels |
|---|---|---|---|
| 1080 px wide (Short, post, end card) | 96 px | 36 px | 28 px |
| 3840×2560 search asset | 240 px | 96 px | 54 px |
| 3840×1646 header | 140 px | — | 36 px |
| 1200×630 OG image | 64 px | 24 px | 18 px |
| 1280×720 thumbnail | 120 px | — | — |

## Layout

- **Brand row** top-left (mark + name), a label top-right (e.g. "Fork · Shock · Tires"),
  vertically centered on each other. When a phone sits below the label, the label centers on the
  phone: the rounded corners make an edge alignment look off.
- **Black rules**, square ends: 6 px under the search asset's brand row, 4 px elsewhere on
  3840 and 1080 px frames, 3 px on the OG image, 2 px for a secondary rule. A rule under the brand row; another one above a number block or the footer.
  A rule that meets the phone ends behind it, never pokes out past its corners.
- **Headline** top-left, ragged right, never covered: the phone may only overlap rules and
  empty space.
- **Number block:** label above, number below; the big one first (`Rebound 9→10`), up to two
  smaller ones next to it. At most 3 changed values per frame.
- **Phone:** the real iPhone frame (`docs/store/app-store/iPhone-17-Pro-Max/frame.png`) with a
  real screenshot or recording, one soft shadow. Android frame for Play assets (Phase 2).

## Grid and safe areas

| Format | Size | Margin | Safe area |
|---|---|---|---|
| Search results asset | 3840×2560 | 200 px | Apple art safe area 836, 765, 2168×1030; the headline may reach past it (#69: the preview shows the full image) |
| App Store header | 3840×1646 | — | 1097, 493, 1646×661: everything that matters; rules run full width |
| Play feature graphic | 1024×500 | 120 px left and right | Text inside the central 784×400 |
| Short frame / end card | 1080×1920 | 60 px | 60, 220, 860×1180 (clear of the platforms' top bar, caption block and action buttons) |
| Post | 1080×1350 (4:5), 1080×1080 (1:1) | 72 px | Whole frame |
| OG image | 1200×630 | 60 px | Whole frame |
| Thumbnail | 1280×720 | 64 px | Bottom-right 220×80 is covered by the duration badge |

No format is a crop of another (#77 Phase 2).

## Reference frames

What each surface looks like (see `reference.html`):

| Surface | Content |
|---|---|
| Search asset | Brand row; headline R4 with "MTB suspension." in teal; number block Rebound 9→10, LSC 6→7, Pressure 83→84 psi; Setup History in the phone on the right |
| App Store header | No phone (Apple: the header is about the brand). Brand row and label in the safe area; headline R2 in two lines, "Fork and shock" in teal; a values row (Rebound, LSC, Pressure); full-width rules |
| Short frame | Brand row; hook R3 with "clicks" in teal; the phone below, bleeding off the bottom |
| End card | See below |
| Post (4:5) | "Setup history" label and date; setup name; Fork · Rebound 9→10 big; LSC and pressure below; brand row and "See what changed" in the footer |
| OG image | Brand row; headline R4; small label row; the phone cropped at the right edge |

## End card

Order of emphasis (#77 decision J):
1. **Mark and name**: the mark 340 px, the name in two lines, 150 px, centered.
2. A rule, then the **signature** "78 psi. 4 clicks. Saved." (messaging.md), 46 px.
3. **Store badges**, official artwork, 104 px high.
4. **"Free on iOS and Android"**: label style, muted, 28 px.

White background (the badges are black). No URL on the end card; the post carries the link. Hold
for at least 2 s.

## Callouts

For a single control that is the point (#77 decision H):
- **`zoom`:** ease into the rect over 0.4 s, hold, ease out; no motion blur.
- **`lift`:** the UI element cropped from the real recording, scaled about 1.6×, square corners,
  a 2 px `ink` border and one soft shadow, floating beside the phone. Never redrawn.
- **Label** next to it: a caps label (`Fork · Rebound`) above the value (`9→10`), the new value
  in `changed`.

## Screens

- Always real screenshots or recordings from the screenshot build; never mocked or AI-drawn.
- Tags off, at most 3 changed values visible (#77 decision F, messaging.md).

## Thumbnail formula

1. A 2–3 word headline, Archivo 900, filling at least ⅓ of the width; the key word in teal.
2. One real UI element lifted out of the screen (e.g. the `9 → 10` chip), or the phone.
3. The bike context in the words (messaging.md), or occasionally in an AI background.
4. Three elements at most. It must still read at 168×94.

## AI images

Rarely and deliberately, for a single post (#77 decision G):
- They follow this guide: light, muted, a lot of empty space, no gradient glow.
- The app screen is composited on top as a real screenshot; AI never draws UI.
- No prominent third-party logos; plausible mechanics (a fork is a fork, a shock sits where a
  shock sits).
- Never in store screenshots or store creative. The prompt goes in the post file.

## Do's and don'ts

| Do | Don't |
|---|---|
| Name the bike in every headline (messaging.md) | Use "Fahrwerk" or "setup" alone |
| Teal for the key phrase, orange for changed values | Teal values, orange headline words, a third color |
| Use real values from the sample dataset | Invent numbers or UI |
| Keep the headline fully readable | Let the phone cover a word |
| Sentence case for headlines | Uppercase headlines (labels only) |
| Square corners on everything we draw | Rounded cards, pills, chips |
| White paper, black rules | Gradients, glows, dark or tinted backgrounds |
| Show third-party brands only as they appear in real data, small | Prominent brand logos (bike, fork, Strava) |
| Turn tags off; show ≤ 3 changed values | Show every value of a setup |
| Keep store assets free of prices | "Free" anywhere but the social end card |
| Check every frame at 100 % and at display size | Approve from a zoomed-out overview |
