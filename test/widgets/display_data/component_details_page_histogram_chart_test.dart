import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/table_column.dart';
import 'package:bike_setup_tracker/widgets/display_data/component_details_page_histogram_chart.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pressure = NumericalAdjustment(
    id: 'pressure',
    name: 'Air pressure',
    notes: null,
    unit: null,
    min: 40,
    max: 140,
  );
  final mode = CategoricalAdjustment(
    id: 'mode',
    name: 'Compression mode',
    notes: null,
    unit: null,
    options: const {'Open', 'Trail', 'Firm'},
  );
  final note = TextAdjustment(id: 'note', name: 'Note', notes: null, unit: null);
  final adjustments = {
    for (final a in [pressure, mode, note]) a.id: a,
  };

  Setup setup(String id, {double? pressureValue, String? modeValue}) => Setup(
    id: id,
    datetime: DateTime.utc(2024, 1, 1),
    datetimeLocal: DateTime(2024, 1, 1),
    tags: const {},
    bike: 'bike',
    person: null,
    bikeAdjustmentValues: {
      'pressure': ?pressureValue,
      'mode': ?modeValue,
    },
    personAdjustmentValues: const {},
  );

  final setups = [
    setup('s1', pressureValue: 60, modeValue: 'Open'),
    setup('s2', pressureValue: 70, modeValue: 'Trail'),
    setup('s3', pressureValue: 60),
  ];
  const counts = {'s1': 3, 's2': 1, 's3': 2};

  Widget harness({
    required List<TableColumn> columns,
    List<Setup>? setupList,
    Map<String, int> activityCounts = counts,
    bool hasAnyActivity = true,
    bool loaded = true,
    bool failed = false,
    TableColumn? selected,
    ValueChanged<TableColumn>? onSelected,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? materialAppTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ComponentDetailsPageHistogramChart(
            activeColumns: columns,
            setups: setupList ?? setups,
            setupActivityCounts: activityCounts,
            hasAnyActivity: hasAnyActivity,
            activityCountsLoaded: loaded,
            activityCountsFailed: failed,
            selectedHistogramColumn: selected,
            valueFor: (setup, column) => setup.bikeAdjustmentValues[(column as ComponentAdjustmentColumn).adjustmentId],
            adjustmentFor: (column) => column is ComponentAdjustmentColumn ? adjustments[column.adjustmentId] : null,
            columnLabel: (column) => adjustments[(column as ComponentAdjustmentColumn).adjustmentId]!.name,
            onSelectedColumnChanged: onSelected ?? (_) {},
            onColumnRemoved: (_) {},
          ),
        ),
      ),
    );
  }

  List<double> barValues(WidgetTester tester) =>
      tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.map((g) => g.barRods.single.toY).toList();

  group('placeholders', () {
    testWidgets('no chartable adjustment columns', (tester) async {
      await tester.pumpWidget(
        harness(columns: [ComponentAdjustmentColumn('note', active: true), RatingScoreColumn(active: true)]),
      );
      expect(find.text('No adjustments selected'), findsOneWidget);
    });

    testWidgets('no setups', (tester) async {
      await tester.pumpWidget(harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], setupList: []));
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('no activities synced', (tester) async {
      await tester.pumpWidget(
        harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], hasAnyActivity: false),
      );
      expect(find.text('No activities'), findsOneWidget);
    });

    testWidgets('loading activity counts', (tester) async {
      await tester.pumpWidget(harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], loaded: false));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('failed activity counts', (tester) async {
      await tester.pumpWidget(harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], failed: true));
      expect(find.text('Could not load activities'), findsOneWidget);
    });

    testWidgets('no activities linked to setups', (tester) async {
      await tester.pumpWidget(
        harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], activityCounts: const {}),
      );
      expect(find.text('No activities linked'), findsOneWidget);
      // Legend stays visible so another adjustment can still be picked.
      expect(find.text('Air pressure'), findsOneWidget);
    });
  });

  testWidgets('shows the first chartable column by default, weighted by activity count', (tester) async {
    await tester.pumpWidget(
      harness(
        columns: [
          ComponentAdjustmentColumn('note', active: true),
          ComponentAdjustmentColumn('pressure', active: true),
          ComponentAdjustmentColumn('mode', active: true),
        ],
      ),
    );
    expect(barValues(tester), [5, 1]); // 60: s1 + s3, 70: s2
    expect(find.text('Note'), findsNothing);
  });

  testWidgets('shows the selected column and ignores setups without a value', (tester) async {
    final modeColumn = ComponentAdjustmentColumn('mode', active: true);
    await tester.pumpWidget(
      harness(columns: [ComponentAdjustmentColumn('pressure', active: true), modeColumn], selected: modeColumn),
    );
    expect(barValues(tester), [3, 1]); // Open: s1, Trail: s2
  });

  testWidgets('tapping a legend entry selects that column', (tester) async {
    final pressureColumn = ComponentAdjustmentColumn('pressure', active: true);
    final modeColumn = ComponentAdjustmentColumn('mode', active: true);
    TableColumn? picked;
    await tester.pumpWidget(harness(columns: [pressureColumn, modeColumn], onSelected: (c) => picked = c));

    await tester.tap(find.text('Air pressure'));
    expect(picked, isNull, reason: 'already selected');
    await tester.tap(find.text('Compression mode'));
    expect(picked, modeColumn);
  });

  testWidgets('renders without overflow in light and dark on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      await tester.pumpWidget(
        harness(
          theme: theme,
          columns: [
            ComponentAdjustmentColumn('pressure', active: true),
            ComponentAdjustmentColumn('mode', active: true),
          ],
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(barValues(tester).sum, 6);
  });
}
