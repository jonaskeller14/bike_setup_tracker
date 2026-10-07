import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_actions.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {
  MockSubscriptionService({this.hasStravaEntitlement = false});

  @override
  final bool hasStravaEntitlement;
}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late bool hasStravaEntitlement;
  late ComponentCatalogRepository catalogRepository;

  final bike = Bike(id: 'b1', name: 'Test Bike', person: null);
  final current = Component(
    id: 'c1',
    name: 'Current Fork',
    componentType: ComponentType.fork,
    installations: [Installation.sinceBeginning(parent: 'b1')],
    adjustments: const [],
  );
  final spare = Component(
    id: 'c2',
    name: 'Spare Fork',
    componentType: ComponentType.fork,
    installations: const [],
    adjustments: const [],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    hasStravaEntitlement = false;
    catalogRepository = ComponentCatalogRepository.withCatalogs(const []);
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest({
    String label = 'replace',
    Future<void> Function(BuildContext context)? action,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(
          create: (_) => MockSubscriptionService(hasStravaEntitlement: hasStravaEntitlement),
        ),
        Provider.value(value: catalogRepository),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => (action ?? (context) => ComponentActions.replaceComponent(context, component: current))(context),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settleRepository(WidgetTester tester, bool Function() until) async {
    // Pump between real waits so multi-step actions (e.g. UNDO) can continue.
    for (var attempts = 0; !until() && attempts < 100; attempts++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('replaceComponent installs the picked component and retires the current one', (tester) async {
    await tester.runAsync(() async {
      await appRepository.addBikes([bike]);
      await appRepository.addComponents([current, spare]);
      // A batched insert dispatches its drift table updates only once the
      // transaction unwinds. Yield so the query streams refetch here, before
      // the pending refetch is dropped along with the replaced repository.
      await Future<void>.delayed(Duration.zero);
    });
    appRepository.dispose();
    appRepository = AppRepository(database);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.runAsync(() => appRepository.initialDataLoaded);
    await tester.pumpAndSettle();
    expect(appRepository.components.keys, containsAll(['c1', 'c2']));

    await tester.tap(find.text('replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existing'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spare Fork').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await settleRepository(tester, () => appRepository.components['c2']?.parentId == 'b1');

    final installed = appRepository.components['c2']!;
    final retired = appRepository.components['c1']!;

    // The spare takes over the bike, the replaced one is left on no bike.
    expect(installed.parentId, 'b1');
    expect(retired.parentId, isNull);

    // Both sides of the swap are logged at the same replacement date.
    expect(installed.installations.single.parent, 'b1');
    expect(retired.installations.length, 2);
    expect(retired.installations.last.parent, isNull);
    expect(retired.installations.last.dateTimeUTC, installed.installations.single.dateTimeUTC);

    expect(find.textContaining("Replaced 'Current Fork' with 'Spare Fork'"), findsOneWidget);
  });

  group('removeComponent with subcomponents', () {
    final fork = Component(
      id: 'f1',
      name: 'Fork',
      componentType: ComponentType.fork,
      installations: [Installation.sinceBeginning(parent: 'b1')],
      adjustments: const [],
    );
    final damper = Component(
      id: 'd1',
      name: 'Damper',
      componentType: ComponentType.other,
      installations: [Installation.componentSinceBeginning(parentComponentId: 'f1')],
      adjustments: const [],
    );
    final token = Component(
      id: 't1',
      name: 'Token',
      componentType: ComponentType.other,
      installations: [Installation.componentSinceBeginning(parentComponentId: 'd1')],
      adjustments: const [],
    );

    Future<void> pumpRemove(WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        await appRepository.addComponents([fork, damper, token]);
        await Future<void>.delayed(Duration.zero);
      });
      appRepository.dispose();
      appRepository = AppRepository(database);

      await tester.pumpWidget(createWidgetUnderTest(
        label: 'remove',
        action: (context) => ComponentActions.removeComponent(context, component: fork),
      ));
      await tester.runAsync(() => appRepository.initialDataLoaded);
      await tester.pumpAndSettle();
      expect(appRepository.components.keys, containsAll(['f1', 'd1', 't1']));

      await tester.tap(find.text('remove'));
      await tester.pumpAndSettle();
    }

    testWidgets('only the parent: direct children are uninstalled, deeper ones stay on their parent', (tester) async {
      await pumpRemove(tester);
      await tester.tap(find.text("Remove only 'Fork'"));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Move to trash'));
      await tester.tap(find.text('Move to trash'));
      await tester.pumpAndSettle();

      await settleRepository(tester, () => !appRepository.components.containsKey('f1'));

      final detachedDamper = appRepository.components['d1']!;
      expect(detachedDamper.installations, hasLength(2));
      expect(detachedDamper.installations.last, isA<Uninstallation>());
      expect(appRepository.components['t1']!.installations.single.parent, 'd1');
      expect(find.textContaining('1 subcomponent uninstalled.'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await settleRepository(
        tester,
        () => appRepository.components.containsKey('f1') && appRepository.components['d1']!.installations.length == 1,
      );
      expect(appRepository.components['d1']!.installations.single.parent, 'f1');
    });

    testWidgets('with subcomponents: the whole tree is moved to the trash', (tester) async {
      await pumpRemove(tester);
      await tester.tap(find.text('Remove with subcomponents'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Move 3 components to trash'));
      await tester.tap(find.text('Move 3 components to trash'));
      await tester.pumpAndSettle();

      await settleRepository(tester, () => appRepository.deletedComponents.length == 3);
      expect(appRepository.components.keys, isNot(contains(anyOf('f1', 'd1', 't1'))));
      expect(find.textContaining('Also moved to trash: 2 subcomponents.'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await settleRepository(tester, () => appRepository.deletedComponents.isEmpty);
      expect(appRepository.components.keys, containsAll(['f1', 'd1', 't1']));
    });

    testWidgets('dismissing the sheet changes nothing', (tester) async {
      await pumpRemove(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Move to trash'), findsNothing);
      expect(appRepository.components.keys, containsAll(['f1', 'd1', 't1']));
      expect(appRepository.deletedComponents, isEmpty);
    });
  });

  group('offerTaskRulesFor', () {
    final chain = Component(
      id: 'ch1',
      name: 'Chain',
      componentType: ComponentType.chain,
      installations: [Installation.sinceBeginning(parent: 'b1')],
      adjustments: const [],
    );
    final newChain = Component(
      id: 'ch2',
      name: 'New Chain',
      componentType: ComponentType.chain,
      installations: [Installation.sinceBeginning(parent: 'b1')],
      adjustments: const [],
    );

    TaskRule chainRule(String name, {String? presetKey}) => TaskRule(
      name: name,
      tags: const {},
      association: const ComponentTaskAssociation('ch1'),
      interval: const DistanceThreshold(500000),
      repeat: true,
      presetKey: presetKey,
    );

    void enableTaskPresets() {
      appSettings
        ..enableTask = true
        ..enableComponentPresets = true
        ..enableTaskPresets = true;
    }

    List<TaskRule> rulesOf(String componentId) =>
        appRepository.taskRules.values.where((rule) => rule.association.componentId == componentId).toList();

    Future<void> pumpOffer(
      WidgetTester tester, {
      Component? source,
      required Component target,
      List<TaskRule> rules = const [],
    }) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        await appRepository.addComponents([?source, target]);
        await appRepository.addTaskRules(rules);
        await Future<void>.delayed(Duration.zero);
      });
      appRepository.dispose();
      appRepository = AppRepository(database);

      await tester.pumpWidget(createWidgetUnderTest(
        label: 'offer',
        action: (context) => ComponentActions.offerTaskRulesFor(context, source: source, target: target),
      ));
      await tester.runAsync(() => appRepository.initialDataLoaded);
      await tester.pumpAndSettle();

      await tester.tap(find.text('offer'));
      await tester.pumpAndSettle();
    }

    testWidgets('a new chain gets the recommend sheet; the defaults create chain:wear_check', (tester) async {
      enableTaskPresets();
      await pumpOffer(tester, target: chain);

      expect(find.text("Recommended tasks for 'Chain'"), findsOneWidget);
      // Without Strava, the ride-only chain templates are hidden.
      expect(find.text('Replace chain'), findsNothing);

      await tester.tap(find.text('Add 1 task'));
      await settleRepository(tester, () => rulesOf('ch1').isNotEmpty);

      final rule = rulesOf('ch1').single;
      expect(rule.presetKey, 'chain:wear_check');
      expect(rule.interval, isA<DurationThreshold>());
      expect(find.text("Added 1 task to 'Chain'."), findsOneWidget);
    });

    for (final (description, configure) in [
      ('task presets are off', () => appSettings.enableTask = true),
      ('the task interval is off', () {
        enableTaskPresets();
        appSettings.enableTaskInterval = false;
      }),
    ]) {
      testWidgets('no sheet when $description', (tester) async {
        configure();
        await pumpOffer(tester, target: chain);

        expect(find.byType(BottomSheet), findsNothing);
      });
    }

    testWidgets('no sheet for a component type without templates and without rules', (tester) async {
      enableTaskPresets();
      await pumpOffer(tester, target: chain.copyWith(componentType: ComponentType.other));

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('a duplicated chain gets the merged sheet without the suggestion its copy covers', (tester) async {
      enableTaskPresets();
      hasStravaEntitlement = true;
      await pumpOffer(
        tester,
        source: chain,
        target: newChain,
        rules: [chainRule('Measure stretch', presetKey: 'chain:wear_check')],
      );

      expect(find.text("Tasks for 'New Chain'"), findsOneWidget);
      expect(find.text("Copy from 'Chain'"), findsOneWidget);
      expect(find.text('Recommended for Chain'), findsOneWidget);
      expect(find.text('Check chain wear'), findsNothing);
      expect(find.text('Replace chain'), findsOneWidget);

      await tester.tap(find.text('Add 1 task'));
      await settleRepository(tester, () => rulesOf('ch2').isNotEmpty);

      final copy = rulesOf('ch2').single;
      expect(copy.name, 'Measure stretch');
      expect(copy.presetKey, 'chain:wear_check');
      expect(find.text("Copied 1 task to 'New Chain'."), findsOneWidget);
    });

    testWidgets('unchecking a keyed copy does not add its suggestion instead', (tester) async {
      enableTaskPresets();
      final fork = chain.copyWith(id: 'f1', name: 'Fork', componentType: ComponentType.fork);
      final newFork = newChain.copyWith(id: 'f2', name: 'New Fork', componentType: ComponentType.fork);
      await pumpOffer(
        tester,
        source: fork,
        target: newFork,
        rules: [
          chainRule('Lower legs', presetKey: 'fork:lower_leg_service').copyWith(
            association: const ComponentTaskAssociation('f1'),
          ),
        ],
      );

      await tester.tap(find.text('Lower legs'));
      await tester.pumpAndSettle();
      expect(find.text('Lower leg service'), findsOneWidget);

      await tester.tap(find.text('Add 1 task'));
      await settleRepository(tester, () => rulesOf('f2').isNotEmpty);

      expect(rulesOf('f2').map((rule) => rule.presetKey), ['fork:full_service']);
    });

    testWidgets('a catalog fork gets the manufacturer interval and its source', (tester) async {
      enableTaskPresets();
      hasStravaEntitlement = true;
      catalogRepository = ComponentCatalogRepository.withCatalogs([
        parseCatalogFile('''
brand: FOX
component_type: fork
nodes:
  - label: "36"
    level: model
    tasks:
      fork:lower_leg_service: { interval: { moving_time_h: 125 }, source: FOX 36 owner's manual }
'''),
      ]);
      final fox36 = chain.copyWith(
        id: 'f1',
        name: 'FOX 36',
        componentType: ComponentType.fork,
        preset: ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '36'}),
      );
      await pumpOffer(tester, target: fox36);

      expect(find.textContaining("FOX 36 owner's manual"), findsOneWidget);

      await tester.tap(find.text('Add 2 tasks'));
      await settleRepository(tester, () => rulesOf('f1').length == 2);

      final lowerLeg = rulesOf('f1').singleWhere((rule) => rule.presetKey == 'fork:lower_leg_service');
      expect(lowerLeg.interval, const MovingTimeThreshold(Duration(hours: 125)));
      expect(lowerLeg.notes, endsWith("Recommended interval: every 125 h — FOX 36 owner's manual"));
    });

    testWidgets('UNDO removes every created rule', (tester) async {
      enableTaskPresets();
      await pumpOffer(tester, source: chain, target: newChain, rules: [chainRule('Wax chain')]);

      await tester.tap(find.text('Add 2 tasks'));
      await settleRepository(tester, () => rulesOf('ch2').length == 2);
      expect(rulesOf('ch2').map((rule) => rule.presetKey), unorderedEquals([null, 'chain:wear_check']));
      expect(find.text("Added 2 tasks to 'New Chain'."), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await settleRepository(tester, () => rulesOf('ch2').isEmpty);
      expect(rulesOf('ch2'), isEmpty);
      expect(rulesOf('ch1'), hasLength(1));
    });
  });
}
