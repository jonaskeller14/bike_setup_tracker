import 'package:intl/intl.dart';
import 'package:units_converter/units_converter.dart';

import '../models/adjustment/adjustment.dart';

final double _lbsInToNmm =
    1.0.convertFromTo(FORCE.poundForce, FORCE.newton)! /
    1.0.convertFromTo(LENGTH.inches, LENGTH.millimeters)!;

Map<String, double> get _springRateConversion => {
  'N/mm': 1.0,
  'lbs/in': 1 / _lbsInToNmm,
};

double convertUnit(double value, KnownUnit from, KnownUnit to) {
  assert(
    from.quantity == to.quantity,
    'convertUnit: quantity mismatch (${from.quantity} vs ${to.quantity})',
  );
  if (from.unitId == to.unitId) return value;

  if (from.quantity == UnitQuantity.springRate) {
    final property = SimpleCustomProperty(_springRateConversion)
      ..convert(from.unitId, value);
    return property.getUnit(to.unitId).value!;
  }

  final fromEnum = _enumValue(from.quantity, from.unitId);
  final toEnum = _enumValue(to.quantity, to.unitId);
  return value.convertFromTo(fromEnum, toEnum)!;
}

dynamic _enumValue(UnitQuantity quantity, String unitId) {
  switch (quantity) {
    case UnitQuantity.pressure:
      return PRESSURE.values.byName(unitId);
    case UnitQuantity.length:
      return LENGTH.values.byName(unitId);
    case UnitQuantity.mass:
      return MASS.values.byName(unitId);
    case UnitQuantity.temperature:
      return TEMPERATURE.values.byName(unitId);
    case UnitQuantity.speed:
      return SPEED.values.byName(unitId);
    case UnitQuantity.angle:
      return ANGLE.values.byName(unitId);
    case UnitQuantity.torque:
      return TORQUE.values.byName(unitId);
    case UnitQuantity.volume:
      return VOLUME.values.byName(unitId);
    case UnitQuantity.springRate:
      throw StateError('springRate is handled via SimpleCustomProperty, not an enum');
  }
}

List<KnownUnit> toggleCycle(UnitQuantity quantity) {
  return unitCatalog[quantity]!
      .map((entry) => KnownUnit(quantity: quantity, unitId: entry.unitId))
      .toList();
}

/// One stop in a value's tap-to-toggle unit cycle: a label plus the mapping to
/// and from the *stored* value.
///
/// Entry 0 is always the storage unit, so an active index of 0 means "no
/// conversion". A cycle of length < 2 means there is nothing to toggle to.
typedef UnitCycleEntry = ({
  String label,
  double Function(double storageValue) fromStorage,
  double Function(double displayValue) toStorage,
});

/// The catalog-driven cycle for a value stored in [storage], rotated so the
/// storage unit leads. Rotation preserves the catalog's cyclic order, so the
/// sequence a user taps through is unchanged.
///
/// Empty when [storage] is not a convertible [KnownUnit].
List<UnitCycleEntry> knownUnitCycle(AdjustmentUnit? storage) {
  if (storage is! KnownUnit) return const [];
  final units = toggleCycle(storage.quantity);
  final index = units.indexWhere((u) => u.unitId == storage.unitId);
  if (index < 0) return const []; // storage unit outside its own catalog
  final ordered = [...units.sublist(index), ...units.sublist(0, index)];
  return ordered
      .map((unit) => (
            label: unit.label,
            fromStorage: (double v) => convertUnit(v, storage, unit),
            toStorage: (double v) => convertUnit(v, unit, storage),
          ))
      .toList();
}

/// Sag's cycle: the stored percentage, plus the absolute travel reading in
/// metric (mm) and imperial (in), derived from the adjustment's reference travel.
///
/// Degrades to percent-only (no toggle) when the travel is unknown, since there
/// is nothing to compute an absolute length against.
List<UnitCycleEntry> sagUnitCycle(SagAdjustment adjustment) {
  const percent = (
    label: '%',
    fromStorage: _identity,
    toStorage: _identity,
  );
  final travel = adjustment.referenceTravelMm;
  if (travel == null || travel <= 0) return const [percent];

  final mm = KnownUnit(quantity: UnitQuantity.length, unitId: LENGTH.millimeters.name);
  final inch = KnownUnit(quantity: UnitQuantity.length, unitId: LENGTH.inches.name);

  return [
    percent,
    (
      label: 'mm',
      fromStorage: (double pct) => pct / 100 * travel,
      toStorage: (double v) => v / travel * 100,
    ),
    (
      label: 'in',
      fromStorage: (double pct) => convertUnit(pct / 100 * travel, mm, inch),
      toStorage: (double v) => convertUnit(v, inch, mm) / travel * 100,
    ),
  ];
}

double _identity(double value) => value;

String formatConverted(double value) => NumberFormat('0.#####', 'en_US').format(value);
