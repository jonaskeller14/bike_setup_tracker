import 'package:bike_setup_tracker/pages/details/setup_details_page.dart';
import 'package:bike_setup_tracker/widgets/sheets/compare_setups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'compare_setups_harness.dart';

void main() {
  late CompareSetupsHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await CompareSetupsHarness.create();
  });

  tearDown(() => harness.dispose());

  Future<void> pumpDetails(WidgetTester tester, String setupId) async {
    await tester.pumpWidget(
      harness.wrap(
        SetupDetailsPageContent.sheet(
          setup: harness.repository.setups[setupId]!,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('sheet actions use an overflow menu and retain Close', (tester) async {
    final setup = harness.setup(id: 'only', name: 'Only', local: DateTime(2026, 8, 1, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpDetails(tester, setup.id);

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byTooltip('Setup actions'));
    await settle(tester);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Restore'), findsNothing);
    expect(find.text('Compare'), findsNothing);
  });

  testWidgets('historical details offers strict eligible Compare above the sheet', (tester) async {
    final historical = harness.setup(id: 'old', name: 'Old', local: DateTime(2026, 8, 1, 10));
    final current = harness.setup(id: 'current', name: 'Current', local: DateTime(2026, 8, 2, 10));
    await harness.addSetups(tester, [historical, current]);
    await harness.reload(tester);
    await pumpDetails(tester, historical.id);

    await tester.tap(find.byTooltip('Setup actions'));
    await settle(tester);
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    await tester.tap(find.text('Compare'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(CompareSetups), matching: find.byIcon(Icons.close)));
    await settle(tester);
    expect(find.byType(SetupDetailsPageContent), findsOneWidget);
  });
}
