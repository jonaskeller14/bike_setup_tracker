import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/selected_data.dart';
import '../utils/file_import.dart';
import 'error_reporter.dart';

/// The end states of a move from Google Drive into cloud sync, plus
/// [offered] and [running] for the sheet.
enum DriveMoveState { offered, running, done, nothingToMove, signInFailed, offline, failed }

enum DriveReadFailure { signIn, offline }

/// Reading the Drive copy failed for a reason the user can fix.
class DriveReadException implements Exception {
  final DriveReadFailure failure;
  const DriveReadException(this.failure);

  @override
  String toString() => 'DriveReadException(${failure.name})';
}

/// What a Google Drive user is told before a later release removes Drive sync.
enum DriveNotice {
  /// Cloud sync is active: move the Drive copy into it.
  move,

  /// Cloud sync isn't active: save a backup file, or take the next step to
  /// cloud sync ([DriveEndingOffer]).
  ending,
}

/// The next step to cloud sync the [DriveNotice.ending] notice offers,
/// besides a backup file.
enum DriveEndingOffer { subscribe, turnOnSync, connectStrava }

/// [premium] is null while the subscription is not known yet, so the
/// [DriveNotice.ending] notice never offers the wrong step.
DriveNotice? driveNoticeFor({
  required bool driveOn,
  required bool syncActive,
  required bool? premium,
  required bool syncOn,
  required bool onAccount,
  required bool endingReleased,
}) {
  if (!driveOn) return null;
  if (syncActive) return DriveNotice.move;
  if (premium == null) return null;
  // Everything is in place and the sync is starting; the move offer follows.
  if (premium && syncOn && onAccount) return null;
  return endingReleased ? DriveNotice.ending : null;
}

/// The account session comes with the Strava link, so a subscriber with sync
/// on but no session connects Strava next.
DriveEndingOffer driveEndingOfferFor({required bool premium, required bool syncOn}) {
  if (!premium) return DriveEndingOffer.subscribe;
  return syncOn ? DriveEndingOffer.connectStrava : DriveEndingOffer.turnOnSync;
}

/// Each notice opens by itself only once. Afterwards it stays reachable from
/// the Google Drive sheet.
class DriveNoticePrompts {
  static String _key(DriveNotice notice) => 'driveNotice.${notice.name}.shown';

  static Future<bool> wasShown(DriveNotice notice) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key(notice)) ?? false;
  }

  static Future<void> markShown(DriveNotice notice) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key(notice), true);
  }
}

/// Moves the Google Drive copy into cloud sync once: reads the Drive file,
/// merges it like a file import, syncs, then turns Google Drive sync off.
/// Nothing is deleted from Google Drive.
class DriveMove {
  /// Null when Drive has no copy. Throws [DriveReadException].
  final Future<SelectedData?> Function() readDrive;
  final AppDatabase database;
  final Future<void> Function() afterMerge;
  final Future<void> Function() syncNow;
  final void Function() turnOffDrive;

  const DriveMove({
    required this.readDrive,
    required this.database,
    required this.afterMerge,
    required this.syncNow,
    required this.turnOffDrive,
  });

  Future<DriveMoveState> run() async {
    try {
      final data = await readDrive();
      if (data != null) {
        await FileImport.merge(remoteData: data, database: database);
        await afterMerge();
        await syncNow();
      }
      turnOffDrive();
      return data == null ? DriveMoveState.nothingToMove : DriveMoveState.done;
    } on DriveReadException catch (e) {
      return switch (e.failure) {
        DriveReadFailure.signIn => DriveMoveState.signInFailed,
        DriveReadFailure.offline => DriveMoveState.offline,
      };
    } catch (e, s) {
      recordNonFatal(e, s, reason: 'driveMove.run');
      return DriveMoveState.failed;
    }
  }
}
