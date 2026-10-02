import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The v21 step adds `attachments` to `task_rules` and `task_entries`.
///
/// Each case seeds a real database file at v20 and re-opens it through
/// [AppDatabase.forTesting], so drift runs the actual open-time upgrade.
void main() {
  const epochSeconds = 1700000000; // 2023-11-14, arbitrary but valid.
  const taskTables = ['task_rules', 'task_entries'];

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_task_attachments_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  // Creates a current-schema database file, lets [seed] reshape and fill it,
  // stamps it as v20 and re-opens it so drift runs the upgrade.
  Future<AppDatabase> upgradeFromV20(Future<void> Function(AppDatabase db) seed) async {
    final file = File(p.join(tempDir.path, 'v20.sqlite'));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await seed(db);
    await db.customStatement('PRAGMA user_version = 20');
    await db.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();
    return upgraded;
  }

  Future<List<String>> columnNames(AppDatabase db, String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  Future<void> seedTaskRows(AppDatabase db) async {
    await db.customStatement(
      'INSERT INTO task_rules (id, last_modified, name, notes) '
      "VALUES ('tr1', $epochSeconds, 'Service fork', 'Lowers service')",
    );
    await db.customStatement(
      'INSERT INTO task_entries (id, last_modified, name, date_time_u_t_c, date_time_local, task_rule) '
      "VALUES ('te1', $epochSeconds, 'Fork serviced', $epochSeconds, $epochSeconds, 'tr1')",
    );
  }

  group('v20 -> v21 task attachments', () {
    test('adds an empty attachments column to both tables and keeps existing rows', () async {
      final db = await upgradeFromV20((seed) async {
        for (final table in taskTables) {
          await seed.customStatement('ALTER TABLE $table DROP COLUMN attachments');
        }
        await seedTaskRows(seed);
      });

      for (final table in taskTables) {
        expect(
          (await columnNames(db, table)).where((name) => name == 'attachments'),
          hasLength(1),
          reason: '$table should have exactly one attachments column',
        );
        final raw = await db.customSelect('SELECT attachments FROM $table').getSingle();
        expect(raw.read<String>('attachments'), '[]');
      }

      final rule = (await db.select(db.taskRules).getSingle()).toModel();
      expect(rule.id, 'tr1');
      expect(rule.name, 'Service fork');
      expect(rule.notes, 'Lowers service');
      expect(rule.attachments, isEmpty);

      final entry = (await db.select(db.taskEntries).getSingle()).toModel();
      expect(entry.id, 'te1');
      expect(entry.name, 'Fork serviced');
      expect(entry.taskRule, 'tr1');
      expect(entry.attachments, isEmpty);
    });

    test('leaves tables that already have the column untouched', () async {
      const stored = '[{"id":"m","extension":".pdf","name":"Service Manual"}]';
      final db = await upgradeFromV20((seed) async {
        await seedTaskRows(seed);
        for (final table in taskTables) {
          await seed.customStatement("UPDATE $table SET attachments = '$stored'");
        }
      });

      final expected = [Attachment(id: 'm', extension: '.pdf', name: 'Service Manual')];
      for (final table in taskTables) {
        expect((await columnNames(db, table)).where((name) => name == 'attachments'), hasLength(1));
      }
      expect((await db.select(db.taskRules).getSingle()).attachments, expected);
      expect((await db.select(db.taskEntries).getSingle()).attachments, expected);
    });
  });
}
