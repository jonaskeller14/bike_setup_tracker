import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget adaptiveAction({
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
