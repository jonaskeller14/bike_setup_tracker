import 'package:flutter/foundation.dart';

/// An inclusive range. A `null` bound leaves that side open.
@immutable
class NumericRange {
  final double? min;
  final double? max;

  const NumericRange({this.min, this.max});

  bool get isActive => min != null || max != null;

  Map<String, Object?> toJson() => {'min': min, 'max': max};

  factory NumericRange.fromJson(Map<String, Object?> json) =>
      NumericRange(min: (json['min'] as num?)?.toDouble(), max: (json['max'] as num?)?.toDouble());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NumericRange && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}
