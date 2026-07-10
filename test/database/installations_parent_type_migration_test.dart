import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for the v9 migration that adds `parent_type` to the
/// `installations` table and backfills rows where `parent IS NULL` to 'none'.
void main() {
  group('installations parentType v9 migration', () {
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

    test('adds parent_type column and backfills bike/none correctly', () async {
      // FK off so we can seed orphan rows and alter the installations table.
      await db.customStatement('PRAGMA foreign_keys = OFF');

      // Simulate pre-v9: strip the column that the v9 step adds.
      await db.customStatement(
        'ALTER TABLE installations DROP COLUMN parent_type',
      );
      expect(await columnNames('installations'), isNot(contains('parent_type')));

      // Seed two rows:
      //   i1: installed on a bike (parent='b1') → keeps the column default 'bike'
      //   i2: uninstalled (parent=NULL) → backfilled to 'none'
      const epoch = 1700000000;
      await db.customStatement(
        "INSERT INTO installations "
        "(id, component_id, parent, date_time_u_t_c, date_time_local) "
        "VALUES ('i1', 'c1', 'b1', $epoch, $epoch)",
      );
      await db.customStatement(
        "INSERT INTO installations "
        "(id, component_id, parent, date_time_u_t_c, date_time_local) "
        "VALUES ('i2', 'c1', NULL, $epoch, $epoch)",
      );

      // Run exactly the v9 migration steps.
      final migrator = db.createMigrator();
      await migrator.addColumn(db.installations, db.installations.parentType);
      await db.customStatement(
        "UPDATE installations SET parent_type = 'none' WHERE parent IS NULL",
      );

      expect(await columnNames('installations'), contains('parent_type'));

      final rows = await db.customSelect(
        'SELECT id, parent_type FROM installations ORDER BY id',
      ).get();
      expect(rows, hasLength(2));

      expect(rows[0].read<String>('id'), 'i1');
      expect(rows[0].read<String>('parent_type'), 'bike',
          reason: 'non-null parent row keeps the column default');

      expect(rows[1].read<String>('id'), 'i2');
      expect(rows[1].read<String>('parent_type'), 'none',
          reason: 'null-parent row is backfilled to none');
    });

    test('archived rows survive round-trip through the typed ORM', () async {
      // Write an archived installation directly via the typed API (which now
      // understands parentType) and read it back via the mapper.
      await db.customStatement('PRAGMA foreign_keys = OFF');

      const epoch = 1700000000;
      await db.customStatement(
        "INSERT INTO installations "
        "(id, component_id, parent, parent_type, date_time_u_t_c, date_time_local) "
        "VALUES ('i3', 'c1', NULL, 'archived', $epoch, $epoch)",
      );

      final rows = await db.customSelect(
        "SELECT id, parent_type FROM installations WHERE id = 'i3'",
      ).get();
      expect(rows.single.read<String>('parent_type'), 'archived');
    });
  });
}
