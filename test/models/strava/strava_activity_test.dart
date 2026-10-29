import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feedbackTime', () {
    final start = DateTime(2026, 5, 3, 14);

    StravaActivity ride({Duration elapsed = const Duration(hours: 2)}) => StravaActivity(
      id: 1,
      name: 'Ride',
      athlete: 1,
      sportType: SportType.Ride,
      startDate: start.toUtc(),
      startDateLocal: start,
      gearId: 'gear_1',
      startLat: null,
      startLon: null,
      distance: null,
      totalElevationGain: null,
      movingTime: elapsed,
      elapsedTime: elapsed,
    );

    test('is now while the ride runs', () {
      final now = DateTime(2026, 5, 3, 15);

      final (utc, local) = ride().feedbackTime(now: now);

      expect(utc, now.toUtc());
      expect(local, now);
    });

    test('is a minute before the end once the ride is over', () {
      final (utc, local) = ride().feedbackTime(now: DateTime(2026, 6, 1));

      expect(utc, DateTime(2026, 5, 3, 15, 59).toUtc());
      expect(local, DateTime(2026, 5, 3, 15, 59));
    });

    test('is the start for a ride shorter than a minute, and before it began', () {
      final short = ride(elapsed: const Duration(seconds: 30));

      expect(short.feedbackTime(now: DateTime(2026, 6, 1)).$2, start);
      expect(ride().feedbackTime(now: DateTime(2026, 5, 1)).$2, start);
    });

    test('keeps the ride\'s local offset, not the device\'s', () {
      final away = StravaActivity(
        id: 2,
        name: 'Away',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2026, 5, 3, 12),
        startDateLocal: DateTime(2026, 5, 3, 21),
        gearId: null,
        startLat: null,
        startLon: null,
        distance: null,
        totalElevationGain: null,
        movingTime: const Duration(hours: 1),
        elapsedTime: const Duration(hours: 1),
      );

      final (utc, local) = away.feedbackTime(now: DateTime(2026, 6, 1));

      expect(utc, DateTime.utc(2026, 5, 3, 12, 59));
      expect(local, DateTime(2026, 5, 3, 21, 59));
    });
  });
}
