import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/screenshots/demo_scenario.dart';
import 'package:bike_setup_tracker/screenshots/screenshot_seed.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hightowerId = '93f93d45-3a56-43ae-8936-5cfcbd768c9b';

/// Every id that [json] refers to but doesn't contain, as readable lines.
List<String> _danglingReferences(Map<String, dynamic> json) {
  List<Map<String, dynamic>> list(String key) => (json[key] as List<dynamic>).cast<Map<String, dynamic>>();
  Set<Object?> ids(String key) => {null, ...list(key).map((item) => item['id'])};
  Set<Object?> adjustmentIds(String key) => {
    for (final item in list(key))
      for (final adjustment in (item['adjustments'] as List<dynamic>).cast<Map<String, dynamic>>()) adjustment['id'],
  };

  final bikes = ids('bikes');
  final components = ids('components');
  final persons = ids('persons');
  final setups = ids('setups');
  final taskRules = ids('taskRules');
  final gears = ids('stravaGears');
  final componentAdjustments = adjustmentIds('components');
  final personAdjustments = adjustmentIds('persons');

  final problems = <String>[];
  void check(bool ok, String problem) {
    if (!ok) problems.add(problem);
  }

  for (final bike in list('bikes')) {
    check(persons.contains(bike['person']), 'bike ${bike['name']}: person');
    check(gears.contains(bike['stravaGear']), 'bike ${bike['name']}: Strava gear');
  }
  for (final component in list('components')) {
    for (final installation in (component['installations'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final parents = switch (installation['type']) {
        'bike' => bikes,
        'component' => components,
        _ => {null},
      };
      check(parents.contains(installation['parent']), 'component ${component['name']}: installation parent');
    }
  }
  for (final setup in list('setups')) {
    check(bikes.contains(setup['bike']), 'setup ${setup['name']}: bike');
    check(persons.contains(setup['person']), 'setup ${setup['name']}: person');
    check(
      componentAdjustments.containsAll((setup['bikeAdjustmentValues'] as Map).keys),
      'setup ${setup['name']}: bike values',
    );
    check(
      personAdjustments.containsAll((setup['personAdjustmentValues'] as Map).keys),
      'setup ${setup['name']}: person values',
    );
  }
  for (final rule in list('taskRules')) {
    check(bikes.contains(rule['bikeId']), 'task rule ${rule['name']}: bike');
    check(components.contains(rule['componentId']), 'task rule ${rule['name']}: component');
  }
  for (final entry in list('taskEntries')) {
    check(taskRules.contains(entry['taskRule']), 'task entry ${entry['name']}: rule');
    check(bikes.contains(entry['bikeId']), 'task entry ${entry['name']}: bike');
    check(components.contains(entry['componentId']), 'task entry ${entry['name']}: component');
  }
  for (final rating in list('ratings')) {
    final targets = switch (rating['filterType']) {
      'FilterType.bike' => bikes,
      'FilterType.component' => components,
      'FilterType.person' => persons,
      _ => null,
    };
    check(targets == null || targets.contains(rating['filter']), 'rating ${rating['name']}: filter');
  }
  for (final entry in list('ratingEntries')) {
    check(bikes.contains(entry['bike']), 'rating entry ${entry['name']}: bike');
    check(setups.contains(entry['setupId']), 'rating entry ${entry['name']}: setup');
  }
  for (final activity in list('stravaActivities')) {
    check(gears.contains(activity['gearId']), 'activity ${activity['name']}: gear');
  }
  return problems;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 9, 26);

  Map<String, dynamic> seedJson(DemoScenario scenario) => ScreenshotSeed.buildSeedJson(
    sampleJson: File(ScreenshotSeed.sampleDataAsset).readAsStringSync(),
    stravaJson: File(ScreenshotSeed.stravaDataAsset).readAsStringSync(),
    today: today,
    scenario: scenario,
  );

  test('looks scenarios up by their flow name', () {
    for (final scenario in DemoScenario.values) {
      expect(DemoScenario.fromId(scenario.id), scenario);
    }
    expect(DemoScenario.fromId('one_bike_no_components'), DemoScenario.oneBikeNoComponents);
    expect(() => DemoScenario.fromId('one_bike'), throwsArgumentError);
  });

  test('applying a scenario leaves the full seed unchanged', () {
    final full = seedJson(DemoScenario.full);
    final before = full.toString();
    for (final scenario in DemoScenario.values) {
      scenario.apply(full);
    }
    expect(full.toString(), before);
  });

  for (final scenario in DemoScenario.values) {
    group(scenario.id, () {
      late AppDatabase database;
      late AppRepository repository;

      setUp(() {
        database = AppDatabase.memory();
        repository = AppRepository(database);
      });

      tearDown(() async {
        await repository.disposeAndAwaitCancellation();
        await database.close();
      });

      test('has no dangling references', () {
        expect(_danglingReferences(seedJson(scenario)), isEmpty);
      });

      test('imports cleanly', () async {
        final json = seedJson(scenario);
        await ScreenshotSeed.seedDatabase(repository, today: today, scenario: scenario);
        await repository.initialDataLoaded;

        expect(repository.bikes, hasLength((json['bikes'] as List).length));
        expect(repository.components, hasLength((json['components'] as List).length));
        expect(repository.setups, hasLength((json['setups'] as List).length));
        expect(repository.taskRules, hasLength((json['taskRules'] as List).length));
        expect(repository.taskEntries, hasLength((json['taskEntries'] as List).length));
        expect(repository.stravaActivities, hasLength((json['stravaActivities'] as List).length));
      });

      test('shows tags only in the tags scenario', () async {
        SharedPreferences.setMockInitialValues({});
        final settings = AppSettings();
        final hintService = AppHintService(appRepository: repository, appSettings: settings);
        await ScreenshotSeed.resetPreferences(hintService, scenario: scenario);

        final loaded = AppSettings();
        await loaded.loadAppSettings();
        expect(loaded.enableSetupTags, scenario == DemoScenario.tags);
        expect(loaded.enableTaskTags, scenario == DemoScenario.tags);
        expect(loaded.showOnboarding, isFalse);

        loaded.dispose();
        hintService.dispose();
        settings.dispose();
      });
    });
  }

  group('scenario content', () {
    test('empty has no bikes and nothing recorded on them', () {
      final json = seedJson(DemoScenario.empty);
      for (final key in ['bikes', 'components', 'setups', 'taskRules', 'taskEntries', 'stravaActivities']) {
        expect(json[key], isEmpty, reason: key);
      }
    });

    test('one_bike_no_components keeps the Hightower and its rides only', () {
      final json = seedJson(DemoScenario.oneBikeNoComponents);
      expect((json['bikes'] as List).map((b) => (b as Map)['id']), [_hightowerId]);
      expect(json['components'], isEmpty);
      expect(json['setups'], isEmpty);
      expect(json['stravaActivities'], isNotEmpty);
    });

    test('no_setups keeps the garage', () {
      final full = seedJson(DemoScenario.full);
      final json = seedJson(DemoScenario.noSetups);
      expect(json['setups'], isEmpty);
      expect(json['ratingEntries'], isEmpty);
      expect(json['bikes'], full['bikes']);
      expect(json['components'], full['components']);
    });

    test('analysis keeps every setup and drops suspension pressure', () {
      final json = seedJson(DemoScenario.analysis);
      expect((json['setups'] as List).length, (seedJson(DemoScenario.full)['setups'] as List).length);

      for (final component in (json['components'] as List).cast<Map<String, dynamic>>()) {
        if (!const {'ComponentType.fork', 'ComponentType.shock'}.contains(component['componentType'])) continue;
        expect((component['adjustments'] as List).map((a) => (a as Map)['name']), isNot(contains('Pressure')));
      }
    });

    test('tasks_one_due has a single due task that completes for good', () async {
      final database = AppDatabase.memory();
      final repository = AppRepository(database);
      await ScreenshotSeed.seedDatabase(repository, today: today, scenario: DemoScenario.tasksOneDue);
      await repository.initialDataLoaded;

      final due = repository.actionableTaskRules.single;
      expect(due.rule.name, 'Investigate BB creaking noise');
      expect(due.rule.repeat, isFalse);
      expect(repository.completedTaskRules, isNotEmpty);

      await repository.disposeAndAwaitCancellation();
      await database.close();
    });
  });

  group('scenario content (03_features demos)', () {
    late AppDatabase database;
    late AppRepository repository;

    setUp(() {
      database = AppDatabase.memory();
      repository = AppRepository(database);
    });

    tearDown(() async {
      await repository.disposeAndAwaitCancellation();
      await database.close();
    });

    Future<void> seed(DemoScenario scenario) async {
      await ScreenshotSeed.seedDatabase(repository, today: today, scenario: scenario);
      await repository.initialDataLoaded;
    }

    TaskRuleWithStatus forkLowers(Iterable<TaskRuleWithStatus> rules) =>
        rules.singleWhere((r) => r.rule.name == 'Fork lowers service');

    test('service_loop_before has the fork service upcoming at 46 of 50 h, and nothing due', () async {
      await seed(DemoScenario.serviceLoopBefore);
      expect(repository.actionableTaskRules, isEmpty);
      final fork = forkLowers(repository.upcomingTaskRules);
      expect(fork.status.progress, closeTo(46 / 50, 0.005));
    });

    test('service_loop_after has the fork service as the only task due, not yet overdue', () async {
      await seed(DemoScenario.serviceLoopAfter);
      final fork = forkLowers(repository.actionableTaskRules);
      expect(repository.actionableTaskRules, hasLength(1));
      expect(fork.status.type, TaskStatusType.due);
      expect(fork.status.progress, closeTo(51.5 / 50, 0.005));
    });

    test('histogram gives the Hightower a ride about every other day', () {
      final rides = (seedJson(DemoScenario.histogram)['stravaActivities'] as List)
          .where((a) => (a as Map)['gearId'] == 'b18168107');
      expect(rides.length, greaterThanOrEqualTo(30));
    });

    test('bike_fit keeps the Grizl with its fit adjustments and pre-fit values', () async {
      await seed(DemoScenario.bikeFit);
      expect(repository.bikes.values.map((b) => b.name), ['Canyon Grizl']);
      final names = repository.components.values.expand((c) => c.adjustments).map((a) => a.name);
      expect(names, containsAll(['Saddle Height', 'Saddle Setback', 'Stem Length', 'Spacers']));
      for (final setup in (seedJson(DemoScenario.bikeFit)['setups'] as List).cast<Map<String, dynamic>>()) {
        expect((setup['bikeAdjustmentValues'] as Map).values, containsAll([738.0, 25.0, 90.0, 20.0]));
      }
    });
  });

  group('content rules of the full sample', () {
    late AppDatabase database;
    late AppRepository repository;

    setUpAll(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await ScreenshotSeed.seedDatabase(repository, today: today);
      await repository.initialDataLoaded;
    });

    tearDownAll(() async {
      await repository.disposeAndAwaitCancellation();
      await database.close();
    });

    test('every setup changes at most 3 values', () {
      for (final setup in repository.setups.values) {
        final previous = repository.setupHistory.previousBikeValuesOf(setup.id);
        final changed = setup.bikeAdjustmentValues.entries.where(
          (e) => previous.containsKey(e.key) && previous[e.key] != e.value,
        );
        expect(changed.length, lessThanOrEqualTo(3), reason: setup.name);
      }
    });

    // The same linking as the activity details page: the setup active at the
    // start, plus the setups recorded during the ride.
    test('every activity links at most 2 setups', () {
      for (final activity in repository.stravaActivities.values) {
        final start = activity.startDateLocal;
        final end = start.add(activity.elapsedTime);
        final bikeSetups = repository.setups.values.where(
          (s) => repository.bikes[s.bike]?.stravaGear == activity.gearId,
        );
        final activeAtStart = bikeSetups.any((s) => !s.datetimeLocal.isAfter(start)) ? 1 : 0;
        final during = bikeSetups.where((s) => s.datetimeLocal.isAfter(start) && s.datetimeLocal.isBefore(end));
        expect(activeAtStart + during.length, lessThanOrEqualTo(2), reason: activity.name);
      }
    });

    test('has a calendar day with a setup, an activity, an installation and a task', () {
      final kindsByDay = <DateTime, Set<String>>{};
      void add(DateTime local, String kind) =>
          (kindsByDay[DateTime(local.year, local.month, local.day)] ??= {}).add(kind);

      for (final setup in repository.setups.values) {
        add(setup.datetimeLocal, 'setup');
      }
      for (final activity in repository.stravaActivities.values) {
        add(activity.startDateLocal, 'activity');
      }
      for (final entry in repository.taskEntries.values) {
        add(entry.dateTimeLocal, 'task');
      }
      for (final component in repository.components.values) {
        for (final installation in component.installations) {
          // 1970 marks "installed since the beginning", not a calendar day.
          if (installation.dateTimeLocal.year >= 2000) add(installation.dateTimeLocal, 'installation');
        }
      }

      expect(kindsByDay.values, anyElement(containsAll(['setup', 'activity', 'installation', 'task'])));
    });
  });
}
