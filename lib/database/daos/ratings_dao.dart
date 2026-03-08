import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ratings.dart';
import '../tables/adjustments.dart';

part 'ratings_dao.g.dart';

@DriftAccessor(tables: [Ratings, Adjustments])
class RatingsDao extends DatabaseAccessor<AppDatabase> with _$RatingsDaoMixin {
  RatingsDao(super.db);

  Stream<List<RatingDb>> watchAllRatings() {
    return (select(ratings)..where((t) => t.isDeleted.equals(false))).watch();
  }

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
  Future deleteRating(String id) => (update(ratings)..where((t) => t.id.equals(id))).write(const RatingsCompanion(isDeleted: Value(true)));
}
