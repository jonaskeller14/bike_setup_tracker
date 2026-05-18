import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog.adaptive(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to exit without saving?'),
        actions: [
          _adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          _adaptiveAction(
            context: context,
            isDestructive: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard Changes'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Widget _adaptiveAction({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
  bool isDestructive = false,
}) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CupertinoDialogAction(
        isDestructiveAction: isDestructive,
        onPressed: onPressed,
        child: child,
      );
    default:
      return TextButton(
        onPressed: onPressed,
        style: isDestructive
            ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
            : null,
        child: child,
      );
  }
}
