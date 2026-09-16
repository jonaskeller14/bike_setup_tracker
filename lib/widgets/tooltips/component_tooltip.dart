import 'package:flutter/material.dart';

import '../../models/component.dart';
import 'entity_tooltip_content.dart';
import 'info_tooltip.dart';
import 'tooltip_style.dart';

/// Tooltip for a [Component]: name, notes, and (when entitled) Strava usage
/// stats.
class ComponentTooltip extends StatelessWidget {
  final Component component;
  final Widget child;
  final bool isError;
  final TooltipStyle? style;
  final TooltipTriggerMode triggerMode;

  const ComponentTooltip({
    super.key,
    required this.component,
    required this.child,
    this.isError = false,
    this.style,
    this.triggerMode = TooltipTriggerMode.longPress,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? TooltipStyle.inverse(context);
    return infoTooltip(
      context: context,
      style: resolvedStyle,
      triggerMode: triggerMode,
      message: EntityTooltipContent(
        style: resolvedStyle,
        name: component.name,
        notes: component.notes,
        stats: component.totalStats,
        errorDescription: isError ? "Component was not installed at setup time" : null,
      ),
      child: child,
    );
  }
}
