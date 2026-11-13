import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../models/selected_data.dart';
import '../../utils/backup.dart';
import '../data_export_service.dart';
import '../error_reporter.dart';
import 'attachment_sync.dart';
import 'backup_remote.dart';
import 'sync_engine.dart';

/// The account's daily JSON snapshots in the cloud. A lifecycle rule on the
/// bucket deletes them after 30 days by their `_backup.json` suffix. They hold
/// the records only; the attachment files stay in the attachments folder.
class CloudBackups {
  static const Duration frequency = Duration(days: 1);
  static const Duration _retryDelay = Duration(hours: 1);
  static const String _lastBackupKey = 'cloudBackup.lastBackupAt';
  static final RegExp _filenamePattern = RegExp(r'^(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})_backup\.json$');

  final AppDatabase db;
  final BackupRemote remote;
  final DateTime Function() _now;

  CloudBackups(this.db, {required this.remote, @visibleForTesting DateTime Function()? now})
    : _now = now ?? DateTime.now;

  DateTime? _notBefore;

  static String filenameFor(DateTime time) =>
      '${DateFormat('yyyyMMdd_HHmmss', 'en_US').format(time.toUtc())}_backup.json';

  /// The UTC time in a backup's filename, or null for any other file.
  static DateTime? createdAtOf(String filename) {
    final match = _filenamePattern.firstMatch(filename);
    if (match == null) return null;
    final [year, month, day, hour, minute, second] = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    return DateTime.utc(year, month, day, hour, minute, second);
  }

  /// Forget the back-off of the previous account.
  void reset() => _notBefore = null;

  Future<List<CloudBackup>> list(String uid) async => [
    for (final filename in await remote.list(uid))
      if (createdAtOf(filename) case final createdAt?) CloudBackup(createdAt: createdAt, filename: filename),
  ];

  Future<SelectedData> read(String uid, CloudBackup backup) async {
    final bytes = await remote.download(uid, backup.filename);
    return SelectedData.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
  }

  /// Uploads a snapshot unless the account got one within [frequency], from
  /// this device or another. A failed backup never fails the sync: offline it
  /// is tried again on the next run, otherwise an hour later. The likely
  /// denial is a full quota; a revoked session fails the records step first.
  Future<void> saveIfDue(String uid, {required void Function() ensureCurrent}) async {
    final now = _now().toUtc();
    if (_notBefore case final notBefore? when now.isBefore(notBefore)) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_lastBackupKey.$uid';
    final last = DateTime.tryParse(prefs.getString(key) ?? '');
    if (last != null && now.difference(last) < frequency) return;
    if (!await db.watchHasUserData().first) return;

    try {
      ensureCurrent();
      var newest = (await list(uid)).map((backup) => backup.createdAt).maxOrNull;
      if (newest == null || now.difference(newest) >= frequency) {
        final json = jsonEncode(await DataExportService.backupDatabaseToJson(db));
        ensureCurrent();
        await remote.upload(uid, filenameFor(now), utf8.encode(json));
        newest = now;
      }
      await prefs.setString(key, newest.toIso8601String());
      _notBefore = null;
    } on SyncCancelled {
      rethrow;
    } catch (e, s) {
      if (AttachmentSync.isOffline(e)) return;
      _notBefore = now.add(_retryDelay);
      if (!AttachmentSync.isDenied(e)) recordNonFatal(e, s, reason: 'cloudSync.backup');
    }
  }
}
