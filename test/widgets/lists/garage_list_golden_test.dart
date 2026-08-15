import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bike_setup_tracker/widgets/items/garage_bike_card.dart';
import 'package:bike_setup_tracker/widgets/items/garage_uninstalled_card.dart';
import 'package:bike_setup_tracker/widgets/lists/garage_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/golden_test_harness.dart';

void main() {
  late GoldenTestHarness harness;

  setUp(() async {
    harness = await GoldenTestHarness.create();
  });

  tearDown(() => harness.dispose());

  GoldenTestGroup buildScenarios() {
    return GoldenTestGroup(
      columns: 2,
      scenarioConstraints: goldenScenarioConstraints,
      children: [
        GoldenTestScenario(
          name: 'Light',
          child: harness.wrap(
            brightness: Brightness.light,
            child: const Scaffold(body: GarageList()),
          ),
        ),
        GoldenTestScenario(
          name: 'Dark',
          child: harness.wrap(
            brightness: Brightness.dark,
            child: const Scaffold(body: GarageList()),
          ),
        ),
      ],
    );
  }

  unawaited(
    goldenTest(
      'renders a populated garage in light and dark themes',
      fileName: 'garage_list_populated',
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 1000),
      pumpBeforeTest: (tester) async {
        await settleGolden(tester);
        expect(find.byType(GarageBikeCard), findsNWidgets(4));
        expect(find.byType(GarageUninstalledCard), findsNWidgets(2));
        expect(
          find.byKey(const ValueKey(GoldenTestHarness.spareWheelId)),
          findsNWidgets(2),
        );
      },
      builder: buildScenarios,
    ),
  );
}
