import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The v22 step replaces `components.preset_key` / `preset_damper_key` with
/// one `preset` column holding a [ComponentPreset].
///
/// Each case seeds a real database file at v21 and re-opens it through
/// [AppDatabase.forTesting], so drift runs the actual open-time upgrade.
void main() {
  const epochSeconds = 1700000000; // 2023-11-14, arbitrary but valid.
  const oldColumns = ['preset_key', 'preset_damper_key'];

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_components_preset_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  // Creates a current-schema database file, reshapes `components` to v21, lets
  // [seed] fill it, stamps it as v21 and re-opens it so drift runs the upgrade.
  Future<AppDatabase> upgradeFromV21(Future<void> Function(AppDatabase db) seed) async {
    final file = File(p.join(tempDir.path, 'v21.sqlite'));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.customStatement('ALTER TABLE components DROP COLUMN preset');
    for (final column in oldColumns) {
      await db.customStatement('ALTER TABLE components ADD COLUMN $column TEXT');
    }
    await seed(db);
    await db.customStatement('PRAGMA user_version = 21');
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

  group('v21 -> v22 components preset map', () {
    test('drops the key pair, adds an empty preset and keeps every other field', () async {
      const attachments = '[{"id":"m","extension":".pdf","name":"Service Manual"}]';
      final db = await upgradeFromV21((seed) async {
        await seed.customStatement(
          'INSERT INTO components (id, last_modified, name, component_type, notes, order_index, '
          'initial_distance, initial_moving_time, initial_activity_count, attachments, '
          'preset_key, preset_damper_key) '
          "VALUES ('c1', $epochSeconds, 'FOX 36 Factory', 'fork', 'Serviced in May', 3, "
          "1234.5, 3600, 7, '$attachments', 'fork-fox-36-factory-2025', 'grip_x2')",
        );
        await seed.customStatement(
          'INSERT INTO installations (id, component_id, parent, parent_type, date_time_u_t_c, date_time_local) '
          "VALUES ('i1', 'c1', 'b1', 'bike', $epochSeconds, $epochSeconds)",
        );
        await seed.customStatement(
          'INSERT INTO adjustments (id, component_id, order_index, name, type, json_payload) '
          "VALUES ('a1', 'c1', 0, 'Rebound', 'boolean', '{}')",
        );
      });

      final columns = await columnNames(db, 'components');
      expect(columns.where((name) => name == 'preset'), hasLength(1));
      expect(columns, isNot(contains(anyOf(oldColumns))));

      final row = await db.select(db.components).getSingle();
      expect(row.preset, isNull);

      final component = row.toModel();
      expect(component.id, 'c1');
      expect(component.name, 'FOX 36 Factory');
      expect(component.componentType, ComponentType.fork);
      expect(component.notes, 'Serviced in May');
      expect(component.orderIndex, 3);
      expect(component.initialStats.distance, 1234.5);
      expect(component.initialStats.movingTime, const Duration(hours: 1));
      expect(component.initialStats.activityCount, 7);
      expect(component.attachments, [Attachment(id: 'm', extension: '.pdf', name: 'Service Manual')]);

      // Recreating the table must not take the rows that point at it along.
      expect(await db.select(db.installations).get(), hasLength(1));
      expect(await db.select(db.adjustments).get(), hasLength(1));
    });

    test('stores and reads a preset after the upgrade', () async {
      final preset = ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '36', 'travel_mm': 160});
      final db = await upgradeFromV21((_) async {});

      await db.into(db.components).insert(
        Component(name: 'FOX 36', componentType: ComponentType.fork, installations: const [], preset: preset)
            .toCompanion(),
      );

      expect((await db.select(db.components).getSingle()).preset, preset);
    });

    test('reads a malformed stored preset as null', () async {
      final db = await upgradeFromV21((_) async {});
      await db.customStatement(
        'INSERT INTO components (id, last_modified, name, component_type, preset) '
        "VALUES ('c1', $epochSeconds, 'Fork', 'fork', '{not json')",
      );

      final row = await db.select(db.components).getSingle();
      expect(row.name, 'Fork');
      expect(row.preset, isNull);
    });
  });
}
