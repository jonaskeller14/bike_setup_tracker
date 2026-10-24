import 'component/resolved_installation.dart';
import 'feedback/ride_feedback.dart';
import 'feedback/test_session.dart';
import 'setup.dart';
import 'strava/strava_activity.dart';
import 'task/task_entry.dart';

sealed class TimelineEntry {
  String get id;
  DateTime get dateUTC;
  DateTime get dateLocal;
}

class SetupEntry extends TimelineEntry {
  final Setup setup;
  SetupEntry(this.setup);
  @override
  String get id => 'setup:${setup.id}';
  @override
  DateTime get dateUTC => setup.datetime;
  @override
  DateTime get dateLocal => setup.datetimeLocal;
}

class StravaEntry extends TimelineEntry {
  final StravaActivity activity;
  StravaEntry(this.activity);
  @override
  String get id => 'strava:${activity.id}';
  @override
  DateTime get dateUTC => activity.startDate;
  @override
  DateTime get dateLocal => activity.startDateLocal;
}

class TaskTimeLineEntry extends TimelineEntry {
  final TaskEntry taskEntry;
  TaskTimeLineEntry(this.taskEntry);
  @override
  String get id => 'task:${taskEntry.id}';
  @override
  DateTime get dateUTC => taskEntry.dateTimeUTC;
  @override
  DateTime get dateLocal => taskEntry.dateTimeLocal;
}

class InstallationEntry extends TimelineEntry {
  final ResolvedInstallation componentInstallation;
  InstallationEntry(this.componentInstallation);
  @override
  String get id => 'inst:${componentInstallation.installation.id}';
  @override
  DateTime get dateUTC => componentInstallation.installation.dateTimeUTC;
  @override
  DateTime get dateLocal => componentInstallation.installation.dateTimeLocal;
}

class FeedbackTimelineEntry extends TimelineEntry {
  final RideFeedback feedback;
  FeedbackTimelineEntry(this.feedback);
  @override
  String get id => 'feedback:${feedback.id}';
  @override
  DateTime get dateUTC => feedback.dateTimeUTC;
  @override
  DateTime get dateLocal => feedback.dateTimeLocal;
}

class TestSessionTimelineEntry extends TimelineEntry {
  final TestSession session;
  final List<Setup> runs; // Oldest first, never empty.

  /// Run id → the feedbacks that rate it, oldest first.
  final Map<String, List<RideFeedback>> feedbacksByRun;

  TestSessionTimelineEntry(this.session, {required this.runs, this.feedbacksByRun = const {}})
    : assert(runs.isNotEmpty, 'a session item holds at least one run');

  @override
  String get id => 'session:${session.id}';
  @override
  DateTime get dateUTC => runs.first.datetime;
  @override
  DateTime get dateLocal => runs.first.datetimeLocal;

  /// When the session ended, or its latest run or feedback while it runs.
  DateTime get endLocal {
    if (session.endedAtLocal case final ended?) return ended;
    var latest = runs.last.datetimeLocal;
    for (final feedback in feedbacksByRun.values.expand((feedbacks) => feedbacks)) {
      if (feedback.dateTimeLocal.isAfter(latest)) latest = feedback.dateTimeLocal;
    }
    return latest;
  }
}

int compareTimelineEntries(TimelineEntry a, TimelineEntry b) {
  final byDate = a.dateUTC.compareTo(b.dateUTC);
  if (byDate != 0) return byDate;
  return _tieOrder(a) - _tieOrder(b);
}

int _tieOrder(TimelineEntry entry) => switch (entry) {
  StravaEntry() => 0,
  SetupEntry() || TaskTimeLineEntry() || InstallationEntry() || TestSessionTimelineEntry() => 1,
  FeedbackTimelineEntry() => 2,
};
