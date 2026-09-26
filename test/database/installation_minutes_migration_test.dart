import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coverage for the v16 migration that rounds installation instants down to the
/// whole minute — the resolution every picker in the app edits at.
void main() {
  group('installation minutes v16 migration', () {
    late AppDatabase db;

    // 2023-11-14 22:13:00Z — an exact minute boundary to offset seconds from.
    const int minute = 1700000040;
    // The floating local face value for the same instant at UTC+1.
    const int localMinute = minute + 3600;

    setUp(() async {
      db = AppDatabase.memory();
      // FK off so installations can reference components that were never seeded.
      await db.customStatement('PRAGMA foreign_keys = OFF');
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seed(String id, String componentId, int utc, int local) {
      return db.customStatement(
        'INSERT INTO installations '
        '(id, component_id, parent, parent_type, date_time_u_t_c, date_time_local) '
        "VALUES ('$id', '$componentId', 'b1', 'bike', $utc, $local)",
      );
    }

    Future<(int, int)> read(String id) async {
      final row = await db
          .customSelect(
            "SELECT date_time_u_t_c AS utc, date_time_local AS local "
            "FROM installations WHERE id = '$id'",
          )
          .getSingle();
      return (row.read<int>('utc'), row.read<int>('local'));
    }

    test('rounds seconds off both timestamp columns', () async {
      await seed('i1', 'c1', minute + 47, localMinute + 47);

      await AppDatabase.migrateInstallationMinutes(db);

      expect(await read('i1'), (minute, localMinute));
    });

    test('spreads same-minute collisions forward, keeping the recorded order', () async {
      // Two drag-and-drops 42 seconds apart collapse onto the same minute.
      await seed('i1', 'c1', minute + 5, localMinute + 5);
      await seed('i2', 'c1', minute + 47, localMinute + 47);

      await AppDatabase.migrateInstallationMinutes(db);

      expect(await read('i1'), (minute, localMinute));
      expect(await read('i2'), (
        minute + 60,
        localMinute + 60,
      ), reason: 'the later row moves on so the two never sort as a tie');
    });

    test('does not disturb a later entry that is already free', () async {
      await seed('i1', 'c1', minute + 5, localMinute + 5);
      await seed('i2', 'c1', minute + 47, localMinute + 47);
      await seed('i3', 'c1', minute + 120, localMinute + 120);

      await AppDatabase.migrateInstallationMinutes(db);

      expect(await read('i3'), (minute + 120, localMinute + 120));
    });

    test('spreads per component, not across them', () async {
      await seed('i1', 'c1', minute + 5, localMinute + 5);
      await seed('i2', 'c1', minute + 47, localMinute + 47);
      await seed('i3', 'c2', minute + 30, localMinute + 30);

      await AppDatabase.migrateInstallationMinutes(db);

      expect(await read('i3'), (minute, localMinute), reason: "another component's collision must not push this row");
    });

    test('leaves the from-beginning sentinel untouched', () async {
      await seed('i1', 'c1', 0, 3600);

      await AppDatabase.migrateInstallationMinutes(db);

      expect(await read('i1'), (0, 3600));
    });

    test('is idempotent', () async {
      await seed('i1', 'c1', minute + 5, localMinute + 5);
      await seed('i2', 'c1', minute + 47, localMinute + 47);

      await AppDatabase.migrateInstallationMinutes(db);
      final first = (await read('i1'), await read('i2'));
      await AppDatabase.migrateInstallationMinutes(db);

      expect((await read('i1'), await read('i2')), first);
    });
  });
}
