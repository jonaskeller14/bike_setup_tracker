import 'package:drift/drift.dart';

import '../converters/utc_datetime_converter.dart';

/// Device-wide cloud sync state: a single row with [id] 0, created on first
/// write.
@DataClassName('SyncStateDb')
class SyncState extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  // Read by the outbox triggers. Only set inside the transaction that applies
  // pulled records, so a crash can't leave it on.
  BoolColumn get applyingRemote => boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastPushAt => dateTime().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
