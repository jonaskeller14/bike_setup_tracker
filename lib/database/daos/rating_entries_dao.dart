import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/rating_entries.dart';
import '../tables/rating_entry_values.dart';
import '../tables/rating_metrics.dart';
import 'soft_delete_dao_mixin.dart';

part 'rating_entries_dao.g.dart';

@DriftAccessor(tables: [RatingEntries, RatingEntryValues, RatingMetrics])
class RatingEntriesDao extends DatabaseAccessor<AppDatabase> with _$RatingEntriesDaoMixin, SoftDeletableDaoMixin<RatingEntries, RatingEntryDb, RatingEntriesCompanion> {
  RatingEntriesDao(super.db);

  @override TableInfo<RatingEntries, RatingEntryDb> get softDeletableTable => ratingEntries;
  @override Expression<bool> get isDeletedColumn => ratingEntries.isDeleted;
  @override Expression<String> get idColumn => ratingEntries.id;
  @override RatingEntriesCompanion createSoftDeleteCompanion() => RatingEntriesCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<RatingEntryDb>> watchAllRatingEntries() => watchAllActive();
  Stream<List<RatingEntryDb>> watchDeletedRatingEntries() => watchAllDeleted();

  Future<RatingEntryDb?> getRatingEntry(String id) {
    return (select(ratingEntries)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<RatingEntryWithValues>> watchAllRatingEntriesWithValues() {
    final query = (select(ratingEntries)..where((t) => isDeletedColumn.equals(false))).join([
      leftOuterJoin(ratingEntryValues, ratingEntryValues.ratingEntryId.equalsExp(ratingEntries.id)),
      leftOuterJoin(ratingMetrics, ratingMetrics.id.equalsExp(ratingEntryValues.ratingMetricId)),
    ]);
    return query.watch().map(_group);
  }

  Future<List<RatingEntryWithValues>> getAllRatingEntriesWithValuesBypass() async {
    final query = select(ratingEntries).join([
      leftOuterJoin(ratingEntryValues, ratingEntryValues.ratingEntryId.equalsExp(ratingEntries.id)),
      leftOuterJoin(ratingMetrics, ratingMetrics.id.equalsExp(ratingEntryValues.ratingMetricId)),
    ]);
    return _group(await query.get());
  }

  List<RatingEntryWithValues> _group(List<TypedResult> rows) {
    final Map<String, RatingEntryWithValues> grouped = {};
    for (final row in rows) {
      final entry = row.readTable(ratingEntries);
      final value = row.readTableOrNull(ratingEntryValues);
      final metric = row.readTableOrNull(ratingMetrics);

      final bucket = grouped.putIfAbsent(entry.id, () => RatingEntryWithValues(entry: entry, values: []));
      if (value != null && metric != null) {
        bucket.values.add(TypedRatingEntryValue(value: value, metric: metric));
      }
    }
    return grouped.values.toList();
  }

  Future<int> insertRatingEntry(RatingEntriesCompanion entry) => into(ratingEntries).insert(entry);
  Future<bool> updateRatingEntry(RatingEntriesCompanion entry) => update(ratingEntries).replace(entry);
  Future<int> deleteRatingEntry(String id) => softDelete(id);

  Future<void> insertRatingEntryWithValues({
    required RatingEntriesCompanion entry,
    required Map<String, dynamic> values, // ratingMetricId -> value
  }) async {
    await transaction(() async {
      await insertRatingEntry(entry);
      await _upsertValues(entry.id.value, values);
    });
  }

  Future<void> updateRatingEntryWithValues({
    required RatingEntriesCompanion entry,
    required Map<String, dynamic> values,
  }) async {
    await transaction(() async {
      await updateRatingEntry(entry);
      await (delete(ratingEntryValues)..where((t) => t.ratingEntryId.equals(entry.id.value))).go();
      await _upsertValues(entry.id.value, values);
    });
  }

  Future<void> _upsertValues(String entryId, Map<String, dynamic> values) async {
    for (final e in values.entries) {
      if (e.value == null) continue;
      await into(ratingEntryValues).insertOnConflictUpdate(RatingEntryValuesCompanion(
        ratingEntryId: Value(entryId),
        ratingMetricId: Value(e.key),
        value: Value(e.value.toString()),
      ));
    }
  }
}

class RatingEntryWithValues {
  final RatingEntryDb entry;
  final List<TypedRatingEntryValue> values;
  RatingEntryWithValues({required this.entry, required this.values});
}

class TypedRatingEntryValue {
  final RatingEntryValueDb value;
  final RatingMetricDb metric;
  TypedRatingEntryValue({required this.value, required this.metric});
}
