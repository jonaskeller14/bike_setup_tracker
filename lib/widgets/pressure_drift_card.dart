import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../services/pressure_drift_service.dart';
import '../theme.dart';
import '../utils/localized_number.dart';
import 'app_snackbar.dart';
import 'hint_card_parts.dart';
import 'setup_guide_status.dart';
import 'sheets/pressure_check_info_sheet.dart';

/// Tells the rider whether the pressures pre-filled from history still read the
/// same on a pump under today's temperature and altitude — that is, whether it
/// is worth unpacking the pump at all. Styled like the app hints, and collapsed
/// while every pressure stays within the threshold or there is nothing to compare.
class PressureDriftCard extends StatefulWidget {
  /// The card hides while it has neither an entry nor a gap.
  final PressureCheck check;

  /// Whether the current location or weather is still being fetched.
  final bool loading;

  /// The pressures marked as set now. A marked row counts as dealt with.
  final Set<String> setNowIds;

  /// The pressures that still read their reference value and can be marked.
  final Set<String> setNowAvailableIds;

  /// Without it no row shows a toggle.
  final void Function(String adjustmentId, bool setNow)? onSetNowChanged;

  const PressureDriftCard({
    super.key,
    required this.check,
    this.loading = false,
    this.setNowIds = const {},
    this.setNowAvailableIds = const {},
    this.onSetNowChanged,
  });

  @override
  State<PressureDriftCard> createState() => _PressureDriftCardState();
}

class _PressureDriftCardState extends State<PressureDriftCard> {
  /// Null until the rider toggles the card; until then it follows the drift.
  bool? _expanded;

  void _showSetNowSnackBar(PressureCheckEntry entry, bool setNow) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!setNow) return;
    messenger.showSnackBar(
      AppSnackBar.success(
        context,
        context.l10n.pressureCheckSetNowMarked("${entry.componentName} · ${entry.adjustmentName}"),
        action: AppSnackBarAction(
          label: context.l10n.undo,
          onPressed: () {
            if (mounted) widget.onSetNowChanged?.call(entry.adjustmentId, false);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.check.entries;
    final gap = widget.check.gap;
    if (entries.isEmpty && gap == null) return const SizedBox.shrink();

    final appSettings = context.watch<AppSettings>();
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final driftEntries = widget.check.driftEntries;
    final driftedCount = driftEntries
        .where((e) => e.isSignificant && !widget.setNowIds.contains(e.adjustmentId))
        .length;
    final currentConditions = widget.check.currentConditions;
    final expanded = _expanded ?? driftedCount > 0;
    final summary = switch ((driftEntries.isEmpty, driftedCount > 0)) {
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
                      if (driftEntries.isNotEmpty)
                        Text(
                          driftedCount > 0 ? context.l10n.pressureCheckWorthPump : context.l10n.pressureCheckNoPump,
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                        ),
                      if (currentConditions != null)
                        Text(
                          context.l10n.pressureCheckNow(pressureConditionsText(appSettings, currentConditions)),
                          style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const _ColumnsHeader(),
                // Hairlines frame the readings so they read apart from the summary and the footer.
                for (final entry in entries) ...[
                  divider,
                  _PressureRow(
                    entry: entry,
                    appSettings: appSettings,
                    setNow: widget.setNowIds.contains(entry.adjustmentId),
                    onSetNowChanged:
                        widget.onSetNowChanged != null && widget.setNowAvailableIds.contains(entry.adjustmentId)
                        ? (setNow) {
                            // Marking the last drifted row must not fold the card under the finger.
                            setState(() => _expanded ??= true);
                            widget.onSetNowChanged!(entry.adjustmentId, setNow);
                            _showSetNowSnackBar(entry, setNow);
                          }
                        : null,
                  ),
                ],
                divider,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: HintLearnMoreText(
                    text: switch ((driftEntries.isEmpty, driftedCount > 0)) {
                      (true, _) => context.l10n.pressureCheckNoRecordedConditions,
                      (false, true) => context.l10n.pressureCheckFooterDrifted,
                      (false, false) => context.l10n.pressureCheckFooterOk(threshold),
                    },
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
  PressureDriftGap.noCurrentConditions => l10n.pressureCheckNoCurrentConditions,
};

class _PressureRow extends StatelessWidget {
  final PressureCheckEntry entry;
  final AppSettings appSettings;
  final bool setNow;

  /// Null where the row cannot be marked.
  final ValueChanged<bool>? onSetNowChanged;

  const _PressureRow({
    required this.entry,
    required this.appSettings,
    required this.setNow,
    required this.onSetNowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mutedStyle = textTheme.bodySmall?.copyWith(color: hint.onContainer.withValues(alpha: 0.75));
    final unit = entry.unit.label;
    final name = "${entry.componentName} · ${entry.adjustmentName}";
    final setOnDate = DateFormat(
      appSettings.dateFormat,
      context.l10n.localeName,
    ).format(entry.referenceSetup.datetimeLocal);
    final referenceText = switch (entry) {
      final PressureDriftEntry drift => [
        context.l10n.pressureCheckSetOn(setOnDate, pressureConditionsText(appSettings, drift.referenceConditions)),
        if (drift.elapsedDays >= 1) context.l10n.pressureCheckReferenceAge(drift.elapsedDays.floor()),
      ].join(" · "),
      PressureReferenceGapEntry() => context.l10n.pressureCheckNoConditionsOn(setOnDate),
    };
    const marked = GuideStatus(GuideStatusKind.inRange);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ColumnsLayout(
            name: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(referenceText, style: mutedStyle, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
            now: switch (entry) {
              final PressureDriftEntry drift when !setNow => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Scaled rather than cut off: a truncated pressure is no use.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${formatPressure(drift.predictedReading, context.l10n)} $unit",
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                      maxLines: 1,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(signedPercent(drift.relativeDelta, context.l10n), style: mutedStyle, maxLines: 1),
                  ),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
            set: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                "${formatPressure(entry.referenceValue, context.l10n)} $unit",
                style: textTheme.bodyMedium?.copyWith(color: hint.onContainer.withValues(alpha: 0.75)),
                maxLines: 1,
              ),
            ),
            status: switch (entry) {
              _ when setNow => Icon(marked.icon, size: 20, color: marked.color(context)),
              final PressureDriftEntry drift => PressureDriftIcon(
                relativeDelta: drift.relativeDelta,
                threshold: drift.significanceThreshold,
              ),
              PressureReferenceGapEntry() => null,
            },
          ),
          if (onSetNowChanged != null) _SetNowToggle(name: name, setNow: setNow, onChanged: onSetNowChanged!),
        ],
      ),
    );
  }
}

/// A check icon and a label, at least as tall as a tap target.
class _SetNowToggle extends StatelessWidget {
  final String name;
  final bool setNow;
  final ValueChanged<bool> onChanged;

  const _SetNowToggle({required this.name, required this.setNow, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final status = GuideStatus(setNow ? GuideStatusKind.matches : GuideStatusKind.notSet);

    return Semantics(
      button: true,
      toggled: setNow,
      label: context.l10n.pressureCheckSetNowSemantics(name),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onChanged(!setNow);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(status.icon, size: 20, color: setNow ? status.color(context) : hint.onContainer),
              Flexible(
                child: Text(
                  context.l10n.pressureCheckSetNow,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: hint.onContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Now" and "Set" captions above the readings.
class _ColumnsHeader extends StatelessWidget {
  const _ColumnsHeader();

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: hint.onContainer.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
    );
    Widget caption(String text) =>
        Text(text, style: style, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: _ColumnsLayout(
        now: caption(context.l10n.pressureCheckColumnNow),
        set: caption(context.l10n.pressureCheckColumnSet),
      ),
    );
  }
}

/// Shared by [_ColumnsHeader] and [_PressureRow] so the columns line up.
class _ColumnsLayout extends StatelessWidget {
  final Widget? name;
  final Widget now;
  final Widget set;
  final Widget? status;

  const _ColumnsLayout({this.name, required this.now, required this.set, this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: name ?? const SizedBox.shrink()),
        Expanded(flex: 2, child: now),
        Expanded(flex: 2, child: set),
        SizedBox(width: 24, child: status),
      ],
    );
  }
}

/// A check while the reading stays within [threshold]; past it, which way to
/// pump back to the set value: up to add air, down to let some out, doubled
/// from twice the threshold on.
class PressureDriftIcon extends StatelessWidget {
  final double relativeDelta;
  final double threshold;

  const PressureDriftIcon({super.key, required this.relativeDelta, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final drift = relativeDelta.abs();
    final significant = drift >= threshold;
    final status = GuideStatus(significant ? GuideStatusKind.off : GuideStatusKind.inRange);
    final icon = switch ((significant, relativeDelta < 0, drift >= 2 * threshold)) {
      (false, _, _) => status.icon,
      (true, true, false) => Icons.keyboard_arrow_up,
      (true, true, true) => Icons.keyboard_double_arrow_up,
      (true, false, false) => Icons.keyboard_arrow_down,
      (true, false, true) => Icons.keyboard_double_arrow_down,
    };
    return Tooltip(
      message: status.label(context.l10n),
      child: Icon(icon, size: 20, color: status.color(context), semanticLabel: status.label(context.l10n)),
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

String signedPressure(double value, AppLocalizations l10n) =>
    "${value < 0 ? '-' : '+'}${formatPressure(value.abs(), l10n)}";

String signedPercent(double fraction, AppLocalizations l10n) {
  final percent = (fraction * 100).abs();
  return "${fraction < 0 ? '-' : '+'}${formatLocalizedDouble(percent, fractionDigits: percent >= 10 ? 0 : 1, locale: l10n.localeName)} %";
}

/// "5 °C · 1800 m" in the rider's units, each value kept on one line with its
/// unit.
String pressureConditionsText(AppSettings appSettings, PressureConditions conditions) {
  final PressureConditions(:temperatureC, :altitudeM) = conditions;
  final temperature =
      ContextWeather.convertTemperatureFromCelsius(temperatureC, appSettings.temperatureUnit)?.round() ??
      temperatureC.round();
  final altitude =
      ContextPosition.convertAltitudeFromMeters(altitudeM, appSettings.altitudeUnit)?.round() ?? altitudeM.round();
  return "$temperature ${appSettings.temperatureUnit} · $altitude ${appSettings.altitudeUnit}";
}
