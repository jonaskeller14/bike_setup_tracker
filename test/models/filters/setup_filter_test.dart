import 'package:bike_setup_tracker/models/filters/setup_filter.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

Setup setup({Set<String> tags = const {}, bool isBookmarked = false}) => Setup(
  name: "Setup",
  tags: tags,
  isBookmarked: isBookmarked,
  datetime: DateTime.utc(2024),
  datetimeLocal: DateTime(2024),
  bike: "bike",
  person: null,
  bikeAdjustmentValues: {},
  personAdjustmentValues: {},
);

void main() {
  group("SetupFilter.matches", () {
    test("the default filter accepts every setup", () {
      const filter = SetupFilter();
      expect(filter.matches(setup()), true);
      expect(filter.matches(setup(tags: {"race"}, isBookmarked: true)), true);
    });

    test("tags require every selected tag", () {
      const filter = SetupFilter(tags: {"race", "wet"});
      expect(filter.matches(setup(tags: {"race", "wet", "alps"})), true);
      expect(filter.matches(setup(tags: {"race"})), false);
      expect(filter.matches(setup()), false);
    });

    test("bookmarkedOnly accepts only bookmarked setups", () {
      const filter = SetupFilter(bookmarkedOnly: true);
      expect(filter.matches(setup(isBookmarked: true)), true);
      expect(filter.matches(setup()), false);
    });

    test("tags and bookmarkedOnly must both hold", () {
      const filter = SetupFilter(tags: {"race"}, bookmarkedOnly: true);
      expect(filter.matches(setup(tags: {"race"}, isBookmarked: true)), true);
      expect(filter.matches(setup(tags: {"race"})), false);
      expect(filter.matches(setup(isBookmarked: true)), false);
    });
  });

  group("SetupFilter.isActive", () {
    test("is false for the default filter", () {
      expect(const SetupFilter().isActive, false);
    });

    test("is true for each criterion on its own", () {
      expect(const SetupFilter(tags: {"race"}).isActive, true);
      expect(const SetupFilter(bookmarkedOnly: true).isActive, true);
    });
  });

  group("SetupFilter value semantics", () {
    test("copyWith replaces only the given fields", () {
      const filter = SetupFilter(tags: {"race"}, bookmarkedOnly: true);
      expect(filter.copyWith(tags: const {}), const SetupFilter(bookmarkedOnly: true));
      expect(filter.copyWith(bookmarkedOnly: false), const SetupFilter(tags: {"race"}));
      expect(filter.copyWith(), filter);
    });

    test("equality compares tags by content", () {
      // Built at runtime: const instances would be identical anyway.
      final a = SetupFilter(tags: {"race", "wet"}.toSet());
      final b = SetupFilter(tags: {"wet", "race"}.toSet());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const SetupFilter(tags: {"race"})));
      expect(a, isNot(a.copyWith(bookmarkedOnly: true)));
    });
  });
}
