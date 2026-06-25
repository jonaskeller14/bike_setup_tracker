import 'dart:async';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/pages/component_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
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
    appSettings.enableInstallationTimeline = false;
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest({
    Component? component,
    required ComponentPageMode mode,
    Object? initialBike,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            switch (mode) {
              case ComponentPageMode.add:
                return ComponentPage.add(initialBike: initialBike);
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
        await appRepository.addBike(bike);
      });
      
      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: [],
        adjustments: [
          BooleanAdjustment(name: 'Lockout', notes: '', unit: ''),
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

  });

  group('ComponentPage Dropdown Scenarios', () {
    testWidgets('displays "BIKE NOT FOUND" when initial bike is missing', (WidgetTester tester) async {
      // Page requested with an ID that doesn't exist in appRepository
      await tester.pumpWidget(createWidgetUnderTest(
        mode: ComponentPageMode.add,
        initialBike: 'non-existent-id',
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
