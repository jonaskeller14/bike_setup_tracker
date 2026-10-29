import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _feedbackTables = [
  'feedbacks',
  'feedback_observations',
  'feedback_comparisons',
  'test_sessions',
];

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_feedback_migration');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<Set<String>> tableNames(AppDatabase db) async {
    final rows = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  Future<Set<String>> columnNames(AppDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  test('v25 -> v26 creates the feedback tables and adds setups.test_session_id', () async {
    final file = File(p.join(tempDir.path, 'v25.sqlite'));

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    await seed.bikesDao.insertBike(Bike(id: 'b1', name: 'Bike', person: null).toCompanion());
    // Back to the v25 shape: no feedback tables, no setups.test_session_id.
    for (final table in _feedbackTables) {
      await seed.customStatement('DROP TABLE $table');
    }
    await seed.customStatement('ALTER TABLE setups DROP COLUMN test_session_id');
    await seed.customStatement(
      'INSERT INTO setups (id, bike_id, is_deleted, last_modified, datetime, datetime_local, tags) '
      "VALUES ('s1', 'b1', 0, 1790000000, 1790000000, 1790000000, '[]')",
    );
    await seed.customStatement('PRAGMA user_version = 25');
    await seed.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect(await tableNames(upgraded), containsAll(_feedbackTables));
    expect(await columnNames(upgraded, 'setups'), contains('test_session_id'));

    final setups = await upgraded.setupsDao.watchAllSetups().first;
    expect(setups.single.id, 's1');
    expect(setups.single.testSessionId, isNull);
    expect(setups.single.toModel().testSessionId, isNull);

    // The new tables accept rows.
    await upgraded.feedbackDao.upsertTestSession(
      TestSessionsCompanion.insert(
        id: 'session1',
        bikeId: 'b1',
        lastModified: DateTime.utc(2026, 10, 1),
        startedAtUTC: DateTime.utc(2026, 10, 1, 9),
        startedAtLocal: DateTime(2026, 10, 1, 11),
      ),
    );
    expect(await upgraded.feedbackDao.getAllTestSessionsBypass(), hasLength(1));
  });
}
