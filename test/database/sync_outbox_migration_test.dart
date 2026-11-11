import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/database/tables/sync_outbox.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _syncTables = ['sync_outbox', 'sync_state', 'sync_cursors'];

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_sync_outbox_migration');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<Map<String, String>> triggerSql(AppDatabase db) async {
    final rows = await db.customSelect("SELECT name, sql FROM sqlite_master WHERE type = 'trigger'").get();
    return {for (final row in rows) row.read<String>('name'): row.read<String>('sql')};
  }

  test('v27 -> v28 creates the sync tables and triggers without enqueuing existing rows', () async {
    final file = File(p.join(tempDir.path, 'v27.sqlite'));
    final bike = Bike(name: 'Bike', person: null);

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get();
    // Back to the v27 shape: no sync tables, no triggers.
    for (final trigger in syncOutboxTriggers) {
      await seed.customStatement('DROP TRIGGER ${trigger.entityName}');
    }
    for (final table in _syncTables) {
      await seed.customStatement('DROP TABLE $table');
    }
    await seed.bikesDao.insertBike(bike.toCompanion());
    await seed.customStatement('PRAGMA user_version = 27');
    await seed.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    final fresh = AppDatabase.memory();
    addTearDown(fresh.close);
    await fresh.customSelect('SELECT 1').get();

    expect(await triggerSql(upgraded), await triggerSql(fresh));
    expect(await triggerSql(upgraded), hasLength(syncOutboxTriggers.length));
    expect(await upgraded.syncDao.pendingBatch(10), isEmpty);

    await upgraded.bikesDao.deleteBike(bike.id);

    expect((await upgraded.syncDao.pendingBatch(10)).single.rowId, bike.id);
  });
}
