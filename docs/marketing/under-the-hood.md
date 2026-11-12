# Under the hood: talking points

The app is easy to underestimate as "a notes app for suspension clicks". This file collects what is
behind it, for audiences who ask how it works: r/FlutterDev, r/SideProject, the MTB-News Tech Talk
forum, tech-minded replies in rider threads, and long-form posts. Rider-facing headlines still come
from [`messaging.md`](messaging.md); nothing here replaces the logbook positioning.

**Rule:** the [channel rules](channels.md#rules-for-every-channel) apply. Only points marked
**Released** go into a post. Check the state against the latest release build before posting, and
name the opt-in toggle or Strava Sync where a point needs it.

## One line

> It started as a notes app for fork clicks and grew into a small parts-and-service system for your
> bikes: what's installed where, since when, set how, and what's due next. It runs offline,
> without an account.

> Angefangen hat es als Notiz-App für Gabel-Klicks. Inzwischen ist es eine kleine Teile- und
> Wartungsverwaltung für deine Bikes: was wo verbaut ist, seit wann, wie eingestellt und was als
> Nächstes fällig ist. Offline und ohne Account.

## Released

| Topic | What the rider sees | How it works | Toggle | Fits |
|---|---|---|---|---|
| **Sub-components** | Wheel on the bike, tire on the wheel, as deep as you like. Move the wheel, the tire comes along and keeps counting km | The installation records are the only source of truth. A part's bike is resolved through its parents, so moving a parent writes nothing for its children. Strava stats are inherited down the tree | Settings → Features | MTB-News, r/bikewrench, r/SideProject |
| **Installation timeline** | Every part's history: which bike, from when to when, what replaced it | Timeline rows built from installation events; replacements are detected and paired automatically | Settings → Features | MTB-News, r/bikewrench |
| **Service due prediction** | "Fork service in about 3 weeks" instead of only "14 h left" | Projects the remaining km, hours or rides with the rider's own pace over the last 10 activities (looking back at most 180 days) | Tasks; km and hours need Strava Sync | r/bikewrench, MTB-News |
| **Rides arrive by themselves** | Rides show up next to the setup that was on the bike, by date and gear | Strava webhook → queued, idempotent Cloud Functions workers; subscriptions are validated server-side for both stores | Strava Sync (paid) | r/FlutterDev, r/SideProject |
| **Values follow your parts** | Swap a fork and the next setup knows which values still fit, and which need a decision | Setup carry-over checks each value against the new part's adjustment range; setup comparison lines up similar components with a Hungarian assignment, so columns don't jump | on by default | r/SideProject |
| **Fork and shock catalog** | A new fork comes with its click ranges filled in | Versioned brand files; fixes to a revision are applied silently, changes a rider has to accept are kept as reviews on the component page | on by default (v1.6.4) | rider threads |
| **Offline-first, no account** | Works in the bike park without signal; data stays on the phone | Drift/SQLite as the main copy, explicit append-only schema migrations (version 27), soft deletes with a 30-day trash | on by default | r/FlutterDev, privacy questions |
| **Six languages** | English, German, French, Italian, Spanish, Portuguese | Written for riders, not word for word: "rebound" is Zugstufe, détente, rebote | on by default (v1.7.0) | country communities |
| **Built and tested solo** | | About 100,000 lines of Dart, about 350 test files (unit, widget, golden, migration), CI on GitHub Actions, store screenshots from Maestro flows, Shorts rendered with Hyperframes (counted 2026-11-12, recount before using) | | r/FlutterDev, r/SideProject |

## In development: don't post yet

| Topic | What it will do | How it works | Before posting |
|---|---|---|---|
| **Cloud sync** ([#17](https://github.com/jonaskeller14/bike_setup_tracker/issues/17)) | Same data on iPhone and Android, with the app still working offline | Each record is mirrored as one Firestore document. An outbox filled by SQLite triggers holds local changes until they are pushed. Conflicts resolve per record by last writer wins, and the server enforces it in the security rules. Each device has its own session, created by connecting Strava | Release, then remove the Drive beta |
| **Service reminders from the server** (#17, Phase 8) | A push notification when a ride makes a service due | The app writes the gear distance at which each task is due; the Strava webhook compares it and sends an FCM message | Release |
| **Test sessions** (debug-only, `enableRating`) | Structured test rides: ride a few setups, say which felt better, see which one wins and which dial made the difference | Three methods. *Compare*: round robin, ranked with Bradley-Terry. *Explore*: two-level Hadamard design, one run per dial. *Fine-tune*: Hooke-Jeeves compass search with an A-B-A confirmation. Dial effects come from logistic regression with a ridge prior, pooled over all sessions on the bike | **Positioning decision first:** the app would propose values, which `messaging.md` currently rules out ("never finds, recommends or optimizes") |
| **Pressure check** (debug-only) | Shows what your pump will read today for the pressure you set last week in the cold or at altitude | Converts between gauge and absolute pressure with the ideal gas law, using the temperature and elevation recorded with each setup | Release; check the copy with a rider who doesn't do physics |

## Angles per channel

- **r/FlutterDev:** one architecture topic per post, not the whole list. Candidates: offline-first sync
  with an SQLite-trigger outbox (once #17 ships), deriving a component tree from installation events,
  or the screenshot and Shorts pipeline (`channels.md`).
- **r/SideProject:** the scope story: from a notes app to parts, service and Strava, built solo, with
  what was learned. Screens, not a feature list.
- **MTB-News (Tech Talk → Elektronik rund ums Bike):** sub-components and service prediction, asked
  as feedback questions ("Wie zählt ihr Kilometer, wenn Laufräder zwischen Bikes wandern?").
- **r/bikewrench:** service prediction and part history, as a real question about intervals.
- **Replies to "how does it know…?"** in any thread: take the "How it works" cell, in plain words.
