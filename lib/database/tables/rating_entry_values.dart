import 'package:drift/drift.dart';
import 'rating_entries.dart';
import 'rating_metrics.dart';

@DataClassName('RatingEntryValueDb')
class RatingEntryValues extends Table {
  TextColumn get ratingEntryId =>
      text().references(RatingEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get ratingMetricId =>
      text().references(RatingMetrics, #id, onDelete: KeyAction.cascade)();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {ratingEntryId, ratingMetricId};
}
