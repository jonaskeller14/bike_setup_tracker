import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_boolean_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_categorical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_duration_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_numerical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment_dial.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_text_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../goldens/support/golden_test_harness.dart';

const _showcaseComponentId = 'golden-component-showcase';
const _textId = 'golden-adjustment-text';
const _durationId = 'golden-adjustment-duration';
const _multiModeId = 'golden-adjustment-multi-mode';
const _sliderDialId = 'golden-adjustment-slider-dial';
const _buttonsId = 'golden-adjustment-buttons';
const _buttonsDialId = 'golden-adjustment-buttons-dial';
const _previousShowcaseSetupId = 'golden-setup-showcase-previous';
const _showcaseSetupId = 'golden-setup-showcase';

/// Tall enough to show the whole form without scrolling.
const _fullPageViewport = Size(390, 1750);

void main() {
  late GoldenTestHarness harness;

  setUp(() async {
    harness = await GoldenTestHarness.create();
    await _seedShowcase(harness);
  });

  tearDown(() => harness.dispose());

  GoldenTestGroup buildScenarios() {
    Widget scenario(Brightness brightness) => harness.wrap(
      brightness: brightness,
      viewport: _fullPageViewport,
      child: SetupPage.edit(setup: harness.repository.setups[_showcaseSetupId]!),
    );

    return GoldenTestGroup(
      columns: 2,
      scenarioConstraints: BoxConstraints.tight(_fullPageViewport),
      children: [
        GoldenTestScenario(name: 'Light', child: scenario(Brightness.light)),
        GoldenTestScenario(name: 'Dark', child: scenario(Brightness.dark)),
      ],
    );
  }

  void expectAdjustmentWidgets() {
    // Two scenarios (light and dark) render every widget once each.
    expect(find.byType(SetNumericalAdjustmentWidget), findsNWidgets(2));
    expect(find.byType(SetStepAdjustmentWidget), findsNWidgets(8));
    expect(find.byType(RotaryKnob), findsNWidgets(4));
    expect(find.byType(SetCategoricalAdjustmentWidget), findsNWidgets(4));
    expect(find.byType(SetBooleanAdjustmentWidget), findsNWidgets(2));
    expect(find.byType(SetTextAdjustmentWidget), findsNWidgets(2));
    expect(find.byType(SetDurationAdjustmentWidget), findsNWidgets(2));
  }

  unawaited(
    goldenTest(
      'renders the whole setup form with every adjustment type',
      fileName: 'setup_page_full',
      constraints: BoxConstraints(
        maxWidth: 2 * _fullPageViewport.width + 120,
        maxHeight: _fullPageViewport.height + 120,
      ),
      pumpBeforeTest: (tester) async {
        await settleGolden(tester);
        expectAdjustmentWidgets();
      },
      builder: buildScenarios,
    ),
  );
}

Future<void> _seedShowcase(GoldenTestHarness harness) async {
  final repository = harness.repository;

  await repository.addComponents([
    Component(
      id: _showcaseComponentId,
      name: 'Showcase Shock',
      componentType: ComponentType.shock,
      orderIndex: 1,
      installations: [
        Installation.sinceBeginning(
          id: 'golden-installation-showcase',
          parent: GoldenTestHarness.trailBikeId,
        ),
      ],
      adjustments: [
        TextAdjustment(
          id: _textId,
          name: 'Tune',
          notes: 'Free text',
          unit: null,
        ),
        DurationAdjustment(
          id: _durationId,
          name: 'Service interval',
          notes: 'Time since last service',
          unit: null,
        ),
        CategoricalAdjustment(
          id: _multiModeId,
          name: 'Damper features',
          notes: 'Multi select',
          unit: null,
          options: const {'Climb', 'Platform', 'Bottom-out'},
          multiSelect: true,
        ),
        StepAdjustment(
          id: _sliderDialId,
          name: 'High-speed compression',
          notes: 'Slider with dial',
          unit: AdjustmentUnit.fromLegacy('clicks'),
          min: 0,
          max: 12,
          step: 1,
          visualization: StepAdjustmentVisualization.sliderWithClockwiseDial,
          dialColor: StepAdjustmentDialColor.red,
        ),
        StepAdjustment(
          id: _buttonsId,
          name: 'Volume spacers',
          notes: 'Plus/minus buttons',
          unit: null,
          min: 0,
          max: 6,
          step: 1,
          visualization: StepAdjustmentVisualization.minusButtonValuePlusButton,
        ),
        StepAdjustment(
          id: _buttonsDialId,
          name: 'Low-speed rebound',
          notes: 'Buttons with dial',
          unit: AdjustmentUnit.fromLegacy('clicks'),
          min: 0,
          max: 16,
          step: 2,
          visualization: StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial,
          dialColor: StepAdjustmentDialColor.green,
          dialSize: StepAdjustmentDialSize.small,
        ),
      ],
    ),
  ]);

  Setup showcaseSetup({
    required String id,
    required String name,
    required DateTime datetime,
    required double pressure,
    required int rebound,
    required String mode,
    required bool lockout,
    required String tune,
    required Duration service,
    required List<String> features,
    required int highSpeed,
    required int spacers,
    required int lowSpeed,
  }) {
    return Setup(
      id: id,
      name: name,
      datetime: datetime.toUtc(),
      datetimeLocal: datetime,
      notes: null,
      tags: const {},
      bike: GoldenTestHarness.trailBikeId,
      person: null,
      bikeAdjustmentValues: {
        GoldenTestHarness.pressureId: NumericalValue(pressure),
        GoldenTestHarness.reboundId: StepValue(rebound),
        GoldenTestHarness.modeId: CategoricalValue([mode]),
        GoldenTestHarness.lockoutId: BooleanValue(lockout),
        _textId: TextValue.orNull(tune)!,
        _durationId: DurationValue(service),
        _multiModeId: CategoricalValue(features),
        _sliderDialId: StepValue(highSpeed),
        _buttonsId: StepValue(spacers),
        _buttonsDialId: StepValue(lowSpeed),
      },
      personAdjustmentValues: const {},
    );
  }

  await repository.addSetups([
    showcaseSetup(
      id: _previousShowcaseSetupId,
      name: 'Showcase before',
      datetime: DateTime(2026, 6, 15, 9),
      pressure: 80,
      rebound: 6,
      mode: 'Open',
      lockout: false,
      tune: 'Medium',
      service: const Duration(days: 30),
      features: const ['Climb'],
      highSpeed: 4,
      spacers: 2,
      lowSpeed: 8,
    ),
    showcaseSetup(
      id: _showcaseSetupId,
      name: 'Showcase after',
      datetime: DateTime(2026, 6, 16, 9),
      pressure: 84,
      rebound: 8,
      mode: 'Trail',
      lockout: true,
      tune: 'Firm',
      service: const Duration(days: 45, hours: 6),
      features: const ['Climb', 'Platform'],
      highSpeed: 7,
      spacers: 2,
      lowSpeed: 12,
    ),
  ]);

  for (var attempt = 0; attempt < 100; attempt++) {
    if (repository.setups[_showcaseSetupId] != null) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('Showcase setups did not finish loading.');
}
