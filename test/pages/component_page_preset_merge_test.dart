import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/component_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Linking a hand-built component with recorded setups to a catalog product
/// merges the catalog adjusters into the rider's own instead of duplicating them.

const _catalog = '''
brand: Acme
component_type: fork
guides:
  acme:
    label: Acme owner's manual (2027)
    source: https://example.com/acme
    rules:
      - { target: hsc, value: 4 }
nodes:
  - label: Guided
    level: model
    guide: acme
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
      - { name: LSR, type: step, max: 16 }
      - { name: HSC, type: step, max: 8 }
''';

const _productName = 'Acme Guided';
const _bikeId = 'bike';
const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');

final _pressure = NumericalAdjustment(id: 'pressure', name: 'Air pressure', notes: null, unit: _psi);
final _lsr = StepAdjustment(
  id: 'lsr',
  name: 'LSR',
  notes: null,
  unit: null,
  step: 1,
  min: 0,
  max: 20,
  visualization: StepAdjustmentVisualization.slider,
);
final _hsc = StepAdjustment(
  id: 'hsc',
  name: 'hsc',
  notes: null,
  unit: null,
  step: 1,
  min: 0,
  max: 10,
  visualization: StepAdjustmentVisualization.slider,
);

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;
  late ComponentCatalogRepository catalog;
  late Component fork;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fork = Component(
      id: 'fork',
      name: 'My Fork',
      componentType: ComponentType.fork,
      installations: const [],
      adjustments: [_pressure, _lsr, _hsc],
    ).copyWithNewInstallation(_bikeId);
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  });

  Future<void> seed() async {
    database = AppDatabase.memory();
    final seedRepository = AppRepository(database);
    await seedRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
    await seedRepository.addComponents([fork]);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await seedRepository.addSetups([
      Setup(
        datetime: yesterday.toUtc(),
        datetimeLocal: yesterday,
        tags: const {},
        bike: _bikeId,
        person: null,
        bikeAdjustmentValues: const {
          'pressure': NumericalValue(80),
          'lsr': StepValue(18),
          'hsc': StepValue(3),
        },
        personAdjustmentValues: const {},
      ),
    ]);
    seedRepository.dispose();

    repository = AppRepository(database);
    for (var attempt = 0; attempt < 100 && repository.setups.isEmpty; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    settings = AppSettings()
      ..enableInstallationTimeline = false
      ..enableComponentPresets = true;
    catalog = ComponentCatalogRepository.withCatalogs([parseCatalogFile(_catalog)]);
    await catalog.all();
  }

  /// Opens the edit page on [fork]; the returned getter reads what it saved.
  Future<Object? Function()> open(WidgetTester tester) async {
    await tester.runAsync(seed);
    // Tall enough for the sheet to build every result card.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Object? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: repository),
          ChangeNotifierProvider(
            create: (_) => AppHintService(appRepository: repository, appSettings: settings),
          ),
          ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
          Provider<ComponentCatalogRepository>.value(value: catalog),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ComponentPage.edit(component: fork)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  Future<void> pickProduct(WidgetTester tester) async {
    await tester.tap(find.text('Choose from catalog'));
    await tester.pumpAndSettle();
    for (final step in ['Acme', 'Guided']) {
      final row = find.widgetWithText(ListTile, step);
      if (row.evaluate().isEmpty) continue; // The picker skips single-choice levels.
      await tester.tap(row.last);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('links a hand-built component with recorded setups without duplicates', (tester) async {
    final saved = await open(tester);
    await pickProduct(tester);

    expect(find.text('Merge adjustments'), findsOneWidget);
    // LSR and HSC match by name; Pressure and the injected SAG have no match.
    expect(find.text('Result · 2 merged · 2 new · 1 unchanged'), findsOneWidget);
    expect(
      find.text("Keeps your range: recorded values lie outside the preset's"),
      findsOneWidget,
      reason: 'The recorded LSR 18 lies outside the catalog 0–16',
    );

    await tester.tap(find.widgetWithText(ListTile, 'Pressure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merge into "Air pressure"').last);
    await tester.pumpAndSettle();
    expect(find.text('Result · 3 merged · 1 new'), findsOneWidget);
    expect(find.text('Air pressure + Pressure (preset)'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expect(find.text('Linked to $_productName · 1 adjustment added'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final adjustments = (saved()! as EditResult<Component>).value.adjustments;
    expect(adjustments.map((a) => a.id).take(3), ['pressure', 'lsr', 'hsc']);
    expect(adjustments.map((a) => a.name), ['Air pressure', 'LSR', 'hsc', 'SAG']);
    expect(adjustments.map((a) => a.presetKey), ['fork:pressure', 'fork:lsr', 'fork:hsc', 'fork:sag']);
    expect((adjustments[1] as StepAdjustment).max, 20, reason: 'Keeps the range a recorded value needs');
    expect((adjustments[2] as StepAdjustment).max, 8, reason: 'Adopts the catalog range');
    final recorded = repository.setups.values.single.bikeAdjustmentValues;
    for (final id in recorded.keys) {
      expect(adjustments.singleWhere((a) => a.id == id).isValidValue(recorded[id]!), isTrue);
    }
  });

  testWidgets('undo restores the unlinked adjustments', (tester) async {
    await open(tester);
    await pickProduct(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expect(find.text('SAG'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();

    expect(find.text('SAG'), findsNothing);
    expect(find.text('Pressure'), findsNothing);
    expect(find.text('Choose from catalog'), findsOneWidget);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
  });

  testWidgets('a preset adjuster that is not added moves below the result', (tester) async {
    await open(tester);
    await pickProduct(tester);

    await tester.tap(find.widgetWithText(ListTile, 'SAG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't add").last);
    await tester.pumpAndSettle();

    expect(find.text('Result · 2 merged · 1 new · 1 unchanged'), findsOneWidget);
    expect(find.text('Not added'), findsNWidgets(2), reason: 'Section header and badge');
  });

  testWidgets('replacing warns about recorded values and uses only the preset adjustments', (tester) async {
    final saved = await open(tester);
    await pickProduct(tester);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 of your adjustments have 3 recorded values.'), findsOneWidget);
    expect(find.text('Result · 4 from the preset · 3 of yours removed'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
    await tester.pumpAndSettle();
    expect(find.text('Replaced adjustments with $_productName'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final adjustments = (saved()! as EditResult<Component>).value.adjustments;
    expect(adjustments.map((a) => a.name), ['Pressure', 'LSR', 'HSC', 'SAG']);
    expect(adjustments.map((a) => a.id), isNot(contains('pressure')));
  });

  testWidgets('dismissing the sheet links nothing', (tester) async {
    await open(tester);
    await pickProduct(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Choose from catalog'), findsOneWidget);
    expect(find.text('SAG'), findsNothing);
  });

  for (final enabled in [true, false]) {
    testWidgets('an unlinked component ${enabled ? 'shows' : 'hides'} the guide hint', (tester) async {
      await open(tester);
      settings.enableSetupGuides = enabled;
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Link to a catalog product to get recommended values'),
        enabled ? findsOneWidget : findsNothing,
      );
    });
  }
}
