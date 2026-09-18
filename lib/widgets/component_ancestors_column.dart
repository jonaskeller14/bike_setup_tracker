import 'package:flutter/material.dart';

import '../models/bike.dart';
import '../models/component.dart';
import '../services/component_hierarchy_resolver.dart';

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
              Icon(_icon(ancestor), size: iconSize, color: _isMissing(ancestor) ? errorColor : variantColor),
              Flexible(
                child: Text(
                  _label(ancestor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _isMissing(ancestor) ? style?.copyWith(color: errorColor) : style,
                ),
              ),
            ],
          ),
      ],
    );
  }

  bool _isMissing(ComponentAncestor ancestor) => switch (ancestor) {
    MissingParentAncestor() => true,
    BikeAncestor(:final bikeId) => !bikes.containsKey(bikeId),
    _ => false,
  };

  IconData _icon(ComponentAncestor ancestor) => switch (ancestor) {
    ParentComponentAncestor(:final component) => component.componentType.getIconData(),
    MissingParentAncestor() => Component.iconData,
    BikeAncestor() => Bike.iconData,
    ArchivedAncestor() => Icons.inventory_2_outlined,
    UninstalledAncestor() => Icons.shelves,
  };

  String _label(ComponentAncestor ancestor) => switch (ancestor) {
    ParentComponentAncestor(:final component) => component.name,
    MissingParentAncestor() => 'COMPONENT NOT FOUND',
    BikeAncestor(:final bikeId) => bikes[bikeId]?.name ?? 'BIKE NOT FOUND',
    ArchivedAncestor() => 'ARCHIVED',
    UninstalledAncestor() => 'UNINSTALLED',
  };
}
