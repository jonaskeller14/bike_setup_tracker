import 'package:drift/drift.dart';
import '../../models/adjustment/adjustment.dart';
import 'ratings.dart';

@DataClassName('RatingMetricDb')
class RatingMetrics extends Table {
  // == the wrapped Adjustment's UUID.
  TextColumn get id => text()();

  TextColumn get ratingId => text().references(Ratings, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer()();
  RealColumn get weight => real().withDefault(const Constant(1.0))();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get type => textEnum<AdjustmentType>()();

  // Subclass-specific properties (min, max, options, …) as a serialized JSON string.
  TextColumn get jsonPayload => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
