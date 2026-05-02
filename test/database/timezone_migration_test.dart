import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Timezone Migration (v1 -> v2)', () {
    test('Migration correctly restores 10:30 face-value from legacy device-shifted epoch', () async {
      // SCENARIO:
      // In the old system (v1), a user in UTC+2 (e.g., Germany Summer) 
      // saved a setup at 10:30:00 local time.
      // Drift/Dart saved this as an absolute Unix epoch representing 08:30:00 UTC.
      
      final String id = "migration_test_1";
      final legacyLocalTime = DateTime(2024, 5, 15, 10, 30); // 10:30 in current system's timezone
      final legacyUnixEpoch = legacyLocalTime.millisecondsSinceEpoch ~/ 1000;
      
      // Manually insert raw data into SQLite to simulate the legacy state 
      // (Bypassing the new TypeConverter which isn't applied to raw SQL strings)
      await db.customStatement(
          'INSERT INTO setups (id, bike_id, name, datetime_local, datetime, last_modified, tags) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [id, 'bike1', 'Legacy Setup', legacyUnixEpoch, legacyUnixEpoch, legacyUnixEpoch, '[]']
      );

      // Verify the "Broken" baseline (Diagnostic: check if it reads the old epoch correctly)
      await db.customSelect('SELECT datetime_local FROM setups WHERE id = ?', variables: [Variable.withString(id)]).get();
      // ACT: Run the migration helper
      // We trigger the migration through the formal onUpgrade path
      await db.migration.onUpgrade(db.createMigrator(), 1, 2);

      // ASSERT: Read back via the DataClass (which uses the new TypeConverter)
      final correctedSetup = await (db.select(db.setups)..where((t) => t.id.equals(id))).getSingle();
      
      expect(correctedSetup.datetimeLocal.hour, 10, reason: "Hour should have stayed 10 after migration");
      expect(correctedSetup.datetimeLocal.minute, 30, reason: "Minute should have stayed 30 after migration");
      expect(correctedSetup.datetimeLocal.isUtc, false, reason: "Must be a floating local time");
    });
  });
}

// Add a visible helper to AppDatabase for the test or just use the private one if possible.
// I'll update AppDatabase to make it accessible or just move the logic here.
// Actually, I'll update AppDatabase to have a @visibleForTesting helper.
