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
import 'hint_card_parts.dart';
import 'setup_guide_status.dart';
import 'sheets/pressure_check_info_sheet.dart';

/// Tells the rider whether the pressures pre-filled from history still read the
/// same on a pump under today's temperature and altitude — that is, whether it
/// is worth unpacking the pump at all. Styled like the app hints, and collapsed
/// while every pressure stays within the threshold or there is nothing to compare.
class PressureDriftCard extends StatefulWidget {
  final List<PressureDriftEntry> entries;

  /// Why [entries] is empty; the card hides while both are empty.
  final PressureDriftGap? gap;

  /// Whether the current location or weather is still being fetched.
  final bool loading;

  const PressureDriftCard({super.key, required this.entries, this.gap, this.loading = false});

  @override
  State<PressureDriftCard> createState() => _PressureDriftCardState();
}

class _PressureDriftCardState extends State<PressureDriftCard> {
  /// Null until the rider toggles the card; until then it follows the drift.
  bool? _expanded;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final gap = widget.gap;
    if (entries.isEmpty && gap == null) return const SizedBox.shrink();

    final appSettings = context.watch<AppSettings>();
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final driftedCount = entries.where((e) => e.isSignificant).length;
    final expanded = _expanded ?? driftedCount > 0;
    final summary = switch ((entries.isEmpty, driftedCount > 0)) {
      (true, _) => const GuideStatus(GuideStatusKind.unavailable),
      (false, true) => const GuideStatus(GuideStatusKind.off),
      (false, false) => const GuideStatus(GuideStatusKind.inRange),
    };
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
              HintCardHeader(
                status: widget.loading
                    ? const HintCardLoadingIndicator()
                    : Icon(
                        summary.icon,
                        size: 18,
                        color: summary.color(context),
                        semanticLabel: entries.isEmpty ? null : summary.label(context.l10n),
                      ),
                title: context.l10n.featuresPressureCheck,
                expanded: expanded,
                onToggle: () => setState(() => _expanded = !expanded),
              ),
              if (expanded && entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: HintLearnMoreText(
                    text: widget.loading ? context.l10n.pressureCheckLoading : _gapText(gap!, context.l10n),
                    style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                    onLearnMore: () => showPressureCheckInfoSheet(context),
                  ),
                )
              else if (expanded) ...[
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: HintLearnMoreText(
                    text: driftedCount > 0
                        ? context.l10n.pressureCheckFooterDrifted
                        : context.l10n.pressureCheckFooterOk(threshold),
                    style: textTheme.bodySmall?.copyWith(color: hint.onContainer),
                    onLearnMore: () => showPressureCheckInfoSheet(context),
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

String _gapText(PressureDriftGap gap, AppLocalizations l10n) => switch (gap) {
  PressureDriftGap.noRecordedPressure => l10n.pressureCheckNoRecordedPressure,
  PressureDriftGap.noRecordedConditions => l10n.pressureCheckNoRecordedConditions,
  PressureDriftGap.noCurrentConditions => l10n.pressureCheckNoCurrentConditions,
};

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
