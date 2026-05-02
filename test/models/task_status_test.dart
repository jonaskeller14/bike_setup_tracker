import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/task_entry.dart';
import 'package:bike_setup_tracker/models/task_rule.dart';
import 'package:bike_setup_tracker/models/task_threshold.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskRule.calculateStatus', () {
    final now = DateTime.utc(2024, 1, 1);
    final componentId = 'comp-1';

    test('Recurring distance task', () {
      final rule = TaskRule(
        name: 'Chain Wax',
        componentId: componentId,
        interval: const DistanceThreshold(300000), // 300km
        repeat: true,
      );

      // No entries, 0m -> upcoming (0%)
      var status = rule.calculateStatus(
        currentStats: ComponentStats.zero(),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, 0.0);

      // 150km -> upcoming (50%)
      status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 150000),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, 0.5);

      // 300km -> due (100%)
      status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 300000),
        now: now,
      );
      expect(status.type, TaskStatusType.due);
      expect(status.progress, 1.0);

      // 350km -> overdue (>110%)
      status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 350000),
        now: now,
      );
      expect(status.type, TaskStatusType.overdue);
      expect(status.progress, closeTo(1.16, 0.01));
    });

    test('Distance task with delay', () {
      final rule = TaskRule(
        name: 'Late Chain Wax',
        componentId: componentId,
        interval: const DistanceThreshold(300000),
        delay: const DistanceThreshold(50000),
        repeat: true,
      );

      // 300km -> upcoming (because of 50km delay, total is 350km)
      var status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 300000),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, closeTo(300 / 350, 0.01));

      // 350km -> due
      status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 350000),
        now: now,
      );
      expect(status.type, TaskStatusType.due);
      expect(status.progress, 1.0);
    });

    test('One-time task completion', () {
      final rule = TaskRule(
        name: 'Break-in service',
        componentId: componentId,
        interval: const DistanceThreshold(100000),
        repeat: false,
      );

      // No entries, 50km -> upcoming
      var status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 50000),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);

      // Entry exists -> completed
      final entry = TaskEntry(
        name: 'Service Done',
        taskRule: rule.id,
        componentId: componentId,
        dateTimeUTC: now,
        dateTimeLocal: now,
        snapshot: ComponentStats.zero().copyWith(distance: 100000),
      );

      status = rule.calculateStatus(
        currentStats: ComponentStats.zero().copyWith(distance: 150000),
        now: now.add(const Duration(days: 1)),
        lastEntry: entry,
      );
      expect(status.type, TaskStatusType.completed);
    });

    test('Time-based recurring task', () {
      final rule = TaskRule(
        name: 'Monthly Check',
        componentId: componentId,
        interval: const DurationThreshold(Duration(days: 30)),
        repeat: true,
      );

      final installationDate = now.subtract(const Duration(days: 45));

      // No entry, 45 days since installation -> overdue (1.5x)
      var status = rule.calculateStatus(
        currentStats: ComponentStats.zero(),
        now: now,
        componentInstallationDate: installationDate,
      );
      expect(status.type, TaskStatusType.overdue);
      expect(status.progress, 1.5);

      // Entry 15 days ago -> upcoming (0.5x)
      final entry = TaskEntry(
        name: 'Last Check',
        taskRule: rule.id,
        componentId: componentId,
        dateTimeUTC: now.subtract(const Duration(days: 15)),
        dateTimeLocal: now.subtract(const Duration(days: 15)),
        snapshot: ComponentStats.zero(),
      );

      status = rule.calculateStatus(
        currentStats: ComponentStats.zero(),
        now: now,
        lastEntry: entry,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, 0.5);
    });

    test('Component unrelated task (bike task)', () {
      final rule = TaskRule(
        name: 'Wash Bike A',
        bikeId: 'bike-1',
        interval: const DurationThreshold(Duration(days: 7)),
        repeat: true,
      );

      // 8 days passed -> overdue
      final status = rule.calculateStatus(
        currentStats: ComponentStats.zero(),
        now: now,
        componentInstallationDate: now.subtract(const Duration(days: 8)),
      );
      expect(status.type, TaskStatusType.overdue);
      expect(status.progress, closeTo(8 / 7, 0.01));
    });

    group('Distance mismatch check', () {
      test('Distance threshold without component or bike should throw assertion error', () {
        expect(() => TaskRule(
          name: 'Invalid Task',
          interval: const DistanceThreshold(100),
        ), throwsA(isA<AssertionError>()));
      });

      test('Bike Distance threshold with bikeId is valid', () {
        final rule = TaskRule(
          name: 'Bike Distance Task',
          bikeId: 'bike-1',
          interval: const DistanceThreshold(100),
        );
        expect(rule.bikeId, 'bike-1');
      });
    });

    test('Manual task without interval', () {
      final rule = TaskRule(
        name: 'Manual task',
        repeat: true, // This is the bug: it defaults to true
      );

      // No entry -> due
      var status = rule.calculateStatus(
        currentStats: ComponentStats.zero(),
        now: now,
      );
      expect(status.type, TaskStatusType.due);

      // Entry exists -> should be completed
      final entry = TaskEntry(
        name: 'Completed',
        taskRule: rule.id,
        dateTimeUTC: now,
        dateTimeLocal: now,
        snapshot: ComponentStats.zero(),
      );

      status = rule.calculateStatus(
        currentStats: ComponentStats.zero(),
        now: now.add(const Duration(hours: 1)),
        lastEntry: entry,
      );
      expect(status.type, TaskStatusType.completed);
    });
  });
}

extension on ComponentStats {
  ComponentStats copyWith({
    double? distance,
    double? elevationGain,
    Duration? movingTime,
    Duration? elapsedTime,
    int? activityCount,
  }) {
    return ComponentStats(
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      movingTime: movingTime ?? this.movingTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      activityCount: activityCount ?? this.activityCount,
    );
  }
}
