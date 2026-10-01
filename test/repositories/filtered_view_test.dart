import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/filters/local_date_range.dart';
import 'package:bike_setup_tracker/models/filters/setup_filter.dart';
import 'package:bike_setup_tracker/models/filters/task_rule_filter.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating/rating.dart';
import 'package:bike_setup_tracker/models/rating/rating_association.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/filtered_view.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, T> byId<T>(Iterable<T> items, String Function(T) id) => {for (final item in items) id(item): item};

void main() {
  final bikes = byId([
    Bike(id: "b1", name: "Bike 1", person: "p1"),
    Bike(id: "b2", name: "Bike 2", person: "p2"),
  ], (bike) => bike.id);

  final persons = byId([Person(id: "p1", name: "Rider 1"), Person(id: "p2", name: "Rider 2")], (person) => person.id);

  Component component(String id, ComponentType type, List<Installation> installations) =>
      Component(id: id, name: id, componentType: type, installations: installations, adjustments: const []);

  // fork and its damper sit on b1, shock on b2, the wheel was archived, and the
  // seal's parent component is in the trash.
  final components = byId([
    component("fork", ComponentType.fork, [Installation.sinceBeginning(parent: "b1")]),
    component("damper", ComponentType.other, [Installation.componentSinceBeginning(parentComponentId: "fork")]),
    component("shock", ComponentType.shock, [Installation.sinceBeginning(parent: "b2")]),
    component("wheel", ComponentType.other, [
      Installation.sinceBeginning(parent: "b1"),
      Archival(dateTimeUTC: DateTime.utc(2024), dateTimeLocal: DateTime(2024)),
    ]),
    component("seal", ComponentType.other, [Installation.componentSinceBeginning(parentComponentId: "trashed")]),
  ], (component) => component.id);

  FilteredView build({
    String? bikeId,
    Map<String, Component>? rawComponents,
    Map<String, Setup> setups = const {},
    Map<String, RatingEntry> ratingEntries = const {},
    Map<String, Rating> ratings = const {},
    Map<String, TaskRule> taskRules = const {},
    Map<String, TaskEntry> taskEntries = const {},
    SetupFilter setupFilter = const SetupFilter(),
    TaskRuleFilter? taskRuleFilter,
    LocalDateRange? dateRange,
  }) {
    final allComponents = rawComponents ?? components;
    return FilteredView(
      bikes: bikes,
      components: allComponents,
      setups: setups,
      ratingEntries: ratingEntries,
      persons: persons,
      ratings: ratings,
      taskRules: taskRules,
      taskEntries: taskEntries,
      hierarchy: ComponentHierarchyResolver(allComponents, deletedComponentIds: const {"trashed"}),
      bikeId: bikeId,
      dateRange: dateRange,
      setupFilter: setupFilter,
      taskRuleFilter: taskRuleFilter ?? TaskRuleFilter(),
    );
  }

  group("bikes and persons", () {
    test("without a bike the raw maps pass through", () {
      final view = build();
      expect(view.bikes, same(bikes));
      expect(view.persons, same(persons));
    });

    test("a selected bike keeps only that bike and its rider", () {
      final view = build(bikeId: "b2");
      expect(view.bikes.keys, ["b2"]);
      expect(view.persons.keys, ["p2"]);
    });
  });

  group("components", () {
    test("archived and deleted components are excluded even without a bike", () {
      expect(build().components.keys, ["fork", "damper", "shock"]);
    });

    test("a selected bike keeps its components, including nested ones", () {
      expect(build(bikeId: "b1").components.keys, ["fork", "damper"]);
      expect(build(bikeId: "b2").components.keys, ["shock"]);
    });
  });

  group("setups", () {
    Setup setup(String id, String bike, {Set<String> tags = const {}, bool isBookmarked = false}) => Setup(
      id: id,
      tags: tags,
      isBookmarked: isBookmarked,
      datetime: DateTime.utc(2024),
      datetimeLocal: DateTime(2024),
      bike: bike,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );
    final setups = byId([
      setup("s1", "b1", tags: {"race"}, isBookmarked: true),
      setup("s2", "b1", tags: {"race"}),
      setup("s3", "b1"),
      setup("s4", "b2", tags: {"race"}, isBookmarked: true),
    ], (setup) => setup.id);

    test("without criteria every setup is kept", () {
      expect(build(setups: setups).setups.keys, ["s1", "s2", "s3", "s4"]);
    });

    test("bike scope", () {
      expect(build(setups: setups, bikeId: "b1").setups.keys, ["s1", "s2", "s3"]);
    });

    test("bike scope combines with tags and bookmarks", () {
      final view = build(
        setups: setups,
        bikeId: "b1",
        setupFilter: const SetupFilter(tags: {"race"}, bookmarkedOnly: true),
      );
      expect(view.setups.keys, ["s1"]);
    });
  });

  test("rating entries follow the bike scope", () {
    RatingEntry entry(String id, String bike) =>
        RatingEntry(id: id, bike: bike, setupId: "s1", dateTimeUTC: DateTime.utc(2024), dateTimeLocal: DateTime(2024));
    final ratingEntries = byId([entry("e1", "b1"), entry("e2", "b2")], (entry) => entry.id);

    expect(build(ratingEntries: ratingEntries).ratingEntries.keys, ["e1", "e2"]);
    expect(build(ratingEntries: ratingEntries, bikeId: "b1").ratingEntries.keys, ["e1"]);
  });

  group("ratings", () {
    Rating rating(String id, RatingAssociation association) => Rating(id: id, name: id, association: association);
    final ratings = byId([
      rating("global", const GlobalRatingAssociation()),
      rating("otherPerson", const PersonRatingAssociation("p2")),
      rating("bike1", const BikeRatingAssociation("b1")),
      rating("bike2", const BikeRatingAssociation("b2")),
      rating("fork", const ComponentRatingAssociation("fork")),
      rating("shock", const ComponentRatingAssociation("shock")),
      rating("wheel", const ComponentRatingAssociation("wheel")),
      rating("forkType", ComponentTypeRatingAssociation(ComponentType.fork.toString())),
      rating("shockType", ComponentTypeRatingAssociation(ComponentType.shock.toString())),
    ], (rating) => rating.id);

    test("without a bike every rating is kept", () {
      expect(build(ratings: ratings).ratings.keys, ratings.keys);
    });

    test("a selected bike narrows bike, component and component type ratings", () {
      expect(build(ratings: ratings, bikeId: "b1").ratings.keys, [
        "global",
        "otherPerson",
        "bike1",
        "fork",
        "forkType",
      ]);
    });
  });

  group("task rules", () {
    TaskRule rule(
      String id, {
      TaskAssociation association = const GeneralTaskAssociation(),
      TaskPriority priority = TaskPriority.medium,
      Set<String> tags = const {},
    }) => TaskRule(id: id, name: id, association: association, priority: priority, tags: tags);
    final taskRules = byId([
      rule("general", priority: TaskPriority.high, tags: {"service"}),
      rule("bike1", association: const BikeTaskAssociation("b1"), tags: {"service"}),
      rule("bike2", association: const BikeTaskAssociation("b2")),
      rule("fork", association: const ComponentTaskAssociation("fork"), priority: TaskPriority.high),
      rule("shock", association: const ComponentTaskAssociation("shock")),
      rule("wheel", association: const ComponentTaskAssociation("wheel")),
      rule("seal", association: const ComponentTaskAssociation("seal")),
      rule("unknown", association: const ComponentTaskAssociation("missing")),
    ], (rule) => rule.id);

    TaskEntry entry(String id, String taskRule) =>
        TaskEntry(id: id, name: id, dateTimeUTC: DateTime.utc(2024), dateTimeLocal: DateTime(2024), taskRule: taskRule);
    final taskEntries = byId([
      entry("generalDone", "general"),
      entry("forkDone", "fork"),
      entry("shockDone", "shock"),
    ], (entry) => entry.id);

    test("rules of archived, deleted and unknown components are out of scope", () {
      final view = build(taskRules: taskRules);
      expect(view.taskRulesInScope.keys, ["general", "bike1", "bike2", "fork", "shock"]);
      expect(view.taskRules.keys, view.taskRulesInScope.keys);
    });

    test("a selected bike keeps general rules and the bike's own", () {
      expect(build(taskRules: taskRules, bikeId: "b1").taskRulesInScope.keys, ["general", "bike1", "fork"]);
    });

    test("priority and tags narrow taskRules but not taskRulesInScope", () {
      final byPriority = build(
        taskRules: taskRules,
        bikeId: "b1",
        taskRuleFilter: TaskRuleFilter(priorities: const {TaskPriority.high}),
      );
      expect(byPriority.taskRulesInScope.keys, ["general", "bike1", "fork"]);
      expect(byPriority.taskRules.keys, ["general", "fork"]);

      final byTag = build(
        taskRules: taskRules,
        bikeId: "b1",
        taskRuleFilter: TaskRuleFilter(tags: const {"service"}),
      );
      expect(byTag.taskRules.keys, ["general", "bike1"]);
    });

    test("open rules are the filtered rules without an entry", () {
      expect(build(taskRules: taskRules, taskEntries: taskEntries).openTaskRules.keys, ["bike1", "bike2"]);
      expect(build(taskRules: taskRules, taskEntries: taskEntries, bikeId: "b1").openTaskRules.keys, ["bike1"]);
    });

    test("task entries follow their rules", () {
      expect(build(taskRules: taskRules, taskEntries: taskEntries).taskEntries.keys, [
        "generalDone",
        "forkDone",
        "shockDone",
      ]);
      expect(build(taskRules: taskRules, taskEntries: taskEntries, bikeId: "b1").taskEntries.keys, [
        "generalDone",
        "forkDone",
      ]);

      final byTag = build(
        taskRules: taskRules,
        taskEntries: taskEntries,
        taskRuleFilter: TaskRuleFilter(tags: const {"service"}),
      );
      expect(byTag.taskEntries.keys, ["generalDone"]);
    });
  });

  group("installations", () {
    // The mover went from b1 to b2 and was then taken off; the spare was added
    // to b1 later on.
    final moving = byId([
      component("mover", ComponentType.other, [
        Installation.sinceBeginning(parent: "b1"),
        Installation(parent: "b2", id: "toB2", dateTimeUTC: DateTime.utc(2024), dateTimeLocal: DateTime(2024)),
        Uninstallation(id: "off", dateTimeUTC: DateTime.utc(2024, 6), dateTimeLocal: DateTime(2024, 6)),
      ]),
      component("spare", ComponentType.other, [
        Installation(parent: "b1", id: "added", dateTimeUTC: DateTime.utc(2024, 3), dateTimeLocal: DateTime(2024, 3)),
      ]),
    ], (component) => component.id);

    List<String> ids(FilteredView view) => view.installations.map((resolved) => resolved.installation.id).toList();

    test("since-beginning installations are skipped and origins resolved", () {
      final view = build(rawComponents: moving);
      expect(ids(view), ["toB2", "off", "added"]);

      final [toB2, off, added] = view.installations;
      expect((toB2.originParent, toB2.isInitial), ("b1", false));
      expect((off.originParent, off.isInitial), ("b2", false));
      expect((added.originParent, added.isInitial), (null, true));
    });

    test("a selected bike matches as origin or as target", () {
      expect(ids(build(rawComponents: moving, bikeId: "b1")), ["toB2", "added"]);
      expect(ids(build(rawComponents: moving, bikeId: "b2")), ["toB2", "off"]);
    });
  });

  group("date range", () {
    // May 10th to 12th. Every entry kind has one entry just outside and one
    // just inside each end, named after where it falls.
    final range = LocalDateRange(start: DateTime(2024, 5, 10), end: DateTime(2024, 5, 12));
    final moments = {
      "before": DateTime(2024, 5, 9, 23, 59),
      "first": DateTime(2024, 5, 10),
      "last": DateTime(2024, 5, 12, 23, 59),
      "after": DateTime(2024, 5, 13),
    };

    Setup setup(String id, DateTime local, {String bike = "b1", DateTime? utc}) => Setup(
      id: id,
      tags: const {},
      datetime: utc ?? local.toUtc(),
      datetimeLocal: local,
      bike: bike,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );

    final setups = {for (final MapEntry(:key, :value) in moments.entries) key: setup(key, value)};
    final ratingEntries = {
      for (final MapEntry(:key, :value) in moments.entries)
        key: RatingEntry(id: key, bike: "b1", setupId: "first", dateTimeUTC: value.toUtc(), dateTimeLocal: value),
    };
    final taskRules = byId([
      TaskRule(id: "done", name: "done", tags: const {}),
      TaskRule(id: "open", name: "open", tags: const {}),
    ], (rule) => rule.id);
    final taskEntries = {
      for (final MapEntry(:key, :value) in moments.entries)
        key: TaskEntry(id: key, name: key, dateTimeUTC: value.toUtc(), dateTimeLocal: value, taskRule: "done"),
    };
    // The mover swaps between the two bikes at every moment.
    final moving = byId([
      component("mover", ComponentType.other, [
        Installation.sinceBeginning(parent: "b1"),
        for (final (index, MapEntry(:key, :value)) in moments.entries.indexed)
          Installation(parent: index.isEven ? "b2" : "b1", id: key, dateTimeUTC: value.toUtc(), dateTimeLocal: value),
      ]),
    ], (component) => component.id);

    FilteredView view({LocalDateRange? dateRange, String? bikeId}) => build(
      rawComponents: moving,
      setups: setups,
      ratingEntries: ratingEntries,
      taskRules: taskRules,
      taskEntries: taskEntries,
      dateRange: dateRange,
      bikeId: bikeId,
    );

    List<String> installationIds(FilteredView view) =>
        view.installations.map((resolved) => resolved.installation.id).toList();

    test("without a range every entry is kept", () {
      final unfiltered = view();

      expect(unfiltered.setups.keys, moments.keys);
      expect(unfiltered.ratingEntries.keys, moments.keys);
      expect(unfiltered.taskEntries.keys, moments.keys);
      expect(installationIds(unfiltered), moments.keys);
    });

    test("narrows every timeline entry kind to the days of the range, both ends inclusive", () {
      final filtered = view(dateRange: range);

      expect(filtered.setups.keys, ["first", "last"]);
      expect(filtered.ratingEntries.keys, ["first", "last"]);
      expect(filtered.taskEntries.keys, ["first", "last"]);
      expect(installationIds(filtered), ["first", "last"]);
    });

    test("an installation in range keeps the origin it had before the range", () {
      final first = view(dateRange: range).installations.first;

      expect((first.installation.parent, first.originParent, first.isInitial), ("b1", "b2", false));
    });

    test("compares the local day, not the UTC instant", () {
      // Recorded late on the 12th in a time zone behind UTC, and early on the
      // 10th in one ahead of it.
      final floating = byId([
        setup("lateEvening", DateTime(2024, 5, 12, 22), utc: DateTime.utc(2024, 5, 13, 5)),
        setup("earlyMorning", DateTime(2024, 5, 10, 2), utc: DateTime.utc(2024, 5, 9, 16)),
        setup("utcInRangeOnly", DateTime(2024, 5, 13, 1), utc: DateTime.utc(2024, 5, 12, 23)),
      ], (setup) => setup.id);

      expect(build(setups: floating, dateRange: range).setups.keys, ["lateEvening", "earlyMorning"]);
    });

    test("combines with the bike scope", () {
      final mixed = {...setups, "otherBike": setup("otherBike", DateTime(2024, 5, 11), bike: "b2")};

      expect(build(setups: mixed, dateRange: range).setups.keys, ["first", "last", "otherBike"]);
      expect(build(setups: mixed, dateRange: range, bikeId: "b1").setups.keys, ["first", "last"]);
      expect(installationIds(view(dateRange: range, bikeId: "b1")), ["first", "last"]);
    });

    test("does not narrow task rules, and a rule whose entries are hidden stays done", () {
      final outside = view(dateRange: LocalDateRange(start: DateTime(2020), end: DateTime(2020, 12, 31)));

      expect(outside.taskEntries, isEmpty);
      expect(outside.taskRulesInScope.keys, ["done", "open"]);
      expect(outside.taskRules.keys, ["done", "open"]);
      expect(outside.openTaskRules.keys, ["open"]);
    });
  });

  test("a result is computed once per snapshot", () {
    final view = build(bikeId: "b1");
    expect(view.components, same(view.components));
    expect(view.installations, same(view.installations));
  });
}
