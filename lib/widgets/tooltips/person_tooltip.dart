import 'package:flutter/material.dart';

import '../../models/person.dart';
import 'entity_tooltip_content.dart';
import 'info_tooltip.dart';
import 'tooltip_style.dart';

/// Tooltip for a [Person]: name and notes.
class PersonTooltip extends StatelessWidget {
  final Person person;
  final Widget child;
  final bool isError;
  final TooltipStyle? style;
  final TooltipTriggerMode triggerMode;

  const PersonTooltip({
    super.key,
    required this.person,
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
        name: person.name,
        notes: person.notes,
        errorDescription: isError ? "Person is not linked to this setup" : null,
      ),
      child: child,
    );
  }
}
