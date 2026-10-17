import 'package:drift/drift.dart';

import '../../models/adjustment/adjustment.dart';
import '../app_database.dart';
import '../tables/adjustments.dart';
import '../tables/setup_adjustment_values.dart';
import '../tables/setups.dart';
import 'deleted_record_value.dart';
import 'soft_delete_dao_mixin.dart';

part 'setups_dao.g.dart';

@DriftAccessor(tables: [Setups, SetupAdjustmentValues, Adjustments])
class SetupsDao extends DatabaseAccessor<AppDatabase> with _$SetupsDaoMixin, SoftDeletableDaoMixin<Setups, SetupDb, SetupsCompanion> {
  SetupsDao(super.db);

  @override TableInfo<Setups, SetupDb> get softDeletableTable => setups;
  @override Expression<bool> get isDeletedColumn => setups.isDeleted;
  @override Expression<String> get idColumn => setups.id;
  @override SetupsCompanion createSoftDeleteCompanion() => SetupsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<SetupDb>> watchAllSetupsForBike(String bikeId) {
    return (select(setups)
          ..where((t) => t.bikeId.equals(bikeId))
          ..orderBy([(t) => OrderingTerm(expression: t.datetime, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<SetupDb>> watchAllSetups() => watchAllActive();
  Stream<List<SetupDb>> watchDeletedSetups() => watchAllDeleted();

  Stream<List<SetupWithValues>> watchAllSetupsWithValues() {
    final query = (select(setups)..where((t) => isDeletedColumn.equals(false))).join([
      leftOuterJoin(setupAdjustmentValues, setupAdjustmentValues.setupId.equalsExp(setups.id)),
      leftOuterJoin(adjustments, adjustments.id.equalsExp(setupAdjustmentValues.adjustmentId)),
    ]);

    return query.watch().map((rows) {
      final Map<String, SetupWithValues> grouped = {};
      for (final row in rows) {
        final setup = row.readTable(setups);
        final value = row.readTableOrNull(setupAdjustmentValues);
        final adjustment = row.readTableOrNull(adjustments);
        
        final entry = grouped.putIfAbsent(setup.id, () => SetupWithValues(setup: setup, values: []));
        if (value != null) {
          entry.values.add(TypedSetupValue(value: value, adjustment: adjustment));
        }
      }
      return grouped.values.toList();
    });
  }

  Future<SetupDb?> getSetup(String id) {
    return (select(setups)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<SetupAdjustmentValueDb>> watchValuesForSetup(String setupId) {
    return (select(setupAdjustmentValues)..where((t) => t.setupId.equals(setupId))).watch();
  }

  // Operation to fetch a setup along with its values and the adjustments they belong to
  // This helps in mapping back to the bikeAdjustmentValues/personAdjustmentValues/ratingAdjustmentValues
  Stream<List<TypedSetupValue>> watchTypedValuesForSetup(String setupId) {
    final query = select(setupAdjustmentValues).join([
      innerJoin(adjustments, adjustments.id.equalsExp(setupAdjustmentValues.adjustmentId)),
    ])..where(setupAdjustmentValues.setupId.equals(setupId));

    return query.watch().map((rows) {
      return rows.map((row) {
        return TypedSetupValue(
          value: row.readTable(setupAdjustmentValues),
          adjustment: row.readTable(adjustments),
        );
      }).toList();
    });
  }

  Future<int> insertSetup(SetupsCompanion entry) => into(setups).insert(entry);
  Future<bool> updateSetup(SetupsCompanion entry) => update(setups).replace(entry);
  Future<int> deleteSetup(String id) => softDelete(id);

  // Value operations
  Future<void> upsertSetupValue(SetupAdjustmentValuesCompanion entry) => into(setupAdjustmentValues).insertOnConflictUpdate(entry);
  
  Future<void> deleteSetupValue(String setupId, String adjustmentId) => 
    (delete(setupAdjustmentValues)..where((t) => t.setupId.equals(setupId) & t.adjustmentId.equals(adjustmentId))).go();

  Future<void> insertSetupWithValues({
    required SetupsCompanion setup,
    required Map<String, AdjustmentValue> bikeValues,
    required Map<String, AdjustmentValue> personValues,
  }) async {
    await transaction(() async {
      await insertSetup(setup);
      await _upsertValuesMap(setup.id.value, bikeValues);
      await _upsertValuesMap(setup.id.value, personValues);
    });
  }

  Future<void> updateSetupWithValues({
    required SetupsCompanion setup,
    required Map<String, AdjustmentValue> bikeValues,
    required Map<String, AdjustmentValue> personValues,
  }) async {
    await transaction(() async {
      await updateSetup(setup);
      // Clear old values for this setup to ensure map deletions are reflected
      await (delete(setupAdjustmentValues)..where((t) => t.setupId.equals(setup.id.value))).go();
      await _upsertValuesMap(setup.id.value, bikeValues);
      await _upsertValuesMap(setup.id.value, personValues);
    });
  }

  /// Rewrites every stored value of [adjustmentId] (an adjustment of [type])
  /// with [migration], soft-deleted setups included, and bumps `lastModified`
  /// on each setup whose value changed so backup merges propagate the change.
  /// A value the migration clears loses its row; undecodable rows are left as-is.
  Future<void> migrateAdjustmentValues(
    String adjustmentId,
    AdjustmentType type,
    ValueMigration migration,
  ) async {
    final rows = await (select(setupAdjustmentValues)
          ..where((t) => t.adjustmentId.equals(adjustmentId)))
        .get();

    final now = DateTime.now().toUtc();
    final touchedSetupIds = <String>{};
    for (final row in rows) {
      final decoded = AdjustmentValue.decode(row.value, type);
      if (decoded == null || decoded is UnresolvedValue) continue;
      final migrated = migration.apply(decoded);
      if (migrated == decoded) continue;
      if (migrated == null) {
        await (delete(setupAdjustmentValues)
              ..where((t) => t.setupId.equals(row.setupId) & t.adjustmentId.equals(adjustmentId)))
            .go();
      } else {
        await (update(setupAdjustmentValues)
              ..where((t) => t.setupId.equals(row.setupId) & t.adjustmentId.equals(adjustmentId)))
            .write(SetupAdjustmentValuesCompanion(value: Value(migrated.encode())));
      }
      touchedSetupIds.add(row.setupId);
    }
    for (final setupId in touchedSetupIds) {
      await (update(setups)..where((t) => t.id.equals(setupId)))
          .write(SetupsCompanion(lastModified: Value(now)));
    }
  }

  /// The stored values of [adjustmentId] in soft-deleted setups; the in-memory
  /// setups hold live records only.
  Future<List<DeletedRecordValue>> getDeletedValuesFor(String adjustmentId) async {
    final query = select(setups).join([
      innerJoin(setupAdjustmentValues, setupAdjustmentValues.setupId.equalsExp(setups.id)),
    ])..where(isDeletedColumn.equals(true) & setupAdjustmentValues.adjustmentId.equals(adjustmentId));
    return [
      for (final row in await query.get())
        DeletedRecordValue(
          recordId: row.readTable(setups).id,
          name: row.readTable(setups).name,
          dateTimeLocal: row.readTable(setups).datetimeLocal,
          rawValue: row.readTable(setupAdjustmentValues).value,
        ),
    ];
  }

  Future<void> _upsertValuesMap(String setupId, Map<String, AdjustmentValue> valuesMap) async {
    for (var entry in valuesMap.entries) {
      await upsertSetupValue(SetupAdjustmentValuesCompanion(
        setupId: Value(setupId),
        adjustmentId: Value(entry.key),
        value: Value(entry.value.encode()),
      ));
    }
  }

  Future<List<SetupWithValues>> getAllSetupsWithValuesBypass() async {
    final query = select(setups).join([
      leftOuterJoin(setupAdjustmentValues, setupAdjustmentValues.setupId.equalsExp(setups.id)),
      leftOuterJoin(adjustments, adjustments.id.equalsExp(setupAdjustmentValues.adjustmentId)),
    ]);

    final rows = await query.get();
    final Map<String, SetupWithValues> grouped = {};
    for (final row in rows) {
      final setup = row.readTable(setups);
      final value = row.readTableOrNull(setupAdjustmentValues);
      final adjustment = row.readTableOrNull(adjustments);
      
      final entry = grouped.putIfAbsent(setup.id, () => SetupWithValues(setup: setup, values: []));
      if (value != null) {
        entry.values.add(TypedSetupValue(value: value, adjustment: adjustment));
      }
    }
    return grouped.values.toList();
  }
}

class SetupWithValues {
  final SetupDb setup;
  final List<TypedSetupValue> values;
  SetupWithValues({required this.setup, required this.values});
}

class TypedSetupValue {
  final SetupAdjustmentValueDb value;
  /// `null` when the adjustment row is gone; the value is then unresolved.
  final AdjustmentDb? adjustment;
  TypedSetupValue({required this.value, required this.adjustment});
}
