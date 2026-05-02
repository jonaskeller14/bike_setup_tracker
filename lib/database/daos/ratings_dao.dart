import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/adjustments.dart';
import '../tables/ratings.dart';
import 'soft_delete_dao_mixin.dart';

part 'ratings_dao.g.dart';

@DriftAccessor(tables: [Ratings, Adjustments])
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

  Stream<List<AdjustmentDb>> watchAdjustmentsForRating(String ratingId) {
    return (select(adjustments)
          ..where((t) => t.ratingId.equals(ratingId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<int> insertRating(RatingsCompanion entry) => into(ratings).insert(entry);
  Future updateRating(RatingsCompanion entry) => update(ratings).replace(entry);
  Future<int> deleteRating(String id) => softDelete(id);

  Stream<List<RatingWithData>> watchAllRatingsWithData() {
    final query = (select(ratings)
          ..where((t) => isDeletedColumn.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: ratings.orderIndex)]))
        .join([
      leftOuterJoin(adjustments, adjustments.ratingId.equalsExp(ratings.id)),
    ]);

    return query.watch().map((rows) {
      final Map<String, RatingWithData> grouped = {};
      for (final row in rows) {
        final rating = row.readTable(ratings);
        final adjustment = row.readTableOrNull(adjustments);

        final entry = grouped.putIfAbsent(
          rating.id,
          () => RatingWithData(rating: rating, adjustments: []),
        );
        if (adjustment != null && !entry.adjustments.any((a) => a.id == adjustment.id)) {
          entry.adjustments.add(adjustment);
        }
      }
      for (final entry in grouped.values) {
        entry.adjustments.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }
      return grouped.values.toList();
    });
  }

  Future<void> insertRatingWithData({
    required RatingsCompanion rating,
    required List<AdjustmentsCompanion> adjustmentsList,
  }) async {
    await transaction(() async {
      await into(ratings).insert(rating);
      for (final adj in adjustmentsList) {
        await into(adjustments).insert(adj);
      }
    });
  }

  Future<void> updateRatingWithData({
    required RatingsCompanion rating,
    required List<AdjustmentsCompanion> adjustmentsList,
  }) async {
    await transaction(() async {
      await update(ratings).replace(rating);
      await (delete(adjustments)..where((t) => t.ratingId.equals(rating.id.value))).go();
      for (final adj in adjustmentsList) {
        await into(adjustments).insert(adj);
      }
    });
  }

  Future<List<RatingWithData>> getAllRatingsWithDataBypass() async {
    final query = select(ratings).join([
      leftOuterJoin(adjustments, adjustments.ratingId.equalsExp(ratings.id)),
    ]);

    final rows = await query.get();
    final Map<String, RatingWithData> grouped = {};
    for (final row in rows) {
      final rating = row.readTable(ratings);
      final adjustment = row.readTableOrNull(adjustments);

      final entry = grouped.putIfAbsent(
        rating.id,
        () => RatingWithData(rating: rating, adjustments: []),
      );
      if (adjustment != null && !entry.adjustments.any((a) => a.id == adjustment.id)) {
        entry.adjustments.add(adjustment);
      }
    }
    for (final entry in grouped.values) {
      entry.adjustments.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
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
  final List<AdjustmentDb> adjustments;
  RatingWithData({required this.rating, required this.adjustments});
}
