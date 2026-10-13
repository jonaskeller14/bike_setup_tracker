import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_card.dart';
import 'package:bike_setup_tracker/widgets/setup_page_tab_person.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

const _catalog = '''
brand: Acme
component_type: fork
guides:
  acme:
    label: Acme owner's manual (2027)
    source: https://example.com/acme
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
      - { target: lsc, value: 4 }
nodes:
  - label: Guided
    level: model
    guide: acme
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
      - { name: LSC, type: step, max: 10 }
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  Future<_Harness> open(WidgetTester tester, {bool enabled = true, bool forkHasValues = false}) async {
    final harness = (await tester.runAsync(() => _Harness.create(enabled: enabled, forkHasValues: forkHasValues)))!;
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.wrap(SetupPage.add()));
    // The catalog resolves asynchronously.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await _settle(tester);
    return harness;
  }

  testWidgets('recommends first values from the last recorded riding weight', (tester) async {
    await open(tester);

    expect(find.byType(SetupGuideCard), findsOneWidget);
    expect(find.text('Recommended values for 82 kg'), findsOneWidget);
    expect(find.text('77 psi'), findsOneWidget);
  });

  testWidgets('is hidden while the flag is off', (tester) async {
    await open(tester, enabled: false);

    expect(find.byType(SetupGuideCard), findsNothing);
  });

  testWidgets('is hidden once the guided component has recorded values', (tester) async {
    await open(tester, forkHasValues: true);

    expect(find.byType(SetupGuideCard), findsNothing);
  });

  testWidgets('follows the riding weight entered on the rider tab', (tester) async {
    await open(tester);

    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.byIcon(Person.iconData)));
    await _settle(tester);
    await tester.enterText(
      find.descendant(of: find.byType(SetupPersonTab), matching: find.byType(TextField)),
      '92',
    );
    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.byIcon(Bike.iconData)));
    await _settle(tester);

    expect(find.text('Recommended values for 92 kg'), findsOneWidget);
    expect(find.text('87 psi'), findsOneWidget);
  });

  testWidgets('Apply all fills the fields and leaves a notes line', (tester) async {
    // Tall enough that the notes field and the card are both laid out.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester);
    // The test environment's location error would queue ahead of the confirmation.
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();

    await tester.tap(find.text('Apply all'));
    await _settle(tester);

    final notes = tester.widget<TextField>(find.widgetWithText(TextField, 'Notes (optional)'));
    expect(notes.controller!.text, "Started from recommended values (Acme owner's manual (2027)) · 82 kg");
    expect(find.text('Applied 2 recommended values'), findsOneWidget);
    expect(find.text('On guide'), findsNWidgets(2));
    expect(find.widgetWithText(TextField, '77.0'), findsOneWidget);
  });
}

/// [SetupPage.add] fetches the location on open, leaving the location chip
/// spinning for the whole test, so the page never settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class _Harness {
  static const bikeId = 'bike';
  static const personId = 'person';
  static const weightId = 'weight';

  final AppDatabase database;
  final AppRepository repository;
  final AppSettings settings;
  final ComponentCatalogRepository catalog;

  _Harness({required this.database, required this.repository, required this.settings, required this.catalog});

  static Future<_Harness> create({required bool enabled, required bool forkHasValues}) async {
    final brand = parseCatalogFile(_catalog);
    final application = buildCatalogApplication(catalogProducts(brand).single);
    final fork = Component(
      name: application.name,
      componentType: application.componentType,
      installations: const [],
      adjustments: application.adjustments,
      preset: application.preset,
    ).copyWithNewInstallation(bikeId);

    final database = AppDatabase.memory();
    final seedRepository = AppRepository(database);
    await seedRepository.addPersons([
      Person(
        id: personId,
        name: 'Rider',
        adjustments: [
          NumericalAdjustment(
            id: weightId,
            name: 'Riding weight',
            notes: null,
            unit: AdjustmentUnit.fromLegacy('kg'),
            min: 0,
            presetKey: 'person:riding_weight',
          ),
        ],
      ),
    ]);
    await seedRepository.addBikes([Bike(id: bikeId, name: 'Test Bike', person: personId)]);
    await seedRepository.addComponents([fork]);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await seedRepository.addSetups([
      Setup(
        datetime: yesterday.toUtc(),
        datetimeLocal: yesterday,
        tags: const {},
        bike: bikeId,
        person: personId,
        bikeAdjustmentValues: {if (forkHasValues) fork.adjustments.first.id: const NumericalValue(70)},
        personAdjustmentValues: const {weightId: NumericalValue(82)},
      ),
    ]);
    seedRepository.dispose();

    final repository = AppRepository(database);
    for (var attempt = 0; attempt < 100 && repository.setups.isEmpty; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final settings = AppSettings()
      ..showOnboarding = false
      ..enablePerson = true
      ..enableComponentPresets = enabled
      ..enableSetupGuides = enabled;
    return _Harness(
      database: database,
      repository: repository,
      settings: settings,
      catalog: ComponentCatalogRepository.withCatalogs([brand]),
    );
  }

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: repository),
        ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
        Provider.value(value: catalog),
      ],
      child: MaterialApp(theme: materialAppTheme, home: home),
    );
  }

  Future<void> dispose() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  }
}
