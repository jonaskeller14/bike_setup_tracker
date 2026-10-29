import 'package:drift/drift.dart';

import 'feedbacks.dart';
import 'setups.dart';

@DataClassName('FeedbackComparisonDb')
class FeedbackComparisons extends Table {
  TextColumn get feedbackId => text().references(Feedbacks, #id, onDelete: KeyAction.cascade)();

  // May dangle once the setup is purged.
  TextColumn get referenceSetupId => text().references(Setups, #id)();

  // `overall` or `<end>.<attribute>`.
  TextColumn get aspect => text()();

  IntColumn get outcome => integer()();

  @override
  Set<Column> get primaryKey => {feedbackId, referenceSetupId, aspect};
}
