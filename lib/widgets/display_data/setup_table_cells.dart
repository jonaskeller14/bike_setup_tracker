import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/adjustment_value_text.dart';
import '../../l10n/entity_names.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/context/context_weather.dart';
import '../../models/feedback/test_session.dart';
import '../../models/setup.dart';
import '../../theme.dart';
import '../../utils/localized_number.dart';
import '../../utils/table_column.dart';

/// A column header: tap sorts, long-press removes the column.
class SortableColumnLabel extends StatelessWidget {
  final String label;
  final String? tooltip;
  final bool isSorted;
  final bool sortAscending;
  final VoidCallback onSort;
  final VoidCallback onRemove;

  const SortableColumnLabel({
    super.key,
    required this.label,
    this.tooltip,
    required this.isSorted,
    required this.sortAscending,
    required this.onSort,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tooltip = this.tooltip;
    final text = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSort,
      onLongPress: () {
        unawaited(HapticFeedback.selectionClick());
        onRemove();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: tooltip == null
                ? text
                // Hover only: on touch, tap sorts and long-press removes the column.
                : Tooltip(message: tooltip, triggerMode: TooltipTriggerMode.manual, child: text),
          ),
          const SizedBox(width: 4),
          Opacity(
            opacity: isSorted ? 1 : 0,
            child: AnimatedRotation(
              turns: sortAscending ? 0 : 0.5,
              duration: const Duration(milliseconds: 150),
              child: const Icon(Icons.arrow_upward, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

DataCell _scrollableTextCell(String text, {double maxWidth = 150}) {
  return DataCell(
    ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(text, overflow: TextOverflow.ellipsis),
      ),
    ),
  );
}

DataCell setupColumnCell(
  BuildContext context,
  Setup setup,
  SetupColumn column, {
  required AppSettings appSettings,
  required Map<String, Bike> bikes,
  required Map<String, TestSession> testSessions,
  required Map<String, int> setupActivityCounts,
}) {
  return switch (column) {
    SetupColumn.name => _scrollableTextCell(setup.label(context.l10n)),
    SetupColumn.notes => _scrollableTextCell(setup.notes ?? '-', maxWidth: 300),
    SetupColumn.tags => _scrollableTextCell(setup.tags.isEmpty ? '-' : setup.tags.join('; '), maxWidth: 300),
    SetupColumn.date => DataCell(
      Text(DateFormat(appSettings.dateFormat, context.l10n.localeName).format(setup.datetimeLocal)),
    ),
    SetupColumn.time => DataCell(
      Text(DateFormat(appSettings.timeFormat, context.l10n.localeName).format(setup.datetimeLocal)),
    ),
    SetupColumn.place => _scrollableTextCell(setup.place?.locality ?? '-'),
    SetupColumn.altitude => DataCell(
      Center(
        child: Text(
          setup.position?.altitude == null ? '-' : "${setup.position!.altitude!.round()} ${appSettings.altitudeUnit}",
        ),
      ),
    ),
    SetupColumn.bike => _scrollableTextCell(bikes[setup.bike]?.name ?? '-'),
    SetupColumn.bookmarked => DataCell(
      Center(
        child: setup.isBookmarked
            ? Icon(Icons.bookmark, size: 16, color: Theme.of(context).colorScheme.primary)
            : const Text('-'),
      ),
    ),
    SetupColumn.activities => DataCell(
      Center(
        child: Text(
          '${setupActivityCounts[setup.id] ?? 0}',
          key: ValueKey('setup-activity-count-${setup.id}'),
        ),
      ),
    ),
    SetupColumn.weatherCode => DataCell(Center(child: Text(setup.weather?.getWeatherCodeLabel(context.l10n) ?? "-"))),
    SetupColumn.temperature => DataCell(
      Center(
        child: Text(
          setup.weather?.currentTemperature == null
              ? '-'
              : "${ContextWeather.convertTemperatureFromCelsius(setup.weather!.currentTemperature!, appSettings.temperatureUnit)?.round()} ${appSettings.temperatureUnit}",
        ),
      ),
    ),
    SetupColumn.precipitation => DataCell(
      Center(
        child: Text(
          setup.weather?.dayAccumulatedPrecipitation == null
              ? '-'
              : "${ContextWeather.convertPrecipitationFromMm(setup.weather!.dayAccumulatedPrecipitation!, appSettings.precipitationUnit)?.round()} ${appSettings.precipitationUnit}",
        ),
      ),
    ),
    SetupColumn.humidity => DataCell(
      Center(
        child: Text(
          setup.weather?.currentHumidity == null ? '-' : "${setup.weather!.currentHumidity!.round()} %",
        ),
      ),
    ),
    SetupColumn.windSpeed => DataCell(
      Center(
        child: Text(
          setup.weather?.currentWindSpeed == null
              ? '-'
              : "${ContextWeather.convertWindSpeedFromKmh(setup.weather!.currentWindSpeed!, appSettings.windSpeedUnit)?.round()} ${appSettings.windSpeedUnit}",
        ),
      ),
    ),
    SetupColumn.soilMoisture => DataCell(
      Center(
        child: Text(
          setup.weather?.currentSoilMoisture0to7cm == null
              ? '-'
              : formatLocalizedDouble(
                  setup.weather!.currentSoilMoisture0to7cm!,
                  fractionDigits: 2,
                  locale: context.l10n.localeName,
                ),
        ),
      ),
    ),
    SetupColumn.condition => DataCell(
      Center(child: Text(setup.weather?.condition?.label(context.l10n) ?? "-")),
    ),
    SetupColumn.testSession => _scrollableTextCell(testSessions[setup.testSessionId]?.label(context.l10n) ?? '-'),
  };
}

/// A value, highlighted when it is dangling, the initial one or changed from
/// [previousValue].
DataCell adjustmentValueCell(
  BuildContext context, {
  required AdjustmentValue? value,
  required AdjustmentValue? previousValue,
  required bool isDangling,
}) {
  final bool isChanged = value != null && previousValue != value;
  final bool isInitial = previousValue == null;
  final highlights = Theme.of(context).extension<ValueHighlightColors>();
  final highlightColor = value != null && isDangling
      ? Theme.of(context).colorScheme.error
      : isChanged
      ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange)
      : null;

  return DataCell(
    Center(
      child: Text(
        value?.displayText(context.l10n) ?? '-',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: highlightColor,
          fontWeight: highlightColor != null ? FontWeight.bold : null,
        ),
      ),
    ),
  );
}
