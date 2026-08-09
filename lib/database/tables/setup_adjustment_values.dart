import 'package:drift/drift.dart';

import 'adjustments.dart';
import 'setups.dart';

@DataClassName('SetupAdjustmentValueDb')
class SetupAdjustmentValues extends Table {
  TextColumn get setupId =>
      text().references(Setups, #id, onDelete: KeyAction.cascade)();
  TextColumn get adjustmentId =>
      text().references(Adjustments, #id, onDelete: KeyAction.cascade)();

  // We store all values as strings. The Repository mapper will parse this back into
  // the appropriate Dart type (double, String, Duration, bool) based on the Adjustment's `type` field.
  // Note: NULL values simply do not receive a row in this table.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {setupId, adjustmentId};
}
