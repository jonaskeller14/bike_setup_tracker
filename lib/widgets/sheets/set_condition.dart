import 'package:flutter/material.dart';

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/context/context_weather.dart';
import '../soil_moisture_legend_table.dart';
import 'radio_group.dart';

/// Callers should mark the resulting weather as manually set (e.g. via
/// `ContextWeather.copyWith(condition: value, conditionManuallySet: true)`).
Future<void> showSetConditionSheet({
  required BuildContext context,
  required Condition? currentCondition,
  required ValueChanged<Condition> onSelected,
}) {
  return radioGroupSheet<Condition?>(
    context: context,
    title: context.l10n.setConditionTitle,
    infoText: context.l10n.setConditionInfo,
    contentWidget: const SoilMoistureLegendTable(),
    value: currentCondition,
    optionWidgets: Map.fromEntries(Condition.values.map((condition) {
      return MapEntry(
        condition,
        Row(
          spacing: 8,
          children: [
            Icon(condition.iconData, color: condition.color),
            Text(condition.label(context.l10n)),
          ],
        ),
      );
    })),
    onChanged: (Condition? newValue) {
      if (newValue == null) return;
      Navigator.pop(context);
      onSelected(newValue);
    },
  );
}
