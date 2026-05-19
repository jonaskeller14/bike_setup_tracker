import 'package:flutter/material.dart';
import 'dialog_action.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  String title = "Are you sure?",
  String? content = "This action cannot be undone.",
  String falseText = "Cancel",
  String trueText = "Continue",
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog.adaptive(
        title: Text(title),
        content: content == null ? null : Text(content),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(falseText),
          ),
          adaptiveAction(
            context: context,
            isDestructive: isDestructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(trueText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
