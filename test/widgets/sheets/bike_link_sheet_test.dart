import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/person_actions.dart';
import 'package:bike_setup_tracker/widgets/sheets/bike_link_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late AppDatabase database;
  late AppRepository repository;

  final rider = Person(id: 'jonas', name: 'Jonas', orderIndex: 0);

  setUp(() async {
    database = AppDatabase.memory();
    repository = AppRepository(database);
    await repository.initialDataLoaded;
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await repository.disposeAndAwaitCancellation();
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

  Future<void> openSheet(WidgetTester tester, {List<Person>? persons, List<Bike> bikes = const []}) async {
    await tester.runAsync(() async {
      await repository.addPersons(persons ?? [rider]);
      if (bikes.isNotEmpty) await repository.addBikes(bikes);
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => PersonActions.editBikeLinks(context, person: rider),
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

  Finder row(String bikeName) => find.widgetWithText(ListTile, bikeName);
  Finder pill(String bikeName, String label) => find.descendant(of: row(bikeName), matching: find.text(label));
  Finder saveButton(String label) => find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>());
  bool isEnabled(WidgetTester tester, String label) => tester.widget<ButtonStyleButton>(saveButton(label)).enabled;

  final twoBikes = [
    Bike(id: 'enduro', name: 'Enduro', person: 'jonas', orderIndex: 0),
    Bike(id: 'gravel', name: 'Gravel', person: null, orderIndex: 1),
  ];

  testWidgets('shows the saved links, with Save disabled until something changes', (tester) async {
    await openSheet(tester, bikes: twoBikes);

    expect(pill('Enduro', 'Unlink'), findsOneWidget);
    expect(pill('Gravel', 'Link'), findsOneWidget);
    expect(isEnabled(tester, 'Save'), isFalse);
  });

  testWidgets('the confirm button names the drafted changes', (tester) async {
    await openSheet(
      tester,
      bikes: [
        ...twoBikes,
        Bike(id: 'trail', name: 'Trail', person: null, orderIndex: 2),
      ],
    );

    await tester.tap(pill('Gravel', 'Link'));
    await tester.pumpAndSettle();
    expect(isEnabled(tester, 'Link 1 bike'), isTrue);

    await tester.tap(pill('Trail', 'Link'));
    await tester.pumpAndSettle();
    expect(saveButton('Link 2 bikes'), findsOneWidget);

    await tester.tap(pill('Gravel', 'Unlink'));
    await tester.tap(pill('Trail', 'Unlink'));
    await tester.tap(pill('Enduro', 'Unlink'));
    await tester.pumpAndSettle();
    expect(saveButton('Unlink 1 bike'), findsOneWidget);
  });

  testWidgets('changes are only drafted and written on confirm', (tester) async {
    await openSheet(tester, bikes: twoBikes);

    await tester.tap(pill('Gravel', 'Link'));
    await tester.pumpAndSettle();
    await tester.tap(pill('Enduro', 'Unlink'));
    await tester.pumpAndSettle();

    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    expect(repository.bikes['gravel']!.person, isNull);
    expect(repository.bikes['enduro']!.person, rider.id);

    await tester.tap(saveButton('Link 1 · Unlink 1'));
    await settleWrite(tester);

    expect(find.byType(BikeLinkSheetContent), findsNothing);
    expect(repository.bikes['gravel']!.person, rider.id);
    expect(repository.bikes['enduro']!.person, isNull);
  });

  testWidgets('toggling a row back clears its change', (tester) async {
    await openSheet(tester, bikes: twoBikes);

    await tester.tap(row('Gravel'));
    await tester.pumpAndSettle();
    expect(isEnabled(tester, 'Link 1 bike'), isTrue);

    await tester.tap(row('Gravel'));
    await tester.pumpAndSettle();
    expect(pill('Gravel', 'Link'), findsOneWidget);
    expect(isEnabled(tester, 'Save'), isFalse);
  });

  testWidgets('Cancel discards the draft', (tester) async {
    await openSheet(tester, bikes: twoBikes);

    await tester.tap(pill('Gravel', 'Link'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await settleWrite(tester);

    expect(find.byType(BikeLinkSheetContent), findsNothing);
    expect(repository.bikes['gravel']!.person, isNull);
  });

  testWidgets("another rider's bike is named, and moving it is announced", (tester) async {
    await openSheet(
      tester,
      persons: [
        rider,
        Person(id: 'other', name: 'Other', orderIndex: 1),
      ],
      bikes: [
        Bike(id: 'kids', name: 'Kids', person: 'other', orderIndex: 0),
        Bike(id: 'old', name: 'Old', person: 'deleted', orderIndex: 1),
      ],
    );

    expect(find.descendant(of: row('Kids'), matching: find.text("Ridden by 'Other'")), findsOneWidget);
    // A stale rider id counts as no rider.
    expect(find.descendant(of: row('Old'), matching: find.textContaining('Ridden by')), findsNothing);

    await tester.tap(pill('Kids', 'Link'));
    await tester.pumpAndSettle();
    // The other rider stays named while the move is pending.
    expect(find.descendant(of: row('Kids'), matching: find.text("Ridden by 'Other'")), findsOneWidget);

    await tester.tap(saveButton('Link 1 bike'));
    await settleWrite(tester);
    expect(repository.bikes['kids']!.person, rider.id);
  });

  testWidgets('without bikes an empty hint is shown', (tester) async {
    await openSheet(tester);

    expect(find.text('Add a bike to link it to this rider.'), findsOneWidget);
    expect(isEnabled(tester, 'Save'), isFalse);
  });

  testWidgets('a long bike name is ellipsized on a narrow screen', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final longName = 'Specialized Stumpjumper Evo ' * 5;

    await openSheet(tester, bikes: [Bike(name: longName, person: null)]);
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.renderObject<RenderParagraph>(find.text(longName)).didExceedMaxLines, isTrue);
  });
}
