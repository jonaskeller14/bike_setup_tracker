import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../services/backup_service.dart';
import '../services/image_storage_service.dart';
import '../services/strava_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';

class DataActions {
  static Future<void> resetAppSettings(BuildContext context) async {
    final appSettings = context.read<AppSettings>();
    final strava = context.read<StravaService>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Reset settings?',
      content: 'All preferences and features are restored to their defaults. Your data is not affected.',
      trueText: 'Reset',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    try {
      await appSettings.resetToDefaults();
      if (strava.isConnected) {
        unawaited(strava.setStravaNotificationsEnabled(appSettings.enableStravaNotifications));
      }
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.success(context, 'Settings reset to defaults.'));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, 'Resetting settings failed: $e'));
    }
  }

  static Future<void> deleteAllBackups(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete all backups?',
      content: 'All automatic backups stored on this device are deleted. This action cannot be undone.',
      trueText: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    try {
      final count = await BackupService.deleteAllBackups();
      if (!context.mounted) return;
      messenger.showSnackBar(
        AppSnackBar.success(context, count == 1 ? 'Deleted 1 backup.' : 'Deleted $count backups.'),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, 'Deleting backups failed: $e'));
    }
  }

  static Future<void> clearDatabase(BuildContext context) async {
    final database = context.read<AppRepository>().database;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Clear database?',
      content:
          'All bikes, components, setups, riders, ratings, tasks and images are deleted. '
          'A backup is saved first. This action cannot be undone.',
      trueText: 'Clear',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    final backup = await BackupService.saveBackup(database: database, force: true);
    if (backup == null) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, 'Could not save a backup. Database was not cleared.'));
      return;
    }

    try {
      await database.deleteAllUserData();
      await ImageStorageService().deleteAllImages();
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.success(context, 'Database cleared.'));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, 'Clearing database failed: $e'));
    }
  }
}
