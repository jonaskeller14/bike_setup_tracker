import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_data/adjustment_activity_histogram_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdjustmentActivityHistogram histogram({bool binned = false}) => AdjustmentActivityHistogram(
    adjustmentId: 'pressure',
    bars: [
      AdjustmentActivityHistogramBar.exact(
        label: 'An exceptionally long category name',
        activityCount: 12345,
        exactValue: CategoricalValue(const ['long']),
      ),
      if (binned)
        const AdjustmentActivityHistogramBar.range(
          label: '20–30 psi',
          activityCount: 7,
          lowerBound: 20,
          upperBound: 30,
          includesUpperBound: true,
        )
      else
        const AdjustmentActivityHistogramBar.exact(label: '30 psi', activityCount: 7, exactValue: NumericalValue(30)),
    ],
    isBinned: binned,
  );

  Widget harness(
    AdjustmentActivityHistogram data, {
    ThemeData? theme,
    double width = 240,
    double textScale = 1,
    AdjustmentValue? currentValue,
  }) {
    return MaterialApp(
      theme: theme ?? materialAppTheme,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: AdjustmentActivityHistogramChart(histogram: data, currentValue: currentValue),
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
        'Activity distribution. An exceptionally long category name: 12345 activities, 20–30 psi: 7 activities',
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

    expect(tooltipItem?.text, 'An exceptionally long category name\n12345 activities');
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
        'Activity distribution. An exceptionally long category name: 12345 activities, 30 psi: 7 activities (current)',
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

  testWidgets('empty histogram renders no chart', (tester) async {
    await tester.pumpWidget(harness(AdjustmentActivityHistogram.empty('empty')));
    expect(find.byType(BarChart), findsNothing);
  });
}
