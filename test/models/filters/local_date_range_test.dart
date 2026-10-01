import 'package:bike_setup_tracker/models/filters/local_date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 12));

  group("LocalDateRange.contains", () {
    test("includes the first day from 00:00", () {
      expect(range.contains(DateTime(2024, 5, 9, 23, 59, 59, 999)), false);
      expect(range.contains(DateTime(2024, 5, 10)), true);
    });

    test("includes the last day up to 23:59", () {
      expect(range.contains(DateTime(2024, 5, 12, 23, 59, 59, 999)), true);
      expect(range.contains(DateTime(2024, 5, 13)), false);
    });

    test("includes the days in between", () {
      expect(range.contains(DateTime(2024, 5, 11, 12)), true);
    });

    test("a single-day range holds that whole day and nothing else", () {
      final day = LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 10));

      expect(day.contains(DateTime(2024, 5, 9, 23, 59)), false);
      expect(day.contains(DateTime(2024, 5, 10)), true);
      expect(day.contains(DateTime(2024, 5, 10, 23, 59)), true);
      expect(day.contains(DateTime(2024, 5, 11)), false);
    });

    test("spans a year end", () {
      final newYear = LocalDateRange(start: DateTime(2023, 12, 31), end: DateTime(2024, 1, 1));

      expect(newYear.contains(DateTime(2023, 12, 30, 23, 59)), false);
      expect(newYear.contains(DateTime(2023, 12, 31, 8)), true);
      expect(newYear.contains(DateTime(2024, 1, 1, 23, 59)), true);
      expect(newYear.contains(DateTime(2024, 1, 2)), false);
    });

    test("reads the day a value shows, not its time zone", () {
      expect(range.contains(DateTime.utc(2024, 5, 10)), true);
      expect(range.contains(DateTime.utc(2024, 5, 12, 23, 59)), true);
      expect(range.contains(DateTime.utc(2024, 5, 13)), false);
    });
  });

  group("LocalDateRange days", () {
    test("drops the time of day of both bounds", () {
      final timed = LocalDateRange(start: DateTime(2024, 5, 10, 18, 30), end: DateTime(2024, 5, 12, 6, 15));

      expect(timed.start, DateTime(2024, 5, 10));
      expect(timed.end, DateTime(2024, 5, 12));
      expect(timed.contains(DateTime(2024, 5, 10, 8)), true);
      expect(timed.contains(DateTime(2024, 5, 12, 20)), true);
    });

    test("endExclusive is the start of the day after the last", () {
      expect(range.endExclusive, DateTime(2024, 5, 13));
      expect(LocalDateRange(start: DateTime(2024), end: DateTime(2024, 1, 31)).endExclusive, DateTime(2024, 2));
      expect(LocalDateRange(start: DateTime(2024), end: DateTime(2024, 12, 31)).endExclusive, DateTime(2025));
    });
  });

  group("LocalDateRange value semantics", () {
    test("equality compares both days", () {
      final other = LocalDateRange(start: DateTime(2024, 5, 10, 9), end: DateTime(2024, 5, 12, 21));

      expect(other, range);
      expect(other.hashCode, range.hashCode);
    });

    test("differs per bound", () {
      expect(range, isNot(LocalDateRange(start: DateTime(2024, 5, 9), end: DateTime(2024, 5, 12))));
      expect(range, isNot(LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 13))));
    });
  });
}
