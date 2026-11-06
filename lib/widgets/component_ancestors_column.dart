import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/bike.dart';
import '../models/component/component_ancestor.dart';
import 'component_ancestor_display.dart';

class ComponentAncestorsColumn extends StatelessWidget {
  final List<ComponentAncestor> ancestors;
  final Map<String, Bike> bikes;
  final double iconSize;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final TextStyle? textStyle;
  final Color? color;

  const ComponentAncestorsColumn({
    super.key,
    required this.ancestors,
    required this.bikes,
    this.iconSize = 14,
    this.spacing = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textStyle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variantColor = color ?? theme.colorScheme.onSurfaceVariant;
    final errorColor = theme.colorScheme.error;
    final l10n = context.l10n;
    final style = textStyle ?? theme.textTheme.bodySmall?.copyWith(color: variantColor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (final ancestor in ancestors)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: spacing,
            children: [
              Icon(ancestor.iconData, size: iconSize, color: ancestor.isMissing(bikes) ? errorColor : variantColor),
              Flexible(
                child: Text(
                  switch (ancestor) {
                    ArchivedAncestor() || UninstalledAncestor() => ancestor.label(bikes, l10n).toUpperCase(),
                    _ => ancestor.label(bikes, l10n),
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ancestor.isMissing(bikes) ? style?.copyWith(color: errorColor) : style,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
