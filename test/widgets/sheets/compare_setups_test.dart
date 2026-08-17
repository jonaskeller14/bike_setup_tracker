import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/compare_setups/setup_comparison_row.dart';
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

  Future<(String, String)> seedPair(WidgetTester tester, {String? name}) async {
    final older = harness.setup(
      id: 'older',
      name: name ?? 'Baseline',
      local: DateTime(2026, 8, 1, 10),
      values: {
        CompareSetupsHarness.changedAdjustmentId: 2,
        CompareSetupsHarness.unchangedAdjustmentId: 80,
      },
    );
    final newer = harness.setup(
      id: 'newer',
      name: name ?? 'Candidate',
      local: DateTime(2026, 8, 2, 10),
      values: {
        CompareSetupsHarness.changedAdjustmentId: 4,
        CompareSetupsHarness.unchangedAdjustmentId: 80,
      },
    );
    await harness.addSetups(tester, [older, newer]);
    await harness.reload(tester);
    return (older.id, newer.id);
  }

  Future<void> pumpComparison(
    WidgetTester tester,
    String setupAId,
    String setupBId, {
    double width = 390,
    bool dark = false,
  }) async {
    await tester.pumpWidget(
      harness.wrap(
        CompareSetups(setupAId: setupAId, setupBId: setupBId),
        width: width,
        dark: dark,
      ),
    );
    await settle(tester);
  }

  testWidgets('starts in Differences and All reveals unchanged rows', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    await pumpComparison(tester, setupAId, setupBId);

    expect(find.text('Differences'), findsOneWidget);
    expect(find.byKey(const Key('compare-row-fork-pressure')), findsNothing);

    await tester.tap(find.text('All'));
    await settle(tester);

    expect(find.byKey(const Key('compare-row-fork-pressure')), findsOneWidget);
  });

  testWidgets('identical projections show the empty hint and Show all works', (tester) async {
    final a = harness.setup(
      id: 'same-a',
      name: 'Same A',
      local: DateTime(2026, 8, 1, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    final b = harness.setup(
      id: 'same-b',
      name: 'Same B',
      local: DateTime(2026, 8, 2, 10),
      values: {CompareSetupsHarness.changedAdjustmentId: 4},
    );
    await harness.addSetups(tester, [a, b]);
    await harness.reload(tester);
    await pumpComparison(tester, a.id, b.id);

    expect(find.text('These setups have no differences'), findsOneWidget);
    await tester.tap(find.text('These setups have no differences'));
    await settle(tester);
    expect(find.byKey(const Key('compare-row-fork-rebound')), findsOneWidget);
  });

  testWidgets('uses narrow and wide row geometry without overflow', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester, name: 'L' * 200);
    await pumpComparison(tester, setupAId, setupBId, width: 320);
    expect(find.byType(Column), findsWidgets);
    expect(tester.takeException(), isNull);

    await pumpComparison(tester, setupAId, setupBId, width: 800);
    expect(find.byType(SetupComparisonRow), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps setup identities pinned while values scroll', (tester) async {
    await harness.dispose();
    harness = await CompareSetupsHarness.create(extraAdjustments: 24);
    final (setupAId, setupBId) = await seedPair(tester);
    await pumpComparison(tester, setupAId, setupBId);
    await tester.tap(find.text('All'));
    await settle(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await settle(tester);

    expect(find.byKey(const Key('compare-identity-a')), findsOneWidget);
    expect(find.byKey(const Key('compare-identity-b')), findsOneWidget);
  });

  testWidgets('changed rows expose a semantic difference and themed fill', (tester) async {
    final (setupAId, setupBId) = await seedPair(tester);
    await pumpComparison(tester, setupAId, setupBId, dark: true);

    final row = tester.widget<Container>(find.byKey(const Key('compare-row-fork-rebound')));
    expect(row.color, materialAppDarkTheme.extension<ValueHighlightColors>()!.changedFill);
    expect(find.bySemanticsLabel(RegExp('Different Rebound')), findsOneWidget);
  });

  testWidgets('explicit cross-bike inputs open and invalid implicit/equal calls do not', (tester) async {
    final setupA = harness.setup(id: 'a', name: 'A', local: DateTime(2026, 8, 1, 10));
    final setupB = harness.setup(
      id: 'b',
      name: 'B',
      local: DateTime(2026, 8, 2, 10),
      bike: CompareSetupsHarness.secondBikeId,
    );
    await harness.addSetups(tester, [setupA, setupB]);
    await harness.reload(tester);
    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => showCompareSetupsSheet(context, setupA: setupA, setupB: setupB),
                child: const Text('Cross bike'),
              ),
              TextButton(
                onPressed: () => showCompareSetupsSheet(context, setupA: null, setupB: setupB),
                child: const Text('Implicit'),
              ),
              TextButton(
                onPressed: () => showCompareSetupsSheet(context, setupA: setupB, setupB: setupB),
                child: const Text('Equal'),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Cross bike'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);

    await tester.tap(find.text('Implicit'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsNothing);
    expect(find.text('No current setup is available to compare.'), findsOneWidget);

    await tester.tap(find.text('Equal'));
    await settle(tester);
    expect(find.byType(CompareSetups), findsNothing);
    expect(find.text('Choose two different setups to compare.'), findsOneWidget);
  });
}
