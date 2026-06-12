import 'dart:async';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/pages/onboarding_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/backup_service.dart';
import 'package:bike_setup_tracker/services/google_drive_service.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/widgets/items/adjustment_list_card.dart';
import 'package:bike_setup_tracker/widgets/items/component_list_card.dart';
import 'package:bike_setup_tracker/widgets/lists/garage_list.dart';
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
    appSettings.showOnboarding = false;
    appSettings.enableGarage = false;
    appSettings.enableStrava = false;
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest() {
    appRepository.dispose();
    appRepository = AppRepository(database);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        ChangeNotifierProvider<AppRepository>.value(value: appRepository),
        Provider<AppDatabase>.value(value: database),
        Provider<BackupService>(create: (_) => BackupService()),
        ChangeNotifierProvider<StravaService>(
            create: (_) => StravaService(appRepository, appSettings)),
        ChangeNotifierProvider<GoogleDriveService>(
            create: (_) => GoogleDriveService(appRepository, database)),
        ChangeNotifierProvider<SubscriptionService>(
            create: (_) => SubscriptionService()),
      ],
      child: const BikeSetupTrackerApp(),
    );
  }

  testWidgets('Home Page BottomNavigationBar', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    AppBar appBar = tester.widget(find.byType(AppBar).last);
    Text titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    final bikesDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Bikes'),
    );

    await tester.tap(bikesDestination.first);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar).last);
    titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    final componentsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Components'),
    );

    await tester.tap(componentsDestination.first);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar).last);
    titleText = appBar.title as Text;

    expect(titleText.data, contains('Components'));

    final setupsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Setups'),
    );

    await tester.tap(setupsDestination);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar).last);
    titleText = appBar.title as Text;

    expect(titleText.data, contains('Setup History'));
  });

  testWidgets('Add Component without Bike', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Components')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last, matching: find.text('Components')),
        findsOneWidget);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last,
            matching: find.text('Add Component')),
        findsNothing);

    await tester.runAsync(() async {
      await appRepository
          .addBike(Bike(name: "TestBike #1", person: null, isDeleted: true));
    });
    await _waitForRepositoryUpdate(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last,
            matching: find.text('Add Component')),
        findsNothing);

    await tester.runAsync(() async {
      await appRepository.addBike(Bike(name: "TestBike #2", person: null));
    });
    await _waitForRepositoryUpdate(tester);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last,
            matching: find.text('Add Component')),
        findsOneWidget);
  });

  testWidgets('Add Setup without Bike and Components', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Setups'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Setup History'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    final bike1 = Bike(name: "TestBike #1", person: null, isDeleted: true);
    await tester.runAsync(() async {
      await appRepository.addBike(bike1);
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    await tester.runAsync(() async {
      await appRepository.addComponent(
        Component(
          name: "TestComponent #1",
          installations: [Installation.sinceBeginning(parent: bike1.id)],
          componentType: ComponentType.other,
          adjustments: [],
          isDeleted: true,
        ),
      );
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    final bike2 = Bike(name: "TestBike #2", person: null, isDeleted: false);
    await tester.runAsync(() async {
      await appRepository.addBike(bike2);
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    await tester.runAsync(() async {
      await appRepository.addComponent(
        Component(
          name: "TestComponent #2",
          installations: [Installation.sinceBeginning(parent: bike2.id)],
          componentType: ComponentType.other,
          adjustments: [],
          isDeleted: false,
        ),
      );
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('BikeList: Add/Remove/Restore Bike and not show deleted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Bikes'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Bikes'),
      ),
      findsOneWidget,
    );

    // Add Bike and show Bike
    await tester.runAsync(() async {
      await appRepository
          .addBike(Bike(name: "TestBike #1", person: null, isDeleted: false));
    });
    await _waitForRepositoryUpdate(tester);
    expect(find.text("TestBike #1"), findsAtLeast(1));

    // Not show deleted Bike
    final bike2 = Bike(name: "TestBike #2", person: null, isDeleted: true);
    await tester.runAsync(() async {
      await appRepository.addBike(bike2);
    });
    await _waitForRepositoryUpdate(tester);
    expect(find.text("TestBike #2"), findsNothing);

    // Remove Bike
    final bike3 = Bike(name: "TestBike #3", person: null, isDeleted: false);
    await tester.runAsync(() async {
      await appRepository.addBike(bike3);
    });
    await _waitForRepositoryUpdate(tester);
    expect(find.text("TestBike #3"), findsAtLeast(1));
    await tester.runAsync(() async {
      await appRepository.removeBike(bike3);
    });
    await _waitForRepositoryUpdate(tester);
    expect(find.text("TestBike #3"), findsNothing);

    // Restore Bike
    await tester.runAsync(() async {
      await appRepository.restoreBike(bike2);
    });
    await _waitForRepositoryUpdate(tester);
    expect(find.text("TestBike #2"), findsAtLeast(1));
  });

  testWidgets('ComponentList/Edit Adjustment with saving Component', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    final bike1 = Bike(name: "Bike #1", person: null);
    final booleanAdjustment1 = BooleanAdjustment(
      name: "BooleanAdjustment #1",
      notes: null,
      unit: null,
      category: AdjustmentCategory.component,
    );
    final component1 = Component(
      name: "Component #1",
      installations: [Installation.sinceBeginning(parent: bike1.id)],
      componentType: ComponentType.fork,
      adjustments: [booleanAdjustment1],
    );

    await tester.runAsync(() async {
      await appRepository.addBike(bike1);
      await appRepository.addComponent(component1);
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Components'),
      ),
    );
    await tester.pumpAndSettle();

    final popupFinder = find.descendant(
        of: find.byType(ComponentListCard),
        matching: find.bySubtype<PopupMenuButton<dynamic>>(),
    );
    
    await tester.tap(popupFinder.first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final menuFinder = find.byType(PopupMenuItem);
    if (menuFinder.evaluate().isEmpty) {
       // Fallback: try by icon
       await tester.tap(find.byIcon(Icons.edit).last);
    } else {
       await tester.tap(menuFinder.last);
    }
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    
    
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit Component'),
      ),
      findsOneWidget,
    );

    final Finder adjRow = find.ancestor(
      of: find.textContaining('BooleanAdjustment #1'),
      matching: find.byType(AdjustmentListCard),
    );
    expect(adjRow, findsOneWidget);
    
    await tester.ensureVisible(adjRow);
    await tester.tap(
      find.descendant(
        of: adjRow,
        matching: find.bySubtype<PopupMenuButton<dynamic>>(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text("Edit").last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit On/Off Adjustment'),
      ),
      findsOneWidget,
    );
    final Finder nameField = find.byType(TextFormField).first;
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'BooleanAdjustment #1 edit #1');

    final updateCompleter = Completer<void>();
    void listener() {
      if (!updateCompleter.isCompleted) {
        // debugPrint('TEST: Repository notified listeners');
        updateCompleter.complete();
      }
    }
    appRepository.addListener(listener);

    await tester.tap(find.byIcon(Icons.check)); // Save Adjustment
    await tester.pumpAndSettle();

    // The second check is to save the Component (which saves everything)
    // debugPrint('TEST: Tapping final Save on ComponentPage');
    await tester.tap(find.byIcon(Icons.check)); // Save Component
    await tester.pump(); // Start the pop and the callback
    
    // Wait for the async repository update
    // debugPrint('TEST: Waiting for repository update...');
    await _waitForRepositoryUpdate(tester);
    
    if (find.textContaining('BooleanAdjustment #1 edit #1').evaluate().isEmpty) {
       debugPrint('FAIL: Widget tree dump:');
       debugDumpApp();
    }

    expect(find.textContaining('BooleanAdjustment #1 edit #1'), findsOneWidget);
  });

  testWidgets('ComponentList/Edit Adjustment without saving Component', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    final bike1 = Bike(name: "Bike #1", person: null);
    final booleanAdjustment1 = BooleanAdjustment(
      name: "BooleanAdjustment #1",
      notes: null,
      unit: null,
      category: AdjustmentCategory.component,
    );
    final component1 = Component(
      name: "Component #1",
      installations: [Installation.sinceBeginning(parent: bike1.id)],
      componentType: ComponentType.fork,
      adjustments: [booleanAdjustment1],
    );

    await tester.runAsync(() async {
      await appRepository.addBike(bike1);
      await appRepository.addComponent(component1);
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Components'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    
    await tester.tap(
      find.descendant(
        of: find.byType(ComponentListCard).first,
        matching: find.bySubtype<PopupMenuButton<dynamic>>(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    
    final editMenuFinder = find.byType(PopupMenuItem);
    if (editMenuFinder.evaluate().isEmpty) {
      await tester.tap(find.text("Edit").last);
    } else {
      await tester.tap(editMenuFinder.last);
    }
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit Component'),
      ),
      findsOneWidget,
    );

    final adjMenu = find.descendant(
      of: find.byType(AdjustmentListCard),
      matching: find.bySubtype<PopupMenuButton<dynamic>>(),
    );
    await tester.ensureVisible(adjMenu);
    await tester.tap(adjMenu);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text("Edit").last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit On/Off Adjustment'),
      ),
      findsOneWidget,
    );
    final Finder nameField = find.byType(TextFormField).first;
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'BooleanAdjustment #1 edit #1');

    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.check));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Discard Changes"));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.textContaining('BooleanAdjustment #1'), findsOneWidget);
    expect(find.textContaining('BooleanAdjustment #1 edit #1'), findsNothing);
  });

  testWidgets('Home Page with enableGarage=True', (WidgetTester tester) async {
    appSettings.enableGarage = true;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title is "Bikes"
    final AppBar appBar = tester.widget(find.byType(AppBar).last);
    final Text titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    // Verify NavigationBar has "Bikes" and "Setups" but NOT "Components"
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bikes'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Setups'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Components'),
      ),
      findsNothing,
    );

    // Verify GarageList is shown (body of the first page)
    expect(find.byType(GarageList), findsOneWidget);
  });

  testWidgets('HomePage -> Settings -> Help -> Show Onboarding shows onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    // Sanity check: we start on the HomePage, not onboarding.
    expect(find.byType(OnboardingPage), findsNothing);

    // Open the AppBar overflow menu and tap "Settings".
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Settings'),
      ),
      findsOneWidget,
    );

    // Settings -> Help & Support.
    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Help & Support'),
      ),
      findsOneWidget,
    );

    // Help -> Show Onboarding. This pops Help + Settings and flips the flag,
    // which rebuilds the app's home to the OnboardingPage.
    await tester.tap(find.text('Show Onboarding'));
    await tester.pumpAndSettle();

    expect(appSettings.showOnboarding, isTrue);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text('Ready to Dial It In?'), findsOneWidget);
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
