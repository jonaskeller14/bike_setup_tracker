import 'package:flutter/foundation.dart';

/// The model years a catalog node applies to: `2026` or `2021-2025`, inclusive.
@immutable
class YearSpan {
  final int first;
  final int last;

  const YearSpan(this.first, this.last) : assert(first <= last);

  static final _pattern = RegExp(r'^(\d{4})(?:-(\d{4}))?$');

  /// Null unless [text] is exactly `YYYY` or `YYYY-YYYY` in ascending order.
  static YearSpan? tryParse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    final first = int.parse(match[1]!);
    final last = match[2] == null ? first : int.parse(match[2]!);
    return first <= last ? YearSpan(first, last) : null;
  }

  /// The smallest span covering every span of [spans]; null when there are none.
  static YearSpan? cover(Iterable<YearSpan> spans) {
    if (spans.isEmpty) return null;
    return YearSpan(
      spans.map((span) => span.first).reduce((a, b) => a < b ? a : b),
      spans.map((span) => span.last).reduce((a, b) => a > b ? a : b),
    );
  }

  bool contains(int year) => first <= year && year <= last;

  @override
  bool operator ==(Object other) => other is YearSpan && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  /// ASCII form, the one the data files use.
  @override
  String toString() => first == last ? '$first' : '$first-$last';
}
