import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../services/attachment_storage_service.dart';
import '../services/backup_service.dart';
import '../services/strava_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/sheets/filter.dart';
import 'filter_actions.dart';

class DataActions {
  static Future<void> resetAppSettings(BuildContext context) async {
    final appSettings = context.read<AppSettings>();
    final strava = context.read<StravaService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: context.l10n.dataResetSettingsTitle,
      content: context.l10n.dataResetSettingsBody,
      trueText: context.l10n.dataResetSettingsConfirm,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    try {
      FilterActions.clear(context, FilterSection.values.toSet());
      await appSettings.resetToDefaults();
      if (strava.isConnected) {
        unawaited(strava.setStravaNotificationsEnabled(appSettings.enableStravaNotifications));
      }
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.success(context, context.l10n.dataResetSettingsDone));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.dataResetSettingsFailed(e.toString())));
    }
  }

  static Future<void> deleteAllBackups(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: context.l10n.dataDeleteBackupsTitle,
      content: context.l10n.dataDeleteBackupsBody,
      trueText: context.l10n.dataDeleteBackupsConfirm,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    try {
      final count = await BackupService.deleteAllBackups();
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.success(context, context.l10n.dataDeleteBackupsDone(count)));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.dataDeleteBackupsFailed(e.toString())));
    }
  }

  static Future<void> clearDatabase(BuildContext context) async {
    final database = context.read<AppRepository>().database;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: context.l10n.dataClearDatabaseTitle,
      content: context.l10n.dataClearDatabaseBody,
      trueText: context.l10n.dataClearDatabaseConfirm,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    final backup = await BackupService.saveBackup(database: database, force: true);
    if (backup == null) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.dataClearDatabaseNoBackup));
      return;
    }

    try {
      await database.deleteAllUserData();
      await AttachmentStorageService().deleteAll();
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.success(context, context.l10n.dataClearDatabaseDone));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.dataClearDatabaseFailed(e.toString())));
    }
  }
}
