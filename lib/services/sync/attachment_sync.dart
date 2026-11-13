import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../models/attachment.dart';
import '../attachment_storage_service.dart';
import '../error_reporter.dart';
import 'attachment_remote.dart';
import 'sync_engine.dart';

enum AttachmentDownloadResult {
  /// Already on this device.
  present,
  downloaded,

  /// Not (yet) in the cloud: another device may not have uploaded it yet.
  notInCloud,
  offline,
  failed,

  /// Cloud sync is not running (off, not premium or not signed in).
  notSyncing;

  bool get isAvailable => this == present || this == downloaded;
}

/// Files whose last record was purged from the local trash and that still
/// have to go from the cloud. Kept across restarts: the purge runs at app
/// start, often before the account session is back or while offline.
class AttachmentDeleteQueue {
  static const String _key = 'cloudAttachments.pendingDeletes';

  /// Queues [filenames], but only on a device that has synced: everyone else
  /// has nothing in the cloud to delete.
  static Future<void> add(Iterable<String> filenames) async {
    if (filenames.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(SyncEngine.syncedUidKey) == null) return;
    await prefs.setStringList(_key, {...?prefs.getStringList(_key), ...filenames}.toList());
  }

  static Future<Set<String>> read() async => ((await SharedPreferences.getInstance()).getStringList(_key) ?? []).toSet();

  static Future<void> remove(Iterable<String> filenames) async {
    final prefs = await SharedPreferences.getInstance();
    final rest = {...?prefs.getStringList(_key)}.difference(filenames.toSet());
    await prefs.setStringList(_key, rest.toList());
  }
}

typedef _Failure = ({DateTime at, AttachmentDownloadResult result});
typedef _Retry = ({int attempts, DateTime notBefore});

/// Keeps the attachment files in step with the cloud: uploads the files the
/// synced records reference, deletes the ones whose records were purged, and
/// downloads a missing one when it is first viewed.
class AttachmentSync {
  static const int quotaBytes = 500 * 1024 * 1024;
  static const Duration _firstRetryDelay = Duration(seconds: 30);
  static const Duration _maxRetryDelay = Duration(hours: 1);
  static const Duration _failureMemory = Duration(minutes: 1);

  final AppDatabase db;
  final AttachmentRemote remote;
  final AttachmentStorageService storage;
  final VoidCallback onChanged;
  final int maxConcurrentDownloads;
  final DateTime Function() _now;
  final Future<Directory> Function() _tempDir;

  AttachmentSync(
    this.db, {
    required this.remote,
    required this.onChanged,
    AttachmentStorageService? storage,
    this.maxConcurrentDownloads = 3,
    @visibleForTesting DateTime Function()? now,
    @visibleForTesting Future<Directory> Function()? tempDir,
  }) : storage = storage ?? AttachmentStorageService(),
       _now = now ?? DateTime.now,
       _tempDir = tempDir ?? getTemporaryDirectory;

  final Map<String, _Retry> _retries = {};
  final Set<String> _quotaBlocked = {};
  final Set<String> _knownInCloud = {};
  final Map<String, _Failure> _failures = {};
  final Map<String, Future<AttachmentDownloadResult>> _downloads = {};
  final Queue<Completer<void>> _waiting = Queue();
  int _activeDownloads = 0;
  int _pendingUploads = 0;

  /// Local files the cloud doesn't have yet.
  int get pendingUploads => _pendingUploads;

  /// A file couldn't be uploaded because the account is over its quota.
  bool get quotaFull => _quotaBlocked.isNotEmpty;

  /// Forget everything learned about the previous account.
  void reset() {
    _retries.clear();
    _quotaBlocked.clear();
    _knownInCloud.clear();
    _failures.clear();
    _pendingUploads = 0;
    onChanged();
  }

  static bool isOffline(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is FirebaseException &&
          const {'unavailable', 'deadline-exceeded', 'retry-limit-exceeded', 'network-request-failed'}.contains(
            error.code,
          );

  /// The rules turned the request down: a revoked session or lapsed premium
  /// (Storage reports `unauthorized`, Firestore `permission-denied`).
  static bool isDenied(Object error) =>
      error is FirebaseException && (error.code == 'unauthorized' || error.code == 'permission-denied');

  /// Deletes the queued cloud files, then uploads the missing ones.
  Future<void> run(String uid, {required void Function() ensureCurrent}) async {
    final referenced = await db.referencedAttachmentFilenames();
    await _deleteQueued(uid, referenced, ensureCurrent);
    await _upload(uid, referenced, ensureCurrent);
  }

  Future<void> _deleteQueued(String uid, Set<String> referenced, void Function() ensureCurrent) async {
    final queued = await AttachmentDeleteQueue.read();
    // A file referenced again (the same bundle imported anew) must stay.
    await AttachmentDeleteQueue.remove(queued.intersection(referenced));
    for (final filename in queued.difference(referenced)) {
      ensureCurrent();
      await remote.delete(uid, filename);
      await AttachmentDeleteQueue.remove([filename]);
    }
  }

  Future<void> _upload(String uid, Set<String> referenced, void Function() ensureCurrent) async {
    final local = <String>{
      for (final filename in referenced)
        if (await storage.exists(filename)) filename,
    };
    if (local.isEmpty) {
      _pruneQuotaBlocked(const {});
      _setPending(0);
      return;
    }

    final Set<String> inCloud;
    try {
      ensureCurrent();
      inCloud = await remote.list(uid);
    } catch (_) {
      _setPending(local.difference(_knownInCloud).length);
      rethrow;
    }
    _knownInCloud.addAll(inCloud);
    final missing = local.difference(inCloud);
    _pruneQuotaBlocked(missing);
    _setPending(missing.length);

    var uploaded = 0;
    for (final filename in missing) {
      ensureCurrent();
      if (_isWaiting(filename)) continue;
      if (await _uploadOne(uid, filename)) {
        uploaded++;
        _setPending(missing.length - uploaded);
      }
    }
  }

  /// Only a file that still waits can keep the quota flag up.
  void _pruneQuotaBlocked(Set<String> missing) {
    final before = _quotaBlocked.length;
    _quotaBlocked.removeWhere((filename) => !missing.contains(filename));
    if (_quotaBlocked.length != before) onChanged();
  }

  bool _isWaiting(String filename) {
    final retry = _retries[filename];
    return retry != null && retry.notBefore.isAfter(_now());
  }

  Future<bool> _uploadOne(String uid, String filename) async {
    final file = await storage.resolve(filename);
    try {
      await remote.upload(uid, filename, file);
      _uploaded(filename);
      return true;
    } catch (e, s) {
      if (isOffline(e)) rethrow;
      if (isDenied(e)) {
        final handled = await _onDenied(uid, filename, file);
        if (handled == null) rethrow;
        return handled;
      }
      // One broken file must not fail every sync: report it once and retry later.
      if (!_retries.containsKey(filename)) recordNonFatal(e, s, reason: 'cloudSync.attachmentUpload');
      _backoff(filename);
      return false;
    }
  }

  /// A denied upload means one of: the file is already there (two devices
  /// imported the same bundle, and the rules never overwrite), the quota is
  /// full, or the session or premium is gone, which the caller handles (null).
  Future<bool?> _onDenied(String uid, String filename, File file) async {
    if ((await remote.list(uid)).contains(filename)) {
      _uploaded(filename);
      return true;
    }
    if (await remote.storageBytes(uid) + await file.length() > quotaBytes) {
      _quotaBlocked.add(filename);
      _backoff(filename);
      onChanged();
      return false;
    }
    return null;
  }

  void _uploaded(String filename) {
    _retries.remove(filename);
    _knownInCloud.add(filename);
    if (_quotaBlocked.remove(filename)) onChanged();
  }

  void _backoff(String filename) {
    final attempts = (_retries[filename]?.attempts ?? 0) + 1;
    final delay = _firstRetryDelay * (1 << (attempts - 1).clamp(0, 12));
    _retries[filename] = (attempts: attempts, notBefore: _now().add(delay > _maxRetryDelay ? _maxRetryDelay : delay));
  }

  void _setPending(int count) {
    if (count == _pendingUploads) return;
    _pendingUploads = count;
    onChanged();
  }

  /// Makes sure [attachment]'s file is on this device, fetching it from the
  /// cloud if needed. A recent failure is answered again without asking the
  /// cloud, unless [force]d (the user's retry).
  Future<AttachmentDownloadResult> download(String uid, Attachment attachment, {bool force = false}) {
    final filename = attachment.filename;
    // Not `=> remove(...)`: whenComplete would wait for the Future that returns, which is this very download.
    return _downloads[filename] ??= _download(uid, filename, force: force).whenComplete(() {
      unawaited(_downloads.remove(filename));
    });
  }

  Future<AttachmentDownloadResult> _download(String uid, String filename, {required bool force}) async {
    final file = await storage.resolve(filename);
    if (file.existsSync()) return AttachmentDownloadResult.present;
    final failure = _failures[filename];
    if (!force && failure != null && _now().difference(failure.at) < _failureMemory) return failure.result;

    await _acquireSlot();
    final temp = File(p.join((await _tempDir()).path, '$filename.${const Uuid().v4()}.download'));
    try {
      await storage.ensureDir();
      if (!await remote.download(uid, filename, temp)) return _failed(filename, AttachmentDownloadResult.notInCloud);
      await _moveInto(temp, file);
      _failures.remove(filename);
      return AttachmentDownloadResult.downloaded;
    } catch (e, s) {
      if (isOffline(e)) return _failed(filename, AttachmentDownloadResult.offline);
      if (!isDenied(e)) recordNonFatal(e, s, reason: 'cloudSync.attachmentDownload');
      return _failed(filename, AttachmentDownloadResult.failed);
    } finally {
      if (temp.existsSync()) await temp.delete();
      _releaseSlot();
    }
  }

  AttachmentDownloadResult _failed(String filename, AttachmentDownloadResult result) {
    _failures[filename] = (at: _now(), result: result);
    return result;
  }

  /// The file only appears under its final name once complete: a half-written
  /// one would count as present and never be fetched again.
  static Future<void> _moveInto(File temp, File destination) async {
    try {
      await temp.rename(destination.path);
    } on FileSystemException {
      await temp.copy(destination.path);
    }
  }

  Future<void> _acquireSlot() async {
    if (_activeDownloads < maxConcurrentDownloads) {
      _activeDownloads++;
      return;
    }
    final turn = Completer<void>();
    _waiting.add(turn);
    await turn.future;
  }

  void _releaseSlot() {
    if (_waiting.isEmpty) {
      _activeDownloads--;
    } else {
      _waiting.removeFirst().complete();
    }
  }
}
