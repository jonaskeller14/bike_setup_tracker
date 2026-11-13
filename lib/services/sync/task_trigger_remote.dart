import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/task/task_trigger.dart';

/// The account's task triggers: `users/{uid}/task_triggers/{ruleId}`.
abstract interface class TaskTriggerRemote {
  /// The stored triggers by rule id. `notifiedAt`, which only the backend
  /// writes, is left out.
  Future<Map<String, TaskTrigger>> list(String uid);

  /// Writes [upserts] in full, which arms a notified trigger again, and
  /// removes the triggers of [deletes].
  Future<void> apply(String uid, {required List<TaskTrigger> upserts, required List<String> deletes});
}

class FirestoreTaskTriggerRemote implements TaskTriggerRemote {
  // A commit waits for the server, also while offline.
  static const Duration _commitTimeout = Duration(seconds: 60);
  static const int _batchLimit = 500;

  final FirebaseFirestore? _firestoreOverride;

  FirestoreTaskTriggerRemote({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _triggers(String uid) =>
      _firestore.collection('users').doc(uid).collection('task_triggers');

  @override
  Future<Map<String, TaskTrigger>> list(String uid) async {
    final snapshot = await _triggers(uid).get(const GetOptions(source: Source.server));
    return {for (final doc in snapshot.docs) doc.id: ?_toTrigger(doc.id, doc.data())};
  }

  /// Null for a malformed doc, which then counts as missing and is rewritten.
  static TaskTrigger? _toTrigger(String ruleId, Map<String, dynamic> data) {
    final gearId = data['gearId'];
    final metric = TaskTriggerMetric.values.asNameMap()[data['metric']];
    final countFrom = data['countFrom'];
    final needed = data['needed'];
    final title = data['title'];
    if (gearId is! String || metric == null || countFrom is! Timestamp || needed is! num || title is! String) {
      return null;
    }
    return TaskTrigger(
      ruleId: ruleId,
      gearId: gearId,
      metric: metric,
      countFrom: countFrom.toDate(),
      needed: needed.toDouble(),
      title: title,
    );
  }

  @override
  Future<void> apply(String uid, {required List<TaskTrigger> upserts, required List<String> deletes}) async {
    final writes = <void Function(WriteBatch)>[
      for (final trigger in upserts)
        (batch) => batch.set(_triggers(uid).doc(trigger.ruleId), {
          'gearId': trigger.gearId,
          'metric': trigger.metric.name,
          'countFrom': Timestamp.fromDate(trigger.countFrom),
          'needed': trigger.needed,
          'title': trigger.title,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      for (final ruleId in deletes) (batch) => batch.delete(_triggers(uid).doc(ruleId)),
    ];
    for (var start = 0; start < writes.length; start += _batchLimit) {
      final batch = _firestore.batch();
      for (final write in writes.skip(start).take(_batchLimit)) {
        write(batch);
      }
      await batch.commit().timeout(_commitTimeout);
    }
  }
}
