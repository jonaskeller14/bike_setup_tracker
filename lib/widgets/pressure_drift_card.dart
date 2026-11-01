import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../services/pressure_drift_service.dart';
import '../theme.dart';
import '../utils/localized_number.dart';
import 'setup_guide_status.dart';
import 'sheets/pressure_check_info_sheet.dart';

/// Tells the rider whether the pressures pre-filled from history still read the
/// same on a pump under today's temperature and altitude — that is, whether it
/// is worth unpacking the pump at all. Styled like the app hints, and collapsed
/// while every pressure stays within the threshold.
class PressureDriftCard extends StatefulWidget {
  final List<PressureDriftEntry> entries;

  const PressureDriftCard({super.key, required this.entries});

  @override
  State<PressureDriftCard> createState() => _PressureDriftCardState();
}

class _PressureDriftCardState extends State<PressureDriftCard> {
  /// Null until the rider toggles the card; until then it follows the drift.
  bool? _expanded;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    if (entries.isEmpty) return const SizedBox.shrink();

    final appSettings = context.watch<AppSettings>();
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final driftedCount = entries.where((e) => e.isSignificant).length;
    final expanded = _expanded ?? driftedCount > 0;
    final summary = driftedCount > 0
        ? const GuideStatus(GuideStatusKind.off)
        : const GuideStatus(GuideStatusKind.inRange);
    final threshold = "${appSettings.pressureCheckThresholdPercent} %";
    final divider = Divider(height: 1, indent: 16, endIndent: 16, color: hint.onContainer.withValues(alpha: 0.15));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: hint.container,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !expanded),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
                  child: Row(
                    spacing: 6,
                    children: [
                      Icon(Icons.compress, size: 16, color: hint.accent),
                      Expanded(
                        child: Text(
                          context.l10n.featuresPressureCheck.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: hint.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(summary.icon, size: 20, color: summary.color(context)),
                      IconButton(
                        onPressed: () => setState(() => _expanded = !expanded),
                        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                        color: hint.accent,
                        tooltip: expanded ? context.l10n.collapse : context.l10n.expand,
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driftedCount > 0 ? context.l10n.pressureCheckWorthPump : context.l10n.pressureCheckNoPump,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                      ),
                      Text(
                        context.l10n.pressureCheckNow(
                          pressureConditionsText(
                            appSettings,
                            entries.first.currentTemperatureC,
                            entries.first.currentAltitudeM,
                          ),
                        ),
                        style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Hairlines frame the readings so they read apart from the summary and the footer.
                for (final entry in entries) ...[
                  divider,
                  _PressureDriftRow(entry: entry, appSettings: appSettings),
                ],
                divider,
                Padding(
                  // Right inset matches the header, so the info button sits under the chevron.
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                  child: Row(
                    spacing: 6,
                    children: [
                      Expanded(
                        child: Text(
                          driftedCount > 0
                              ? context.l10n.pressureCheckFooterDrifted
                              : context.l10n.pressureCheckFooterOk(threshold),
                          style: textTheme.bodySmall?.copyWith(color: hint.onContainer),
                        ),
                      ),
                      IconButton(
                        onPressed: () => showPressureCheckInfoSheet(context),
                        icon: const Icon(Icons.info_outline_rounded),
                        iconSize: 18,
                        color: hint.accent,
                        tooltip: context.l10n.pressureCheckInfoTooltip,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mutedStyle = textTheme.bodySmall?.copyWith(color: hint.onContainer.withValues(alpha: 0.75));
    final unit = entry.unit.label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${entry.componentName} · ${entry.adjustmentName}",
                  style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  context.l10n.pressureCheckSetOn(
                    formatPressure(entry.referenceValue, context.l10n),
                    unit,
                    DateFormat(appSettings.dateFormat, context.l10n.localeName).format(entry.referenceSetup.datetimeLocal),
                    pressureConditionsText(appSettings, entry.referenceTemperatureC, entry.referenceAltitudeM),
                  ),
                  style: mutedStyle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                Text(
                  "${formatPressure(entry.predictedReading, context.l10n)} $unit",
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                GuideStatusPill(pressureDriftStatus(entry.relativeDelta, context.l10n, significant: entry.isSignificant)),
                Text(
                  "${signedPressure(entry.delta, context.l10n)} $unit",
                  style: mutedStyle,
                  maxLines: 1,
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

/// Green within the threshold, orange from it on, labelled with the drift.
GuideStatus pressureDriftStatus(double relativeDelta, AppLocalizations l10n, {required bool significant}) =>
    GuideStatus(significant ? GuideStatusKind.off : GuideStatusKind.inRange, text: signedPercent(relativeDelta, l10n));

String formatPressure(double value, AppLocalizations l10n) {
  final magnitude = value.abs();
  final decimals = magnitude >= 100 ? 0 : (magnitude >= 10 ? 1 : 2);
  return formatLocalizedDouble(value, fractionDigits: decimals, locale: l10n.localeName);
}

String signedPressure(double value, AppLocalizations l10n) => "${value < 0 ? '-' : '+'}${formatPressure(value.abs(), l10n)}";

String signedPercent(double fraction, AppLocalizations l10n) {
  final percent = (fraction * 100).abs();
  return "${fraction < 0 ? '-' : '+'}${formatLocalizedDouble(percent, fractionDigits: percent >= 10 ? 0 : 1, locale: l10n.localeName)} %";
}

/// "5 °C · 1800 m" in the rider's units.
String pressureConditionsText(AppSettings appSettings, double temperatureC, double altitudeM) {
  final temperature =
      ContextWeather.convertTemperatureFromCelsius(temperatureC, appSettings.temperatureUnit)?.round() ??
      temperatureC.round();
  final altitude =
      ContextPosition.convertAltitudeFromMeters(altitudeM, appSettings.altitudeUnit)?.round() ?? altitudeM.round();
  return "$temperature ${appSettings.temperatureUnit} · $altitude ${appSettings.altitudeUnit}";
}
