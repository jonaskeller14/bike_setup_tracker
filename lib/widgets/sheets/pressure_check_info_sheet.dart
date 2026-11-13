import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:units_converter/units_converter.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../services/pressure_drift_service.dart';
import '../pressure_drift_card.dart';
import '../setup_guide_status.dart';
import 'sheet_header.dart';

/// Why pump readings drift, a worked example, and what the card's icons mean.
Future<void> showPressureCheckInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (_) => const _PressureCheckInfoSheet(),
  );
}

/// The example runs through the real calculation, so its numbers never go stale.
class _Example {
  static const double setPsi = 80;
  static const home = PressureConditions(temperatureC: 20, altitudeM: 500);
  static const trailhead = PressureConditions(temperatureC: 5, altitudeM: 1800);

  static final PressurePrediction _prediction = PressureDriftService.predict(
    value: setPsi,
    unit: KnownUnit(quantity: UnitQuantity.pressure, unitId: PRESSURE.psi.name),
    from: home,
    to: trailhead,
  );

  static double get readingPsi => _prediction.reading;
  static double get temperatureSharePsi => _prediction.temperatureShare;
  static double get altitudeSharePsi => _prediction.altitudeShare;
  static double get deltaPsi => readingPsi - setPsi;
  static double get relativeDelta => deltaPsi / setPsi;
}

class _PressureCheckInfoSheet extends StatelessWidget {
  const _PressureCheckInfoSheet();

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final threshold = appSettings.pressureCheckThreshold;
    final thresholdText = "${appSettings.pressureCheckThresholdPercent} %";
    final exampleSignificant = _Example.relativeDelta.abs() >= threshold;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.featuresPressureCheck, leadingIcon: const Icon(Icons.compress)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    context.l10n.pressureCheckInfoIntro,
                    style: muted,
                  ),
                  _heading(context, context.l10n.pressureCheckInfoWhyHeading),
                  _bullet(context, Icons.ac_unit, context.l10n.pressureCheckInfoCold),
                  _bullet(
                    context,
                    Icons.landscape_outlined,
                    context.l10n.pressureCheckInfoThin,
                  ),
                  Text(context.l10n.pressureCheckInfoCancel, style: muted),
                  _bullet(
                    context,
                    Icons.schedule,
                    context.l10n.pressureCheckInfoLeak(
                      "${(PressureDriftService.tireWeeklyLoss * 100).round()} %",
                    ),
                  ),
                  _heading(context, context.l10n.pressureCheckInfoExampleHeading),
                  _ExampleCard(appSettings: appSettings, significant: exampleSignificant),
                  _heading(context, context.l10n.pressureCheckInfoWhatToDoHeading),
                  Text(
                    context.l10n.pressureCheckInfoWhatToDo(formatPressure(_Example.setPsi, context.l10n)),
                    style: muted,
                  ),
                  _heading(context, context.l10n.pressureCheckInfoStatusHeading),
                  _legendRow(
                    context,
                    [PressureDriftIcon(relativeDelta: 0, threshold: threshold)],
                    context.l10n.pressureCheckInfoStatusOk(thresholdText),
                  ),
                  _legendRow(
                    context,
                    [
                      PressureDriftIcon(relativeDelta: -threshold, threshold: threshold),
                      PressureDriftIcon(relativeDelta: threshold, threshold: threshold),
                    ],
                    context.l10n.pressureCheckInfoStatusDrift(thresholdText),
                  ),
                  Text(
                    context.l10n.pressureCheckInfoSettingsHint,
                    style: muted,
                  ),
                  _heading(context, context.l10n.pressureCheckInfoReferenceHeading),
                  _bullet(
                    context,
                    Icons.history,
                    context.l10n.pressureCheckInfoCompared,
                  ),
                  _bullet(
                    context,
                    Icons.content_copy_outlined,
                    context.l10n.pressureCheckInfoCarriedOver,
                  ),
                  _bullet(
                    context,
                    Icons.check_circle_outline,
                    context.l10n.pressureCheckInfoSetNow,
                  ),
                  _bullet(
                    context,
                    Icons.location_off_outlined,
                    context.l10n.pressureCheckInfoNeedsConditions,
                  ),
                  _heading(context, context.l10n.pressureCheckInfoGoodToKnowHeading),
                  _bullet(
                    context,
                    Icons.science_outlined,
                    context.l10n.pressureCheckInfoNotIncluded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
  );

  Widget _bullet(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(BuildContext context, List<Widget> icons, String meaning) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SizedBox(width: 40, child: Row(children: icons)),
        Expanded(
          child: Text(
            meaning,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Home → trailhead, then the two effects adding up to the drift.
class _ExampleCard extends StatelessWidget {
  final AppSettings appSettings;
  final bool significant;

  const _ExampleCard({required this.appSettings, required this.significant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    Widget place(IconData icon, String title, String conditions, String label, double psi, {bool end = false}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
                spacing: 6,
                children: [
                  Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                  Flexible(
                    child: Text(title, style: textTheme.labelLarge, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              Text(conditions, style: muted, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(label, style: muted),
              Text(
                context.l10n.pressureCheckPsi(formatPressure(psi, context.l10n)),
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

    Widget share(IconData icon, String label, double psi) => Row(
      spacing: 8,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        Expanded(
          child: Text(label, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
        ),
        Text(context.l10n.pressureCheckPsi(signedPressure(psi, context.l10n)), style: textTheme.bodyMedium),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              place(
                Icons.home_outlined,
                context.l10n.pressureCheckExampleHome,
                pressureConditionsText(appSettings, _Example.home),
                context.l10n.pressureCheckExampleYouSet,
                _Example.setPsi,
              ),
              Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
              place(
                Icons.terrain_outlined,
                context.l10n.pressureCheckExampleTrailhead,
                pressureConditionsText(appSettings, _Example.trailhead),
                context.l10n.pressureCheckExamplePumpReads,
                _Example.readingPsi,
                end: true,
              ),
            ],
          ),
          const Divider(height: 8),
          share(Icons.ac_unit, context.l10n.pressureCheckExampleColder, _Example.temperatureSharePsi),
          share(Icons.landscape_outlined, context.l10n.pressureCheckExampleHigherUp, _Example.altitudeSharePsi),
          Row(
            spacing: 8,
            children: [
              Icon(Icons.functions, size: 18, color: scheme.onSurfaceVariant),
              Expanded(
                child: Text(
                  context.l10n.pressureCheckExampleTotal,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                context.l10n.pressureCheckPsi(signedPressure(_Example.deltaPsi, context.l10n)),
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GuideStatusPill(
              pressureDriftStatus(_Example.relativeDelta, context.l10n, significant: significant),
            ),
          ),
        ],
      ),
    );
  }
}
