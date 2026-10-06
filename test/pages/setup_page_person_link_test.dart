import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/rider_name_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
  });

  testWidgets('linking a person to the bike replaces the placeholder with the person attributes', (tester) async {
    final harness = (await tester.runAsync(_PersonLinkHarness.create))!;
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.wrap(SetupPage.add()));
    await _settle(tester);

    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.byIcon(Person.iconData)));
    await _settle(tester);

    expect(find.text('No person linked'), findsOneWidget);

    await tester.tap(find.text('Link Person'));
    await _settle(tester);

    // Only one rider outside the advanced layout: it can be linked, not added.
    expect(find.text('Create new Person'), findsNothing);

    await tester.tap(find.text("Link 'Rider'"));
    await tester.pump();
    // The link is persisted through the database, which only progresses in real time.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await _settle(tester);

    expect(harness.repository.bikes[_PersonLinkHarness.bikeId]!.person, _PersonLinkHarness.personId);
    expect(find.text('No person linked'), findsNothing);
    expect(find.text('Rider'), findsOneWidget);
    expect(find.text('1 attribute'), findsOneWidget);
  });

  testWidgets('without any person the tab creates the rider inline and links it to the bike', (tester) async {
    final harness = (await tester.runAsync(() => _PersonLinkHarness.create(withPerson: false)))!;
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.wrap(SetupPage.add()));
    await _settle(tester);

    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.byIcon(Person.iconData)));
    await _settle(tester);

    expect(find.text('Link Person'), findsNothing);
    expect(find.byType(RiderNameForm), findsOneWidget);

    await tester.enterText(find.byType(RiderNameField), 'Jonas');
    await tester.ensureVisible(find.text('Create rider'));
    await tester.pump();
    await tester.tap(find.text('Create rider'));
    // The rider and then the link are persisted through the database, which
    // only progresses in real time, while each step resumes on the fake clock.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await _settle(tester);

    final person = harness.repository.persons.values.single;
    expect(person.name, 'Jonas');
    expect(harness.repository.bikes[_PersonLinkHarness.bikeId]!.person, person.id);
    expect(find.byType(RiderNameForm), findsNothing);
    expect(find.text('Jonas'), findsOneWidget);
    expect(find.text('1 attribute'), findsOneWidget);
  });

  testWidgets('the advanced layout still offers to create another person', (tester) async {
    final harness = (await tester.runAsync(() => _PersonLinkHarness.create(advanced: true)))!;
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.wrap(SetupPage.add()));
    await _settle(tester);

    await tester.tap(find.descendant(of: find.byType(TabBar), matching: find.byIcon(Person.iconData)));
    await _settle(tester);

    await tester.tap(find.text('Link Person'));
    await _settle(tester);

    expect(find.text("Link 'Rider'"), findsOneWidget);
    expect(find.text('Create new Person'), findsOneWidget);
  });
}

/// [SetupPage.add] fetches the location on open, leaving the location chip
/// spinning for the whole test, so the page never settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class _PersonLinkHarness {
  static const bikeId = 'bike';
  static const personId = 'person';

  final AppDatabase database;
  final AppRepository repository;
  final AppSettings settings;
  final SubscriptionService subscriptionService;

  _PersonLinkHarness({
    required this.database,
    required this.repository,
    required this.settings,
    required this.subscriptionService,
  });

  static Future<_PersonLinkHarness> create({bool withPerson = true, bool advanced = false}) async {
    final database = AppDatabase.memory();
    final seedRepository = AppRepository(database);
    await seedRepository.addBikes([Bike(id: bikeId, name: 'Test Bike', person: null)]);
    if (withPerson) {
      await seedRepository.addPersons([
        Person(
          id: personId,
          name: 'Rider',
          adjustments: [
            TextAdjustment(
              id: 'riding_weight',
              name: 'Riding Weight',
              notes: null,
              unit: AdjustmentUnit.fromLegacy('kg'),
            ),
          ],
        ),
      ]);
    }
    seedRepository.dispose();

    final repository = AppRepository(database);
    await _waitForData(repository, persons: withPerson ? 1 : 0);
    final settings = AppSettings()
      ..showOnboarding = false
      ..enablePerson = true
      ..enablePersonAdvanced = advanced;
    return _PersonLinkHarness(
      database: database,
      repository: repository,
      settings: settings,
      subscriptionService: _MockSubscriptionService(),
    );
  }

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: repository),
        ChangeNotifierProvider.value(value: subscriptionService),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: home,
      ),
    );
  }

  Future<void> dispose() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  }

  static Future<void> _waitForData(AppRepository repository, {required int persons}) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (repository.bikes.length == 1 && repository.persons.length == persons) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('SetupPage person link fixture did not finish loading.');
  }
}
