import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/pages/forms/person_page.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/person_list_card.dart';
import 'package:bike_setup_tracker/widgets/rider_name_form.dart';
import 'package:bike_setup_tracker/widgets/sheets/bike_link_sheet.dart';
import 'package:bike_setup_tracker/widgets/sheets/person_add_adjustment.dart';
import 'package:bike_setup_tracker/widgets/sheets/rider_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;
  late SubscriptionService subscriptionService;

  const recordButton = 'Record rider values';
  const linkBike = 'Link bike';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    await repository.initialDataLoaded;
    settings = AppSettings()
      ..showOnboarding = false
      ..enablePerson = true;
    subscriptionService = _MockSubscriptionService();
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(false);
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
  });

  /// The write runs through drift's sqlite3 bindings, which only progress in
  /// real time, and the repository picks it up from a watch stream after that.
  Future<void> settleWrite(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(
    WidgetTester tester, {
    List<Person> persons = const [],
    List<Bike> bikes = const [],
    List<Component> components = const [],
  }) async {
    await tester.runAsync(() async {
      if (persons.isNotEmpty) await repository.addPersons(persons);
      if (bikes.isNotEmpty) await repository.addBikes(bikes);
      if (components.isNotEmpty) await repository.addComponents(components);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<AppRepository>.value(value: repository),
          ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showRiderSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await settleWrite(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('without a rider the form creates one and the sheet shows its card', (tester) async {
    await openSheet(tester);

    expect(find.byType(RiderNameForm), findsOneWidget);
    expect(find.byType(PersonListCard), findsNothing);

    await tester.enterText(find.byType(RiderNameField), 'Jonas');
    await tester.tap(find.text('Create rider'));
    await settleWrite(tester);

    expect(find.byType(RiderSheetContent), findsOneWidget);
    expect(find.byType(RiderNameForm), findsNothing);
    expect(find.widgetWithText(PersonListCard, 'Jonas'), findsOneWidget);
    expect(find.text(linkBike), findsOneWidget);
  });

  testWidgets('one rider shows the intro and the card; Edit opens edit', (tester) async {
    await openSheet(tester, persons: [Person(name: 'Jonas')]);

    expect(find.textContaining('depend on your weight'), findsOneWidget);
    expect(find.byType(PersonListCard), findsOneWidget);
    expect(find.byType(RiderNameForm), findsNothing);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonPage), findsOneWidget);
  });

  testWidgets('two riders are stacked in order', (tester) async {
    await openSheet(
      tester,
      persons: [
        Person(name: 'First', orderIndex: 0),
        Person(name: 'Second', orderIndex: 1),
      ],
    );

    expect(find.byType(PersonListCard), findsNWidgets(2));
    expect(tester.getTopLeft(find.text('First')).dy, lessThan(tester.getTopLeft(find.text('Second')).dy));
  });

  testWidgets('a long name is ellipsized on a narrow screen', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final longName = 'Maximilian Alexander ' * 5;

    await openSheet(tester, persons: [Person(name: longName)]);

    expect(tester.takeException(), isNull);
    expect(tester.renderObject<RenderParagraph>(find.text(longName)).didExceedMaxLines, isTrue);
  });

  testWidgets('Remove closes the sheet so the undo snackbar is visible', (tester) async {
    await openSheet(tester, persons: [Person(name: 'Jonas')]);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await settleWrite(tester);

    expect(find.byType(RiderSheetContent), findsNothing);
    expect(find.textContaining("'Jonas' moved to trash."), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
    expect(repository.persons, isEmpty);
  });

  group('link bike', () {
    testWidgets('without a linked bike the button opens the link sheet; Save shows the record button', (tester) async {
      final rider = Person(id: 'jonas', name: 'Jonas');
      await openSheet(tester, persons: [rider], bikes: [Bike(id: 'gravel', name: 'Gravel', person: null)]);

      expect(find.text('Link a bike to record rider values with its setups.'), findsOneWidget);
      expect(find.text(recordButton), findsNothing);

      await tester.tap(find.text(linkBike));
      await tester.pumpAndSettle();
      expect(find.byType(BikeLinkSheetContent), findsOneWidget);

      await tester.tap(find.text('Link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Link 1 bike'));
      await settleWrite(tester);

      expect(find.byType(BikeLinkSheetContent), findsNothing);
      expect(find.byType(RiderSheetContent), findsOneWidget);
      expect(repository.bikes['gravel']!.person, rider.id);
      expect(find.text(linkBike), findsNothing);
      expect(find.text(recordButton), findsOneWidget);
      expect(find.descendant(of: find.byType(PersonListCard), matching: find.text('Gravel')), findsOneWidget);
    });

    testWidgets('without bikes the button is disabled', (tester) async {
      await openSheet(tester, persons: [Person(name: 'Jonas')]);

      final button = tester.widget<ButtonStyleButton>(
        find.ancestor(of: find.text(linkBike), matching: find.bySubtype<ButtonStyleButton>()),
      );
      expect(button.enabled, isFalse);
      expect(find.text('Add a bike to link it to this rider.'), findsOneWidget);
    });
  });

  group('record rider values', () {
    Component componentOn(String bikeId) => Component(
      name: 'Fork',
      componentType: ComponentType.fork,
      adjustments: const [],
      installations: [Installation.sinceBeginning(parent: bikeId)],
    );

    bool isEnabled(WidgetTester tester) => tester
        .widget<ButtonStyleButton>(
          find.ancestor(of: find.text(recordButton), matching: find.bySubtype<ButtonStyleButton>()),
        )
        .enabled;

    testWidgets('is disabled while no component exists', (tester) async {
      await openSheet(
        tester,
        persons: [Person(id: 'jonas', name: 'Jonas')],
        bikes: [Bike(name: 'Enduro', person: 'jonas')],
      );

      expect(isEnabled(tester), isFalse);
      expect(find.text('Add a component to record setups.'), findsOneWidget);
    });

    testWidgets('opens Add Setup on the Rider tab with the linked bike', (tester) async {
      const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(pathProviderChannel, (call) async => Directory.systemTemp.path);
      addTearDown(() => messenger.setMockMethodCallHandler(pathProviderChannel, null));

      final rider = Person(id: 'jonas', name: 'Jonas', adjustments: [ridingWeightPreset.deepCopy()]);
      await openSheet(
        tester,
        persons: [rider],
        // The unlinked bike comes first, so the page only starts on Enduro
        // because the button passes it.
        bikes: [
          Bike(id: 'gravel', name: 'Gravel', person: null, orderIndex: 0),
          Bike(id: 'enduro', name: 'Enduro', person: rider.id, orderIndex: 1),
        ],
        components: [componentOn('gravel'), componentOn('enduro')],
      );

      expect(isEnabled(tester), isTrue);
      expect(find.text('Rider values are saved with a new setup.'), findsOneWidget);

      await tester.tap(find.text(recordButton));
      // SetupPage.add fetches the location on open, so it never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SetupPage), findsOneWidget);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
      expect(find.text('No rider linked'), findsNothing);
      expect(find.text('1 attribute'), findsOneWidget);
    });
  });
}
