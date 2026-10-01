import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/layer_filter.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
import 'package:bike_setup_tracker/models/filters/setup_filter.dart';
import 'package:bike_setup_tracker/models/filters/task_rule_filter.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/filter_controller.dart';
import 'package:bike_setup_tracker/utils/filter_actions.dart';
import 'package:bike_setup_tracker/widgets/sheets/filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppRepository extends Mock implements AppRepository {}

const timelineSections = {FilterSection.bike, FilterSection.setups, FilterSection.timelineLayers};
const mapSections = {FilterSection.bike, FilterSection.setups, FilterSection.mapLayers};
const taskSections = {FilterSection.bike, FilterSection.taskPriority, FilterSection.taskTags};
const activitySections = {FilterSection.bike, FilterSection.activity};

const activityRanges = ActivityFilter(distance: NumericRange(min: 10000), elevationGain: NumericRange(max: 500));

void main() {
  late MockAppRepository repository;
  late FilterController filters;
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockAppRepository();
    filters = FilterController(onChanged: () {});
    when(() => repository.filters).thenReturn(filters);
    when(() => repository.bikes).thenReturn({'b1': Bike(id: 'b1', name: 'Bike 1', person: 'P1')});
    settings = AppSettings();
  });

  tearDown(() {
    settings.dispose();
  });

  Set<FilterSection> enabled(Set<FilterSection> sections, {bool stravaActive = false}) =>
      FilterActions.enabledSections(sections, appSettings: settings, stravaActive: stravaActive);

  Set<TimelineLayer> layers(Set<FilterSection> sections, {bool stravaActive = false}) =>
      FilterActions.availableLayers(sections, appSettings: settings, stravaActive: stravaActive);

  bool isFiltered(Set<FilterSection> sections, {bool stravaActive = false}) => FilterActions.isFiltered(
    sections,
    appRepository: repository,
    appSettings: settings,
    stravaActive: stravaActive,
  );

  List<String> labels(Set<FilterSection> sections, {bool stravaActive = false}) => FilterActions.activeLabels(
    sections,
    appRepository: repository,
    appSettings: settings,
    stravaActive: stravaActive,
  );

  group('enabledSections', () {
    test('always offers the bike section', () {
      expect(enabled(const {FilterSection.bike}), {FilterSection.bike});
    });

    test('never offers a section the page did not name', () {
      settings.enableSetupTags = true;
      settings.enableTaskTags = true;
      settings.enableRating = true;

      expect(enabled(const {FilterSection.bike}, stravaActive: true), {FilterSection.bike});
    });

    test('offers the setup section for tags or bookmarks', () {
      const sections = {FilterSection.setups};
      expect(enabled(sections), isEmpty);

      settings.enableSetupTags = true;
      expect(enabled(sections), sections);

      settings.enableSetupTags = false;
      settings.enableSetupBookmark = true;
      expect(enabled(sections), sections);
    });

    test('task sections follow their own flags', () {
      settings.enableTaskPriority = false;
      expect(enabled(taskSections), {FilterSection.bike});

      settings.enableTaskPriority = true;
      expect(enabled(taskSections), {FilterSection.bike, FilterSection.taskPriority});

      settings.enableTaskTags = true;
      expect(enabled(taskSections), taskSections);
    });

    test('offers the activity section only while Strava is active', () {
      // Tests run in debug mode, the only mode that offers the section so far.
      const sections = {FilterSection.activity};
      expect(enabled(sections), isEmpty);
      expect(enabled(sections, stravaActive: true), sections);
    });

    test('map layers need a layer besides setups', () {
      const sections = {FilterSection.mapLayers};
      settings.enableTask = true;
      settings.enableInstallationTimeline = true;
      expect(enabled(sections), isEmpty);

      expect(enabled(sections, stravaActive: true), sections);

      settings.enableRating = true;
      expect(enabled(sections), sections);
    });

    test('timeline layers also count tasks and installations', () {
      const sections = {FilterSection.timelineLayers};
      expect(enabled(sections), isEmpty);

      settings.enableTask = true;
      expect(enabled(sections), sections);

      settings.enableTask = false;
      settings.enableInstallationTimeline = true;
      expect(enabled(sections), sections);
    });
  });

  group('availableLayers', () {
    test('is empty without a layer section', () {
      settings.enableRating = true;
      expect(layers(taskSections, stravaActive: true), isEmpty);
    });

    test('is empty while the layer section is not offered', () {
      expect(layers(mapSections), isEmpty);
      expect(layers(timelineSections), isEmpty);
    });

    test('lists the map layers whose feature is on', () {
      settings.enableTask = true;
      settings.enableInstallationTimeline = true;
      expect(layers(mapSections, stravaActive: true), [TimelineLayer.setups, TimelineLayer.activities]);

      settings.enableRating = true;
      expect(layers(mapSections), [TimelineLayer.setups, TimelineLayer.ratingEntries]);
    });

    test('lists the timeline layers whose feature is on, in display order', () {
      settings.enableTask = true;
      expect(layers(timelineSections), [TimelineLayer.setups, TimelineLayer.tasks]);

      settings.enableInstallationTimeline = true;
      settings.enableRating = true;
      expect(layers(timelineSections, stravaActive: true), TimelineLayer.values);
    });
  });

  group('isFiltered and activeLabels', () {
    test('report nothing while no criterion is set', () {
      settings.enableSetupTags = true;
      settings.enableTask = true;

      expect(isFiltered(timelineSections), false);
      expect(labels(timelineSections), isEmpty);
    });

    test('name the selected bike', () {
      filters.toggleBike('b1');

      expect(isFiltered(const {FilterSection.bike}), true);
      expect(labels(const {FilterSection.bike}), ['Bike 1']);
    });

    test('ignore the bike on a page without a bike section', () {
      filters.toggleBike('b1');
      settings.enableSetupTags = true;

      expect(isFiltered(const {FilterSection.setups}), false);
    });

    test('count setup criteria only while their feature is on', () {
      filters.setup = const SetupFilter(tags: {'race'}, bookmarkedOnly: true);
      expect(isFiltered(timelineSections), false);

      settings.enableSetupBookmark = true;
      expect(labels(timelineSections), ['Bookmarked']);

      settings.enableSetupTags = true;
      expect(labels(timelineSections), ['Bookmarked', '1 Tag']);
    });

    test('ignore setup criteria on a page without a setup section', () {
      settings.enableSetupTags = true;
      settings.enableSetupBookmark = true;
      filters.setup = const SetupFilter(tags: {'race'}, bookmarkedOnly: true);

      expect(isFiltered(taskSections), false);
    });

    test('count task criteria only while their feature is on', () {
      settings.enableTaskPriority = false;
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {'service', 'fork'});
      expect(isFiltered(taskSections), false);

      settings.enableTaskPriority = true;
      expect(labels(taskSections), ['1 Priority']);

      settings.enableTaskTags = true;
      expect(labels(taskSections), ['2 Tags', '1 Priority']);
    });

    test('pluralise the priority count', () {
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high, TaskPriority.critical});

      expect(labels(taskSections), ['2 Priorities']);
    });

    test('add setup and task tags into one count', () {
      settings.enableSetupTags = true;
      settings.enableTaskTags = true;
      filters.setup = const SetupFilter(tags: {'race'});
      filters.taskRule = TaskRuleFilter(tags: const {'service', 'fork'});

      expect(labels(const {FilterSection.setups, FilterSection.taskTags}), ['3 Tags']);
    });

    test('count a hidden layer the page offers', () {
      settings.enableTask = true;
      filters.layers = const LayerFilter(hidden: {TimelineLayer.tasks});

      expect(labels(timelineSections), ['1 Filter']);
    });

    test('ignore a hidden layer whose feature is off', () {
      settings.enableTask = true;
      filters.layers = const LayerFilter(
        hidden: {TimelineLayer.installations, TimelineLayer.ratingEntries, TimelineLayer.activities},
      );

      expect(isFiltered(timelineSections), false);
    });

    test('ignore hidden layers while the layer section is not offered', () {
      filters.layers = const LayerFilter(hidden: {TimelineLayer.setups});

      expect(isFiltered(mapSections), false);
      expect(isFiltered(timelineSections), false);
    });

    test('ignore a hidden layer only another section offers', () {
      settings.enableRating = true;
      settings.enableTask = true;
      filters.layers = const LayerFilter(hidden: {TimelineLayer.tasks});

      expect(isFiltered(mapSections), false);
      expect(isFiltered(timelineSections), true);
    });

    test('label an activity range in the user\'s units', () {
      filters.activity = const ActivityFilter(
        distance: NumericRange(min: 10000, max: 50000),
        elevationGain: NumericRange(min: 500),
      );

      expect(labels(activitySections, stravaActive: true), ['10–50 km', '≥ 500 m']);

      settings.distanceUnit = 'mi';
      settings.altitudeUnit = 'ft';
      expect(labels(activitySections, stravaActive: true), ['6.2–31.1 mi', '≥ 1,640.4 ft']);
    });

    test('count one activity range without the other', () {
      filters.activity = const ActivityFilter(elevationGain: NumericRange(max: 1000));

      expect(labels(activitySections, stravaActive: true), ['≤ 1,000 m']);
    });

    test('ignore the activity ranges while Strava is not active', () {
      filters.activity = const ActivityFilter(distance: NumericRange(min: 10000));

      expect(isFiltered(activitySections), false);
      expect(isFiltered(activitySections, stravaActive: true), true);
    });

    test('ignore the activity ranges on a page without an activity section', () {
      filters.activity = const ActivityFilter(distance: NumericRange(min: 10000));

      expect(isFiltered(taskSections, stravaActive: true), false);
    });

    test('order the labels like the chip', () {
      settings.enableSetupTags = true;
      settings.enableSetupBookmark = true;
      settings.enableTaskTags = true;
      settings.enableTask = true;
      filters.toggleBike('b1');
      filters.setup = const SetupFilter(tags: {'race'}, bookmarkedOnly: true);
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {'service'});
      filters.layers = const LayerFilter(hidden: {TimelineLayer.setups});
      filters.activity = const ActivityFilter(
        distance: NumericRange(max: 50000),
        elevationGain: NumericRange(min: 500),
      );

      expect(labels(FilterSection.values.toSet()), ['Bike 1', 'Bookmarked', '2 Tags', '1 Priority', '1 Filter']);
      expect(labels(FilterSection.values.toSet(), stravaActive: true), [
        'Bike 1',
        'Bookmarked',
        '2 Tags',
        '1 Priority',
        '≤ 50 km',
        '≥ 500 m',
        '1 Filter',
      ]);
    });
  });

  group('rangeLabel', () {
    String? label(NumericRange range) =>
        FilterActions.rangeLabel(range, unit: 'km', fromMeters: AppSettings.convertDistanceFromMeters);

    test('is null while the range is open at both ends', () {
      expect(label(const NumericRange()), null);
    });

    test('names a min only, a max only and both', () {
      expect(label(const NumericRange(min: 10000)), '≥ 10 km');
      expect(label(const NumericRange(max: 50000)), '≤ 50 km');
      expect(label(const NumericRange(min: 10000, max: 50000)), '10–50 km');
    });

    test('keeps a bound of zero and at most one decimal', () {
      expect(label(const NumericRange(min: 0, max: 12340)), '0–12.3 km');
    });
  });

  group('clear', () {
    Future<void> clear(WidgetTester tester, Set<FilterSection> sections) async {
      await tester.pumpWidget(
        ListenableProvider<AppRepository>.value(
          value: repository,
          child: const SizedBox.shrink(),
        ),
      );
      FilterActions.clear(tester.element(find.byType(SizedBox)), sections);
    }

    void setEverything() {
      filters.toggleBike('b1');
      filters.setup = const SetupFilter(tags: {'race'}, bookmarkedOnly: true);
      filters.taskRule = TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {'service'});
      filters.layers = const LayerFilter(hidden: {TimelineLayer.setups, TimelineLayer.tasks});
      filters.activity = activityRanges;
    }

    testWidgets('resets the timeline sections and leaves the task and activity criteria', (tester) async {
      setEverything();
      await clear(tester, timelineSections);

      expect(filters.bikeId, null);
      expect(filters.setup, const SetupFilter());
      expect(filters.layers, const LayerFilter());
      expect(filters.taskRule, TaskRuleFilter(priorities: const {TaskPriority.high}, tags: const {'service'}));
      expect(filters.activity, activityRanges);
    });

    testWidgets('resets both activity ranges and nothing else', (tester) async {
      setEverything();
      await clear(tester, const {FilterSection.activity});

      expect(filters.activity, const ActivityFilter());
      expect(filters.bikeId, 'b1');
      expect(filters.setup, const SetupFilter(tags: {'race'}, bookmarkedOnly: true));
      expect(filters.layers, const LayerFilter(hidden: {TimelineLayer.setups, TimelineLayer.tasks}));
    });

    testWidgets('resets the map layers and keeps a timeline-only layer hidden', (tester) async {
      setEverything();
      await clear(tester, mapSections);

      expect(filters.bikeId, null);
      expect(filters.setup, const SetupFilter());
      expect(filters.layers, const LayerFilter(hidden: {TimelineLayer.tasks}));
    });

    testWidgets('resets only the task narrowing', (tester) async {
      setEverything();
      await clear(tester, const {FilterSection.taskPriority, FilterSection.taskTags});

      expect(filters.taskRule, TaskRuleFilter());
      expect(filters.bikeId, 'b1');
      expect(filters.setup, const SetupFilter(tags: {'race'}, bookmarkedOnly: true));
      expect(filters.layers, const LayerFilter(hidden: {TimelineLayer.setups, TimelineLayer.tasks}));
    });

    testWidgets('resets one task section without the other', (tester) async {
      setEverything();
      await clear(tester, const {FilterSection.taskTags});

      expect(filters.taskRule, TaskRuleFilter(priorities: const {TaskPriority.high}));
    });

    testWidgets('resets a criterion whose feature is off', (tester) async {
      // Every flag is off, so no section is offered: the criteria still apply
      // to the lists and must not survive a reset.
      settings.enableTaskPriority = false;
      setEverything();
      await clear(tester, FilterSection.values.toSet());

      expect(filters.bikeId, null);
      expect(filters.setup, const SetupFilter());
      expect(filters.taskRule, TaskRuleFilter());
      expect(filters.layers, const LayerFilter());
      expect(filters.activity, const ActivityFilter());
    });

    testWidgets('notifies once per changed filter object', (tester) async {
      var changes = 0;
      filters = FilterController(onChanged: () => changes++);
      when(() => repository.filters).thenReturn(filters);
      setEverything();
      changes = 0;

      await clear(tester, FilterSection.values.toSet());
      expect(changes, 5);

      await clear(tester, FilterSection.values.toSet());
      expect(changes, 5);
    });
  });
}
