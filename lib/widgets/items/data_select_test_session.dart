import 'package:flutter/material.dart';

import '../../models/bike.dart';
import '../../models/feedback/test_session.dart';
import 'tile_meta_row.dart';

class DataSelectTestSession extends StatelessWidget {
  final TestSession item;
  final Map<String, Bike> bikes;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectTestSession({
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
        secondary: const Icon(TestSession.iconData),
        title: Text(
          item.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: TileMetaRow(icon: Bike.iconData, text: bike?.name ?? "BIKE NOT FOUND", isError: bike == null),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        value: isSelected,
        onChanged: onChanged,
      ),
    );
  }
}
