import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// End-to-end migration coverage for every supported upgrade entry point.
///
/// Single-step upgrades (vN-1 -> vN) are *not* enough: each `TableMigration`
/// step recreates its table from the **current** Dart schema, so a column added
/// in a later version silently changes the SQL that an earlier step emits. That
/// only blows up on long upgrade paths — e.g. the v8 `images` column broke the
/// `from < 4` setups recreation for anyone crossing the v4 boundary, while
/// v7 -> v8 users were unaffected.
///
/// Each case seeds a real database file at an older schema version, then
/// re-opens it through [AppDatabase.forTesting] so drift runs the *actual*
/// open-time upgrade machinery to the current schema.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_migration_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  // Reshapes a freshly-created (v9) database back to [version] by undoing every
  // structural change introduced after it, newest-first. This lets us drive the
  // real `onUpgrade` from any historical version without hand-writing each full
  // schema. v4 (setups.name NOT NULL -> nullable), v6 (rating_entries reshape)
  // and v2 (data-only) need no structural undo — their steps rewrite/recreate
  // the affected tables regardless of the starting column shape.
  Future<void> reshapeToVersion(AppDatabase db, int version) async {
    if (version < 9) {
      // v9 added installations.parent_type.
      await db.customStatement('ALTER TABLE installations DROP COLUMN parent_type');
    }
    if (version < 8) {
      // v8 added setups.images.
      await db.customStatement('ALTER TABLE setups DROP COLUMN images');
    }
    if (version < 7) {
      // v7 dropped the `category` column from adjustments + rating_metrics.
      await db.customStatement('ALTER TABLE adjustments ADD COLUMN category TEXT');
    }
    if (version < 5) {
      // v5 introduced the rating_* tables and dropped adjustments.rating_id.
      await db.customStatement('DROP TABLE rating_entry_values');
      await db.customStatement('DROP TABLE rating_entries');
      await db.customStatement('DROP TABLE rating_metrics');
      await db.customStatement('ALTER TABLE adjustments ADD COLUMN rating_id TEXT');
    } else if (version < 7) {
      // rating_metrics exists from v5 on and carried `category` until v7.
      await db.customStatement('ALTER TABLE rating_metrics ADD COLUMN category TEXT');
    }
    if (version < 3) {
      // v3 added task_rules.tags.
      await db.customStatement('ALTER TABLE task_rules DROP COLUMN tags');
    }
  }

  // Seeds a single setup row via raw SQL — the typed API can't be used here
  // because the reshaped schema predates the `images` column. `name` is the
  // legacy placeholder the v4 step is expected to clear.
  Future<void> seedSetup(AppDatabase db) async {
    const epochSeconds = 1700000000; // 2023-11-14, arbitrary but valid.
    await db.customStatement(
      'INSERT INTO setups '
      '(id, bike_id, name, is_deleted, last_modified, datetime, datetime_local, tags) '
      "VALUES ('s1', 'b1', 'Unnamed Setup', 0, $epochSeconds, $epochSeconds, $epochSeconds, '[]')",
    );
  }

  // Seeds a single installation row (on a bike) via raw SQL. The reshaped
  // schema for versions < 9 lacks `parent_type`, so we omit it here; the v9
  // migration step is expected to add the column with the correct default.
  Future<void> seedInstallation(AppDatabase db) async {
    const epochSeconds = 1700000000;
    await db.customStatement(
      'INSERT INTO installations '
      '(id, component_id, parent, date_time_u_t_c, date_time_local) '
      "VALUES ('i1', 'c1', 'b1', $epochSeconds, $epochSeconds)",
    );
  }

  // Builds a db file seeded at [startVersion] and re-opens it so drift runs the
  // real upgrade to the current schema. Returns the upgraded database.
  Future<AppDatabase> migrateFrom(int startVersion) async {
    final file = File(p.join(tempDir.path, 'v$startVersion.sqlite'));

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    // Force the lazy open so onCreate (createAll @ v8) runs before we reshape.
    await seed.customSelect('SELECT 1').get();
    // FKs off so we can drop/re-add columns and seed an orphan setup row.
    await seed.customStatement('PRAGMA foreign_keys = OFF');
    await reshapeToVersion(seed, startVersion);
    await seedSetup(seed);
    await seedInstallation(seed);
    await seed.customStatement('PRAGMA user_version = $startVersion');
    await seed.close();

    // Re-open: drift sees user_version < schemaVersion and runs onUpgrade.
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    await upgraded.customSelect('SELECT 1').get(); // triggers open + migration
    return upgraded;
  }

  Future<Set<String>> columnNames(AppDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  group('onUpgrade from every prior version to the current schema', () {
    // Covers the full range of jump sizes: the v8 case is a single step, the
    // v1 case crosses every TableMigration in the strategy.
    for (final startVersion in [1, 2, 3, 4, 5, 6, 7, 8]) {
      test('v$startVersion -> current completes and preserves seed rows', () async {
        final db = await migrateFrom(startVersion);
        addTearDown(db.close);

        // The setups table ends up with the v8 `images` column.
        expect(
          await columnNames(db, 'setups'),
          contains('images'),
          reason: 'images column missing after v$startVersion upgrade',
        );

        // The installations table ends up with the v9 `parent_type` column.
        expect(
          await columnNames(db, 'installations'),
          contains('parent_type'),
          reason: 'parent_type column missing after v$startVersion upgrade',
        );

        // The seeded installation row (parent='b1') got the 'bike' default.
        final instRows = await db.customSelect(
          "SELECT parent_type FROM installations WHERE id = 'i1'",
        ).get();
        expect(instRows, hasLength(1));
        expect(instRows.single.read<String>('parent_type'), 'bike');

        // The seeded row survived the migration.
        final rows = await db.customSelect('SELECT id, name, images FROM setups').get();
        expect(rows, hasLength(1));
        final row = rows.single;
        expect(row.read<String>('id'), 's1');

        // images defaulted to the empty list, and the converter round-trips it.
        expect(row.read<String>('images'), '[]');
        final typed = await (db.select(db.setups)..where((t) => t.id.equals('s1'))).getSingle();
        expect(typed.images, isEmpty);

        // The v4 step clears the legacy 'Unnamed Setup' placeholder, but only on
        // upgrades that start before v4.
        if (startVersion < 4) {
          expect(row.read<String?>('name'), isNull,
              reason: 'v4 step should clear the legacy placeholder name');
        } else {
          expect(row.read<String?>('name'), 'Unnamed Setup');
        }

        // Schema converged on the post-v5 rating tables / post-v7 column drops
        // regardless of entry point.
        expect(await columnNames(db, 'adjustments'), isNot(contains('category')));
        expect(await columnNames(db, 'adjustments'), isNot(contains('rating_id')));
        expect(await columnNames(db, 'rating_metrics'), isNot(contains('category')));
        expect(await columnNames(db, 'task_rules'), contains('tags'));
      });
    }
  });
}
