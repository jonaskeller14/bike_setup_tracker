import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/rider_name_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repository,
        child: MaterialApp(
          theme: materialAppTheme,
          home: const Scaffold(body: SingleChildScrollView(child: RiderNameForm())),
        ),
      ),
    );
  }

  /// The write runs through drift's sqlite3 bindings, which only progress in
  /// real time, and the repository picks it up from a watch stream after that.
  Future<void> settleWrite(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
  }

  testWidgets('an empty name shows the validation error and creates nothing', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Create rider'));
    await settleWrite(tester);

    expect(find.text('Enter a name to continue.'), findsOneWidget);
    expect(repository.persons, isEmpty);
  });

  testWidgets('a valid name creates one rider with Riding weight', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(RiderNameField), '  Jonas  ');
    await tester.tap(find.text('Create rider'));
    await settleWrite(tester);

    final person = repository.persons.values.single;
    expect(person.name, 'Jonas');
    final adjustment = person.adjustments.single;
    expect(adjustment, isA<NumericalAdjustment>());
    expect(adjustment.name, 'Riding weight');
    expect(adjustment.presetKey, 'person:riding_weight');
    expect(find.text("Rider 'Jonas' created."), findsOneWidget);
  });

  testWidgets('a double tap still creates only one rider', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(RiderNameField), 'Jonas');
    await tester.tap(find.text('Create rider'));
    await tester.tap(find.text('Create rider'), warnIfMissed: false);
    await settleWrite(tester);

    expect(repository.persons, hasLength(1));
  });

  testWidgets('submitting from the keyboard creates the rider', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(RiderNameField), 'Jonas');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleWrite(tester);

    expect(repository.persons.values.single.name, 'Jonas');
  });
}
