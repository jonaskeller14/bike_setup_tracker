import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/rating_entry.dart';

class DataSelectRatingEntry extends StatelessWidget {
  final RatingEntry item;
  final Map<String, Bike> bikes;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectRatingEntry({
    super.key,
    required this.item,
    required this.bikes,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bike = bikes[item.bike];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(RatingEntry.iconData),
        title: Text(
          item.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Icon(
              bike != null ? Bike.iconData : Icons.bike_scooter,
              size: 13,
              color: bike != null
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.error,
            ),
            Flexible(
              child: Text(
                bike?.name ?? "BIKE NOT FOUND",
                style: TextStyle(
                  color: bike != null
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
