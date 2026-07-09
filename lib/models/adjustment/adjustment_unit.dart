import 'package:units_converter/units_converter.dart';

enum UnitQuantity {
  pressure('Pressure'),
  length('Length'),
  mass('Mass'),
  temperature('Temperature'),
  speed('Speed'),
  angle('Angle'),
  torque('Torque'),
  volume('Volume'),
  springRate('Spring Rate');
  final String label;
  const UnitQuantity(this.label);
}

class UnitCatalogEntry {
  final String unitId;  // id used by `units_converter`
  final String label;
  const UnitCatalogEntry(this.unitId, this.label);
}

final Map<UnitQuantity, List<UnitCatalogEntry>> unitCatalog = {
  UnitQuantity.pressure: [
    UnitCatalogEntry(PRESSURE.psi.name, 'psi'),
    UnitCatalogEntry(PRESSURE.bar.name, 'bar'),
    UnitCatalogEntry(PRESSURE.kiloPascal.name, 'kPa'),
  ],
  UnitQuantity.length: [
    UnitCatalogEntry(LENGTH.millimeters.name, 'mm'),
    UnitCatalogEntry(LENGTH.centimeters.name, 'cm'),
    UnitCatalogEntry(LENGTH.inches.name, 'in'),
  ],
  UnitQuantity.mass: [
    UnitCatalogEntry(MASS.kilograms.name, 'kg'),
    UnitCatalogEntry(MASS.grams.name, 'g'),
    UnitCatalogEntry(MASS.pounds.name, 'lb'),
  ],
  UnitQuantity.temperature: [
    UnitCatalogEntry(TEMPERATURE.celsius.name, '°C'),
    UnitCatalogEntry(TEMPERATURE.fahrenheit.name, '°F'),
  ],
  UnitQuantity.speed: [
    UnitCatalogEntry(SPEED.kilometersPerHour.name, 'km/h'),
    UnitCatalogEntry(SPEED.milesPerHour.name, 'mph'),
    UnitCatalogEntry(SPEED.metersPerSecond.name, 'm/s'),
  ],
  UnitQuantity.angle: [
    UnitCatalogEntry(ANGLE.degree.name, '°'),
    UnitCatalogEntry(ANGLE.radians.name, 'rad'),
  ],
  UnitQuantity.torque: [
    UnitCatalogEntry(TORQUE.newtonMeter.name, 'Nm'),
    UnitCatalogEntry(TORQUE.poundForceInch.name, 'in·lb'),
  ],
  UnitQuantity.volume: [
    UnitCatalogEntry(VOLUME.milliliters.name, 'ml'),
    UnitCatalogEntry(VOLUME.usFluidOunces.name, 'fl oz'),
  ],
  UnitQuantity.springRate: [
    const UnitCatalogEntry('N/mm', 'N/mm'),
    const UnitCatalogEntry('lbs/in', 'lbs/in'),
  ],
};

const List<String> blessedCustomUnitLabels = ['%', 'clicks', 'turns', 'tokens'];

// Case-insensitive spelling
final Map<String, (UnitQuantity, String)> _aliasTable = {
  // pressure
  'psi': (UnitQuantity.pressure, PRESSURE.psi.name),
  'bar': (UnitQuantity.pressure, PRESSURE.bar.name),
  'kpa': (UnitQuantity.pressure, PRESSURE.kiloPascal.name),
  // length
  'mm': (UnitQuantity.length, LENGTH.millimeters.name),
  'cm': (UnitQuantity.length, LENGTH.centimeters.name),
  'in': (UnitQuantity.length, LENGTH.inches.name),
  'inch': (UnitQuantity.length, LENGTH.inches.name),
  // mass
  'kg': (UnitQuantity.mass, MASS.kilograms.name),
  'g': (UnitQuantity.mass, MASS.grams.name),
  'lb': (UnitQuantity.mass, MASS.pounds.name),
  'lbs': (UnitQuantity.mass, MASS.pounds.name),
  // temperature (bare "c"/"f" intentionally excluded — too ambiguous)
  '°c': (UnitQuantity.temperature, TEMPERATURE.celsius.name),
  '°f': (UnitQuantity.temperature, TEMPERATURE.fahrenheit.name),
  // speed
  'km/h': (UnitQuantity.speed, SPEED.kilometersPerHour.name),
  'kph': (UnitQuantity.speed, SPEED.kilometersPerHour.name),
  'kmh': (UnitQuantity.speed, SPEED.kilometersPerHour.name),
  'mph': (UnitQuantity.speed, SPEED.milesPerHour.name),
  'm/s': (UnitQuantity.speed, SPEED.metersPerSecond.name),
  // angle
  '°': (UnitQuantity.angle, ANGLE.degree.name),
  'deg': (UnitQuantity.angle, ANGLE.degree.name),
  // torque
  'nm': (UnitQuantity.torque, TORQUE.newtonMeter.name),
  'n·m': (UnitQuantity.torque, TORQUE.newtonMeter.name),
  'n-m': (UnitQuantity.torque, TORQUE.newtonMeter.name),
  // volume
  'ml': (UnitQuantity.volume, VOLUME.milliliters.name),
  'fl oz': (UnitQuantity.volume, VOLUME.usFluidOunces.name),
  'oz': (UnitQuantity.volume, VOLUME.usFluidOunces.name),
  // spring rate (no package enum; see unitCatalog)
  'n/mm': (UnitQuantity.springRate, 'N/mm'),
  'lbs/in': (UnitQuantity.springRate, 'lbs/in'),
  'lb/in': (UnitQuantity.springRate, 'lbs/in'),
};

sealed class AdjustmentUnit {
  const AdjustmentUnit();

  String get label;
  String encode();

  static AdjustmentUnit? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final idx = raw.indexOf(':');
    if (idx <= 0 || idx == raw.length - 1) return CustomUnit(raw);
    final quantityName = raw.substring(0, idx);
    final unitId = raw.substring(idx + 1);
    final quantity = UnitQuantity.values.asNameMap()[quantityName];
    if (quantity == null) return CustomUnit(raw);
    final isKnownUnitId = unitCatalog[quantity]!.any((e) => e.unitId == unitId);
    if (!isKnownUnitId) return CustomUnit(raw);
    return KnownUnit(quantity: quantity, unitId: unitId);
  }

  static AdjustmentUnit? fromLegacy(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final strict = decode(trimmed);
    if (strict is KnownUnit) return strict;
    final alias = _aliasTable[trimmed.toLowerCase()];
    if (alias != null) {
      final (quantity, unitId) = alias;
      return KnownUnit(quantity: quantity, unitId: unitId);
    }
    return CustomUnit(trimmed);
  }
}

class KnownUnit extends AdjustmentUnit {
  final UnitQuantity quantity;
  final String unitId;

  const KnownUnit({required this.quantity, required this.unitId});

  @override
  String get label {
    for (final entry in unitCatalog[quantity]!) {
      if (entry.unitId == unitId) return entry.label;
    }
    return unitId;
  }

  @override
  String encode() => '${quantity.name}:$unitId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownUnit && quantity == other.quantity && unitId == other.unitId);

  @override
  int get hashCode => Object.hash(quantity, unitId);

  @override
  String toString() => 'KnownUnit(${encode()})';
}

/// An opaque, non-convertible unit label (e.g. "clicks", "%", or any legacy
/// spelling that couldn't be matched to the [unitCatalog]).
class CustomUnit extends AdjustmentUnit {
  @override
  final String label;

  const CustomUnit(this.label);

  @override
  String encode() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomUnit && label == other.label);

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() => 'CustomUnit($label)';
}
