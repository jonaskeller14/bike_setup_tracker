import 'package:bike_setup_tracker/models/filters/layer_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("LayerFilter.shows", () {
    test("the default filter shows every layer", () {
      const filter = LayerFilter();
      for (final layer in TimelineLayer.values) {
        expect(filter.shows(layer), true);
      }
    });

    test("hides only the hidden layers", () {
      const filter = LayerFilter(hidden: {TimelineLayer.tasks, TimelineLayer.activities});
      expect(filter.shows(TimelineLayer.tasks), false);
      expect(filter.shows(TimelineLayer.activities), false);
      expect(filter.shows(TimelineLayer.setups), true);
      expect(filter.shows(TimelineLayer.installations), true);
      expect(filter.shows(TimelineLayer.ratingEntries), true);
    });
  });

  group("LayerFilter.isActiveFor", () {
    test("is false for the default filter", () {
      expect(const LayerFilter().isActiveFor(TimelineLayer.values.toSet()), false);
    });

    test("is true when an available layer is hidden", () {
      const filter = LayerFilter(hidden: {TimelineLayer.tasks});
      expect(filter.isActiveFor({TimelineLayer.setups, TimelineLayer.tasks}), true);
    });

    test("ignores a hidden layer that is not available", () {
      const filter = LayerFilter(hidden: {TimelineLayer.activities, TimelineLayer.ratingEntries});
      expect(filter.isActiveFor({TimelineLayer.setups, TimelineLayer.tasks}), false);
      expect(filter.isActiveFor(const {}), false);
    });
  });

  group("LayerFilter value semantics", () {
    test("copyWith replaces the hidden layers", () {
      const filter = LayerFilter(hidden: {TimelineLayer.tasks});
      expect(filter.copyWith(hidden: const {}), const LayerFilter());
      expect(filter.copyWith(), filter);
    });

    test("equality compares hidden layers by content", () {
      // Built at runtime: const instances would be identical anyway.
      final a = LayerFilter(hidden: {TimelineLayer.tasks, TimelineLayer.setups}.toSet());
      final b = LayerFilter(hidden: {TimelineLayer.setups, TimelineLayer.tasks}.toSet());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const LayerFilter(hidden: {TimelineLayer.tasks})));
      expect(a, isNot(const LayerFilter()));
    });
  });
}
