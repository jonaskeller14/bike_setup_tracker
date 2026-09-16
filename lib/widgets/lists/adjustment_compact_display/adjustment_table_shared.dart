import 'package:flutter/material.dart';

/// A themed long-press tooltip shared by the compact adjustment table's row
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

/// The thin separator between adjacent cells in a compact adjustment row.
class AdjustmentTableDivider extends StatelessWidget {
  static const double width = 1;

  final Color color;

  const AdjustmentTableDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 28,
      color: color,
    );
  }
}
