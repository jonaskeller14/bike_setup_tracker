import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for the v12 migration that normalizes `Adjustments.unit` from
/// free-spelled strings ("psi", "PSI", "kph", ...) to the canonical
/// `AdjustmentUnit` encoding ("pressure:psi").
void main() {
  group('adjustment unit v12 migration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    test('normalizes legacy spellings via the alias table', () async {
      await db.customStatement('PRAGMA foreign_keys = OFF');

      // adjustments: unambiguous alias, mixed case, unrecognized, empty, null.
      // component_id is required by the table's CHECK (exactly one owner set).
      await db.customStatement(
        "INSERT INTO adjustments (id, component_id, order_index, name, unit, type) VALUES "
        "('a1', 'c1', 0, 'Pressure', 'psi', 'numerical'), "
        "('a2', 'c1', 1, 'Pressure Caps', 'PSI', 'numerical'), "
        "('a3', 'c1', 2, 'Speed', 'kph', 'numerical'), "
        "('a4', 'c1', 3, 'Custom', 'Klicks', 'step'), "
        "('a5', 'c1', 4, 'Empty', '', 'numerical'), "
        "('a6', 'c1', 5, 'Null', NULL, 'numerical')",
      );

      await AppDatabase.migrateAdjustmentUnits(db);

      final adjustmentRows = {
        for (final row in await db.customSelect('SELECT id, unit FROM adjustments').get())
          row.read<String>('id'): row.read<String?>('unit'),
      };
      expect(adjustmentRows['a1'], 'pressure:psi');
      expect(adjustmentRows['a2'], 'pressure:psi', reason: 'alias lookup is case-insensitive');
      expect(adjustmentRows['a3'], 'speed:kilometersPerHour');
      expect(adjustmentRows['a4'], 'Klicks', reason: 'unrecognized spelling stays a custom label');
      expect(adjustmentRows['a5'], isNull, reason: 'empty string normalizes to no unit');
      expect(adjustmentRows['a6'], isNull);
    });

    test('re-running the migration is a no-op (already-canonical strings survive)', () async {
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement(
        "INSERT INTO adjustments (id, component_id, order_index, name, unit, type) VALUES "
        "('a1', 'c1', 0, 'Pressure', 'psi', 'numerical')",
      );

      await AppDatabase.migrateAdjustmentUnits(db);
      await AppDatabase.migrateAdjustmentUnits(db);

      final row = (await db.customSelect(
        "SELECT unit FROM adjustments WHERE id = 'a1'",
      ).get()).single;
      expect(row.read<String?>('unit'), 'pressure:psi');
    });
  });
}
