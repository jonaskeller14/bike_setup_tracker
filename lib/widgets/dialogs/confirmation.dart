import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'dialog_action.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  String? title,
  String? content,
  String? falseText,
  String? trueText,
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog.adaptive(
        title: Text(title ?? context.l10n.confirmationTitle),
        content: Text(content ?? context.l10n.confirmationBody),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(falseText ?? context.l10n.cancel),
          ),
          adaptiveAction(
            context: context,
            isDestructive: isDestructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(trueText ?? context.l10n.continueLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
