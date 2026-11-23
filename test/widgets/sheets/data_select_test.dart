import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/data_select_bike.dart';
import 'package:bike_setup_tracker/widgets/items/data_select_feedback.dart';
import 'package:bike_setup_tracker/widgets/items/data_select_person.dart';
import 'package:bike_setup_tracker/widgets/items/data_select_setup.dart';
import 'package:bike_setup_tracker/widgets/sheets/data_select.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../goldens/support/localized_test_app.dart';

const _bikeId = 'bike';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 40 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

/// The export, share and import sheets all pick their data here, so feedback
/// and test sessions must survive both the "Entire dataset" and
/// the manual path into an export file and back.
void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  final local = DateTime(2026, 5, 1, 10);
  final setup = Setup(
    id: 's1',
    name: 'S1',
    datetime: local.toUtc(),
    datetimeLocal: local,
    tags: const {},
    bike: _bikeId,
    person: null,
    bikeAdjustmentValues: const {},
    personAdjustmentValues: const {},
  );
  final feedback = RideFeedback(
    id: 'f1',
    bike: _bikeId,
    setupId: 's1',
    dateTimeUTC: local.add(const Duration(hours: 2)).toUtc(),
    dateTimeLocal: local.add(const Duration(hours: 2)),
  );
  final session = TestSession(
    id: 'ts1',
    bike: _bikeId,
    adjustmentIds: const [],
    startedAtUTC: local.toUtc(),
    startedAtLocal: local,
  );

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()
        ..showOnboarding = false
        ..enableRating = true;
      await appRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
      await appRepository.addSetups([setup]);
      await appRepository.addFeedbacks([feedback]);
      await appRepository.addTestSessions([session]);
      await waitFor(() => appRepository.feedbacks.isNotEmpty && appRepository.testSessions.isNotEmpty);
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
  }

  /// Opens the sheet and returns a getter for what it popped with.
  Future<SelectedData? Function()> openSheet(WidgetTester tester) async {
    SelectedData? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: localizedTestApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await showDataSelectSheet(context: context, data: appRepository),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return () => result;
  }

  /// Exports [selection] from the seeded DB and imports the file into a fresh one.
  Future<SelectedData> exportThenImport(WidgetTester tester, SelectedData selection) async {
    late SelectedData imported;
    await tester.runAsync(() async {
      final json = await DataExportService.backupDatabaseToJson(database, subset: selection);
      final target = AppDatabase.memory();
      try {
        await DatabaseMigrationService(target).migrateFromSelectedData(SelectedData.fromJson(json));
        imported = SelectedData.fromJson(await DataExportService.backupDatabaseToJson(target));
      } finally {
        await target.close();
      }
    });
    return imported;
  }

  testWidgets('the entire dataset carries feedback and test sessions', (tester) async {
    await seed(tester);
    final result = await openSheet(tester);

    await tester.tap(find.text('Entire dataset'));
    await settle(tester);

    final imported = await exportThenImport(tester, result()!);
    expect(imported.feedbacks.keys, ['f1']);
    expect(imported.testSessions.keys, ['ts1']);
  });

  testWidgets('a manual selection keeps exactly the chosen new kinds', (tester) async {
    await seed(tester);
    final result = await openSheet(tester);

    await tester.tap(find.text('Choose specific items'));
    await settle(tester);
    expect(find.text('Feedback (0 / 1)'), findsOneWidget);
    expect(find.text('Test Sessions (0 / 1)'), findsOneWidget);

    final feedbackGroup = find.ancestor(
      of: find.text('Feedback (0 / 1)'),
      matching: find.byType(ExpansionTile),
    );
    await tester.tap(find.descendant(of: feedbackGroup, matching: find.byType(Checkbox)).first);
    await settle(tester);
    expect(find.text('Feedback (1 / 1)'), findsOneWidget);
    expect(find.text('Test Sessions (0 / 1)'), findsOneWidget);

    await tester.tap(find.textContaining('Confirm Selection'));
    await settle(tester);

    final imported = await exportThenImport(tester, result()!);
    expect(imported.feedbacks.keys, ['f1']);
    expect(imported.testSessions, isEmpty);
  });

  group('choosing items', () {
    final rider = Person(id: 'p1', name: 'Rider');
    final enduro = Bike(id: 'b1', name: 'Enduro', person: 'p1');
    final trail = Bike(id: 'b2', name: 'Trail', person: null);
    Setup setupOn(String id, String bike) => Setup(
      id: id,
      name: 'Setup $id',
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: bike,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );
    final allData = SelectedData(
      persons: {rider.id: rider},
      bikes: {enduro.id: enduro, trail.id: trail},
      setups: {
        's1': setupOn('s1', 'b1'),
        's2': setupOn('s2', 'b2'),
        // Its bike isn't in the dataset, so ticking it can't add the bike.
        's3': setupOn('s3', 'ghost'),
      },
      feedbacks: {
        'f1': RideFeedback(
          id: 'f1',
          bike: 'b1',
          setupId: 's1',
          dateTimeUTC: local.toUtc(),
          dateTimeLocal: local,
        ),
      },
    );

    late SelectedData? confirmed;

    Future<void> pumpSheet(WidgetTester tester) async {
      confirmed = null;
      appSettings = AppSettings()
        ..showOnboarding = false
        ..enableRating = true;
      addTearDown(appSettings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appSettings,
          child: localizedTestApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: SelectDataItemsSheetContent(
                allData: allData,
                onConfirm: (data) => confirmed = data,
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await settle(tester);
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await settle(tester);
    }

    Future<void> expand(WidgetTester tester, String group) => tapVisible(tester, find.textContaining('$group ('));

    Finder row<T extends Widget>(bool Function(T row) matches) =>
        find.byWidgetPredicate((widget) => widget is T && matches(widget));
    Finder bikeRow(String id) => row<DataSelectBike>((r) => r.bike.id == id);
    Finder setupRow(String id) => row<DataSelectSetup>((r) => r.setup.id == id);
    Finder riderRow(String id) => row<DataSelectPerson>((r) => r.item.id == id);
    Finder feedbackRow(String id) => row<DataSelectFeedback>((r) => r.item.id == id);

    Future<void> toggle(WidgetTester tester, Finder row) =>
        tapVisible(tester, find.descendant(of: row, matching: find.byType(Checkbox)));

    Future<void> toggleGroup(WidgetTester tester, String group) => tapVisible(
      tester,
      find.descendant(
        of: find.ancestor(of: find.textContaining('$group ('), matching: find.byType(ExpansionTile)),
        matching: find.byType(Checkbox),
      ).first,
    );

    bool isTicked(WidgetTester tester, Finder row) =>
        tester.widget<CheckboxListTile>(find.descendant(of: row, matching: find.byType(CheckboxListTile))).value!;

    FilledButton confirmButton(WidgetTester tester) => tester.widget<FilledButton>(find.byType(FilledButton));

    testWidgets('opens with nothing selected and Continue disabled', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Bikes (0 / 2)'), findsOneWidget);
      expect(find.text('Setups (0 / 3)'), findsOneWidget);
      expect(find.text('Select at least one item'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);

      await expand(tester, 'Bikes');
      await toggle(tester, bikeRow('b2'));

      expect(find.text('Select at least one item'), findsNothing);
      expect(confirmButton(tester).onPressed, isNotNull);
      expect(find.text('Confirm Selection (1 / 7)'), findsOneWidget);
    });

    testWidgets('ticking a setup ticks its bike and the bike\'s rider', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Setups');
      await toggle(tester, setupRow('s1'));

      expect(find.text('Bikes (1 / 2)'), findsOneWidget);
      expect(find.text('Riders (1 / 1)'), findsOneWidget);
      await expand(tester, 'Bikes');
      expect(isTicked(tester, bikeRow('b1')), isTrue);
      expect(isTicked(tester, bikeRow('b2')), isFalse);
    });

    testWidgets('ticking a feedback ticks setup, bike and rider transitively', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Feedback');
      await toggle(tester, feedbackRow('f1'));

      expect(find.text('Setups (1 / 3)'), findsOneWidget);
      expect(find.text('Bikes (1 / 2)'), findsOneWidget);
      expect(find.text('Riders (1 / 1)'), findsOneWidget);
      await expand(tester, 'Setups');
      expect(isTicked(tester, setupRow('s1')), isTrue);
    });

    testWidgets('unticking a bike leaves its setups ticked', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Setups');
      await toggle(tester, setupRow('s1'));
      await expand(tester, 'Bikes');
      await toggle(tester, bikeRow('b1'));

      expect(isTicked(tester, bikeRow('b1')), isFalse);
      expect(isTicked(tester, setupRow('s1')), isTrue);
      expect(find.text('Riders (1 / 1)'), findsOneWidget);
    });

    testWidgets('unticking a group removes only that group', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Riders');
      await toggle(tester, riderRow('p1'));
      await toggleGroup(tester, 'Setups');
      expect(find.text('Setups (3 / 3)'), findsOneWidget);

      await toggleGroup(tester, 'Setups');

      expect(find.text('Setups (0 / 3)'), findsOneWidget);
      expect(find.text('Bikes (2 / 2)'), findsOneWidget);
      expect(find.text('Riders (1 / 1)'), findsOneWidget);
    });

    testWidgets('a group tick adds the whole group plus its dependencies', (tester) async {
      await pumpSheet(tester);
      await toggleGroup(tester, 'Setups');

      expect(find.text('Setups (3 / 3)'), findsOneWidget);
      expect(find.text('Bikes (2 / 2)'), findsOneWidget);
      expect(find.text('Riders (1 / 1)'), findsOneWidget);
      expect(find.text('Feedback (0 / 1)'), findsOneWidget);
    });

    testWidgets('a reference to an item outside the dataset adds nothing', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Setups');
      await toggle(tester, setupRow('s3'));

      expect(find.text('Confirm Selection (1 / 7)'), findsOneWidget);
    });

    testWidgets('confirms exactly the selection, in the original order', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Setups');
      await toggle(tester, setupRow('s3'));
      await toggle(tester, setupRow('s1'));
      await tapVisible(tester, find.byType(FilledButton));

      expect(confirmed!.setups.keys, ['s1', 's3']);
      expect(confirmed!.bikes.keys, ['b1']);
      expect(confirmed!.persons.keys, ['p1']);
      expect(confirmed!.feedbacks, isEmpty);
      expect(confirmed!.components, isEmpty);
    });

    testWidgets('an automatically ticked row flashes, the ticked row does not', (tester) async {
      await pumpSheet(tester);
      await expand(tester, 'Bikes');
      await expand(tester, 'Setups');
      Color? cardColor(Finder row) =>
          tester.widget<Material>(find.descendant(of: row, matching: find.byType(Material)).first).color;
      final rest = cardColor(bikeRow('b1'));

      await tester.ensureVisible(setupRow('s1'));
      await tester.pump();
      await tester.tap(find.descendant(of: setupRow('s1'), matching: find.byType(Checkbox)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(cardColor(bikeRow('b1')), isNot(rest));
      expect(cardColor(bikeRow('b2')), rest);
      expect(cardColor(setupRow('s1')), rest);

      await tester.pump(const Duration(seconds: 1));
      expect(cardColor(bikeRow('b1')), rest);
    });
  });
}
