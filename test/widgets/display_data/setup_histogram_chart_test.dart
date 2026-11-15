import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/component_slot.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/table_column.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_histogram_chart.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../goldens/support/localized_test_app.dart';

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

  Setup setup(String id, {double? pressureValue, List<String>? modeValue}) => Setup(
    id: id,
    datetime: DateTime.utc(2024, 1, 1),
    datetimeLocal: DateTime(2024, 1, 1),
    tags: const {},
    bike: 'bike',
    person: null,
    bikeAdjustmentValues: {
      if (pressureValue != null) 'pressure': NumericalValue(pressureValue),
      if (modeValue != null) 'mode': CategoricalValue(modeValue),
    },
    personAdjustmentValues: const {},
  );

  final setups = [
    setup('s1', pressureValue: 60, modeValue: ['Open']),
    setup('s2', pressureValue: 70, modeValue: ['Trail']),
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
    ComponentSlot? Function(Setup setup, TableColumn column)? slotFor,
    ThemeData? theme,
  }) {
    return localizedTestApp(
      theme: theme ?? materialAppTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SetupHistogramChart(
            activeColumns: columns,
            setups: setupList ?? setups,
            setupActivityCounts: activityCounts,
            hasAnyActivity: hasAnyActivity,
            activityCountsLoaded: loaded,
            activityCountsFailed: failed,
            selectedHistogramColumn: selected,
            valueFor: (setup, column) => setup.bikeAdjustmentValues[(column as ComponentAdjustmentColumn).adjustmentId],
            adjustmentFor: (column) => column is ComponentAdjustmentColumn ? adjustments[column.adjustmentId] : null,
            slotFor: slotFor,
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
        harness(columns: [ComponentAdjustmentColumn('note', active: true)]),
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

  group('slot stacking', () {
    const frontTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront);
    const rearTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelRear);
    ComponentSlot rotated(Setup setup, TableColumn column) => setup.id == 's1' ? frontTire : rearTire;
    List<List<double>> stackHeights(WidgetTester tester) => tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups
        .map((group) => group.barRods.single.rodStackItems.map((item) => item.toY - item.fromY).toList())
        .toList();

    testWidgets('splits bars by slot and names the slots', (tester) async {
      await tester.pumpWidget(harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], slotFor: rotated));

      expect(barValues(tester), [5, 1]);
      expect(stackHeights(tester), [
        [3, 2], // 60: s1 front, s3 rear
        [1], // 70: s2 rear
      ]);
      expect(find.text('Tire (Front Wheel)'), findsOneWidget);
      expect(find.text('Tire (Rear Wheel)'), findsOneWidget);
    });

    testWidgets('stays unstacked when every setup shares one slot', (tester) async {
      await tester.pumpWidget(
        harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], slotFor: (_, _) => rearTire),
      );

      expect(stackHeights(tester), [isEmpty, isEmpty]);
      expect(find.text('Tire (Rear Wheel)'), findsNothing);
    });

    testWidgets('lists the slot counts in the bar tooltip', (tester) async {
      await tester.pumpWidget(harness(columns: [ComponentAdjustmentColumn('pressure', active: true)], slotFor: rotated));
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final group = chart.data.barGroups.first;
      final item = chart.data.barTouchData.touchTooltipData.getTooltipItem(group, 0, group.barRods.single, 0)!;

      expect(
        item.children!.map((span) => span.toPlainText()).join(),
        '5 activities\nTire (Front Wheel): 3 activities\nTire (Rear Wheel): 2 activities',
      );
    });
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
          slotFor: (setup, _) => ComponentSlot(
            type: ComponentType.tire,
            parentType: setup.id == 's1' ? ComponentType.wheelFront : ComponentType.wheelRear,
          ),
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(barValues(tester).sum, 6);
  });
}
