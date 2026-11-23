import 'package:flutter/material.dart';

import '../../l10n/entity_names.dart';
import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/setup.dart';
import '../../services/data_selection_dependencies.dart';
import 'data_select_missing_line.dart';

class DataSelectSetup extends StatelessWidget {
  final Setup setup;
  final Map<String, Bike> bikes;
  final bool isSelected;

  /// The referenced items that aren't selected, with their names.
  final Map<DataRef, String> missing;

  final ValueChanged<bool?> onChanged;

  const DataSelectSetup({
    super.key,
    required this.setup,
    required this.bikes,
    required this.isSelected,
    this.missing = const {},
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(Setup.iconData),
        title: Text(
          setup.label(context.l10n),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: setup.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                    bikes[setup.bike]?.name ?? context.l10n.bikeNotFound,
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
            for (final MapEntry(key: ref, value: name) in missing.entries)
              DataSelectMissingLine(kind: ref.kind, name: name),
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
