import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/daos/sync_dao.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/syncable.dart';
import 'sync_codec.dart';
import 'sync_collection.dart';
import 'sync_local_store.dart';
import 'sync_merge.dart';
import 'sync_remote.dart';

/// Thrown between steps when the run no longer belongs to the signed-in uid.
class SyncCancelled implements Exception {
  const SyncCancelled();
}

/// One sync run: pull the cloud changes, then push the outbox.
class SyncEngine {
  /// A write that started before another one can still become visible after
  /// it, behind a cursor that already passed it. Each run reads that far back
  /// again; identical versions are no-ops.
  static const Duration cursorOverlap = Duration(minutes: 1);

  static const String defaultPrefsPrefix = 'cloudSync';

  /// Set once this device has synced; the uid is the account it last synced with.
  static const String syncedUidKey = '$defaultPrefsPrefix.uid';

  final AppDatabase db;
  final SyncRemote remote;
  final int pageSize;
  final int batchSize;
  final String _syncedUidKey;
  final String _skippedKey;

  SyncEngine(
    this.db, {
    required this.remote,
    this.pageSize = 500,
    this.batchSize = 500,
    String prefsPrefix = defaultPrefsPrefix,
  }) : _syncedUidKey = '$prefsPrefix.uid',
       _skippedKey = '$prefsPrefix.skipped';

  SyncDao get _dao => db.syncDao;
  SyncLocalStore get _store => SyncLocalStore(db);

  /// [ensureCurrent] throws [SyncCancelled] once the run is obsolete.
  Future<void> run(String uid, {void Function()? ensureCurrent}) async {
    final check = ensureCurrent ?? () {};
    await _prepare(uid);
    await _pull(uid, check);
    try {
      await _push(uid, check);
    } on FirebaseException catch (e) {
      // Another device pushed a newer version since the pull. Pulling drops
      // the local versions that lost, so the retry only sends winners.
      if (e.code != 'permission-denied') rethrow;
      await _pull(uid, check);
      await _push(uid, check);
    }
  }

  /// The first run for a uid (first sync on this device, or after moving
  /// into an account) merges all local data into the cloud data.
  Future<void> _prepare(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_syncedUidKey) == uid) return;
    await _dao.resetCursors();
    await _dao.enqueueAll();
    await prefs.remove(_skippedKey);
    await prefs.setString(_syncedUidKey, uid);
  }

  Future<void> _pull(String uid, void Function() check) async {
    await _retrySkipped(uid, check);
    for (final collection in SyncCollection.values) {
      final stored = await _dao.getCursor(collection);
      // Doc id '' sorts first, so this starts at the overlap's timestamp.
      SyncCursor? after = stored == null
          ? null
          : (serverUpdatedAt: stored.serverUpdatedAt.subtract(cursorOverlap), docId: '');
      while (true) {
        check();
        final docs = await remote.pull(uid, collection, after: after, limit: pageSize);
        if (docs.isEmpty) break;
        final last = docs.last;
        final cursor = (serverUpdatedAt: last.serverUpdatedAt, docId: last.id);
        after = cursor;
        await _addSkipped(collection, await _apply(collection, docs, cursor: cursor));
        if (docs.length < pageSize) break;
      }
    }
  }

  /// Merges [docs] into the local data and advances the cursor in one
  /// transaction. Returns the ids of documents this client can't read.
  Future<List<String>> _apply(SyncCollection collection, List<SyncRemoteDoc> docs, {SyncCursor? cursor}) {
    return _dao.runApplyingRemote(() async {
      final snapshot = await _store.snapshot();
      final local = snapshot.recordsOf(collection);
      final adjustmentTypes = collection.needsAdjustmentTypes
          ? snapshot.adjustmentTypes
          : const <String, AdjustmentType>{};
      final skipped = <String>[];
      for (final doc in docs) {
        final remoteRecord = SyncCodec.decode(collection, doc.data, adjustmentTypes: adjustmentTypes);
        final localRecord = local[doc.id];
        if (remoteRecord == null) {
          skipped.add(doc.id);
          // The rules would reject the local version, and with it every
          // record pushed in the same batch.
          if (localRecord != null && !_lastModifiedOf(doc).isBefore(localRecord.lastModified)) {
            await _dao.drop(collection, doc.id);
          }
          continue;
        }
        switch (SyncMerge.resolve(local: localRecord, remote: remoteRecord)) {
          case SyncAction.applyRemote:
            await _store.write(remoteRecord, adjustmentTypes: adjustmentTypes);
          case SyncAction.keepLocal when !_sameVersion(localRecord!, remoteRecord):
            // Without an outbox entry the cloud would keep the losing version.
            await _dao.enqueue(collection, doc.id);
          case SyncAction.keepLocal || SyncAction.skip:
            break;
        }
      }
      if (cursor != null) await _dao.setCursor(collection, cursor);
      return skipped;
    });
  }

  static DateTime _lastModifiedOf(SyncRemoteDoc doc) => switch (doc.data['lastModified']) {
    final Timestamp timestamp => timestamp.toDate().toUtc(),
    _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  };

  static bool _sameVersion(Syncable a, Syncable b) =>
      a.lastModified == b.lastModified && jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  /// Documents skipped earlier (a newer model version, usually) are read
  /// again on every run: the cursor has moved past them, and after an app
  /// update this client may understand them.
  Future<void> _retrySkipped(String uid, void Function() check) async {
    final prefs = await SharedPreferences.getInstance();
    final skipped = prefs.getStringList(_skippedKey) ?? const [];
    if (skipped.isEmpty) return;
    final stillSkipped = <String>[];
    for (final collection in SyncCollection.values) {
      final prefix = '${collection.collectionName}/';
      final ids = [
        for (final key in skipped)
          if (key.startsWith(prefix)) key.substring(prefix.length),
      ];
      if (ids.isEmpty) continue;
      check();
      final docs = await remote.fetch(uid, collection, ids);
      if (docs.isEmpty) continue;
      stillSkipped.addAll([for (final id in await _apply(collection, docs)) '$prefix$id']);
    }
    await prefs.setStringList(_skippedKey, stillSkipped);
  }

  Future<void> _addSkipped(SyncCollection collection, List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _skippedKey,
      {
        ...?prefs.getStringList(_skippedKey),
        for (final id in ids) '${collection.collectionName}/$id',
      }.toList(),
    );
  }

  Future<void> _push(String uid, void Function() check) async {
    while (true) {
      check();
      final batch = await _dao.pendingBatch(batchSize);
      if (batch.isEmpty) return;
      final snapshot = await _store.snapshot();
      final records = <(SyncCollection, Syncable)>[];
      for (final entry in batch) {
        final collection = SyncCollection.fromCollectionName(entry.collection);
        // Missing: purged from the local trash since, which doesn't sync.
        final record = collection == null ? null : snapshot.recordsOf(collection)[entry.rowId];
        if (record != null) records.add((collection!, record));
      }
      if (records.isNotEmpty) await remote.push(uid, records);
      await _dao.markPushed([for (final entry in batch) entry.id]);
      if (batch.length < batchSize) return;
    }
  }
}
