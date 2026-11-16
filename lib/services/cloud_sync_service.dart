import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/attachment.dart';
import '../models/selected_data.dart';
import '../models/service_error.dart';
import '../utils/backup.dart';
import 'account_service.dart';
import 'error_reporter.dart';
import 'sync/attachment_remote.dart';
import 'sync/attachment_sync.dart';
import 'sync/backup_remote.dart';
import 'sync/cloud_backups.dart';
import 'sync/sync_collection.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_remote.dart';

enum CloudSyncStatus { idle, syncing, offline, error }

enum CloudSyncTrigger { activated, edit, resume, manual, signOut }

typedef CloudSyncRun = ({
  DateTime at,
  CloudSyncTrigger trigger,
  CloudSyncStatus status,
  SyncRunStats stats,
  Object? error,
});

/// Keeps the local data and the account's cloud copy in step. Runs after
/// local edits (debounced), on app resume and on "Sync now"; there are no
/// live listeners, since every snapshot costs reads. Only active with cloud
/// sync on, premium and an account session. The attachment files travel with
/// each run: uploaded after the records, downloaded when first viewed. The
/// daily cloud backup is the last step of a run.
class CloudSyncService extends ChangeNotifier with WidgetsBindingObserver implements UserBoundService {
  static const String _lastSyncKey = 'cloudSync.lastSyncAt';
  static const int _runLogLength = 5;

  final AppDatabase _database;
  final SyncEngine _engine;
  final AttachmentRemote _attachmentRemote;
  final CloudBackups _backups;
  final Duration _debounce;
  late final AttachmentSync _attachments = AttachmentSync(
    _database,
    remote: _attachmentRemote,
    onChanged: notifyListeners,
  );

  CloudSyncService(
    this._database, {
    SyncRemote? remote,
    AttachmentRemote? attachmentRemote,
    BackupRemote? backupRemote,
    this._debounce = const Duration(seconds: 10),
  }) : _engine = SyncEngine(_database, remote: remote ?? FirestoreSyncRemote()),
       _attachmentRemote = attachmentRemote ?? FirebaseAttachmentRemote(),
       _backups = CloudBackups(_database, remote: backupRemote ?? FirebaseBackupRemote());

  AccountService? _account;
  bool _enabled = false;
  bool _premium = false;
  String? _uid;
  bool _wasActive = false;
  bool _isDisposed = false;

  CloudSyncStatus _status = CloudSyncStatus.idle;
  DateTime? _lastSyncAt;
  int _pendingCount = 0;
  Future<void>? _running;
  bool _runAgain = false;
  CloudSyncTrigger _nextTrigger = CloudSyncTrigger.manual;
  final List<CloudSyncRun> _runs = [];
  Timer? _debounceTimer;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  CloudSyncStatus get status => _status;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get pendingCount => _pendingCount;

  /// Attachment files that are not in the cloud yet.
  int get pendingAttachmentUploads => _attachments.pendingUploads;

  /// An attachment couldn't be uploaded because the 500 MB quota is full.
  bool get attachmentQuotaFull => _attachments.quotaFull;

  /// The cloud storage each account may use: attachments and backups.
  static const int storageQuotaBytes = AttachmentSync.quotaBytes;

  /// Cloud sync on, premium and an account session.
  bool get isActive => _enabled && _premium && _uid != null && (_account?.isOnAccount ?? false);

  /// The account synced to, while [isActive].
  String? get activeUid => isActive ? _uid : null;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    if (_account != null) WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  /// Called from the proxy provider on every change of its inputs, during a
  /// build, so listeners hear about it a microtask later.
  void update({required bool enabled, required bool premium, required AccountService account}) {
    if (enabled && _account == null) _start(account);
    _enabled = enabled;
    _premium = premium;
    _onGateChanged();
  }

  /// Syncs when the service becomes active.
  void _onGateChanged() {
    final active = isActive;
    if (active == _wasActive) return;
    _wasActive = active;
    if (!active) _debounceTimer?.cancel();
    scheduleMicrotask(() {
      notifyListeners();
      if (active) unawaited(_requestSync(CloudSyncTrigger.activated));
    });
  }

  void _start(AccountService account) {
    _account = account;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadLastSync());
    final dao = _database.syncDao;
    _subscriptions.add(
      dao.watchPendingCount().listen((pending) {
        _pendingCount = pending;
        notifyListeners();
      }),
    );
    // The first value is the starting point, not an edit.
    int? latest;
    var first = true;
    _subscriptions.add(
      dao.watchLatestEntryId().listen((id) {
        final edited = !first && id != null && (latest == null || id > latest!);
        first = false;
        if (id != null) latest = id;
        if (edited && isActive) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(_debounce, () => unawaited(_requestSync(CloudSyncTrigger.edit)));
        }
      }),
    );
    unawaited(account.bind(this));
  }

  Future<void> _loadLastSync() async {
    final stored = (await SharedPreferences.getInstance()).getString(_lastSyncKey);
    _lastSyncAt = stored == null ? null : DateTime.tryParse(stored);
    notifyListeners();
  }

  @override
  Future<void> bindUser(String uid) async {
    _uid = uid;
    _attachments.reset();
    _backups.reset();
    // A new uid needs a sync even when the service stayed active.
    _wasActive = false;
    _onGateChanged();
  }

  /// Waits for a running sync, which stops at its next step.
  @override
  Future<void> unbindUser() async {
    _uid = null;
    _onGateChanged();
    await _running;
    _attachments.reset();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isActive) unawaited(_requestSync(CloudSyncTrigger.resume));
  }

  /// Runs a sync now, or once more after the running one, and returns the
  /// resulting status.
  Future<CloudSyncStatus> syncNow() async {
    if (!isActive) return _status;
    await _requestSync(CloudSyncTrigger.manual);
    return _status;
  }

  /// Fetches an attachment file this device doesn't have from the cloud.
  /// [force] asks again after a recent failure.
  Future<AttachmentDownloadResult> downloadAttachment(Attachment attachment, {bool force = false}) {
    final uid = _uid;
    if (uid == null || !isActive) return Future.value(AttachmentDownloadResult.notSyncing);
    return _attachments.download(uid, attachment, force: force);
  }

  /// The bytes of [storageQuotaBytes] in use, read from the server on each
  /// call. A Function counts them after each upload, so they lag by seconds.
  Future<int> readStorageBytes() {
    final uid = _uid;
    if (uid == null || !isActive) return Future.error(StateError('Cloud sync is not active'));
    return _attachmentRemote.storageBytes(uid);
  }

  /// The account's cloud backups, for the restore list. Empty while sync isn't active.
  Future<DataResult<List<CloudBackup>>> listBackups() async {
    final uid = _uid;
    if (uid == null || !isActive) return const DataSuccess([]);
    try {
      return DataSuccess(await _backups.list(uid));
    } catch (e) {
      return DataFailure(DataError(DataErrorKind.getCloudBackups, e.toString()));
    }
  }

  Future<DataResult<SelectedData>> readBackup(CloudBackup backup) async {
    final uid = _uid;
    if (uid == null || !isActive) return const DataFailure(DataError(DataErrorKind.readCloudBackup));
    try {
      return DataSuccess(await _backups.read(uid, backup));
    } catch (e) {
      return DataFailure(DataError(DataErrorKind.readCloudBackup, e.toString()));
    }
  }

  /// Pushes the pending changes before this device signs out. Returns how many
  /// changes and attachment files are still not in the cloud.
  Future<int> pushBeforeSignOut() async {
    if (isActive) await _requestSync(CloudSyncTrigger.signOut);
    return await _database.syncDao.watchPendingCount().first + _attachments.pendingUploads;
  }

  Future<void> _requestSync(CloudSyncTrigger trigger) {
    _debounceTimer?.cancel();
    _nextTrigger = trigger;
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
      await _runOnce(_nextTrigger);
    } while (_runAgain && isActive);
  }

  Future<void> _runOnce(CloudSyncTrigger trigger) async {
    final uid = _uid;
    if (uid == null || !isActive) return;
    _setStatus(CloudSyncStatus.syncing);
    void ensureCurrent() {
      if (_uid != uid || !isActive) throw const SyncCancelled();
    }

    Object? error;
    try {
      await _engine.run(uid, ensureCurrent: ensureCurrent);
      await _attachments.run(uid, ensureCurrent: ensureCurrent);
      await _backups.saveIfDue(uid, ensureCurrent: ensureCurrent);
      _lastSyncAt = DateTime.now().toUtc();
      unawaited(
        SharedPreferences.getInstance().then((prefs) => prefs.setString(_lastSyncKey, _lastSyncAt!.toIso8601String())),
      );
      _setStatus(CloudSyncStatus.idle);
    } on SyncCancelled {
      _setStatus(CloudSyncStatus.idle);
    } catch (e, s) {
      error = e;
      if (AttachmentSync.isOffline(e)) {
        _setStatus(CloudSyncStatus.offline);
        return;
      }
      _setStatus(CloudSyncStatus.error);
      // On an account, a denied request is how a revoked session or a lapsed
      // premium shows up first.
      if (AttachmentSync.isDenied(e)) {
        unawaited(_account?.recheckSession());
        return;
      }
      recordNonFatal(e, s, reason: 'cloudSync.run');
    } finally {
      _logRun(trigger, error);
    }
  }

  void _logRun(CloudSyncTrigger trigger, Object? error) {
    final run = (at: DateTime.now(), trigger: trigger, status: _status, stats: _engine.lastRunStats, error: error);
    _runs.add(run);
    if (_runs.length > _runLogLength) _runs.removeAt(0);
    debugPrint('cloudSync: ${_describeRun(run)}');
  }

  static String _describeRun(CloudSyncRun run) =>
      'trigger=${run.trigger.name} status=${run.status.name} ${run.stats}'
      '${run.error == null ? '' : ' error=${run.error}'}';

  /// Debug-only state for the About page, newest run first.
  Future<String> debugReport() async {
    final dao = _database.syncDao;
    String time(DateTime? at) =>
        at == null ? '-' : at.toLocal().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
    return [
      'Active: $isActive, status: ${_status.name}',
      'Outbox: $_pendingCount pending, sequence ${await dao.outboxSequence()}',
      for (final entry in await dao.pendingBatch(3)) '  ${entry.collection}/${entry.rowId}',
      'Last push: ${time(await dao.lastPushAt())}',
      'Applying remote: ${await dao.applyingRemote()}',
      'Skipped docs: ${await _engine.skippedCount()}',
      'Cursors:',
      for (final collection in SyncCollection.values)
        '  ${collection.collectionName}: ${time((await dao.getCursor(collection))?.serverUpdatedAt)}',
      'Recent runs:',
      for (final run in _runs.reversed) '  ${time(run.at).substring(11)} ${_describeRun(run)}',
    ].join('\n');
  }

  void _setStatus(CloudSyncStatus status) {
    _status = status;
    notifyListeners();
  }
}
