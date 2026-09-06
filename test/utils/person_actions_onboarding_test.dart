import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/person_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
  });

  tearDown(() async {
    appRepository.dispose();
    await database.close();
  });

  /// Runs [PersonActions.createOnboardingRider] with a real provider scope, the
  /// way the rider slide calls it.
  ///
  /// The write goes through drift's real sqlite3 FFI bindings, which never
  /// resolve on the fake timer queue a plain `testWidgets` body runs on — the
  /// call has to happen inside [WidgetTester.runAsync]. That also means the
  /// repository's watch-stream notification it triggers fires on a real
  /// timer, not the fake one `pump(duration)` controls, so it needs a beat
  /// of real time (inside another `runAsync`) before `appRepository.persons`
  /// reflects the write.
  Future<Person?> createRider(WidgetTester tester, String name) async {
    late BuildContext context;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: appRepository,
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final created = await tester.runAsync(
      () => PersonActions.createOnboardingRider(context, name: name),
    );
    // The write ran inside runAsync, so any internal debounce/notification
    // timer it scheduled is a real one, not the fake one testWidgets
    // controls — pump()'s fake-clock elapse can't advance it. Give it a
    // moment of real time to fire before checking appRepository.persons.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    return created;
  }

  testWidgets('creates a rider carrying only a Riding weight definition', (WidgetTester tester) async {
    final person = await createRider(tester, 'Jonas');

    expect(person, isNotNull);
    expect(appRepository.persons.containsKey(person!.id), isTrue);

    final stored = appRepository.persons[person.id]!;
    expect(stored.name, 'Jonas');
    expect(stored.adjustments, hasLength(1));

    final adjustment = stored.adjustments.single;
    expect(adjustment, isA<NumericalAdjustment>());
    expect(adjustment.name, 'Riding weight');

    // A definition only — onboarding never collects a value for it.
    final values = await database.select(database.setupAdjustmentValues).get();
    expect(values, isEmpty);
  });

  testWidgets('trims the entered name', (WidgetTester tester) async {
    final person = await createRider(tester, '  Jonas  ');

    expect(person?.name, 'Jonas');
  });

  testWidgets('a blank name creates nothing', (WidgetTester tester) async {
    final person = await createRider(tester, '   ');

    expect(person, isNull);
    expect(appRepository.persons, isEmpty);
  });
}
