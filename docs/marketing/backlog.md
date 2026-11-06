# Short topics: backlog

Evergreen Short topics that haven't been made yet. `/marketingkit <topic>` builds one into a kit; a
monthly batch (`/marketingkit monthly`, see [`README.md`](README.md#monthly-rhythm)) takes four.
Once a topic has a Short in a kit, delete its row here.

Every topic carries a pillar and an audience from [`messaging.md`](messaging.md):

- **Pillar:** R remember what worked · C see what changed · S service on time · D your data stays yours.
- **Audience:** MTB suspension · Tires (gravel and road pressure) · Maint (maintenance-minded).
- **Hook:** an ID from the headline bank. `new` means the line goes into the bank first (EN + DE,
  bike context, a question), then into the kit.

**Pick rules.** Spread a batch over at least three pillars and two audiences. Check each topic
against the latest release build before planning (`messaging.md`, Pillars; `channels.md`): demos
show only shipped, release-build features, so no ratings, pressure check, setup guides, riders or
bookmarks; the fork and shock catalog and suggested service tasks only from v1.6.4. A feature that is off by default carries "Switch it on under Settings → Features" in the
post; Strava Sync is the only paid part and is named wherever a topic needs it.

## Ready: core features, free

| Topic | Pillar | Audience | Hook | Shows | Notes |
|---|---|---|---|---|---|
| Back to the setup that worked | R | MTB | R10 | Open the setup from a trip: every fork and shock value, plus the weather and place it was ridden in | Scenario `full`. Overlaps `core`'s history; keep the focus on opening an old one. Format idea: two riders talking as kinetic type ("What's your rebound at?" "Nine. No, eleven?"), then one opens the old setup; see Production ideas |
| Tire pressure, front and rear | R | Tires | R5 | Add a gravel bike's tires with a pressure each, set the value, save | Needs a gravel-bike scenario; check psi and bar both appear before naming bar |
| Set your sag | R | MTB | new | The sag adjustment on a fork or shock: percent and the reference travel | Hook idea: "How much sag are you running on your fork?" / "Wie viel Sag fährst du an deiner Gabel?" Motion: a stanchion line compressing, percent and mm moving together (mm = % × travel). The sample has no sag adjustment, so it needs a scenario. Records the rider's number, never suggests one. Check what the page shows and how to reach it before storyboarding |
| Flip chip and other choices | R | MTB | new | A categorical adjustment on the frame, e.g. flip chip high or low, saved in a setup | Weak alone; could be one shot of a bike-fit follow-up |
| Restore a deleted setup | D | MTB | new | Delete a setup, open the trash, restore it | Hook idea: "Deleted the wrong fork setup?" / "Das falsche Gabel-Setup gelöscht?" Mostly screen; one small drawn rule for the 30 days before the trash empties. Check the trash flow and its confirmation dialog |
| New phone, same data | D | MTB | new | Share Data → JSON, then the import on a second install | Hook idea: "Where do your fork settings actually live?" / "Wo liegen deine Gabel-Einstellungen eigentlich?" Motion: a phone with the database inside, no account, local backups, export lines to Excel, CSV and JSON. Say "stored on your phone, no account", never "nothing leaves your phone": the app also has Firebase Analytics and Crashlytics, the Open-Meteo lookup and optional Strava Sync. Check the import flow exists in the release build before planning |
| Bike details and component table | C | Maint | C4 | Bike details table and charts; component table with filter and column selection | Good long-form material, a lot to explain in a Short |
| Edit an adjustment, your recorded values follow | C | MTB | new | Change an adjustment's range or steps: the value migration sheet with its before/after preview | Since v1.6.4. Advanced and mostly troubleshooting: low priority, better as a carousel tip than a Short. Needs a scenario with recorded values |
| Add a missing component or adjustment from the setup page | R | MTB | new | — | v1.6.3 shows only an empty-state hint (`setup_page_tab_bike.dart`), no add flow. Check before planning |

## Ready: opt-in features (Settings → Features)

| Topic | Pillar | Audience | Hook | Shows | Notes |
|---|---|---|---|---|---|
| Maintenance reminders | S | Maint | S5 | Interval types and the due prediction, with callouts on the interval choice; the garage indicator for what's due | Phase 9 of #77. Needs a flow and a scenario. Tasks are opt-in; km intervals need Strava Sync. Motion: one ride, four counters on one timeline: km, hours and rides move, months tick on regardless (sample: chain 2,000 km, fork 50 h, brake bleed 25 rides, sealant 120 days). Hook idea: "Km, hours or months: what does your fork service count?" / "Kilometer, Stunden oder Monate: Was zählt dein Gabel-Service?" One interval per task, so never "whichever comes first" |
| One day, four records | C | Maint | new | Setups, rides, parts and service converging on one date, then the calendar's showcase day | Hook idea: "What happened to your bike in May?" / "Was war im Mai an deinem Bike los?" Flow `demo_calendar` and its data exist. Calendar is opt-in; rides need Strava Sync. A voiced remake of the silent `calendar` Short, so the least new topic here |
| Attachments | D | Maint | new | A manual or photo on a component or setup | Phase 9. Seed the attachments in the scenario; the file picker can't be automated |
| Installation timeline | R | Maint | new | Usage tracking per part and its history on the timeline | Phase 9. Pairs with the subcomponents rows; check which flag each part needs. Motion: the bike as a long rule, parts entering and leaving as bars. Hook idea: "How long has that fork been on your bike?" / "Wie lange ist die Gabel schon an deinem Bike?" Scenario `swap` has the flag on |
| Subcomponents | R | Maint | new | The hierarchy; swapping a parent moves its children | Phase 9. `swap` (batch 2) moved a part between bikes; this moves one between components. Motion: a tree of bike → wheel → tire; move the wheel and the tire follows, and a ride counts for each level. Hook idea: "Swapped your wheelset: which tires came along?" / "Laufräder getauscht: Welche Reifen sind mitgekommen?" The sample has no wheels, so it needs a scenario |
| Move parts between components | R | Maint | new | Drag and drop a part from one component to another | Phase 9. Same Maestro slow-swipe trick as `swap` |
| Tag your setups | R | MTB | new | Tags such as "wet" or "race" on setups, then filtering by one | Scenario `tags` exists. Tags are off by default |
| Count your tokens | R | MTB | new | A counted-select adjustment, e.g. volume spacers | Opt-in (Multi-select / Counted select). Weak visual alone; pair with sag |
| Text adjustments | R | MTB | new | A text value on a component, e.g. "Saddle: SMP Lite 209" | Weak visual on its own; could be one shot in a bike-fit follow-up |

## Ready: Strava Sync (paid)

| Topic | Pillar | Audience | Hook | Shows | Notes |
|---|---|---|---|---|---|
| Find an old ride | R | MTB | R10 | Strava with 100+ rides: search offline, find an old ride, *View on Strava* | Overlaps the `map` Short; needs a bigger Strava sample |

## Platform-specific

| Topic | Pillar | Audience | Hook | Shows | Notes |
|---|---|---|---|---|---|
| Back up to Google Drive | D | MTB | D2 | Settings → Google Drive backup and restore | Android only (guarded at runtime). Post only on Android-facing copy; leave it out of store text |
| Log a setup from the home screen | R | MTB | new | Long-press the app icon → *Add setup* | Maestro can't drive the home screen, so this would break the "every demo is a Maestro take" policy. Probably an Android-only manual take, or drop |

## Waiting for a release

| Topic | Shipped as | Notes |
|---|---|---|
| Pressure check | Not shipped (developer mode only) | Wait until released |
| Setup guides | Not shipped (developer mode only) | Wait until released |

## Production ideas

- **Two-voice voiceover (speechma interviews).** speechma can voice a dialogue: start each line
  with `A:` or `B:` (or two names, like `Host:` and `Guest:`), then pick a voice for each. Could
  suit a Short built as a conversation between two riders (e.g. "Which clicks did you ride?"). Before
  using it, check that `tool/marketing/voice.py` still splits the batch into lines, since speaker
  prefixes are new to it. Noted 2026-10-29; not used in `04_v1.6.4`.

## Reminders

- **Re-check the competitor comparison** (#77 Phase 11) every 6 months once the page exists; its
  claims each carry a "checked on" date.
