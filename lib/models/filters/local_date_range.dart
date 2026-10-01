import 'package:flutter/foundation.dart';

/// An inclusive range of local calendar days. Only the day of [start] and
/// [end] counts: their time of day is dropped.
@immutable
class LocalDateRange {
  final DateTime start;
  final DateTime end;

  LocalDateRange({required DateTime start, required DateTime end})
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day);

  /// The first day after the range, for a query that needs an exclusive bound.
  DateTime get endExclusive => DateTime(end.year, end.month, end.day + 1);

  /// Whether the calendar day of [local] is in the range. Reads the wall-clock
  /// fields only, so a local-floating value is compared by the day it shows.
  bool contains(DateTime local) {
    final day = DateTime(local.year, local.month, local.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocalDateRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}
