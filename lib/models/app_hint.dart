enum AppHint {
  garageGesturesV1,
  gettingStartedV1,
  setupTasksV1,
  setupCalendarV1,
  setupComparisonV1,
  stravaLinkGearV1,
  installationTimelineV1,
}

/// "What's new" hints, keyed by the `AppInfo.buildNumber` they shipped in.
///
/// A hint listed here is announced to everyone who updates past that build and
/// stays pending until it is handled, so users who skipped releases catch up
/// one feature per app start. Only add features that are easy to miss, and keep
/// it to one or two per release — drop entries once they are no longer worth
/// announcing.
///
/// Each entry needs an [AppHint] value, a build, and a widget in `AppHintSlot`.
const Map<AppHint, int> releaseHintBuilds = <AppHint, int>{};

enum AppHintPlacement {
  garageHeader,
  setupHeader,
  setupComparison,
  stravaDashboardGear,
}

enum AppHintStatus {
  unseen,
  dismissed,
  completed,
}
