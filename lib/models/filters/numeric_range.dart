import 'package:flutter/foundation.dart';

/// An inclusive range. A `null` bound leaves that side open.
@immutable
class NumericRange {
  final double? min;
  final double? max;

  const NumericRange({this.min, this.max});

  bool get isActive => min != null || max != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NumericRange && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
}
