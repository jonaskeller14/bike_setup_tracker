import 'package:drift/drift.dart';

import 'feedbacks.dart';

@DataClassName('FeedbackObservationDb')
class FeedbackObservations extends Table {
  TextColumn get feedbackId => text().references(Feedbacks, #id, onDelete: KeyAction.cascade)();

  // `issue.<end>.<attribute>`, or `issue.none`.
  TextColumn get key => text()();

  RealColumn get value => real().nullable()();
  TextColumn get textValue => text().nullable()();

  @override
  Set<Column> get primaryKey => {feedbackId, key};
}
