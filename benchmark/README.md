# Startup benchmark

Times app start against a generated heavy-user dataset (`startup_dataset.dart`):
10 bikes over 5 years, ~10k Strava activities, wear parts replaced on a schedule
(retired and archived generations), subcomponents three levels deep, front wheels
swapped between bikes, partial setups, task rules with completion history, and a
few recently trashed rows. Generation is seeded and dated relative to today, so
every run sees the same shape of data.

```bash
flutter test benchmark/startup_benchmark_test.dart
```

The folder is outside `test/`, so CI and a plain `flutter test` skip it.

## What it measures

- **app start**: the repository's construction, `initialize()` and the initial
  streams, in the order `main()` and `LoadingGate` run them, on a file database
  opened like the app's. "gate opens" is when the UI mounts; "settled" is the
  last change notification; "notifications" counts the rebuilds the home page
  would get.
- **startup queries**: each query alone on a fresh connection, to show which
  one dominates.
- **strava sync**: `setStravaActivities` on a settled app, for one new
  activity and for re-delivering every activity unchanged (what a relaunch
  sync does). Each run starts from a copy of the seeded database.

It stops at the data layer. Widget build, plugin start-up and Firebase aren't
included, and it runs on the host VM. Compare runs on the same machine. A phone
is several times slower.

Task-entry snapshots are left empty: a full snapshot refresh takes hours at
this size (see "one task snapshot" × the entry count). Start only reads
the stored column, so the timings don't depend on them.

## Results

Medians in ms. Add a row when you change something on the startup path.

| Date | Commit | Machine | gate opens | stats loaded | settled | notifications | Notes |
| ---- | ------ | ------- | ---------: | -----------: | ------: | ------------: | ----- |
| 2026-10-25 | eeccebde | Windows 11, host VM | 3355 | 1367 | 3326 | 24 | Baseline; componentStats query 1191, setups 368, one task snapshot 1114 |
| 2026-10-25 | eeccebde + Phase 1 | Windows 11, host VM | 4613 | 2073 | 4550 | 24 | Startup path unchanged; machine ran ~35% slower than the baseline (componentStats 1665, one task snapshot 1317). Sync: one new activity 2970 (no snapshot refreshed; waits behind the Strava watch queries the write re-runs), unchanged re-delivery of 10k activities 516 (was a full refresh, ≈ 2376 × 1.1 s ≈ 44 min) |
