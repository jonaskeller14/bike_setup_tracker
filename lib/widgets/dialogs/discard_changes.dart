import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'dialog_action.dart';

Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: Text(context.l10n.discardChangesTitle),
        content: Text(context.l10n.discardChangesBody),
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
            child: Text(context.l10n.discardChangesConfirm),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
