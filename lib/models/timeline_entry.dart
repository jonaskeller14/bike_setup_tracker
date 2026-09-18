import 'component_installation.dart';
import 'rating_entry.dart';
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
  final ResolvedComponentInstallation componentInstallation;
  InstallationEntry(this.componentInstallation);
  @override
  String get id => 'inst:${componentInstallation.installation.id}';
  @override
  DateTime get dateUTC => componentInstallation.installation.dateTimeUTC;
  @override
  DateTime get dateLocal => componentInstallation.installation.dateTimeLocal;
}

class RatingEntryTimelineEntry extends TimelineEntry {
  final RatingEntry ratingEntry;
  RatingEntryTimelineEntry(this.ratingEntry);
  @override
  String get id => 'rating:${ratingEntry.id}';
  @override
  DateTime get dateUTC => ratingEntry.dateTimeUTC;
  @override
  DateTime get dateLocal => ratingEntry.dateTimeLocal;
}
