# v1.6.4 marketing: options and plan

Ideas and alternatives for the v1.6.4 (build 45) release content, with the picks marked
**Recommended**. Nothing here is recorded or rendered yet; the picked items go into
`/marketingkit v1.6.4+45` (kit `v1.6.4`). Rules from [`messaging.md`](messaging.md),
[`channels.md`](channels.md) and [`brand.md`](brand.md) apply to every item.

**Release day for the posts: Wed 04.11.2026**, the last day the current Short queue has a
TikTok and Instagram slot. Release posts only go out once 1.6.4 is live in **both** stores.

## Decisions (29.10.)

- TikTok uses the resolution of the previous kits: **9:16, 1080×1920**, also for the slideshow.
- **Voiceover** on the feature Shorts (as in `03_features`).
- Brand names in plain text are OK, with a disclaimer (see [Brand names](#brand-names)).
- **Strava club skipped** for this release.
- Cadence: **daily or every other day**.
- Value migration moved to [`backlog.md`](backlog.md) (advanced, troubleshooting only).
- A Short about **dial color and size** is wanted (N8).

## What ships (flag-checked against the staged build 45)

| Change | Flag state in build 45 | Postable? |
|---|---|---|
| **Fork & shock catalog** (Component Presets): pick brand › model › generation › trim, click ranges, air pressure and SAG are filled in, all editable | `enableComponentPresets = true`, user toggle now visible to everyone | **Yes, headline** |
| **Recommended tasks** (Task Presets): adding a component suggests tasks like *Check chain wear*, *Lower leg service*, *Air can service*; catalog forks and shocks use the manufacturer's service intervals | `enableTaskPresets = true`, but **Tasks itself is off by default** | Yes, with "Switch on Tasks under Settings → Features" (the in-app What's new card has a *Turn on Tasks* button) |
| **Dial color and size**, picked in a sheet on a clicks adjustment | No flag (the old `enableStepDialColorSize` key is removed); step adjustments are core | Yes |
| Catalog picker ranking, model years, DT Swiss F 132 gravel forks | Part of the catalog | Yes, as detail |
| Value migration on adjustment edits | No flag | Not in release content; [backlog](backlog.md) row |
| Feedback / test sessions (Rating v3), pressure check, setup guides, riders, bookmarks | Developer mode / off | **No** |

Real numbers available: **15 brands** (fork: BOS, Cane Creek, Cannondale, DT Swiss, DVO, EXT,
Formula, FOX, Intend, Manitou, Marzocchi, Öhlins, RockShox, RST, SR Suntour; shock: the same minus
Cannondale and Intend), sourced from the manufacturers' service manuals and support pages
(`data/component_presets/`). Count models before naming a model number.

**Messaging guard:** the catalog fills in *what your fork can do* (ranges), never *what to set*.
"Recommended tasks" is the in-app name; in copy say "service tasks with the manufacturer's
intervals", never "the app recommends settings". Setup guides (manufacturer starting points) stay
out of all content.

### Brand names

Naming a manufacturer to say which products the catalog covers is referential use, which
trademark law generally allows (EU: Art. 14 EUTMR "honest practices"; US: nominative fair use) as
long as nothing suggests a partnership. Not legal advice; the safe pattern:

- Names in plain text in the brand font, as the app lists them. **No logos, brand fonts or brand
  colors**, and a name is never the biggest element on a slide.
- Never "official", "partner", "approved by" or anything that reads as endorsement.
- Every post that shows or names brands (release posts, N1, N4, N5) ends its description or
  caption with:
  - EN: `Not affiliated with or endorsed by the brands shown. Brand names are trademarks of their owners.`
  - DE: `Keine Verbindung zu den gezeigten Marken. Markennamen sind Eigentum der jeweiligen Inhaber.`
- The S5 brand-wall slide carries the EN line as its footer note.

## Prep before anything is recorded

- [x] Lift the "no presets" rule where it is now wrong: `channels.md` (Rules for every channel),
      `backlog.md` (pick rules, *Waiting for a release*), `.claude/commands/marketingkit.md`
      (Constraints) and `tool/screenshots/README.md` (Demo clips, "Only released features").
      Pressure check, ratings, riders and bookmarks stay banned. Add the brand disclaimer rule to
      `channels.md`.
- [x] New hooks into the bank (below), EN + DE.
- [x] A 9:16 still layout for the TikTok slideshow and the IG story: `post_9x16.html`
      (1080×1920, same kinds as `post_4x5.html`, inside the Short's safe area); kit key
      `images.vertical`, rendered to `build/marketing/<kit>/vertical/`.
- [ ] `/releaseversion` writes `changelogs/45.txt` (EN + DE), the base text of every release post,
      opens the `v1.6.4: Marketing` issue and offers `/marketingkit v1.6.4+45` as its last step.

### Hook candidates for the bank

| Proposed ID | EN | DE | Use |
|---|---|---|---|
| R13 | How many rebound clicks does your fork have? | Wie viele Zugstufen-Klicks hat deine Gabel? | N1 hook |
| R14 | Which fork do you ride? | Welche Gabel fährst du? | N5 hook, comment bait |
| R15 | New fork? Every click range, filled in. | Neue Gabel? Alle Klickbereiche schon eingetragen. | Release slideshow headline (statement) |
| R16 | Thinking about upgrading your fork? | Überlegst du, deine Gabel aufzurüsten? | E4 re-cut of N1; Black Friday only in the caption |
| R17 | Red dial or blue dial: which one was rebound? | Rotes oder blaues Rad: Welches war die Zugstufe? | N8 hook (the sheet offers blue, red, green, brown, orange, purple, grey; normal or small) |
| S7 | How often does your fork need a lower leg service? | Wie oft braucht deine Gabel einen Lower-Leg-Service? | N2 hook |
| S8 | Off-season: what's due on your fork? | Winterpause: Was ist an deiner Gabel fällig? | E3 hook |

## Release slideshow

Channels: Instagram (carousel + story), TikTok (photo mode), YouTube (community post on `yt-bst`).
The `release` kind already exists in `post_4x5.html` and `post_1x1.html`: big version number, label
(default "What's new"), date note, **up to 4 items**, footer.

### Alternatives

| | Idea | Slides | Pros | Cons |
|---|---|---|---|---|
| **S1** | **Classic release card + feature slides** | 1 `release` card (1.6.4 + 4 items) → 2–3 `screen` slides (picker, filled-in adjustments, task suggestions) → end card | Template exists; matches the v1.6.3 community post | Opens with a number, not a problem: weak first slide on TikTok |
| **S2** | **Story-first** | Hook slide "New fork?" (R15) → 1 · pick the brand → 2 · pick model and trim → 3 · adjustments filled in → 4 · service tasks suggested → `release` card last | Strong first slide for TikTok/IG; teaches the flow | Needs a hook slide (closest: `cover`) |
| **S3** | **Version card only** | Just the `release` card | 10 minutes of work | Little to look at; no product shot |
| **S4** | **Animated release trailer** (9:16 video, ~12 s) | Version number, items building in one by one, 2 clip cuts, end card | Motion beats stills in the feed | New template work; competes with the feature Shorts |
| S5 | Brand wall slide (add-on to S1/S2) | One slide listing the 15 brand names as type, disclaimer as footer | Readers spot their fork at a glance; shareable | Check the list right before posting |

### Formats per channel

| Channel | Format | Template |
|---|---|---|
| `ig-bst` carousel | 4:5, 1080×1350 | `post_4x5.html` ✓ |
| `ig-bst` story | 9:16, 1080×1920; link sticker to the campaign link, poll sticker on 09.11 (E6) | `post_9x16.html` (new) |
| `tiktok` photo mode | 9:16, 1080×1920, as in the previous kits | `post_9x16.html` (new) |
| `yt-bst` community post | 1:1, rendered square from the start | `post_1x1.html` ✓ |

**Recommended:** **S2 on TikTok and Instagram, S1 on YouTube**, from one shared slide set (the step
slides are the same in both, only the order and the first slide differ), plus the **S5 brand wall**.
S3 is the fallback if time runs out before 04.11.

Draft release card items (final wording follows `45.txt`):

1. Fork & shock catalog: pick your model, the adjustments are filled in
2. Service tasks with the manufacturer's intervals (switch on Tasks)
3. Pick each dial's color and size to match the real one
4. Better catalog search, with model years

## Shorts: new features

All 9:16 (1080×1920), ≤30 s, voiceover, problem hook ≤1.5 s, payoff on screen, end card. Each runs
on `yt-shorts`, `ig-bst` (Reel) and `tiktok`.

| ID | Short | Pillar · audience | Hook | Shows | Recording | Verdict |
|---|---|---|---|---|---|---|
| **N1** | **Pick your fork, skip the manual** | R · MTB | R13 | Add component → Fork → search "Lyrik" → generation, trim, damper → Pressure, LSC, HSC, Rebound, SAG appear with their ranges; callout on one range (the real click count from `fork/rockshox.yaml`) | New flow `demo_add_component_catalog`, scenario `one_bike_no_components` | **Recommended** |
| **N2** | **Service tasks come with the fork** | S · Maint | S7 | Right after N1's save: the task sheet suggests *Lower leg service* and *Full service* with the manufacturer's interval; tick, save, tasks list | New flow `demo_task_presets`; scenario needs Tasks on. Post: "Switch on Tasks under Settings → Features" | **Recommended** |
| **N5** | **Which fork do you ride?** | R · MTB | R14 | Fast scroll through the brand list, open 3 brands, end on "Request this product"; caption asks "Tell us your fork in the comments" | One short flow; mostly scrolling | **Recommended** (cheap, comment bait) |
| **N8** | **Your dial, matching the real one** | R · MTB | R17 | The fork's Rebound adjustment → dial style sheet → color and size → the dial now looks like the knob on the fork; same for LSC; callout on the sheet | New flow `demo_dial_style`, scenario `full` | **Recommended**. Builds the backlog row *Step adjustments*; delete that row once made |
| N3 | New fork, logged in 30 s | R + S · MTB | R15 | N1 → N2 → first setup with values, in one Short | Stitch N1 + N2 + `demo_add_setup` | Fallback if only one Short fits |
| N4 | Shock version | R · MTB | R13 variant ("…your shock have?") | Float X2 or Super Deluxe: HSC/LSC/HSR/LSR filled in, air vs coil | N1's flow with a shock | Recommended for batch 2 |
| N6 | Manual vs. catalog, split screen | R · MTB | — | Left: typing adjustments by hand (`demo_add_component`), right: N1; timer | Reuses clips, but `build_kit.py` has no split layout | Later |

## Shorts and posts: general app (not about 1.6.4)

So the feed isn't only release content. November is off-season in Europe and has Black Friday:
both fit this release well.

| ID | Idea | Pillar · audience | Hook | Material | Verdict |
|---|---|---|---|---|---|
| **E1** | **Log your setup before winter storage** | R · MTB | R3 | Re-cut of `demo_add_setup` with a seasonal caption and new voiceover | **Recommended** |
| **E3** | **Off-season = service season** | S · Maint | S8 | `demo_tasks` + N2 footage: what's due on the fork before spring | **Recommended** |
| **E4** | **Fork upgrade** | R · MTB | R16 | N1 re-cut with a new hook, posted 27.11 (Black Friday weekend; mention it only in the caption) | **Recommended** (no recording) |
| **E6** | **Poll: where do you keep your settings?** (tape on the fork / notes app / memory / an app) | R · MTB | R9 | IG story poll sticker; TikTok photo post with the same question | **Recommended** (no recording) |
| **E8** | **Dev story: 15 brands of click ranges from the service manuals** | — · dev | — | Screens of the YAML and its sources, the picker; `yt-jk` community post, r/SideProject, r/FlutterDev (modmail first, ≥2 days apart) | **Recommended**, dev channels only |
| E2 | Your season in setups | C · MTB | C6 | Carousel from `demo_analysis` stills (`analysis` Short ran 25.10) | Maybe |
| E5 | POV: you serviced your fork and forgot your clicks | R · MTB | — | Text-on-screen meme opener, then the setup history as the payoff | Maybe; check tone against `brand.md` |
| E7 | Tip carousel: "Count clicks from closed" | R · MTB | — | `tip` slides using the catalog notes; education only, never a setting | Maybe |
| E10 | Backlog rows: *Back to the setup that worked* (R10), *Pressure for wet vs. dry*, *Restore a deleted setup* | R, C, D | from `backlog.md` | Per the backlog notes | **Recommended**, batch 2 |
| E11 | Long-form "Add your fork from the catalog" (16:9, 2–3 min) | R · MTB | — | Walkthrough; set as the Shorts' related video (Shorts links aren't clickable) | Maybe |
| E12 | Custom product page "fork catalog" in the store (#82) | — | — | Bio link → product page with catalog screenshots during November | Maybe; check what #82 supports |
| E13 | Reddit r/MTB: click ranges of 15 brands, data-first | R · MTB | — | Value post with the app as the source; developer disclosed | Later, modmail first |

## Schedule

Daily in the release week, then every other day to the end of November. Shorts go to
`yt-shorts`, `ig-bst` (Reel) and `tiktok` on the same day unless noted.

| Date | Channels | Item | Batch |
|---|---|---|---|
| Wed 04.11 | `ig-bst` carousel + story, `tiktok` photo, `yt-bst` community | Release slideshow (S2 / S1 + S5) | 1 |
| Thu 05.11 | Shorts | N1 catalog | 1 |
| Fri 06.11 | Shorts | N2 service tasks | 1 |
| Sat 07.11 | Shorts | N8 dial color and size | 1 |
| Sun 08.11 | Shorts | N5 "Which fork do you ride?" | 1 |
| Mon 09.11 | `ig-bst` story, `tiktok` photo | E6 poll | 1 |
| Wed 11.11 | Shorts | E1 log before winter | 2 |
| Wed 11.11 | `yt-jk`, `reddit-sideproject` | E8 dev story | 2 |
| Fri 13.11 | Shorts | E10 *Back to the setup that worked* | 2 |
| Sun 15.11 | Shorts | E3 off-season service | 2 |
| Mon 16.11 | `reddit-flutterdev` | E8 dev variant | 2 |
| Tue 17.11 | Shorts | N4 shock | 2 |
| Thu 19.11 | Shorts | E10 *Pressure for wet vs. dry* | 2 |
| Sat 21.11 | Shorts | E10 *Restore a deleted setup* | 2 |
| Mon 23.11 | `ig-bst` carousel, `tiktok` photo | E2 season in setups, or E7 tip carousel | 2 |
| Wed 25.11 | Shorts | E5 POV, or the next backlog row | 2 |
| Fri 27.11 | Shorts | E4 fork upgrade (N1 re-cut) | 2 |
| Sun 29.11 | Shorts | Next backlog row (start of the December monthly kit) | 2 |

**Batch 1** is the release kit (`/marketingkit v1.6.4+45`), reviewed and scheduled before 04.11.
**Batch 2** is a second kit (`/marketingkit` with these topics), reviewed and scheduled by ~09.11.

### Back-planning to 04.11

Voiceover adds a round trip: the batch texts have to be ready for speechma before the render.

| By | Step |
|---|---|
| Thu 29.10 – Fri 30.10 | Lift the presets rule; hooks into the bank; `post_9x16.html`; `/releaseversion` (writes `45.txt`, opens the marketing issue) |
| Sat 31.10 | `/marketingkit v1.6.4+45`: write and record the N1, N2, N5, N8 flows; kit; voiceover texts → **you generate the MP3s** |
| Sun 01.11 | Render; review via `/reviewkit`; **build 45 submitted to both stores** (App Store review needs ~1–2 days) |
| Mon 02.11 – Tue 03.11 | Fixes; schedule natively (YouTube Studio, Meta Business Suite, TikTok web); post files `Status: scheduled` |
| Wed 04.11 | Check 1.6.4 is live in both stores, then the release posts go out |

If build 45 isn't live by the morning of 04.11, move the release slideshow and N1/N2/N8 by the
same number of days and fill the gap with E6 and E1, which don't name a new feature.

## Recommendation

1. **Slideshow:** S2 for TikTok/Instagram, S1 for YouTube, plus the S5 brand wall.
2. **New-feature Shorts:** N1, N2, N8, N5 in batch 1; N4 in batch 2.
3. **General content:** E1, E3, E4, E6, E8 and three backlog rows (E10).
