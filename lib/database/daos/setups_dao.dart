import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/setups.dart';
import '../tables/setup_adjustment_values.dart';
import '../tables/adjustments.dart';

part 'setups_dao.g.dart';

@DriftAccessor(tables: [Setups, SetupAdjustmentValues, Adjustments])
class SetupsDao extends DatabaseAccessor<AppDatabase> with _$SetupsDaoMixin {
  SetupsDao(super.db);

  Stream<List<SetupDb>> watchAllSetupsForBike(String bikeId) {
    return (select(setups)
          ..where((t) => t.bikeId.equals(bikeId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.datetime, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<SetupDb>> watchAllSetups() {
    return (select(setups)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Stream<List<SetupWithValues>> watchAllSetupsWithValues() {
    final query = select(setups).join([
      leftOuterJoin(setupAdjustmentValues, setupAdjustmentValues.setupId.equalsExp(setups.id)),
      leftOuterJoin(adjustments, adjustments.id.equalsExp(setupAdjustmentValues.adjustmentId)),
    ])..where(setups.isDeleted.equals(false));

    return query.watch().map((rows) {
      final Map<String, SetupWithValues> grouped = {};
      for (final row in rows) {
        final setup = row.readTable(setups);
        final value = row.readTableOrNull(setupAdjustmentValues);
        final adjustment = row.readTableOrNull(adjustments);
        
        final entry = grouped.putIfAbsent(setup.id, () => SetupWithValues(setup: setup, values: []));
        if (value != null && adjustment != null) {
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
  Future updateSetup(SetupsCompanion entry) => update(setups).replace(entry);
  Future deleteSetup(String id) => (update(setups)..where((t) => t.id.equals(id))).write(const SetupsCompanion(isDeleted: Value(true)));

  // Value operations
  Future upsertSetupValue(SetupAdjustmentValuesCompanion entry) => into(setupAdjustmentValues).insertOnConflictUpdate(entry);
  Future deleteSetupValue(String setupId, String adjustmentId) => 
    (delete(setupAdjustmentValues)..where((t) => t.setupId.equals(setupId) & t.adjustmentId.equals(adjustmentId))).go();
}

class SetupWithValues {
  final SetupDb setup;
  final List<TypedSetupValue> values;
  SetupWithValues({required this.setup, required this.values});
}

class TypedSetupValue {
  final SetupAdjustmentValueDb value;
  final AdjustmentDb adjustment;
  TypedSetupValue({required this.value, required this.adjustment});
}
