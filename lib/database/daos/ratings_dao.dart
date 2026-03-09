import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ratings.dart';
import '../tables/adjustments.dart';

part 'ratings_dao.g.dart';

@DriftAccessor(tables: [Ratings, Adjustments])
class RatingsDao extends DatabaseAccessor<AppDatabase> with _$RatingsDaoMixin {
  RatingsDao(super.db);

  Stream<List<RatingDb>> watchAllRatings() => (select(ratings)..where((t) => t.isDeleted.equals(false))).watch();

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
  Future deleteRating(String id) => (update(ratings)..where((t) => t.id.equals(id))).write(RatingsCompanion(isDeleted: const Value(true), lastModified: Value(DateTime.now().toUtc())));

  Stream<List<RatingWithData>> watchAllRatingsWithData() {
    final query = (select(ratings)..where((t) => t.isDeleted.equals(false))).join([
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
}

class RatingWithData {
  final RatingDb rating;
  final List<AdjustmentDb> adjustments;
  RatingWithData({required this.rating, required this.adjustments});
}
