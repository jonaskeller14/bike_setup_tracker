# 03_features: voiceover scripts

Voiceover for the six Shorts of kit `03_features` ([plan](../shorts-batch-2.md)), voice **Rowan HD**
in [speechma](https://speechma.com). speechma takes at most 2,000 characters per run, so the takes
are pasted in batches. Each batch's text is `tool/marketing/assets/voice/03_features/batch-N.md`
(tracked: paste it as is) and its audio `batch-N.mp3` next to it (gitignored). The build splits a batch at the
spoken slates ("Clip 12."), drops the slates, trims the silence and times the captions to the
sentences. A blank line gives a ~1.2 s pause, so every paragraph is a sentence the build can move on
its own.

## Style

- Simple words, short sentences. Say it the way you'd explain it to a friend.
- Open with the hook from [`../messaging.md`](../messaging.md), word for word, then **the scenario**: who
  the rider is and what they want ("You just had a bike fit…"). Then what they do in the app, then the
  payoff.
- One feature per Short. Share (a setup as text) and export (everything to Excel) are two Shorts.
- Every spoken number comes from the sample dataset. Paid parts (Strava Sync) and opt-in features
  (Settings → Features) go in the post text, not in the voice.
- Full takes: 20–28 s. Short takes: 8–12 s, for a cut with less voice.

## Takes

Batch 1 (clips 1–9) is the first, denser style; batches 2 and 3 are the simpler, scenario-first
style. Pick per Short when editing; sentences can be mixed across takes.

| Short | Hook | Simple, full | Simple, short | First style (A / B) |
|---|---|---|---|---|
| `bike-fit` | R11 | 10 | — | 1 / 2 |
| `swap` | R12 | 11 | — | 3 / 4 |
| `share` | D4 | 12 | 18 | 5 / 6 (also mentions export) |
| `export` | D5 | 13 | 19 | — |
| `histogram` | C8 | 14 | 16 | 7 / 8 |
| `service-loop` | S4 | 15 | 17 | 9 / — |
| End card | — | 20 (free on iOS and Android), 21 (search the stores) | | |

### Facts behind the scripts

- `bike-fit`: Canyon Grizl, *Saddle Height* 745 mm in the sample. Setback, stem and spacers aren't in
  the sample yet; they appear on screen only.
- `swap`: Crankbrothers Stamp 7 Pedals; the sample already moves them Hightower → Session → Hightower.
  The history table is the opt-in *Installation timeline*, offered at the first drag.
- `share`: setup tile menu → *Share* → system share sheet with the setup as text.
- `export`: home menu → *Share Data* → *Excel Spreadsheet* (also CSV, JSON, plain text).
- `histogram`: rides per value on the component's details page; hold a bar for its ride count. The
  Short uses take 14 without its last line (the bold current value is only in the setup page's
  tooltip). Needs the Strava sample at 100+ rides; no counts are spoken.
- `service-loop`: *Fork lowers service*, every 50 h of riding (moving time from Strava). Needs the
  `service_loop` scenario, where rides arrive during the recording.

### Captions (draft)

| Short | Captions |
|---|---|
| `bike-fit` | `What *saddle height* did your bike fit give you?` · `Your *bike fit*, as a setup` · `Pack the bike, *set it back*` · `745 mm. *Saved.*` |
| `swap` | `Which bike are your *pedals* on right now?` · `Hold and *drag* to the other bike` · `Saved *with the date*` · `One garage. *Every part.*` |
| `share` | `Your riding buddy wants your *fork settings*?` · `You won't remember *every click*` · `Menu → *Share*` · `Every value, *in one text*` · `Same settings. *Ready to ride.*` |
| `export` | `Want all your *bike setups* in a spreadsheet?` · `Season over? *Look back.*` · `Share Data → *Excel*` · `Every bike, *every setup*` · `No account. *Your data stays yours.*` |
| `histogram` | `Which *tire pressure* have you ridden the most?` · `Your setups + *your Strava rides*` · `Taller bar, *more rides*` |
| `service-loop` | `When did you last service your *fork*?` · `Every *50 hours* of riding` · `Enough rides: *it's due*` · `Tick it off: *back to zero*` |

## When listening

- "745 millimetres": spoken as a number (fallback: "seven hundred forty-five millimetres")
- "CSV", "JSON" (clip 5): letters, and "Jason"
- "Strava": stress on the first syllable
- Length: full takes 18–28 s, short takes 8–12 s

## Batches

| Batch | Text | Clips | Audio |
|---|---|---|---|
| 1 | [`batch-1.md`](../../../tool/marketing/assets/voice/03_features/batch-1.md) | 1–9 (first style) | `batch-1.mp3`, 154 s; takes 20.0 / 10.7 / 18.4 / 7.6 / 19.7 / 7.8 / 17.2 / 8.4 / 19.1 s |
| 2 | [`batch-2.md`](../../../tool/marketing/assets/voice/03_features/batch-2.md) | 10–14 (simple, full) | `batch-2.mp3`, 129 s; takes about 26 / 22 / 25 / 23 / 20 s |
| 3 | [`batch-3.md`](../../../tool/marketing/assets/voice/03_features/batch-3.md) | 15–21 (service full, short takes, end card) | `batch-3.mp3`, 87 s |

A new take goes into a new batch file with the next clip numbers; a generated batch's text is never
edited, so it always matches its MP3.
