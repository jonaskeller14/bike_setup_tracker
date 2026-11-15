import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_set_now_migration');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('v28 -> v29 adds set_now_adjustment_ids, keeps setups and backfills no marks', () async {
    final file = File(p.join(tempDir.path, 'v28.sqlite'));

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get();
    await seed.customStatement('PRAGMA foreign_keys = OFF');
    // Back to the v28 shape: no set-now column.
    await seed.customStatement('ALTER TABLE setups DROP COLUMN set_now_adjustment_ids');
    await seed.customStatement(
      'INSERT INTO setups '
      '(id, bike_id, is_deleted, last_modified, datetime, datetime_local, tags) '
      "VALUES ('s1', 'b1', 0, 0, 0, 0, '[\"Trail\"]')",
    );
    await seed.customStatement('PRAGMA user_version = 28');
    await seed.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    final raw = await upgraded.customSelect('SELECT set_now_adjustment_ids FROM setups').getSingle();
    expect(raw.read<String>('set_now_adjustment_ids'), '[]');

    final row = await upgraded.select(upgraded.setups).getSingle();
    expect(row.id, 's1');
    expect(row.tags, {'Trail'});
    expect(row.setNowAdjustmentIds, isEmpty);

    final marked = row.copyWith(setNowAdjustmentIds: {'adj1'});
    await upgraded.update(upgraded.setups).replace(marked);
    final reread = await upgraded.select(upgraded.setups).getSingle();
    expect(reread.setNowAdjustmentIds, {'adj1'});
    expect(reread.toModel().setNowAdjustmentIds, {'adj1'});
  });
}
