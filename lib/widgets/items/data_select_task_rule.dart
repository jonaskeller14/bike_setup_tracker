import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/task/task_rule.dart';

class DataSelectTaskRule extends StatelessWidget {
  final TaskRule item;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectTaskRule({
    super.key,
    required this.item,
    required this.bikes,
    required this.components,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final component = item.componentId != null
        ? components[item.componentId]
        : null;
    final bike = item.bikeId != null
        ? bikes[item.bikeId]
        : (component?.bike != null
              ? bikes[component!.bike]
              : null);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Icons.check_box_outline_blank),
        title: Text(
          item.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            if (item.componentId != null) ...[
              Icon(
                component?.componentType.getIconData() ?? Icons.grid_view_sharp,
                size: 13,
                color: component != null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.error,
              ),
              Flexible(
                child: Text(
                  component?.name ?? "COMPONENT NOT FOUND",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: component != null
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ] else if (item.bikeId != null) ...[
              Icon(
                Bike.iconData,
                size: 13,
                color: bike != null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.error,
              ),
              Flexible(
                child: Text(
                  bike?.name ?? "BIKE NOT FOUND",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: bike != null
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.circle_outlined,
                size: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Flexible(
                child: Text(
                  "General Task",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
