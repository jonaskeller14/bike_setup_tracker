part of 'adjustment.dart';

class DurationAdjustment extends Adjustment<double> {
  Duration? min;
  Duration? max;

  static const IconData iconData = Icons.timer_outlined;

  DurationAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    Duration? min,
    Duration? max,
  });

  @override
  DurationAdjustment deepCopy() {
    return DurationAdjustment(name: name, notes: notes, unit: unit);
  }

  @override
  bool isValidValue(dynamic value) {  
    return value is Duration && (min == null || value.compareTo(min!) >= 0) && (max == null || value.compareTo(max!) <= 0);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'duration',
    'valueType': valueType.toString(),
    'unit': unit,
    'min': min == null ? null : toIso8601String(min!),
    'max': max == null ? null : toIso8601String(max!),
  };

  factory DurationAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return DurationAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          min: DurationAdjustment.tryParseIso8601String(json["min"]),
          max: DurationAdjustment.tryParseIso8601String(json["max"]),
        );
      default: throw Exception("Json Version $version of DurationAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => DurationAdjustment.iconData;

  @override
  String getProperties() {
    return "Range ${min == null ? '-∞' : Adjustment.formatValue(min)}..${max == null ? '∞' : Adjustment.formatValue(max)}";
  }

  static String toIso8601String(Duration duration) {
    if (duration.inMicroseconds == 0) return "PT0S";

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final microseconds = duration.inMicroseconds.remainder(1000000);

    StringBuffer buffer = StringBuffer("P");
    
    // Date component: Days
    if (days != 0) buffer.write("${days}D");

    // Time components: T prefix is mandatory if H, M, or S are present
    if (hours != 0 || minutes != 0 || seconds != 0 || microseconds != 0) {
      buffer.write("T");
      if (hours != 0) buffer.write("${hours}H");
      if (minutes != 0) buffer.write("${minutes}M");
      
      if (seconds != 0 || microseconds != 0) {
        if (microseconds == 0) {
          buffer.write("${seconds}S");
        } else {
          // Handle decimal seconds for precision
          double s = seconds + (microseconds / 1000000.0);
          buffer.write("${s.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}S");
        }
      }
    }

    return buffer.toString();
  }

  static Duration? tryParseIso8601String(String? isoString) {
    if (isoString == null) return null;
    
    try {
      // Regex explained: 
      // ^P start with P
      // (?:(\d+)D)? optional Days
      // (?:T...)? optional Time section starting with T
      // (?:(\d+)H)? optional Hours
      // (?:(\d+)M)? optional Minutes
      // (?:(\d+(?:\.\d+)?)S)? optional Seconds (supports decimals)
      final regex = RegExp(r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)?$');
      
      final match = regex.firstMatch(isoString);
      if (match == null || isoString == "P") return null;

      final days = int.parse(match.group(1) ?? '0');
      final hours = int.parse(match.group(2) ?? '0');
      final minutes = int.parse(match.group(3) ?? '0');
      final secondsInput = double.parse(match.group(4) ?? '0');

      final seconds = secondsInput.toInt();
      final microseconds = ((secondsInput - seconds) * 1000000).round();

      return Duration(
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        microseconds: microseconds,
      );
    } catch (e) {
      return null;
    }
  }
}
