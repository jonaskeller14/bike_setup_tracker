import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _ratingTables = ['rating_entry_values', 'rating_entries', 'rating_metrics', 'ratings'];

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bst_drop_rating_v2');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<Set<String>> tableNames(AppDatabase db) async {
    final rows = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  test('v24 -> v25 drops the rating v2 tables and keeps the rest of the data', () async {
    final file = File(p.join(tempDir.path, 'v24.sqlite'));

    final seed = AppDatabase.forTesting(NativeDatabase(file));
    final bike = Bike(id: 'b1', name: 'Bike', person: null);
    final grip = NumericalAdjustment(id: 'grip', name: 'Pressure', notes: null, unit: null, min: 0, max: 300);
    final component = Component(
      id: 'c1',
      name: 'Fork',
      componentType: ComponentType.fork,
      adjustments: [grip],
      installations: const [],
    );
    final setup = Setup(
      id: 's1',
      datetime: DateTime.utc(2026, 9, 27),
      datetimeLocal: DateTime(2026, 9, 27),
      tags: const {},
      bike: bike.id,
      person: null,
      bikeAdjustmentValues: {grip.id: const NumericalValue(85)},
      personAdjustmentValues: const {},
    );
    await seed.bikesDao.insertBike(bike.toCompanion());
    await seed.componentsDao.insertComponentWithData(
      component: component.toCompanion(),
      adjustmentsList: [grip.toCompanion(componentId: component.id, orderIndex: 0)],
      installationsList: const [],
    );
    await seed.setupsDao.insertSetupWithValues(
      setup: setup.toCompanion(),
      bikeValues: setup.bikeAdjustmentValues,
      personValues: setup.personAdjustmentValues,
    );
    // The v24 rating tables, reduced to the columns the rows below need.
    await seed.customStatement('CREATE TABLE ratings (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL)');
    await seed.customStatement('CREATE TABLE rating_metrics (id TEXT NOT NULL PRIMARY KEY, rating_id TEXT NOT NULL)');
    await seed.customStatement('CREATE TABLE rating_entries (id TEXT NOT NULL PRIMARY KEY, bike_id TEXT NOT NULL)');
    await seed.customStatement(
      'CREATE TABLE rating_entry_values '
      '(rating_entry_id TEXT NOT NULL, rating_metric_id TEXT NOT NULL, value TEXT NOT NULL)',
    );
    await seed.customStatement("INSERT INTO ratings VALUES ('r1', 'Feel')");
    await seed.customStatement("INSERT INTO rating_metrics VALUES ('m1', 'r1')");
    await seed.customStatement("INSERT INTO rating_entries VALUES ('e1', 'b1')");
    await seed.customStatement("INSERT INTO rating_entry_values VALUES ('e1', 'm1', '4')");
    expect(await tableNames(seed), containsAll(_ratingTables));
    await seed.customStatement('PRAGMA user_version = 24');
    await seed.close();

    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect((await tableNames(upgraded)).intersection(_ratingTables.toSet()), isEmpty);

    expect((await upgraded.bikesDao.watchAllBikes().first).map((b) => b.id), ['b1']);
    expect((await upgraded.componentsDao.watchAllComponents().first).map((c) => c.id), ['c1']);
    expect((await upgraded.select(upgraded.adjustments).get()).map((a) => a.id), ['grip']);
    expect((await upgraded.setupsDao.watchAllSetups().first).map((s) => s.id), ['s1']);
    final values = await upgraded.setupsDao.watchValuesForSetup('s1').first;
    expect(values.map((v) => v.adjustmentId), ['grip']);
  });
}
