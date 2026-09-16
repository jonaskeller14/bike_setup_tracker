import 'package:flutter/material.dart';

/// A themed long-press tooltip shared by the compact adjustment view's owner
/// icon and value cells.
Tooltip infoTooltip({
  required BuildContext context,
  required Widget message,
  required Widget child,
}) {
  return Tooltip(
    triggerMode: TooltipTriggerMode.longPress,
    preferBelow: false,
    showDuration: const Duration(seconds: 5),
    enableTapToDismiss: false,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.inverseSurface,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(12),
    richMessage: WidgetSpan(child: message),
    child: child,
  );
}
