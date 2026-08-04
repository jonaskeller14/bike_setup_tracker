import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

/// Mirrors the transform in `ComponentActions._copyTaskRulesTo`.
TaskRule copyRuleTo(TaskRule rule, String componentId) =>
    rule.deepCopy().copyWith(componentId: componentId);

void main() {
  group("Copy task rules onto a duplicated/replacing component", () {
    late AppDatabase database;
    late AppRepository repository;
    late Bike bike;
    late Component source;
    late Component target;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);

      bike = Bike(name: "Enduro", person: null);
      await repository.addBike(bike);

      source = Component(
        name: "Fox 36",
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      target = Component(
        name: "Fox 36 (Copy)",
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponent(source);
      await repository.addComponent(target);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("copy is a new rule pointing at the target, with all settings preserved", () {
      final rule = TaskRule(
        name: "Lower leg service",
        notes: "50 h interval",
        priority: TaskPriority.high,
        tags: const {"suspension"},
        componentId: source.id,
        interval: const DistanceThreshold(500000),
        delay: const DistanceThreshold(100000),
        repeat: false,
      );

      final copy = copyRuleTo(rule, target.id);

      expect(copy.id, isNot(rule.id));
      expect(copy.componentId, target.id);
      expect(copy.bikeId, isNull);
      expect(copy.isDeleted, isFalse);
      expect(copy.name, rule.name);
      expect(copy.notes, rule.notes);
      expect(copy.priority, rule.priority);
      expect(copy.tags, rule.tags);
      expect(copy.interval, rule.interval);
      expect(copy.delay, rule.delay);
      expect(copy.repeat, rule.repeat);
    });

    test("deepCopy alone keeps the source componentId", () {
      // Guards the reason `copyWith(componentId: ...)` is required in the action.
      final rule = TaskRule(name: "Check torque", tags: const {}, componentId: source.id);
      expect(rule.deepCopy().componentId, source.id);
    });

    test("copied rules land on the target while the source keeps its own", () async {
      final rules = [
        TaskRule(name: "Lower leg service", tags: const {}, componentId: source.id, interval: const DistanceThreshold(500000)),
        TaskRule(name: "Air spring rebuild", tags: const {}, componentId: source.id),
      ];
      await repository.addTaskRules(rules);
      await pumpEventQueue();

      await repository.addTaskRules(rules.map((rule) => copyRuleTo(rule, target.id)).toList());
      await pumpEventQueue();

      expect(
        repository.openTaskRulesForComponent(target.id).map((t) => t.rule.name),
        unorderedEquals(["Lower leg service", "Air spring rebuild"]),
      );
      expect(
        repository.openTaskRulesForComponent(source.id).map((t) => t.rule.id),
        unorderedEquals(rules.map((r) => r.id)),
      );
      expect(repository.taskRules.length, 4);
    });

    test("addTaskRules emits the rule stream once, not once per rule", () async {
      var emissions = 0;
      final subscription = database.taskDao.watchAllRules().listen((_) => emissions++);
      await pumpEventQueue();
      emissions = 0; // ignore the initial emission

      await repository.addTaskRules([
        TaskRule(name: "A", tags: const {}, componentId: target.id),
        TaskRule(name: "B", tags: const {}, componentId: target.id),
        TaskRule(name: "C", tags: const {}, componentId: target.id),
      ]);
      await pumpEventQueue();

      expect(emissions, 1);
      await subscription.cancel();
    });

    test("the UNDO path removes and restores in one emission each", () async {
      final rules = [
        TaskRule(name: "A", tags: const {}, componentId: target.id),
        TaskRule(name: "B", tags: const {}, componentId: target.id),
        TaskRule(name: "C", tags: const {}, componentId: target.id),
      ];
      await repository.addTaskRules(rules);
      await pumpEventQueue();

      var emissions = 0;
      final subscription = database.taskDao.watchAllRules().listen((_) => emissions++);
      await pumpEventQueue();
      emissions = 0;

      await repository.removeTaskRules(rules);
      await pumpEventQueue();
      expect(emissions, 1);
      expect(repository.taskRules, isEmpty);

      emissions = 0;
      await repository.restoreTaskRules(rules);
      await pumpEventQueue();
      expect(emissions, 1);
      expect(repository.taskRules.length, 3);

      await subscription.cancel();
    });

    test("bike-linked rules are not picked up by the component filter", () async {
      await repository.addTaskRule(TaskRule(name: "Wash bike", tags: const {}, bikeId: bike.id));
      await repository.addTaskRule(TaskRule(name: "Check torque", tags: const {}, componentId: source.id));
      await pumpEventQueue();

      final offered = repository.taskRules.values.where((rule) => rule.componentId == source.id).toList();

      expect(offered.map((r) => r.name), ["Check torque"]);
    });
  });
}
