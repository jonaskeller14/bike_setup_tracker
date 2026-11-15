import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/l10n/enum_labels.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/service_error.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late Directory directory;

  setUp(() {
    database = AppDatabase.memory();
    directory = Directory.systemTemp.createTempSync('file_import_errors');
  });

  tearDown(() async {
    await database.close();
    directory.deleteSync(recursive: true);
  });

  test('a missing backup file is a typed error that reads in both languages', () async {
    final result = await FileImport.readBackup(path: '${directory.path}/missing.json', appDatabase: database);

    expect(result, isA<DataFailure<SelectedData>>());
    final error = (result as DataFailure<SelectedData>).error;
    expect(error.kind, DataErrorKind.readLocalBackup);
    expect(error.detail, contains('File does not exist'));
    expect(error.message(lookupAppLocalizations(const Locale('en'))), startsWith('Reading backup failed: '));
    expect(error.message(lookupAppLocalizations(const Locale('de'))), startsWith('Backup konnte nicht gelesen werden: '));
  });

  test('a backup file that is not JSON keeps the parser text as the detail', () async {
    final file = File('${directory.path}/broken.json')..writeAsStringSync('not json');

    final result = await FileImport.readBackup(path: file.path, appDatabase: database);

    final error = (result as DataFailure<SelectedData>).error;
    expect(error.kind, DataErrorKind.readLocalBackup);
    expect(error.detail, isNotEmpty);
  });
}
