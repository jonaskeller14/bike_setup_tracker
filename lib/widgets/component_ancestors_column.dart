import 'package:flutter/material.dart';

import '../models/bike.dart';
import '../models/component/component_ancestor.dart';
import 'component_ancestor_display.dart';

class ComponentAncestorsColumn extends StatelessWidget {
  final List<ComponentAncestor> ancestors;
  final Map<String, Bike> bikes;
  final double iconSize;
  final double spacing;
  /// Defaults to `bodySmall` in `onSurfaceVariant`.
  final TextStyle? textStyle;

  const ComponentAncestorsColumn({
    super.key,
    required this.ancestors,
    required this.bikes,
    this.iconSize = 14,
    this.spacing = 4,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variantColor = theme.colorScheme.onSurfaceVariant;
    final errorColor = theme.colorScheme.error;
    final style = textStyle ?? theme.textTheme.bodySmall?.copyWith(color: variantColor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ancestor in ancestors)
          Row(
            spacing: spacing,
            children: [
              Icon(ancestor.iconData, size: iconSize, color: ancestor.isMissing(bikes) ? errorColor : variantColor),
              Flexible(
                child: Text(
                  switch (ancestor) {
                    ArchivedAncestor() || UninstalledAncestor() => ancestor.label(bikes).toUpperCase(),
                    _ => ancestor.label(bikes),
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
