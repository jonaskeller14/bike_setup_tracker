import 'dart:async';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/details/component_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_edit_list.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest(String componentId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ComponentDetailsPage(
            componentId: componentId,
          ),
        ),
      ),
    );
  }

  testWidgets('show placeholder when setups are empty', (WidgetTester tester) async {
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [
        StepAdjustment(
          id: 'adj1',
          name: 'Rebound',
          notes: '',
          unit: 'clicks',
          category: AdjustmentCategory.component,
          min: 0,
          max: 10,
          step: 1,
          visualization: StepAdjustmentVisualization.slider,
        ),
      ],
    );
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(component);
    });

    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for the asynchronous loading of components from the database
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });

    await tester.pumpAndSettle();

    expect(find.text('No setups yet'), findsOneWidget);
  });

  testWidgets('show placeholder when component has no adjustments', (WidgetTester tester) async {
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [],
    );
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(component);
    });

    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });

    await tester.pumpAndSettle();

    expect(find.text('No adjustments defined for this component'), findsOneWidget);
  });

  testWidgets('show placeholder when no columns are selected', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: 'clicks', category: AdjustmentCategory.component, min: 0, max: 10, step: 1, visualization: StepAdjustmentVisualization.slider);
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustment],
    );
    await tester.runAsync(() async {
      await appRepository.addComponent(component);

      final setup = Setup(
        name: 'Setup 1',
        datetime: DateTime.now().toUtc(),
        datetimeLocal: DateTime.now(),
        tags: {},
        bike: 'bike1',
        person: null,
        bikeAdjustmentValues: {'adj1': 5},
        personAdjustmentValues: {},
        ratingAdjustmentValues: {},
      );
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addSetup(setup);
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Open columns sheet
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();

    // Deselect active columns: Name, Date, adj1 (Rebound)
    // Use descendant of Wrap to avoid matching the ones in the DataTable background
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Name')));
    await tester.pumpAndSettle();
    
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Date')));
    await tester.pumpAndSettle();
    
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Rebound')));
    await tester.pumpAndSettle();

    // Tap outside to close the sheet (at the top area which should be the backdrop)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Select a column to display the table'), findsOneWidget);
  });

  testWidgets('sorting setups by name', (WidgetTester tester) async {
    // Component needs an adjustment for setups with that adjustment to be shown
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: 'clicks', category: AdjustmentCategory.component, min: 0, max: 10, step: 1, visualization: StepAdjustmentVisualization.slider);
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustment],
    );
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(component);
      await appRepository.addSetup(Setup(id: 's1', name: 'A Setup', datetime: DateTime(2023).toUtc(), datetimeLocal: DateTime(2023), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'B Setup', datetime: DateTime(2024).toUtc(), datetimeLocal: DateTime(2024), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}));
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Sort by name
    final nameColumn = find.text('Name');
    await tester.tap(nameColumn);
    await tester.pumpAndSettle();

    Iterable<String> getSetupTextOrder() {
      // Find all Text widgets and get their data, filter for our setup names
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();
      return texts.where((t) => t == 'A Setup' || t == 'B Setup');
    }

    var texts = getSetupTextOrder().toList();
    if (texts.isEmpty) {
        fail("No setups found in table. Check filters.");
    }

    // Ensure we start with A, B or toggle to it
    if (texts.first != 'A Setup') {
      await tester.tap(nameColumn);
      await tester.pumpAndSettle();
      texts = getSetupTextOrder().toList();
    }
    expect(texts, ['A Setup', 'B Setup']);

    // Tap again to reverse
    await tester.tap(nameColumn);
    await tester.pumpAndSettle();
    texts = getSetupTextOrder().toList();
    expect(texts, ['B Setup', 'A Setup']);
  });

  testWidgets('sortColumn and remove columns so that index >= length', (WidgetTester tester) async {
    final adjustment1 = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    final adjustment2 = StepAdjustment(id: 'adj2', name: 'Compression', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustment1, adjustment2],
    );
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(component);
      await appRepository.addSetup(Setup(name: 'Setup 1', datetime: DateTime.now().toUtc(), datetimeLocal: DateTime.now(), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5, 'adj2': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}));
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Sort by Compression
    await tester.tap(find.text('Compression'));
    await tester.pumpAndSettle();

    // Open columns sheet
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();

    // Deselect Compression in the sheet
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Compression')));
    await tester.pumpAndSettle();

    // Close sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // It should not crash, and the column should be removed from the DataTable
    // We check that it's not found in the DataTable (descendant of DataTable)
    expect(find.descendant(of: find.byType(DataTable), matching: find.text('Compression')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit Component updates ComponentOverviewPage (remove column, add possible columns, update appbar name)', (WidgetTester tester) async {
    final adjustmentOld = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    
    final component = Component(
      id: 'comp1',
      name: 'Old Fork Name',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustmentOld],
    );
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(component);
      await appRepository.addSetup(Setup(name: 'Setup 1', datetime: DateTime.now().toUtc(), datetimeLocal: DateTime.now(), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}));
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Initial assertions
    expect(find.text('Old Fork Name'), findsOneWidget);
    expect(find.text('Rebound'), findsOneWidget);
    expect(find.text('New Volume Spacers'), findsNothing);

    // Tap edit button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Verify we are on ComponentPage (Edit mode)
    expect(find.text('Edit Component'), findsOneWidget);

    // Update name
    await tester.enterText(find.widgetWithText(TextFormField, 'Component Name'), 'New Fork Name');
    await tester.pumpAndSettle();

    // Remove 'Rebound' adjustment
    final popupMenu = find.descendant(
      of: find.byType(AdjustmentEditList), 
      matching: find.bySubtype<PopupMenuButton<Enum>>()
    );
    await tester.ensureVisible(popupMenu);
    await tester.tap(popupMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    // Add 'New Volume Spacers' adjustment
    await tester.ensureVisible(find.text('Add Adjustment'));
    await tester.tap(find.text('Add Adjustment'));
    await tester.pumpAndSettle();
    
    // Tap Step Adjustment from custom section (not template since it might not be there for fork if not specifically added to presets)
    // Actually, presets has Rebound and Compression. Let's use custom Step Adjustment.
    await tester.ensureVisible(find.text('Step Adjustment'));
    await tester.tap(find.text('Step Adjustment'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Adjustment Name'), 'New Volume Spacers');
    await tester.enterText(find.widgetWithText(TextFormField, 'Max Value'), '5');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Save component
    await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.check)));
    await tester.pump(); // Start the pop and the callback
    
    // Wait for the async repository update
    await _waitForRepositoryUpdate(tester);

    // Assertions after edit
    expect(find.text('New Fork Name'), findsOneWidget);
    expect(find.text('Rebound'), findsNothing);
    expect(find.text('New Volume Spacers'), findsOneWidget);
  });
}

Future<void> _waitForRepositoryUpdate(WidgetTester tester) async {
  final appRepository = tester.element(find.byType(MaterialApp)).read<AppRepository>();
  final completer = Completer<void>();
  void listener() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  appRepository.addListener(listener);

  // We use a longer timeout and multiple pumps to allow background streams to fire
  await tester.runAsync(() async {
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      // Timeout is handled by falling back to pumps below
    }
  });

  appRepository.removeListener(listener);

  await tester.pumpAndSettle();
  // Extra pumps to ensure the UI has completely rebuilt from the new stream data
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}
