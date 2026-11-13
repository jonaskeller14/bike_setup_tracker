import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// The cloud copy of the daily snapshots: `users/{uid}/backups/{filename}`.
abstract interface class BackupRemote {
  /// The filenames in the account's backups folder.
  Future<List<String>> list(String uid);

  /// Uploads [bytes] as JSON. The rules only accept `yyyyMMdd_HHmmss_backup.json`
  /// names and reject anything beyond the 500 MB quota (`unauthorized`).
  Future<void> upload(String uid, String filename, Uint8List bytes);

  Future<Uint8List> download(String uid, String filename);
}

class FirebaseBackupRemote implements BackupRemote {
  // Without a limit an offline upload retries for ten minutes, which would
  // hold up the whole sync run.
  static const Duration _retryTime = Duration(seconds: 30);
  static const int _listPageSize = 1000;
  // getData holds the whole file in memory and refuses anything larger.
  static const int _maxDownloadBytes = 200 * 1024 * 1024;

  final FirebaseStorage? _storageOverride;

  FirebaseBackupRemote({FirebaseStorage? storage}) : _storageOverride = storage;

  FirebaseStorage get _storage {
    final storage = _storageOverride ?? FirebaseStorage.instance;
    storage
      ..setMaxOperationRetryTime(_retryTime)
      ..setMaxUploadRetryTime(_retryTime)
      ..setMaxDownloadRetryTime(_retryTime);
    return storage;
  }

  Reference _folder(String uid) => _storage.ref('users/$uid/backups');

  @override
  Future<List<String>> list(String uid) async {
    final names = <String>[];
    String? pageToken;
    do {
      final page = await _folder(uid).list(ListOptions(maxResults: _listPageSize, pageToken: pageToken));
      names.addAll(page.items.map((item) => item.name));
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return names;
  }

  @override
  Future<void> upload(String uid, String filename, Uint8List bytes) async {
    await _folder(uid).child(filename).putData(bytes, SettableMetadata(contentType: 'application/json'));
  }

  @override
  Future<Uint8List> download(String uid, String filename) async {
    final bytes = await _folder(uid).child(filename).getData(_maxDownloadBytes);
    if (bytes == null) throw StateError('Backup $filename is empty');
    return bytes;
  }
}
