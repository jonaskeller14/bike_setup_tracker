import 'package:flutter/material.dart';

import '../../l10n/entity_names.dart';
import '../../l10n/l10n.dart';
import '../../models/bike.dart';
import '../../models/feedback/test_session.dart';
import '../../services/data_selection_dependencies.dart';
import 'data_select_missing_line.dart';
import 'tile_meta_row.dart';

class DataSelectTestSession extends StatelessWidget {
  final TestSession item;
  final Map<String, Bike> bikes;
  final bool isSelected;

  /// The referenced items that aren't selected, with their names.
  final Map<DataRef, String> missing;

  final ValueChanged<bool?> onChanged;

  const DataSelectTestSession({
    super.key,
    required this.item,
    required this.bikes,
    required this.isSelected,
    this.missing = const {},
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
          item.label(context.l10n),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.isDeleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TileMetaRow(icon: Bike.iconData, text: bike?.name ?? context.l10n.bikeNotFound, isError: bike == null),
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
