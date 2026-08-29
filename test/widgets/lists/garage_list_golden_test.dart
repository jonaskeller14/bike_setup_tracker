import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bike_setup_tracker/widgets/items/garage_bike_card.dart';
import 'package:bike_setup_tracker/widgets/items/garage_uninstalled_card.dart';
import 'package:bike_setup_tracker/widgets/lists/garage_list.dart';
import 'package:bike_setup_tracker/widgets/lists/list_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/golden_test_harness.dart';

void main() {
  late GoldenTestHarness harness;
  late ListScrollController lightController;
  late ListScrollController darkController;

  setUp(() async {
    harness = await GoldenTestHarness.create();
    lightController = ListScrollController();
    darkController = ListScrollController();
  });

  tearDown(() {
    lightController.dispose();
    darkController.dispose();
    unawaited(harness.dispose());
  });

  GoldenTestGroup buildScenarios() {
    return GoldenTestGroup(
      columns: 2,
      scenarioConstraints: goldenScenarioConstraints,
      children: [
        GoldenTestScenario(
          name: 'Light',
          child: harness.wrap(
            brightness: Brightness.light,
            child: Scaffold(body: GarageList(controller: lightController)),
          ),
        ),
        GoldenTestScenario(
          name: 'Dark',
          child: harness.wrap(
            brightness: Brightness.dark,
            child: Scaffold(body: GarageList(controller: darkController)),
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
