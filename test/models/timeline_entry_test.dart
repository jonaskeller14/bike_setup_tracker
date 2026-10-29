import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/timeline_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime(2026, 5, 1, 10);
  final setup = SetupEntry(
    Setup(
      datetime: at.toUtc(),
      datetimeLocal: at,
      tags: const {},
      bike: 'b1',
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    ),
  );
  FeedbackTimelineEntry feedbackAt(DateTime local) => FeedbackTimelineEntry(
    RideFeedback(bike: 'b1', setupId: 's1', dateTimeUTC: local.toUtc(), dateTimeLocal: local),
  );

  test('a feedback at the same instant as its setup comes after it', () {
    final feedback = feedbackAt(at);

    expect(([feedback, setup]..sort(compareTimelineEntries)), [setup, feedback]);
    expect(([setup, feedback]..sort((a, b) => compareTimelineEntries(b, a))), [feedback, setup]);
  });

  test('a Strava activity at the same instant comes before the setup and the feedback', () {
    final activity = StravaEntry(
      StravaActivity(
        id: 1,
        name: 'Ride',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: at.toUtc(),
        startDateLocal: at,
        gearId: null,
        startLat: null,
        startLon: null,
        distance: null,
        totalElevationGain: null,
        movingTime: Duration.zero,
        elapsedTime: Duration.zero,
      ),
    );
    final feedback = feedbackAt(at);

    expect(([feedback, setup, activity]..sort(compareTimelineEntries)), [activity, setup, feedback]);
  });

  test('the date decides before the kind', () {
    final earlier = feedbackAt(at.subtract(const Duration(minutes: 1)));

    expect(([setup, earlier]..sort(compareTimelineEntries)), [earlier, setup]);
  });
}
