import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

/// End to end: edit an adjustment in the component form, confirm the value
/// migration sheet, save the form through [ComponentActions.editComponent] and
/// read the setups back from the database.
void main() {
  const psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
  const bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings()..enableInstallationTimeline = false;
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  });

  final bike = Bike(name: 'Bike', person: null);

  Component fork(Adjustment adjustment) => Component(
    id: 'fork',
    name: 'Fork',
    componentType: ComponentType.fork,
    adjustments: [adjustment],
    installations: [Installation.sinceBeginning(parent: bike.id)],
  );

  Setup setup(String id, Adjustment adjustment, AdjustmentValue value, {int day = 1}) => Setup(
    id: id,
    name: id,
    tags: const {},
    datetime: DateTime(2024, 1, day).toUtc(),
    datetimeLocal: DateTime(2024, 1, day),
    bike: bike.id,
    person: null,
    bikeAdjustmentValues: {adjustment.id: value},
    personAdjustmentValues: const {},
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
  }

  /// Saves [component] with [live] setups and soft-deleted [deleted] ones, then
  /// opens it in edit mode the way the component details page does.
  Future<void> openForm(
    WidgetTester tester,
    Component component, {
    required List<Setup> live,
    List<Setup> deleted = const [],
  }) async {
    await tester.runAsync(() async {
      await repository.addBikes([bike]);
      await repository.addComponents([component]);
      await repository.addSetups([...live, ...deleted]);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (deleted.isNotEmpty) await repository.removeSetups(deleted);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: repository),
          ChangeNotifierProvider(
            create: (_) => AppHintService(appRepository: repository, appSettings: settings),
          ),
          ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
          Provider<ComponentCatalogRepository>.value(value: ComponentCatalogRepository.withCatalogs(const [])),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ComponentActions.editComponent(context, component: component),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Edits the only adjustment through [interact] and saves it; [inSheet]
  /// checks the value migration sheet before it is confirmed. Without
  /// [inSheet] the sheet must not open.
  Future<void> editAdjustment(
    WidgetTester tester,
    Future<void> Function() interact, {
    Future<void> Function()? inSheet,
  }) async {
    await tester.ensureVisible(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await interact();
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);
    if (inSheet == null) {
      expect(find.text('Update recorded values'), findsNothing);
      return;
    }
    expect(find.text('Update recorded values'), findsOneWidget);
    await inSheet();
    await tester.tap(find.byKey(const Key('value-migration-confirm')));
    await tester.pumpAndSettle();
  }

  Future<void> saveForm(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);
  }

  Future<void> enterText(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), text);
    await tester.pumpAndSettle();
  }

  AdjustmentValue? stored(String setupId, String adjustmentId) =>
      repository.setups[setupId]!.bikeAdjustmentValues[adjustmentId];

  Future<AdjustmentValue?> storedDeleted(WidgetTester tester, String adjustmentId, AdjustmentType type) async {
    final rows = await tester.runAsync(() => database.setupsDao.getDeletedValuesFor(adjustmentId));
    return AdjustmentValue.decode(rows!.single.rawValue, type);
  }

  Adjustment savedAdjustment() => repository.components['fork']!.adjustments.single;

  testWidgets('converting psi to bar previews a real value and converts live and deleted setups', (tester) async {
    final pressure = NumericalAdjustment(id: 'pressure', name: 'Pressure', notes: null, unit: psi, min: 0, max: 300);
    await openForm(
      tester,
      fork(pressure),
      live: [setup('live', pressure, const NumericalValue(10))],
      deleted: [setup('deleted', pressure, const NumericalValue(20))],
    );

    await editAdjustment(
      tester,
      () async {
        await tester.tap(find.byKey(const Key('unit_picker_field')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('bar'));
        await tester.pumpAndSettle();
      },
      inSheet: () async {
        expect(
          find.text("Your change to 'Pressure' affects 1 setup (+1 deleted). Choose what happens to their values."),
          findsOneWidget,
        );
        expect(find.text('10 psi'), findsOneWidget);
        expect(find.text('≈ 0.689 bar'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Update 1 setup'), findsOneWidget);
      },
    );
    expect(find.text('Updates 1 setup (+1 deleted) on save'), findsOneWidget);

    await saveForm(tester);

    expect(savedAdjustment().unit, bar);
    expect((stored('live', 'pressure')! as NumericalValue).value, closeTo(0.689476, 1e-5));
    final deleted = await storedDeleted(tester, 'pressure', AdjustmentType.numerical);
    expect((deleted! as NumericalValue).value, closeTo(1.378951, 1e-5));
  });

  testWidgets('renaming and deleting options leaves no outdated value in any setup', (tester) async {
    final mode = CategoricalAdjustment(
      id: 'mode',
      name: 'Mode',
      notes: null,
      unit: null,
      options: const {'Open', 'Pedal', 'Lock'},
    );
    await openForm(
      tester,
      fork(mode),
      live: [
        setup('pedal', mode, CategoricalValue(const ['Pedal']), day: 1),
        setup('lock', mode, CategoricalValue(const ['Lock']), day: 2),
        setup('open', mode, CategoricalValue(const ['Open']), day: 3),
      ],
    );

    await editAdjustment(
      tester,
      () async {
        await enterText(tester, 'Option 2', 'Climb');
        await tester.tap(find.byTooltip('Remove option').at(2));
        await tester.pumpAndSettle();
      },
      inSheet: () async {
        expect(find.text("'Lock' was deleted"), findsWidgets);
        expect(find.text("Replace 'Lock' with"), findsOneWidget);
        expect(find.text("'Lock' becomes 'Open' in 1 setup."), findsOneWidget);
      },
    );

    await saveForm(tester);

    final saved = savedAdjustment() as CategoricalAdjustment;
    expect(saved.options, {'Open', 'Climb'});
    expect(stored('pedal', 'mode'), CategoricalValue(const ['Climb']));
    expect(stored('lock', 'mode'), CategoricalValue(const ['Open']));
    expect(stored('open', 'mode'), CategoricalValue(const ['Open']));
    // The setup details flag a value as outdated exactly when it is not valid.
    for (final id in ['pedal', 'lock', 'open']) {
      expect(saved.isValidValue(stored(id, 'mode')!), isTrue, reason: id);
    }
  });

  group('a narrowed maximum edited again', () {
    final pressure = NumericalAdjustment(id: 'pressure', name: 'Pressure', notes: null, unit: psi, min: 0, max: 20);
    const maxField = 'Max Value (optional)';

    testWidgets('clamps the stored value to the newest maximum', (tester) async {
      await openForm(tester, fork(pressure), live: [setup('setup', pressure, const NumericalValue(20))]);

      await editAdjustment(tester, () => enterText(tester, maxField, '10'), inSheet: () async {});
      expect(find.text('Updates 1 setup on save'), findsOneWidget);

      await editAdjustment(
        tester,
        () => enterText(tester, maxField, '15'),
        inSheet: () async {
          expect(find.textContaining('This replaces the change you confirmed earlier.'), findsOneWidget);
          expect(find.text('20 psi'), findsOneWidget);
          expect(find.text('15 psi'), findsOneWidget);
        },
      );

      await saveForm(tester);

      expect((savedAdjustment() as NumericalAdjustment).max, 15);
      expect(stored('setup', 'pressure'), const NumericalValue(15));
    });

    testWidgets('back to the saved maximum stages nothing and keeps the value', (tester) async {
      await openForm(tester, fork(pressure), live: [setup('setup', pressure, const NumericalValue(20))]);
      final lastModified = repository.setups['setup']!.lastModified;

      await editAdjustment(tester, () => enterText(tester, maxField, '10'), inSheet: () async {});
      expect(find.byIcon(Icons.sync_alt), findsOneWidget);

      await editAdjustment(tester, () => enterText(tester, maxField, '20'));
      expect(find.byIcon(Icons.sync_alt), findsNothing);

      await saveForm(tester);

      expect(stored('setup', 'pressure'), const NumericalValue(20));
      expect(repository.setups['setup']!.lastModified, lastModified);
    });
  });
}
