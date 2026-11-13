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
import 'sync/sync_engine.dart';
import 'sync/sync_remote.dart';

enum CloudSyncStatus { idle, syncing, offline, error }

/// Keeps the local data and the account's cloud copy in step. Runs after
/// local edits (debounced), on app resume and on "Sync now"; there are no
/// live listeners, since every snapshot costs reads. Only active with cloud
/// sync on, premium and an account session. The attachment files travel with
/// each run: uploaded after the records, downloaded when first viewed. The
/// daily cloud backup is the last step of a run.
class CloudSyncService extends ChangeNotifier with WidgetsBindingObserver implements UserBoundService {
  static const String _lastSyncKey = 'cloudSync.lastSyncAt';

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
  Timer? _debounceTimer;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  CloudSyncStatus get status => _status;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get pendingCount => _pendingCount;

  /// Attachment files that are not in the cloud yet.
  int get pendingAttachmentUploads => _attachments.pendingUploads;

  /// An attachment couldn't be uploaded because the 500 MB quota is full.
  bool get attachmentQuotaFull => _attachments.quotaFull;

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
      if (active) unawaited(_requestSync());
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
          _debounceTimer = Timer(_debounce, () => unawaited(_requestSync()));
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
    if (state == AppLifecycleState.resumed && isActive) unawaited(_requestSync());
  }

  /// Runs a sync now, or once more after the running one, and returns the
  /// resulting status.
  Future<CloudSyncStatus> syncNow() async {
    if (!isActive) return _status;
    await _requestSync();
    return _status;
  }

  /// Fetches an attachment file this device doesn't have from the cloud.
  /// [force] asks again after a recent failure.
  Future<AttachmentDownloadResult> downloadAttachment(Attachment attachment, {bool force = false}) {
    final uid = _uid;
    if (uid == null || !isActive) return Future.value(AttachmentDownloadResult.notSyncing);
    return _attachments.download(uid, attachment, force: force);
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
    if (isActive) await _requestSync();
    return await _database.syncDao.watchPendingCount().first + _attachments.pendingUploads;
  }

  Future<void> _requestSync() {
    _debounceTimer?.cancel();
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
    } while (_runAgain && isActive);
  }

  Future<void> _runOnce() async {
    final uid = _uid;
    if (uid == null || !isActive) return;
    _setStatus(CloudSyncStatus.syncing);
    void ensureCurrent() {
      if (_uid != uid || !isActive) throw const SyncCancelled();
    }

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
    }
  }

  void _setStatus(CloudSyncStatus status) {
    _status = status;
    notifyListeners();
  }
}
