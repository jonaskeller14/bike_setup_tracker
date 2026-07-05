import 'package:flutter/material.dart';
import '../../models/context/context_weather.dart';
import '../soil_moisture_legend_table.dart';
import 'app_settings_radio_group.dart';

/// Callers should mark the resulting weather as manually set (e.g. via
/// `ContextWeather.copyWith(condition: value, conditionManuallySet: true)`).
Future<void> showSetConditionSheet({
  required BuildContext context,
  required Condition? currentCondition,
  required ValueChanged<Condition> onSelected,
}) {
  return appSettingsRadioGroupSheet<Condition?>(
    context: context,
    title: "Select Trail Condition",
    infoText: "Conditions are automatically calculated based on soil moisture (see weather data). You can manually adjust the trail condition here:",
    contentWidget: const SoilMoistureLegendTable(),
    value: currentCondition,
    optionWidgets: Map.fromEntries(Condition.values.map((condition) {
      return MapEntry(
        condition,
        Row(
          spacing: 8,
          children: [
            Icon(condition.iconData, color: condition.color),
            Text(condition.value),
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
