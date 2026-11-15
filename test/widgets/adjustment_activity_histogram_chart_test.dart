import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/services/component_slot.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_data/adjustment_activity_histogram_chart.dart';
import 'package:bike_setup_tracker/widgets/display_data/histogram_slot_stack.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../goldens/support/localized_test_app.dart';

void main() {
  AdjustmentActivityHistogram histogram({bool binned = false}) => AdjustmentActivityHistogram(
    adjustmentId: 'pressure',
    bars: [
      AdjustmentActivityHistogramBar.exact(
        activityCount: 12345,
        exactValue: CategoricalValue(const ['An exceptionally long category name']),
      ),
      if (binned)
        const AdjustmentActivityHistogramBar.range(
          activityCount: 7,
          lowerBound: 20,
          upperBound: 30,
          includesUpperBound: true,
        )
      else
        const AdjustmentActivityHistogramBar.exact(activityCount: 7, exactValue: NumericalValue(30)),
    ],
    isBinned: binned,
    unitLabel: 'psi',
  );

  Widget harness(
    AdjustmentActivityHistogram data, {
    ThemeData? theme,
    double width = 240,
    double textScale = 1,
    AdjustmentValue? currentValue,
    AdjustmentValue? guideValue,
  }) {
    return localizedTestApp(
      theme: theme ?? materialAppTheme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: AdjustmentActivityHistogramChart(
                histogram: data,
                currentValue: currentValue,
                guideValue: guideValue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders exact and binned labels responsively in light and dark themes', (tester) async {
    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      for (final binned in [false, true]) {
        await tester.pumpWidget(harness(histogram(binned: binned), theme: theme, width: 180, textScale: 2));
        await tester.pump();
        expect(find.byType(BarChart), findsOneWidget);
        expect(find.byKey(const ValueKey('adjustment-activity-histogram')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('exposes the full distribution through semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(histogram(binned: true)));

    expect(
      find.bySemanticsLabel(
        'Activity distribution. An exceptionally long category name psi: 12345 activities, 20 psi–30 psi: 7 activities',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('shows a compact bottom-to-top activity-count axis label', (tester) async {
    await tester.pumpWidget(harness(histogram()));

    expect(find.text('Activity count'), findsOneWidget);
    final axisLabel = tester.widget<SizedBox>(find.byKey(const ValueKey('histogram-activity-count-axis-label')));
    expect(axisLabel.child, isA<Text>());
  });

  testWidgets('touch tooltip retains full exact or bin labels and large counts', (tester) async {
    final data = histogram(binned: true);
    await tester.pumpWidget(harness(data));
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final tooltipItem = chart.data.barTouchData.touchTooltipData.getTooltipItem(
      chart.data.barGroups.first,
      0,
      chart.data.barGroups.first.barRods.first,
      0,
    );

    expect(tooltipItem?.text, 'An exceptionally long category name psi\n12345 activities');
  });

  testWidgets('highlights only the bar of the current value', (tester) async {
    List<Color?> rodColors() => tester
        .widget<BarChart>(find.byType(BarChart))
        .data
        .barGroups
        .map((group) => group.barRods.single.color)
        .toList();
    final full = materialAppTheme.colorScheme.primaryContainer;

    await tester.pumpWidget(harness(histogram()));
    expect(rodColors(), [full, full]);

    await tester.pumpWidget(harness(histogram(), currentValue: const NumericalValue(99)));
    expect(rodColors(), [full, full]);

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(histogram(), currentValue: const NumericalValue(30)));
    expect(rodColors(), [full.withValues(alpha: 0.4), full]);
    expect(
      find.bySemanticsLabel(
        'Activity distribution. An exceptionally long category name psi: 12345 activities, 30 psi: 7 activities (current)',
      ),
      findsOneWidget,
    );
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final tooltipItem = chart.data.barTouchData.touchTooltipData.getTooltipItem(
      chart.data.barGroups.last,
      1,
      chart.data.barGroups.last.barRods.first,
      0,
    );
    expect(tooltipItem?.text, '30 psi\n7 activities\nCurrent value');
    semantics.dispose();
  });

  testWidgets('marks the recommended value with an icon, next to the current one', (tester) async {
    final icon = find.byIcon(Icons.tips_and_updates_outlined);

    await tester.pumpWidget(harness(histogram()));
    expect(icon, findsNothing);

    final semantics = tester.ensureSemantics();
    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      await tester.pumpWidget(
        harness(
          histogram(),
          theme: theme,
          currentValue: CategoricalValue(const ['An exceptionally long category name']),
          guideValue: const NumericalValue(30),
        ),
      );
      await tester.pumpAndSettle();
      expect(icon, findsOneWidget);
    }
    expect(
      find.bySemanticsLabel(
        'Activity distribution. An exceptionally long category name psi: 12345 activities (current), '
        '30 psi: 7 activities (recommended)',
      ),
      findsOneWidget,
    );
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final tooltipItem = chart.data.barTouchData.touchTooltipData.getTooltipItem(
      chart.data.barGroups.last,
      1,
      chart.data.barGroups.last.barRods.first,
      0,
    );
    expect(tooltipItem?.text, '30 psi\n7 activities\nRecommended value');
    semantics.dispose();
  });

  testWidgets('empty histogram renders no chart', (tester) async {
    await tester.pumpWidget(harness(AdjustmentActivityHistogram.empty('empty')));
    expect(find.byType(BarChart), findsNothing);
  });

  group('slot stacking', () {
    const frontTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront);
    const rearTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelRear);
    const stacked = AdjustmentActivityHistogram(
      adjustmentId: 'pressure',
      bars: [
        AdjustmentActivityHistogramBar.exact(
          activityCount: 5,
          exactValue: NumericalValue(1.8),
          segments: [(slot: frontTire, activityCount: 4), (slot: null, activityCount: 1)],
        ),
        AdjustmentActivityHistogramBar.exact(
          activityCount: 3,
          exactValue: NumericalValue(2.1),
          segments: [(slot: rearTire, activityCount: 3)],
        ),
      ],
      isBinned: false,
      unitLabel: 'bar',
      slots: [frontTire, rearTire, null],
    );

    testWidgets('stacks bars by slot with a slot legend', (tester) async {
      await tester.pumpWidget(harness(stacked));
      final rods = tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.map((group) => group.barRods.single);

      expect(rods.map((rod) => rod.rodStackItems.map((item) => (item.fromY, item.toY))), [
        [(0.0, 4.0), (4.0, 5.0)],
        [(0.0, 3.0)],
      ]);
      expect(find.text('Tire (Front Wheel)'), findsOneWidget);
      expect(find.text('Tire (Rear Wheel)'), findsOneWidget);
      expect(find.text('Not installed'), findsOneWidget);
    });

    testWidgets('fills each slot with its own pattern of the bar color', (tester) async {
      await tester.pumpWidget(harness(stacked, currentValue: const NumericalValue(2.1)));
      final colorScheme = materialAppTheme.colorScheme;
      final rods = tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.map((group) => group.barRods.single);
      List<SlotPatternFill> fills(BarChartRodData rod) => [
        for (final item in rod.rodStackItems) item.gradient! as SlotPatternFill,
      ];

      expect(rods.map((rod) => rod.color), everyElement(Colors.transparent), reason: 'fl_chart paints the rod under its parts');
      expect(rods.map((rod) => fills(rod).map((fill) => fill.pattern)), [
        [SlotPattern.solid, SlotPattern.horizontal], // front wheel, not installed
        [SlotPattern.diagonal], // rear wheel
      ]);
      expect(fills(rods.first).map((fill) => fill.fill), everyElement(colorScheme.primaryContainer.withValues(alpha: 0.4)));
      expect(fills(rods.last).single.fill, colorScheme.primaryContainer);
    });

    testWidgets('names the slot counts in tooltip and semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness(stacked));
      final chart = tester.widget<BarChart>(find.byType(BarChart));
      final group = chart.data.barGroups.first;

      expect(
        chart.data.barTouchData.touchTooltipData.getTooltipItem(group, 0, group.barRods.single, 0)?.text,
        '1.8 bar\n5 activities\nTire (Front Wheel): 4 activities\nNot installed: 1 activity',
      );
      expect(
        find.bySemanticsLabel(
          'Activity distribution. 1.8 bar: 5 activities (Tire (Front Wheel): 4 activities, Not installed: 1 activity), '
          '2.1 bar: 3 activities (Tire (Rear Wheel): 3 activities)',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('renders without overflow in light and dark on narrow widths', (tester) async {
      for (final theme in [materialAppTheme, materialAppDarkTheme]) {
        await tester.pumpWidget(harness(stacked, theme: theme, width: 140, textScale: 2));
        expect(find.byType(BarChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
