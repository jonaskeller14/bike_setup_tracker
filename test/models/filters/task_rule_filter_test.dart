import 'package:bike_setup_tracker/models/filters/task_rule_filter.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:flutter_test/flutter_test.dart';

TaskRule rule({TaskPriority priority = TaskPriority.medium, Set<String> tags = const {}}) =>
    TaskRule(name: "Rule", priority: priority, tags: tags);

void main() {
  group("TaskRuleFilter.matches", () {
    test("the default filter accepts every priority and tag", () {
      final filter = TaskRuleFilter();
      for (final priority in TaskPriority.values) {
        expect(filter.matches(rule(priority: priority, tags: {"service"})), true);
      }
    });

    test("priorities accept only the selected ones", () {
      final filter = TaskRuleFilter(priorities: const {TaskPriority.high, TaskPriority.critical});
      expect(filter.matches(rule(priority: TaskPriority.high)), true);
      expect(filter.matches(rule(priority: TaskPriority.critical)), true);
      expect(filter.matches(rule(priority: TaskPriority.low)), false);
    });

    test("no selected priority rejects everything", () {
      final filter = TaskRuleFilter(priorities: const {});
      expect(filter.matches(rule()), false);
    });

    test("tags require every selected tag", () {
      final filter = TaskRuleFilter(tags: const {"service", "fork"});
      expect(filter.matches(rule(tags: {"service", "fork", "yearly"})), true);
      expect(filter.matches(rule(tags: {"service"})), false);
      expect(filter.matches(rule()), false);
    });

    test("priority and tags must both hold", () {
      final filter = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {"service"});
      expect(filter.matches(rule(priority: TaskPriority.high, tags: {"service"})), true);
      expect(filter.matches(rule(priority: TaskPriority.low, tags: {"service"})), false);
      expect(filter.matches(rule(priority: TaskPriority.high)), false);
    });

    test("ignores the bike scope", () {
      final filter = TaskRuleFilter();
      expect(
        filter.matches(TaskRule(name: "Rule", tags: const {}, association: const BikeTaskAssociation("bike"))),
        true,
      );
    });
  });

  group("TaskRuleFilter activity", () {
    test("the default filter is inactive", () {
      final filter = TaskRuleFilter();
      expect(filter.hasActivePriorities, false);
      expect(filter.isActive, false);
    });

    test("a deselected priority is an active priority filter", () {
      final filter = TaskRuleFilter(priorities: const {TaskPriority.high});
      expect(filter.hasActivePriorities, true);
      expect(filter.isActive, true);
    });

    test("tags alone make the filter active without a priority filter", () {
      final filter = TaskRuleFilter(tags: const {"service"});
      expect(filter.hasActivePriorities, false);
      expect(filter.isActive, true);
    });
  });

  group("TaskRuleFilter value semantics", () {
    test("copyWith replaces only the given fields", () {
      final filter = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {"service"});
      expect(filter.copyWith(tags: const {}), TaskRuleFilter(priorities: const {TaskPriority.high}));
      expect(filter.copyWith(priorities: TaskPriority.values.toSet()), TaskRuleFilter(tags: const {"service"}));
      expect(filter.copyWith(), filter);
    });

    test("equality compares priorities and tags by content", () {
      final a = TaskRuleFilter(priorities: const {TaskPriority.low, TaskPriority.high}, tags: const {"a", "b"});
      final b = TaskRuleFilter(priorities: const {TaskPriority.high, TaskPriority.low}, tags: const {"b", "a"});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(TaskRuleFilter(tags: const {"a", "b"})));
      expect(a, isNot(a.copyWith(tags: const {"a"})));
      expect(TaskRuleFilter(), TaskRuleFilter(priorities: TaskPriority.values.toSet()));
    });
  });
}
