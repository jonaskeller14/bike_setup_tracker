import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/task/task_threshold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ElevationThreshold', () {
    final baselineDate = DateTime(2023, 1, 1);
    final currentDate = DateTime(2023, 1, 10);
    
    final baselineStats = const ComponentStats(
      distance: 1000,
      elevationGain: 100,
      movingTime: Duration(hours: 1),
      elapsedTime: Duration(hours: 2),
      activityCount: 1,
    );

    final currentStats = const ComponentStats(
      distance: 5000,
      elevationGain: 350, // Diff: 250m
      movingTime: Duration(hours: 5),
      elapsedTime: Duration(hours: 6),
      activityCount: 5,
    );

    test('isMet returns true when elevation gain exceeds threshold', () {
      const threshold = ElevationThreshold(200); // 200m
      expect(threshold.isMet(currentStats, baselineStats, currentDate, baselineDate), isTrue);
    });

    test('isMet returns false when elevation gain is below threshold', () {
      const threshold = ElevationThreshold(300); // 300m
      expect(threshold.isMet(currentStats, baselineStats, currentDate, baselineDate), isFalse);
    });

    test('getProgress returns correct ratio', () {
      const threshold = ElevationThreshold(500); // 500m
      // Diff is 250m. Ratio = 250 / 500 = 0.5
      expect(threshold.getProgress(currentStats, baselineStats, currentDate, baselineDate), 0.5);
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
    });
    
    test('isMet handles delay correctly', () {
      const threshold = ElevationThreshold(200);
      const delay = ElevationThreshold(100);
      // Total needed = 300m. Diff = 250m.
      expect(threshold.isMet(currentStats, baselineStats, currentDate, baselineDate, delay: delay), isFalse);
    });
  });
}
