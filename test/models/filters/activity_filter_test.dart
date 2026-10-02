import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ActivityFilter.isActive", () {
    test("is false for the default filter", () {
      expect(const ActivityFilter().isActive, false);
    });

    test("is true with a distance range, an elevation gain range or both", () {
      expect(const ActivityFilter(distance: NumericRange(min: 10000)).isActive, true);
      expect(const ActivityFilter(elevationGain: NumericRange(max: 500)).isActive, true);
      expect(
        const ActivityFilter(distance: NumericRange(min: 10000), elevationGain: NumericRange(max: 500)).isActive,
        true,
      );
    });
  });

  group("ActivityFilter value semantics", () {
    const filter = ActivityFilter(distance: NumericRange(min: 10000), elevationGain: NumericRange(max: 500));

    test("copyWith replaces one range and keeps the other", () {
      expect(
        filter.copyWith(distance: const NumericRange()),
        const ActivityFilter(elevationGain: NumericRange(max: 500)),
      );
      expect(
        filter.copyWith(elevationGain: const NumericRange(min: 100)),
        const ActivityFilter(distance: NumericRange(min: 10000), elevationGain: NumericRange(min: 100)),
      );
      expect(filter.copyWith(), filter);
    });

    test("equality compares both ranges", () {
      // Built at runtime: const instances would be identical anyway.
      final min = [10000.0].first;
      final a = ActivityFilter(
        distance: NumericRange(min: min),
        elevationGain: const NumericRange(max: 500),
      );
      expect(a, filter);
      expect(a.hashCode, filter.hashCode);
      expect(a, isNot(const ActivityFilter(distance: NumericRange(min: 10000))));
      expect(a, isNot(const ActivityFilter(elevationGain: NumericRange(max: 500))));
      expect(a, isNot(const ActivityFilter()));
    });

    test("the same range on the other criterion is a different filter", () {
      expect(
        const ActivityFilter(distance: NumericRange(min: 100)),
        isNot(const ActivityFilter(elevationGain: NumericRange(min: 100))),
      );
    });
  });
}
