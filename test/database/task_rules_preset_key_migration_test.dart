import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The v23 step adds a nullable `task_rules.preset_key`.
///
/// Each case seeds a real database file at v22 and re-opens it through
/// [AppDatabase.forTesting], so drift runs the actual open-time upgrade.
void main() {
  const epochSeconds = 1700000000; // 2023-11-14, arbitrary but valid.

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_task_rules_preset_key_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  // Creates a current-schema database file, drops `preset_key` to get v22, lets
  // [seed] fill it, stamps it as v22 and re-opens it so drift runs the upgrade.
  Future<AppDatabase> upgradeFromV22(Future<void> Function(AppDatabase db) seed) async {
    final file = File(p.join(tempDir.path, 'v22.sqlite'));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('ALTER TABLE task_rules DROP COLUMN preset_key');
    await seed(db);
    await db.customStatement('PRAGMA user_version = 22');
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

  group('v22 -> v23 task_rules preset_key', () {
    test('adds a null preset_key and keeps every other field', () async {
      const interval = '{"type":"distance","meters":500000.0}';
      final db = await upgradeFromV22((seed) async {
        await seed.customStatement(
          'INSERT INTO task_rules (id, last_modified, component_id, name, notes, priority, tags, '
          'interval, repeat) '
          "VALUES ('tr1', $epochSeconds, 'c1', 'Service fork', 'Lowers service', 'high', "
          "'[\"suspension\"]', '$interval', 0)",
        );
        await seed.customStatement(
          'INSERT INTO task_entries (id, last_modified, name, date_time_u_t_c, date_time_local, task_rule) '
          "VALUES ('te1', $epochSeconds, 'Fork serviced', $epochSeconds, $epochSeconds, 'tr1')",
        );
      });

      expect((await columnNames(db, 'task_rules')).where((name) => name == 'preset_key'), hasLength(1));

      final row = await db.select(db.taskRules).getSingle();
      expect(row.presetKey, isNull);

      final rule = row.toModel();
      expect(rule.id, 'tr1');
      expect(rule.association, const ComponentTaskAssociation('c1'));
      expect(rule.name, 'Service fork');
      expect(rule.notes, 'Lowers service');
      expect(rule.priority, TaskPriority.high);
      expect(rule.tags, {'suspension'});
      expect(rule.interval, const DistanceThreshold(500000));
      expect(rule.repeat, isFalse);
      expect(rule.presetKey, isNull);
      expect(await db.select(db.taskEntries).get(), hasLength(1));
    });

    test('stores and reads a presetKey after the upgrade', () async {
      final db = await upgradeFromV22((_) async {});
      final rule = TaskRule(
        name: 'Replace chain',
        tags: const {},
        association: const ComponentTaskAssociation('c1'),
        presetKey: 'chain:replace',
      );

      await db.into(db.taskRules).insert(rule.toCompanion());

      expect((await db.select(db.taskRules).getSingle()).toModel().presetKey, 'chain:replace');
    });
  });
}
