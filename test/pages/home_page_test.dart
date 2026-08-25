import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/pages/onboarding_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/backup_service.dart';
import 'package:bike_setup_tracker/services/google_drive_service.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/widgets/items/adjustment_list_card.dart';
import 'package:bike_setup_tracker/widgets/items/component_list_card.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_icon_card.dart';
import 'package:bike_setup_tracker/widgets/lists/garage_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late AppHintService appHintService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings()..showOnboarding = false;
    appHintService = AppHintService(
      appRepository: appRepository,
      appSettings: appSettings,
    );
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    appHintService.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        ChangeNotifierProvider<AppRepository>.value(value: appRepository),
        ChangeNotifierProvider<AppHintService>.value(value: appHintService),
        Provider<AppDatabase>.value(value: database),
        Provider<BackupService>(create: (_) => BackupService()),
        ChangeNotifierProvider<StravaService>(
          create: (_) => StravaService(appRepository, appSettings),
        ),
        ChangeNotifierProvider<GoogleDriveService>(
          create: (_) => GoogleDriveService(appRepository, database),
        ),
        ChangeNotifierProvider<SubscriptionService>(
          create: (_) => SubscriptionService(),
        ),
      ],
      child: const BikeSetupTrackerApp(),
    );
  }

  testWidgets('uses the Garage as the Bikes tab', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(_appBarTitle(tester), 'Bikes');
    expect(find.byType(GarageList), findsOneWidget);
    expect(_navigationDestination('Bikes'), findsOneWidget);
    expect(_navigationDestination('Setups'), findsOneWidget);
    expect(_navigationDestination('Components'), findsNothing);

    await tester.tap(_navigationDestination('Setups'));
    await tester.pumpAndSettle();
    expect(_appBarTitle(tester), 'Setup History');
  });

  testWidgets('opens Setup History by default when bikes and components exist', (tester) async {
    final bike = Bike(name: 'Test bike', person: null);
    await tester.runAsync(() async {
      await appRepository.addBike(bike);
      await appRepository.addComponent(
        Component(
          name: 'Test component',
          componentType: ComponentType.frame,
          adjustments: const [],
          installations: [Installation.sinceBeginning(parent: bike.id)],
        ),
      );
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await _waitForRepositoryUpdate(
      tester,
      until: (repository) =>
          repository.bikes.containsKey(bike.id) &&
          repository.components.values.any(
            (component) => component.installations.any(
              (installation) => installation.parent == bike.id,
            ),
          ),
    );

    expect(_appBarTitle(tester), 'Setup History');
  });

  testWidgets('Garage shows active bikes and hides deleted bikes', (tester) async {
    final activeBike = Bike(name: 'Active bike', person: null);
    final deletedBike = Bike(name: 'Deleted bike', person: null, isDeleted: true);
    await tester.runAsync(() async {
      await appRepository.addBike(activeBike);
      await appRepository.addBike(deletedBike);
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await _waitForRepositoryUpdate(
      tester,
      until: (repository) => repository.bikes.containsKey(activeBike.id),
    );

    expect(find.text('Active bike'), findsAtLeast(1));
    expect(find.text('Deleted bike'), findsNothing);
  });

  testWidgets('edits and saves an adjustment through the Garage', (tester) async {
    await _seedGarageComponent(tester, appRepository);
    await tester.pumpWidget(createWidgetUnderTest());
    await _waitForRepositoryUpdate(
      tester,
      until: (repository) => repository.components.values.any(
        (component) => component.name == 'Test component',
      ),
    );
    await _openComponentEditor(tester);

    final adjustmentRow = find.ancestor(
      of: find.text('Boolean adjustment'),
      matching: find.byType(AdjustmentListCard),
    );
    await tester.tap(
      find.descendant(
        of: adjustmentRow,
        matching: find.bySubtype<PopupMenuButton<dynamic>>(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Saved adjustment');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Saved adjustment'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.check),
      ),
    );
    await tester.pumpAndSettle();
    await _waitForRepositoryUpdate(
      tester,
      until: (repository) => repository.components.values.any(
        (component) => component.adjustments.any(
          (adjustment) => adjustment.name == 'Saved adjustment',
        ),
      ),
    );

    expect(_appBarTitle(tester), 'Bikes');
    expect(find.text('Saved adjustment'), findsOneWidget);
  });

  testWidgets('discards an adjustment edit opened through the Garage', (tester) async {
    await _seedGarageComponent(tester, appRepository);
    await tester.pumpWidget(createWidgetUnderTest());
    await _waitForRepositoryUpdate(
      tester,
      until: (repository) => repository.components.values.any(
        (component) => component.name == 'Test component',
      ),
    );
    await _openComponentEditor(tester);

    final adjustmentMenu = find.descendant(
      of: find.byType(AdjustmentListCard),
      matching: find.bySubtype<PopupMenuButton<dynamic>>(),
    );
    await tester.tap(adjustmentMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Discarded adjustment');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Boolean adjustment'), findsOneWidget);
    expect(find.text('Discarded adjustment'), findsNothing);
  });

  testWidgets('can add a setup only after an active bike has a component', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(_navigationDestination('Setups'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Add Setup'), findsNothing);

    final bike = Bike(name: 'Test bike', person: null);
    await tester.runAsync(() async {
      await appRepository.addBike(bike);
      await appRepository.addComponent(
        Component(
          name: 'Test component',
          componentType: ComponentType.other,
          adjustments: const [],
          installations: [Installation.sinceBeginning(parent: bike.id)],
        ),
      );
    });
    await _waitForRepositoryUpdate(
      tester,
      until: (repository) =>
          repository.bikes.containsKey(bike.id) &&
          repository.components.values.any(
            (component) => component.installations.any(
              (installation) => installation.parent == bike.id,
            ),
          ),
    );

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Add Setup'), findsOneWidget);
  });

  testWidgets('Settings help can re-enable onboarding', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Onboarding'));
    await tester.pumpAndSettle();

    expect(appSettings.showOnboarding, isTrue);
    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}

Finder _navigationDestination(String label) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(label),
);

String? _appBarTitle(WidgetTester tester) => (tester.widget<AppBar>(find.byType(AppBar).last).title as Text).data;

Future<void> _seedGarageComponent(
  WidgetTester tester,
  AppRepository appRepository,
) async {
  await tester.runAsync(() async {
    final bike = Bike(name: 'Test bike', person: null);
    await appRepository.addBike(bike);
    await appRepository.addComponent(
      Component(
        name: 'Test component',
        componentType: ComponentType.fork,
        adjustments: [
          BooleanAdjustment(name: 'Boolean adjustment', notes: null, unit: null),
        ],
        installations: [Installation.sinceBeginning(parent: bike.id)],
      ),
    );
  });
}

Future<void> _openComponentEditor(WidgetTester tester) async {
  await tester.tap(_navigationDestination('Bikes'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(GarageComponentIconCard).first);
  await tester.pump(const Duration(milliseconds: 500));

  final componentMenu = find.descendant(
    of: find.byType(ComponentListCard),
    matching: find.bySubtype<PopupMenuButton<dynamic>>(),
  );
  await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -200));
  await tester.pumpAndSettle();
  tester.state<PopupMenuButtonState<dynamic>>(componentMenu).showButtonMenu();
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit').last);
  await tester.pumpAndSettle();

  expect(_appBarTitle(tester), 'Edit Component');
}

Future<void> _waitForRepositoryUpdate(
  WidgetTester tester, {
  bool Function(AppRepository repository)? until,
}) async {
  final repository = tester.element(find.byType(MaterialApp)).read<AppRepository>();
  if (until != null) {
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 1000; attempt++) {
        if (until(repository)) return;
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      throw StateError('Repository did not reach the expected state');
    });
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}
