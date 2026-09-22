import 'dart:async';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_preset.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/pages/component_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/component_preset_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_installation_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late ComponentPresetRepository presetRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.enableInstallationTimeline = false;
    presetRepository = ComponentPresetRepository.withVariants(const [
      ComponentPresetVariant(
        key: 'fox/38/factory',
        brand: 'FOX',
        model: '38',
        trim: 'Factory',
        componentType: ComponentType.fork,
        note: 'Preset note',
        adjustmentSpecs: [
          PresetAdjustmentSpec({'name': 'Rebound', 'type': 'step', 'max': 20}),
        ],
      ),
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
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
        Provider<ComponentPresetRepository>.value(value: presetRepository),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
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
                return ComponentPage.replace(component: component!, replacementDate: DateTime.now());
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
      expect(find.text('NOT INSTALLED'), findsOneWidget);
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
        installations: [],
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
        installations: [],
        adjustments: [],
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
      expect(find.byType(DropdownButtonFormField<Installation?>), findsNothing);
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

      expect(find.text('From catalog · Tap to change'), findsOneWidget);
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
        installations: [],
        adjustments: [],
        presetKey: 'fox/38/factory',
      );
      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      expect(find.text(presetName), findsOneWidget);
      expect(find.text('From catalog · Tap to change'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

      await tester.tap(find.byTooltip('Unlink preset (keeps values)'));
      await tester.pumpAndSettle();

      expect(find.text(presetName), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse,
          reason: 'Unlinking changes the persisted presetKey');
    });

    testWidgets('picking in edit mode only adds missing adjustments', (WidgetTester tester) async {
      appSettings.enableComponentPresets = true;
      await tester.runAsync(() => presetRepository.all());

      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: [],
        adjustments: [BooleanAdjustment(name: 'rebound', notes: '', unit: null)],
        notes: 'Serial 123',
      );
      await tester.pumpWidget(createWidgetUnderTest(component: component, mode: ComponentPageMode.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose from catalog'));
      await tester.pumpAndSettle();
      await pickFoxFactory(tester);

      // Existing "rebound" matches the preset's "Rebound" by name → only SAG is added.
      expect(find.text('Linked to $presetName · 1 adjustment added'), findsOneWidget);
      expect(find.text('1 adjustment prefilled from $presetName · 1 other'), findsOneWidget);
      expect(find.text('rebound'), findsOneWidget);
      expect(find.text('SAG'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'My Fork'), findsOneWidget, reason: "Name stays the user's");
      expect(notesText(tester), 'Serial 123\n\nPreset note');

      // Re-picking swaps the appended block instead of stacking a second copy.
      await tester.tap(find.widgetWithText(ListTile, presetName));
      await tester.pumpAndSettle();
      await pickFoxFactory(tester);
      expect(notesText(tester), 'Serial 123\n\nPreset note');
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
