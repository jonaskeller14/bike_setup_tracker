import '../feedback/ride_feedback.dart';
import '../setup.dart';
import 'strava_activity.dart';

sealed class ActivityTimelineItem {
  DateTime get dateUTC;

  /// On equal times: the setup ridden on comes before the start, and the end
  /// comes after everything recorded during the ride.
  int get _tieOrder;
}

/// Stands in for the setup ridden on when none was recorded before the ride.
class ActivityMissingSetupItem extends ActivityTimelineItem {
  @override
  final DateTime dateUTC;
  ActivityMissingSetupItem(this.dateUTC);
  @override
  int get _tieOrder => 0;
}

class ActivitySetupItem extends ActivityTimelineItem {
  final Setup setup;
  ActivitySetupItem(this.setup);
  @override
  DateTime get dateUTC => setup.datetime;
  @override
  int get _tieOrder => 1;
}

class ActivityStartItem extends ActivityTimelineItem {
  @override
  final DateTime dateUTC;
  ActivityStartItem(this.dateUTC);
  @override
  int get _tieOrder => 2;
}

class ActivityFeedbackItem extends ActivityTimelineItem {
  final RideFeedback feedback;
  ActivityFeedbackItem(this.feedback);
  @override
  DateTime get dateUTC => feedback.dateTimeUTC;
  @override
  int get _tieOrder => 3;
}

class ActivityEndItem extends ActivityTimelineItem {
  @override
  final DateTime dateUTC;
  ActivityEndItem(this.dateUTC);
  @override
  int get _tieOrder => 4;
}

/// A ride's setups and feedbacks around its start and end, oldest first.
class ActivityTimeline {
  final StravaActivity activity;
  final List<ActivityTimelineItem> items;
  final int startIndex;
  final int endIndex;

  ActivityTimeline._(this.activity, this.items)
    : startIndex = items.indexWhere((i) => i is ActivityStartItem),
      endIndex = items.indexWhere((i) => i is ActivityEndItem);

  /// Keeps from [setups] the one ridden on (the latest at or before the start)
  /// and those recorded during the ride; older ones were replaced before it.
  factory ActivityTimeline.of(
    StravaActivity activity, {
    required Iterable<Setup> setups,
    required Iterable<RideFeedback> feedbacks,
  }) {
    final start = activity.startDate;
    final end = activity.endDate;
    Setup? riddenOn;
    final changedDuringRide = <Setup>[];
    for (final setup in setups) {
      if (!setup.datetime.isAfter(start)) {
        if (riddenOn == null || setup.datetime.isAfter(riddenOn.datetime)) riddenOn = setup;
      } else if (setup.datetime.isBefore(end)) {
        changedDuringRide.add(setup);
      }
    }
    final items =
        <ActivityTimelineItem>[
          if (riddenOn == null) ActivityMissingSetupItem(start) else ActivitySetupItem(riddenOn),
          ActivityStartItem(start),
          ...changedDuringRide.map(ActivitySetupItem.new),
          ...feedbacks.map(ActivityFeedbackItem.new),
          ActivityEndItem(end),
        ]..sort((a, b) {
          final byDate = a.dateUTC.compareTo(b.dateUTC);
          if (byDate != 0) return byDate;
          return a._tieOrder - b._tieOrder;
        });
    return ActivityTimeline._(activity, items);
  }

  int get setupCount => items.whereType<ActivitySetupItem>().length;

  /// Whether the line below [index] runs through the ride.
  bool isRideSegmentBelow(int index) => index >= startIndex && index < endIndex;
}
