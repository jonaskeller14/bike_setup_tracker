import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../services/pressure_drift_service.dart';
import '../theme.dart';
import 'dialogs/dialog_action.dart';
import 'items/card_header_tile.dart';

/// Tells the rider whether the pressures pre-filled from history still read the
/// same on a pump under today's temperature and altitude — that is, whether it
/// is worth unpacking the pump at all.
class PressureDriftCard extends StatelessWidget {
  final List<PressureDriftEntry> entries;

  const PressureDriftCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final appSettings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final driftedCount = entries.where((e) => e.isSignificant).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardHeaderTile(
            color: scheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.compress),
              title: const Text("Pressure Check", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "Now ${_conditions(appSettings, entries.first.currentTemperatureC, entries.first.currentAltitudeM)}",
              ),
              trailing: IconButton(
                onPressed: () => _showExplanation(context),
                icon: const Icon(Icons.info_outline),
                tooltip: "How this is calculated",
              ),
            ),
          ),
          ...entries.map((entry) => _PressureDriftRow(entry: entry, appSettings: appSettings)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  driftedCount > 0 ? Icons.build_outlined : Icons.check_circle_outline,
                  size: 18,
                  color: driftedCount > 0
                      ? theme.extension<ValueHighlightColors>()?.changed
                      : scheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    driftedCount > 0
                        ? "Your pump would read the values above. Setting them back to the values you "
                              "last used restores the same feel."
                        : "All readings stay within $_thresholdLabel of the values you last used — "
                              "no need to unpack the pump.",
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PressureDriftRow extends StatelessWidget {
  final PressureDriftEntry entry;
  final AppSettings appSettings;

  const _PressureDriftRow({required this.entry, required this.appSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final driftColor = entry.isSignificant
        ? theme.extension<ValueHighlightColors>()?.changed
        : scheme.onSurfaceVariant;
    final unit = entry.unit.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: entry.isSignificant ? theme.extension<ValueHighlightColors>()?.changedFill : null,
      child: Row(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${entry.componentName} · ${entry.adjustmentName}",
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Set ${_formatPressure(entry.referenceValue)} $unit on "
                  "${DateFormat(appSettings.dateFormat).format(entry.referenceSetup.datetimeLocal)} · "
                  "${_conditions(appSettings, entry.referenceTemperatureC, entry.referenceAltitudeM)}",
                  style: mutedStyle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.isSignificant)
                  Text(
                    "Temperature ${_signedPressure(entry.temperatureShare)} · "
                    "Altitude ${_signedPressure(entry.altitudeShare)} $unit",
                    style: mutedStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${_formatPressure(entry.predictedReading)} $unit",
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: driftColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${_signedPressure(entry.delta)} $unit (${_signedPercent(entry.relativeDelta)})",
                  style: mutedStyle?.copyWith(color: driftColor),
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String get _thresholdLabel => "${(PressureDriftService.significanceThreshold * 100).round()} %";

String _formatPressure(double value) {
  final magnitude = value.abs();
  final decimals = magnitude >= 100 ? 0 : (magnitude >= 10 ? 1 : 2);
  return value.toStringAsFixed(decimals);
}

String _signedPressure(double value) => "${value < 0 ? '-' : '+'}${_formatPressure(value.abs())}";

String _signedPercent(double fraction) {
  final percent = (fraction * 100).abs();
  return "${fraction < 0 ? '-' : '+'}${percent.toStringAsFixed(percent >= 10 ? 0 : 1)} %";
}

String _conditions(AppSettings appSettings, double temperatureC, double altitudeM) {
  final temperature =
      ContextWeather.convertTemperatureFromCelsius(temperatureC, appSettings.temperatureUnit)?.round() ??
      temperatureC.round();
  final altitude =
      ContextPosition.convertAltitudeFromMeters(altitudeM, appSettings.altitudeUnit)?.round() ??
      altitudeM.round();
  return "$temperature ${appSettings.temperatureUnit} · $altitude ${appSettings.altitudeUnit}";
}

Future<void> _showExplanation(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: const Text("Pressure Check"),
      content: const SingleChildScrollView(
        child: Text(
          "A pump measures a chamber against the surrounding air. Cooling lowers the "
          "pressure of the sealed air, while thinner air higher up makes the same "
          "chamber read higher — the two often cancel each other out in part.\n\n"
          "Each value is compared against the temperature and altitude recorded with "
          "the setup that last changed it, which is not necessarily the previous setup.\n\n"
          "Spring feel follows what the pump reads, so the values you last used are "
          "still the right targets. The point of this card is whether the difference is "
          "worth getting the pump out for.\n\n"
          "Not accounted for: how a different absolute pressure changes the spring "
          "curve, oil viscosity, and the air a pump hose swallows when connected.",
        ),
      ),
      actions: [
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Got it"),
        ),
      ],
    ),
  );
}
