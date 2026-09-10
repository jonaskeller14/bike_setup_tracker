import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/task/task_progress_context.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baselineStats = ComponentStats(
    distance: 1000,
    elevationGain: 100,
    movingTime: Duration(hours: 1),
    elapsedTime: Duration(hours: 2),
    activityCount: 1,
  );

  TaskProgressContext contextWith(ComponentStats currentStats) => TaskProgressContext(
        currentStats: currentStats,
        baselineStats: baselineStats,
        now: DateTime(2023, 1, 10),
        baselineDate: DateTime(2023, 1, 1),
      );

  group('ElevationThreshold', () {
    final context = contextWith(const ComponentStats(
      distance: 5000,
      elevationGain: 350, // Diff: 250m
      movingTime: Duration(hours: 5),
      elapsedTime: Duration(hours: 6),
      activityCount: 5,
    ));

    test('isMet returns true when elevation gain exceeds threshold', () {
      const threshold = ElevationThreshold(200); // 200m
      expect(threshold.isMet(context), isTrue);
    });

    test('isMet returns false when elevation gain is below threshold', () {
      const threshold = ElevationThreshold(300); // 300m
      expect(threshold.isMet(context), isFalse);
    });

    test('progress returns correct ratio', () {
      const threshold = ElevationThreshold(500); // 500m
      // Diff is 250m. Ratio = 250 / 500 = 0.5
      expect(threshold.progress(context), 0.5);
    });

    test('toJson and fromJson work correctly', () {
      const threshold = ElevationThreshold(250);
      final json = threshold.toJson();
      expect(json['type'], 'elevation');
      expect(json['meters'], 250);

      final parsed = TaskThreshold.fromJson(json) as ElevationThreshold;
      expect(parsed.meters, 250);
      expect(parsed.iconData, Icons.terrain);
      expect(parsed.toDisplayValue(), '250 m');
      expect(parsed.isPositive, isTrue);
      expect(parsed, threshold);
    });

    test('isMet handles delay correctly', () {
      const threshold = ElevationThreshold(200);
      const delay = ElevationThreshold(100);
      // Total needed = 300m. Diff = 250m.
      expect(threshold.isMet(context, delay: delay), isFalse);
    });

    test('delay of another kind is ignored', () {
      const threshold = ElevationThreshold(200);
      // A distance delay says nothing about elevation, so the 250m still count.
      expect(threshold.isMet(context, delay: const DistanceThreshold(100000)), isTrue);
    });
  });

  group('KilojoulesThreshold', () {
    final context = contextWith(const ComponentStats(
      distance: 5000,
      elevationGain: 350,
      movingTime: Duration(hours: 5),
      elapsedTime: Duration(hours: 6),
      activityCount: 5,
      kilojoules: 350, // Diff: 350 kJ
    ));

    test('isMet returns true when kilojoules exceeds threshold', () {
      const threshold = KilojoulesThreshold(300);
      expect(threshold.isMet(context), isTrue);
    });

    test('isMet returns false when kilojoules is below threshold', () {
      const threshold = KilojoulesThreshold(400);
      expect(threshold.isMet(context), isFalse);
    });

    test('progress returns correct ratio', () {
      const threshold = KilojoulesThreshold(700);
      // Diff is 350 kJ. Ratio = 350 / 700 = 0.5
      expect(threshold.progress(context), 0.5);
    });

    test('toJson and fromJson work correctly', () {
      const threshold = KilojoulesThreshold(350);
      final json = threshold.toJson();
      expect(json['type'], 'kilojoules');
      expect(json['kilojoules'], 350);

      final parsed = TaskThreshold.fromJson(json) as KilojoulesThreshold;
      expect(parsed.kilojoules, 350);
      expect(parsed.iconData, Icons.bolt);
      expect(parsed.toDisplayValue(), '350 kJ');
      expect(parsed.isPositive, isTrue);
      expect(parsed, threshold);
    });

    test('isMet handles delay correctly', () {
      const threshold = KilojoulesThreshold(300);
      const delay = KilojoulesThreshold(100);
      // Total needed = 400 kJ. Diff = 350 kJ.
      expect(threshold.isMet(context, delay: delay), isFalse);
    });

    test('delay of another kind is ignored', () {
      const threshold = KilojoulesThreshold(300);
      // A distance delay says nothing about kilojoules, so the 350 kJ still count.
      expect(threshold.isMet(context, delay: const DistanceThreshold(100000)), isTrue);
    });
  });

  group('ElapsedTimeThreshold', () {
    final context = contextWith(const ComponentStats(
      distance: 5000,
      elevationGain: 350,
      movingTime: Duration(hours: 5),
      elapsedTime: Duration(hours: 12), // Diff: 10h
      activityCount: 5,
    ));

    test('isMet returns true when elapsed time exceeds threshold', () {
      const threshold = ElapsedTimeThreshold(Duration(hours: 8));
      expect(threshold.isMet(context), isTrue);
    });

    test('isMet returns false when elapsed time is below threshold', () {
      const threshold = ElapsedTimeThreshold(Duration(hours: 12));
      expect(threshold.isMet(context), isFalse);
    });

    test('progress returns correct ratio', () {
      const threshold = ElapsedTimeThreshold(Duration(hours: 20));
      // Diff is 10h. Ratio = 10 / 20 = 0.5
      expect(threshold.progress(context), 0.5);
    });

    test('toJson and fromJson work correctly', () {
      const threshold = ElapsedTimeThreshold(Duration(hours: 10));
      final json = threshold.toJson();
      expect(json['type'], 'elapsedTime');
      expect(json['microseconds'], const Duration(hours: 10).inMicroseconds);

      final parsed = TaskThreshold.fromJson(json) as ElapsedTimeThreshold;
      expect(parsed.hours, const Duration(hours: 10));
      expect(parsed.iconData, Icons.timelapse);
      expect(parsed.toDisplayValue(), '10 h');
      expect(parsed.isPositive, isTrue);
      expect(parsed, threshold);
    });

    test('isMet handles delay correctly', () {
      const threshold = ElapsedTimeThreshold(Duration(hours: 8));
      const delay = ElapsedTimeThreshold(Duration(hours: 4));
      // Total needed = 12h. Diff = 10h.
      expect(threshold.isMet(context, delay: delay), isFalse);
    });

    test('a moving time threshold of the same length is a different threshold', () {
      const elapsed = ElapsedTimeThreshold(Duration(hours: 8));
      const moving = MovingTimeThreshold(Duration(hours: 8));
      expect(elapsed, isNot(moving));
      // Diff is 4h moving vs. 10h elapsed, so only the elapsed one is met.
      expect(moving.isMet(context), isFalse);
      expect(elapsed.isMet(context), isTrue);
    });
  });

  group('requiresActivityData', () {
    test('is true for ride-measured thresholds', () {
      expect(const DistanceThreshold(1000).requiresActivityData, isTrue);
      expect(const ElevationThreshold(100).requiresActivityData, isTrue);
      expect(const MovingTimeThreshold(Duration(hours: 1)).requiresActivityData, isTrue);
      expect(const ElapsedTimeThreshold(Duration(hours: 1)).requiresActivityData, isTrue);
      expect(const ActivityCountThreshold(5).requiresActivityData, isTrue);
      expect(const KilojoulesThreshold(100).requiresActivityData, isTrue);
    });

    test('is false for calendar thresholds', () {
      expect(const DurationThreshold(Duration(days: 30)).requiresActivityData, isFalse);
      expect(DateTimeThreshold(DateTime(2023, 1, 1)).requiresActivityData, isFalse);
    });
  });
}
