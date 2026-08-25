import 'dart:async';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/details/component_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_data/component_details_page_line_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/component_details_page_radial_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/component_details_page_table.dart';
import 'package:bike_setup_tracker/widgets/display_installation_timeline.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_edit_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: ComponentDetailsPage(
            componentId: componentId,
          ),
        ),
      ),
    );
  }

  Widget createTableWidget(int setupCount) {
    final setups = List.generate(
      setupCount,
      (index) => Setup(
        id: 'setup-$index',
        name: 'Setup $index',
        datetime: DateTime(2024, 1, 1).toUtc(),
        datetimeLocal: DateTime(2024, 1, 1),
        tags: {},
        bike: 'bike1',
        person: null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
      ),
    );

    return ChangeNotifierProvider.value(
      value: appSettings,
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: ComponentDetailsPageTable(
            key: ValueKey(setupCount),
            activeColumns: const [],
            setups: setups,
            selectedSetupIds: const {},
            sortAscending: true,
            sortColumn: null,
            bikes: const {},
            valueFor: (_, _) => null,
            columnLabel: (_) => '',
            onSort: (_, _) {},
            onColumnRemoved: (_) {},
            onSelectAll: (_) {},
            onSetupSelected: (_, _) {},
          ),
        ),
      ),
    );
  }

  testWidgets('uses setup-aware rows-per-page options and defaults', (WidgetTester tester) async {
    final cases = <int, List<int>>{
      0: [1],
      3: [3],
      5: [5],
      7: [5, 7],
      10: [5, 10],
      11: [5, 10, 11],
      20: [5, 10, 20],
      21: [5, 10, 20, 21],
      50: [5, 10, 20, 50],
      51: [5, 10, 20, 50],
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(createTableWidget(entry.key));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
      expect(dropdown.value, entry.key < 5 ? entry.key.clamp(1, 5) : 5);
      expect(dropdown.items!.map((item) => item.value).toList(), entry.value);
    }
  });

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
          unit: AdjustmentUnit.fromLegacy('clicks'),
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
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });

    await tester.pumpAndSettle();

    expect(find.text('No setups yet'), findsOneWidget);
    expect(find.byType(ComponentDetailsPageTable), findsNothing);
  });

  testWidgets('shows installation history for complex data when feature is disabled', (WidgetTester tester) async {
    appSettings.enableInstallationTimeline = false;
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [
        Installation.sinceBeginning(parent: 'bike1', componentId: 'comp1'),
        Uninstallation(
          componentId: 'comp1',
          dateTimeUTC: DateTime.utc(2026, 1, 2),
          dateTimeLocal: DateTime(2026, 1, 2),
        ),
      ],
      componentType: ComponentType.fork,
    );
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(component);
    });

    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await _waitForComponent(tester, appRepository);

    expect(find.text('History'), findsOneWidget);
    expect(find.byType(DisplayInstallationTimeline), findsOneWidget);
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
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });

    await tester.pumpAndSettle();

    expect(find.text('No adjustments'), findsOneWidget);
    expect(find.text('No adjustments are defined for this component'), findsOneWidget);
    expect(find.byType(ComponentDetailsPageTable), findsNothing);
  });

  testWidgets('show placeholder when no columns are selected', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: AdjustmentUnit.fromLegacy('clicks'), min: 0, max: 10, step: 1, visualization: StepAdjustmentVisualization.slider);
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
        await Future<void>.delayed(const Duration(milliseconds: 100));
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
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: AdjustmentUnit.fromLegacy('clicks'), min: 0, max: 10, step: 1, visualization: StepAdjustmentVisualization.slider);
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
      await appRepository.addSetup(Setup(id: 's1', name: 'A Setup', datetime: DateTime(2023).toUtc(), datetimeLocal: DateTime(2023), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'B Setup', datetime: DateTime(2024).toUtc(), datetimeLocal: DateTime(2024), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}));
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
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
    final adjustment1 = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    final adjustment2 = StepAdjustment(id: 'adj2', name: 'Compression', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    
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
      await appRepository.addSetup(Setup(name: 'Setup 1', datetime: DateTime.now().toUtc(), datetimeLocal: DateTime.now(), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5, 'adj2': 5}, personAdjustmentValues: {}));
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Sort by Compression
    await tester.tap(find.text('Compression'));
    await tester.pumpAndSettle();

    // Remove Compression directly from its table header.
    await tester.longPress(
      find.descendant(of: find.byType(DataTable), matching: find.text('Compression')),
    );
    await tester.pumpAndSettle();

    // It should not crash, and the column should be removed from the DataTable
    // We check that it's not found in the DataTable (descendant of DataTable)
    expect(find.descendant(of: find.byType(DataTable), matching: find.text('Compression')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit Component updates ComponentOverviewPage (remove column, add possible columns, update appbar name)', (WidgetTester tester) async {
    final adjustmentOld = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    
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
      await appRepository.addSetup(Setup(name: 'Setup 1', datetime: DateTime.now().toUtc(), datetimeLocal: DateTime.now(), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}));
    });
    
    appRepository.dispose();
    appRepository = AppRepository(database);
    
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    // Wait for data
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
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
    expect(find.text('No setups yet'), findsOneWidget);
    expect(find.byType(ComponentDetailsPageTable), findsNothing);
  });

  // ── Row selection ──────────────────────────────────────────────────────────

  testWidgets('initially selects the 3 most recent setups and labels chart endpoints', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      for (int i = 1; i <= 7; i++) {
        await appRepository.addSetup(Setup(
          id: 's$i', name: 'Setup $i',
          datetime: DateTime(2024, 1, i).toUtc(), datetimeLocal: DateTime(2024, 1, i),
          tags: {}, bike: 'bike1', person: null,
          bikeAdjustmentValues: {'adj1': i},
          personAdjustmentValues: {},
        ));
      }
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    final lineChart = tester.widget<ComponentDetailsPageLineChart>(
      find.byType(ComponentDetailsPageLineChart),
    );
    expect(lineChart.selectedSetups.map((setup) => setup.id), ['s7', 's6', 's5']);
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-07')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-05')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-06')),
      findsNothing,
    );
    final chartBounds = tester.getRect(find.byType(ComponentDetailsPageLineChart));
    final firstLabelBounds = tester.getRect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-07')),
    );
    final lastLabelBounds = tester.getRect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-05')),
    );
    expect(firstLabelBounds.left, greaterThanOrEqualTo(chartBounds.left));
    expect(lastLabelBounds.right, lessThanOrEqualTo(chartBounds.right));

    await tester.tap(find.descendant(of: find.byType(DataTable), matching: find.text('Name')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-07')),
      findsNothing,
    );
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-05')),
      findsNothing,
    );

    await tester.tap(find.descendant(of: find.byType(DataTable), matching: find.text('Date')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-07')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ComponentDetailsPageLineChart), matching: find.text('2024-01-05')),
      findsOneWidget,
    );

    final rowsPerPageDropdown = tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
    expect(rowsPerPageDropdown.items!.map((item) => item.value), contains(7));
  });

  testWidgets('header checkbox shows and controls selection across all pages', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      for (int i = 1; i <= 6; i++) {
        await appRepository.addSetup(Setup(
          id: 's$i', name: 'Setup $i',
          datetime: DateTime(2024, 1, i).toUtc(), datetimeLocal: DateTime(2024, 1, i),
          tags: {}, bike: 'bike1', person: null,
          bikeAdjustmentValues: {'adj1': i},
          personAdjustmentValues: {},
        ));
      }
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    Checkbox selectAll() => tester.widget(find.byKey(const ValueKey('select-all-setups')));

    expect(selectAll().value, isNull);

    await tester.tap(find.text('Setup 3'));
    await tester.tap(find.text('Setup 2'));
    await tester.pumpAndSettle();

    // The current page is fully selected, but Setup 1 on page two is not.
    expect(selectAll().value, isNull);

    await tester.tap(find.byKey(const ValueKey('select-all-setups')));
    await tester.pumpAndSettle();
    expect(selectAll().value, isTrue);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byKey(const ValueKey('select-setup-s1'))).value, isTrue);

    await tester.tap(find.byKey(const ValueKey('select-all-setups')));
    await tester.pumpAndSettle();
    expect(selectAll().value, isFalse);
    expect(tester.widget<Checkbox>(find.byKey(const ValueKey('select-setup-s1'))).value, isFalse);
  });

  testWidgets('tapping a selected row deselects it', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup Old', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup New', datetime: DateTime(2024, 2, 1).toUtc(), datetimeLocal: DateTime(2024, 2, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 7}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Both rows selected: header (true) + 2 rows (true) = 3 true checkboxes
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == true), findsNWidgets(3));

    // With 1 StepAdjustment (<3 required for radar), setup names only appear in the
    // DataTable — not in chart legends — so the finder is unambiguous.
    await tester.tap(find.text('Setup Old'));
    await tester.pumpAndSettle();

    // 1 row selected (true), 1 deselected (false); header becomes null (tristate)
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == true), findsNWidgets(1));
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == false), findsNWidgets(1));
    // Line chart requires at least 2 selected setups
    expect(find.text('Not enough setups'), findsOneWidget);
  });

  testWidgets('tapping an unselected row selects it', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup Old', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup New', datetime: DateTime(2024, 2, 1).toUtc(), datetimeLocal: DateTime(2024, 2, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 7}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Both rows are initially selected: header (true) + 2 rows (true) = 3 true checkboxes
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == true), findsNWidgets(3));

    // Deselect one row
    await tester.tap(find.text('Setup Old'));
    await tester.pumpAndSettle();

    // 1 selected (true), 1 deselected (false); header becomes null (tristate)
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == false), findsNWidgets(1));

    // Reselect it by tapping its (now unchecked) leading checkbox — the checkbox column
    // is the leftmost column and always on-screen, so this avoids any scroll-position issues.
    await tester.tap(find.byWidgetPredicate((w) => w is Checkbox && w.value == false));
    await tester.pumpAndSettle();

    // Both rows selected again: header (true) + 2 rows (true) = 3 true checkboxes
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == true), findsNWidgets(3));
    expect(find.byWidgetPredicate((w) => w is Checkbox && w.value == false), findsNothing);
  });

  testWidgets('reselecting a deselected radar setup does not restore its highlight', (WidgetTester tester) async {
    final adjustments = [
      StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
      StepAdjustment(id: 'adj2', name: 'Compression', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
      StepAdjustment(id: 'adj3', name: 'Volume Spacers', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
    ];
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: adjustments,
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup 1', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3, 'adj2': 4, 'adj3': 5}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup 2', datetime: DateTime(2024, 1, 2).toUtc(), datetimeLocal: DateTime(2024, 1, 2), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5, 'adj2': 6, 'adj3': 7}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await _waitForComponent(tester, appRepository);

    final radarSetup = find.descendant(
      of: find.byType(ComponentDetailsPageRadialChart),
      matching: find.text('Setup 1'),
    );
    await tester.ensureVisible(radarSetup);
    await tester.tap(radarSetup);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(radarSetup).style?.fontWeight, FontWeight.bold);

    final setupRow = find.descendant(of: find.byType(DataTable), matching: find.text('Setup 1'));
    await tester.ensureVisible(setupRow);
    await tester.tap(setupRow);
    await tester.pumpAndSettle();
    await tester.tap(setupRow);
    await tester.pumpAndSettle();

    final reselectedRadarSetup = find.descendant(
      of: find.byType(ComponentDetailsPageRadialChart),
      matching: find.text('Setup 1'),
    );
    await tester.ensureVisible(reselectedRadarSetup);
    expect(tester.widget<Text>(reselectedRadarSetup).style?.fontWeight, FontWeight.normal);
  });

  testWidgets('re-enabling a removed line-chart column does not restore its highlight', (WidgetTester tester) async {
    final adjustments = [
      StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
      StepAdjustment(id: 'adj2', name: 'Compression', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider),
    ];
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: adjustments,
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup 1', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3, 'adj2': 4}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup 2', datetime: DateTime(2024, 1, 2).toUtc(), datetimeLocal: DateTime(2024, 1, 2), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5, 'adj2': 6}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await _waitForComponent(tester, appRepository);

    final lineColumn = find.descendant(
      of: find.byType(ComponentDetailsPageLineChart),
      matching: find.text('Rebound'),
    );
    await tester.ensureVisible(lineColumn);
    await tester.tap(lineColumn);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(lineColumn).style?.fontWeight, FontWeight.bold);

    await tester.longPress(lineColumn);
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(DataTable), matching: find.text('Rebound')), findsNothing);

    await tester.ensureVisible(find.text('Columns'));
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.text('Rebound')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final reenabledLineColumn = find.descendant(
      of: find.byType(ComponentDetailsPageLineChart),
      matching: find.text('Rebound'),
    );
    await tester.ensureVisible(reenabledLineColumn);
    expect(tester.widget<Text>(reenabledLineColumn).style?.fontWeight, FontWeight.normal);
  });

  // ── Chart placeholders ─────────────────────────────────────────────────────

  testWidgets('line and radar charts show placeholder when no numerical columns are active', (WidgetTester tester) async {
    final adjustment = CategoricalAdjustment(id: 'adj1', name: 'Tire Brand', notes: '', unit: null, options: {'Brand A', 'Brand B'});
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup 1', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 'Brand A'}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Both chart sections show this placeholder since categorical values cannot be plotted
    expect(find.text('Select numerical or step adjustment columns to visualize trends'), findsNWidgets(2));
  });

  testWidgets('line and radar charts show placeholder when no setups are selected', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup 1', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup 2', datetime: DateTime(2024, 1, 2).toUtc(), datetimeLocal: DateTime(2024, 1, 2), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Deselect both rows; setup names only appear in DataTable (radar shows placeholder)
    await tester.tap(find.text('Setup 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setup 2'));
    await tester.pumpAndSettle();

    expect(find.text('Select setups in the table above to visualize the chart'), findsNWidgets(2));
  });

  testWidgets('line chart shows placeholder when fewer than 2 setups are selected', (WidgetTester tester) async {
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adjustment],
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup 1', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup 2', datetime: DateTime(2024, 1, 2).toUtc(), datetimeLocal: DateTime(2024, 1, 2), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    // Deselect one row, leaving only 1 selected
    await tester.tap(find.text('Setup 1'));
    await tester.pumpAndSettle();

    expect(find.text('Not enough setups'), findsOneWidget);
  });

  testWidgets('radar chart shows placeholder when fewer than 3 numerical columns are active', (WidgetTester tester) async {
    // 2 numerical columns < 3 required for a radar chart
    final adj1 = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    final adj2 = StepAdjustment(id: 'adj2', name: 'Compression', notes: '', unit: null, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    await tester.runAsync(() async {
      await appRepository.addBike(Bike(id: 'bike1', name: 'Test Bike', person: null));
      await appRepository.addComponent(Component(
        id: 'comp1', name: 'Test Fork',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [adj1, adj2],
      ));
      await appRepository.addSetup(Setup(id: 's1', name: 'Setup 1', datetime: DateTime(2024, 1, 1).toUtc(), datetimeLocal: DateTime(2024, 1, 1), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 3, 'adj2': 5}, personAdjustmentValues: {}));
      await appRepository.addSetup(Setup(id: 's2', name: 'Setup 2', datetime: DateTime(2024, 1, 2).toUtc(), datetimeLocal: DateTime(2024, 1, 2), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 4, 'adj2': 7}, personAdjustmentValues: {}));
    });
    appRepository.dispose();
    appRepository = AppRepository(database);
    await tester.pumpWidget(createWidgetUnderTest('comp1'));
    await tester.runAsync(() async {
      int attempts = 0;
      while (appRepository.components['comp1'] == null && attempts < 10) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('Not enough columns'), findsOneWidget);
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

Future<void> _waitForComponent(WidgetTester tester, AppRepository appRepository) async {
  await tester.runAsync(() async {
    int attempts = 0;
    while (appRepository.components['comp1'] == null && attempts < 10) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  });
  await tester.pumpAndSettle();
}
