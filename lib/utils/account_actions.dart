import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/account_service.dart';
import '../services/cloud_sync_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/account_renewing_subscription.dart';
import '../widgets/dialogs/account_sign_out.dart';
import '../widgets/dialogs/confirmation.dart';

class AccountActions {
  /// Signs this device out of the account and leaves the account page.
  /// [onConfirmed] runs once the user has confirmed, before the call.
  static Future<void> signOut(BuildContext context, {VoidCallback? onConfirmed}) async {
    final l10n = context.l10n;
    final account = context.read<AccountService>();
    final removeData = await showAccountSignOutDialog(
      context,
      title: l10n.accountSignOutTitle,
      content: l10n.accountSignOutBody,
      confirmText: l10n.accountSignOutDeviceConfirm,
    );
    if (removeData == null || !context.mounted) return;
    onConfirmed?.call();
    if (!await _pushOrConfirm(context, removeData: removeData) || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = AppSnackBar.success(context, l10n.accountSignOutDone);
    final failed = AppSnackBar.error(context, l10n.accountSignOutFailed);
    try {
      await account.signOut(removeData: removeData);
      navigator.pop();
      messenger.showSnackBar(done);
    } catch (e) {
      messenger.showSnackBar(failed);
    }
  }

  /// With cloud sync on, the pending changes are pushed first. Only those
  /// that didn't make it are lost when the data is removed, so the user is
  /// asked then.
  static Future<bool> _pushOrConfirm(BuildContext context, {required bool removeData}) async {
    if (!context.read<AppSettings>().enableCloudSync) return true;
    final pending = await context.read<CloudSyncService>().pushBeforeSignOut();
    if (!removeData || pending == 0 || !context.mounted) return true;
    final l10n = context.l10n;
    return showConfirmationDialog(
      context,
      title: l10n.accountUnsyncedChangesTitle,
      content: l10n.accountUnsyncedChangesBody(pending),
      trueText: l10n.accountUnsyncedChangesConfirm,
      isDestructive: true,
    );
  }

  static Future<void> syncNow(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final done = AppSnackBar.success(context, l10n.accountSyncDone);
    final offline = AppSnackBar.info(context, l10n.accountSyncOfflineDone);
    final failed = AppSnackBar.error(context, l10n.accountSyncFailed);
    final storageFull = AppSnackBar.error(context, l10n.accountSyncStorageFull);
    final sync = context.read<CloudSyncService>();
    final status = await sync.syncNow();
    final snackBar = switch (status) {
      CloudSyncStatus.offline => offline,
      CloudSyncStatus.error => failed,
      CloudSyncStatus.idle when sync.attachmentQuotaFull => storageFull,
      CloudSyncStatus.idle || CloudSyncStatus.syncing => done,
    };
    if (snackBar == done) unawaited(HapticFeedback.successNotification());
    messenger.showSnackBar(snackBar);
  }

  static Future<void> signOutDevice(BuildContext context, AccountDevice device, {required String deviceLabel}) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.accountSignOutDeviceTitle(deviceLabel),
      content: l10n.accountSignOutDeviceBody,
      trueText: l10n.accountSignOutDeviceConfirm,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    final messenger = ScaffoldMessenger.of(context);
    final done = AppSnackBar.success(context, l10n.accountSignOutDeviceDone(deviceLabel));
    final failed = AppSnackBar.error(context, l10n.accountSignOutDeviceFailed);
    try {
      await context.read<AccountService>().revokeDevice(device.deviceId);
      messenger.showSnackBar(done);
    } catch (e) {
      messenger.showSnackBar(failed);
    }
  }

  /// Deletes the account, signs this device out and leaves the account page.
  /// A store subscription keeps renewing, so the user is told to cancel it.
  /// [onConfirmed] runs once the user has confirmed, before the call.
  static Future<void> deleteAccount(BuildContext context, {VoidCallback? onConfirmed}) async {
    final l10n = context.l10n;
    final account = context.read<AccountService>();
    final removeData = await showAccountSignOutDialog(
      context,
      title: l10n.accountDeleteTitle,
      content: l10n.accountDeleteBody,
      confirmText: l10n.accountDeleteConfirm,
    );
    if (removeData == null || !context.mounted) return;
    onConfirmed?.call();
    unawaited(HapticFeedback.heavyImpact());

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = AppSnackBar.success(context, l10n.accountDeleteDone);
    final failed = AppSnackBar.error(context, l10n.accountDeleteFailed);
    try {
      final result = await account.deleteAccount(removeData: removeData);
      navigator.pop();
      messenger.showSnackBar(done);
      if (result.subscriptionRenews && navigator.mounted) {
        await showRenewingSubscriptionDialog(navigator.context, platform: result.platform ?? 'android');
      }
    } catch (e) {
      messenger.showSnackBar(failed);
    }
  }

}
