import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/component_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:bike_setup_tracker/widgets/installation_parent_field.dart';
import 'package:bike_setup_tracker/widgets/set_installation_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StravaSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => true;
}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late ComponentCatalogRepository presetRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.enableInstallationTimeline = false;
    presetRepository = ComponentCatalogRepository.withCatalogs([
      parseCatalogFile('''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2: { name: GRIP X2, adjustments: [{ name: HSC, type: step, max: 8 }] }
    grip_x: { name: GRIP X, adjustments: [{ name: LSC, type: step, max: 16 }] }
nodes:
  - label: "38"
    level: model
    children:
      - label: Factory
        level: trim
        note: Preset note
        adjustments:
          - { name: Rebound, type: step, max: 20 }
  - label: "36"
    level: model
    children:
      - label: Performance
        level: trim
        options:
          damper: [grip_x2, grip_x]
          travel_mm: [150, 160]
'''),
      parseCatalogFile('''
brand: FOX
component_type: shock
nodes:
  - label: FLOAT X
    level: model
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0 }
'''),
    ]);
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest({
    Component? component,
    required ComponentPageMode mode,
    List<Installation>? initialInstallations,
    SubscriptionService? subscriptionService,
    ThemeData? theme,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider(create: (_) => AppHintService(appRepository: appRepository, appSettings: appSettings)),
        if (subscriptionService != null)
          ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService)
        else
          ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
        Provider<ComponentCatalogRepository>.value(value: presetRepository),
      ],
      child: MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Builder(
          builder: (context) {
            switch (mode) {
              case ComponentPageMode.add:
                return ComponentPage.add(initialInstallations: initialInstallations);
              case ComponentPageMode.edit:
                return ComponentPage.edit(component: component!);
              case ComponentPageMode.duplicate:
                return ComponentPage.duplicate(component: component!);
              case ComponentPageMode.replace:
                return ComponentPage.replace(
                  component: component!,
                  replacementDate: DateTime.now(),
                  replacedInstallation: component.installations.last,
                  replacedComponentId: component.id,
                );
            }
          },
        ),
      ),
    );
  }

  group('ComponentPage Initialization', () {
    testWidgets('renders in Add mode with default values', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Component'), findsOneWidget);
      expect(find.text('Component Name'), findsOneWidget);
      expect(find.text('UNINSTALLED'), findsOneWidget);
      expect(find.text('Please select type'), findsOneWidget);
      expect(find.text('No adjustments yet'), findsOneWidget);
    });

    testWidgets('renders in Edit mode with component data', (WidgetTester tester) async {
      final bike = Bike(name: 'My Bike', person: 'Me');
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
      });
      
      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: [
          BooleanAdjustment(name: 'Lockout', notes: '', unit: null),
        ],
      ).copyWithNewInstallation(bike.id);

      await _waitForRepositoryUpdate(tester, appRepository);

      await tester.pumpWidget(createWidgetUnderTest(
        component: component,
        mode: ComponentPageMode.edit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Component'), findsOneWidget);
      expect(find.text('My Fork'), findsOneWidget);
      expect(find.text('My Bike'), findsOneWidget);
      expect(find.text('Fork'), findsOneWidget);
      expect(find.text('Lockout'), findsOneWidget);
    });

    testWidgets('renders in Duplicate mode with component data and "Add" title', (WidgetTester tester) async {
      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: const [],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        component: component,
        mode: ComponentPageMode.duplicate,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Component'), findsOneWidget);
      expect(find.text('My Fork'), findsOneWidget);
    });
  });

  group('ComponentPage Validation', () {
    testWidgets('shows error when name is empty', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows error when type is not selected', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Component Name'), 'New Component');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Component type cannot be empty. You can edit it later.'), findsOneWidget);
    });

    testWidgets('does not count archived components as installed on a bike', (WidgetTester tester) async {
      final archivedAt = DateTime.now();
      Component archivedTire(String id) => Component(
        id: id,
        name: 'Archived Tire $id',
        componentType: ComponentType.tire,
        installations: [
          Archival(
            dateTimeUTC: archivedAt.toUtc(),
            dateTimeLocal: archivedAt,
          ),
        ],
      );

      final component = archivedTire('c1');
      await tester.runAsync(() async {
        await appRepository.addComponents([
          component,
          archivedTire('c2'),
          archivedTire('c3'),
        ]);
      });
      await _waitForRepositoryUpdate(tester, appRepository);

      await tester.pumpWidget(createWidgetUnderTest(
        component: component,
        mode: ComponentPageMode.edit,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('WARNING: There are already 2 Tire-Components installed on this bike.'),
        findsNothing,
      );
    });

  });

  group('ComponentPage Dropdown Scenarios', () {
    testWidgets('shows timeline editor for complex data when feature is disabled', (WidgetTester tester) async {
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.fork,
        installations: [
          Installation.sinceBeginning(parent: 'bike1'),
          Uninstallation(
            dateTimeUTC: DateTime.utc(2026, 1, 2),
            dateTimeLocal: DateTime(2026, 1, 2),
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        component: component,
        mode: ComponentPageMode.edit,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SetInstallationTimeline), findsOneWidget);
      expect(find.byType(InstallationParentField), findsNWidgets(2), reason: 'one per timeline row, no simple field');
    });

    testWidgets('the simple parent picker suggests the timeline and switches the form to it', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([
          Bike(id: 'bike1', name: 'Trail', person: null),
          Bike(id: 'bike2', name: 'Enduro', person: null),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: 'bike1')],
      );

      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();
      expect(find.byType(SetInstallationTimeline), findsNothing);

      await tester.tap(find.byType(InstallationParentField));
      await tester.pumpAndSettle();
      expect(find.text('Track installation history'), findsOneWidget);

      await tester.ensureVisible(find.text('Activate Timeline'));
      await tester.tap(find.text('Activate Timeline'));
      await tester.pumpAndSettle();

      expect(appSettings.enableInstallationTimeline, isTrue);
      expect(find.text('Track installation history'), findsNothing);
      expect(find.byType(SetInstallationTimeline), findsOneWidget);
    });

    testWidgets('the simple parent picker hides "ARCHIVED" while adding', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(mode: ComponentPageMode.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InstallationParentField));
      await tester.pumpAndSettle();

      expect(find.text('ARCHIVED'), findsNothing);
      expect(find.text('UNINSTALLED'), findsWidgets);
    });

    testWidgets('displays "BIKE NOT FOUND" when initial bike is missing', (WidgetTester tester) async {
      // Page requested with an ID that doesn't exist in appRepository
      await tester.pumpWidget(createWidgetUnderTest(
        mode: ComponentPageMode.add,
        initialInstallations: [Installation.sinceBeginning(parent: 'non-existent-id')],
      ));
      await tester.pumpAndSettle();

      expect(find.text('BIKE NOT FOUND'), findsOneWidget);
    });

    testWidgets('does not detect changes initially when installation timeline is enabled', (WidgetTester tester) async {
      appSettings.enableInstallationTimeline = true;
      
      await tester.pumpWidget(createWidgetUnderTest(
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isTrue, reason: 'Form should not have changes initially');
    });
  });

  group('ComponentPage applied preset', () {
    const presetName = 'FOX 38 Factory';

    Future<void> pickFoxFactory(WidgetTester tester) async {
      for (final step in ['FOX', '38', 'Factory']) {
        final row = find.widgetWithText(ListTile, step);
        if (row.evaluate().isEmpty) continue; // The picker skips single-choice levels.
        await tester.tap(row.last);
        await tester.pumpAndSettle();
      }
    }

    String notesText(WidgetTester tester) => tester
        .widget<TextField>(find.descendant(
          of: find.widgetWithText(TextFormField, 'Notes (optional)'),
          matching: find.byType(TextField),
        ))
        .controller!
        .text;

    Future<void> applyPresetViaAutocomplete(WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      await tester.pumpWidget(createWidgetUnderTest(mode: ComponentPageMode.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Component Name'), 'fox 38');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, presetName));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the applied preset, confirms it and offers undo', (WidgetTester tester) async {
      await applyPresetViaAutocomplete(tester);

      expect(find.text('Tap to change'), findsOneWidget);
      expect(find.text('Filled from $presetName'), findsOneWidget);
      // Rebound from the spec plus the auto-injected SAG.
      expect(find.text('2 adjustments prefilled from $presetName'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(find.text(presetName), findsNothing);
      expect(find.widgetWithText(TextFormField, 'fox 38'), findsOneWidget, reason: 'Undo restores the typed query');
      expect(find.text('2 adjustments prefilled from $presetName'), findsNothing);
      expect(find.text('Please select type'), findsOneWidget);
    });

    testWidgets('the name suggestions follow the chosen type', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      await tester.pumpWidget(createWidgetUnderTest(mode: ComponentPageMode.add));
      await tester.pumpAndSettle();
      final nameField = find.widgetWithText(TextFormField, 'Component Name');

      await tester.enterText(nameField, 'fox float');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'FOX FLOAT X'), findsOneWidget, reason: 'Without a type, every type is offered');

      await tester.enterText(nameField, 'fox 38');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, presetName));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, presetName), 'fox float');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'FOX FLOAT X'), findsNothing, reason: 'A fork is not offered shocks');
    });

    testWidgets('unlinking keeps the prefilled values', (WidgetTester tester) async {
      await applyPresetViaAutocomplete(tester);

      await tester.tap(find.byTooltip('Unlink preset (keeps values)'));
      await tester.pumpAndSettle();

      expect(find.text('Choose from catalog'), findsOneWidget);
      expect(find.text('2 adjustments prefilled from $presetName'), findsNothing);
      expect(find.widgetWithText(TextFormField, presetName), findsOneWidget);
      expect(find.text('Unlinked from $presetName — values kept'), findsOneWidget);
    });

    testWidgets('shows persisted provenance in edit mode', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      // Warm the per-type cache so the card teaser never touches rootBundle.
      await tester.runAsync(() => presetRepository.all());

      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: const [],
        preset: ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '38', 'trim': 'factory'}),
      );
      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      expect(find.text(presetName), findsOneWidget);
      expect(find.text('Tap to change'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

      await tester.tap(find.byTooltip('Unlink preset (keeps values)'));
      await tester.pumpAndSettle();

      expect(find.text(presetName), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse,
          reason: 'Unlinking changes the persisted preset');
    });

    testWidgets('a link the catalog no longer resolves says so and can be unlinked', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      await tester.runAsync(() => presetRepository.all());

      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: const [],
        preset: ComponentPreset(const {'brand': 'sram', 'component_type': 'fork', 'model': 'zeb'}),
      );
      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      expect(find.text('Catalog entry not found'), findsOneWidget);

      await tester.tap(find.byTooltip('Unlink preset (keeps values)'));
      await tester.pumpAndSettle();

      expect(find.text('Choose from catalog'), findsOneWidget);
      expect(find.text('Unlinked from catalog — values kept'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();

      expect(find.text('Catalog entry not found'), findsOneWidget);
    });

    testWidgets('a type change clears a link that has not resolved yet', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      final forks = Completer<List<BrandCatalog>>();
      presetRepository = ComponentCatalogRepository.withLoader(
        (type) => type == ComponentType.fork ? forks.future : Future.value(const <BrandCatalog>[]),
      );

      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: const [],
        preset: ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '38', 'trim': 'factory'}),
      );
      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fork').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shock').last);
      await tester.pumpAndSettle();
      forks.complete([
        parseCatalogFile('''
brand: FOX
component_type: fork
nodes:
  - label: "38"
    level: model
    children:
      - label: Factory
        level: trim
'''),
      ]);
      await tester.pumpAndSettle();

      expect(find.text(presetName), findsNothing, reason: 'The fork link resolving late must not come back on a shock');
      expect(find.text('Choose from catalog'), findsOneWidget);
    });

    testWidgets('picking in edit mode only adds missing adjustments', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      await tester.runAsync(() => presetRepository.all());

      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: const [],
        adjustments: [
          StepAdjustment(
            name: 'rebound',
            notes: '',
            unit: null,
            step: 1,
            min: 0,
            max: 20,
            visualization: StepAdjustmentVisualization.slider,
          ),
        ],
        notes: 'Serial 123',
      );
      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose from catalog'));
      await tester.pumpAndSettle();
      await pickFoxFactory(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
      await tester.pumpAndSettle();

      // Existing "rebound" matches the preset's "Rebound" by name → only SAG is added.
      expect(find.text('Linked to $presetName · 1 adjustment added'), findsOneWidget);
      expect(find.text('1 adjustment prefilled from $presetName · 1 other'), findsOneWidget);
      expect(find.text('rebound'), findsOneWidget);
      expect(find.text('SAG'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'My Fork'), findsOneWidget, reason: "Name stays the user's");
      expect(notesText(tester), 'Serial 123\n\n- Preset note');

      // Re-picking swaps the appended block instead of stacking a second copy.
      await tester.tap(find.widgetWithText(ListTile, presetName));
      await tester.pumpAndSettle();
      await pickFoxFactory(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
      await tester.pumpAndSettle();
      expect(notesText(tester), 'Serial 123\n\n- Preset note');
    });

    testWidgets('saves the picked path, damper and travel as the preset', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      await tester.runAsync(() => presetRepository.all());

      Object? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider(create: (_) => AppHintService(appRepository: appRepository, appSettings: appSettings)),
            ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
            Provider<ComponentCatalogRepository>.value(value: presetRepository),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComponentPage.edit(
                      component: Component(
                        id: 'c1',
                        name: 'My Fork',
                        componentType: ComponentType.fork,
                        installations: [Installation.sinceBeginning(parent: null)],
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose from catalog'));
      await tester.pumpAndSettle();
      for (final row in ['FOX', '36', 'Performance', 'GRIP X']) {
        await tester.tap(find.widgetWithText(ListTile, row).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(ChoiceChip, '160 mm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('FOX 36 Performance GRIP X'), findsOneWidget);
      expect(find.text('160 mm · Tap to change'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      final saved = (result! as EditResult<Component>).value;
      expect(
        saved.preset,
        ComponentPreset(const {
          'brand': 'fox',
          'component_type': 'fork',
          'model': '36',
          'trim': 'performance',
          'damper': 'grip_x',
          'travel_mm': 160,
        }),
      );
      expect(saved.adjustments.map((a) => a.name), ['SAG', 'LSC']);
      expect(saved.adjustments.whereType<SagAdjustment>().single.referenceTravelMm, 160);
    });
  });

  group('ComponentPage catalog update', () {
    const revision1 = '''
brand: FOX
component_type: fork
nodes:
  - label: "38"
    level: model
    adjustments:
      - { name: HSC, type: step, max: 8 }
''';
    const revision2 = '''
brand: FOX
component_type: fork
revision: 2
changes:
  - { revision: 2, review: Adds the low-speed compression adjuster. }
nodes:
  - label: "38"
    level: model
    adjustments:
      - { name: HSC, type: step, max: 8 }
      - { name: LSC, type: step, max: 16 }
''';

    /// Opens the edit page on a fork built from revision 1 while the catalog is
    /// at revision 2; the returned getter reads what it saved.
    Future<Component Function()> openOutdated(WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      presetRepository = ComponentCatalogRepository.withCatalogs([parseCatalogFile(revision2)]);
      await tester.runAsync(() => presetRepository.all());
      final app = buildCatalogApplication(catalogProducts(parseCatalogFile(revision1)).single);
      final component = Component(
        id: 'c1',
        name: app.name,
        componentType: ComponentType.fork,
        installations: [Installation.sinceBeginning(parent: null)],
        adjustments: app.adjustments,
        preset: app.preset,
      );

      Object? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider(create: (_) => AppHintService(appRepository: appRepository, appSettings: appSettings)),
            ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
            Provider<ComponentCatalogRepository>.value(value: presetRepository),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ComponentPage.edit(component: component)),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => (result! as EditResult<Component>).value;
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the pending review on the card', (WidgetTester tester) async {
      await openOutdated(tester);

      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Adds the low-speed compression adjuster.'), findsOneWidget);
    });

    testWidgets('dismissing keeps the adjustments and stores the revision', (WidgetTester tester) async {
      final saved = await openOutdated(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
      await tester.pumpAndSettle();

      expect(find.text('Catalog update dismissed'), findsOneWidget);
      expect(find.text('Update available'), findsNothing);
      await save(tester);
      expect(saved().preset!.revision, 2);
      expect(saved().adjustments.map((adjustment) => adjustment.name), ['HSC', 'SAG']);
    });

    testWidgets('reviewing merges the new adjuster and stores the revision', (WidgetTester tester) async {
      final saved = await openOutdated(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Review'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Update available'), findsNothing);
      await save(tester);
      expect(saved().preset!.revision, 2);
      expect(saved().adjustments.map((adjustment) => adjustment.name), ['HSC', 'SAG', 'LSC']);
    });
  });

  group('ComponentPage recorded values', () {
    const psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
    const kPa = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'kiloPascal');
    final bike = Bike(name: 'Bike', person: null);

    Component fork(Adjustment adjustment) => Component(
      id: 'fork',
      name: 'Fork',
      componentType: ComponentType.fork,
      adjustments: [adjustment],
      installations: [Installation.sinceBeginning(parent: bike.id)],
    );

    /// Saves [component] with a setup holding [value] for its adjustment,
    /// opens it in edit mode and returns a getter for what the form pops.
    Future<Object? Function()> openForm(WidgetTester tester, Component component, AdjustmentValue value) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        await appRepository.addComponents([component]);
        await appRepository.addSetups([
          Setup(
            name: 'Setup',
            tags: const {},
            datetime: DateTime(2024).toUtc(),
            datetimeLocal: DateTime(2024),
            bike: bike.id,
            person: null,
            bikeAdjustmentValues: {component.adjustments.single.id: value},
            personAdjustmentValues: const {},
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });

      Object? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider(create: (_) => AppHintService(appRepository: appRepository, appSettings: appSettings)),
            ChangeNotifierProvider<SubscriptionService>.value(value: _StravaSubscriptionService()),
            Provider<ComponentCatalogRepository>.value(value: presetRepository),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ComponentPage.edit(component: component)),
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

    /// Edits the only adjustment through [interact] and saves it. With
    /// [confirm], expects the value migration sheet and confirms it.
    Future<void> editAdjustment(
      WidgetTester tester,
      Future<void> Function() interact, {
      bool confirm = true,
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
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();
      if (!confirm) {
        expect(find.text('Update recorded values'), findsNothing);
        return;
      }
      expect(find.text('Update recorded values'), findsOneWidget);
      await inSheet?.call();
      await tester.tap(find.byKey(const Key('value-migration-confirm')));
      await tester.pumpAndSettle();
    }

    Future<void> setMax(WidgetTester tester, String label, String max) async {
      await tester.enterText(find.widgetWithText(TextFormField, label), max);
      await tester.pumpAndSettle();
    }

    Future<EditResult<Component>> saveForm(WidgetTester tester, Object? Function() result) async {
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      return result()! as EditResult<Component>;
    }

    testWidgets('two unit edits of one adjustment stage a single combined migration', (WidgetTester tester) async {
      final pressure = NumericalAdjustment(id: 'pressure', name: 'Pressure', notes: null, unit: psi);
      final result = await openForm(tester, fork(pressure), const NumericalValue(10));

      Future<void> changeUnitTo(String label) => editAdjustment(tester, () async {
        await tester.tap(find.byKey(const Key('unit_picker_field')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      });

      await changeUnitTo('bar');
      await changeUnitTo('kPa');

      final saved = await saveForm(tester, result);
      expect(saved.value.adjustments.single.unit, kPa);
      expect(saved.migrations, [
        ValueMigration('pressure', const [ConvertUnitStep(psi, kPa)]),
      ]);
    });

    group('a narrowed maximum edited again', () {
      final pressure = NumericalAdjustment(id: 'pressure', name: 'Pressure', notes: null, unit: psi, min: 0, max: 20);
      const maxField = 'Max Value (optional)';

      testWidgets('clamps to the newest maximum and shows the net change', (WidgetTester tester) async {
        final result = await openForm(tester, fork(pressure), const NumericalValue(20));

        await editAdjustment(tester, () => setMax(tester, maxField, '10'));
        await editAdjustment(
          tester,
          () => setMax(tester, maxField, '15'),
          inSheet: () async {
            expect(find.textContaining('This replaces the change you confirmed earlier.'), findsOneWidget);
            expect(find.text('Clamp'), findsOneWidget);
            expect(find.text('15 psi'), findsOneWidget);
          },
        );

        final migration = (await saveForm(tester, result)).migrations.single;
        expect(migration.apply(const NumericalValue(20)), const NumericalValue(15));
      });

      testWidgets('back to the saved maximum writes nothing', (WidgetTester tester) async {
        final result = await openForm(tester, fork(pressure), const NumericalValue(20));

        await editAdjustment(tester, () => setMax(tester, maxField, '10'));
        await editAdjustment(tester, () => setMax(tester, maxField, '20'), confirm: false);

        expect((await saveForm(tester, result)).migrations, isEmpty);
      });

      testWidgets('a rename-only re-edit shows the pending change again', (WidgetTester tester) async {
        final result = await openForm(tester, fork(pressure), const NumericalValue(20));

        await editAdjustment(tester, () => setMax(tester, maxField, '10'));
        await editAdjustment(tester, () async {
          await tester.enterText(find.widgetWithText(TextFormField, 'Adjustment Name'), 'Air');
          await tester.pumpAndSettle();
        });

        final migration = (await saveForm(tester, result)).migrations.single;
        expect(migration.apply(const NumericalValue(20)), const NumericalValue(10));
      });
    });

    group('a preset merge after an edit', () {
      final rebound = StepAdjustment(
        id: 'rebound',
        name: 'rebound',
        notes: '',
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.slider,
      );

      Future<Object? Function()> narrowThenMerge(WidgetTester tester) async {
        appSettings.enableComponentPresets = true;
        await tester.runAsync(() => presetRepository.all());
        final result = await openForm(tester, fork(rebound), const StepValue(20));
        await editAdjustment(tester, () => setMax(tester, 'Max Value', '10'));

        await tester.ensureVisible(find.text('Choose from catalog'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose from catalog'));
        await tester.pumpAndSettle();
        for (final step in ['FOX', '38', 'Factory']) {
          final row = find.widgetWithText(ListTile, step);
          if (row.evaluate().isEmpty) continue; // The picker skips single-choice levels.
          await tester.tap(row.last);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
        await tester.pumpAndSettle();
        return result;
      }

      testWidgets('rebuilds the pending change for the merged range', (WidgetTester tester) async {
        final result = await narrowThenMerge(tester);

        // The catalog's 0..20 is adopted, which is the saved range again.
        final saved = await saveForm(tester, result);
        expect((saved.value.adjustments.firstWhere((a) => a.id == 'rebound') as StepAdjustment).max, 20);
        expect(saved.migrations, isEmpty);
      });

      testWidgets('UNDO restores the pending change', (WidgetTester tester) async {
        final result = await narrowThenMerge(tester);
        await tester.tap(find.text('UNDO'));
        await tester.pumpAndSettle();

        final migration = (await saveForm(tester, result)).migrations.single;
        expect(migration.apply(const StepValue(20)), const StepValue(10));
      });
    });
  });

  group('ComponentPage attachments', () {
    const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProviderChannel,
        (call) async => Directory.systemTemp.path,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null);
    });

    final manual = Attachment(id: 'manual', extension: '.pdf', name: 'Fox 38 Service Manual.pdf');
    final invoice = Attachment(id: 'invoice', extension: '.pdf', name: 'Invoice.pdf');
    Component componentWithAttachments({List<Attachment>? attachments}) => Component(
      id: 'c1',
      name: 'My Fork',
      componentType: ComponentType.fork,
      installations: [Installation.sinceBeginning(parent: null)],
      adjustments: const [],
      attachments: attachments ?? [manual, invoice],
    );

    Finder attachChip() => find.widgetWithIcon(ActionChip, Icons.attach_file);

    testWidgets('hides the Attach chip when attachments are disabled', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(component: componentWithAttachments(), mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      expect(attachChip(), findsNothing);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('shows the Attach chip next to Initial Stats and the strip below', (tester) async {
      appSettings.enableAttachments = true;
      await tester.pumpWidget(createWidgetUnderTest(
        component: componentWithAttachments(),
        mode: ComponentPageMode.edit,
        subscriptionService: _StravaSubscriptionService(),
      ));
      await tester.pumpAndSettle();

      final wrap = find.ancestor(of: attachChip(), matching: find.byType(Wrap));
      expect(wrap, findsOneWidget);
      expect(find.descendant(of: wrap, matching: find.widgetWithText(FilterChip, 'Initial Stats')), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsOneWidget);
      expect(find.text('Fox 38 Service Manual.pdf'), findsOneWidget);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('both chips and a long attachment name fit a narrow screen ($label)', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        appSettings.enableAttachments = true;
        final longName = '${'Very long service manual name ' * 6}.pdf';
        await tester.pumpWidget(createWidgetUnderTest(
          component: componentWithAttachments(attachments: [Attachment(extension: '.pdf', name: longName), invoice]),
          mode: ComponentPageMode.edit,
          subscriptionService: _StravaSubscriptionService(),
          theme: theme,
        ));
        await tester.pumpAndSettle();

        expect(attachChip(), findsOneWidget);
        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('removing an attachment marks the form changed and saving returns the rest', (tester) async {
      appSettings.enableAttachments = true;
      Object? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider(create: (_) => AppHintService(appRepository: appRepository, appSettings: appSettings)),
            ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
            Provider<ComponentCatalogRepository>.value(value: presetRepository),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ComponentPage.edit(component: componentWithAttachments())),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      Color? chipColor() => tester.widget<ActionChip>(attachChip()).backgroundColor;
      expect(chipColor(), isNull);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Fox 38 Service Manual.pdf'), findsNothing);
      final changedFill = Theme.of(tester.element(attachChip())).extension<ValueHighlightColors>()!.changedFill;
      expect(chipColor(), changedFill);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(result, isA<EditResult<Component>>());
      final saved = (result! as EditResult<Component>).value;
      expect(saved.id, 'c1');
      expect(saved.attachments, [invoice]);
    });
  });
}

Future<void> _waitForRepositoryUpdate(WidgetTester tester, AppRepository repository) async {
  final completer = Completer<void>();
  void listener() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  repository.addListener(listener);

  await tester.runAsync(() async {
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      // Timeout is handled by falling back to pumps below
    }
  });

  repository.removeListener(listener);

  await tester.pump(); // Just a small pump to trigger rebuilds if needed
}
