import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/pages/forms/person_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/person_list_card.dart';
import 'package:bike_setup_tracker/widgets/rider_name_form.dart';
import 'package:bike_setup_tracker/widgets/sheets/rider_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  const hint = 'Riding weight and other rider values are recorded with each setup.';

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

  Future<void> openSheet(WidgetTester tester, {List<Person> persons = const []}) async {
    if (persons.isNotEmpty) await tester.runAsync(() => repository.addPersons(persons));
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
    expect(find.text(hint), findsOneWidget);
  });

  testWidgets('one rider shows the card and the hint; tap opens edit', (tester) async {
    await openSheet(tester, persons: [Person(name: 'Jonas')]);

    expect(find.byType(PersonListCard), findsOneWidget);
    expect(find.text(hint), findsOneWidget);
    expect(find.byType(RiderNameForm), findsNothing);

    await tester.tap(find.text('Jonas'));
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
}
