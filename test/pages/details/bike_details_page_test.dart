import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/details/bike_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/setup_activity_analysis_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late SetupActivityAnalysisService setupActivityAnalysisService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    setupActivityAnalysisService = SetupActivityAnalysisService(database);
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    setupActivityAnalysisService.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest(String bikeId) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider.value(value: setupActivityAnalysisService),
        ChangeNotifierProvider<SubscriptionService>.value(value: MockSubscriptionService()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: BikeDetailsPage(bikeId: bikeId),
      ),
    );
  }

  Setup setup(String id, String name, String bike) => Setup(
    id: id,
    name: name,
    datetime: DateTime(2024).toUtc(),
    datetimeLocal: DateTime(2024),
    tags: {},
    bike: bike,
    person: null,
    bikeAdjustmentValues: {},
    personAdjustmentValues: {},
  );

  /// Seeds the database, then rebuilds the repository so it loads the rows into
  /// its caches, and pumps the page once the bike has arrived.
  Future<void> pumpPageWith(WidgetTester tester, Future<void> Function() writes) async {
    await tester.runAsync(() async {
      await writes();
      await Future<void>.delayed(Duration.zero);
    });

    appRepository.dispose();
    appRepository = AppRepository(database);

    await tester.pumpWidget(createWidgetUnderTest('bike1'));
    await tester.runAsync(() async {
      for (var attempts = 0; appRepository.bikes['bike1'] == null && attempts < 10; attempts++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('lists only the setups of this bike, without a bike column', (WidgetTester tester) async {
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([
        Bike(id: 'bike1', name: 'Test Bike', person: null),
        Bike(id: 'bike2', name: 'Other Bike', person: null),
      ]);
      await appRepository.addSetups([
        setup('s1', 'Alpha Setup', 'bike1'),
        setup('s2', 'Beta Setup', 'bike2'),
      ]);
    });

    expect(find.text('SETUP HISTORY'), findsOneWidget);
    expect(find.byType(SetupTable), findsOneWidget);
    expect(find.text('Alpha Setup'), findsOneWidget);
    expect(find.text('Beta Setup'), findsNothing);

    // Rows are not selectable here: there are no charts to compare setups in.
    expect(find.descendant(of: find.byType(SetupTable), matching: find.byType(Checkbox)), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Columns'));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Wrap), matching: find.text('Bike')), findsNothing);
    expect(find.text('Component Adjustments'), findsNothing);
    expect(find.descendant(of: find.byType(Wrap), matching: find.text('Temperature')), findsOneWidget);
  });

  testWidgets('keeps the setups of this bike when another bike is selected', (WidgetTester tester) async {
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([
        Bike(id: 'bike1', name: 'Test Bike', person: null),
        Bike(id: 'bike2', name: 'Other Bike', person: null),
      ]);
      await appRepository.addSetups([setup('s1', 'Alpha Setup', 'bike1')]);
    });

    appRepository.onBikeTap('bike2');
    await tester.pumpAndSettle();

    expect(find.text('Alpha Setup'), findsOneWidget);
  });

  testWidgets('shows a placeholder when no setup references the bike', (WidgetTester tester) async {
    await pumpPageWith(tester, () async {
      await appRepository.addBikes([Bike(id: 'bike1', name: 'Test Bike', person: null)]);
      await appRepository.addSetups([setup('s2', 'Beta Setup', 'bike2')]);
    });

    expect(find.byType(SetupTable), findsNothing);
    expect(find.text('No setups reference this bike'), findsOneWidget);
  });
}
