import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  group('DAOs Test', () {
    test('BikesDao - Insert and watch', () async {
      final bikes = await database.bikesDao.watchAllBikes().first;
      expect(bikes, isEmpty);

      final bike = Bike(id: 'bike1', name: 'Mtb', person: null);
      await database.bikesDao.insertBike(bike.toCompanion());

      final updatedBikes = await database.bikesDao.watchAllBikes().first;
      expect(updatedBikes, hasLength(1));
      expect(updatedBikes.first.name, 'Mtb');
    });

    test('ComponentsDao - Insert and watch', () async {
      final components = await database.componentsDao.watchAllComponents().first;
      expect(components, isEmpty);

      final component = Component(
        id: 'comp1', 
        name: 'Fork', 
        componentType: ComponentType.fork,
        adjustments: const [],
        installations: const [],
      );
      await database.componentsDao.insertComponent(component.toCompanion());

      final updatedComponents = await database.componentsDao.watchAllComponents().first;
      expect(updatedComponents, hasLength(1));
      expect(updatedComponents.first.name, 'Fork');
    });

    test('ComponentsDao - Delete (Soft Delete)', () async {
      final component = Component(
        id: 'comp1', 
        name: 'Fork', 
        componentType: ComponentType.fork,
        installations: const [],
      );
      await database.componentsDao.insertComponent(component.toCompanion());

      await database.componentsDao.deleteComponent('comp1');

      final activeComponents = await database.componentsDao.watchAllComponents().first;
      expect(activeComponents, isEmpty);

      final deletedComponents = await database.componentsDao.watchDeletedComponents().first;
      expect(deletedComponents, hasLength(1));
      expect(deletedComponents.first.isDeleted, true);
    });

    test('BikesDao - Get bike by ID', () async {
      final bike = Bike(id: 'bike1', name: 'Mtb', person: null);
      await database.bikesDao.insertBike(bike.toCompanion());

      final fetched = await database.bikesDao.getBike('bike1');
      expect(fetched, isNotNull);
      expect(fetched?.name, 'Mtb');

      final nonExistent = await database.bikesDao.getBike('none');
      expect(nonExistent, isNull);
    });
  });

  group('Unresolved adjustment values', () {
    final keep = BooleanAdjustment(name: 'Lockout', notes: null, unit: null);
    final removed = DurationAdjustment(name: 'Warm-up', notes: null, unit: null);
    const removedValue = DurationValue(Duration(minutes: 90));

    Component component(List<Adjustment> adjustments) => Component(
          id: 'comp1',
          name: 'Fork',
          componentType: ComponentType.fork,
          adjustments: adjustments,
          installations: const [],
        );

    Future<void> saveComponent(List<Adjustment> adjustments) {
      return database.componentsDao.updateComponentWithData(
        component: component(adjustments).toCompanion(),
        adjustmentsList: [
          for (final (i, adjustment) in adjustments.indexed)
            adjustment.toCompanion(componentId: 'comp1', orderIndex: i),
        ],
        installationsList: [],
      );
    }

    Future<Setup> readSetup() async {
      final setups = await database.setupsDao.watchAllSetupsWithValues().first;
      final entry = setups.single;
      return entry.setup.toModel(values: entry.values);
    }

    setUp(() async {
      await database.componentsDao.insertComponent(component(const []).toCompanion());
      await saveComponent([keep, removed]);
      await database.setupsDao.insertSetupWithValues(
        setup: Setup(
          id: 's1',
          datetime: DateTime.utc(2026, 9, 27),
          datetimeLocal: DateTime(2026, 9, 27),
          tags: const {},
          bike: 'bike1',
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ).toCompanion(),
        bikeValues: {keep.id: const BooleanValue(true), removed.id: removedValue},
        personValues: const {},
      );
      // Removing an adjustment hard-deletes its row but keeps the value rows.
      await saveComponent([keep]);
    });

    test('a value of a removed adjustment is read as unresolved', () async {
      final setup = await readSetup();
      expect(setup.bikeAdjustmentValues, {
        keep.id: const BooleanValue(true),
        removed.id: UnresolvedValue(removedValue.encode()),
      });
    });

    test('saving the setup writes the unresolved value back unchanged', () async {
      final setup = await readSetup();
      await database.setupsDao.updateSetupWithValues(
        setup: setup.toCompanion(),
        bikeValues: setup.bikeAdjustmentValues,
        personValues: setup.personAdjustmentValues,
      );

      expect((await readSetup()).bikeAdjustmentValues, setup.bikeAdjustmentValues);
      // Re-adding the adjustment resolves the untouched value again.
      await saveComponent([keep, removed]);
      expect((await readSetup()).bikeAdjustmentValues[removed.id], removedValue);
    });

    test('removing the unresolved value deletes its row', () async {
      final setup = await readSetup();
      await database.setupsDao.updateSetupWithValues(
        setup: setup.toCompanion(),
        bikeValues: {keep.id: const BooleanValue(true)},
        personValues: setup.personAdjustmentValues,
      );

      expect(await database.setupsDao.watchValuesForSetup('s1').first, hasLength(1));
      expect((await readSetup()).bikeAdjustmentValues, {keep.id: const BooleanValue(true)});
    });

    test('a rating value of a removed metric is read as unresolved', () async {
      await database.ratingEntriesDao.insertRatingEntryWithValues(
        entry: RatingEntry(
          id: 'r1',
          bike: 'bike1',
          setupId: 's1',
          dateTimeUTC: DateTime.utc(2026, 9, 27),
          dateTimeLocal: DateTime(2026, 9, 27),
          metricValues: const {},
        ).toCompanion(),
        values: {'removedMetric': const StepValue(4)},
      );

      final entry = (await database.ratingEntriesDao.watchAllRatingEntriesWithValues().first).single;
      expect(entry.entry.toModel(values: entry.values).metricValues, {'removedMetric': const UnresolvedValue('4')});
    });
  });
}
