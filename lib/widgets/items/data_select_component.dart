import 'package:flutter/material.dart';
import '../../models/bike.dart';
import '../../models/component.dart';

class DataSelectComponent extends StatelessWidget {
  final Component component;
  final Map<String, Bike> bikes;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectComponent({
    super.key,
    required this.component,
    required this.bikes,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: Icon(component.componentType.getIconData()),
        title: Text(
          component.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: component.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(
              component.bike != null ? Bike.iconData : Icons.shelves,
              size: 13,
              color: component.bike == null || bikes.containsKey(component.bike)
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                component.bike == null
                    ? "Not installed"
                    : bikes[component.bike]?.name ?? "BIKE NOT FOUND",
                style: TextStyle(
                  color: component.bike == null || bikes.containsKey(component.bike)
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
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
