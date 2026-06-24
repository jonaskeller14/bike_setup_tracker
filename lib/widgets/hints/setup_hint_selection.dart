import '../../models/app_settings.dart';

/// Which suggestion hint (if any) the Setup timeline should show.
enum SetupHint { none, task, calendar }

/// Selects at most one suggestion hint for the Setup timeline.
///
/// Rules (see `SetupList`):
/// - Nothing shows once a hint was dismissed or acted on this session
///   ([AppSettings.hintShownThisSession]).
/// - The Task hint takes priority over the Calendar hint when both qualify.
/// - Task hint: tasks still off and at least one setup recorded.
/// - Calendar hint: calendar still off and either ≥2 setups or >2 Strava
///   activities loaded.
SetupHint selectSetupHint({
  required AppSettings settings,
  required int setupCount,
  required int stravaActivityCount,
}) {
  if (settings.hintShownThisSession) return SetupHint.none;

  if (settings.showSetupTaskHint && !settings.enableTask && setupCount >= 1) {
    return SetupHint.task;
  }

  if (settings.showSetupCalendarHint &&
      !settings.enableCalendar &&
      (setupCount >= 2 || stravaActivityCount > 2)) {
    return SetupHint.calendar;
  }

  return SetupHint.none;
}
