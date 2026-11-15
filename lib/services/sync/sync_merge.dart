import 'dart:convert';

import '../../models/syncable.dart';

enum SyncAction {
  applyRemote,
  keepLocal,
  skip, // A tombstone for a record this device does not have: nothing to store.
}

/// Per-record last-writer-wins, the rule `FileImport.merge` applies
class SyncMerge {
  /// The newest `lastModified` wins. `lastModified` is stored in whole seconds,
  /// so two devices can edit within one tick; then a tombstone wins (a delete
  /// that raced an edit is not undone), and otherwise the version with the
  /// greater JSON, so every device picks the same winner and they converge.
  /// An identical version keeps the local one, which makes a re-pull a no-op.
  static SyncAction resolve({required Syncable? local, required Syncable remote}) {
    if (local == null) return remote.isDeleted ? SyncAction.skip : SyncAction.applyRemote;

    final order = remote.lastModified.compareTo(local.lastModified);
    if (order > 0) return SyncAction.applyRemote;
    if (order < 0) return SyncAction.keepLocal;

    if (remote.isDeleted != local.isDeleted) return remote.isDeleted ? SyncAction.applyRemote : SyncAction.keepLocal;
    final byContent = canonicalJson(remote).compareTo(canonicalJson(local));
    return byContent > 0 ? SyncAction.applyRemote : SyncAction.keepLocal;
  }

  static bool sameVersion(Syncable a, Syncable b) =>
      a.lastModified == b.lastModified && canonicalJson(a) == canonicalJson(b);

  /// The record's JSON with the keys of every map sorted. Firestore returns
  /// maps in no fixed key order (a `HashMap` on Android), so the plain JSON of
  /// a pulled copy can differ from the identical local record's.
  static String canonicalJson(Syncable record) => jsonEncode(_sortKeys(jsonDecode(jsonEncode(record.toJson()))));

  static Object? _sortKeys(Object? value) => switch (value) {
    final Map<String, dynamic> map => {for (final key in map.keys.toList()..sort()) key: _sortKeys(map[key])},
    final List<dynamic> list => [for (final item in list) _sortKeys(item)],
    _ => value,
  };
}
