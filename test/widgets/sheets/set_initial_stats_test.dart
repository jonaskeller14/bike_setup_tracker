import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_initial_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  late AppSettings settings;

  setUp(() => settings = AppSettings());
  tearDown(() => settings.dispose());

  /// Opens the sheet and returns a getter for what it saved.
  Future<ComponentStats? Function()> openSheet(
    WidgetTester tester, {
    ComponentStats initialStats = const ComponentStats(),
  }) async {
    ComponentStats? saved;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: localizedTestApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  saved = await showSetInitialStatsSheet(context: context, initialStats: initialStats),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => saved;
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), text);
    await tester.pump();
  }

  testWidgets('reads a decimal comma in the decimal fields', (tester) async {
    final saved = await openSheet(tester);

    await enter(tester, 'Distance', '12,5');
    await enter(tester, 'Elevation Gain', '100,5');
    await enter(tester, 'Energy', '2,5');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved()?.distance, closeTo(12500, 0.001));
    expect(saved()?.elevationGain, closeTo(100.5, 0.001));
    expect(saved()?.kilojoules, 2.5);
  });

  testWidgets('German values are pre-filled with a decimal comma and survive a save', (tester) async {
    Intl.defaultLocale = 'de';
    addTearDown(() => Intl.defaultLocale = null);

    const stats = ComponentStats(distance: 12500, elevationGain: 100.5, kilojoules: 2.5);
    final saved = await openSheet(tester, initialStats: stats);

    expect(find.widgetWithText(TextFormField, '12,5'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '100,5'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2,5'), findsOneWidget);

    // Save needs a change; the pre-filled fields stay untouched.
    await enter(tester, 'Activities', '3');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved(), const ComponentStats(distance: 12500, elevationGain: 100.5, kilojoules: 2.5, activityCount: 3));
  });

  testWidgets('a stray key keeps the value instead of emptying the field', (tester) async {
    await openSheet(tester);

    await enter(tester, 'Distance', '12,5');
    await enter(tester, 'Distance', '12,5,');
    await enter(tester, 'Activities', '42');
    await enter(tester, 'Activities', '42,');

    expect(find.widgetWithText(TextFormField, '12,5'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '42'), findsOneWidget);
  });
}
