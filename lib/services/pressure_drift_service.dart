import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:units_converter/units_converter.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/context/context_position.dart';
import '../models/context/context_weather.dart';
import '../models/setup.dart';
import '../utils/unit_conversion.dart';
import 'setup_resolution_service.dart';

@immutable
class PressureConditions {
  final double temperatureC;
  final double altitudeM;

  const PressureConditions({required this.temperatureC, required this.altitudeM});

  static PressureConditions? of(ContextWeather? weather, ContextPosition? position) {
    final temperatureC = weather?.currentTemperature;
    final altitudeM = position?.altitude;
    if (temperatureC == null || altitudeM == null) return null;
    if (PressureDriftService.kelvin(temperatureC) <= 0) return null;
    return PressureConditions(temperatureC: temperatureC, altitudeM: altitudeM);
  }

  static PressureConditions? ofSetup(Setup setup) => of(setup.weather, setup.position);

  @override
  bool operator ==(Object other) =>
      other is PressureConditions && other.temperatureC == temperatureC && other.altitudeM == altitudeM;

  @override
  int get hashCode => Object.hash(temperatureC, altitudeM);
}

/// What a pump reads for a chamber set to `referenceValue` once the conditions
/// have moved, split by cause. The shares add up to `reading − referenceValue`.
typedef PressurePrediction = ({double reading, double temperatureShare, double altitudeShare});

sealed class PressureCheckEntry {
  final String adjustmentId;
  final String adjustmentName;
  final String componentName;
  final KnownUnit unit;
  final Setup referenceSetup;
  final double referenceValue;

  const PressureCheckEntry({
    required this.adjustmentId,
    required this.adjustmentName,
    required this.componentName,
    required this.unit,
    required this.referenceSetup,
    required this.referenceValue,
  });
}

final class PressureDriftEntry extends PressureCheckEntry {
  final PressureConditions referenceConditions;
  final PressureConditions currentConditions;
  final double predictedReading;

  final double temperatureShare;
  final double altitudeShare;

  /// Relative drift from which correcting the pressure is worthwhile.
  final double significanceThreshold;

  const PressureDriftEntry({
    required super.adjustmentId,
    required super.adjustmentName,
    required super.componentName,
    required super.unit,
    required super.referenceSetup,
    required super.referenceValue,
    required this.referenceConditions,
    required this.currentConditions,
    required this.predictedReading,
    required this.temperatureShare,
    required this.altitudeShare,
    this.significanceThreshold = PressureDriftService.defaultSignificanceThreshold,
  });

  double get delta => predictedReading - referenceValue;

  double get relativeDelta => delta / referenceValue;

  bool get isSignificant => relativeDelta.abs() >= significanceThreshold;

  double get temperatureDeltaC => currentConditions.temperatureC - referenceConditions.temperatureC;
  double get altitudeDeltaM => currentConditions.altitudeM - referenceConditions.altitudeM;
}

final class PressureReferenceGapEntry extends PressureCheckEntry {
  const PressureReferenceGapEntry({
    required super.adjustmentId,
    required super.adjustmentName,
    required super.componentName,
    required super.unit,
    required super.referenceSetup,
    required super.referenceValue,
  });
}

enum PressureDriftGap {
  noRecordedPressure,
  noRecordedConditions,
  noCurrentConditions,
}

@immutable
class PressureCheck {
  /// Null while the current temperature or altitude is missing.
  final PressureConditions? currentConditions;

  /// Every recorded pressure, in component order. Empty while
  /// [currentConditions] is null, since nothing can be compared or marked then.
  final List<PressureCheckEntry> entries;

  /// Why [driftEntries] is empty, or null when it isn't. A gap the rider cannot
  /// fix by fetching the current conditions comes first.
  final PressureDriftGap? gap;

  const PressureCheck({this.currentConditions, this.entries = const [], this.gap});

  List<PressureDriftEntry> get driftEntries => entries.whereType<PressureDriftEntry>().toList();

  List<PressureReferenceGapEntry> get referenceGapEntries => entries.whereType<PressureReferenceGapEntry>().toList();
}

/// Predicts what a pump will read for pressures that were set under different
/// ambient conditions.
///
/// The chamber is sealed at constant volume, so its absolute pressure follows
/// temperature alone, while the gauge reading is that absolute pressure minus
/// whatever the ambient air is doing:
///
///   P_abs(set)  = P_gauge(set) + P_atm(altitude when set)
///   P_abs(now)  = P_abs(set) · T(now) / T(set)        (Kelvin)
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
  static const double defaultSignificanceThreshold = 0.03;
  static const double _seaLevelPressurePa = 101325;

  static final KnownUnit _pascal = KnownUnit(
    quantity: UnitQuantity.pressure,
    unitId: PRESSURE.pascal.name,
  );

  static double kelvin(double celsius) => celsius + 273.15;

  /// Ambient pressure at [altitudeM] above sea level, in Pascal (ISA barometric
  /// formula).
  static double atmosphericPressurePa(double altitudeM) {
    // Beyond this band the formula's base goes negative, and an altitude that
    // far out is bad data rather than a real riding elevation.
    final clamped = altitudeM.clamp(-500.0, 9000.0);
    return _seaLevelPressurePa * math.pow(1 - 2.25577e-5 * clamped, 5.25588);
  }

  /// Gauge pressure a pump reads under [to] for a chamber sealed at [gaugePa]
  /// under [from].
  static double readingAtPa({
    required double gaugePa,
    required PressureConditions from,
    required PressureConditions to,
  }) {
    final absolutePa = gaugePa + atmosphericPressurePa(from.altitudeM);
    final temperatureRatio = kelvin(to.temperatureC) / kelvin(from.temperatureC);
    return absolutePa * temperatureRatio - atmosphericPressurePa(to.altitudeM);
  }

  /// [readingAtPa] for a value in [unit], with the drift split by cause.
  static PressurePrediction predict({
    required double value,
    required KnownUnit unit,
    required PressureConditions from,
    required PressureConditions to,
  }) {
    final reading = convertUnit(
      readingAtPa(gaugePa: convertUnit(value, unit, _pascal), from: from, to: to),
      _pascal,
      unit,
    );
    final altitudeShare = convertUnit(
      atmosphericPressurePa(from.altitudeM) - atmosphericPressurePa(to.altitudeM),
      _pascal,
      unit,
    );
    // Derived from the total so the shares always add up to it.
    return (reading: reading, temperatureShare: reading - value - altitudeShare, altitudeShare: altitudeShare);
  }

  static KnownUnit? pressureUnitOf(Adjustment adjustment) {
    if (adjustment is! NumericalAdjustment) return null;
    final unit = adjustment.unit;
    if (unit is! KnownUnit || unit.quantity != UnitQuantity.pressure) return null;
    return unit;
  }

  static bool hasPressureAdjustment(Iterable<Component> components) =>
      components.any((component) => component.adjustments.any((adjustment) => pressureUnitOf(adjustment) != null));

  /// Compares every pressure adjustment of [components] that [provenance]
  /// resolves to a positive value with the conditions it was set in.
  ///
  /// Zero gauge pressure is an empty chamber, and a negative one is bad data;
  /// neither has a meaningful relative drift, so both count as not recorded.
  static PressureCheck check({
    required Iterable<Component> components,
    required Map<String, AdjustmentProvenance> provenance,
    required ContextWeather? currentWeather,
    required ContextPosition? currentPosition,
    double significanceThreshold = defaultSignificanceThreshold,
  }) {
    final recorded = [
      for (final component in components)
        for (final adjustment in component.adjustments)
          if (pressureUnitOf(adjustment) case final unit?)
            if (provenance[adjustment.id] case (value: NumericalValue(:final value), :final setup) when value > 0)
              (component: component, adjustment: adjustment, unit: unit, setup: setup, value: value),
    ];
    final current = PressureConditions.of(currentWeather, currentPosition);
    if (recorded.isEmpty) {
      return PressureCheck(currentConditions: current, gap: PressureDriftGap.noRecordedPressure);
    }
    if (current == null) {
      final anyReferenceConditions = recorded.any((r) => PressureConditions.ofSetup(r.setup) != null);
      return PressureCheck(
        gap: anyReferenceConditions ? PressureDriftGap.noCurrentConditions : PressureDriftGap.noRecordedConditions,
      );
    }

    final entries = <PressureCheckEntry>[
      for (final r in recorded)
        if (PressureConditions.ofSetup(r.setup) case final reference?)
          _driftEntry(
            component: r.component,
            adjustment: r.adjustment,
            unit: r.unit,
            setup: r.setup,
            value: r.value,
            reference: reference,
            current: current,
            significanceThreshold: significanceThreshold,
          )
        else
          PressureReferenceGapEntry(
            adjustmentId: r.adjustment.id,
            adjustmentName: r.adjustment.name,
            componentName: r.component.name,
            unit: r.unit,
            referenceSetup: r.setup,
            referenceValue: r.value,
          ),
    ];
    return PressureCheck(
      currentConditions: current,
      entries: entries,
      gap: entries.any((entry) => entry is PressureDriftEntry) ? null : PressureDriftGap.noRecordedConditions,
    );
  }

  static PressureDriftEntry _driftEntry({
    required Component component,
    required Adjustment adjustment,
    required KnownUnit unit,
    required Setup setup,
    required double value,
    required PressureConditions reference,
    required PressureConditions current,
    required double significanceThreshold,
  }) {
    final prediction = predict(value: value, unit: unit, from: reference, to: current);
    return PressureDriftEntry(
      adjustmentId: adjustment.id,
      adjustmentName: adjustment.name,
      componentName: component.name,
      unit: unit,
      referenceSetup: setup,
      referenceValue: value,
      referenceConditions: reference,
      currentConditions: current,
      predictedReading: prediction.reading,
      temperatureShare: prediction.temperatureShare,
      altitudeShare: prediction.altitudeShare,
      significanceThreshold: significanceThreshold,
    );
  }
}
