import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../database/daos/sync_dao.dart';
import '../../models/syncable.dart';
import 'sync_codec.dart';
import 'sync_collection.dart';

typedef SyncRemoteDoc = ({String id, Map<String, dynamic> data, DateTime serverUpdatedAt});

/// The cloud copy of the records: `users/{uid}/data/{collection}/records/{id}`.
abstract interface class SyncRemote {
  /// Up to [limit] documents changed after [after], oldest first.
  Future<List<SyncRemoteDoc>> pull(String uid, SyncCollection collection, {SyncCursor? after, required int limit});

  /// The documents of [ids] that exist.
  Future<List<SyncRemoteDoc>> fetch(String uid, SyncCollection collection, Iterable<String> ids);

  /// Writes all [records] or none. The rules reject the whole batch if one
  /// record is older than its cloud version (`permission-denied`).
  Future<void> push(String uid, List<(SyncCollection, Syncable)> records);
}

class FirestoreSyncRemote implements SyncRemote {
  // A commit waits for the server, also while offline.
  static const Duration _commitTimeout = Duration(seconds: 60);

  final FirebaseFirestore? _firestoreOverride;
  final Object _tieBreaker;

  /// [tieBreaker] replaces the document id, which `fake_cloud_firestore`
  /// can't page by. The rules keep the `id` field equal to the document id.
  FirestoreSyncRemote({FirebaseFirestore? firestore, @visibleForTesting Object? tieBreaker})
    : _firestoreOverride = firestore,
      _tieBreaker = tieBreaker ?? FieldPath.documentId;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _records(String uid, SyncCollection collection) =>
      _firestore.collection('users').doc(uid).collection('data').doc(collection.collectionName).collection('records');

  @override
  Future<List<SyncRemoteDoc>> pull(
    String uid,
    SyncCollection collection, {
    SyncCursor? after,
    required int limit,
  }) async {
    // All writes of one batch share a server timestamp, so the doc id breaks ties.
    var query = _records(uid, collection).orderBy('serverUpdatedAt').orderBy(_tieBreaker);
    if (after != null) {
      final timestamp = Timestamp.fromMicrosecondsSinceEpoch(after.serverUpdatedAt.microsecondsSinceEpoch);
      // An empty doc id (the start of the overlap) is no valid document id for the native SDKs:
      // it becomes the collection path itself. startAt with the timestamp alone starts at the same place.
      query = after.docId.isEmpty ? query.startAt([timestamp]) : query.startAfter([timestamp, after.docId]);
    }
    // From the server: the offline cache would hide changes, and an
    // `unavailable` error is how being offline shows up.
    final snapshot = await query.limit(limit).get(const GetOptions(source: Source.server));
    return [for (final doc in snapshot.docs) ?_toDoc(doc)];
  }

  @override
  Future<List<SyncRemoteDoc>> fetch(String uid, SyncCollection collection, Iterable<String> ids) async {
    final docs = await Future.wait([
      for (final id in ids) _records(uid, collection).doc(id).get(const GetOptions(source: Source.server)),
    ]);
    return [for (final doc in docs) ?_toDoc(doc)];
  }

  static SyncRemoteDoc? _toDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final serverUpdatedAt = data?['serverUpdatedAt'];
    if (data == null || serverUpdatedAt is! Timestamp) return null;
    return (id: doc.id, data: data, serverUpdatedAt: serverUpdatedAt.toDate().toUtc());
  }

  @override
  Future<void> push(String uid, List<(SyncCollection, Syncable)> records) async {
    final batch = _firestore.batch();
    for (final (collection, record) in records) {
      final data = SyncCodec.encode(record);
      // Replaces every field this client writes, nested maps included (a
      // removed setup value must disappear), and keeps fields a newer app
      // version added.
      batch.set(_records(uid, collection).doc(record.id), data, SetOptions(mergeFields: data.keys.toList()));
    }
    await batch.commit().timeout(_commitTimeout);
  }
}
