import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/component_overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createWidgetUnderTest(
    AppData appData,
    AppSettings appSettings,
    String componentId,
    Future<void> Function(BuildContext, {required Component component}) editComponent,
  ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appData),
        ChangeNotifierProxyProvider<AppData, FilteredData>(
          create: (context) => FilteredData(appData),
          update: (context, newAppData, filteredData) => filteredData!..update(newAppData),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ComponentOverviewPage(
            componentId: componentId,
            editComponent: editComponent,
          ),
        ),
      ),
    );
  }

  testWidgets('show placeholder when setups are empty', (WidgetTester tester) async {
    final appData = AppData();
    final appSettings = AppSettings();
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [],
    );
    appData.components['comp1'] = component;

    await tester.pumpWidget(createWidgetUnderTest(appData, appSettings, 'comp1', (c, {required component}) async {}));
    await tester.pumpAndSettle();

    expect(find.text('No setups yet'), findsOneWidget);
  });

  testWidgets('show placeholder when no columns are selected', (WidgetTester tester) async {
    final appData = AppData();
    final appSettings = AppSettings();
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: 'clicks', category: AdjustmentCategory.component, min: 0, max: 10, step: 1, visualization: StepAdjustmentVisualization.slider);
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustment],
    );
    appData.components['comp1'] = component;

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
      isCurrent: false,
    );
    appData.setups[setup.id] = setup;

    await tester.pumpWidget(createWidgetUnderTest(appData, appSettings, 'comp1', (c, {required component}) async {}));
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
    final appData = AppData();
    final appSettings = AppSettings();
    // Component needs an adjustment for setups with that adjustment to be shown
    final adjustment = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: 'clicks', category: AdjustmentCategory.component, min: 0, max: 10, step: 1, visualization: StepAdjustmentVisualization.slider);
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustment],
    );
    appData.components['comp1'] = component;

    // Setups need the same bike and the adjustment values
    appData.setups['s1'] = Setup(id: 's1', name: 'A Setup', datetime: DateTime(2023).toUtc(), datetimeLocal: DateTime(2023), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}, isCurrent: false);
    appData.setups['s2'] = Setup(id: 's2', name: 'B Setup', datetime: DateTime(2024).toUtc(), datetimeLocal: DateTime(2024), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}, isCurrent: false);

    await tester.pumpWidget(createWidgetUnderTest(appData, appSettings, 'comp1', (c, {required component}) async {}));
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
    final appData = AppData();
    final appSettings = AppSettings();
    final adjustment1 = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    final adjustment2 = StepAdjustment(id: 'adj2', name: 'Compression', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    
    final component = Component(
      id: 'comp1',
      name: 'Test Fork',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustment1, adjustment2],
    );
    appData.components['comp1'] = component;

    appData.setups['s1'] = Setup(name: 'Setup 1', datetime: DateTime.now().toUtc(), datetimeLocal: DateTime.now(), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5, 'adj2': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}, isCurrent: false);

    await tester.pumpWidget(createWidgetUnderTest(appData, appSettings, 'comp1', (c, {required component}) async {}));
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
    final appData = AppData();
    final appSettings = AppSettings();
    final adjustmentOld = StepAdjustment(id: 'adj1', name: 'Rebound', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
    
    final component = Component(
      id: 'comp1',
      name: 'Old Fork Name',
      installations: [Installation.sinceBeginning(parent: 'bike1')],
      componentType: ComponentType.fork,
      adjustments: [adjustmentOld],
    );
    appData.components['comp1'] = component;

    appData.setups['s1'] = Setup(name: 'Setup 1', datetime: DateTime.now().toUtc(), datetimeLocal: DateTime.now(), tags: {}, bike: 'bike1', person: null, bikeAdjustmentValues: {'adj1': 5}, personAdjustmentValues: {}, ratingAdjustmentValues: {}, isCurrent: false);

    Future<void> mockEditComponent(BuildContext context, {required Component component}) async {
      // Simulate editing the component
      final newAdjustment = StepAdjustment(id: 'adj2', name: 'New Volume Spacers', notes: '', unit: null, category: AdjustmentCategory.component, step: 1, min: 0, max: 10, visualization: StepAdjustmentVisualization.slider);
      // Update the component in AppData
      final updatedComponent = Component(
        id: 'comp1',
        name: 'New Fork Name',
        installations: [Installation.sinceBeginning(parent: 'bike1')],
        componentType: ComponentType.fork,
        adjustments: [newAdjustment], // Removed Old, Added New
      );
      
      appData.components['comp1'] = updatedComponent;
      appData.notifyListeners();
    }

    await tester.pumpWidget(createWidgetUnderTest(appData, appSettings, 'comp1', mockEditComponent));
    await tester.pumpAndSettle();

    // Initial assertions
    expect(find.text('Old Fork Name'), findsOneWidget);
    expect(find.text('Rebound'), findsOneWidget);
    expect(find.text('New Volume Spacers'), findsNothing);

    // Tap edit button
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    // Assertions after edit
    expect(find.text('New Fork Name'), findsOneWidget);
    expect(find.text('Rebound'), findsNothing);
    expect(find.text('New Volume Spacers'), findsOneWidget);
  });
}
