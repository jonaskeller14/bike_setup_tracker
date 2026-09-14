import 'dart:math' as math;

import 'package:units_converter/units_converter.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/setup.dart';
import '../utils/unit_conversion.dart';
import 'setup_resolution_service.dart';

/// One numerical pressure adjustment whose ambient conditions have moved since
/// the setup that last changed it.
///
/// A pump reads *gauge* pressure — the sealed chamber measured against the
/// surrounding air — so the same trapped air reads differently once temperature
/// or altitude changes. [predictedReading] is what the pump would show now
/// without touching anything; [referenceValue] is what it showed when the value
/// was set, and therefore also what it has to read again for the same feel.
class PressureDriftEntry {
  final String adjustmentId;
  final String adjustmentName;
  final String componentName;

  /// Unit the adjustment stores its values in. Every pressure here uses it.
  final KnownUnit unit;

  /// Setup that last changed this value, plus the conditions it recorded.
  final Setup referenceSetup;
  final double referenceValue;
  final double referenceTemperatureC;
  final double referenceAltitudeM;

  final double currentTemperatureC;
  final double currentAltitudeM;

  final double predictedReading;

  /// [delta] split by cause. The two routinely cancel each other out: cold
  /// lowers the reading, thinner air at altitude raises it.
  final double temperatureShare;
  final double altitudeShare;

  const PressureDriftEntry({
    required this.adjustmentId,
    required this.adjustmentName,
    required this.componentName,
    required this.unit,
    required this.referenceSetup,
    required this.referenceValue,
    required this.referenceTemperatureC,
    required this.referenceAltitudeM,
    required this.currentTemperatureC,
    required this.currentAltitudeM,
    required this.predictedReading,
    required this.temperatureShare,
    required this.altitudeShare,
  });

  /// How far the pump reading has moved. Positive means it now reads high, so
  /// the chamber has to be bled back down to [referenceValue].
  double get delta => predictedReading - referenceValue;

  double get relativeDelta => delta / referenceValue;

  /// Whether the difference is worth getting the pump out for.
  bool get isSignificant => relativeDelta.abs() >= PressureDriftService.significanceThreshold;

  double get temperatureDeltaC => currentTemperatureC - referenceTemperatureC;
  double get altitudeDeltaM => currentAltitudeM - referenceAltitudeM;
}

/// Predicts what a pump will read for pressures that were set under different
/// ambient conditions.
///
/// The chamber is sealed at constant volume, so its absolute pressure follows
/// temperature alone, while the gauge reading is that absolute pressure minus
/// whatever the ambient air is doing:
///
///   P_abs(set)  = P_gauge(set) + P_atm(altitude when set)
///   P_abs(now)  = P_abs(set) · T(now) / T(set)        [Kelvin]
///   P_gauge(now) = P_abs(now) − P_atm(altitude now)
///
/// Spring force follows the gauge pressure at ride time, so restoring the
/// original feel means restoring the original *reading* — the useful output is
/// how far the reading has drifted, not a new target number.
///
/// Second-order effects are deliberately ignored: the spring curve's
/// progression under a different absolute pressure, damper oil viscosity, and
/// the air a pump hose swallows when it is connected.
class PressureDriftService {
  static const double significanceThreshold = 0.03;
  static const double _seaLevelPressurePa = 101325;

  static final KnownUnit _pascal = KnownUnit(
    quantity: UnitQuantity.pressure,
    unitId: PRESSURE.pascal.name,
  );

  /// Ambient pressure at [altitudeM] above sea level, in Pascal (ISA barometric
  /// formula).
  static double atmosphericPressurePa(double altitudeM) {
    // Beyond this band the formula's base goes negative, and an altitude that
    // far out is bad data rather than a real riding elevation.
    final clamped = altitudeM.clamp(-500.0, 9000.0);
    return _seaLevelPressurePa * math.pow(1 - 2.25577e-5 * clamped, 5.25588);
  }

  /// Gauge pressure a pump reads at ([toTemperatureC], [toAltitudeM]) for a
  /// chamber sealed at [gaugePa] under ([fromTemperatureC], [fromAltitudeM]).
  static double readingAtPa({
    required double gaugePa,
    required double fromTemperatureC,
    required double fromAltitudeM,
    required double toTemperatureC,
    required double toAltitudeM,
  }) {
    final absolutePa = gaugePa + atmosphericPressurePa(fromAltitudeM);
    final temperatureRatio = _kelvin(toTemperatureC) / _kelvin(fromTemperatureC);
    return absolutePa * temperatureRatio - atmosphericPressurePa(toAltitudeM);
  }

  static KnownUnit? pressureUnitOf(Adjustment adjustment) {
    if (adjustment is! NumericalAdjustment) return null;
    final unit = adjustment.unit;
    if (unit is! KnownUnit || unit.quantity != UnitQuantity.pressure) return null;
    return unit;
  }

  /// Drift for every pressure adjustment of [components] that has a resolvable
  /// source setup, in component order.
  ///
  /// An adjustment is skipped whenever temperature or altitude is missing on
  /// either side: substituting a standard value (sea level, say) would turn
  /// missing data into a confidently wrong recommendation.
  static List<PressureDriftEntry> compute({
    required Iterable<Component> components,
    required Map<String, AdjustmentProvenance> provenance,
    required ContextWeather? currentWeather,
    required ContextPosition? currentPosition,
  }) {
    final currentTemperatureC = currentWeather?.currentTemperature;
    final currentAltitudeM = currentPosition?.altitude;
    if (currentTemperatureC == null || currentAltitudeM == null) return const [];
    if (_kelvin(currentTemperatureC) <= 0) return const [];

    final entries = <PressureDriftEntry>[];
    for (final component in components) {
      for (final adjustment in component.adjustments) {
        final unit = pressureUnitOf(adjustment);
        if (unit == null) continue;

        final source = provenance[adjustment.id];
        final referenceRaw = source?.value;
        if (source == null || referenceRaw is! num) continue;
        final referenceValue = referenceRaw.toDouble();
        // Zero gauge pressure is an empty chamber, and a negative one is bad
        // data; neither has a meaningful relative drift.
        if (referenceValue <= 0) continue;

        final referenceTemperatureC = source.setup.weather?.currentTemperature;
        final referenceAltitudeM = source.setup.position?.altitude;
        if (referenceTemperatureC == null || referenceAltitudeM == null) continue;
        if (_kelvin(referenceTemperatureC) <= 0) continue;

        final predictedPa = readingAtPa(
          gaugePa: convertUnit(referenceValue, unit, _pascal),
          fromTemperatureC: referenceTemperatureC,
          fromAltitudeM: referenceAltitudeM,
          toTemperatureC: currentTemperatureC,
          toAltitudeM: currentAltitudeM,
        );
        final predictedReading = convertUnit(predictedPa, _pascal, unit);
        final altitudeShare = convertUnit(
          atmosphericPressurePa(referenceAltitudeM) - atmosphericPressurePa(currentAltitudeM),
          _pascal,
          unit,
        );

        entries.add(PressureDriftEntry(
          adjustmentId: adjustment.id,
          adjustmentName: adjustment.name,
          componentName: component.name,
          unit: unit,
          referenceSetup: source.setup,
          referenceValue: referenceValue,
          referenceTemperatureC: referenceTemperatureC,
          referenceAltitudeM: referenceAltitudeM,
          currentTemperatureC: currentTemperatureC,
          currentAltitudeM: currentAltitudeM,
          predictedReading: predictedReading,
          // Derived from the total so the two shares always add up to it.
          temperatureShare: predictedReading - referenceValue - altitudeShare,
          altitudeShare: altitudeShare,
        ));
      }
    }
    return entries;
  }

  static double _kelvin(double celsius) => celsius + 273.15;
}
