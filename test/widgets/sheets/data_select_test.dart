import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/data_select.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        child: MaterialApp(
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
    expect(find.text('Feedback (1 / 1)'), findsOneWidget);
    expect(find.text('Test Sessions (1 / 1)'), findsOneWidget);

    final sessionsGroup = find.ancestor(
      of: find.text('Test Sessions (1 / 1)'),
      matching: find.byType(ExpansionTile),
    );
    await tester.tap(find.descendant(of: sessionsGroup, matching: find.byType(Checkbox)).first);
    await settle(tester);
    expect(find.text('Test Sessions (0 / 1)'), findsOneWidget);

    await tester.tap(find.textContaining('Confirm Selection'));
    await settle(tester);

    final imported = await exportThenImport(tester, result()!);
    expect(imported.feedbacks.keys, ['f1']);
    expect(imported.testSessions, isEmpty);
  });
}
