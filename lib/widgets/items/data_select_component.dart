import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/component.dart';
import '../../models/installation.dart';

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
              switch (component.latestInstallation) {
                Archival() => Icons.inventory_2_outlined,
                BikeInstallation() => Bike.iconData,
                Uninstallation() || null => Icons.shelves,
              },
              size: 13,
              color: switch (component.latestInstallation) {
                BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                _ => Theme.of(context).colorScheme.onSurfaceVariant,
              },
            ),
            Flexible(
              child: Text(
                switch (component.latestInstallation) {
                  Archival() => "Archived",
                  BikeInstallation(:final bikeId) => bikes[bikeId]?.name ?? "BIKE NOT FOUND",
                  Uninstallation() || null => "Not installed",
                },
                style: TextStyle(
                  color: switch (component.latestInstallation) {
                    BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                    _ => Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  },
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
