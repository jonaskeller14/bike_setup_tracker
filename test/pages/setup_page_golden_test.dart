import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bike_setup_tracker/pages/setup_page.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_boolean_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_categorical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_numerical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/golden_test_harness.dart';

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
            child: SetupPage.edit(setup: harness.newerSetup),
          ),
        ),
        GoldenTestScenario(
          name: 'Dark',
          child: harness.wrap(
            brightness: Brightness.dark,
            child: SetupPage.edit(setup: harness.newerSetup),
          ),
        ),
      ],
    );
  }

  void expectAdjustmentWidgets() {
    expect(find.byType(SetNumericalAdjustmentWidget), findsNWidgets(2));
    expect(find.byType(SetStepAdjustmentWidget), findsNWidgets(2));
    expect(find.byType(SetCategoricalAdjustmentWidget), findsNWidgets(2));
    expect(find.byType(SetBooleanAdjustmentWidget), findsNWidgets(2));
  }

  unawaited(
    goldenTest(
      'renders setup metadata and the start of its adjustment form',
      fileName: 'setup_page_top',
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 1000),
      pumpBeforeTest: (tester) async {
        await settleGolden(tester);
        expectAdjustmentWidgets();
      },
      builder: buildScenarios,
    ),
  );
}
