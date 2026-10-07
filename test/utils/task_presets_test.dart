import 'package:bike_setup_tracker/models/task/task_template.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/utils/task_presets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('taskPresets', () {
    final templatesByKey = <String, List<TaskTemplate>>{};
    for (final templates in taskPresets.values) {
      for (final template in templates) {
        templatesByKey.putIfAbsent(template.key, () => []).add(template);
      }
    }
    final templates = [for (final list in templatesByKey.values) list.first];

    test('keys are unique within each component type', () {
      for (final MapEntry(key: type, value: list) in taskPresets.entries) {
        final keys = list.map((template) => template.key).toList();
        expect(keys.toSet().length, keys.length, reason: '$type');
      }
    });

    test('a key shared by several types always refers to the same template', () {
      for (final MapEntry(:key, value: list) in templatesByKey.entries) {
        expect(list.every((template) => identical(template, list.first)), isTrue, reason: key);
      }
    });

    test('keys follow <type>:<snake_case>', () {
      final format = RegExp(r'^[a-z][a-z_]*:[a-z][a-z0-9]*(_[a-z0-9]+)*$');
      for (final key in templatesByKey.keys) {
        expect(format.hasMatch(key), isTrue, reason: key);
      }
    });

    test('every interval is positive', () {
      for (final template in templates) {
        expect(template.interval.isPositive, isTrue, reason: template.key);
        expect(template.fallbackInterval?.isPositive ?? true, isTrue, reason: template.key);
      }
    });

    test('templates are never pinned to a fixed date', () {
      for (final template in templates) {
        expect(template.interval, isNot(isA<DateTimeThreshold>()), reason: template.key);
        expect(template.fallbackInterval, isNot(isA<DateTimeThreshold>()), reason: template.key);
      }
    });

    test('every fallback works without Strava', () {
      for (final template in templates) {
        final fallback = template.fallbackInterval;
        if (fallback == null) continue;
        expect(fallback, isA<DurationThreshold>(), reason: template.key);
        expect(fallback.requiresActivityData, isFalse, reason: template.key);
      }
    });

    test('a time-based template has no fallback', () {
      for (final template in templates.where((template) => !template.interval.requiresActivityData)) {
        expect(template.fallbackInterval, isNull, reason: template.key);
      }
    });

    test('names are not empty', () {
      for (final template in templates) {
        expect(template.name.trim(), isNotEmpty, reason: template.key);
      }
    });
  });

  group('taskIntervalLabel', () {
    test('uses the largest whole duration unit', () {
      expect(taskIntervalLabel(const DurationThreshold(Duration(days: 30))), 'every month');
      expect(taskIntervalLabel(const DurationThreshold(Duration(days: 180))), 'every 6 months');
      expect(taskIntervalLabel(const DurationThreshold(Duration(days: 365))), 'every year');
      expect(taskIntervalLabel(const DurationThreshold(Duration(days: 14))), 'every 2 weeks');
      expect(taskIntervalLabel(const DurationThreshold(Duration(days: 1))), 'every day');
    });

    test('ride-based thresholds use their display value in the given unit', () {
      expect(taskIntervalLabel(const DistanceThreshold(2000000)), 'every 2,000 km');
      expect(taskIntervalLabel(const DistanceThreshold(1609344), distanceUnit: 'mi'), 'every 1,000 mi');
      expect(taskIntervalLabel(const MovingTimeThreshold(Duration(hours: 125))), 'every 125 h');
      expect(taskIntervalLabel(const ActivityCountThreshold(5)), 'every 5 rides');
    });
  });
}
