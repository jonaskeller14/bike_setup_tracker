import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/attachment_storage_service.dart';
import 'package:bike_setup_tracker/utils/component_actions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

Future<TaskRule> copyRuleTo(TaskRule rule, String componentId) async =>
    (await ComponentActions.taskRuleCopies([rule], componentId: componentId)).single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Copy task rules onto a duplicated/replacing component", () {
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    late AppDatabase database;
    late AppRepository repository;
    late Directory documentsDirectory;
    late Bike bike;
    late Component source;
    late Component target;

    setUp(() async {
      documentsDirectory = await Directory.systemTemp.createTemp('task_rule_copy_docs_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => call.method == 'getApplicationDocumentsDirectory' ? documentsDirectory.path : null,
      );
      database = AppDatabase.memory();
      repository = AppRepository(database);

      bike = Bike(name: "Enduro", person: null);
      await repository.addBikes([bike]);

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
      await repository.addComponents([source, target]);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        null,
      );
      await documentsDirectory.delete(recursive: true);
    });

    test("copy is a new rule pointing at the target, with all settings preserved", () async {
      final rule = TaskRule(
        name: "Lower leg service",
        notes: "50 h interval",
        priority: TaskPriority.high,
        tags: const {"suspension"},
        association: ComponentTaskAssociation(source.id),
        interval: const DistanceThreshold(500000),
        delay: const DistanceThreshold(100000),
        repeat: false,
        presetKey: "fork:lower_leg_service",
      );

      final copy = await copyRuleTo(rule, target.id);

      expect(copy.id, isNot(rule.id));
      expect(copy.association.componentId, target.id);
      expect(copy.association.bikeId, isNull);
      expect(copy.isDeleted, isFalse);
      expect(copy.name, rule.name);
      expect(copy.notes, rule.notes);
      expect(copy.priority, rule.priority);
      expect(copy.tags, rule.tags);
      expect(copy.interval, rule.interval);
      expect(copy.delay, rule.delay);
      expect(copy.repeat, rule.repeat);
      expect(copy.presetKey, "fork:lower_leg_service");
      expect(copy.attachments, isEmpty);
    });

    test("copied rules have their own attachment files with the same names", () async {
      final service = AttachmentStorageService();
      final manual = Attachment(extension: '.pdf', name: 'Fox 36 Service Manual');
      final chart = Attachment(extension: '.jpg', name: 'Torque chart.jpg');
      await service.ensureDir();
      await (await service.resolve(manual.filename)).writeAsBytes([1, 2, 3]);
      await (await service.resolve(chart.filename)).writeAsBytes([4, 5]);
      final rule = TaskRule(
        name: "Lower leg service",
        tags: const {},
        association: ComponentTaskAssociation(source.id),
        attachments: [manual, chart],
      );

      final copy = await copyRuleTo(rule, target.id);

      expect(copy.attachments.map((a) => a.name), ['Fox 36 Service Manual', 'Torque chart.jpg']);
      expect(copy.attachments.map((a) => a.id), isNot(anyElement(anyOf(manual.id, chart.id))));
      expect(await (await service.resolve(copy.attachments[0].filename)).readAsBytes(), [1, 2, 3]);
      expect(await (await service.resolve(copy.attachments[1].filename)).readAsBytes(), [4, 5]);
      expect(await service.exists(manual.filename), isTrue);
      expect(await service.exists(chart.filename), isTrue);
    });

    test("deepCopy alone keeps the source componentId", () {
      // Guards the reason the copies are re-pointed in the action.
      final rule = TaskRule(name: "Check torque", tags: const {}, association: ComponentTaskAssociation(source.id));
      expect(rule.deepCopy().association.componentId, source.id);
    });

    test("copied rules land on the target while the source keeps its own", () async {
      final rules = [
        TaskRule(name: "Lower leg service", tags: const {}, association: ComponentTaskAssociation(source.id), interval: const DistanceThreshold(500000)),
        TaskRule(name: "Air spring rebuild", tags: const {}, association: ComponentTaskAssociation(source.id)),
      ];
      await repository.addTaskRules(rules);
      await pumpEventQueue();

      await repository.addTaskRules(await ComponentActions.taskRuleCopies(rules, componentId: target.id));
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
        TaskRule(name: "A", tags: const {}, association: ComponentTaskAssociation(target.id)),
        TaskRule(name: "B", tags: const {}, association: ComponentTaskAssociation(target.id)),
        TaskRule(name: "C", tags: const {}, association: ComponentTaskAssociation(target.id)),
      ]);
      await pumpEventQueue();

      expect(emissions, 1);
      await subscription.cancel();
    });

    test("the UNDO path removes and restores in one emission each", () async {
      final rules = [
        TaskRule(name: "A", tags: const {}, association: ComponentTaskAssociation(target.id)),
        TaskRule(name: "B", tags: const {}, association: ComponentTaskAssociation(target.id)),
        TaskRule(name: "C", tags: const {}, association: ComponentTaskAssociation(target.id)),
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
      await repository.addTaskRules([
        TaskRule(name: "Wash bike", tags: const {}, association: BikeTaskAssociation(bike.id)),
        TaskRule(name: "Check torque", tags: const {}, association: ComponentTaskAssociation(source.id)),
      ]);
      await pumpEventQueue();

      final offered = repository.taskRules.values.where((rule) => rule.association.componentId == source.id).toList();

      expect(offered.map((r) => r.name), ["Check torque"]);
    });
  });
}
