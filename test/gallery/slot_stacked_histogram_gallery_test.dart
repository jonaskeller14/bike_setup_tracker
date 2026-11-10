// Renders every state of the slot-stacked activity histograms to PNGs in
// build/gallery/slot_stacked_histogram/ (git-ignored): SetupHistogramChart as
// on ComponentDetailsPage, and AdjustmentActivityHistogramChart framed like the
// adjustment tooltip. Skipped by default (see dart_test.yaml); run it on demand
// with:
//
//   flutter test test/gallery/slot_stacked_histogram_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; every
// state is also written on its own.
//
// Names that start with "my" are user data (adjustment names and options).
// Slot labels ("Tire (Rear Wheel)", "Not installed"), axis labels and counts
// come from the UI. Slots are resolved from real installation timelines, the
// way ComponentDetailsPage and SetupActivityAnalysisService do it.
//
// Besides the pictures, the second test checks that no state traps the user:
// the column legend still switches and removes columns, the slot legend does
// not swallow taps, and every stacked bar adds up to its total.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/services/component_slot.dart';
import 'package:bike_setup_tracker/utils/adjustment_activity_histogram_grouping.dart';
import 'package:bike_setup_tracker/utils/table_column.dart';
import 'package:bike_setup_tracker/widgets/display_data/adjustment_activity_histogram_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/histogram_slot_stack.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_histogram_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _pageWidth = 400.0;
const _tooltipWidth = 344.0;
const _cellKey = ValueKey('cell');

const _bike1 = 'bike-1';
const _bike2 = 'bike-2';

final _pressure = NumericalAdjustment(id: 'pressure', name: 'myPressure', notes: null, unit: const CustomUnit('bar'));
final _insert = CategoricalAdjustment(
  id: 'insert',
  name: 'myInsert',
  notes: null,
  unit: null,
  options: const {'myOption1', 'myOption2', 'myOption3'},
  multiSelect: true,
);
final _weight = NumericalAdjustment(id: 'weight', name: 'myWeight', notes: null, unit: const CustomUnit('kg'));
final _adjustments = {
  for (final a in [_pressure, _insert, _weight]) a.id: a,
};

Installation _onBike(String bikeId, int day) =>
    BikeInstallation(bikeId: bikeId, dateTimeUTC: DateTime.utc(2026, 1, day), dateTimeLocal: DateTime(2026, 1, day));

Installation _onPart(String componentId, int day) => ComponentInstallation(
  parentComponentId: componentId,
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation _uninstalled(int day) =>
    Uninstallation(dateTimeUTC: DateTime.utc(2026, 1, day), dateTimeLocal: DateTime(2026, 1, day));

/// The garage every state is drawn from.
///
/// - myTire1: on myBike1 directly (day 1), on the front wheel (day 10), on the
///   rear wheel (day 20), not installed (day 30), on myBike2 directly (day 40).
/// - myTire2: moves through seven slots (every 3 days from day 1), then is not
///   installed from day 22.
/// - myTire3: on the front wheel the whole time.
/// - myTire4: never installed.
final _hierarchy = () {
  Component part(String id, String name, ComponentType type, List<Installation> installations) =>
      Component(id: id, name: name, componentType: type, installations: installations, adjustments: const []);
  final components = [
    part('wheel-front', 'myWheelFront1', ComponentType.wheelFront, [Installation.sinceBeginning(parent: _bike1)]),
    part('wheel-rear', 'myWheelRear1', ComponentType.wheelRear, [Installation.sinceBeginning(parent: _bike1)]),
    part('fork', 'myFork1', ComponentType.fork, [Installation.sinceBeginning(parent: _bike1)]),
    part('bb', 'myBottomBracket1', ComponentType.bottomBracket, [Installation.sinceBeginning(parent: _bike1)]),
    part('cable', 'myCable1', ComponentType.shiftInnerCable, [Installation.sinceBeginning(parent: _bike1)]),
    part('calliper', 'myCalliper1', ComponentType.brakeCalliper, [Installation.sinceBeginning(parent: _bike1)]),
    part('tire-1', 'myTire1', ComponentType.tire, [
      _onBike(_bike1, 1),
      _onPart('wheel-front', 10),
      _onPart('wheel-rear', 20),
      _uninstalled(30),
      _onBike(_bike2, 40),
    ]),
    part('tire-2', 'myTire2', ComponentType.tire, [
      _onBike(_bike1, 1),
      _onPart('wheel-front', 4),
      _onPart('wheel-rear', 7),
      _onPart('fork', 10),
      _onPart('bb', 13),
      _onPart('cable', 16),
      _onPart('calliper', 19),
      _uninstalled(22),
    ]),
    part('tire-3', 'myTire3', ComponentType.tire, [
      Installation.componentSinceBeginning(parentComponentId: 'wheel-front'),
    ]),
    part('tire-4', 'myTire4', ComponentType.tire, [_uninstalled(1)]),
  ];
  return ComponentHierarchyResolver({for (final c in components) c.id: c});
}();

typedef _Ride = (Setup setup, int activities);

int _setupCounter = 0;

_Ride _ride(int day, int activities, {String bike = _bike1, double? pressure, List<String>? insert, double? weight}) {
  final at = DateTime.utc(2026, 1, day, 12);
  final setup = Setup(
    id: 'setup-${_setupCounter++}',
    datetime: at,
    datetimeLocal: at.toLocal(),
    tags: const {},
    bike: bike,
    person: null,
    bikeAdjustmentValues: {
      if (pressure != null) _pressure.id: NumericalValue(pressure),
      if (insert != null) _insert.id: CategoricalValue(insert),
    },
    personAdjustmentValues: {if (weight != null) _weight.id: NumericalValue(weight)},
  );
  return (setup, activities);
}

/// Bike direct 2.0 · 1.9, front 1.8 · 1.9, rear 2.1 · 1.9: the 1.9 bar mixes
/// all three slots, the others hold one each.
List<_Ride> _threeSlots({int Function(int activities)? weight}) {
  int w(int activities) => weight?.call(activities) ?? activities;
  return [
    _ride(2, w(3), pressure: 2.0, insert: ['myOption1'], weight: 72),
    _ride(4, w(2), pressure: 1.9, weight: 72),
    _ride(12, w(4), pressure: 1.8, insert: ['myOption1', 'myOption2'], weight: 74),
    _ride(14, w(1), pressure: 1.9, weight: 74),
    _ride(22, w(5), pressure: 2.1, insert: ['myOption2', 'myOption3'], weight: 75),
    _ride(24, w(2), pressure: 1.9, weight: 75),
  ];
}

final _rides = <String, List<_Ride>>{
  'three': _threeSlots(),
  'not-installed': [..._threeSlots(), _ride(32, 2, pressure: 2.0)],
  'other-bike': [..._threeSlots(), _ride(42, 3, bike: _bike2, pressure: 2.0)],
  'single': [_ride(2, 3, pressure: 1.8), _ride(12, 2, pressure: 1.9), _ride(22, 4, pressure: 1.8)],
  'never': [_ride(2, 3, pressure: 1.8), _ride(12, 2, pressure: 1.9)],
  'single-plus-not-installed': [
    _ride(2, 3, pressure: 1.8),
    _ride(12, 2, pressure: 1.9),
    _ride(14, 2, bike: _bike2, pressure: 1.9),
  ],
  'binned': [
    for (final (index, pressure) in [1.60, 1.80, 2.00, 2.20, 2.40].indexed)
      _ride(2 + index, 1 + index % 3, pressure: pressure),
    for (final (index, pressure) in [1.65, 1.85, 2.05, 2.25, 2.35].indexed)
      _ride(11 + index, 1 + index % 2, pressure: pressure),
    for (final (index, pressure) in [1.70, 1.90, 2.10, 2.30].indexed) _ride(21 + index, 2, pressure: pressure),
  ],
  'zero-rear': _threeSlots(weight: (activities) => activities)
    ..[4] = _ride(22, 0, pressure: 2.1)
    ..[5] = _ride(24, 0, pressure: 1.9),
  'empty': _threeSlots(weight: (_) => 0),
  'many': [
    _ride(2, 2, pressure: 2.0),
    _ride(5, 3, pressure: 1.8),
    _ride(8, 4, pressure: 2.1),
    _ride(11, 1, pressure: 2.0),
    _ride(14, 2, pressure: 1.9),
    _ride(17, 1, pressure: 2.0),
    _ride(20, 3, pressure: 1.9),
    _ride(24, 2, pressure: 2.0),
  ],
};

class _Case {
  final String slug;
  final String title;
  final String rides;
  final String tireId;
  final Adjustment adjustment;
  final double width;
  final double textScale;
  final Locale locale;
  final int? touchBar;

  /// Tooltip only.
  final AdjustmentValue? current;
  final AdjustmentValue? recommended;

  const _Case(
    this.slug,
    this.title, {
    required this.rides,
    this.tireId = 'tire-1',
    required this.adjustment,
    required this.width,
    this.textScale = 1,
    this.locale = const Locale('en'),
    this.touchBar,
    this.current,
    this.recommended,
  });

  ComponentSlot? slotOf(Setup setup) => slotOnBikeAt(
    _hierarchy,
    _hierarchy.components[tireId]!,
    bikeId: setup.bike,
    atUTC: setup.datetimeLocal.toUtc(),
  );
}

final _pageCases = [
  _Case('three', '3 slots: bike, front wheel, rear wheel', rides: 'three', adjustment: _pressure, width: _pageWidth),
  _Case(
    'not_installed',
    '3 slots + not installed (value after uninstall)',
    rides: 'not-installed',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case(
    'other_bike',
    'Moved to myBike2: "Tire" on both bikes merges',
    rides: 'other-bike',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case(
    'touched',
    'Touched 1.9 bar bar: tooltip lists slot counts',
    rides: 'three',
    adjustment: _pressure,
    width: _pageWidth,
    touchBar: 1,
  ),
  _Case(
    'single',
    'Single slot, never moved (unstacked)',
    rides: 'single',
    tireId: 'tire-3',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case(
    'never_installed',
    'Never installed: all not installed (unstacked)',
    rides: 'never',
    tireId: 'tire-4',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case(
    'single_plus_not_installed',
    'One slot + not installed (value on myBike2)',
    rides: 'single-plus-not-installed',
    tireId: 'tire-3',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case('binned', 'Binned: 14 distinct pressures', rides: 'binned', adjustment: _pressure, width: _pageWidth),
  _Case(
    'zero_rear',
    'Rear wheel setups have 0 activities: slot left out',
    rides: 'zero-rear',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case('empty', 'All setups 0 activities (empty state)', rides: 'empty', adjustment: _pressure, width: _pageWidth),
  _Case('categorical', 'Categorical multi-select column', rides: 'three', adjustment: _insert, width: _pageWidth),
  _Case(
    'rider',
    'Rider attribute column (never stacked)',
    rides: 'three',
    adjustment: _weight,
    width: _pageWidth,
  ),
  _Case(
    'many',
    'Many slots: 7 + not installed',
    rides: 'many',
    tireId: 'tire-2',
    adjustment: _pressure,
    width: _pageWidth,
  ),
  _Case(
    'narrow',
    'Many slots, 320 px, text 2x',
    rides: 'many',
    tireId: 'tire-2',
    adjustment: _pressure,
    width: 320,
    textScale: 2,
  ),
  _Case(
    'german',
    'German labels',
    rides: 'not-installed',
    adjustment: _pressure,
    width: _pageWidth,
    locale: const Locale('de'),
  ),
];

final _tooltipCases = [
  _Case('three', '3 slots', rides: 'three', adjustment: _pressure, width: _tooltipWidth),
  _Case(
    'current',
    '3 slots, current 1.9 bar (others dimmed)',
    rides: 'three',
    adjustment: _pressure,
    width: _tooltipWidth,
    current: const NumericalValue(1.9),
  ),
  _Case(
    'current_recommended',
    'Current 1.8, recommended 2.1',
    rides: 'three',
    adjustment: _pressure,
    width: _tooltipWidth,
    current: const NumericalValue(1.8),
    recommended: const NumericalValue(2.1),
  ),
  _Case(
    'same_bar',
    'Current = recommended (2.0)',
    rides: 'three',
    adjustment: _pressure,
    width: _tooltipWidth,
    current: const NumericalValue(2.0),
    recommended: const NumericalValue(2.0),
  ),
  _Case(
    'not_installed',
    '3 slots + not installed',
    rides: 'not-installed',
    adjustment: _pressure,
    width: _tooltipWidth,
  ),
  _Case(
    'binned',
    'Binned, current 1.95 in a bin',
    rides: 'binned',
    adjustment: _pressure,
    width: _tooltipWidth,
    current: const NumericalValue(1.95),
  ),
  _Case(
    'categorical',
    'Categorical, current spans 2 bars',
    rides: 'three',
    adjustment: _insert,
    width: _tooltipWidth,
    current: CategoricalValue(const ['myOption1', 'myOption2']),
  ),
  _Case(
    'single',
    'Single slot (unstacked)',
    rides: 'single',
    tireId: 'tire-3',
    adjustment: _pressure,
    width: _tooltipWidth,
  ),
  _Case(
    'many',
    'Many slots: 7 + not installed',
    rides: 'many',
    tireId: 'tire-2',
    adjustment: _pressure,
    width: _tooltipWidth,
  ),
  _Case(
    'narrow',
    'Many slots, 160 px, text 2x',
    rides: 'many',
    tireId: 'tire-2',
    adjustment: _pressure,
    width: 184,
    textScale: 2,
  ),
  _Case(
    'empty',
    'All 0 activities: chart renders nothing',
    rides: 'empty',
    adjustment: _pressure,
    width: _tooltipWidth,
  ),
  _Case('touched', 'Touched 1.9 bar bar', rides: 'three', adjustment: _pressure, width: _tooltipWidth, touchBar: 1),
  _Case(
    'german',
    'German labels',
    rides: 'not-installed',
    adjustment: _pressure,
    width: _tooltipWidth,
    locale: const Locale('de'),
  ),
];

String _adjustmentIdOf(TableColumn column) => switch (column) {
  ComponentAdjustmentColumn(:final adjustmentId) || PersonAttributeColumn(:final adjustmentId) => adjustmentId,
  _ => throw ArgumentError(column),
};

/// The histogram the tooltip gets: same input as SetupActivityAnalysisService.
AdjustmentActivityHistogram _histogramOf(_Case c) => groupAdjustmentActivityHistogram(
  adjustment: c.adjustment,
  values: [
    for (final (setup, activities) in _rides[c.rides]!)
      if (setup.bikeAdjustmentValues[c.adjustment.id] case final value?)
        AdjustmentActivityValue(setupId: setup.id, value: value, activityCount: activities, slot: c.slotOf(setup)),
  ],
);

Widget _app(ThemeData theme, _Case c, Widget child, {Key? key}) => RepaintBoundary(
  key: key,
  child: localizedTestApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: c.locale,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(c.textScale)),
      child: app!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _cellKey,
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(8),
              // The page chart's Column fills its height; an unbounded
              // parent shrinks it to its content.
              child: SizedBox(
                width: c.width,
                child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Widget _pageChart(
  _Case c, {
  ValueChanged<TableColumn>? onSelected,
  ValueChanged<TableColumn>? onRemoved,
}) {
  final rides = _rides[c.rides]!;
  final columns = [
    ComponentAdjustmentColumn(_pressure.id, active: true),
    ComponentAdjustmentColumn(_insert.id, active: true),
    if (c.adjustment == _weight) PersonAttributeColumn(_weight.id, active: true),
  ];
  return SetupHistogramChart(
    activeColumns: columns,
    setups: [for (final (setup, _) in rides) setup],
    setupActivityCounts: {for (final (setup, activities) in rides) setup.id: activities},
    hasAnyActivity: true,
    activityCountsLoaded: true,
    activityCountsFailed: false,
    selectedHistogramColumn: columns.firstWhere((column) => _adjustmentIdOf(column) == c.adjustment.id),
    valueFor: (setup, column) => switch (column) {
      ComponentAdjustmentColumn(:final adjustmentId) => setup.bikeAdjustmentValues[adjustmentId],
      PersonAttributeColumn(:final adjustmentId) => setup.personAdjustmentValues[adjustmentId],
      _ => null,
    },
    adjustmentFor: (column) => _adjustments[_adjustmentIdOf(column)],
    // Same rule as ComponentDetailsPage: only the component's own adjustments stack.
    slotFor: (setup, column) => column is ComponentAdjustmentColumn ? c.slotOf(setup) : null,
    columnLabel: (column) => _adjustments[_adjustmentIdOf(column)]!.name,
    onSelectedColumnChanged: onSelected ?? (_) {},
    onColumnRemoved: onRemoved ?? (_) {},
  );
}

/// The adjustment tooltip's frame (see AdjustmentIconNameNotes).
Widget _tooltipFrame(ThemeData theme, _Case c) => Container(
  decoration: BoxDecoration(
    color: theme.colorScheme.onSecondaryContainer,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [BoxShadow(color: theme.colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
  ),
  padding: const EdgeInsets.all(12),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        c.adjustment.name,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: AdjustmentActivityHistogramChart(
          histogram: _histogramOf(c),
          currentValue: c.current,
          guideValue: c.recommended,
        ),
      ),
    ],
  ),
);

/// Holds a finger on bar [index]; fl_chart spaces bars evenly over the
/// drawing area (`spaceAround`), which starts after the left titles.
Future<TestGesture?> _touch(
  WidgetTester tester,
  int? index, {
  required double leftInset,
  required double bottomInset,
}) async {
  if (index == null) return null;
  final chart = tester.widget<BarChart>(find.byType(BarChart));
  final rect = tester.getRect(find.byType(BarChart));
  final drawWidth = rect.width - leftInset;
  final x = rect.left + leftInset + drawWidth * (index + 0.5) / chart.data.barGroups.length;
  final gesture = await tester.startGesture(Offset(x, rect.bottom - bottomInset - 4));
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('slot_stacked_histogram'));

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(_pageWidth + 40, 1200);
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      for (final (index, c) in _pageCases.indexed) {
        await tester.pumpWidget(_app(theme, c, _pageChart(c), key: ValueKey('page-$index')));
        await tester.pumpAndSettle();
        final gesture = await _touch(tester, c.touchBar, leftInset: 40, bottomInset: 56);
        await session.add('page_${c.slug}', 'Page · ${c.title}', tester.renderObject(find.byKey(_cellKey)));
        await gesture?.up();
      }

      for (final (index, c) in _tooltipCases.indexed) {
        await tester.pumpWidget(_app(theme, c, _tooltipFrame(theme, c), key: ValueKey('tooltip-$index')));
        await tester.pumpAndSettle();
        final gesture = await _touch(tester, c.touchBar, leftInset: 46, bottomInset: 54);
        await session.add('tooltip_${c.slug}', 'Tooltip · ${c.title}', tester.renderObject(find.byKey(_cellKey)));
        await gesture?.up();
      }

      await session.finish();
    });
  }

  testWidgets('every page state keeps the column legend usable and adds up', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_pageWidth + 40, 1200);

    for (final (index, c) in _pageCases.indexed) {
      TableColumn? selected;
      TableColumn? removed;
      await tester.pumpWidget(
        _app(
          galleryThemes.first.$2,
          c,
          _pageChart(c, onSelected: (column) => selected = column, onRemoved: (column) => removed = column),
          key: ValueKey('check-$index'),
        ),
      );
      await tester.pumpAndSettle();

      final slotLabels = find.descendant(of: find.byType(HistogramSlotLegend), matching: find.byType(Text));
      for (final label in slotLabels.evaluate().toList()) {
        await tester.tap(find.byWidget(label.widget));
      }
      await tester.pump();
      expect(selected, isNull, reason: '"${c.title}": the slot legend must not change the column');

      final other = c.adjustment == _pressure ? _insert : _pressure;
      await tester.tap(find.text(other.name));
      await tester.pump();
      expect(_adjustmentIdOf(selected!), other.id, reason: '"${c.title}": cannot switch to ${other.name}');

      await tester.longPress(find.text(c.adjustment.name));
      await tester.pump();
      expect(_adjustmentIdOf(removed!), c.adjustment.id, reason: '"${c.title}": cannot remove the column');

      final chart = find.byType(BarChart);
      if (chart.evaluate().isEmpty) continue;
      for (final group in tester.widget<BarChart>(chart).data.barGroups) {
        final rod = group.barRods.single;
        if (rod.rodStackItems.isEmpty) continue;
        expect(rod.rodStackItems.last.toY, rod.toY, reason: '"${c.title}": bar ${group.x} parts do not add up');
      }
    }
  });

  test('tooltip histograms resolve the expected slots', () {
    const front = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront);
    const rear = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelRear);
    const direct = ComponentSlot(type: ComponentType.tire);
    String slotsOf(String slug) => _histogramOf(_tooltipCases.firstWhere((c) => c.slug == slug)).slots.toString();

    expect(slotsOf('three'), [direct, front, rear].toString());
    expect(slotsOf('not_installed'), [direct, front, rear, null].toString());
    expect(slotsOf('single'), '[]');
    expect(_histogramOf(_tooltipCases.firstWhere((c) => c.slug == 'many')).slots, hasLength(8));
  });
}
