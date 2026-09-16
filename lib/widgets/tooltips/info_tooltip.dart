import 'package:flutter/material.dart';

import 'tooltip_style.dart';

/// A themed tooltip shared by entity (component/person) tooltips and the
/// compact adjustment display's value-cell tooltips.
Tooltip infoTooltip({
  required BuildContext context,
  required TooltipStyle style,
  required Widget message,
  required Widget child,
  TooltipTriggerMode triggerMode = TooltipTriggerMode.longPress,
}) {
  return Tooltip(
    triggerMode: triggerMode,
    preferBelow: false,
    showDuration: const Duration(seconds: 5),
    enableTapToDismiss: false,
    decoration: BoxDecoration(
      color: style.background,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(12),
    richMessage: WidgetSpan(child: message),
    child: child,
  );
}
