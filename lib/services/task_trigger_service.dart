import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task/task_trigger.dart';
import '../repositories/app_repository.dart';
import 'error_reporter.dart';
import 'sync/attachment_sync.dart';
import 'sync/task_trigger_remote.dart';

/// Keeps the account's task triggers in step with the open rules that rides
/// move, so the backend can send a push when a Strava ride makes one due (#17
/// Phase 8). Runs while cloud sync is active (flag, premium, account session),
/// a few seconds after the data settles, and writes only what changed. A new
/// ride changes no trigger; finishing a task, editing its interval or a new
/// month ([TaskTrigger.earliestCountFrom]) does.
class TaskTriggerService {
  final AppRepository _repository;
  final TaskTriggerRemote _remote;
  final Duration _debounce;

  TaskTriggerService(
    this._repository, {
    TaskTriggerRemote? remote,
    this._debounce = const Duration(seconds: 5),
  }) : _remote = remote ?? FirestoreTaskTriggerRemote() {
    _repository.addListener(_schedule);
  }

  String? _uid;

  /// What the cloud holds for [_uid] as far as this device knows; null until
  /// read, and again after a failed write.
  Map<String, TaskTrigger>? _stored;
  Timer? _timer;
  Future<void>? _running;
  bool _runAgain = false;

  /// [uid] is the account while cloud sync is active, null otherwise.
  void update({required String? uid}) {
    if (uid == _uid) {
      // Retries a failed run once sync works again.
      if (uid != null && _stored == null && _running == null) _schedule();
      return;
    }
    _uid = uid;
    _stored = null;
    _timer?.cancel();
    if (uid != null) _schedule();
  }

  void dispose() {
    _repository.removeListener(_schedule);
    _timer?.cancel();
    _uid = null;
  }

  void _schedule() {
    if (_uid == null) return;
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(sync()));
  }

  /// Writes the changed triggers now, or once more after the running write.
  @visibleForTesting
  Future<void> sync() {
    _timer?.cancel();
    final running = _running;
    if (running != null) {
      _runAgain = true;
      return running;
    }
    return _running = _runWhileRequested().whenComplete(() => _running = null);
  }

  Future<void> _runWhileRequested() async {
    do {
      _runAgain = false;
      await _runOnce();
    } while (_runAgain && _uid != null);
  }

  Future<void> _runOnce() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final wanted = {for (final trigger in await _repository.taskTriggers()) trigger.ruleId: trigger};
      if (_uid != uid || mapEquals(_stored, wanted)) return;
      final stored = _stored ?? await _remote.list(uid);
      if (_uid != uid) return;
      final upserts = [
        for (final trigger in wanted.values)
          if (stored[trigger.ruleId] != trigger) trigger,
      ];
      final deletes = [
        for (final ruleId in stored.keys)
          if (!wanted.containsKey(ruleId)) ruleId,
      ];
      if (upserts.isNotEmpty || deletes.isNotEmpty) {
        await _remote.apply(uid, upserts: upserts, deletes: deletes);
      }
      if (_uid == uid) _stored = wanted;
    } catch (e, s) {
      if (_uid == uid) _stored = null;
      // Offline, or a revoked session or lapsed premium, which the cloud sync
      // notices and handles itself.
      if (AttachmentSync.isOffline(e) || AttachmentSync.isDenied(e)) return;
      recordNonFatal(e, s, reason: 'taskTriggers.sync');
    }
  }
}
