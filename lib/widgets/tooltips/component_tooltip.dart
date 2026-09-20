import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/component.dart';
import '../../models/component_stats.dart';
import '../../repositories/app_repository.dart';
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
    final stats = context.select<AppRepository, ComponentStats>(
      (repository) => repository.componentStatsOf(component.id),
    );
    return infoTooltip(
      context: context,
      style: resolvedStyle,
      triggerMode: triggerMode,
      message: EntityTooltipContent(
        style: resolvedStyle,
        name: component.name,
        notes: component.notes,
        stats: stats,
        errorDescription: isError ? "Component was not installed at setup time" : null,
      ),
      child: child,
    );
  }
}
