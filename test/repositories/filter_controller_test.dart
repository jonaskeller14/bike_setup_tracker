import 'package:bike_setup_tracker/models/filters/layer_filter.dart';
import 'package:bike_setup_tracker/models/filters/setup_filter.dart';
import 'package:bike_setup_tracker/models/filters/task_rule_filter.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/filter_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FilterController filters;
  late int changes;

  setUp(() {
    changes = 0;
    filters = FilterController(onChanged: () => changes++);
  });

  test("starts without any criteria", () {
    expect(filters.bikeId, null);
    expect(filters.setup, const SetupFilter());
    expect(filters.taskRule, TaskRuleFilter());
    expect(filters.layers, const LayerFilter());
  });

  group("toggleBike", () {
    test("selects a bike", () {
      filters.toggleBike("b1");
      expect(filters.bikeId, "b1");
      expect(changes, 1);
    });

    test("switches straight to another bike", () {
      filters.toggleBike("b1");
      filters.toggleBike("b2");
      expect(filters.bikeId, "b2");
      expect(changes, 2);
    });

    test("tapping the selected bike again clears the selection", () {
      filters.toggleBike("b1");
      filters.toggleBike("b1");
      expect(filters.bikeId, null);
      expect(changes, 2);
    });

    test("null clears the selection", () {
      filters.toggleBike("b1");
      filters.toggleBike(null);
      expect(filters.bikeId, null);
      expect(changes, 2);
    });

    test("null without a selection does not fire", () {
      filters.toggleBike(null);
      expect(changes, 0);
    });
  });

  group("setters", () {
    test("setup fires once per actual change", () {
      filters.setup = const SetupFilter(tags: {"race"});
      expect(filters.setup, const SetupFilter(tags: {"race"}));
      expect(changes, 1);

      // An equal value that is not the same instance.
      filters.setup = SetupFilter(tags: {"race"}.toSet());
      expect(changes, 1);
    });

    test("taskRule fires once per actual change", () {
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high});
      expect(filters.taskRule.priorities, {TaskPriority.high});
      expect(changes, 1);

      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high});
      expect(changes, 1);
    });

    test("layers fires once per actual change", () {
      filters.layers = const LayerFilter(hidden: {TimelineLayer.tasks});
      expect(filters.layers.shows(TimelineLayer.tasks), false);
      expect(changes, 1);

      filters.layers = LayerFilter(hidden: {TimelineLayer.tasks}.toSet());
      expect(changes, 1);
    });

    test("equal default values do not fire", () {
      filters.setup = const SetupFilter();
      filters.taskRule = TaskRuleFilter();
      filters.layers = const LayerFilter();
      expect(changes, 0);
    });
  });

  group("normalize", () {
    setUp(() {
      filters.toggleBike("b1");
      filters.setup = const SetupFilter(tags: {"race", "wet"}, bookmarkedOnly: true);
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {"service", "fork"});
      filters.layers = const LayerFilter(hidden: {TimelineLayer.tasks});
      changes = 0;
    });

    test("keeps criteria that still exist", () {
      filters.normalize(bikeIds: ["b1", "b2"], setupTags: {"race", "wet"}, taskRuleTags: {"service", "fork"});

      expect(filters.bikeId, "b1");
      expect(filters.setup, const SetupFilter(tags: {"race", "wet"}, bookmarkedOnly: true));
      expect(filters.taskRule, TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {"service", "fork"}));
    });

    test("drops a deleted bike", () {
      filters.normalize(bikeIds: ["b2"], setupTags: {"race", "wet"}, taskRuleTags: {"service", "fork"});
      expect(filters.bikeId, null);
    });

    test("drops vanished tags and keeps the other criteria", () {
      filters.normalize(bikeIds: ["b1"], setupTags: {"race"}, taskRuleTags: {"fork"});

      expect(filters.setup, const SetupFilter(tags: {"race"}, bookmarkedOnly: true));
      expect(filters.taskRule, TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {"fork"}));
    });

    test("never fires the callback", () {
      filters.normalize(bikeIds: [], setupTags: {}, taskRuleTags: {});

      expect(filters.bikeId, null);
      expect(filters.setup.tags, isEmpty);
      expect(filters.taskRule.tags, isEmpty);
      expect(filters.layers, const LayerFilter(hidden: {TimelineLayer.tasks}));
      expect(changes, 0);
    });
  });
}
