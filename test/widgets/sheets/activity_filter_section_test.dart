import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
import 'package:bike_setup_tracker/models/strava/activity_bounds.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/repositories/filter_controller.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/filter/activity_filter_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifies like the real repository, so the section rebuilds on a filter change.
class _FakeAppRepository extends ChangeNotifier implements AppRepository {
  @override
  late final FilterController filters = FilterController(onChanged: notifyListeners);

  @override
  ActivityBounds activityBounds = ActivityBounds.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAppRepository repository;
  late FilterController filters;
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _FakeAppRepository();
    filters = repository.filters;
    settings = AppSettings();
  });

  tearDown(() {
    settings.dispose();
    repository.dispose();
  });

  Future<void> pumpSection(WidgetTester tester, {ThemeData? theme}) => tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider<AppRepository>.value(value: repository),
      ],
      child: MaterialApp(
        theme: theme ?? materialAppTheme,
        home: const Scaffold(body: ActivityFilterSection()),
      ),
    ),
  );

  RangeSlider distanceSlider(WidgetTester tester) => tester.widget(find.byType(RangeSlider).first);
  RangeSlider elevationSlider(WidgetTester tester) => tester.widget(find.byType(RangeSlider).last);

  Future<void> release(WidgetTester tester, RangeSlider slider, RangeValues values) async {
    slider.onChanged!(values);
    slider.onChangeEnd!(values);
    await tester.pump();
  }

  testWidgets('offers both ranges, open by default', (tester) async {
    await pumpSection(tester);

    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Elevation Gain'), findsOneWidget);
    expect(find.text('Any'), findsNWidgets(2));
    expect(distanceSlider(tester).values, const RangeValues(0, 150));
    expect(elevationSlider(tester).values, const RangeValues(0, 3000));
  });

  testWidgets('shows the stored ranges', (tester) async {
    filters.activity = const ActivityFilter(
      distance: NumericRange(min: 10000, max: 50000),
      elevationGain: NumericRange(min: 500),
    );
    await pumpSection(tester);

    expect(distanceSlider(tester).values, const RangeValues(10, 50));
    expect(elevationSlider(tester).values, const RangeValues(500, 3000));
    expect(find.text('10–50 km'), findsOneWidget);
    expect(find.text('≥ 500 m'), findsOneWidget);

    final rightEdge = tester.getTopRight(find.byType(ActivityFilterSection)).dx;
    expect(tester.getTopRight(find.text('10–50 km')).dx, rightEdge);
    expect(tester.getTopRight(find.text('≥ 500 m')).dx, rightEdge);
  });

  testWidgets('a drag previews the range and writes it on release only', (tester) async {
    await pumpSection(tester);

    distanceSlider(tester).onChanged!(const RangeValues(10, 50));
    await tester.pump();
    expect(find.text('10–50 km'), findsOneWidget);
    expect(filters.activity, const ActivityFilter());

    distanceSlider(tester).onChangeEnd!(const RangeValues(10, 50));
    await tester.pump();
    expect(filters.activity.distance.min, closeTo(10000, 1e-6));
    expect(filters.activity.distance.max, closeTo(50000, 1e-6));
    expect(filters.activity.elevationGain, const NumericRange());
    expect(find.text('10–50 km'), findsOneWidget);
    expect(distanceSlider(tester).values, const RangeValues(10, 50));
  });

  testWidgets('either end of the slider leaves that side open', (tester) async {
    await pumpSection(tester);

    await release(tester, distanceSlider(tester), const RangeValues(0, 50));
    expect(filters.activity.distance.min, null);
    expect(filters.activity.distance.max, closeTo(50000, 1e-6));
    expect(find.text('≤ 50 km'), findsOneWidget);

    await release(tester, distanceSlider(tester), const RangeValues(10, 150));
    expect(filters.activity.distance.min, closeTo(10000, 1e-6));
    expect(filters.activity.distance.max, null);
    expect(find.text('≥ 10 km'), findsOneWidget);

    await release(tester, distanceSlider(tester), const RangeValues(0, 150));
    expect(filters.activity, const ActivityFilter());
    expect(find.text('Any'), findsNWidgets(2));
  });

  testWidgets('the elevation gain slider keeps the distance range', (tester) async {
    filters.activity = const ActivityFilter(distance: NumericRange(min: 10000));
    await pumpSection(tester);

    await release(tester, elevationSlider(tester), const RangeValues(500, 1500));

    expect(filters.activity.distance, const NumericRange(min: 10000));
    expect(filters.activity.elevationGain.min, closeTo(500, 1e-6));
    expect(filters.activity.elevationGain.max, closeTo(1500, 1e-6));
    expect(find.text('500–1,500 m'), findsOneWidget);
  });

  testWidgets('works in miles and feet and stores metres', (tester) async {
    settings.distanceUnit = 'mi';
    settings.altitudeUnit = 'ft';
    await pumpSection(tester);

    expect(distanceSlider(tester).max, 100);
    expect(elevationSlider(tester).max, 10000);

    await release(tester, distanceSlider(tester), const RangeValues(5, 100));
    await release(tester, elevationSlider(tester), const RangeValues(0, 2000));

    expect(filters.activity.distance.min, closeTo(8046.72, 1e-6));
    expect(filters.activity.distance.max, null);
    expect(filters.activity.elevationGain.min, null);
    expect(filters.activity.elevationGain.max, closeTo(609.6, 1e-6));
    expect(find.text('≥ 5 mi'), findsOneWidget);
    expect(find.text('≤ 2,000 ft'), findsOneWidget);
    expect(distanceSlider(tester).values, const RangeValues(5, 100));
    expect(elevationSlider(tester).values, const RangeValues(0, 2000));
  });

  testWidgets('the tracks end just past the longest and highest activity', (tester) async {
    repository.activityBounds = const ActivityBounds(maxDistance: 143000, maxElevationGain: 1840);
    await pumpSection(tester);

    expect(distanceSlider(tester).values, const RangeValues(0, 145));
    expect(distanceSlider(tester).divisions, 29);
    expect(elevationSlider(tester).values, const RangeValues(0, 1850));
    expect(elevationSlider(tester).divisions, 37);

    await release(tester, distanceSlider(tester), const RangeValues(10, 145));
    expect(filters.activity.distance.min, closeTo(10000, 1e-6));
    expect(filters.activity.distance.max, null);
  });

  testWidgets('a stored bound beyond the track keeps its label', (tester) async {
    repository.activityBounds = const ActivityBounds(maxDistance: 40000, maxElevationGain: 1000);
    filters.activity = const ActivityFilter(distance: NumericRange(max: 80000));
    await pumpSection(tester);

    expect(distanceSlider(tester).values, const RangeValues(0, 40));
    expect(find.text('≤ 80 km'), findsOneWidget);
  });

  testWidgets('a tap on the track sets the nearer bound', (tester) async {
    await pumpSection(tester);

    final track = tester.getRect(find.byType(RangeSlider).first);
    await tester.tapAt(Offset(track.left + track.width * 0.25, track.center.dy));
    await tester.pumpAndSettle();

    expect(filters.activity.distance.min, isNotNull);
    expect(filters.activity.distance.max, null);
    expect(filters.activity.elevationGain, const NumericRange());
  });

  for (final theme in [materialAppTheme, materialAppDarkTheme]) {
    testWidgets('fits a narrow screen with long labels (${theme.brightness.name})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(280, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      settings.distanceUnit = 'mi';
      settings.altitudeUnit = 'ft';
      filters.activity = const ActivityFilter(
        distance: NumericRange(min: 12345, max: 123456),
        elevationGain: NumericRange(min: 457.2, max: 2895.6),
      );

      await pumpSection(tester, theme: theme);

      expect(tester.takeException(), null);
      expect(find.text('1,500–9,500 ft'), findsOneWidget);
    });
  }
}
