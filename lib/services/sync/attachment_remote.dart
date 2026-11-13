import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// The cloud copy of the attachment files: `users/{uid}/attachments/{filename}`.
abstract interface class AttachmentRemote {
  /// The filenames in the account's attachments folder.
  Future<Set<String>> list(String uid);

  /// Uploads [file]. The rules reject an overwrite, the 25 MB file limit and
  /// anything beyond the 500 MB quota (`unauthorized`).
  Future<void> upload(String uid, String filename, File file);

  /// Writes the cloud file to [destination]. Returns false if there is none.
  Future<bool> download(String uid, String filename, File destination);

  /// Deletes the cloud file. A missing one is not an error: every device
  /// purges its own trash.
  Future<void> delete(String uid, String filename);

  /// Bytes the quota counts for the account, as the Storage rules see them.
  Future<int> storageBytes(String uid);
}

class FirebaseAttachmentRemote implements AttachmentRemote {
  // Without a limit an offline upload retries for ten minutes, which would
  // hold up the whole sync run.
  static const Duration _retryTime = Duration(seconds: 30);
  static const int _listPageSize = 1000;

  final FirebaseStorage? _storageOverride;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseAttachmentRemote({FirebaseStorage? storage, FirebaseFirestore? firestore})
    : _storageOverride = storage,
      _firestoreOverride = firestore;

  FirebaseStorage get _storage {
    final storage = _storageOverride ?? FirebaseStorage.instance;
    storage
      ..setMaxOperationRetryTime(_retryTime)
      ..setMaxUploadRetryTime(_retryTime)
      ..setMaxDownloadRetryTime(_retryTime);
    return storage;
  }

  Reference _folder(String uid) => _storage.ref('users/$uid/attachments');

  @override
  Future<Set<String>> list(String uid) async {
    final names = <String>{};
    String? pageToken;
    do {
      final page = await _folder(uid).list(ListOptions(maxResults: _listPageSize, pageToken: pageToken));
      names.addAll(page.items.map((item) => item.name));
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return names;
  }

  @override
  Future<void> upload(String uid, String filename, File file) async {
    await _folder(uid).child(filename).putFile(file);
  }

  @override
  Future<bool> download(String uid, String filename, File destination) async {
    try {
      await _folder(uid).child(filename).writeToFile(destination);
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return false;
      rethrow;
    }
  }

  @override
  Future<void> delete(String uid, String filename) async {
    try {
      await _folder(uid).child(filename).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  @override
  Future<int> storageBytes(String uid) async {
    final user = await (_firestoreOverride ?? FirebaseFirestore.instance)
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    return (user.data()?['storageBytes'] as num?)?.toInt() ?? 0;
  }
}
