import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../services/data_selection_dependencies.dart';
import 'data_select_missing_line.dart';
import 'tile_meta_row.dart';

class DataSelectFeedback extends StatelessWidget {
  final RideFeedback item;
  final Map<String, Bike> bikes;
  final bool isSelected;

  /// The referenced items that aren't selected, with their names.
  final Map<DataRef, String> missing;

  final ValueChanged<bool?> onChanged;

  const DataSelectFeedback({
    super.key,
    required this.item,
    required this.bikes,
    required this.isSelected,
    this.missing = const {},
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final bike = bikes[item.bike];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: CheckboxListTile(
        secondary: const Icon(RideFeedback.iconData),
        title: Text(
          '${DateFormat(appSettings.dateFormat, context.l10n.localeName).format(item.dateTimeLocal)} • '
          '${DateFormat(appSettings.timeFormat, context.l10n.localeName).format(item.dateTimeLocal)}',
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
