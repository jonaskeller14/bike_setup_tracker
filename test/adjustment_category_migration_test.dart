import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdjustmentCategory removal migration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.memory();
    });

    tearDown(() async {
      await db.close();
    });

    // Helper to get column names for a table via PRAGMA
    Future<Set<String>> columnNames(String table) async {
      final rows = await db
          .customSelect('PRAGMA table_info($table)')
          .get();
      return rows.map((r) => r.read<String>('name')).toSet();
    }

    group('DB schema v7: category column absent', () {
      test('adjustments table has no category column', () async {
        final cols = await columnNames('adjustments');
        expect(cols, isNot(contains('category')));
        expect(cols, containsAll(['id', 'name', 'type', 'json_payload']));
      });

      test('rating_metrics table has no category column', () async {
        final cols = await columnNames('rating_metrics');
        expect(cols, isNot(contains('category')));
        expect(cols, containsAll(['id', 'rating_id', 'name', 'type', 'json_payload']));
      });

      test('insert and read adjustment row without category', () async {
        // FK checks are ON by default in Drift memory DB; disable so we can
        // insert without a parent component/person row.
        await db.customStatement('PRAGMA foreign_keys = OFF');
        await db.customStatement(
          'INSERT INTO adjustments (id, component_id, order_index, name, type, json_payload) '
          "VALUES ('adj1', 'comp1', 0, 'Rebound', 'step', '{\"step\":1,\"min\":0,\"max\":20,\"visualization\":\"slider\"}')",
        );
        final row = await (db.select(db.adjustments)
              ..where((t) => t.id.equals('adj1')))
            .getSingle();

        expect(row.id, 'adj1');
        expect(row.name, 'Rebound');
        expect(row.type, AdjustmentType.step);
      });

      test('insert and read rating_metric row without category', () async {
        await db.customStatement('PRAGMA foreign_keys = OFF');
        await db.customStatement(
          'INSERT INTO ratings (id, is_deleted, last_modified, name, filter_type, order_index) '
          "VALUES ('r1', 0, 0, 'Ride Feel', 'global', 0)",
        );
        await db.customStatement(
          'INSERT INTO rating_metrics (id, rating_id, order_index, weight, name, type, json_payload) '
          "VALUES ('m1', 'r1', 0, 1.0, 'Grip', 'step', '{\"step\":1,\"min\":0,\"max\":10,\"visualization\":\"slider\"}')",
        );
        final row = await (db.select(db.ratingMetrics)
              ..where((t) => t.id.equals('m1')))
            .getSingle();

        expect(row.id, 'm1');
        expect(row.name, 'Grip');
        expect(row.type, AdjustmentType.step);
      });
    });

    group('JSON migration: old JSON with category key still parses', () {
      test('BooleanAdjustment silently ignores legacy category field', () {
        final adj = Adjustment.fromJson({
          'version': 1,
          'type': 'boolean',
          'id': 'adj1',
          'name': 'Lockout',
          'notes': null,
          'unit': null,
          'category': 'AdjustmentCategory.component',
        });
        expect(adj, isA<BooleanAdjustment>());
        expect(adj.name, 'Lockout');
      });

      test('NumericalAdjustment silently ignores legacy category field', () {
        final adj = Adjustment.fromJson({
          'version': 1,
          'type': 'numerical',
          'id': 'adj2',
          'name': 'Pressure',
          'notes': null,
          'unit': 'psi',
          'min': 0.0,
          'max': 200.0,
          'category': 'AdjustmentCategory.component',
        }) as NumericalAdjustment;
        expect(adj.name, 'Pressure');
        expect(adj.unit, 'psi');
        expect(adj.min, 0.0);
        expect(adj.max, 200.0);
      });

      test('StepAdjustment silently ignores legacy category field', () {
        final adj = Adjustment.fromJson({
          'version': 1,
          'type': 'step',
          'id': 'adj3',
          'name': 'Rebound',
          'notes': null,
          'unit': null,
          'step': 1,
          'min': 0,
          'max': 20,
          'visualization': 'slider',
          'category': 'AdjustmentCategory.component',
        }) as StepAdjustment;
        expect(adj.name, 'Rebound');
        expect(adj.min, 0);
        expect(adj.max, 20);
      });

      test('CategoricalAdjustment silently ignores legacy category field', () {
        final adj = Adjustment.fromJson({
          'version': 1,
          'type': 'categorical',
          'id': 'adj4',
          'name': 'Mode',
          'notes': null,
          'unit': null,
          'options': ['Open', 'Firm', 'Locked'],
          'category': 'AdjustmentCategory.component',
        }) as CategoricalAdjustment;
        expect(adj.name, 'Mode');
        expect(adj.options, containsAll(['Open', 'Firm', 'Locked']));
      });

      test('TextAdjustment silently ignores legacy category field', () {
        final adj = Adjustment.fromJson({
          'version': 1,
          'type': 'text',
          'id': 'adj5',
          'name': 'Note',
          'notes': null,
          'unit': null,
          'category': 'AdjustmentCategory.body',
        });
        expect(adj, isA<TextAdjustment>());
        expect(adj.name, 'Note');
      });

      test('DurationAdjustment silently ignores legacy category field', () {
        final adj = Adjustment.fromJson({
          'version': 1,
          'type': 'duration',
          'id': 'adj6',
          'name': 'Service',
          'notes': null,
          'unit': null,
          'category': 'AdjustmentCategory.rating',
        });
        expect(adj, isA<DurationAdjustment>());
        expect(adj.name, 'Service');
      });

      test('All 5 former AdjustmentCategory values parse without error', () {
        for (final cat in [
          'AdjustmentCategory.component',
          'AdjustmentCategory.rating',
          'AdjustmentCategory.body',
          'AdjustmentCategory.nutrition',
          'AdjustmentCategory.equipment',
        ]) {
          expect(
            () => Adjustment.fromJson({
              'version': 1,
              'type': 'boolean',
              'id': 'test',
              'name': 'Test',
              'notes': null,
              'unit': null,
              'category': cat,
            }),
            returnsNormally,
            reason: 'Should parse category value: $cat',
          );
        }
      });
    });
  });
}
