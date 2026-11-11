import 'package:drift/drift.dart';

import '../../services/sync/sync_collection.dart';
import '../app_database.dart';
import '../tables/sync_cursors.dart';
import '../tables/sync_outbox.dart';
import '../tables/sync_state.dart';

part 'sync_dao.g.dart';

typedef SyncCursor = ({DateTime serverUpdatedAt, String docId});

@DriftAccessor(tables: [SyncOutbox, SyncState, SyncCursors])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  static const _stateId = 0;

  // --- Outbox ---

  /// The [limit] oldest entries.
  Future<List<SyncOutboxDb>> pendingBatch(int limit) {
    return (select(syncOutbox)
          ..orderBy([(t) => OrderingTerm(expression: t.id)])
          ..limit(limit))
        .get();
  }

  Stream<int> watchPendingCount() {
    final count = syncOutbox.id.count();
    return (selectOnly(syncOutbox)..addColumns([count])).map((row) => row.read(count)!).watchSingle();
  }

  /// Clears the pushed entries. A row edited after its entry was read has a
  /// new entry by now, which stays.
  Future<void> markPushed(Iterable<int> ids) {
    return transaction(() async {
      await (delete(syncOutbox)..where((t) => t.id.isIn(ids))).go();
      await into(syncState).insertOnConflictUpdate(
        SyncStateCompanion(id: const Value(_stateId), lastPushAt: Value(DateTime.now().toUtc())),
      );
    });
  }

  Future<DateTime?> lastPushAt() async => (await _state())?.lastPushAt;

  /// Enqueues every root row for the first sync on a device, trashed rows
  /// included so their deletion reaches the cloud. Existing entries stay.
  Future<void> enqueueAll() {
    return transaction(() async {
      final now = DateTime.now().toUtc();
      for (final collection in SyncCollection.values) {
        await customInsert(
          'INSERT OR IGNORE INTO sync_outbox (collection, row_id, enqueued_at) '
          'SELECT ?, id, ? FROM ${collection.collectionName}',
          variables: [Variable.withString(collection.collectionName), Variable.withDateTime(now)],
          updates: {syncOutbox},
        );
      }
    });
  }

  // --- Pull ---

  Future<SyncCursor?> getCursor(SyncCollection collection) async {
    final row = await (select(
      syncCursors,
    )..where((t) => t.collection.equals(collection.collectionName))).getSingleOrNull();
    if (row == null) return null;
    return (
      serverUpdatedAt: DateTime.fromMicrosecondsSinceEpoch(row.serverUpdatedAtMicros, isUtc: true),
      docId: row.docId,
    );
  }

  Future<void> setCursor(SyncCollection collection, SyncCursor cursor) {
    return into(syncCursors).insertOnConflictUpdate(
      SyncCursorsCompanion.insert(
        collection: collection.collectionName,
        serverUpdatedAtMicros: cursor.serverUpdatedAt.microsecondsSinceEpoch,
        docId: cursor.docId,
      ),
    );
  }

  /// Runs [action] in one transaction in which the outbox triggers don't
  /// enqueue the rows it writes but drop their entries (see
  /// [syncOutboxTriggers]).
  Future<T> runApplyingRemote<T>(Future<T> Function() action) {
    return transaction(() async {
      await _setApplyingRemote(true);
      final result = await action();
      await _setApplyingRemote(false);
      return result;
    });
  }

  Future<void> _setApplyingRemote(bool value) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion(id: const Value(_stateId), applyingRemote: Value(value)),
    );
  }

  Future<SyncStateDb?> _state() => (select(syncState)..where((t) => t.id.equals(_stateId))).getSingleOrNull();
}
