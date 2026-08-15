import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bike_setup_tracker/widgets/current_setup_highlight.dart';
import 'package:bike_setup_tracker/widgets/items/setup_list_tile.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display_list.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/golden_test_harness.dart';

void main() {
  late GoldenTestHarness harness;

  setUp(() async {
    harness = await GoldenTestHarness.create();
  });

  tearDown(() => harness.dispose());

  unawaited(
    goldenTest(
      'renders setup history with compact adjustment values',
      fileName: 'setup_list_populated',
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 1000),
      pumpBeforeTest: (tester) async {
        await settleGolden(tester);
        expect(find.byType(SetupListTile), findsNWidgets(6));
        expect(find.byType(AdjustmentCompactDisplayList), findsNWidgets(6));
        expect(find.byType(CurrentSetupHighlight), findsNWidgets(2));
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        scenarioConstraints: goldenScenarioConstraints,
        children: [
          GoldenTestScenario(
            name: 'Light',
            child: harness.wrap(
              brightness: Brightness.light,
              child: const Scaffold(body: SetupList()),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark',
            child: harness.wrap(
              brightness: Brightness.dark,
              child: const Scaffold(body: SetupList()),
            ),
          ),
        ],
      ),
    ),
  );
}
