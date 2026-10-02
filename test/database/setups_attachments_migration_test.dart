import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the v3 -> v8 upgrade crash:
///
///   SqliteException(1): no such column: "images"
///   INSERT INTO tmp_for_copy_setups (..., "images", ...)
///   SELECT ..., "images", ... FROM "setups";
///
/// The `from < 4` migration recreates the `setups` table via [TableMigration].
/// That recreation is built from the *current* schema, whose `attachments`
/// column (v20, `images` from v8 on) the source `setups` table of an older
/// database lacks, so the data-copy step must not try to read it. The v20 step
/// uses the same recreation to drop the unshipped `images` column.
void main() {
  group('setups recreation with a pre-attachments schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    Future<Set<String>> columnNames(String table) async {
      final rows = await db.customSelect('PRAGMA table_info($table)').get();
      return rows.map((r) => r.read<String>('name')).toSet();
    }

    test('recreates setups and backfills attachments when the source lacks it', () async {
      // FK checks are ON by default; disable so we can seed a setup row without
      // a parent bike, and so dropping/recreating the table is unconstrained.
      await db.customStatement('PRAGMA foreign_keys = OFF');

      // Simulate a pre-v8 database: strip the column that later versions added.
      await db.customStatement('ALTER TABLE setups DROP COLUMN attachments');
      expect(await columnNames('setups'), isNot(contains('attachments')));

      await db.customStatement(
        'INSERT INTO setups '
        '(id, bike_id, is_deleted, last_modified, datetime, datetime_local, tags) '
        "VALUES ('s1', 'b1', 0, 0, 0, 0, '[]')",
      );

      // This is exactly the `from < 4` step. Before the fix it crashed with
      // "no such column"; `newColumns` makes Drift fill it from the column
      // default instead of copying it out of the old table.
      final migrator = db.createMigrator();
      await migrator.alterTable(
        TableMigration(db.setups, newColumns: [db.setups.attachments]),
      );

      // The column exists again and the pre-existing row survived with the
      // default value.
      expect(await columnNames('setups'), contains('attachments'));
      final rows = await db.customSelect('SELECT id, attachments FROM setups').get();
      expect(rows, hasLength(1));
      expect(rows.single.read<String>('id'), 's1');
      expect(rows.single.read<String>('attachments'), '[]');
    });

    test('replaces the v8 images column with an empty attachments column', () async {
      await db.customStatement('PRAGMA foreign_keys = OFF');

      // Simulate a v8–v19 database: `images` instead of `attachments`.
      await db.customStatement('ALTER TABLE setups RENAME COLUMN attachments TO images');
      await db.customStatement(
        'INSERT INTO setups '
        '(id, bike_id, is_deleted, last_modified, datetime, datetime_local, tags, images) '
        """VALUES ('s1', 'b1', 0, 0, 0, 0, '[]', '["0f8e.jpg"]')""",
      );

      // This is exactly the `from < 20` setups step.
      final migrator = db.createMigrator();
      await migrator.alterTable(
        TableMigration(db.setups, newColumns: [db.setups.attachments]),
      );

      final columns = await columnNames('setups');
      expect(columns, contains('attachments'));
      expect(columns, isNot(contains('images')));
      final setup = await db.select(db.setups).getSingle();
      expect(setup.id, 's1');
      expect(setup.attachments, isEmpty);
    });
  });
}
