import 'component_installation.dart';
import 'rating_entry.dart';
import 'setup.dart';
import 'strava/strava_activity.dart';
import 'task/task_entry.dart';

sealed class TimelineEntry {
  DateTime get date;
}

class SetupEntry extends TimelineEntry {
  final Setup setup;
  SetupEntry(this.setup);
  @override
  DateTime get date => setup.datetime;
}

class StravaEntry extends TimelineEntry {
  final StravaActivity activity;
  StravaEntry(this.activity);
  @override
  DateTime get date => activity.startDate;
}

class TaskTimeLineEntry extends TimelineEntry {
  final TaskEntry taskEntry;
  TaskTimeLineEntry(this.taskEntry);
  @override
  DateTime get date => taskEntry.dateTimeUTC;
}

class InstallationEntry extends TimelineEntry {
  final ComponentInstallation componentInstallation;
  InstallationEntry(this.componentInstallation);
  @override
  DateTime get date => componentInstallation.installation.dateTimeUTC;
}

class RatingEntryTimelineEntry extends TimelineEntry {
  final RatingEntry ratingEntry;
  RatingEntryTimelineEntry(this.ratingEntry);
  @override
  DateTime get date => ratingEntry.dateTimeUTC;
}
