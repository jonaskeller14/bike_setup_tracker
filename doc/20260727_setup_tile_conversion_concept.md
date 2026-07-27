# Setup card → ListTile conversion — concept brainstorming

**Status:** Brainstorming — pick one option per section, then run /plan.

Goal: turn `lib/widgets/items/setup_list_card.dart` from a `Card` into a plain
tile so the SetupList timeline reads as **one uniform stream of events** — same
horizontal rhythm for every row, dividers between every pair of rows, and a
narrower content inset (32 → 16 px). The blockers are (a) the two trailing
controls the card carries (popup menu + expand chevron) which a `ListTile` has
only one slot for, (b) the `Setup.isCurrent` primary border + corner `Current`
label that depend on a `Card` shape, and (c) `SetupGroupCard`, which is built
out of embedded `SetupListCard`s inside a `Card`.

### What the code does now (constraints)

- **`SetupListCard` has three render modes**, all in one file:
  1. **standalone card** — `Card(margin: vertical 4)` + `InkWell` + `Stack`
     ([setup_list_card.dart:494-529](lib/widgets/items/setup_list_card.dart#L494-L529)),
  2. **embedded group member** (`embedded: true`) — no `Card`, collapsed to just
     the changed values with a bottom-right chevron
     ([setup_list_card.dart:374-440](lib/widgets/items/setup_list_card.dart#L374-L440)),
  3. the shared header block `_setupListTile(...)` used by both
     ([setup_list_card.dart:176-356](lib/widgets/items/setup_list_card.dart#L176-L356)).
- **It is *already* hand-rolled as a tile**, not a `ListTile`: `Padding` +
  `Stack` with `Positioned` popup menu (top-right) and `Positioned` `ExpandIcon`
  (bottom-right), plus `ConstrainedBox(minHeight: 2 * kMinInteractiveDimension)`
  so both controls fit. **This is the real obstacle** — `ListTile` has one
  `trailing` slot, not two.
- **The other four event tiles are the template.** `RatingEntryListTile` and
  `TaskEntryListItem` are `InkWell( Column( ListTile(...), <below-block> ) )`:
  `dense`, `visualDensity: compact`, `titleAlignment: top`, `minLeadingWidth: 0`,
  `horizontalTitleGap: 8`, `minTileHeight: 0`, `minVerticalPadding: 0`,
  `contentPadding: only(left:16, right:16, top:8, bottom:4)`, popup menu in
  `trailing`, and everything that doesn't fit (place, notes, stat box) in a
  `Padding(left:16, right:16, bottom:8)` block underneath. `InstallationListTile`
  and `ReplacementListTile` are bare `ListTile`s. Body font size in tiles is
  **12**; the setup card uses **13** and `titleMedium` bold for the title.
- **Padding arithmetic today:** `_buildRow` wraps every non-day-header row in
  `Padding(horizontal: 16)` ([setup_list.dart:236-244](lib/widgets/lists/setup_list.dart#L236-L244));
  the card adds its own inner `16`, and the tiles add their own `contentPadding`
  of `16`. **So every row — card *and* tile — sits at 32 px today.** The
  32 → 16 win therefore comes from removing the list-level padding, not from the
  widget swap itself; the swap is what makes removing it *coherent* (a `Card` at
  0 horizontal margin, with rounded corners and a border, next to full-bleed
  dividers, looks broken).
- **Dividers are already full-bleed.** They're siblings of the padded row inside
  the section `Column` / `SliverList.separated`, so they already span the screen.
  The only thing suppressing them around setups is `_isTileRow`, which returns
  `false` for `SetupEntry()` and `SetupGroupRow()`
  ([setup_list.dart:182-193](lib/widgets/lists/setup_list.dart#L182-L193)). Making
  setups tiles is a **two-line change there**.
- **`StravaContextWrapper`** insets its child by `4 (bar) + 10 = 14` px *inside*
  the row's 16 px padding. If the list-level padding goes away, the orange bar
  lands at x = 0. Deliberate choice, see F.
- **`isCurrent` is rendered in four places** and the pattern is already
  inconsistent: card border + corner label
  ([setup_list_card.dart:46-69](lib/widgets/items/setup_list_card.dart#L46-L69)),
  **group member = primary 8 % background + 4 px left border**
  ([setup_group_card.dart:84-93](lib/widgets/items/setup_group_card.dart#L84-L93)),
  details-page app-bar chip
  ([setup_details_page.dart:155-171](lib/pages/details/setup_details_page.dart#L155-L171)),
  and the map pin ([map_page.dart:164](lib/pages/map_page.dart#L164)). The badge
  container is duplicated verbatim in two files.
- **Four call sites** for `SetupListCard`: the timeline
  ([setup_list.dart:144](lib/widgets/lists/setup_list.dart#L144)), the search
  overlay ([setup_list_search.dart:120](lib/widgets/chips/setup_list_search.dart#L120)),
  the Strava activity details `ExpansionTile`
  ([strava_activitiy_details_page.dart:323](lib/pages/details/strava_activitiy_details_page.dart#L323)),
  and `SetupGroupCard` (both the single-member shortcut and the embedded members).
- **Prior decisions** (`doc/20260702_setup_list_redesign.md`, Round 2) already
  pushed in this direction: full-bleed day bands, list padding moved into rows,
  dates dropped from timeline tiles, "no Current border on the *group* card — a
  group is not current, one member is". The open TODO list at the bottom of that
  doc also asks for member dividers and full-width members inside the group.

Decision axes:

- **A. Card or tile** — the conceptual call
- **B. Tile structure** — where the popup menu, chevron and value list go
- **C. Keeping Setup visually primary** as a tile
- **D. `isCurrent` treatment** (replacing the card border)
- **E. `Current` label placement** inside a tile
- **F. Padding + divider mechanics** in `setup_list.dart`
- **G. `SetupGroupCard`** consequences
- **H. Non-timeline call sites**
- **I. Tests**

---

## Verdict on the card → tile question (you asked for my opinion)

**Yes — convert it, and do it for the reason you gave, not for the padding.**

Your Card/Tile taxonomy is the right model and the app is already 90 % committed
to it: cards are **objects you own and navigate to** (Bike, Component, TaskRule,
Rating, Person — all in grids/lists where each card *is* a destination), tiles
are **things that happened at a time**. A Setup is unambiguously the second kind
in this view: it has a timestamp, it is sorted between rides and installations,
it participates in day sections and Strava blocks, and it is *the* thing the
other events give context to. Rendering the timeline's most important row as the
only card in the stream doesn't make it more important — it makes the stream look
broken, because a card's margin + corners + elevation fight the day bands and
the dividers around it.

Two caveats worth stating honestly:

1. **"Consistency" is not the strongest argument — the shared rhythm is.** The
   payoff is that all six row types then share one left edge, one baseline grid,
   and one divider rule, so the eye scans down a column instead of across
   alternating containers.
2. **The main object must not become visually equal to its context.** Losing the
   card means losing the only prominence mechanism the setup row has. Do not skip
   section C — prominence has to be re-established with type weight / leading
   icon / a subtle row tint, or the conversion trades a broken rhythm for a lost
   hierarchy. "Setup is a special kind of event" should still be *visible*.

Where the card **should stay** is outside the timeline (see H): in the Strava
details `ExpansionTile` and the search overlay, a setup is a standalone object in
a list of its own, not one event among many.

---

## A. Card or tile

### A1 — Full conversion: `SetupListCard` becomes `SetupListTile` everywhere (recommended)

One widget, tile shape, used by all four call sites; card wrapper deleted.

**Pros:**
- Single source of truth; no mode flag proliferation on top of the existing
  `embedded` / `hidePlace` / `showDate` set.
- Unlocks the full-bleed rhythm in F for *every* row without special cases.
- Matches the taxonomy argument above exactly.

**Cons:**
- Setups inside the Strava details `ExpansionTile` and the search overlay lose
  their container and become a wall of undifferentiated rows there (those lists
  have no day bands or dividers to carry the structure).
- Biggest single diff; touches all four call sites at once.

### A2 — Keep the `Card` (do nothing)

**Pros:**
- Zero risk; the current-state border/label problem disappears.
- Preserves maximum prominence for the app's headline object.

**Cons:**
- Leaves the 32 px inset and the divider gap around setups — the two things that
  make the timeline look inconsistent today.
- Keeps the odd situation that `SetupListCard` is *already* a hand-rolled tile
  wearing a card, i.e. the complexity without the benefit.

### A3 — Tile in the timeline, card elsewhere (`tile: true` / `wrapInCard: true` flag) (recommended fallback)

The widget renders tile-shaped by default and the two standalone contexts opt
into a `Card` wrapper (or a tiny `SetupCard` wrapper widget wraps the tile).

**Pros:**
- Best of both: uniform timeline, retained container where the setup really is a
  standalone object.
- Incremental — the timeline can flip first, other call sites unchanged.

**Cons:**
- One more render mode in a widget that already has three; risk that "card mode"
  quietly rots.
- Two visual identities for the same object; a user who searches and then scrolls
  sees two different shapes for the same thing.

### A4 — "Flat card": keep `Card` but elevation 0, no margin, square corners

**Pros:**
- Very small diff; keeps `shape` available so the `isCurrent` border survives
  untouched.
- Can be made visually indistinguishable from a tile with a background tint.

**Cons:**
- Cargo-cult container: pays `Card`'s clip/shape cost for no visual benefit and
  still isn't a `ListTile`, so it doesn't inherit `dense`/`visualDensity`
  behaviour or the other tiles' metrics.
- Half-measure that keeps the file's `Stack`/`Positioned` layout instead of
  aligning it with the tile template.

---

## B. Tile structure: two trailing controls, one `trailing` slot

The card needs a popup menu **and** (when collapsed values hide something) an
`ExpandIcon`. `ListTile` gives one `trailing`.

### B1 — `ListTile` + below-block, chevron moves into the value block (recommended)

Exactly the `TaskEntryListItem` / `RatingEntryListTile` shape: `InkWell( Column(
ListTile(title, subtitle, trailing: popup menu), Padding(metadata + notes +
AdjustmentCompactDisplayList) ) )`. The expand affordance moves *into* the value
block — either a small right-aligned `ExpandIcon` at the end of the list or (like
`TaskEntryListItem`'s stat box) making the value block itself tappable to toggle.

**Pros:**
- Literally the established pattern; the `Stack`/`Positioned`/`ConstrainedBox`
  (`2 * kMinInteractiveDimension`) machinery disappears — a real simplification.
- The chevron ends up next to the thing it expands, which is arguably clearer
  than the current bottom-right corner.
- `ListTile` handles the leading-icon alignment and min-heights we hand-tune now.

**Cons:**
- Behaviour change: a tap on the value block toggling expansion competes with
  the row's `onTap` → details page. Needs a decision (explicit chevron is safer).
- Two tappable regions inside one row is a small a11y/hit-test risk on narrow
  screens.

### B2 — `ListTile` with a composite `trailing` (`Column(menu, ExpandIcon)`)

**Pros:**
- Closest to today's visual result; nothing about where controls live changes.
- No new tap semantics.

**Cons:**
- Forces the tile ≥ 96 px tall whenever the chevron shows, even for a one-line
  setup — the very padding waste we're trying to remove.
- `ListTile` centres `trailing`; a two-control column will need alignment
  fiddling and won't line up with the other tiles' single menu button.

### B3 — `ExpansionTile`

**Pros:**
- Built-in expand semantics and animation; no custom chevron state.
- Free `AnimatedSize`-equivalent behaviour.

**Cons:**
- `ExpansionTile` owns `onTap` — it can't also navigate to the details page,
  which is the row's primary action. Fatal unless navigation moves to the menu.
- Its own padding/shape defaults fight the tile metrics used elsewhere; the app
  already had to neutralise them with `shape: Border()` in the Strava page.

### B4 — Keep the current `Stack` body, just drop the `Card`

**Pros:**
- Smallest possible diff to get the shape change; zero behaviour risk.
- Preserves the deliberate two-corner control layout.

**Cons:**
- The row still won't match the other tiles' metrics (font sizes, densities,
  leading gap) — you get consistency of *outline* but not of *rhythm*.
- Leaves the duplicated `_subtitleRow`/`_metadataRow` helpers (also copied in
  `SetupGroupCard`) uncleaned.

---

## C. Keeping Setup visually primary as a tile

### C1 — Type weight only: keep `titleMedium` bold + 13 px metadata (recommended)

Other tiles use plain bold 14-ish titles and 12 px subtitles; the setup row keeps
`titleMedium` bold and 13 px secondary text, so it is measurably heavier without
any container.

**Pros:**
- Zero new visual vocabulary; hierarchy via typography is the Material-native
  answer and survives light/dark automatically.
- Already true today — nothing to build, just *don't* normalise the font sizes
  down to 12 during the conversion.

**Cons:**
- Subtle; on a screen full of setups the distinction disappears (though then
  there's nothing to distinguish *from*).
- Leaves a deliberate inconsistency in font sizes that a future cleanup might
  "fix" by accident — needs a one-line comment saying why.

### C2 — Primary-tinted leading icon for setup rows

`Icon(Setup.iconData, color: colorScheme.primary)` while context events keep
`onSurfaceVariant`.

**Pros:**
- Instantly scannable: the eye finds setups by colour down the leading column.
- Cheap, theme-safe, and reinforces "setup = the main event".

**Cons:**
- Colour then means two things if D also uses primary for `isCurrent` — the
  current setup must still stand out *among* setups.
- Risks looking like a "selected"/interactive state.

### C3 — Subtle row background band (`surfaceContainerLow`) for setup rows

**Pros:**
- Strongest "this is the anchor event" signal; the timeline reads as setups with
  context slotted between them.
- Full-bleed band composes with the full-bleed day headers.

**Cons:**
- Three background tones in one list (day band, setup band, current-setup tint)
  is a lot; high chance of mud in dark mode.
- Fights `StravaContextWrapper`'s orange bar and the D options that also tint.

### C4 — Accept equal weight (setups look exactly like other events)

**Pros:**
- Maximum consistency and the cleanest code.
- Time ordering carries the story; no visual vocabulary to maintain.

**Cons:**
- The app is called Bike **Setup** Tracker — the headline object becoming
  indistinguishable from a synced Strava row is a real product regression.
- The setup row is the only one with an expandable value list; it deserves a cue.

---

## D. `isCurrent` treatment (replacing the card border)

### D1 — 4 px primary left bar + primary 8 % row tint (recommended)

Reuse the treatment `SetupGroupCard` **already** applies to a current member
([setup_group_card.dart:86-93](lib/widgets/items/setup_group_card.dart#L86-L93)),
promoted into the tile itself (or a small `CurrentSetupHighlight` wrapper) so the
standalone row and the group member finally look identical.

**Pros:**
- Not a new invention — it's the existing in-app answer to "mark this row as
  current without a card shape", and it removes today's inconsistency between
  standalone and grouped current setups for free.
- Works full-bleed; needs no border radius, so it survives the divider rhythm.
- Structurally identical to `StravaContextWrapper`, so the two compose
  predictably (nesting order must be decided — see open questions).

**Cons:**
- Left-bar vocabulary is now overloaded: orange = ride block, primary = current
  setup. On a current setup recorded during a ride you'd get two stacked bars.
- The 8 % tint plus C3's band would be two tints on one row (pick one).

### D2 — Badge only, no border and no tint

The `Current` chip in the title row is the sole indicator.

**Pros:**
- Simplest possible; nothing competes with the Strava bar or day bands.
- The badge is already the indicator on the details page and the map pin —
  one vocabulary across the app.

**Cons:**
- Much weaker at a glance; scanning a long list for "where am I now" gets harder
  — and that's a primary use of this screen.
- Loses the "this row is different" signal that the border currently gives even
  before you read the label.

### D3 — Filled row background (primary container, no bar)

**Pros:**
- Unmistakable; strongest single-row emphasis available without a container.
- One mechanism instead of bar + tint + badge.

**Cons:**
- Very loud for a permanent state; a `primaryContainer` row in a list of plain
  rows reads as "selected", inviting a tap that does nothing special.
- Tinted background + the badge's `primary` fill need a contrast check in both
  themes.

### D4 — Keep a bordered `Card` **only** for the current setup

**Pros:**
- Zero redesign of the indicator; guaranteed to keep today's prominence.
- Trivially small diff.

**Cons:**
- Reintroduces the inconsistency at the worst possible spot: the row jumps 16 px
  of inset and grows margins the moment a setup becomes current, and dividers
  must be suppressed around it — the exact thing this whole change removes.
- Two layouts to maintain and test for one widget.

---

## E. `Current` label placement inside a tile

The corner-anchored badge depends on a clipped rounded container, so it can't
survive as-is. `trailing` is taken by the popup menu.

### E1 — In the title row, after the name, before the score badge (recommended)

`Row(Expanded(title), if (isCurrent) CurrentBadge, if (score != null) ScoreBadge)`
— mirrors the details page's app-bar treatment (`title`, gap, badge).

**Pros:**
- Highest-priority information sits in the highest-priority slot; identical to
  the details page, so the app has one placement rule.
- No new layout: the title row already handles a trailing badge (score).

**Cons:**
- Three items compete for the title line; long setup names shrink further. Needs
  the title to stay `Flexible`/`Expanded` with ellipsis and the badges
  `mainAxisSize.min` (already how the score badge behaves).
- With both badges present on a narrow screen the title can get very short.

### E2 — First chip in the subtitle `Wrap` (before the time)

**Pros:**
- The `Wrap` already handles overflow gracefully — zero risk of squeezing the
  title, and it composes with tags/score/metadata chips.
- Reads naturally as "Current · 14:32 · Enduro".

**Cons:**
- Demotes the most important status to secondary-text weight, next to muted
  metadata.
- Easy to miss when several metadata chips wrap onto multiple lines.

### E3 — Replace/annotate the leading icon (e.g. filled primary circle avatar)

**Pros:**
- Costs zero horizontal text space — the strongest argument on narrow screens.
- Aligns with D1's left-edge emphasis; the whole left column becomes the status
  column.
- Text-free, so no truncation ever.

**Cons:**
- Loses the literal word "Current"; discoverability relies on the user learning
  the glyph (a11y needs a `Semantics` label / tooltip).
- Collides with C2 if the leading icon is already tinted to mark "this is a
  setup".

---

## F. Padding and divider mechanics in `setup_list.dart`

### F1 — Drop the row-level `Padding(horizontal: 16)`; every row owns its 16 (recommended)

`_buildRow` stops wrapping rows; tiles keep their `contentPadding: 16`; the setup
tile gets the same. Content inset 32 → 16, dividers already full-bleed, day bands
unchanged. `_isTileRow` starts returning `true` for `SetupEntry`.

**Pros:**
- Achieves the stated goal with the smallest, most honest change — and it's the
  direction Round 2/R4 of the redesign doc already started.
- Every row type then declares its own inset, so there's one place per widget to
  reason about (no invisible outer padding to remember).
- Dividers now separate *all* rows uniformly.

**Cons:**
- `StravaContextWrapper` currently lives inside the padded region; without it the
  orange bar sits flush at x = 0 and the tile's own 16 px is *inside* the wrapper's
  14 px inset → content lands at ~30 px, so wrapped rows will be inset more than
  unwrapped ones. Needs an explicit fix: either shrink the wrapper insets, or pass
  a reduced `contentPadding` to wrapped tiles (`StravaListTile` already accepts
  `contentPadding`; the others don't yet).
- Touches every row type at once (installation, replacement, task, rating,
  strava) — bigger blast radius than the setup widget itself, and each needs a
  light/dark visual check.

### F2 — Keep the row padding, only fix `_isTileRow` (dividers now, padding later)

**Pros:**
- Two-line change; ships the divider consistency immediately with near-zero risk.
- Decouples the shape conversion from the list-wide padding refactor.
- Good phase 1 even if F1 is the destination.

**Cons:**
- Doesn't deliver the 32 → 16 reduction, i.e. the concrete motivation.
- Ships an intermediate look that must be revisited.

### F3 — Keep the padding, but reduce each tile's own `contentPadding` to 0

**Pros:**
- Also lands content at 16 px, and leaves the outer padding available for wrappers
  (Strava bar, current-setup bar) to sit *inside* the safe area rather than flush.
- No change to how `StravaContextWrapper` composes.

**Cons:**
- Every tile then depends on being wrapped by a padded parent — reuse outside the
  timeline (search overlay, task-rule sheet, Strava dashboard) silently loses its
  inset. Fragile in exactly the places the redesign doc flagged as shared.
- Inverts the "widget owns its padding" convention the other tiles follow.

---

## G. `SetupGroupCard` consequences

If a single setup is a tile, a group of setups inside a `Card` becomes the only
card in the list — and `_isTileRow` still returns `false` for it.

### G1 — Convert the group to a full-bleed section: header tile + divided member tiles (recommended)

Group header becomes a tile-shaped row (`"3 Setups"` title, bike/time/place
subtitle), members follow as tiles separated by the same `Divider(height: 1)`,
whole block delimited by dividers top and bottom. Also closes three items on the
Round 2 TODO list (full-width members, dividers between members, `"n Setups"` as
title with bike in the subtitle).

**Pros:**
- The timeline becomes genuinely uniform: no cards at all, one divider rule.
- Members inherit the full row width, so the member chevrons align — the exact
  open TODO.
- Group's current-member highlight (D1) then uses the identical mechanism as a
  standalone current setup.

**Cons:**
- A group loses its containment cue: without a card outline, "these 4 rows belong
  together" must be carried by something else (indent, a left rail, header
  styling, or slightly heavier top/bottom dividers) — needs its own design pass.
- Largest scope item here; arguably a follow-up rather than part of this change.

### G2 — Leave `SetupGroupCard` a `Card` for now

**Pros:**
- Keeps this change bounded to the single-setup row; grouping is behind
  `enableTimelineSetupGrouping` anyway, so the inconsistency is opt-in.
- Preserves the containment cue while the tile conversion settles.

**Cons:**
- Groups become the *only* cards in the stream — visually the odd one out, i.e.
  the problem moves rather than disappears.
- The embedded member path still needs work if `SetupListCard` is restructured
  (B1 changes where the chevron lives), so "leave it alone" is partly illusory.

### G3 — Group renders as an indented sub-list under a header tile (left rail)

Header tile full-bleed; members inset (e.g. 16 px) with a thin vertical rail.

**Pros:**
- Keeps grouping legible without a card, and reads as hierarchy rather than as a
  container.
- The rail vocabulary already exists (`StravaContextWrapper`).

**Cons:**
- A third left-bar meaning (ride / current / group) — the left edge gets crowded.
- Indentation reintroduces a second horizontal rhythm right after we unified one.

---

## H. Non-timeline call sites

### H1 — Card wrapper kept for the search overlay + Strava details, tile in the timeline (recommended)

Pairs with A3, or with A1 plus a thin `SetupCard(child: SetupListTile(...))`
wrapper local to those two call sites.

**Pros:**
- Those lists have no day bands, no dividers and no other event types — a bare
  tile there would read as an unstructured wall.
- Zero risk to two screens that aren't part of this redesign.

**Cons:**
- Two shapes for one object across the app.
- A wrapper widget that exists for two call sites is easy to forget about.

### H2 — Tile everywhere; add dividers in those two lists instead

**Pros:**
- Truly one shape for a setup, app-wide; simplest mental model.
- The Strava details `ExpansionTile` and the search results both already look
  list-like, so dividers fit.

**Cons:**
- Requires touching two unrelated screens (and re-checking the `ExpansionTile`'s
  `childrenPadding: symmetric(horizontal: 16)`, which would double-pad again).
- The search overlay mixes setups with other tiles *without* day headers; without
  cards, setups lose their only distinction there.

---

## I. Tests

### I1 — Widget tests for the tile's states + reuse of the perf guard (recommended)

New `test/widgets/items/setup_list_tile_test.dart`: renders as a `ListTile`;
`Current` badge present/absent by `isCurrent`; score badge gated by
`enableRating`; expand toggle switches the value list; popup menu items respect
`enableRating`. Extend the existing `test/widgets/lists/setup_list_perf_test.dart`
sibling with a divider-presence assertion between adjacent rows.

**Pros:**
- Cheap and targeted; `setup_list_perf_test.dart` already shows how to stand up
  `AppRepository` + `AppSettings` + entitled `SubscriptionService` in a widget
  test, so the harness is copy-paste.
- Locks in the `isCurrent` behaviour, which is the part most likely to regress
  silently since it has four renderings.

**Cons:**
- Widget tests don't catch the actual goal (visual rhythm, inset, dark mode) —
  those need on-device review by you.
- Some risk of asserting layout details that legitimately churn.

### I2 — No new tests (layout-only change)

**Pros:**
- CLAUDE.md explicitly exempts pure-layout tweaks; fastest path.

**Cons:**
- This isn't purely layout: `isCurrent` rendering, the expand-state ownership,
  and `_isTileRow` are logic. The perf guard also asserts widget composition and
  could break in a confusing way.

---

## Recommended combination

**A1** (full conversion) with **H1** (card wrapper retained for search + Strava
details) — i.e. one `SetupListTile` widget, wrapped in a card only where a setup
stands alone. Structure it as **B1** (`ListTile` + below-block, chevron inside the
value block), keep prominence via **C1** typography plus **C2** primary leading
icon, mark current setups with **D1** (left bar + 8 % tint, reusing the group
card's existing treatment) and place the badge per **E1** (title row, before the
score badge). Extract the duplicated badge into one shared widget while you're
there. Tests per **I1**.

Phased so each step is independently reviewable on device:

1. **Phase 1 — divider + padding rhythm (F2 → F1).** Flip `_isTileRow` for
   `SetupEntry`, then drop the row-level padding and fix the
   `StravaContextWrapper` inset. Visible win, no widget rewrite yet.
2. **Phase 2 — the tile itself (A1 + B1 + C1/C2).** Rewrite `SetupListCard` as
   `SetupListTile` on the `RatingEntryListTile` template; keep the `embedded`
   mode working.
3. **Phase 3 — `isCurrent` (D1 + E1).** Shared `CurrentSetupBadge` +
   `CurrentSetupHighlight`; delete the three duplicated badge bodies; unify the
   standalone and grouped current-setup look.
4. **Phase 4 (optional follow-up) — G1**, converting `SetupGroupCard` into a
   full-bleed section and clearing the Round 2 TODOs. Ship **G2** in the meantime.

Rationale for the shape of this: phases 1 and 3 each deliver a standalone
improvement even if the rest stalls, and phase 4 is the only item with an open
design question (how a group signals containment without a card), so it must not
block the rest.

---

## Open questions for the final plan

1. **C vs. D collision:** if the leading icon is tinted `primary` to mark "this
   is a setup" (C2) *and* current setups use `primary` bar + tint (D1), primary
   means two things. Options: setup icon uses `primary`, current uses
   `primary` bar + tint + badge (probably still distinguishable), or setup icon
   uses `onSurface` bold and current owns `primary` exclusively. Which?
2. **Bar nesting:** a current setup recorded during a ride gets the orange Strava
   bar *and* the primary current bar. Two stacked 4 px bars, one replacing the
   other, or the current state moves to E3 (leading icon) so the left edge stays
   single-purpose?
3. **Expand affordance (B1):** explicit `ExpandIcon` at the end of the value
   list, or make the value block itself tappable like `TaskEntryListItem`'s stat
   box? The latter competes with the row's navigate-to-details tap.
4. **Font sizes:** normalise the setup row to the other tiles' 12 px metadata and
   plain bold title (maximum consistency), or keep 13 px + `titleMedium` as the
   prominence mechanism (C1)? This is the concrete form of "how special is a
   Setup".
5. **Strava-wrapped inset (F1):** shrink `StravaContextWrapper`'s
   `_barWidth + _contentInset` so wrapped rows land at 16 px too, or add a
   `contentPadding` parameter to the remaining tiles? Only `StravaListTile` has
   one today.
6. **Rename?** `SetupListCard` → `SetupListTile` matches the naming of the four
   event tiles but touches four call sites and one test comment. Do it in
   phase 2, or keep the old name to shrink the diff?
7. **Is `SetupGroupCard` in scope now (G1) or a follow-up (G2)?** Related: does
   the group header row itself get a divider treatment, and does a group still
   suppress the `Current` marker at group level (Round 2 said yes)?
8. **Search overlay:** it mixes setups with other event tiles and has no day
   headers. Does H1's card wrapper apply there, or should that list get day
   headers so a bare tile works?
