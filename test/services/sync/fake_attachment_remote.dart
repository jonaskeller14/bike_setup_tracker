import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/services/sync/attachment_remote.dart';
import 'package:firebase_core/firebase_core.dart';

/// The attachment folder of the cloud with the Storage rules that matter
/// here: no overwrite, and a quota that turns uploads down as `unauthorized`.
class FakeAttachmentRemote implements AttachmentRemote {
  final Map<String, List<int>> cloud = {};

  /// What `users/{uid}.storageBytes` says; null counts the stored files.
  int? reportedBytes;

  /// Uploads are rejected once the stored files would exceed this.
  int? quota;

  /// Every call times out, as without a connection.
  bool offline = false;

  /// Thrown by the next call of any kind, once.
  Exception? failNext;

  /// Thrown by every upload of these files.
  final Map<String, Exception> uploadErrors = {};

  /// Downloads wait for this before they finish.
  Completer<void>? downloadGate;

  int lists = 0;
  int uploads = 0;
  int uploadAttempts = 0;
  int downloads = 0;
  int deletes = 0;
  int concurrentDownloads = 0;
  int maxConcurrentDownloads = 0;
  final List<String> deleted = [];

  static FirebaseException denied() => FirebaseException(plugin: 'firebase_storage', code: 'unauthorized');

  int get used => cloud.values.fold(0, (sum, bytes) => sum + bytes.length);

  void _maybeFail() {
    if (offline) throw TimeoutException('offline');
    if (failNext case final error?) {
      failNext = null;
      throw error;
    }
  }

  @override
  Future<Set<String>> list(String uid) async {
    _maybeFail();
    lists++;
    return cloud.keys.toSet();
  }

  @override
  Future<void> upload(String uid, String filename, File file) async {
    _maybeFail();
    uploadAttempts++;
    if (uploadErrors[filename] case final error?) throw error;
    final bytes = await file.readAsBytes();
    if (cloud.containsKey(filename) || (quota != null && used + bytes.length > quota!)) throw denied();
    uploads++;
    cloud[filename] = bytes;
  }

  @override
  Future<bool> download(String uid, String filename, File destination) async {
    _maybeFail();
    downloads++;
    concurrentDownloads++;
    if (concurrentDownloads > maxConcurrentDownloads) maxConcurrentDownloads = concurrentDownloads;
    try {
      await downloadGate?.future;
      final bytes = cloud[filename];
      if (bytes == null) return false;
      await destination.writeAsBytes(bytes);
      return true;
    } finally {
      concurrentDownloads--;
    }
  }

  @override
  Future<void> delete(String uid, String filename) async {
    _maybeFail();
    deletes++;
    deleted.add(filename);
    cloud.remove(filename);
  }

  @override
  Future<int> storageBytes(String uid) async => reportedBytes ?? used;
}
