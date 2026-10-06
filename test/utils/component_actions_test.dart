import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

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
        ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService()),
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
}
