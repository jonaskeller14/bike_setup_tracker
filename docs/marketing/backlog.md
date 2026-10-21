# Short topics: backlog

Evergreen Short topics that haven't been made yet. A batch picks from here (see
[`shorts-batch-2.md`](shorts-batch-2.md), section 1, for how batch 2 picked), then removes what it
made. Before picking a topic, check it against the latest release tag: demos show only shipped,
release-build features (no presets, ratings, pressure check, riders or bookmarks).

| Topic | Shows | Shipped as | Notes |
|---|---|---|---|
| Rides per value, from the setup | On a setup page, tap an adjustment's name (e.g. the rear tire's *Pressure*): a small histogram of rides per value, the current value in bold | Strava Sync, paid | Second half of batch 2's `histogram` Short, cut for pacing. Little-known feature. Maestro steps that worked (scenario `histogram`): Setups → tap `"(?s).*Hometrails - back to neutral.*"` → `scrollUntilVisible` `Rear Tire` (centred) → `tapOn` text `"Tire\nPressure\nInsert\n"` at `point: 20%,61%` (the name isn't its own element); the tooltip stays 5 s |
| Find an old ride | Strava with 100+ rides: search offline, find an old ride, *View on Strava* | Strava Sync, paid | Overlaps the `map` Short (batch 1); needs a bigger Strava sample |
| Bike details and component table | Bike details table and charts; component table with filter and column selection | Core, free | Good long-form material, a lot to explain in a Short |
| Text adjustments | A text value on a component, e.g. "Saddle: SMP Lite 209" | Opt-in (Settings → Features) | Weak visual on its own; could be one shot in a bike-fit follow-up |
| Add a missing component or adjustment from the setup page | — | — | v1.6.3 shows only an empty-state hint (`setup_page_tab_bike.dart`), no add flow. Check before planning |
| Pressure check, component presets, task presets | — | Not shipped (developer mode only) | Wait until released |
