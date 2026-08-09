import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/rating_metrics.dart';
import '../tables/ratings.dart';
import 'soft_delete_dao_mixin.dart';

part 'ratings_dao.g.dart';

@DriftAccessor(tables: [Ratings, RatingMetrics])
class RatingsDao extends DatabaseAccessor<AppDatabase> with _$RatingsDaoMixin, SoftDeletableDaoMixin<Ratings, RatingDb, RatingsCompanion> {
  RatingsDao(super.db);

  @override TableInfo<Ratings, RatingDb> get softDeletableTable => ratings;
  @override Expression<bool> get isDeletedColumn => ratings.isDeleted;
  @override Expression<String> get idColumn => ratings.id;
  @override RatingsCompanion createSoftDeleteCompanion() => RatingsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc()));

  Stream<List<RatingDb>> watchAllRatings() => watchAllActive();
  Stream<List<RatingDb>> watchDeletedRatings() => watchAllDeleted();

  Future<RatingDb?> getRating(String id) {
    return (select(ratings)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<RatingMetricDb>> watchMetricsForRating(String ratingId) {
    return (select(ratingMetrics)
          ..where((t) => t.ratingId.equals(ratingId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<int> insertRating(RatingsCompanion entry) => into(ratings).insert(entry);
  Future<bool> updateRating(RatingsCompanion entry) => update(ratings).replace(entry);
  Future<int> deleteRating(String id) => softDelete(id);

  Stream<List<RatingWithData>> watchAllRatingsWithData() {
    final query = (select(ratings)
          ..where((t) => isDeletedColumn.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: ratings.orderIndex)]))
        .join([
      leftOuterJoin(ratingMetrics, ratingMetrics.ratingId.equalsExp(ratings.id)),
    ]);

    return query.watch().map((rows) => _group(rows));
  }

  Future<void> insertRatingWithData({
    required RatingsCompanion rating,
    required List<RatingMetricsCompanion> metricsList,
  }) async {
    await transaction(() async {
      await into(ratings).insert(rating);
      for (final metric in metricsList) {
        await into(ratingMetrics).insert(metric);
      }
    });
  }

  Future<void> updateRatingWithData({
    required RatingsCompanion rating,
    required List<RatingMetricsCompanion> metricsList,
  }) async {
    await transaction(() async {
      await update(ratings).replace(rating);
      await (delete(ratingMetrics)..where((t) => t.ratingId.equals(rating.id.value))).go();
      for (final metric in metricsList) {
        await into(ratingMetrics).insert(metric);
      }
    });
  }

  Future<List<RatingWithData>> getAllRatingsWithDataBypass() async {
    final query = select(ratings).join([
      leftOuterJoin(ratingMetrics, ratingMetrics.ratingId.equalsExp(ratings.id)),
    ]);
    return _group(await query.get());
  }

  List<RatingWithData> _group(List<TypedResult> rows) {
    final Map<String, RatingWithData> grouped = {};
    for (final row in rows) {
      final rating = row.readTable(ratings);
      final metric = row.readTableOrNull(ratingMetrics);

      final entry = grouped.putIfAbsent(
        rating.id,
        () => RatingWithData(rating: rating, metrics: []),
      );
      if (metric != null && !entry.metrics.any((m) => m.id == metric.id)) {
        entry.metrics.add(metric);
      }
    }
    for (final entry in grouped.values) {
      entry.metrics.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    return grouped.values.toList();
  }

  Future<void> reorder(List<String> ids) async {
    await transaction(() async {
      for (int i = 0; i < ids.length; i++) {
        await (update(ratings)..where((t) => t.id.equals(ids[i])))
            .write(RatingsCompanion(orderIndex: Value(i)));
      }
    });
  }
}

class RatingWithData {
  final RatingDb rating;
  final List<RatingMetricDb> metrics;
  RatingWithData({required this.rating, required this.metrics});
}
