import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/ride_feedback.dart';
import 'tile_meta_row.dart';

class DataSelectFeedback extends StatelessWidget {
  final RideFeedback item;
  final Map<String, Bike> bikes;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const DataSelectFeedback({
    super.key,
    required this.item,
    required this.bikes,
    required this.isSelected,
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
          '${DateFormat(appSettings.dateFormat).format(item.dateTimeLocal)} • '
          '${DateFormat(appSettings.timeFormat).format(item.dateTimeLocal)}',
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
