import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_position.dart';
import '../../models/context/context_weather.dart';
import '../../models/setup_comparison.dart' as comparison;
import '../../theme.dart';
import '../display_adjustment_diff/display_adjustment_diff.dart';

class SetupComparisonRow extends StatelessWidget {
  static const wideBreakpoint = 600.0;

  final String groupId;
  final comparison.SetupComparisonRow row;

  const SetupComparisonRow({super.key, required this.groupId, required this.row});

  @override
  Widget build(BuildContext context) {
    if (row.kind == comparison.SetupComparisonRowKind.adjustment) {
      return DisplayAdjustmentDiff(groupId: groupId, row: row);
    }

    final id = '$groupId-${row.id}';
    final child = LayoutBuilder(
      builder: (context, constraints) {
        final label = _Label(row: row);
        final panelA = _ValuePanel(key: Key('compare-panel-a-$id'), row: row, side: row.valueA);
        final panelB = _ValuePanel(key: Key('compare-panel-b-$id'), row: row, side: row.valueB);
        if (constraints.maxWidth < wideBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: panelA),
                  const SizedBox(width: 8),
                  Expanded(child: panelB),
                ],
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: label),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: panelA),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: panelB),
          ],
        );
      },
    );
    return Semantics(
      container: true,
      label: row.isDifferent ? 'Different ${row.label}' : row.label,
      child: Container(
        key: Key('compare-row-$id'),
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final comparison.SetupComparisonRow row;

  const _Label({required this.row});

  @override
  Widget build(BuildContext context) {
    return Text(row.label, softWrap: true);
  }
}

class _ValuePanel extends StatelessWidget {
  final comparison.SetupComparisonRow row;
  final comparison.SetupComparisonSideValue side;

  const _ValuePanel({super.key, required this.row, required this.side});

  @override
  Widget build(BuildContext context) {
    final reference = side.value is comparison.SetupComparisonReference
        ? side.value as comparison.SetupComparisonReference
        : null;
    final hasError = reference?.isMissing ?? false;
    final text = _displayValue(context, side);
    final color = hasError
        ? Theme.of(context).colorScheme.error
        : row.isDifferent
        ? Theme.of(context).extension<ValueHighlightColors>()!.changed
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: text,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              text,
              style: TextStyle(color: color),
            ),
            if (side.provenance == comparison.SetupComparisonValueProvenance.inherited)
              Text('Inherited', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String _displayValue(BuildContext context, comparison.SetupComparisonSideValue side) {
    if (side.provenance == comparison.SetupComparisonValueProvenance.unavailable) {
      return '-';
    }
    if (side.value == null) return 'Cleared';
    if (side.value is comparison.SetupComparisonReference) {
      return (side.value as comparison.SetupComparisonReference).label;
    }
    if (side.value is List) return (side.value as List).join(', ');
    if (side.value is (double?, double?)) {
      final value = side.value as (double?, double?);
      return '${value.$1?.toStringAsFixed(4) ?? '-'}°/${value.$2?.toStringAsFixed(4) ?? '-'}°';
    }
    if (row.kind == comparison.SetupComparisonRowKind.context && row.id == 'altitude') {
      final settings = context.read<AppSettings>();
      return '${ContextPosition.convertAltitudeFromMeters(side.value as double?, settings.altitudeUnit)?.round() ?? '-'} ${settings.altitudeUnit}';
    }
    if (row.kind == comparison.SetupComparisonRowKind.context) {
      final settings = context.read<AppSettings>();
      return switch (row.id) {
        'temperature' =>
          '${ContextWeather.convertTemperatureFromCelsius(side.value as double?, settings.temperatureUnit)?.round() ?? '-'} ${settings.temperatureUnit}',
        'precipitation' =>
          '${ContextWeather.convertPrecipitationFromMm(side.value as double?, settings.precipitationUnit)?.round() ?? '-'} ${settings.precipitationUnit}',
        'humidity' => '${(side.value as double?)?.round() ?? '-'} %',
        'wind' =>
          '${ContextWeather.convertWindSpeedFromKmh(side.value as double?, settings.windSpeedUnit)?.round() ?? '-'} ${settings.windSpeedUnit}',
        'soil-moisture' => '${(side.value as double?)?.toStringAsFixed(2) ?? '-'} m³/m³',
        _ => '${side.value}',
      };
    }
    return '${side.value}';
  }
}
