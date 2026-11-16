import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../services/account_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/drive_move.dart';
import '../services/google_drive_service.dart';
import '../services/subscription_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/drive_move_sheet.dart';
import '../widgets/sheets/strava.dart';
import 'file_export.dart';

/// The Drive notice that applies right now; rebuilds [context] when it changes.
DriveNotice? selectDriveNotice(BuildContext context) {
  final (driveOn, syncOn, developerMode) = context.select<AppSettings, (bool, bool, bool)>(
    (settings) => (settings.enableGoogleDrive, settings.enableCloudSync, settings.developerMode),
  );
  // Without Drive, the home page needn't rebuild on sync, subscription or account changes.
  if (!driveOn) return null;
  return driveNoticeFor(
    driveOn: driveOn,
    syncActive: context.select<CloudSyncService, bool>((sync) => sync.isActive),
    premium: context.select<SubscriptionService, bool?>((subscription) => subscription.premiumIfKnown),
    syncOn: syncOn,
    onAccount: context.select<AccountService, bool>((account) => account.isOnAccount),
    // Hidden until cloud sync ships to everyone (#17, 9b).
    endingReleased: developerMode,
  );
}

Future<void> showDriveNotice(BuildContext context, DriveNotice notice) => switch (notice) {
  DriveNotice.move => offerDriveMove(context),
  DriveNotice.ending => offerDriveEnding(context),
};

Future<void> offerDriveMove(BuildContext context) {
  final settings = context.read<AppSettings>();
  final repository = context.read<AppRepository>();
  final sync = context.read<CloudSyncService>();
  final drive = context.read<GoogleDriveService>();
  final move = DriveMove(
    readDrive: drive.readSyncData,
    database: context.read<AppDatabase>(),
    // Like a file import: the merged task entries carry the other device's snapshots.
    afterMerge: repository.refreshTaskEntrySnapshots,
    syncNow: sync.syncNow,
    turnOffDrive: () => settings.enableGoogleDrive = false,
  );
  return showDriveMoveSheet(context, move: move.run);
}

Future<void> offerDriveEnding(BuildContext context) async {
  final offer = driveEndingOfferFor(
    premium: context.read<SubscriptionService>().premiumIfKnown ?? false,
    syncOn: context.read<AppSettings>().enableCloudSync,
  );
  final choice = await showDriveEndingSheet(context, offer: offer);
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case DriveEndingChoice.saveFile:
      await FileExport.saveJson(context: context, database: context.read<AppDatabase>());
    case DriveEndingChoice.cloudSync:
      final settings = context.read<AppSettings>();
      final account = context.read<AccountService>();
      // The account session comes with the Strava link, so the Strava sheet
      // leads through whatever is missing: the purchase, then the link.
      switch (offer) {
        case DriveEndingOffer.turnOnSync:
          settings.enableCloudSync = true;
          if (account.isOnAccount) return _confirmCloudSyncOn(context);
          await showStravaSheet(context: context);
        case DriveEndingOffer.connectStrava:
          await showStravaSheet(context: context);
        case DriveEndingOffer.subscribe:
          await showStravaSheet(context: context);
          if (!context.mounted || context.read<SubscriptionService>().premiumIfKnown != true) return;
          settings.enableCloudSync = true;
          if (account.isOnAccount) _confirmCloudSyncOn(context);
      }
  }
}

/// Once sync is active, the Drive notice listener offers the move.
void _confirmCloudSyncOn(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.success(context, context.l10n.driveEndingSyncTurnedOn));
}
