import 'package:intl/intl.dart';
import 'package:units_converter/units_converter.dart';
import '../models/adjustment/adjustment_unit.dart';

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

String formatConverted(double value) => NumberFormat('0.#####', 'en_US').format(value);
