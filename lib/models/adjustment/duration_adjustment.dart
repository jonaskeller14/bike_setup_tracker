part of 'adjustment.dart';

class DurationAdjustment extends Adjustment {
  final Duration? min;
  final Duration? max;

  static const IconData iconData = Icons.timer_outlined;

  DurationAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    this.min,
    this.max,
  });

  @override
  DurationAdjustment deepCopy() {
    return DurationAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      min: min,
      max: max,
    );
  }

  DurationAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? min = const _Sentinel(),
    Object? max = const _Sentinel(),
  }) {
    return DurationAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      unit: unit is _Sentinel ? this.unit : (unit as AdjustmentUnit?),
      min: min is _Sentinel ? this.min : (min as Duration?),
      max: max is _Sentinel ? this.max : (max as Duration?),
    );
  }

  @override
  bool isValidValue(dynamic value) {  
    return value is Duration && (min == null || value.compareTo(min!) >= 0) && (max == null || value.compareTo(max!) <= 0);
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.duration.name,
    'unit': unit?.encode(),
    'min': min?.toString(),
    'max': max?.toString(),
  };

  factory DurationAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return DurationAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: AdjustmentUnit.decode(json['unit'] as String?),
          min: DurationAdjustment.tryParseDurationString(json["min"]),
          max: DurationAdjustment.tryParseDurationString(json["max"]),
        );
      default: throw Exception("Json Version $version of DurationAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => DurationAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DurationAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        min == other.min &&
        max == other.max;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, min, max);
  }

  static Duration? tryParseDurationString(String? durationString) {
    if (durationString == null || durationString.isEmpty) return null;

    try {
      // Regex explained:
      // ^(-?)            Optional negative sign
      // (\d+)            Hours (can be multiple digits)
      // :(\d{1,2})       Minutes (1-2 digits)
      // :(\d{1,2})       Seconds (1-2 digits)
      // (?:\.(\d{1,6}))? Optional microseconds (up to 6 digits)
      final regex = RegExp(r'^(-?)(\d+):(\d{1,2}):(\d{1,2})(?:\.(\d{1,6}))?$');

      final match = regex.firstMatch(durationString);
      if (match == null) return null;

      final isNegative = match.group(1) == '-';
      final hours = int.parse(match.group(2)!);
      final minutes = int.parse(match.group(3)!);
      final seconds = int.parse(match.group(4)!);
      
      // Microseconds need padding if the string has fewer than 6 digits (e.g., .1 -> 100000)
      final microPart = match.group(5) ?? '0';
      final microseconds = int.parse(microPart.padRight(6, '0'));

      final duration = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        microseconds: microseconds,
      );

      return isNegative ? -duration : duration;
    } catch (e) {
      return null;
    }
  }
}
