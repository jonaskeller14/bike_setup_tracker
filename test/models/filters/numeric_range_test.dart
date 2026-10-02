import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("NumericRange.isActive", () {
    test("is false while both sides are open", () {
      expect(const NumericRange().isActive, false);
    });

    test("is true with a min only, a max only or both", () {
      expect(const NumericRange(min: 10).isActive, true);
      expect(const NumericRange(max: 50).isActive, true);
      expect(const NumericRange(min: 10, max: 50).isActive, true);
    });

    test("a bound of zero still counts", () {
      expect(const NumericRange(min: 0).isActive, true);
      expect(const NumericRange(max: 0).isActive, true);
    });
  });

  group("NumericRange value semantics", () {
    test("equality compares both bounds", () {
      // Built at runtime: const instances would be identical anyway.
      final ten = [10.0].first;
      final a = NumericRange(min: ten, max: 50);
      final b = NumericRange(min: ten, max: 50);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test("differs per bound and from the open range", () {
      const range = NumericRange(min: 10, max: 50);
      expect(range, isNot(const NumericRange(min: 10)));
      expect(range, isNot(const NumericRange(max: 50)));
      expect(range, isNot(const NumericRange(min: 50, max: 10)));
      expect(range, isNot(const NumericRange()));
    });
  });
}
