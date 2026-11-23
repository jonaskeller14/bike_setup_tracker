import 'dart:async';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/import_preview.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/import.dart';
import 'package:bike_setup_tracker/widgets/sheets/import_merge_overwrite.dart';
import 'package:bike_setup_tracker/widgets/sheets/import_summary.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  final now = DateTime.now().toUtc().copyWith(millisecond: 0, microsecond: 0);
  final older = now.subtract(const Duration(hours: 1));

  Bike bike(String id, {String? name, DateTime? lastModified}) =>
      Bike(id: id, name: name ?? id, person: null, lastModified: lastModified ?? now);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The subtitle of the group titled [title].
  Text subtitleOf(WidgetTester tester, String title) {
    final group = find.ancestor(of: find.text(title), matching: find.byType(ExpansionTile));
    return tester.widget<ExpansionTile>(group).subtitle! as Text;
  }

  String subtitleTextOf(WidgetTester tester, String title) => subtitleOf(tester, title).textSpan!.toPlainText();

  group('summary step', () {
    late AppSettings appSettings;

    setUp(() => appSettings = AppSettings()..showOnboarding = false);
    tearDown(() => appSettings.dispose());

    Future<void> pumpSummary(
      WidgetTester tester, {
      required SelectedData remote,
      required Future<SelectedData> Function() loadLocalData,
      ImportMethod method = ImportMethod.merge,
      ImportSourceOptions source = ImportSourceOptions.file,
      VoidCallback? onConfirm,
      VoidCallback? onBack,
    }) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appSettings,
          child: localizedTestApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: ImportSummarySheetContent(
                remoteData: remote,
                source: source,
                method: method,
                loadLocalData: loadLocalData,
                onConfirm: onConfirm ?? () {},
                onBack: onBack ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows only the non-zero counts per type', (tester) async {
      await pumpSummary(
        tester,
        remote: SelectedData(
          bikes: {
            'new': bike('new'),
            'edited': bike('edited', name: 'Remote'),
          },
        ),
        loadLocalData: () async => SelectedData(
          bikes: {'edited': bike('edited', name: 'Local', lastModified: older)},
        ),
      );

      expect(find.text('Import Summary'), findsOneWidget);
      expect(find.text('Merge data'), findsOneWidget);
      expect(find.text('1 new · 1 to overwrite', findRichText: true), findsOneWidget);
      expect(subtitleTextOf(tester, 'Bikes'), '1 new · 1 to overwrite');
      expect(find.text('Setups'), findsNothing);

      await tester.tap(find.text('Bikes'));
      await tester.pumpAndSettle();
      expect(find.text('File'), findsOneWidget);
      expect(find.text('This device'), findsOneWidget);
      expect(find.text('Remote'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Will be overwritten'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Not on this device'), findsOneWidget);
    });

    testWidgets('only Merge shows when each version was last edited', (tester) async {
      for (final method in ImportMethod.values) {
        // A fresh sheet per method, as the flow builds one each time.
        await tester.pumpWidget(const SizedBox());
        await pumpSummary(
          tester,
          method: method,
          remote: SelectedData(bikes: {'b1': bike('b1', name: 'Remote')}),
          loadLocalData: () async => SelectedData(
            bikes: {'b1': bike('b1', name: 'Local', lastModified: older)},
          ),
        );
        await tester.tap(find.text('Bikes'));
        await tester.pumpAndSettle();
        expect(
          find.byIcon(Icons.history),
          method == ImportMethod.merge ? findsNWidgets(2) : findsNothing,
          reason: '$method',
        );
      }
    });

    testWidgets('an item in the trash here shows as a ghost card that will be restored', (tester) async {
      await pumpSummary(
        tester,
        method: ImportMethod.overwrite,
        remote: SelectedData(bikes: {'b1': bike('b1', name: 'Remote')}),
        loadLocalData: () async => SelectedData(
          bikes: {'b1': Bike(id: 'b1', name: 'Trashed', person: null, isDeleted: true)},
        ),
      );
      await tester.tap(find.text('Bikes'));
      await tester.pumpAndSettle();

      expect(subtitleTextOf(tester, 'Bikes'), '1 new');
      expect(find.text('Will be restored'), findsOneWidget);
      expect(find.text('In the trash'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Trashed')).style?.decoration, TextDecoration.lineThrough);
      expect(find.text('Not on this device'), findsNothing);
    });

    testWidgets('a deletion in the file shows as a ghost card that trashes the device item', (tester) async {
      await pumpSummary(
        tester,
        source: ImportSourceOptions.backup,
        remote: SelectedData(
          bikes: {'b1': Bike(id: 'b1', name: 'Deleted', person: null, lastModified: now, isDeleted: true)},
        ),
        loadLocalData: () async => SelectedData(
          bikes: {'b1': bike('b1', name: 'Live', lastModified: older)},
        ),
      );
      await tester.tap(find.text('Bikes'));
      await tester.pumpAndSettle();

      expect(subtitleTextOf(tester, 'Bikes'), '1 to trash');
      expect(find.text('Deleted in the backup'), findsOneWidget);
      expect(find.text('Will be moved to trash'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Deleted')).style?.decoration, TextDecoration.lineThrough);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('a backup names its column and placeholders after the backup', (tester) async {
      await pumpSummary(
        tester,
        method: ImportMethod.replace,
        source: ImportSourceOptions.backup,
        remote: SelectedData(),
        loadLocalData: () async => SelectedData(bikes: {'b1': bike('b1')}),
      );
      await tester.tap(find.text('Bikes'));
      await tester.pumpAndSettle();

      expect(find.text('Backup'), findsOneWidget);
      expect(find.text('Not in the backup'), findsOneWidget);
      expect(find.text('File'), findsNothing);
    });

    testWidgets('items moved to the trash are red, dimmed and struck through', (tester) async {
      await pumpSummary(
        tester,
        method: ImportMethod.replace,
        remote: SelectedData(bikes: {'kept': bike('kept')}),
        loadLocalData: () async => SelectedData(
          bikes: {
            'kept': bike('kept'),
            'other': bike('other', name: 'Trail'),
          },
        ),
      );
      final error = materialAppTheme.colorScheme.error;

      expect(find.text('Replace data'), findsOneWidget);
      expect(subtitleTextOf(tester, 'Bikes'), '1 unchanged · 1 to trash');
      final spans = (subtitleOf(tester, 'Bikes').textSpan! as TextSpan).children!.whereType<TextSpan>();
      final trashedSpan = spans.singleWhere((span) => span.text == '1 to trash');
      expect(trashedSpan.style?.color, error);

      await tester.tap(find.text('Bikes'));
      await tester.pumpAndSettle();
      final device = tester.widget<Text>(find.text('Trail'));
      expect(device.style?.decoration, TextDecoration.lineThrough);
      expect(
        tester.widget<Opacity>(find.ancestor(of: find.text('Trail'), matching: find.byType(Opacity))).opacity,
        lessThan(1),
      );
      expect(find.text('Not in the file'), findsOneWidget);
      final badge = tester.widget<Container>(
        find.ancestor(of: find.text('Will be moved to trash'), matching: find.byType(Container)).first,
      );
      expect((badge.decoration! as BoxDecoration).color, materialAppTheme.colorScheme.errorContainer);
    });

    testWidgets('an import that changes nothing says so and can still run', (tester) async {
      var confirmed = false;
      await pumpSummary(
        tester,
        remote: SelectedData(),
        loadLocalData: () async => SelectedData(),
        onConfirm: () => confirmed = true,
      );

      expect(find.text('Nothing on this device changes'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      expect(confirmed, isTrue);
    });

    testWidgets('shows progress while the device data loads', (tester) async {
      final local = Completer<SelectedData>();
      await pumpSummary(tester, remote: SelectedData(), loadLocalData: () => local.future);

      expect(find.text('Comparing with the data on this device…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);

      local.complete(SelectedData());
      await tester.pump();
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('a load error shows the message and goes back', (tester) async {
      var back = false;
      await pumpSummary(
        tester,
        remote: SelectedData(),
        loadLocalData: () => Future.error(StateError('disk full')),
        onBack: () => back = true,
      );

      expect(find.textContaining("Couldn't read the data on this device"), findsOneWidget);
      expect(find.textContaining('disk full'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);

      await tester.tap(find.byType(BackButtonIcon));
      expect(back, isTrue);
    });
  });

  group('import flow', () {
    late AppDatabase database;
    late AppSettings appSettings;

    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
    tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

    final remote = SelectedData(bikes: {'b1': bike('b1', name: 'Enduro')});

    Future<List<ImportResult>> openAtMethods(WidgetTester tester) async {
      await tester.runAsync(() async {
        database = AppDatabase.memory();
        await DatabaseMigrationService(database).migrateFromSelectedData(SelectedData(bikes: {'b2': bike('b2')}));
      });
      appSettings = AppSettings()..showOnboarding = false;
      addTearDown(() async {
        appSettings.dispose();
        await tester.runAsync(database.close);
      });

      final imports = <ImportResult>[];
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider.value(value: appSettings),
          ],
          child: localizedTestApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ImportSheetFlow(onImport: (result) async => imports.add(result)),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Step 1 opens the system file picker; hand the file over directly.
      tester.widget<SelectImportSourceSheetContent>(find.byType(SelectImportSourceSheetContent)).onFile(remote);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entire dataset'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectImportMethodSheetContent), findsOneWidget);
      return imports;
    }

    Future<void> waitForSummary(WidgetTester tester) async {
      for (var i = 0; i < 40 && find.byType(FilledButton).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    testWidgets('a method opens the summary, and back returns to the methods', (tester) async {
      await openAtMethods(tester);

      await tester.tap(find.text('Replace data'));
      await tester.pump();
      await waitForSummary(tester);
      expect(find.byType(ImportSummarySheetContent), findsOneWidget);
      expect(subtitleTextOf(tester, 'Bikes'), '1 new · 1 to trash');

      await tester.tap(find.byType(BackButtonIcon));
      await tester.pumpAndSettle();
      expect(find.byType(ImportSummarySheetContent), findsNothing);
      expect(find.byType(SelectImportMethodSheetContent), findsOneWidget);
    });

    testWidgets('Import runs the chosen method on the selection', (tester) async {
      final imports = await openAtMethods(tester);

      await tester.tap(find.text('Overwrite data'));
      await tester.pump();
      await waitForSummary(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(imports, hasLength(1));
      expect(imports.single.importMethod, ImportMethod.overwrite);
      expect(imports.single.dataToImport, same(remote));
      expect(find.byType(ImportSheetFlow), findsNothing);
    });
  });
}
