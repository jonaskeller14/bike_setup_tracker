import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/setup.dart';

class DataSelectSetup extends StatelessWidget {
  final Setup setup;
  final Map<String, Bike> bikes;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectSetup({
    super.key,
    required this.setup,
    required this.bikes,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Setup.iconData),
        title: Text(
          setup.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: setup.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(
              Bike.iconData,
              size: 13,
              color: bikes.containsKey(setup.bike)
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                bikes[setup.bike]?.name ?? "BIKE NOT FOUND",
                style: TextStyle(
                  color: bikes.containsKey(setup.bike)
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
