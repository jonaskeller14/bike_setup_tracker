# Messaging

What Bike Setup Tracker says, to whom, and where. Part of
[#77](https://github.com/jonaskeller14/bike_setup_tracker/issues/77) Phase 1; the look is in
[`brand.md`](brand.md). Every headline on a store asset, Short, post or web page comes from the
bank below. A new headline goes into the bank before it goes onto an asset.

## Positioning

> For mountain bikers and cyclists who tune their own bike, **Bike Setup Tracker is the logbook
> for suspension, tire pressure and service.** It keeps every click and psi together with the
> ride and the conditions it belonged to, so you can go back to what worked. It doesn't tell you
> what to set: it keeps *your* record. No account, and the data stays with you.

> Für Mountainbiker und Radfahrer, die ihr Bike selbst einstellen, ist **Bike Setup Tracker das
> Logbuch für Fahrwerk, Reifendruck und Wartung.** Es speichert jeden Klick und jeden Druck
> zusammen mit der Ausfahrt und den Bedingungen, damit du zu dem zurückkommst, was funktioniert
> hat. Es sagt dir nicht, was du einstellen sollst: Es führt *dein* Protokoll. Ohne Account, und
> die Daten bleiben bei dir.

**Is / is not:** a logbook, not an AI tuner or a suspension calculator. Copy never claims the app
finds, recommends or optimizes a setting; the rider does, the app remembers.

## Pillars

| # | Pillar | Proof in the app | Flag state |
|---|---|---|---|
| R | **Remember what worked** | Setups with every fork, shock, tire and cockpit value; weather and location filled in automatically | Released |
| C | **See what changed** | Setup history with `9 → 10` diffs, setup comparison, line and radial charts | Released |
| S | **Service on time** | Tasks with date intervals; distance-based intervals and component km with Strava | Tasks are opt-in (Settings → Features); km needs Strava, the one paid add-on |
| D | **Your data stays yours** | No account, no ads, local database, export to Excel, CSV and JSON | Released |

Content for S always carries "Switch it on under Settings → Features"; km-based service also
names Strava. Before a post goes out, every named capability is flag-checked against the release
build.

## Audiences

| Audience | Cares about | Their words (EN) | Their words (DE) | Lead pillars |
|---|---|---|---|---|
| **MTB suspension** (primary: trail, enduro, downhill) | Getting fork and shock right, and getting back to it | fork, shock, clicks, rebound, compression, sag, tokens, psi | Federgabel, Dämpfer, Klicks, Zugstufe, Druckstufe, Sag, Tokens | R, C |
| **Gravel and road tire pressure** | Pressure per tire, surface and weather | tire pressure, psi, bar, tubeless, gravel | Reifendruck, Luftdruck, bar, Tubeless, Gravel | R, D |
| **Maintenance-minded** (home mechanics, eMTB owners) | Services on time, part history | service, fork lowers, chain, intervals, km | Service, Wartung, Kette, Intervall, km | S, R |

## Rules

- **Bike context in every headline.** Each one names the bike, a part or a bike unit: MTB, fork,
  shock, suspension, tire pressure, clicks, psi (DE: MTB, Federgabel, Dämpfer, Fahrwerk,
  Reifendruck, Klicks). "Setup" or "Fahrwerk" alone is too generic.
- **One headline per store-funnel surface.** The search asset, header, Play feature graphic and
  screenshot 1 each use a different headline (table below). The OG image and Shorts sit outside
  the funnel and may repeat a funnel headline.
- **No price on store assets.** "Free" only appears on social end cards, smallest (brand.md).
- **Numbers are real.** A value on an asset comes from the sample dataset or a real screenshot,
  never invented. Default pair: Lyrik pressure 84 → 85 psi, LSC 7 → 8, rebound 9 → 10
  ("Hometrails – angleset test").
- **Questions are hooks, statements are headlines.** Question lines (R3, C5, S4) open Shorts and
  posts; store assets use statements.
- **Variety over one slogan.** Pick from the whole bank instead of repeating one line. R7
  ("sweet spot", the v1 headline) is a good line, but goes on one store surface at most.

## Headline bank

IDs stay stable; reference them in kits and post files (e.g. `headline: C1`). DE is written for
German riders, not translated word for word.

### R — Remember what worked

| ID | EN | DE |
|---|---|---|
| R1 | Every click. Every psi. Every ride. | Jeder Klick. Jeder Druck. Jede Ausfahrt. |
| R2 | Fork and shock settings, remembered. | Gabel und Dämpfer: kein Klick geht verloren. |
| R3 | Which clicks did you ride last weekend? | Mit wie vielen Klicks bist du letztes Wochenende gefahren? |
| R4 | The logbook for your MTB suspension. | Das Logbuch für dein MTB-Fahrwerk. |
| R5 | Tire pressure for every gravel ride, logged. | Reifendruck für jede Gravel-Runde, notiert. |
| R6 | Every fork setup, with the weather it was ridden in. | Jedes Gabel-Setup, mit dem Wetter der Ausfahrt. |
| R7 | Never lose your suspension sweet spot. | Nie wieder den Sweet Spot deines Fahrwerks verlieren. |
| R8 | Back to the fork setup that worked. | Zurück zum Gabel-Setup, das funktioniert hat. |

### C — See what changed

| ID | EN | DE |
|---|---|---|
| C1 | Rebound 9 → 10. See what changed. | Zugstufe 9 → 10. Sieh, was sich geändert hat. |
| C2 | Two suspension setups, side by side. | Zwei Fahrwerks-Setups im direkten Vergleich. |
| C3 | Find the fork setting that works for you. | Finde die Gabel-Einstellung, die zu dir passt. |
| C4 | Every change to your MTB, at a glance. | Jede Änderung an deinem MTB auf einen Blick. |
| C5 | Was it the rebound or the tire pressure? | War es die Zugstufe oder der Reifendruck? |

### S — Service on time

| ID | EN | DE |
|---|---|---|
| S1 | Never miss a fork service. | Nie wieder den Gabel-Service verpassen. |
| S2 | Fork, shock, chain: serviced on time. | Gabel, Dämpfer, Kette: Wartung pünktlich. |
| S3 | Your bike's service log, always current. | Das Wartungsbuch für dein Bike, immer aktuell. |
| S4 | When did you last service your fork? | Wann war dein letzter Gabel-Service? |

### D — Your data stays yours

| ID | EN | DE |
|---|---|---|
| D1 | Your suspension log. No account. | Dein Fahrwerks-Logbuch. Ohne Account. |
| D2 | Your bike data stays with you. | Deine Bike-Daten bleiben bei dir. |
| D3 | Export every bike setup: Excel, CSV, JSON. | Jedes Bike-Setup exportieren: Excel, CSV, JSON. |

### Signature

**78 psi. 4 clicks. Saved.** / **78 psi. 4 Klicks. Gespeichert.**
Echoes the app icon. Only next to the icon (end card, avatar, channel art), whose bike gives the
context; not a standalone headline.

## Surfaces

| Surface | Headline | Why |
|---|---|---|
| App Store search results asset | **R4** | Names the category in the first glance; next to real UI |
| App Store header | **R2** | Type-only header (brand.md): the headline above a row of fork values |
| Play feature graphic | **C3** | The outcome, short enough for 1024×500 |
| Search asset, store test | R7 | The live v1 headline; Phase 6 tests it against R4 |
| Screenshot 1 (garage) | **R1** | The garage screen shows the values: pressure, LSC, rebound per part |
| OG image (website) | R4 | Outside the store funnel; the same promise as the search asset |
| Website hero | R4 | Matches the OG image a shared link shows |
| Website sections 01–04 | R8, C4, S1, D2 | One per pillar, in pillar order; none repeats a store-funnel headline |
| Website end card (download section) | Signature | Next to the mark, like the social end card |
| End card (Shorts, walkthrough) | Signature | Next to the icon; the name is the hero (brand.md) |
| Short hooks | R3, C5, S4 | Questions; one per Short, from the pillar the Short shows |

Screenshots 2–8 keep one pillar each; their captions are reworked in Phase 5.
