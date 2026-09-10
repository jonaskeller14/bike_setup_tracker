import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The notch marks where the target sat before a delay pushed it out. It only
/// earns its place when a delay actually moved the target, and it has to land
/// on the track exactly where the original target's share of it ends.
void main() {
  const width = 200.0;

  Widget wrap(
    TaskThreshold interval, {
    TaskThreshold? delay,
    double progress = 0.5,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? materialAppTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: TaskProgressBar(
              interval: interval,
              delay: delay,
              progress: progress,
              statusColor: const Color(0xFFEF6C00),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('marks where the original target sat', (tester) async {
    await tester.pumpWidget(wrap(
      const DistanceThreshold(700000),
      delay: const DistanceThreshold(300000),
    ));

    final notch = find.byKey(TaskProgressBar.originalTargetKey);
    expect(notch, findsOneWidget);
    // 700 of the 1000 km total, so 70% along a 200px track.
    expect(tester.getCenter(notch).dx - tester.getTopLeft(find.byType(TaskProgressBar)).dx, closeTo(140, 1.5));
  });

  testWidgets('stays out of the way when nothing moved the target', (tester) async {
    await tester.pumpWidget(wrap(const DistanceThreshold(700000)));
    expect(find.byKey(TaskProgressBar.originalTargetKey), findsNothing);

    await tester.pumpWidget(wrap(const DistanceThreshold(700000), delay: const DistanceThreshold(0)));
    expect(find.byKey(TaskProgressBar.originalTargetKey), findsNothing);
  });

  testWidgets('ignores a delay that never moved the target', (tester) async {
    // A delay of another kind is dropped by totalTarget, so the track is
    // unchanged and a notch would sit at the very end, marking nothing.
    await tester.pumpWidget(wrap(
      const DistanceThreshold(700000),
      delay: const ActivityCountThreshold(5),
    ));

    expect(find.byKey(TaskProgressBar.originalTargetKey), findsNothing);
  });

  testWidgets('leaves a deadline track unmarked', (tester) async {
    // A deadline's track is a fixed lead window, not a run up to the target,
    // so there is no point on it that stands for the original deadline.
    await tester.pumpWidget(wrap(
      DateTimeThreshold(DateTime.utc(2026, 3, 12)),
      delay: const DurationThreshold(Duration(days: 3)),
    ));

    expect(find.byKey(TaskProgressBar.originalTargetKey), findsNothing);
  });

  testWidgets('renders overdue and light/dark without overflowing', (tester) async {
    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      await tester.pumpWidget(wrap(
        const ActivityCountThreshold(10),
        delay: const ActivityCountThreshold(12),
        progress: 1.4,
        theme: theme,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(TaskProgressBar.originalTargetKey), findsOneWidget);
    }
  });
}
