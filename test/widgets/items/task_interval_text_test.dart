import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A delay is spent on the next completion, so it is folded into the interval
/// number ("Every 10+1 rides") but keeps its own colour. Only a delay of the
/// interval's own kind can be folded — anything else falls back to a chip.
void main() {
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings();
  });

  tearDown(() => appSettings.dispose());

  Widget wrap(
    TaskThreshold interval, {
    TaskThreshold? delay,
    bool repeat = true,
    ThemeData? theme,
    double width = 400,
  }) {
    return ChangeNotifierProvider.value(
      value: appSettings,
      child: MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: TaskIntervalText(interval: interval, delay: delay, repeat: repeat),
            ),
          ),
        ),
      ),
    );
  }

  /// The colour the '+1' span is painted in, or null when no such span exists.
  Color? delaySpanColor(WidgetTester tester, String delayText) {
    Color? found;
    tester.widget<Text>(find.byType(Text)).textSpan!.visitChildren((span) {
      if (span is TextSpan && span.text == delayText) found = span.style?.color;
      return true;
    });
    return found;
  }

  testWidgets('folds a same-typed delay into the interval and colours it', (tester) async {
    await tester.pumpWidget(wrap(const ActivityCountThreshold(10), delay: const ActivityCountThreshold(1)));

    expect(find.text('Every 10+1 rides', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.history), findsNothing);
    expect(delaySpanColor(tester, '+1'), ValueHighlightColors.light.changed);
  });

  testWidgets('pluralises on interval and delay combined', (tester) async {
    await tester.pumpWidget(wrap(const ActivityCountThreshold(1), delay: const ActivityCountThreshold(1)));
    expect(find.text('Every 1+1 rides', findRichText: true), findsOneWidget);

    await tester.pumpWidget(wrap(const ActivityCountThreshold(1)));
    expect(find.text('Every 1 ride'), findsOneWidget);
  });

  testWidgets('keeps the "After" prefix for a one-off rule', (tester) async {
    await tester.pumpWidget(wrap(
      const DurationThreshold(Duration(days: 30)),
      delay: const DurationThreshold(Duration(days: 1)),
      repeat: false,
    ));

    expect(find.text('After 30+1 days', findRichText: true), findsOneWidget);
  });

  testWidgets('prints the shared unit once, in the configured unit', (tester) async {
    appSettings.distanceUnit = 'mi';
    await tester.pumpWidget(wrap(const DistanceThreshold(1609.344), delay: const DistanceThreshold(1609.344)));

    expect(find.text('Every 1+1 mi', findRichText: true), findsOneWidget);
  });

  testWidgets('ignores a delay of zero', (tester) async {
    await tester.pumpWidget(wrap(const ActivityCountThreshold(10), delay: const ActivityCountThreshold(0)));

    expect(find.text('Every 10 rides'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsNothing);
  });

  testWidgets('falls back to a separate chip for a deadline interval', (tester) async {
    await tester.pumpWidget(wrap(
      DateTimeThreshold(DateTime.utc(2026, 3, 12, 12)),
      delay: const DurationThreshold(Duration(days: 3)),
    ));

    expect(find.textContaining('2026-03-12'), findsOneWidget);
    expect(find.text('+3 days'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('falls back to a separate chip when the kinds differ', (tester) async {
    await tester.pumpWidget(wrap(const DistanceThreshold(100000), delay: const ActivityCountThreshold(2)));

    expect(find.text('Every 100 km'), findsOneWidget);
    expect(find.text('+2 rides'), findsOneWidget);
  });

  testWidgets('survives a narrow card in light and dark', (tester) async {
    for (final theme in [materialAppTheme, materialAppDarkTheme]) {
      await tester.pumpWidget(wrap(
        const DistanceThreshold(1234567),
        delay: const DistanceThreshold(98765),
        theme: theme,
        width: 90,
      ));
      expect(tester.takeException(), isNull);
    }
  });
}
