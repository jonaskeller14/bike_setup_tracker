import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Schema-v11 migration: the single value column moves to a uniformly
/// JSON-encoded format for every type.
///
/// v11 is a *data-only* upgrade (no schema change), so we can seed a real
/// database at the current schema, stamp `user_version = 10`, write old-format
/// value rows, then re-open through [AppDatabase.forTesting] so drift runs the
/// actual `onUpgrade` (which calls [AppDatabase.migrateAdjustmentValuesToJson]).
///
/// Each pre-v11 value was stored as: scalars via `toString`, categoricals as a
/// plain option string (multi-select never shipped), durations via
/// `Duration.toString()`. The migration must reparse and re-encode every row
/// losslessly, so a text value that *looks* like a categorical array can never
/// again be confused with one.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_v11_migration_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  const epoch = 1700000000; // arbitrary but valid.

  Future<void> insertAdjustment(AppDatabase db, String id, String type,
      [String payload = '{}']) {
    return db.customStatement(
      'INSERT INTO adjustments (id, component_id, order_index, name, type, json_payload) '
      "VALUES ('$id', 'comp1', 0, '$id', '$type', '$payload')",
    );
  }

  Future<void> insertSetupValue(AppDatabase db, String adjId, String rawValue) {
    return db.customStatement(
      'INSERT INTO setup_adjustment_values (setup_id, adjustment_id, value) '
      "VALUES ('s1', '$adjId', '$rawValue')",
    );
  }

  Future<void> insertMetric(AppDatabase db, String id, String type) {
    return db.customStatement(
      'INSERT INTO rating_metrics (id, rating_id, order_index, weight, name, type, json_payload) '
      "VALUES ('$id', 'r1', 0, 1.0, '$id', '$type', '{}')",
    );
  }

  Future<void> insertEntryValue(AppDatabase db, String metricId, String rawValue) {
    return db.customStatement(
      'INSERT INTO rating_entry_values (rating_entry_id, rating_metric_id, value) '
      "VALUES ('e1', '$metricId', '$rawValue')",
    );
  }

  /// Seeds a v10 database file with old-format value rows and returns the
  /// re-opened (migrated) database.
  Future<AppDatabase> seedAndMigrate() async {
    final file = File(p.join(tempDir.path, 'v10.sqlite'));

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get(); // force onCreate at current schema
    await seed.customStatement('PRAGMA foreign_keys = OFF');

    // Parent rows for the value FKs / mapper joins.
    await seed.customStatement(
      'INSERT INTO setups (id, bike_id, name, is_deleted, last_modified, datetime, datetime_local, tags) '
      "VALUES ('s1', 'b1', 'S', 0, $epoch, $epoch, $epoch, '[]')",
    );
    await seed.customStatement(
      'INSERT INTO rating_entries (id, bike_id, setup_id, is_deleted, last_modified, date_time_u_t_c, date_time_local) '
      "VALUES ('e1', 'b1', 's1', 0, $epoch, $epoch, $epoch)",
    );

    // Adjustments + old-format setup values, one per type.
    await insertAdjustment(seed, 'b1adj', 'boolean');
    await insertSetupValue(seed, 'b1adj', 'true');
    await insertAdjustment(seed, 'n1', 'numerical');
    await insertSetupValue(seed, 'n1', '1.5');
    await insertAdjustment(seed, 'st1', 'step');
    await insertSetupValue(seed, 'st1', '3');
    await insertAdjustment(seed, 'txt1', 'text');
    await insertSetupValue(seed, 'txt1', 'hello world');
    await insertAdjustment(seed, 'txt2', 'text');
    await insertSetupValue(seed, 'txt2', '["abc"]'); // text that looks like an array
    await insertAdjustment(seed, 'c1', 'categorical');
    await insertSetupValue(seed, 'c1', 'Open');
    await insertAdjustment(seed, 'c2', 'categorical');
    await insertSetupValue(seed, 'c2', '[1,2]'); // an option literally named "[1,2]"
    await insertAdjustment(seed, 'd1', 'duration');
    await insertSetupValue(seed, 'd1', '0:00:10.000000');

    // Rating metrics + old-format entry values (proves the 2nd table migrates).
    await insertMetric(seed, 'mNum', 'numerical');
    await insertEntryValue(seed, 'mNum', '2.5');
    await insertMetric(seed, 'mCat', 'categorical');
    await insertEntryValue(seed, 'mCat', 'Firm');
    await insertMetric(seed, 'mDur', 'duration');
    await insertEntryValue(seed, 'mDur', '0:01:00.000000');

    await seed.customStatement('PRAGMA user_version = 10');
    await seed.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    await upgraded.customSelect('SELECT 1').get(); // triggers migration
    return upgraded;
  }

  Future<String> rawSetupValue(AppDatabase db, String adjId) async {
    final rows = await db.customSelect(
      "SELECT value FROM setup_adjustment_values WHERE adjustment_id = '$adjId'",
    ).get();
    return rows.single.read<String>('value');
  }

  Future<String> rawEntryValue(AppDatabase db, String metricId) async {
    final rows = await db.customSelect(
      "SELECT value FROM rating_entry_values WHERE rating_metric_id = '$metricId'",
    ).get();
    return rows.single.read<String>('value');
  }

  group('setup_adjustment_values re-encoded to JSON', () {
    test('scalars keep their (already-JSON) form', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);
      expect(await rawSetupValue(db, 'b1adj'), 'true');
      expect(await rawSetupValue(db, 'n1'), '1.5');
      expect(await rawSetupValue(db, 'st1'), '3');
    });

    test('text becomes a quoted JSON string — JSON-looking text no longer confusable', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);
      expect(await rawSetupValue(db, 'txt1'), '"hello world"');
      expect(await rawSetupValue(db, 'txt2'), '"[\\"abc\\"]"');
    });

    test('categorical plain string becomes a one-element JSON array', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);
      expect(await rawSetupValue(db, 'c1'), '["Open"]');
    });

    test('an option literally named "[1,2]" is preserved, not split', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);
      expect(await rawSetupValue(db, 'c2'), '["[1,2]"]');
    });

    test('duration becomes integer microseconds', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);
      expect(await rawSetupValue(db, 'd1'), '10000000');
    });
  });

  group('rating_entry_values re-encoded to JSON', () {
    test('every metric value type is migrated', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);
      expect(await rawEntryValue(db, 'mNum'), '2.5');
      expect(await rawEntryValue(db, 'mCat'), '["Firm"]');
      expect(await rawEntryValue(db, 'mDur'), '60000000');
    });
  });

  group('reads back through the mapper as correctly-typed values', () {
    test('setup values decode to their in-memory types', () async {
      final db = await seedAndMigrate();
      addTearDown(db.close);

      final typed = await db.setupsDao.watchTypedValuesForSetup('s1').first;
      final setup = (await db.setupsDao.getSetup('s1'))!.toModel(values: typed);
      final v = setup.bikeAdjustmentValues;

      expect(v['b1adj'], true);
      expect(v['n1'], 1.5);
      expect(v['st1'], 3);
      expect(v['txt1'], 'hello world');
      // The whole point: JSON-looking text survives as a String, not a List.
      expect(v['txt2'], isA<String>());
      expect(v['txt2'], '["abc"]');
      expect(v['c1'], isA<List<String>>());
      expect(v['c1'], ['Open']);
      expect(v['c2'], ['[1,2]']);
      expect(v['d1'], const Duration(seconds: 10));
    });
  });
}
