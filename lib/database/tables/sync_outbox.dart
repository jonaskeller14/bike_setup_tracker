import 'package:drift/drift.dart';

import '../../services/sync/sync_collection.dart';
import '../converters/utc_datetime_converter.dart';

/// Root rows whose latest local version is not in the cloud yet, one entry per
/// row. Only [syncOutboxTriggers] write it.
@DataClassName('SyncOutboxDb')
class SyncOutbox extends Table {
  // Re-enqueuing a row replaces its entry under a new id, so a push that read
  // the old entry only clears that one. AUTOINCREMENT keeps the id of a
  // replaced entry from being reused.
  IntColumn get id => integer().autoIncrement()();

  TextColumn get collection => text()();
  TextColumn get rowId => text()();
  DateTimeColumn get enqueuedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [
    {collection, rowId},
  ];
}

/// An `AFTER INSERT` and an `AFTER UPDATE` trigger on each root table (the
/// [SyncCollection] name is the table name). Each one replaces the row's
/// outbox entry. While remote changes are applied, they only drop it: the row
/// now holds the cloud version, so the local one it stood for lost.
///
/// The body avoids conflict clauses because a conflict clause on the outer
/// statement (`INSERT OR IGNORE INTO bikes …`) would override them. There are
/// no `DELETE` triggers: hard deletes only come from the local trash purge,
/// which doesn't sync.
final List<Trigger> syncOutboxTriggers = [
  for (final collection in SyncCollection.values)
    for (final event in const ['insert', 'update'])
      Trigger(
        'CREATE TRIGGER IF NOT EXISTS sync_outbox_${collection.collectionName}_$event '
            'AFTER ${event.toUpperCase()} ON ${collection.collectionName} '
            'BEGIN '
            "DELETE FROM sync_outbox WHERE collection = '${collection.collectionName}' AND row_id = NEW.id; "
            'INSERT INTO sync_outbox (collection, row_id, enqueued_at) '
            "SELECT '${collection.collectionName}', NEW.id, CAST(strftime('%s', 'now') AS INTEGER) "
            'WHERE NOT EXISTS (SELECT 1 FROM sync_state WHERE applying_remote = 1); '
            'END',
        'sync_outbox_${collection.collectionName}_$event',
      ),
];
