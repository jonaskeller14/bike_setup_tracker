import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../services/account_service.dart';
import 'dialog_action.dart';

Future<bool> showStravaDisconnectDialog(BuildContext context) async {
  // On an account, Strava is disconnected for all of its devices.
  final onAccount = context.read<AppSettings>().enableAccounts && context.read<AccountService>().isOnAccount;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: Text(context.l10n.stravaDisconnectTitle),
        content: Text(onAccount ? context.l10n.stravaDisconnectBodyAccount : context.l10n.stravaDisconnectBody),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          adaptiveAction(
            context: context,
            isDestructive: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.stravaDisconnectConfirm),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
