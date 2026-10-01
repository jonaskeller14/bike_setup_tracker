import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/layer_filter.dart';
import 'package:bike_setup_tracker/models/filters/local_date_range.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
import 'package:bike_setup_tracker/models/filters/setup_filter.dart';
import 'package:bike_setup_tracker/models/filters/task_rule_filter.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity_query.dart';
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
    expect(filters.dateRange, null);
    expect(filters.setup, const SetupFilter());
    expect(filters.taskRule, TaskRuleFilter());
    expect(filters.layers, const LayerFilter());
    expect(filters.activity, const ActivityFilter());
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

    test("activity fires once per actual change", () {
      filters.activity = const ActivityFilter(distance: NumericRange(min: 10000));
      expect(filters.activity.distance, const NumericRange(min: 10000));
      expect(changes, 1);

      // An equal value that is not the same instance.
      filters.activity = ActivityFilter(distance: NumericRange(min: [10000.0].first));
      expect(changes, 1);

      filters.activity = filters.activity.copyWith(elevationGain: const NumericRange(max: 500));
      expect(changes, 2);
    });

    test("dateRange fires once per actual change, also when it is cleared", () {
      filters.dateRange = LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 12));
      expect(filters.dateRange, LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 12)));
      expect(changes, 1);

      // An equal value that is not the same instance.
      filters.dateRange = LocalDateRange(start: DateTime(2024, 5, 10, 8), end: DateTime(2024, 5, 12, 20));
      expect(changes, 1);

      filters.dateRange = null;
      expect(filters.dateRange, null);
      expect(changes, 2);
    });

    test("equal default values do not fire", () {
      filters.dateRange = null;
      filters.setup = const SetupFilter();
      filters.taskRule = TaskRuleFilter();
      filters.layers = const LayerFilter();
      filters.activity = const ActivityFilter();
      expect(changes, 0);
    });
  });

  group("stravaQuery", () {
    test("no selected bike queries every gear", () {
      expect(filters.stravaQuery(null), const StravaActivityQuery());
    });

    test("a bike with a linked gear queries that gear", () {
      final bike = Bike(name: "Enduro", person: null, stravaGear: "g1");
      expect(filters.stravaQuery(bike), const StravaActivityQuery(gearId: "g1"));
    });

    test("a bike without a linked gear has no query", () {
      final bike = Bike(name: "Hardtail", person: null, stravaGear: null);
      expect(filters.stravaQuery(bike), null);
    });

    group("with activity criteria", () {
      const activity = ActivityFilter(distance: NumericRange(min: 10000), elevationGain: NumericRange(max: 500));

      setUp(() => filters.activity = activity);

      test("no selected bike queries every gear within the ranges", () {
        expect(filters.stravaQuery(null), const StravaActivityQuery(activity: activity));
      });

      test("a bike with a linked gear queries that gear within the ranges", () {
        final bike = Bike(name: "Enduro", person: null, stravaGear: "g1");
        expect(filters.stravaQuery(bike), const StravaActivityQuery(gearId: "g1", activity: activity));
      });

      test("a bike without a linked gear still has no query", () {
        final bike = Bike(name: "Hardtail", person: null, stravaGear: null);
        expect(filters.stravaQuery(bike), null);
      });
    });

    group("with a date range", () {
      const activity = ActivityFilter(distance: NumericRange(min: 10000));
      final may = LocalDateRange(start: DateTime(2024, 5), end: DateTime(2024, 5, 31));

      setUp(() {
        filters.activity = activity;
        filters.dateRange = may;
      });

      test("no selected bike queries every gear within the range and the activity criteria", () {
        expect(filters.stravaQuery(null), StravaActivityQuery(activity: activity, dateRange: may));
      });

      test("a bike with a linked gear queries that gear within the range", () {
        final bike = Bike(name: "Enduro", person: null, stravaGear: "g1");
        expect(filters.stravaQuery(bike), StravaActivityQuery(gearId: "g1", activity: activity, dateRange: may));
      });

      test("a bike without a linked gear still has no query", () {
        final bike = Bike(name: "Hardtail", person: null, stravaGear: null);
        expect(filters.stravaQuery(bike), null);
      });

      test("clearing the range queries every day again", () {
        filters.dateRange = null;
        expect(filters.stravaQuery(null), const StravaActivityQuery(activity: activity));
      });
    });
  });

  group("normalize", () {
    setUp(() {
      filters.toggleBike("b1");
      filters.setup = const SetupFilter(tags: {"race", "wet"}, bookmarkedOnly: true);
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {"service", "fork"});
      filters.layers = const LayerFilter(hidden: {TimelineLayer.tasks});
      filters.activity = const ActivityFilter(distance: NumericRange(min: 10000));
      filters.dateRange = LocalDateRange(start: DateTime(2024, 5), end: DateTime(2024, 5, 31));
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
      expect(filters.activity, const ActivityFilter(distance: NumericRange(min: 10000)));
      expect(filters.dateRange, LocalDateRange(start: DateTime(2024, 5), end: DateTime(2024, 5, 31)));
      expect(changes, 0);
    });
  });
}
