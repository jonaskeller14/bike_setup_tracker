import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/component/installation.dart';

class DataSelectComponent extends StatelessWidget {
  final Component component;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectComponent({
    super.key,
    required this.component,
    required this.bikes,
    required this.components,
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
                ComponentInstallation(:final parentComponentId) =>
                  components[parentComponentId]?.componentType.getIconData() ?? Component.iconData,
                Uninstallation() || null => Icons.shelves,
              },
              size: 13,
              color: switch (component.latestInstallation) {
                BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                ComponentInstallation(:final parentComponentId) when !components.containsKey(parentComponentId) => Theme.of(context).colorScheme.error,
                _ => Theme.of(context).colorScheme.onSurfaceVariant,
              },
            ),
            Flexible(
              child: Text(
                switch (component.latestInstallation) {
                  Archival() => context.l10n.timelineArchived,
                  BikeInstallation(:final bikeId) => bikes[bikeId]?.name ?? context.l10n.bikeNotFound,
                  ComponentInstallation(:final parentComponentId) =>
                    components[parentComponentId]?.name ?? context.l10n.componentNotFound,
                  Uninstallation() || null => context.l10n.timelineNotInstalled,
                },
                style: TextStyle(
                  color: switch (component.latestInstallation) {
                    BikeInstallation(:final bikeId) when !bikes.containsKey(bikeId) => Theme.of(context).colorScheme.error,
                    ComponentInstallation(:final parentComponentId) when !components.containsKey(parentComponentId) => Theme.of(context).colorScheme.error,
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
