import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/activity_timeline.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 5, 10, 9);
  const elapsed = Duration(hours: 2);
  final activity = StravaActivity(
    id: 1,
    name: 'Ride',
    athlete: 1,
    sportType: SportType.Ride,
    startDate: start.toUtc(),
    startDateLocal: start,
    gearId: 'g',
    startLat: null,
    startLon: null,
    distance: null,
    totalElevationGain: null,
    movingTime: elapsed,
    elapsedTime: elapsed,
  );

  Setup setupAt(String id, Duration offset) {
    final local = start.add(offset);
    return Setup(
      id: id,
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: 'b',
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );
  }

  RideFeedback feedbackAt(String id, Duration offset) {
    final local = start.add(offset);
    return RideFeedback(id: id, bike: 'b', setupId: 's', dateTimeUTC: local.toUtc(), dateTimeLocal: local);
  }

  String describe(ActivityTimelineItem item) => switch (item) {
    ActivityMissingSetupItem() => 'missing',
    ActivitySetupItem(:final setup) => setup.id,
    ActivityFeedbackItem(:final feedback) => feedback.id,
    ActivityStartItem() => 'start',
    ActivityEndItem() => 'end',
  };

  group('ActivityTimeline.of', () {
    test('keeps the setup ridden on and the mid-ride changes, oldest first', () {
      final timeline = ActivityTimeline.of(
        activity,
        setups: [
          setupAt('older', const Duration(days: -3)),
          setupAt('mid', const Duration(minutes: 30)),
          setupAt('riddenOn', const Duration(days: -1)),
          setupAt('afterwards', const Duration(hours: 5)),
        ],
        feedbacks: [feedbackAt('later', const Duration(hours: 4)), feedbackAt('during', const Duration(hours: 1))],
      );

      expect(timeline.items.map(describe), ['riddenOn', 'start', 'mid', 'during', 'end', 'later']);
      expect(timeline.setupCount, 2);
    });

    test('a placeholder stands in when no setup precedes the ride', () {
      final timeline = ActivityTimeline.of(
        activity,
        setups: [setupAt('mid', const Duration(minutes: 30))],
        feedbacks: const [],
      );

      expect(timeline.items.map(describe), ['missing', 'start', 'mid', 'end']);
      expect(timeline.setupCount, 1);
    });

    test('ties: a setup at the start is ridden on, feedback at the end lies within the ride', () {
      final timeline = ActivityTimeline.of(
        activity,
        setups: [setupAt('atStart', Duration.zero), setupAt('atEnd', elapsed)],
        feedbacks: [feedbackAt('atEndFeedback', elapsed), feedbackAt('atStartFeedback', Duration.zero)],
      );

      expect(timeline.items.map(describe), ['atStart', 'start', 'atStartFeedback', 'atEndFeedback', 'end']);
    });

    test('a zero-length activity keeps its start before its end', () {
      final timeline = ActivityTimeline.of(
        StravaActivity(
          id: 2,
          name: 'Zero',
          athlete: 1,
          sportType: SportType.Ride,
          startDate: start.toUtc(),
          startDateLocal: start,
          gearId: 'g',
          startLat: null,
          startLon: null,
          distance: null,
          totalElevationGain: null,
          movingTime: Duration.zero,
          elapsedTime: Duration.zero,
        ),
        setups: const [],
        feedbacks: [feedbackAt('f', Duration.zero)],
      );

      expect(timeline.items.map(describe), ['missing', 'start', 'f', 'end']);
    });
  });

  test('only the lines from the start down to the end are the ride', () {
    final timeline = ActivityTimeline.of(
      activity,
      setups: [setupAt('before', const Duration(hours: -26)), setupAt('mid', const Duration(minutes: 73))],
      feedbacks: [feedbackAt('early', const Duration(hours: -1)), feedbackAt('after', const Duration(hours: 5))],
    );

    expect(timeline.items.map(describe), ['before', 'early', 'start', 'mid', 'end', 'after']);
    expect(
      [for (var i = 0; i < timeline.items.length; i++) timeline.isRideSegmentBelow(i)],
      [false, false, true, true, false, false],
    );
  });
}
