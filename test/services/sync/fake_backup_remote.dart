import 'dart:async';
import 'dart:typed_data';

import 'package:bike_setup_tracker/services/sync/backup_remote.dart';
import 'package:firebase_core/firebase_core.dart';

/// The backups folder of the cloud.
class FakeBackupRemote implements BackupRemote {
  final Map<String, Uint8List> cloud = {};

  /// Every call times out, as without a connection.
  bool offline = false;

  /// Uploads are turned down as by the quota rule.
  bool quotaFull = false;

  int lists = 0;
  int uploads = 0;

  static FirebaseException denied() => FirebaseException(plugin: 'firebase_storage', code: 'unauthorized');

  @override
  Future<List<String>> list(String uid) async {
    if (offline) throw TimeoutException('offline');
    lists++;
    return cloud.keys.toList();
  }

  @override
  Future<void> upload(String uid, String filename, Uint8List bytes) async {
    if (offline) throw TimeoutException('offline');
    if (quotaFull) throw denied();
    uploads++;
    cloud[filename] = bytes;
  }

  @override
  Future<Uint8List> download(String uid, String filename) async {
    if (offline) throw TimeoutException('offline');
    return cloud[filename] ?? (throw FirebaseException(plugin: 'firebase_storage', code: 'object-not-found'));
  }
}
