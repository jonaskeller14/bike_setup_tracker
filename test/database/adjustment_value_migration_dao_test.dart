import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
const _bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

final _aged = DateTime(2000).toUtc();

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  group('SetupsDao.migrateAdjustmentValues', () {
    Future<void> addSetup(String id, Map<String, AdjustmentValue> values) async {
      await database.setupsDao.insertSetupWithValues(
        setup: Setup(
          id: id,
          datetime: DateTime.utc(2026, 9, 27),
          datetimeLocal: DateTime(2026, 9, 27),
          tags: const {},
          bike: 'bike1',
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ).toCompanion(),
        bikeValues: values,
        personValues: const {},
      );
      await (database.update(
        database.setups,
      )..where((t) => t.id.equals(id))).write(SetupsCompanion(lastModified: Value(_aged)));
    }

    Future<Map<String, String>> storedValues(String adjustmentId) async {
      final rows = await (database.select(
        database.setupAdjustmentValues,
      )..where((t) => t.adjustmentId.equals(adjustmentId))).get();
      return {for (final row in rows) row.setupId: row.value};
    }

    Future<DateTime> lastModified(String setupId) async {
      final setup = await (database.select(database.setups)..where((t) => t.id.equals(setupId))).getSingle();
      return setup.lastModified;
    }

    final psiToBar = ValueMigration('a', const [ConvertUnitStep(_psi, _bar)]);

    test('rewrites the values of live and soft-deleted setups', () async {
      await addSetup('live', {'a': const NumericalValue(10)});
      await addSetup('deleted', {'a': const NumericalValue(20)});
      await database.setupsDao.softDelete('deleted');

      await database.setupsDao.migrateAdjustmentValues('a', AdjustmentType.numerical, psiToBar);

      final stored = await storedValues('a');
      expect(
        (AdjustmentValue.decode(stored['live']!, AdjustmentType.numerical)! as NumericalValue).value,
        closeTo(0.689476, 1e-5),
      );
      expect(
        (AdjustmentValue.decode(stored['deleted']!, AdjustmentType.numerical)! as NumericalValue).value,
        closeTo(1.378951, 1e-5),
      );
    });

    test('only touches the migrated adjustment', () async {
      await addSetup('s', {'a': const NumericalValue(10), 'b': const NumericalValue(10)});

      await database.setupsDao.migrateAdjustmentValues('a', AdjustmentType.numerical, psiToBar);

      expect((await storedValues('b'))['s'], const NumericalValue(10).encode());
    });

    test('a null result deletes the row', () async {
      await addSetup('s1', {'a': const NumericalValue(10), 'b': const NumericalValue(1)});
      await addSetup('s2', {'a': const NumericalValue(10)});

      await database.setupsDao.migrateAdjustmentValues(
        'a',
        AdjustmentType.numerical,
        ValueMigration('a', const [ClearAllStep()]),
      );

      expect(await storedValues('a'), isEmpty);
      expect(await storedValues('b'), hasLength(1));
      expect(await lastModified('s1'), isNot(_aged));
    });

    test('lastModified is bumped only on setups whose value changed', () async {
      await addSetup('changed', {'a': const NumericalValue(100)});
      await addSetup('unchanged', {'a': const NumericalValue(3)});
      await addSetup('other', {'b': const NumericalValue(100)});

      await database.setupsDao.migrateAdjustmentValues(
        'a',
        AdjustmentType.numerical,
        ValueMigration('a', const [ClampToRangeStep(NumericalRange(double.negativeInfinity, 10))]),
      );

      expect(await lastModified('changed'), isNot(_aged));
      expect(await lastModified('unchanged'), _aged);
      expect(await lastModified('other'), _aged);
      expect((await storedValues('a'))['unchanged'], const NumericalValue(3).encode());
    });

    test('a no-op migration leaves rows and lastModified untouched', () async {
      await addSetup('s', {'a': const NumericalValue(10)});

      await database.setupsDao.migrateAdjustmentValues('a', AdjustmentType.numerical, ValueMigration('a', const []));

      expect(await lastModified('s'), _aged);
    });

    test('rows that do not decode with the type are left as stored', () async {
      await database
          .into(database.setupAdjustmentValues)
          .insert(
            SetupAdjustmentValuesCompanion.insert(setupId: 's1', adjustmentId: 'a', value: '"n/a"'),
          );
      await database
          .into(database.setupAdjustmentValues)
          .insert(
            SetupAdjustmentValuesCompanion.insert(setupId: 's2', adjustmentId: 'a', value: 'null'),
          );

      await database.setupsDao.migrateAdjustmentValues(
        'a',
        AdjustmentType.numerical,
        ValueMigration('a', const [ClearAllStep()]),
      );

      expect(await storedValues('a'), {'s1': '"n/a"', 's2': 'null'});
    });

    test('categorical values round-trip through a rename', () async {
      await addSetup('s1', {
        'a': CategoricalValue(const ['Soft', 'Firm']),
      });
      await addSetup('s2', {
        'a': CategoricalValue(const ['Firm']),
      });

      await database.setupsDao.migrateAdjustmentValues(
        'a',
        AdjustmentType.categorical,
        ValueMigration('a', [
          MapOptionsStep(const {'Soft': 'Plush'}),
        ]),
      );

      final stored = await storedValues('a');
      expect(stored['s1'], CategoricalValue(const ['Plush', 'Firm']).encode());
      expect(stored['s2'], CategoricalValue(const ['Firm']).encode());
      expect(await lastModified('s2'), _aged);
    });

    test('step values round-trip through a snap', () async {
      await addSetup('s', {'a': const StepValue(7)});

      await database.setupsDao.migrateAdjustmentValues(
        'a',
        AdjustmentType.step,
        ValueMigration('a', const [ClampToRangeStep(StepGrid(0, 20, 5))]),
      );

      expect((await storedValues('a'))['s'], const StepValue(5).encode());
    });
  });

  group('getDeletedValuesFor', () {
    test('returns only soft-deleted setups holding a value for the adjustment', () async {
      Future<void> addSetup(String id, String? name, Map<String, AdjustmentValue> values) =>
          database.setupsDao.insertSetupWithValues(
            setup: Setup(
              id: id,
              name: name,
              datetime: DateTime.utc(2026, 9, 27),
              datetimeLocal: DateTime(2026, 9, 27, 8),
              tags: const {},
              bike: 'bike1',
              person: null,
              bikeAdjustmentValues: const {},
              personAdjustmentValues: const {},
            ).toCompanion(),
            bikeValues: values,
            personValues: const {},
          );
      await addSetup('live', 'Live', {'a': const NumericalValue(1)});
      await addSetup('deleted', 'Gone', {'a': const NumericalValue(2), 'b': const NumericalValue(3)});
      await addSetup('deleted-other', null, {'b': const NumericalValue(4)});
      await database.setupsDao.softDelete('deleted');
      await database.setupsDao.softDelete('deleted-other');

      final rows = await database.setupsDao.getDeletedValuesFor('a');

      expect(rows, hasLength(1));
      expect(rows.single.recordId, 'deleted');
      expect(rows.single.name, 'Gone');
      expect(rows.single.dateTimeLocal, DateTime(2026, 9, 27, 8));
      expect(rows.single.rawValue, const NumericalValue(2).encode());
    });
  });
}
