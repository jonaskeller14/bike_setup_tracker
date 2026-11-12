import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../utils/url.dart';
import 'dialog_action.dart';

/// Tells the user that a store subscription keeps renewing after the account
/// was deleted, and offers to open the store's subscription page.
Future<void> showRenewingSubscriptionDialog(BuildContext context, {required String platform}) {
  final l10n = context.l10n;
  final store = platform == 'ios' ? 'Apple App Store' : 'Google Play Store';
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog.adaptive(
      title: Text(l10n.accountDeleteSubscriptionTitle),
      content: Text(l10n.accountDeleteSubscriptionBody(store)),
      actions: [
        adaptiveAction(
          context: dialogContext,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
        adaptiveAction(
          context: dialogContext,
          onPressed: () {
            Navigator.of(dialogContext).pop();
            unawaited(
              launchAppUrl(
                context,
                url: storeSubscriptionsUrl(platform),
                launchMode: LaunchMode.externalApplication,
              ),
            );
          },
          child: Text(l10n.settingsManageSubscription),
        ),
      ],
    ),
  );
}
