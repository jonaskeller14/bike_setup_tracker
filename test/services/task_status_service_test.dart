import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/services/task_status_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskStatusService.calculate', () {
    final now = DateTime.utc(2024, 1, 1);
    final componentId = 'comp-1';

    test('Recurring distance task', () {
      final rule = TaskRule(
        name: 'Chain Wax',
        association: ComponentTaskAssociation(componentId),
        interval: const DistanceThreshold(300000), // 300km
        repeat: true,
        tags: const {},
      );

      // No entries, 0m -> upcoming (0%)
      var status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero,
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, 0.0);

      // 150km -> upcoming (50%)
      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 150000),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, 0.5);

      // 300km -> due (100%)
      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 300000),
        now: now,
      );
      expect(status.type, TaskStatusType.due);
      expect(status.progress, 1.0);

      // 350km -> overdue (>110%)
      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 350000),
        now: now,
      );
      expect(status.type, TaskStatusType.overdue);
      expect(status.progress, closeTo(1.16, 0.01));
    });

    test('Distance task with delay', () {
      final rule = TaskRule(
        name: 'Late Chain Wax',
        association: ComponentTaskAssociation(componentId),
        interval: const DistanceThreshold(300000),
        delay: const DistanceThreshold(50000),
        repeat: true,
        tags: const {},
      );

      // 300km -> upcoming (because of 50km delay, total is 350km)
      var status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 300000),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, closeTo(300 / 350, 0.01));

      // 350km -> due
      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 350000),
        now: now,
      );
      expect(status.type, TaskStatusType.due);
      expect(status.progress, 1.0);
    });

    test('One-time task completion', () {
      final rule = TaskRule(
        name: 'Break-in service',
        association: ComponentTaskAssociation(componentId),
        interval: const DistanceThreshold(100000),
        repeat: false,
        tags: const {},
      );

      // No entries, 50km -> upcoming
      var status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 50000),
        now: now,
      );
      expect(status.type, TaskStatusType.upcoming);

      // Entry exists -> completed
      final entry = TaskEntry(
        name: 'Service Done',
        taskRule: rule.id,
        association: ComponentTaskAssociation(componentId),
        dateTimeUTC: now,
        dateTimeLocal: now,
        snapshot: ComponentStats.zero.copyWith(distance: 100000),
      );

      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 150000),
        now: now.add(const Duration(days: 1)),
        lastEntry: entry,
      );
      expect(status.type, TaskStatusType.completed);
    });

    test('Time-based recurring task', () {
      final rule = TaskRule(
        name: 'Monthly Check',
        association: ComponentTaskAssociation(componentId),
        interval: const DurationThreshold(Duration(days: 30)),
        repeat: true,
        tags: const {},
      );

      final installationDate = now.subtract(const Duration(days: 45));

      // No entry, 45 days since installation -> overdue (1.5x)
      var status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero,
        now: now,
        componentInstallationDate: installationDate,
      );
      expect(status.type, TaskStatusType.overdue);
      expect(status.progress, 1.5);

      // Entry 15 days ago -> upcoming (0.5x)
      final entry = TaskEntry(
        name: 'Last Check',
        taskRule: rule.id,
        association: ComponentTaskAssociation(componentId),
        dateTimeUTC: now.subtract(const Duration(days: 15)),
        dateTimeLocal: now.subtract(const Duration(days: 15)),
        snapshot: ComponentStats.zero,
      );

      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero,
        now: now,
        lastEntry: entry,
      );
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, 0.5);
    });

    test('Component unrelated task (bike task)', () {
      final rule = TaskRule(
        name: 'Wash Bike A',
        association: const BikeTaskAssociation('bike-1'),
        interval: const DurationThreshold(Duration(days: 7)),
        repeat: true,
        tags: const {},
      );

      // 8 days passed -> overdue
      final status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero,
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
          tags: const {},
        ), throwsA(isA<AssertionError>()));
      });

      test('Bike Distance threshold with bikeId is valid', () {
        final rule = TaskRule(
          name: 'Bike Distance Task',
          association: const BikeTaskAssociation('bike-1'),
          interval: const DistanceThreshold(100),
          tags: const {},
        );
        expect(rule.association.bikeId, 'bike-1');
      });
    });

    test('Manual task without interval', () {
      final rule = TaskRule(
        name: 'Manual task',
        repeat: true, // This is the bug: it defaults to true
        tags: const {},
      );

      // No entry -> due
      var status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero,
        now: now,
      );
      expect(status.type, TaskStatusType.due);

      // Entry exists -> should be completed
      final entry = TaskEntry(
        name: 'Completed',
        taskRule: rule.id,
        dateTimeUTC: now,
        dateTimeLocal: now,
        snapshot: ComponentStats.zero,
      );

      status = TaskStatusService.calculate(
        rule: rule,
        currentStats: ComponentStats.zero,
        now: now.add(const Duration(hours: 1)),
        lastEntry: entry,
      );
      expect(status.type, TaskStatusType.completed);
    });
  });

  group('TaskStatusService.dueNowDelay', () {
    final now = DateTime.utc(2024, 1, 1);
    final componentId = 'comp-1';

    TaskRule ruleWith(TaskThreshold interval, {TaskThreshold? delay}) => TaskRule(
          name: 'Chain Wax',
          association: ComponentTaskAssociation(componentId),
          interval: interval,
          delay: delay,
          tags: const {},
        );

    TaskStatus statusWithDueNowDelay(
      TaskRule rule, {
      required ComponentStats stats,
      DateTime? at,
      TaskEntry? lastEntry,
      DateTime? installedAt,
    }) {
      final delay = TaskStatusService.dueNowDelay(
        rule: rule,
        currentStats: stats,
        now: now,
        lastEntry: lastEntry,
        componentInstallationDate: installedAt,
      );
      return TaskStatusService.calculate(
        rule: rule.copyWith(delay: delay),
        currentStats: stats,
        now: at ?? now,
        lastEntry: lastEntry,
        componentInstallationDate: installedAt,
      );
    }

    test('pulls a distance target in to what was ridden, despite float rounding', () {
      final rule = ruleWith(const DistanceThreshold(300000));
      final stats = ComponentStats.zero.copyWith(distance: 123456.789);

      final delay = TaskStatusService.dueNowDelay(rule: rule, currentStats: stats, now: now);
      expect(delay, isA<DistanceThreshold>());
      expect((delay as DistanceThreshold).isPullForward, isTrue);

      final status = statusWithDueNowDelay(rule, stats: stats);
      expect(status.type, TaskStatusType.due);
      expect(status.progress, closeTo(1.0, 1e-9));
    });

    test('turns overdue once riding continues past the pulled-in target', () {
      final rule = ruleWith(const DistanceThreshold(300000));
      final delay = TaskStatusService.dueNowDelay(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 100000),
        now: now,
      );

      final status = TaskStatusService.calculate(
        rule: rule.copyWith(delay: delay),
        currentStats: ComponentStats.zero.copyWith(distance: 120000),
        now: now,
      );
      expect(status.type, TaskStatusType.overdue);
    });

    test('is due right away when nothing was gathered yet', () {
      final rule = ruleWith(const ActivityCountThreshold(10));

      final status = statusWithDueNowDelay(rule, stats: ComponentStats.zero);
      expect(status.type, TaskStatusType.due);
    });

    test('measures a duration from the last entry', () {
      final rule = ruleWith(const DurationThreshold(Duration(days: 30)));
      final entry = TaskEntry(
        name: 'Chain Wax',
        taskRule: rule.id,
        association: ComponentTaskAssociation(componentId),
        dateTimeUTC: now.subtract(const Duration(days: 12)),
        dateTimeLocal: now.subtract(const Duration(days: 12)),
        snapshot: ComponentStats.zero,
      );

      final delay = TaskStatusService.dueNowDelay(
        rule: rule,
        currentStats: ComponentStats.zero,
        now: now,
        lastEntry: entry,
      );
      expect((delay as DurationThreshold).days, const Duration(days: -18));

      final status = statusWithDueNowDelay(
        rule,
        stats: ComponentStats.zero,
        lastEntry: entry,
        at: now.add(const Duration(hours: 1)),
      );
      expect(status.type, TaskStatusType.due);
    });

    test('replaces a delay that postponed the task', () {
      final rule = ruleWith(const DistanceThreshold(300000), delay: const DistanceThreshold(50000));

      final status = statusWithDueNowDelay(rule, stats: ComponentStats.zero.copyWith(distance: 100000));
      expect(status.type, TaskStatusType.due);
    });

    test('needs no delay when the interval alone is already met', () {
      final rule = ruleWith(const DistanceThreshold(300000), delay: const DistanceThreshold(50000));

      final delay = TaskStatusService.dueNowDelay(
        rule: rule,
        currentStats: ComponentStats.zero.copyWith(distance: 320000),
        now: now,
      );
      expect(delay, isNull);
    });

    test('has nothing to pull in for a deadline', () {
      final rule = TaskRule(
        name: 'Inspection',
        interval: DateTimeThreshold(now.add(const Duration(days: 30))),
        tags: const {},
      );

      final delay = TaskStatusService.dueNowDelay(rule: rule, currentStats: ComponentStats.zero, now: now);
      expect(delay, isNull);
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
