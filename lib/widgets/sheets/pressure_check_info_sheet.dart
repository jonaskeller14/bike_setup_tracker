import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:units_converter/units_converter.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../services/pressure_drift_service.dart';
import '../../utils/unit_conversion.dart';
import '../pressure_drift_card.dart';
import '../setup_guide_status.dart';
import 'sheet_header.dart';

/// Why pump readings drift, a worked example, and what the card's pills mean.
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
  static const double homeTemperatureC = 20;
  static const double homeAltitudeM = 500;
  static const double trailTemperatureC = 5;
  static const double trailAltitudeM = 1800;

  static final KnownUnit _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: PRESSURE.psi.name);
  static final KnownUnit _pascal = KnownUnit(quantity: UnitQuantity.pressure, unitId: PRESSURE.pascal.name);

  static final double readingPsi = convertUnit(
    PressureDriftService.readingAtPa(
      gaugePa: convertUnit(setPsi, _psi, _pascal),
      fromTemperatureC: homeTemperatureC,
      fromAltitudeM: homeAltitudeM,
      toTemperatureC: trailTemperatureC,
      toAltitudeM: trailAltitudeM,
    ),
    _pascal,
    _psi,
  );

  static final double altitudeSharePsi = convertUnit(
    PressureDriftService.atmosphericPressurePa(homeAltitudeM) -
        PressureDriftService.atmosphericPressurePa(trailAltitudeM),
    _pascal,
    _psi,
  );

  static double get deltaPsi => readingPsi - setPsi;
  static double get temperatureSharePsi => deltaPsi - altitudeSharePsi;
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
          const SheetHeader(title: "Pressure Check", leadingIcon: Icon(Icons.compress)),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    "A pressure you set at home doesn't read the same on the trail, even if no air "
                    "escaped. This card shows what your pump would read right now.",
                    style: muted,
                  ),
                  _heading(context, "Why the reading changes"),
                  _bullet(context, Icons.ac_unit, "Colder air shrinks the air in the chamber: the reading drops."),
                  _bullet(
                    context,
                    Icons.landscape_outlined,
                    "Thinner air higher up pushes back less: the same chamber reads higher.",
                  ),
                  Text("The two often partly cancel each other out.", style: muted),
                  _heading(context, "Example"),
                  _ExampleCard(appSettings: appSettings, significant: exampleSignificant),
                  _heading(context, "What to do"),
                  Text(
                    "The feel follows what your pump reads. So the value you last set is still the right "
                    "target: pump the fork back to ${formatPressure(_Example.setPsi)} psi and it feels "
                    "the same as at home.",
                    style: muted,
                  ),
                  _heading(context, "Status"),
                  _legendRow(
                    context,
                    pressureDriftStatus(0.012, significant: false),
                    "Less than $thresholdText off. Fine to ride as is.",
                  ),
                  _legendRow(
                    context,
                    pressureDriftStatus(-0.035, significant: true),
                    "$thresholdText or more off. Worth getting the pump out.",
                  ),
                  Text(
                    "Change the threshold or skip component types in Settings › Features › Pressure Check.",
                    style: muted,
                  ),
                  _heading(context, "Good to know"),
                  _bullet(
                    context,
                    Icons.history,
                    "Each value is compared with the setup that last changed it, which is not always your "
                    "previous setup.",
                  ),
                  _bullet(
                    context,
                    Icons.location_off_outlined,
                    "Both setups need a temperature and an altitude; pressures without them are left out.",
                  ),
                  _bullet(
                    context,
                    Icons.science_outlined,
                    "Not included: how the spring curve changes at a different pressure, oil viscosity, and "
                    "the air the pump hose takes when you connect it.",
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

  Widget _legendRow(BuildContext context, GuideStatus status, String meaning) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SizedBox(
          width: 88,
          child: Align(alignment: Alignment.centerLeft, child: GuideStatusPill(status)),
        ),
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
              const SizedBox(height: 4),
              Text(label, style: muted),
              Text(
                "${formatPressure(psi)} psi",
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
        Text("${signedPressure(psi)} psi", style: textTheme.bodyMedium),
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
                "At home",
                pressureConditionsText(appSettings, _Example.homeTemperatureC, _Example.homeAltitudeM),
                "You set",
                _Example.setPsi,
              ),
              Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
              place(
                Icons.terrain_outlined,
                "At the trailhead",
                pressureConditionsText(appSettings, _Example.trailTemperatureC, _Example.trailAltitudeM),
                "Pump reads",
                _Example.readingPsi,
                end: true,
              ),
            ],
          ),
          const Divider(height: 8),
          share(Icons.ac_unit, "Colder", _Example.temperatureSharePsi),
          share(Icons.landscape_outlined, "Higher up", _Example.altitudeSharePsi),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  "Total ${signedPressure(_Example.deltaPsi)} psi",
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GuideStatusPill(pressureDriftStatus(_Example.relativeDelta, significant: significant)),
            ],
          ),
        ],
      ),
    );
  }
}
