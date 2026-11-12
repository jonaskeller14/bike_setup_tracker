import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../repositories/app_repository.dart';
import '../services/account_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/account_renewing_subscription.dart';
import '../widgets/dialogs/account_sign_out.dart';
import '../widgets/dialogs/confirmation.dart';

class AccountActions {
  /// Signs this device out of the account and leaves the account page.
  static Future<void> signOut(BuildContext context) async {
    final l10n = context.l10n;
    final account = context.read<AccountService>();
    final removeData = await showAccountSignOutDialog(
      context,
      title: l10n.accountSignOutTitle,
      content: l10n.accountSignOutBody,
      confirmText: l10n.accountSignOutDeviceConfirm,
    );
    if (removeData == null || !context.mounted) return;
    if (removeData && !await _confirmUnsyncedChanges(context)) return;
    if (!context.mounted) return;
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

  /// With cloud sync on, removing the data loses the changes the outbox
  /// still holds.
  static Future<bool> _confirmUnsyncedChanges(BuildContext context) async {
    if (!context.read<AppSettings>().enableCloudSync) return true;
    final pending = await context.read<AppRepository>().database.syncDao.watchPendingCount().first;
    if (pending == 0 || !context.mounted) return true;
    final l10n = context.l10n;
    return showConfirmationDialog(
      context,
      title: l10n.accountUnsyncedChangesTitle,
      content: l10n.accountUnsyncedChangesBody(pending),
      trueText: l10n.accountUnsyncedChangesConfirm,
      isDestructive: true,
    );
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
  static Future<void> deleteAccount(BuildContext context) async {
    final l10n = context.l10n;
    final account = context.read<AccountService>();
    final removeData = await showAccountSignOutDialog(
      context,
      title: l10n.accountDeleteTitle,
      content: l10n.accountDeleteBody,
      confirmText: l10n.accountDeleteConfirm,
    );
    if (removeData == null || !context.mounted) return;
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
