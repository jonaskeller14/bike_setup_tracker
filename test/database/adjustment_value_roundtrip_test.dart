import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

/// End-to-end DB round-trip for adjustment values: write via the setups DAO
/// (`encodeAdjustmentValue`) and read back via the mapper (`decodeAdjustmentValue`).
///
/// Since schema v11 every value is stored JSON-encoded, so the stored shape is
/// structural: a *text* value which happens to be valid JSON is never decoded
/// into a `List` (which would later crash a text field), while a categorical
/// value round-trips as `List<String>`. A non-JSON row (a legacy value that
/// somehow escaped the v11 migration) degrades gracefully via the decoder's
/// fallback rather than crashing the load.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    // Insert value rows without seeding parent bike/component/adjustment FKs.
    await db.customStatement('PRAGMA foreign_keys = OFF');
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertAdjustment(String id, String type, String jsonPayload) {
    return db.customStatement(
      'INSERT INTO adjustments (id, component_id, order_index, name, type, json_payload) '
      "VALUES ('$id', 'comp1', 0, '$id', '$type', '$jsonPayload')",
    );
  }

  Setup bareSetup() => Setup(
        id: 's1',
        datetime: DateTime.utc(2024, 1, 1),
        datetimeLocal: DateTime(2024, 1, 1),
        tags: const {},
        bike: 'bike1',
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
      );

  Future<Setup> readSetup() async {
    final typed = await db.setupsDao.watchTypedValuesForSetup('s1').first;
    final row = await db.setupsDao.getSetup('s1');
    return row!.toModel(values: typed);
  }

  /// Persists [bikeValues] through the normal write path (encode).
  Future<Setup> roundTrip(Map<String, dynamic> bikeValues) async {
    final setup = bareSetup();
    await db.setupsDao.insertSetupWithValues(
      setup: setup.toCompanion(),
      bikeValues: bikeValues,
      personValues: const {},
    );
    return readSetup();
  }

  /// Inserts a bare setup, then writes a raw (unencoded) value string directly,
  /// simulating a legacy row written before the list encoding existed.
  Future<Setup> withLegacyValue(String adjustmentId, String rawValue) async {
    await db.setupsDao.insertSetupWithValues(
      setup: bareSetup().toCompanion(),
      bikeValues: const {},
      personValues: const {},
    );
    await db.customStatement(
      'INSERT INTO setup_adjustment_values (setup_id, adjustment_id, value) '
      "VALUES ('s1', '$adjustmentId', '$rawValue')",
    );
    return readSetup();
  }

  test('a JSON-looking text value round-trips as a String, categorical as a List', () async {
    await insertAdjustment('txt1', 'text', '{"version":1}');
    await insertAdjustment('cat1', 'categorical',
        '{"version":2,"multiSelect":true,"options":["Front","Rear"]}');

    final restored = await roundTrip({
      'txt1': '["abc"]', // user literally typed this into a text field
      'cat1': ['Front', 'Rear'],
    });

    expect(restored.bikeAdjustmentValues['txt1'], isA<String>());
    expect(restored.bikeAdjustmentValues['txt1'], '["abc"]');
    expect(restored.bikeAdjustmentValues['cat1'], isA<List<String>>());
    expect(restored.bikeAdjustmentValues['cat1'], ['Front', 'Rear']);
  });

  test('single-select categorical round-trips as a one-element List', () async {
    await insertAdjustment('cat1', 'categorical', '{"version":1,"options":["Open","Firm"]}');
    final restored = await roundTrip({'cat1': ['Open']});
    expect(restored.bikeAdjustmentValues['cat1'], isA<List<String>>());
    expect(restored.bikeAdjustmentValues['cat1'], ['Open']);
  });

  test('a categorical value written as a scalar String reads back as a wrapped List', () async {
    // Multi-select never shipped, so callers still pass a plain option String;
    // it is JSON-encoded as a scalar and read back canonicalised to List<String>
    // (the `type` column, not the storage shape, marks it as categorical).
    await insertAdjustment('cat1', 'categorical', '{"version":1,"options":["Brand A","Brand B"]}');
    final restored = await roundTrip({'cat1': 'Brand A'});
    expect(restored.bikeAdjustmentValues['cat1'], isA<List<String>>());
    expect(restored.bikeAdjustmentValues['cat1'], ['Brand A']);
  });

  test('a non-JSON categorical row (un-migrated legacy value) falls back to a wrapped list', () async {
    // Every row is JSON after the v11 migration; this exercises the decoder's
    // defensive fallback so a stray plain-string row degrades gracefully rather
    // than crashing the whole setup load.
    await insertAdjustment('cat1', 'categorical', '{"version":1,"options":["Open","Firm"]}');
    final restored = await withLegacyValue('cat1', 'Open');
    expect(restored.bikeAdjustmentValues['cat1'], ['Open']);
  });

  test('a non-JSON text row (un-migrated legacy value) falls back to the raw string', () async {
    await insertAdjustment('txt1', 'text', '{"version":1}');
    final restored = await withLegacyValue('txt1', 'plain notes');
    expect(restored.bikeAdjustmentValues['txt1'], isA<String>());
    expect(restored.bikeAdjustmentValues['txt1'], 'plain notes');
  });
}
