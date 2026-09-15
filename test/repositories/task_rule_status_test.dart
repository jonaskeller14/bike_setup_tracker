import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("AppRepository - task rule status baseline", () {
    late AppDatabase database;
    late AppRepository repository;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    TaskEntry entryAgo({required TaskRule rule, required int days}) {
      final when = DateTime.now().toUtc().subtract(Duration(days: days));
      return TaskEntry(
        name: "Done ${days}d ago",
        taskRule: rule.id,
        dateTimeUTC: when,
        dateTimeLocal: when.toLocal(),
      );
    }

    /// A time-based rule measures from its newest entry, so the chosen baseline
    /// is visible in the progress: newest (1 day into a 10 day interval) is
    /// upcoming, while any older entry would already read as overdue.
    Future<void> expectNewestEntryWins(List<int> insertionOrderInDays) async {
      final rule = TaskRule(
        name: "Wash",
        tags: const {},
        interval: const DurationThreshold(Duration(days: 10)),
      );
      await repository.addTaskRules([rule]);
      await pumpEventQueue();

      await repository.addTaskEntries([
        for (final days in insertionOrderInDays) entryAgo(rule: rule, days: days),
      ]);
      await pumpEventQueue();

      final status = repository.getTaskRuleStatus(rule);
      expect(status.type, TaskStatusType.upcoming);
      expect(status.progress, closeTo(0.1, 0.01));
    }

    test("uses the newest entry when older ones were inserted first", () async {
      await expectNewestEntryWins([100, 40, 1]);
    });

    test("uses the newest entry when it was inserted first", () async {
      await expectNewestEntryWins([1, 40, 100]);
    });

    test("falls back to no baseline when the rule has no entries", () async {
      final rule = TaskRule(
        name: "Wash",
        tags: const {},
        interval: const DurationThreshold(Duration(days: 10)),
      );
      await repository.addTaskRules([rule]);
      await pumpEventQueue();

      expect(repository.getTaskRuleStatus(rule).type, TaskStatusType.overdue);
    });

    test("a new entry re-baselines the status of an already overdue rule", () async {
      final rule = TaskRule(
        name: "Wash",
        tags: const {},
        interval: const DurationThreshold(Duration(days: 10)),
      );
      await repository.addTaskRules([rule]);
      await repository.addTaskEntries([entryAgo(rule: rule, days: 100)]);
      await pumpEventQueue();
      expect(repository.getTaskRuleStatus(rule).type, TaskStatusType.overdue);

      // The cached newest-entry index must be dropped when entries change.
      await repository.addTaskEntries([entryAgo(rule: rule, days: 1)]);
      await pumpEventQueue();
      expect(repository.getTaskRuleStatus(rule).type, TaskStatusType.upcoming);
    });
  });
}
