import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/syncable.dart';
import 'sync_collection.dart';

/// Converts records to and from Firestore documents.
class SyncCodec {
  static Map<String, dynamic> encode(Syncable record) => {
    ...record.toJson(),
    'lastModified': Timestamp.fromDate(record.lastModified.toUtc()),
    'serverUpdatedAt': FieldValue.serverTimestamp(), // server fills this in
  };

  /// Reads a document of [collection], or returns `null` if this client must
  /// not touch it: it is malformed, or its model `version` is newer than this
  /// client knows (reading would drop fields).
  static Syncable? decode(
    SyncCollection collection,
    Map<String, dynamic> data, {
    Map<String, AdjustmentType> adjustmentTypes = const {},
  }) {
    try {
      // Most models default a missing timestamp to "now", which would let a
      // broken document win every merge.
      final lastModified = switch (data['lastModified']) {
        final Timestamp timestamp => timestamp.toDate().toUtc().toIso8601String(),
        final String iso => iso,
        _ => throw const FormatException('lastModified missing'),
      };
      return collection.fromJson({...data, 'lastModified': lastModified}, adjustmentTypes);
    } catch (e) {
      debugPrint('Skipping unreadable ${collection.collectionName} document ${data['id']}: $e');
      return null;
    }
  }
}
