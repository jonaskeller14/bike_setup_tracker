import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// [evaluateSetupGuide] over small inline catalogs run through the real
/// parser, so every rule shape is exercised as authored.

const _fork = '''
brand: FOX
component_type: fork
guides:
  fox_36:
    label: FOX 36 owner's manual (2027)
    source: https://tech.ridefox.com/fox-36
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
      - target: pressure
        unit: bar
        input: rider_weight
        input_unit: kg
        when: { trim: rhythm }
        rows: { 60: 5, 80: 6 }
      - target: lsr
        input: pressure
        input_unit: psi
        rows: { "<70": 14, 70-80: 12, 80-90: 8, 90+: 6 }
      - { target: hsc, value: [2, max] }
      - { target: lsc, value: max-3 }
      - target: volume_spacers
        input: rider_weight
        input_unit: kg
        rows: { 60: 1, 80: 2, 100: 3 }
      - { target: compression_mode, value: Firm }
      - { target: lockout, value: false }
      - { target: sag, range: [15, 20], comfort_at: max }
      - { target: sag, value: 16, when: { riding_style: race, damper: grip } }
      - target: rebound
        input: travel_mm
        rows: { 150: 7, 160: 9 }
      - target: preload
        unit: mm
        input: wheel_size
        rows: { 29: 3 }
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      adjustments:
        - { name: HSC, type: step, max: 8 }
        - { name: LSC, type: step, max: ~ }
        - { name: LSR, type: step, max: 16 }
        - { name: Compression Mode, type: categorical, options: [Open, Firm] }
        - { name: Lockout, type: boolean }
    grip:
      name: GRIP
      adjustments:
        - { name: Rebound, type: step, max: 13 }
nodes:
  - label: "36"
    level: model
    guide: fox_36
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 100 }
      - { name: Volume Spacers, type: step, max: 6, visualization: stepper }
      - { name: Preload, type: numerical, unit: mm }
    children:
      - label: Factory
        level: trim
        options:
          damper: [grip_x2, grip]
          travel_mm: [150, 160]
          wheel_size: [29, 27.5]
      - label: Rhythm
        level: trim
        options:
          damper: [grip]
          travel_mm: [150, 160]
''';

const _shock = '''
brand: FOX
component_type: shock
guides:
  fox_float_x2:
    label: FOX FLOAT X2 owner's manual (2027)
    source: https://tech.ridefox.com/float-x2
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: lb
        rows: { 150-170: [150, 160], 170-190: [170, 180] }
      - target: spring_rate
        unit: lbs/in
        input: rider_weight
        input_unit: kg
        rows: { 60: 400, 70: 450, 80: 500 }
      - target: rebound
        input: spring_rate
        input_unit: N/mm
        when: { trim: coil }
        rows: { 70-80: 10, 80-90: 8 }
      - target: sag
        unit: mm
        input: stroke_mm
        rows: { 55: [15, 17], 65: [18, 20] }
nodes:
  - label: FLOAT X2
    level: model
    guide: fox_float_x2
    children:
      - label: Air
        level: trim
        adjustments:
          - { name: Pressure, type: numerical, unit: psi, min: 0, max: 300 }
        options:
          size: ["210x55", "230x65"]
      - label: Coil
        level: trim
        adjustments:
          - { name: Spring Rate, type: numerical, unit: lbs/in, min: 300, max: 650 }
          - { name: Rebound, type: step, max: 16 }
        options:
          size: ["210x55"]
''';

/// The product at [trim] of [yaml], with [options] chosen by value id.
ResolvedPreset _preset(String yaml, String trim, [Map<String, Object> options = const {}]) {
  var preset = catalogProducts(parseCatalogFile(yaml)).firstWhere((preset) => preset.node.id == trim);
  for (final MapEntry(key: axisId, value: valueId) in options.entries) {
    final axis = preset.axes.firstWhere((axis) => axis.id == axisId);
    preset = preset.select(axis, axis.values.firstWhere((value) => value.id == valueId));
  }
  return preset;
}

/// Evaluates [preset] for the adjustments a catalog component gets, with
/// [current] keyed by adjustment name.
List<GuideRecommendation> _evaluate(
  ResolvedPreset preset, {
  GuideInputs inputs = const GuideInputs(),
  Map<String, AdjustmentValue> current = const {},
  List<Adjustment>? adjustments,
}) {
  final built = adjustments ?? buildCatalogApplication(preset).adjustments;
  return evaluateSetupGuide(preset, built, inputs, {
    for (final adjustment in built) adjustment.id: ?current[adjustment.name],
  });
}

GuideRecommendation _of(List<GuideRecommendation> results, String target) =>
    results.singleWhere((result) => result.rule.target == target);

const _kg = KnownUnit(quantity: UnitQuantity.mass, unitId: 'kilograms');
const _lb = KnownUnit(quantity: UnitQuantity.mass, unitId: 'pounds');

void main() {
  late ResolvedPreset factoryX2;

  setUpAll(() {
    factoryX2 = _preset(_fork, 'factory', {'damper': 'grip_x2', 'travel_mm': 160, 'wheel_size': '29'});
  });

  group('lookup', () {
    GuideRecommendation pressureAt(double weight, {KnownUnit unit = _kg}) => _of(
      _evaluate(
        factoryX2,
        inputs: GuideInputs(riderWeight: weight, riderWeightUnit: unit),
      ),
      'pressure',
    );

    test('interpolates between bracket midpoints', () {
      final result = pressureAt(83);
      expect(result.value, const NumericalValue(78));
      expect(result.interpolated, isTrue);
      expect(result.basis, "FOX 36 owner's manual (2027) · 83 kg · interpolated");
    });

    test('a midpoint is the published value, not interpolated', () {
      final result = pressureAt(85);
      expect(result.value, const NumericalValue(80));
      expect(result.interpolated, isFalse);
    });

    test('inside an outermost bracket the bracket value applies', () {
      expect(pressureAt(70).value, const NumericalValue(70));
      expect(pressureAt(99.9).value, const NumericalValue(90));
      expect(pressureAt(72).interpolated, isFalse);
    });

    test('outside the table there is no value', () {
      for (final weight in [69.9, 100.0, 130.0]) {
        final result = pressureAt(weight);
        expect(result.value, isNull, reason: '$weight kg');
        expect(result.issue, GuideIssue.outsideRange);
      }
    });

    test('converts the rider weight into the input unit', () {
      // 183 lb = 83.0 kg
      expect(pressureAt(183, unit: _lb).value, const NumericalValue(78));
      expect(pressureAt(183, unit: _lb).inputText, '183 lb');
    });

    test('converts the output unit and rounds pressure to 0.1 bar', () {
      final rhythm = _preset(_fork, 'rhythm', {'damper': 'grip'});
      final pressure = (rhythm.product!.adjustments.first.build() as NumericalAdjustment).copyWith(
        unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar'),
        max: 10.0,
      );
      final result = _of(
        _evaluate(rhythm, inputs: const GuideInputs(riderWeight: 73), adjustments: [pressure]),
        'pressure',
      );
      // The more specific rhythm rule: 5 bar at 60 kg, 6 bar at 80 kg.
      expect(result.value, const NumericalValue(5.7));
    });

    test('rounds pressure to 1 psi', () {
      final rhythm = _preset(_fork, 'rhythm', {'damper': 'grip'});
      // 5.65 bar = 81.9 psi
      expect(
        _of(_evaluate(rhythm, inputs: const GuideInputs(riderWeight: 73)), 'pressure').value,
        const NumericalValue(82),
      );
    });

    test('open-ended edge rows apply beyond the edge', () {
      AdjustmentValue? lsrAt(double psi) =>
          _of(_evaluate(factoryX2, current: {'Pressure': NumericalValue(psi)}), 'lsr').value;
      expect(lsrAt(40), const StepValue(14));
      expect(lsrAt(72), const StepValue(12));
      expect(lsrAt(80), const StepValue(10));
      expect(lsrAt(95), const StepValue(6));
      expect(lsrAt(250), const StepValue(6));
    });

    test('discrete targets take the nearest point, the lower on a tie', () {
      AdjustmentValue? spacersAt(double weight) =>
          _of(_evaluate(factoryX2, inputs: GuideInputs(riderWeight: weight)), 'volume_spacers').value;
      expect(spacersAt(60), const StepValue(1));
      expect(spacersAt(69), const StepValue(1));
      expect(spacersAt(70), const StepValue(1));
      expect(spacersAt(71), const StepValue(2));
      expect(spacersAt(100), const StepValue(3));
      expect(
        _of(_evaluate(factoryX2, inputs: const GuideInputs(riderWeight: 101)), 'volume_spacers').issue,
        GuideIssue.outsideRange,
      );
    });

    test('spring rates take the bracket value and never interpolate', () {
      final coil = _preset(_shock, 'coil');
      final result = _of(_evaluate(coil, inputs: const GuideInputs(riderWeight: 74)), 'spring_rate');
      expect(result.value, const NumericalValue(450));
      expect(result.interpolated, isFalse);
    });

    test('band cells interpolate both bounds and apply the midpoint', () {
      final air = _preset(_shock, 'air', {'size': '210x55'});
      // 180 lb is the second midpoint; 170 lb lies halfway between both.
      final atMidpoint = _of(
        _evaluate(air, inputs: const GuideInputs(riderWeight: 180, riderWeightUnit: _lb)),
        'pressure',
      );
      expect(atMidpoint.value, const NumericalValue(175));
      expect(atMidpoint.band, (min: 170.0, max: 180.0));

      final between = _of(
        _evaluate(air, inputs: const GuideInputs(riderWeight: 170, riderWeightUnit: _lb)),
        'pressure',
      );
      expect(between.value, const NumericalValue(165));
      expect(between.band, (min: 160.0, max: 170.0));
      expect(between.interpolated, isTrue);
    });

    test('a literal input matches its value id exactly', () {
      expect(_of(_evaluate(factoryX2), 'preload').value, const NumericalValue(3));
      final small = _preset(_fork, 'factory', {'damper': 'grip_x2', 'wheel_size': '27.5'});
      expect(_of(_evaluate(small), 'preload').issue, GuideIssue.outsideRange);
    });
  });

  group('inputs', () {
    test('no rider weight leaves weight-keyed rules without a value', () {
      final results = _evaluate(factoryX2);
      expect(_of(results, 'pressure').issue, GuideIssue.missingInput);
      expect(_of(results, 'volume_spacers').issue, GuideIssue.missingInput);
      // Constants still apply.
      expect(_of(results, 'hsc').value, isNotNull);
    });

    test('an adjuster input reads the current form value first', () {
      final results = _evaluate(
        factoryX2,
        inputs: const GuideInputs(riderWeight: 95),
        current: {'Pressure': const NumericalValue(75)},
      );
      expect(_of(results, 'lsr').value, const StepValue(12));
      expect(_of(results, 'lsr').inputText, 'Pressure 75 psi');
    });

    test('an adjuster input falls back to its own recommendation', () {
      final results = _evaluate(factoryX2, inputs: const GuideInputs(riderWeight: 95));
      // 95 kg → 90 psi → LSR 6.
      expect(_of(results, 'lsr').value, const StepValue(6));
    });

    test('without either the adjuster input is missing', () {
      expect(_of(_evaluate(factoryX2), 'lsr').issue, GuideIssue.missingInput);
    });

    test('a spring rate input converts into the input unit', () {
      final coil = _preset(_shock, 'coil');
      // 450 lbs/in ≈ 78.8 N/mm, between the midpoints 75 (10) and 85 (8).
      final results = _evaluate(coil, inputs: const GuideInputs(riderWeight: 70));
      expect(_of(results, 'rebound').value, const StepValue(9));
      final heavier = _evaluate(coil, current: {'Spring Rate': const NumericalValue(500)});
      // 500 lbs/in ≈ 87.6 N/mm, in the outer half of the 80-90 row.
      expect(_of(heavier, 'rebound').value, const StepValue(8));
    });

    test('a numeric preset input reads the selected option', () {
      AdjustmentValue? reboundAt(int travel) => _of(
        _evaluate(_preset(_fork, 'rhythm', {'damper': 'grip', 'travel_mm': travel})),
        'rebound',
      ).value;
      expect(reboundAt(150), const StepValue(7));
      expect(reboundAt(160), const StepValue(9));
      expect(
        _of(_evaluate(_preset(_fork, 'rhythm', {'damper': 'grip'})), 'rebound').issue,
        GuideIssue.missingInput,
      );
    });

    test('a spec input reads the selected size, and SAG converts from mm', () {
      final small = _preset(_shock, 'air', {'size': '210x55'});
      final result = _of(_evaluate(small), 'sag');
      // [15, 17] mm of 55 mm stroke.
      expect(result.inputText, '55 mm');
      expect(result.band!.min, closeTo(27.27, 0.01));
      expect(result.band!.max, closeTo(30.91, 0.01));
      expect(result.value, const NumericalValue(29.1));
    });
  });

  group('rules', () {
    test('the most specific matching rule wins', () {
      final rhythm = _preset(_fork, 'rhythm', {'damper': 'grip'});
      final result = _of(_evaluate(rhythm, inputs: const GuideInputs(riderWeight: 80)), 'pressure');
      expect(result.rule.unit, const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar'));
    });

    test('a rule naming a skipped option does not match', () {
      final skipped = _preset(_fork, 'factory', {'damper': 'grip'});
      final race = _of(
        _evaluate(skipped, inputs: const GuideInputs(ridingStyle: GuideRidingStyle.race)),
        'sag',
      );
      expect(race.value, const NumericalValue(16));
      final x2 = _of(_evaluate(factoryX2, inputs: const GuideInputs(ridingStyle: GuideRidingStyle.race)), 'sag');
      expect(x2.value, const NumericalValue(15));
    });

    test('a target without a matching adjustment is dropped', () {
      final results = _evaluate(factoryX2);
      expect(results.map((result) => result.rule.target), isNot(contains('rebound')));
    });

    test('a hand-built adjustment matches by its name slug', () {
      final results = _evaluate(
        factoryX2,
        adjustments: [
          StepAdjustment(
            name: 'HSC',
            notes: null,
            unit: null,
            step: 1,
            min: 0,
            max: 10,
            visualization: StepAdjustmentVisualization.slider,
          ),
        ],
      );
      expect(_of(results, 'hsc').value, const StepValue(6));
    });

    test('results follow the adjustment order', () {
      final adjustments = buildCatalogApplication(factoryX2).adjustments;
      final results = _evaluate(factoryX2, inputs: const GuideInputs(riderWeight: 80));
      final order = [for (final result in results) adjustments.indexOf(result.adjustment)];
      expect(order, [...order]..sort());
    });
  });

  group('range', () {
    AdjustmentValue? sagFor(GuideRidingStyle? style) =>
        _of(_evaluate(factoryX2, inputs: GuideInputs(ridingStyle: style)), 'sag').value;

    test('maps the riding style onto the band', () {
      expect(sagFor(GuideRidingStyle.comfort), const NumericalValue(20));
      expect(sagFor(GuideRidingStyle.balanced), const NumericalValue(17.5));
      expect(sagFor(null), const NumericalValue(17.5));
    });

    test('the whole band is on guide', () {
      final result = _of(_evaluate(factoryX2, current: {'SAG': const NumericalValue(19)}), 'sag');
      expect(result.band, (min: 15.0, max: 20.0));
      expect(result.deviation!.onGuide, isTrue);
      expect(result.deviation!.delta, 1.5);
    });
  });

  group('range references', () {
    test('resolve against the live range', () {
      final hsc = _of(_evaluate(factoryX2), 'hsc');
      expect(hsc.value, const StepValue(5));
      expect(hsc.band, (min: 2.0, max: 8.0));
    });

    test('follow an edited max', () {
      final adjustments = [
        for (final adjustment in buildCatalogApplication(factoryX2).adjustments)
          adjustment is StepAdjustment && adjustment.name == 'HSC' ? adjustment.copyWith(max: 12) : adjustment,
      ];
      expect(_of(_evaluate(factoryX2, adjustments: adjustments), 'hsc').value, const StepValue(7));
    });

    test('a placeholder max gives no value until the rider enters the real one', () {
      final adjustments = buildCatalogApplication(factoryX2).adjustments;
      expect(_of(_evaluate(factoryX2, adjustments: adjustments), 'lsc').issue, GuideIssue.placeholderMax);

      final edited = [
        for (final adjustment in adjustments)
          adjustment is StepAdjustment && adjustment.name == 'LSC' ? adjustment.copyWith(max: 18) : adjustment,
      ];
      expect(_of(_evaluate(factoryX2, adjustments: edited), 'lsc').value, const StepValue(15));
    });

    test('a hand-built max of 20 is no placeholder', () {
      final adjustments = [
        StepAdjustment(
          name: 'LSC',
          notes: null,
          unit: null,
          step: 1,
          min: 0,
          max: 20,
          visualization: StepAdjustmentVisualization.slider,
        ),
      ];
      final rhythm = _preset(_fork, 'rhythm', {'damper': 'grip'});
      expect(_of(_evaluate(rhythm, adjustments: adjustments), 'lsc').value, const StepValue(17));
    });
  });

  group('rounding and limits', () {
    test('step values round to the nearest click and are never capped', () {
      final narrow = [
        StepAdjustment(
          name: 'HSC',
          notes: null,
          unit: null,
          step: 2,
          min: 0,
          max: 6,
          visualization: StepAdjustmentVisualization.slider,
        ),
      ];
      // [2, 6] → midpoint 4 on a 2-click grid.
      expect(_of(_evaluate(factoryX2, adjustments: narrow), 'hsc').value, const StepValue(4));

      final short = [
        for (final adjustment in buildCatalogApplication(factoryX2).adjustments)
          adjustment is StepAdjustment && adjustment.name == 'LSR' ? adjustment.copyWith(max: 10) : adjustment,
      ];
      final lsr = _of(_evaluate(factoryX2, adjustments: short, current: {'Pressure': const NumericalValue(40)}), 'lsr');
      expect(lsr.value, isNull);
      expect(lsr.issue, GuideIssue.aboveMax);
      expect(lsr.unappliedValue, const StepValue(14));
    });

    test('a numerical value above the adjuster max is not applied', () {
      final low = [
        for (final adjustment in buildCatalogApplication(factoryX2).adjustments)
          adjustment is NumericalAdjustment && adjustment.name == 'Pressure'
              ? adjustment.copyWith(max: 75.0)
              : adjustment,
      ];
      final result = _of(
        _evaluate(factoryX2, adjustments: low, inputs: const GuideInputs(riderWeight: 85)),
        'pressure',
      );
      expect(result.value, isNull);
      expect(result.issue, GuideIssue.aboveMax);
      expect(result.unappliedValue, const NumericalValue(80));
    });
  });

  group('dial counting', () {
    /// The catalog adjustments with [name]'s step adjuster edited.
    List<Adjustment> withStep(String name, StepAdjustment Function(StepAdjustment) edit) => [
      for (final adjustment in buildCatalogApplication(factoryX2).adjustments)
        adjustment is StepAdjustment && adjustment.name == name ? edit(adjustment) : adjustment,
    ];

    GuideRecommendation lsrAt(double pressure, List<Adjustment> adjustments) => _of(
      _evaluate(factoryX2, adjustments: adjustments, current: {'Pressure': NumericalValue(pressure)}),
      'lsr',
    );

    const clockwise = StepAdjustmentVisualization.sliderWithClockwiseDial;

    test('a clockwise -16…0 dial counts the catalog\'s clicks from closed down from 0', () {
      final adjustments = withStep('LSR', (a) => a.copyWith(min: -16, max: 0, visualization: clockwise));
      final lsr = lsrAt(85, adjustments);
      expect(lsr.value, const StepValue(-8));
      expect(lsr.converted, isTrue);
      expect(lsrAt(75, adjustments).value, const StepValue(-12));
    });

    test('the same range turning the other way is mirrored', () {
      final lsr = lsrAt(75, withStep('LSR', (a) => a.copyWith(visualization: clockwise)));
      expect(lsr.value, const StepValue(4));
      expect(lsr.converted, isTrue);
    });

    test('a shifted range turning the same way keeps the clicks from its min', () {
      final lsr = lsrAt(75, withStep('LSR', (a) => a.copyWith(min: -16, max: 0)));
      expect(lsr.value, const StepValue(-4));
      expect(lsr.converted, isTrue);
    });

    test('the catalog\'s own dial is not converted', () {
      final lsr = lsrAt(75, buildCatalogApplication(factoryX2).adjustments);
      expect(lsr.value, const StepValue(12));
      expect(lsr.converted, isFalse);
    });

    test('range references and bands swap ends on a mirrored dial', () {
      final hsc = _of(
        _evaluate(factoryX2, adjustments: withStep('HSC', (a) => a.copyWith(visualization: clockwise))),
        'hsc',
      );
      expect(hsc.band, (min: 0.0, max: 6.0));
      expect(hsc.value, const StepValue(3));

      final lsc = withStep('LSC', (a) => a.copyWith(visualization: clockwise));
      expect(_of(_evaluate(factoryX2, adjustments: lsc), 'lsc').issue, GuideIssue.placeholderMax);
      final edited = withStep('LSC', (a) => a.copyWith(max: 18, visualization: clockwise));
      expect(_of(_evaluate(factoryX2, adjustments: edited), 'lsc').value, const StepValue(3));
    });

    test('a stepper on another range is shown in the catalog\'s counting but not applied', () {
      final adjustments = withStep(
        'LSR',
        (a) => a.copyWith(min: -16, max: 0, visualization: StepAdjustmentVisualization.minusButtonValuePlusButton),
      );
      final lsr = lsrAt(75, adjustments);
      expect(lsr.value, isNull);
      expect(lsr.issue, GuideIssue.directionUnknown);
      expect(lsr.unappliedValue, const StepValue(12));
    });
  });

  group('options and booleans', () {
    test('yield values of the adjustment type', () {
      final results = _evaluate(factoryX2);
      expect(_of(results, 'compression_mode').value, CategoricalValue(const ['Firm']));
      expect(_of(results, 'lockout').value, const BooleanValue(false));
    });

    test('a removed option or another type is incompatible', () {
      final edited = [
        CategoricalAdjustment(name: 'Compression Mode', notes: null, unit: null, options: const {'Open', 'Medium'}),
        StepAdjustment(
          name: 'Lockout',
          notes: null,
          unit: null,
          step: 1,
          min: 0,
          max: 1,
          visualization: StepAdjustmentVisualization.slider,
        ),
      ];
      final results = _evaluate(factoryX2, adjustments: edited);
      expect(_of(results, 'compression_mode').issue, GuideIssue.incompatible);
      expect(_of(results, 'lockout').issue, GuideIssue.incompatible);
    });

    test('are on guide only when equal', () {
      final results = _evaluate(
        factoryX2,
        current: {
          'Compression Mode': CategoricalValue(const ['Open']),
          'Lockout': const BooleanValue(false),
        },
      );
      expect(_of(results, 'compression_mode').deviation!.onGuide, isFalse);
      expect(_of(results, 'compression_mode').deviation!.delta, isNull);
      expect(_of(results, 'lockout').deviation!.onGuide, isTrue);
    });
  });

  group('deviation', () {
    GuideRecommendation pressure({required double weight, required double now}) => _of(
      _evaluate(
        factoryX2,
        inputs: GuideInputs(riderWeight: weight),
        current: {'Pressure': NumericalValue(now)},
      ),
      'pressure',
    );

    test('tolerance is half the difference to the neighbouring row', () {
      final result = pressure(weight: 85, now: 84);
      expect(result.band, (min: 75.0, max: 85.0));
      expect(result.deviation!.delta, 4);
      expect(result.deviation!.onGuide, isTrue);
      expect(result.deviation!.exact, isFalse);
      expect(pressure(weight: 85, now: 80).deviation!.exact, isTrue);
      expect(pressure(weight: 85, now: 86).deviation!.onGuide, isFalse);
    });

    test('a step band snaps to whole clicks, like the value', () {
      // 77 psi → 11.2 clicks ± 2 → 9.2–13.2, which a dial can only set as 9–13.
      final lsr = _of(
        _evaluate(factoryX2, current: {'Pressure': const NumericalValue(77), 'LSR': const StepValue(9)}),
        'lsr',
      );
      expect(lsr.value, const StepValue(11));
      expect(lsr.band, (min: 9.0, max: 13.0));
      expect(lsr.deviation!.onGuide, isTrue);
    });

    test('an outermost bracket uses its inner neighbour', () {
      expect(pressure(weight: 72, now: 74).band, (min: 65.0, max: 75.0));
    });

    test('a constant must match exactly', () {
      final result = _of(_evaluate(factoryX2, current: {'Lockout': const BooleanValue(true)}), 'lockout');
      expect(result.deviation!.onGuide, isFalse);
      expect(result.band, isNull);
    });

    test('no current value, no deviation', () {
      expect(_of(_evaluate(factoryX2, inputs: const GuideInputs(riderWeight: 85)), 'pressure').deviation, isNull);
    });
  });

  group('reverse lookup', () {
    ({double min, double max})? weightsFor(double psi, {KnownUnit unit = _kg}) => _of(
      _evaluate(
        factoryX2,
        inputs: GuideInputs(riderWeightUnit: unit),
        current: {'Pressure': NumericalValue(psi)},
      ),
      'pressure',
    ).riderWeightRange;

    test('finds the weights a pressure is on guide for, without a rider weight', () {
      final range = weightsFor(80)!;
      expect(range.min, closeTo(80, 1e-3));
      expect(range.max, closeTo(90, 1e-3));
    });

    test('reaches into the outermost bracket', () {
      final range = weightsFor(70)!;
      expect(range.min, closeTo(70, 1e-3));
      expect(range.max, closeTo(80, 1e-3));
    });

    test('reports in the rider weight unit', () {
      final range = weightsFor(80, unit: _lb)!;
      expect(range.min, closeTo(176.4, 0.1));
      expect(range.max, closeTo(198.4, 0.1));
    });

    test('a pressure no rider gets has no range', () {
      expect(weightsFor(40), isNull);
    });

    test('band cells use band membership', () {
      final air = _preset(_shock, 'air', {'size': '210x55'});
      final range = _of(
        _evaluate(
          air,
          inputs: const GuideInputs(riderWeightUnit: _lb),
          current: {'Pressure': const NumericalValue(155)},
        ),
        'pressure',
      ).riderWeightRange!;
      // Flat [150, 160] up to the 160 lb midpoint, then the lower bound
      // rises past 155 a quarter of the way to 180 lb.
      expect(range.min, closeTo(150, 1e-3));
      expect(range.max, closeTo(165, 1e-3));
    });
  });

  test('a product without a guide yields nothing', () {
    const plain = '''
brand: FOX
component_type: fork
nodes:
  - label: "34"
    level: model
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0 }
''';
    expect(_evaluate(_preset(plain, '34')), isEmpty);
  });

  group('FOX catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/fox.md:
    // 82 kg = 180.78 lb, 57.8 % of the way from the 170-180 lb midpoint (175)
    // to the 180-190 lb midpoint (185).
    const weight = GuideInputs(riderWeight: 82);

    test('38 FLOAT GRIP X2 (2025-2026) at 82 kg', () {
      final results = _evaluate(
        _real('fork/fox.yaml', '38/2025/factory', {'damper': 'grip_x2', 'travel_mm': 170, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(95)); // 93 → 97 psi
      expect(_of(results, 'pressure').basis, "FOX 38 owner's manual (2026) · 82 kg · interpolated");
      expect(_of(results, 'lsr').value, const StepValue(6)); // 7 → 6
      expect(_of(results, 'hsr').value, const StepValue(4)); // 5 → 4
      expect(_of(results, 'hsc').value, const StepValue(5));
      expect(_of(results, 'lsc').value, const StepValue(10));
      expect(_of(results, 'volume_spacers').value, const StepValue(2));
    });

    test('38 FLOAT (2027) takes the revised pressure table and spacer configurations', () {
      final results = _evaluate(
        _real('fork/fox.yaml', '38/2027/factory', {'damper': 'grip_x2', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(78)); // 75 → 80 psi
      expect(_of(results, 'volume_spacers').value, CategoricalValue(const ['1× 10cc + 1× 5cc']));
    });

    test('36 Rhythm GRIP (2025-2026) at 82 kg', () {
      final results = _evaluate(
        _real('fork/fox.yaml', '36/2025/rhythm', {'damper': 'grip', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(78)); // 76 → 80 psi
      expect(_of(results, 'rebound').value, const StepValue(7)); // 8 → 7
      expect(_of(results, 'volume_spacers').value, const StepValue(2));
    });

    test('a 130 kg rider is outside the published range', () {
      final results = _evaluate(
        _real('fork/fox.yaml', '38/2025/factory', {'damper': 'grip_x2', 'travel_mm': 170, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 130),
      );
      for (final target in ['pressure', 'lsr', 'hsr']) {
        expect(_of(results, target).value, isNull, reason: target);
        expect(_of(results, target).issue, GuideIssue.outsideRange, reason: target);
      }
      expect(_of(results, 'hsc').value, const StepValue(5));
    });

    test('FLOAT X2 (2025-2026) reads its damper settings off the recommended pressure', () {
      final results = _evaluate(
        _real('shock/fox.yaml', 'float-x2/2025/factory', {'damper': 'vvc2'}),
        inputs: const GuideInputs(riderWeight: 95),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(209)); // psi = lb
      expect(_of(results, 'lsr').value, const StepValue(7)); // 200-220 psi
      expect(_of(results, 'lsc').value, const StepValue(10)); // [9, 10], midpoint rounded
    });
  });

  group('RockShox catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/rockshox.md:
    // 82 kg = 180.78 lb, 53.9 % of the way from the 160-180 lb midpoint (170)
    // to the 180-200 lb midpoint (190); rebound sits between the 80 and 85 kg rows.
    const weight = GuideInputs(riderWeight: 82);
    final pike = _real('fork/rockshox.yaml', 'pike/2025/ultimate', {
      'damper': 'charger_3_1',
      'travel_mm': 130,
      'wheel_size': '29',
    });

    test('Pike Ultimate (2025-2027) at 82 kg', () {
      final results = _evaluate(pike, inputs: weight);
      final pressure = _of(results, 'pressure');
      expect(pressure.value, const NumericalValue(80)); // [70, 80] → [80, 90] psi
      expect(pressure.band!.min, closeTo(75.39, 0.01));
      expect(pressure.band!.max, closeTo(85.39, 0.01));
      expect(pressure.basis, 'RockShox Front Suspension Specifications (2027) · 82 kg · interpolated');
      expect(_of(results, 'rebound').value, const StepValue(8)); // 10 clicks from closed on an 18-click dial
      expect(_of(results, 'hsc').value, const StepValue(0));
      expect(_of(results, 'lsc').value, const StepValue(0));
      expect(_of(results, 'volume_spacers').value, const StepValue(0));
    });

    test('a rider above the last printed bracket gets no pressure', () {
      final results = _evaluate(pike, inputs: const GuideInputs(riderWeight: 105));
      expect(_of(results, 'pressure').issue, GuideIssue.outsideRange); // 231 lb, the decal's "100+" cell
      expect(_of(results, 'rebound').value, const StepValue(11)); // 7 clicks from closed
    });

    test('SID SL E1 and D1 read their own decals', () {
      ResolvedPreset sidSl(String generation) => _real('fork/rockshox.yaml', 'sid-sl/$generation/ultimate', {
        'damper': 'charger_race_day_2',
        'travel_mm': 100,
        'wheel_size': '29',
      });
      final e1 = _evaluate(sidSl('2026'), inputs: weight);
      expect(_of(e1, 'pressure').value, const NumericalValue(120)); // [108, 120] → [120, 132] psi
      expect(_of(e1, 'rebound').issue, GuideIssue.placeholderMax);
      final d1 = _evaluate(sidSl('2025'), inputs: weight);
      expect(_of(d1, 'pressure').value, const NumericalValue(121)); // [105, 120] → [120, 135] psi
      expect(_of(d1, 'sag').value, const NumericalValue(20)); // the general 10-30 % band
    });

    test('Super Deluxe Select (SoloAir) at 82 kg', () {
      final results = _evaluate(
        _real('shock/rockshox.yaml', 'super-deluxe/2023/select', {'damper': 'rc2t'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(180)); // psi = lb
      expect(_of(results, 'rebound').value, const StepValue(6)); // 9 → 8 clicks from closed on a 15-click dial
      expect(_of(results, 'hsc').value, const StepValue(0));
      expect(_of(results, 'lsc').value, const StepValue(0));
      expect(_of(results, 'sag').value, const NumericalValue(25)); // SoloAir: 20-30 %
    });
  });

  group('Öhlins catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/ohlins.md:
    // 82 kg sits 70 % of the way from the 70-80 kg midpoint (75) to the
    // 80-90 kg midpoint (85).
    const weight = GuideInputs(riderWeight: 82);

    test('RXF36 m.2 Air TTX18 at 82 kg sets both chambers', () {
      final results = _evaluate(
        _real('fork/ohlins.yaml', 'rxf36/m2/air-ttx18', {'damper': 'ttx18_m2', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: weight,
      );
      final main = _of(results, 'main_chamber_pressure');
      expect(main.value, const NumericalValue(102)); // [90, 100] → [100, 110] psi
      expect(main.band!.min, closeTo(97, 0.01));
      expect(main.band!.max, closeTo(107, 0.01));
      expect(main.basis, "Öhlins RXF36 m.2 owner's manual (2023) · 82 kg · interpolated");
      expect(_of(results, 'ramp_up_chamber_pressure').value, const NumericalValue(192)); // [180, 190] → [190, 200]
      expect(_of(results, 'rebound').value, const StepValue(15)); // 14-16 clicks, fits the raised max 16
      expect(_of(results, 'lsc').value, const StepValue(15));
      expect(_of(results, 'hsc').value, const StepValue(3));
      expect(_of(results, 'sag').value, const NumericalValue(12.5)); // air 10-15 %
    });

    test('RXF38 m.3 Coil takes the nearest spring of the chart', () {
      final coil = _real('fork/ohlins.yaml', 'rxf38/m3/coil', {
        'damper': 'ttx18_m3',
        'travel_mm': 170,
        'wheel_size': '29',
      });
      expect(_of(_evaluate(coil, inputs: weight), 'spring_rate').value, const NumericalValue(9.7)); // 82 kg point
      expect(
        _of(_evaluate(coil, inputs: const GuideInputs(riderWeight: 87)), 'spring_rate').value,
        const NumericalValue(10.6), // 91 kg is nearer than 82 kg
      );
      expect(_of(_evaluate(coil, inputs: weight), 'sag').value, const NumericalValue(17.5)); // coil 15-20 %
    });

    test('TTX Air and TTX22 m.2 shocks recommend named dial positions', () {
      final ttx1 = _evaluate(_real('shock/ohlins.yaml', 'ttx1air/m1/universal', {'damper': 'ttx1air_m1'}));
      expect(_of(ttx1, 'pressure').value, const NumericalValue(170)); // start pressure before sag
      expect(_of(ttx1, 'hsc').value, CategoricalValue(const ['2']));
      expect(_of(ttx1, 'volume_spacers').value, CategoricalValue(const ['A'])); // MTBM 1950-1955 production
      expect(_of(ttx1, 'sag').value, const NumericalValue(30)); // 25-35 %
      final ttx22 = _evaluate(_real('shock/ohlins.yaml', 'ttx22/m2/piggyback', {'damper': 'ttx22_m2'}));
      expect(_of(ttx22, 'hsc').value, CategoricalValue(const ['II']));
    });
  });

  group('INTEND catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/intend.md:
    // psi = 1.0 or 1.3 × rider weight in kg, calculated at 5 kg steps.
    test('Hero at 82 kg', () {
      final results = _evaluate(
        _real('fork/intend.yaml', 'hero/standard', {'damper': 'closed_cartridge', 'travel_mm': 160}),
        inputs: const GuideInputs(riderWeight: 82),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(82)); // 1.0 × 82
      expect(_of(results, 'compression').value, const StepValue(6)); // from closed, applies on the placeholder max
    });

    test('Bandit at 82 kg takes the 1.3 factor', () {
      final results = _evaluate(
        _real('fork/intend.yaml', 'bandit/standard', {'damper': 'closed_cartridge', 'travel_mm': 170}),
        inputs: const GuideInputs(riderWeight: 82),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(107)); // 1.3 × 82 = 106.6
    });

    test('a 130 kg rider is outside the calculated range', () {
      final results = _evaluate(
        _real('fork/intend.yaml', 'edge/standard', {'damper': 'closed_cartridge', 'travel_mm': 160}),
        inputs: const GuideInputs(riderWeight: 130),
      );
      expect(_of(results, 'pressure').issue, GuideIssue.outsideRange);
    });
  });

  group('Marzocchi catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/marzocchi.md:
    // 82 kg = 180.78 lb, 57.8 % of the way from the 170-180 lb midpoint (175)
    // to the 180-190 lb midpoint (185).
    const weight = GuideInputs(riderWeight: 82);

    test('Bomber Z1 (2024 owner\'s guide) at 82 kg', () {
      final results = _evaluate(
        _real('fork/marzocchi.yaml', 'z1/standard', {'damper': 'rail', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(78)); // 76 → 80 psi
      expect(_of(results, 'rebound').value, const StepValue(7)); // 8 → 7 clicks from closed
      expect(_of(results, 'volume_spacers').value, const StepValue(2)); // factory count at 160 mm
    });

    test('Bomber Z1 Coil gets SAG but not the air table\'s rebound', () {
      final results = _evaluate(
        _real('fork/marzocchi.yaml', 'z1-coil/coil', {'damper': 'rail', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(results.where((result) => result.rule.target == 'rebound'), isEmpty);
      expect(_of(results, 'sag').band, isNotNull); // 15-20 %
    });

    test('Bomber Air reads its rebound off the recommended pressure', () {
      final results = _evaluate(
        _real('shock/marzocchi.yaml', 'bomber-air/metric', {'damper': 'bomber_air', 'size': '230x65'}),
        inputs: const GuideInputs(riderWeight: 95),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(209)); // psi = lb
      expect(_of(results, 'rebound').value, const StepValue(5)); // 200-220 psi
      expect(_of(results, 'compression_mode').value, CategoricalValue(const ['Open']));
    });
  });

  group('Cane Creek catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/canecreek.md:
    // 82 kg sits 40 % of the way from the 80 kg row to the 85 kg row.
    const weight = GuideInputs(riderWeight: 82);

    test('Helm MKII Air takes 30-40 % of the rider weight', () {
      final results = _evaluate(
        _real('fork/canecreek.yaml', 'helm-mkii/air', {'damper': 'helm_mkii_damper', 'travel_mm': 150, 'wheel_size': '29'}),
        inputs: weight,
      );
      final pressure = _of(results, 'pressure');
      expect(pressure.value, const NumericalValue(63)); // [53, 71] → [56, 75] psi
      expect(pressure.band!.min, closeTo(54.2, 0.01));
      expect(pressure.band!.max, closeTo(72.6, 0.01));
      expect(_of(results, 'sag').value, const NumericalValue(20)); // air: 15-25 %
    });

    test('Helm MKII Coil picks the spring for the rider weight', () {
      final results = _evaluate(
        _real('fork/canecreek.yaml', 'helm-mkii/coil', {'damper': 'helm_mkii_damper', 'travel_mm': 150, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'spring_rate').value, const NumericalValue(55)); // 180.78 lb, 160-200 lb bracket
    });

    test('Double Barrel base tunes count from open on each damper\'s own range', () {
      final airCs = _evaluate(
        _real('shock/canecreek.yaml', 'db-air-cs/standard', {'damper': 'db_classic_cs'}),
        inputs: weight,
      );
      expect(_of(airCs, 'pressure').value, const NumericalValue(160)); // 156 → 167 psi (lb − 20)
      expect(_of(airCs, 'lsc').value, const StepValue(12)); // 13 from open on 25 clicks
      expect(_of(airCs, 'lsr').value, const StepValue(10)); // 15 from open on 25 clicks
      expect(_of(airCs, 'hsc').value, const NumericalValue(2)); // 2 turns from open on 4
      final inline = _evaluate(_real('shock/canecreek.yaml', 'db-inline/standard', {'damper': 'db_inline'}));
      expect(_of(inline, 'lsc').value, const StepValue(11)); // 7 from open on 18 clicks
      expect(_of(inline, 'lsr').value, const StepValue(8)); // 10 from open on 18 clicks
      expect(_of(inline, 'hsr').value, const NumericalValue(2.5)); // 2 turns from open on 4.5
    });
  });

  group('EXT catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/ext.md:
    // 74 kg sits 40 % of the way from the 70 kg point to the 80 kg point.
    final era = _real('fork/ext.yaml', 'era-v2-1/standard', {
      'damper': 'era_cartridge',
      'travel_mm': 160,
      'wheel_size': '29',
    });

    test('Era V2.1 sets both air chambers and three dials at 74 kg', () {
      final results = _evaluate(era, inputs: const GuideInputs(riderWeight: 74));
      expect(_of(results, 'main_chamber_pressure').value, const NumericalValue(59)); // 55 → 65 psi
      expect(_of(results, 'secondary_chamber_pressure').value, const NumericalValue(91)); // 85 → 100 psi
      expect(_of(results, 'hsc').value, const StepValue(8)); // 8 → 7
      expect(_of(results, 'lsc').value, const StepValue(8)); // 8 → 7
      expect(_of(results, 'rebound').value, const StepValue(13)); // 14 → 12
    });

    test('an Era rider below 60 kg gets clicks but no pressure', () {
      final results = _evaluate(era, inputs: const GuideInputs(riderWeight: 55));
      expect(_of(results, 'main_chamber_pressure').issue, GuideIssue.outsideRange); // "< 45 psi" has no minimum
      expect(_of(results, 'hsc').value, const StepValue(10));
      expect(_of(results, 'rebound').value, const StepValue(18));
    });

    test('Vecta reads its dials off the fitted spring rate', () {
      final results = _evaluate(
        _real('shock/ext.yaml', 'vecta/metric-standard', {'damper': 'vecta', 'size': '230x65'}),
        current: {'Spring Rate': const NumericalValue(450)},
      );
      expect(_of(results, 'hsc').value, const StepValue(7)); // 425-450 lb/in
      expect(_of(results, 'lsc').value, const StepValue(7));
      expect(_of(results, 'rebound').value, const StepValue(10));
      final arma = _evaluate(_real('shock/ext.yaml', 'arma-v4/metric-standard', {'damper': 'arma_v4', 'size': '230x65'}));
      expect(_of(arma, 'hbc').value, const StepValue(5)); // V4 quick manual constant
    });
  });

  group('DVO catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/dvo.md:
    // 82 kg = 180.78 lb, 53.9 % of the way from the 160-180 lb midpoint (170)
    // to the 180-200 lb midpoint (190). Rebound, HSC and OTT read the
    // recommended pressure.
    const weight = GuideInputs(riderWeight: 82);
    final onyx38 = _real('fork/dvo.yaml', '38/d1', {'damper': 'onyx38_d1e1', 'travel_mm': 170, 'wheel_size': '29'});

    test('Onyx 38 D1 at 82 kg', () {
      final results = _evaluate(onyx38, inputs: weight);
      final pressure = _of(results, 'pressure');
      expect(pressure.value, const NumericalValue(68)); // [60, 70] → [65, 75] psi, center 67.69
      expect(pressure.basis, 'DVO Onyx 38 Series Set-Up Guide (v1.1, 2024) · 82 kg · interpolated');
      // 68 psi is 10 % of the way from the 65-70 midpoint (67.5) to the 70-75 midpoint (72.5).
      expect(_of(results, 'rebound').value, const StepValue(16)); // [14, 18] → [12, 16], center 15.8
      expect(_of(results, 'hsc').value, const NumericalValue(1.1)); // 1 → 2 turns
      expect(_of(results, 'ott').value, const NumericalValue(6.1)); // [5, 7] → [6, 8], center 6.1
      expect(_of(results, 'sag').value, const NumericalValue(22.5)); // 15-30 %
      expect(results.where((result) => result.rule.target == 'volume_spacers'), isEmpty); // SL only
    });

    test('Onyx 38 Plush and Firm ends follow the riding style', () {
      final comfort = _evaluate(
        onyx38,
        inputs: const GuideInputs(riderWeight: 82, ridingStyle: GuideRidingStyle.comfort),
      );
      expect(_of(comfort, 'pressure').value, const NumericalValue(63)); // Plush 60 → 65 psi
      expect(_of(comfort, 'sag').value, const NumericalValue(30));
      final race = _evaluate(onyx38, inputs: const GuideInputs(riderWeight: 82, ridingStyle: GuideRidingStyle.race));
      expect(_of(race, 'pressure').value, const NumericalValue(73)); // Firm 70 → 75 psi
      expect(_of(race, 'rebound').value, const StepValue(14)); // 73 psi: [12, 16] → [10, 14] at 10 %, center 13.8
    });

    test('Sapphire 34 D1 (2020 guide) at 82 kg', () {
      final results = _evaluate(
        _real('fork/dvo.yaml', 'sapphire-34/d1', {'damper': 'quick_range_d1e1'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(95)); // [85, 95] → [95, 105] psi, center 95.39
      expect(_of(results, 'rebound').value, const StepValue(18)); // 95 psi: halfway [18, 22] → [14, 18]
      expect(_of(results, 'hsc').value, const NumericalValue(2.5)); // [2, 3] both sides
      // OTT by weight: 57.8 % from 170-180 lb [9, 11] to 180-190 lb [11, 12], center 10.87.
      expect(_of(results, 'ott').value, const NumericalValue(10.9));
    });

    test('Diamond E3 reads its own column and a pressure-keyed open-ended row', () {
      final results = _evaluate(
        _real('fork/dvo.yaml', 'diamond/e3', {'damper': 'diamond_d3e3', 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 82, ridingStyle: GuideRidingStyle.race),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(98)); // E3 Firm 95 → 100 psi
      expect(_of(results, 'rebound').value, const StepValue(8)); // 98 psi: flat upper half of 90-100, [6, 10]
      expect(_of(results, 'compression').value, const NumericalValue(0)); // start fully open
    });

    test('Jade base tune applies per shock size', () {
      final results = _evaluate(
        _real('shock/dvo.yaml', 'jade/standard', {'damper': 'jade_coil', 'size': '215.9x63.5'}),
        inputs: weight,
      );
      expect(
        _of(results, 'bladder_pressure').value,
        const NumericalValue(185),
      ); // [180, 185] → [185, 190], center 185.19
      expect(_of(results, 'spring_rate').value, const NumericalValue(550)); // 180-200 lb, never interpolated
      expect(_of(results, 'rebound').value, const StepValue(30)); // [29, 32] → [28, 31], center 29.96
      expect(_of(results, 'hsc').value, const StepValue(6)); // [4, 6] → [6, 9], center 6.35
      expect(_of(results, 'lsc').value, const StepValue(5)); // [3, 5] → [5, 8], center 5.35
      final metric = _evaluate(
        _real('shock/dvo.yaml', 'jade/standard', {'damper': 'jade_coil', 'size': '250x70'}),
        inputs: weight,
      );
      expect(_of(metric, 'bladder_pressure').value, const NumericalValue(183)); // bladder chart 180 → 185
      expect(metric.where((result) => result.rule.target == 'spring_rate'), isEmpty); // no base tune
    });

    test('Topaz Pro and the WP CV shocks at 82 kg', () {
      final topaz = _evaluate(_real('shock/dvo.yaml', 'topaz/pro', {'damper': 'topaz_pro'}), inputs: weight);
      expect(_of(topaz, 'pressure').value, const NumericalValue(181)); // [165, 175] → [180, 200], center 180.78
      expect(_of(topaz, 'sag').value, const NumericalValue(25)); // 20-30 %
      final jadeWp = _evaluate(_real('shock/dvo.yaml', 'jade-x/wp-cv', {'damper': 'jade_x_wp_cv'}), inputs: weight);
      expect(_of(jadeWp, 'spring_rate').value, const NumericalValue(450)); // 80-100 kg
      expect(_of(jadeWp, 'hsc').value, const StepValue(4));
      expect(_of(jadeWp, 'lsc').value, const StepValue(6));
    });
  });

  group('Manitou catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/manitou.md:
    // 82 kg = 180.78 lb, 53.9 % of the way from the 160-180 lb midpoint (170)
    // to the 180-200 lb midpoint (190), and 3.9 % from the 180 lb to the 200 lb point.
    const weight = GuideInputs(riderWeight: 82);

    test('Mezzer G2 Pro at 82 kg', () {
      final results = _evaluate(
        _real('fork/manitou.yaml', 'mezzer/2026/pro', {'damper': 'mc2_pro_x_2026', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 82, ridingStyle: GuideRidingStyle.race),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(60)); // 55 → 64 psi
      expect(_of(results, 'pressure').basis, 'Manitou Mezzer G2 Pro & LT Pro set-up guide (2025) · 82 kg · interpolated');
      expect(_of(results, 'irt_pressure').value, const NumericalValue(90)); // 83 → 96 psi
      expect(_of(results, 'lsr').value, const StepValue(7)); // [7, 8] → [6, 7]
      expect(_of(results, 'hsr').value, const StepValue(5)); // [5, 7] → [4, 6]
      expect(_of(results, 'lsc').value, const StepValue(3)); // Firm Park [2, 4]
      expect(_of(results, 'hsc').value, const StepValue(3)); // Firm Park [2, 4]
    });

    test('Mattoc Comp reads IVA by travel and rebound as a clock position', () {
      final results = _evaluate(
        _real('fork/manitou.yaml', 'mattoc/comp', {'damper': 'abs_plus_2023', 'travel_mm': 130, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 82, ridingStyle: GuideRidingStyle.balanced),
      );
      expect(_of(results, 'pressure').value, const NumericalValue(75)); // 75 → 85 psi
      expect(_of(results, 'iva_position').value, const StepValue(2));
      expect(_of(results, 'rebound').value, CategoricalValue(const ["3 o'clock"])); // nearest point, 180 lb
      expect(_of(results, 'compression').value, const StepValue(4)); // Increased Support [3, 5]
    });

    test('a 100 kg rider is outside the Gen 1 Mezzer table, a coil spring is picked by bracket', () {
      final mezzer = _evaluate(
        _real('fork/manitou.yaml', 'mezzer/2019/pro', {'damper': 'mc2_mezzer_2019', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 100),
      );
      expect(_of(mezzer, 'pressure').issue, GuideIssue.outsideRange); // 220.5 lb, the left-out ">220" row
      expect(_of(mezzer, 'irt_pressure').issue, GuideIssue.outsideRange);
      final coil = _evaluate(
        _real('fork/manitou.yaml', 'dorado/comp-coil', {'damper': 'abs_plus_dorado_2022', 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(coil, 'spring_rate').value, const NumericalValue(40)); // 175-200 lb, Firm
    });
  });

  group('BOS catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/bos.md:
    // 82 kg lies 40 % of the way from the 80 kg to the 85 kg point.
    const weight = GuideInputs(riderWeight: 82);

    test('Kyll 39 Grabber at 180 mm', () {
      final results = _evaluate(
        _real('fork/bos.yaml', 'kyll-39/grabber', {'damper': 'grabber_2025', 'travel_mm': 180, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(201)); // 197 → 208 psi
      expect(_of(results, 'lsc').value, const StepValue(11));
      expect(_of(results, 'hsc').value, const StepValue(10));
      expect(_of(results, 'rebound').value, const StepValue(10));
      expect(_of(results, 'volume_spacers').value, const StepValue(1));
    });

    test('Obsys 42 at 82 kg; the Deville 35 has no guide', () {
      final obsys = _evaluate(
        _real('fork/bos.yaml', 'obsys-42/air', {'damper': 'obsys_2025', 'travel_mm': 200, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(obsys, 'pressure').value, const NumericalValue(198)); // 195 → 202 psi
      expect(_of(obsys, 'compression').value, const StepValue(20));
      expect(_of(obsys, 'rebound').value, const StepValue(13));
      final deville = _evaluate(
        _real('fork/bos.yaml', 'deville-35/grabber', {'damper': 'grabber_2025', 'travel_mm': 150, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(deville, isEmpty);
    });
  });

  group('DT Swiss catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/dtswiss.md:
    // 82 kg sits 40 % of the way from the 80 kg to the 85 kg row.
    const weight = GuideInputs(riderWeight: 82);

    test('F 535 ONE at 140 mm reads its rebound off the recommended pressure', () {
      final results = _evaluate(
        _real('fork/dtswiss.yaml', 'f-535-one/standard', {
          'damper': 'incontrol_odl_plushport_2023',
          'travel_mm': 140,
          'wheel_size': '29',
        }),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(75)); // 73 → 78 psi
      // 75 psi lies between the 67-77 (17) and 77-88 (18) psi midpoints: 17.29.
      expect(_of(results, 'rebound').value, const StepValue(17));
      expect(_of(results, 'compression').value, const StepValue(0));
      expect(_of(results, 'compression_mode').value, CategoricalValue(const ['Open']));
      expect(_of(results, 'volume_spacers').value, const StepValue(1));
    });

    test('F 535 and F 232 ONE take their own tables', () {
      final f535 = _evaluate(
        _real('fork/dtswiss.yaml', 'f-535/standard', {'damper': 'incontrol_ol_2023', 'travel_mm': 130, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(f535, 'pressure').value, const NumericalValue(75)); // 73 → 78 psi
      // 75 psi between the 61-71 (17) and 71-83 (18) psi midpoints: 17.82.
      expect(_of(f535, 'rebound').value, const StepValue(18));
      final f232 = _evaluate(
        _real('fork/dtswiss.yaml', 'f-232-one/standard', {
          'damper': 'incontrol_odl_232_2020',
          'travel_mm': 110,
          'wheel_size': '29',
        }),
        inputs: weight,
      );
      expect(_of(f232, 'pressure').value, const NumericalValue(89)); // 87 → 93 psi: 89.4
      expect(_of(f232, 'rebound').value, const StepValue(21)); // 87 psi 21, 94 psi 22
      expect(_of(f232, 'volume_spacers').value, const StepValue(2));
      expect(f232.where((result) => result.rule.target == 'compression'), isEmpty);
      final heavy = _evaluate(
        _real('fork/dtswiss.yaml', 'f-232-one/standard', {
          'damper': 'incontrol_odl_232_2020',
          'travel_mm': 110,
          'wheel_size': '29',
        }),
        inputs: const GuideInputs(riderWeight: 115),
      );
      expect(_of(heavy, 'pressure').issue, GuideIssue.outsideRange); // the table ends at 110 kg
    });

    test('R 535 ONE at 82 kg', () {
      final results = _evaluate(
        _real('shock/dtswiss.yaml', 'r-535-one/standard-mount', {'damper': 'r535_one_standard'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(258)); // 252 → 266 psi: 257.6
      expect(_of(results, 'compression_mode').value, CategoricalValue(const ['Open']));
      expect(_of(results, 'sag').value, const NumericalValue(27.5)); // midpoint of 20-35 %
      expect(results.where((result) => result.rule.target == 'rebound'), isEmpty);
    });
  });

  group('Formula catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/formula.md.
    test('Selva R and Nero R get one value per chamber', () {
      final selvaR = _evaluate(
        _real('fork/formula.yaml', 'selva/r', {'damper': 'selva_2017', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 82),
      );
      expect(_of(selvaR, 'main_chamber_pressure').value, const NumericalValue(82)); // 80 → 90 psi
      expect(_of(selvaR, 'negative_chamber_pressure').value, const NumericalValue(102)); // Silver + 20
      expect(_of(selvaR, 'neopos').value, const StepValue(1));
      final neroR = _evaluate(
        _real('fork/formula.yaml', 'nero/r', {'damper': 'nero_2017', 'travel_mm': 200, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 75),
      );
      expect(_of(neroR, 'progressivity_chamber_pressure').value, const NumericalValue(125)); // 120 → 130 psi
      expect(_of(neroR, 'main_chamber_pressure').value, const NumericalValue(95)); // 90 → 100 psi
      expect(_of(neroR, 'sensitivity_chamber_pressure').value, const NumericalValue(115)); // 110 → 120 psi
    });

    test('Selva V has no structured guide', () {
      final results = _evaluate(
        _real('fork/formula.yaml', 'selva/v', {'damper': 'selva_v_2025', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: const GuideInputs(riderWeight: 82),
      );
      expect(results, isEmpty);
    });

    test('Nebbia and MOD base tunes', () {
      final nebbia = _evaluate(
        _real('shock/formula.yaml', 'nebbia/air', {'damper': 'nebbia_2024'}),
        inputs: const GuideInputs(riderWeight: 85),
      );
      final pressure = _of(nebbia, 'pressure');
      expect(pressure.value, const NumericalValue(160)); // 80-90 kg: 150-170 psi
      expect(pressure.band!.min, 150);
      expect(pressure.band!.max, 170);
      expect(_of(nebbia, 'rebound').value, const StepValue(12));
      expect(_of(nebbia, 'compression').value, const StepValue(10));
      final mod = _evaluate(_real('shock/formula.yaml', 'mod-dh/coil', {'damper': 'mod_dh'}));
      expect(_of(mod, 'rebound').value, const StepValue(6));
      expect(_of(mod, 'compression').value, const StepValue(9));
      expect(_of(mod, 'sag').value, const NumericalValue(30));
    });
  });

  group('Cannondale catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/cannondale.md:
    // 82 kg = 180.78 lb, 7.8 % of the way from the 180 lb point to the 190 lb point.
    const weight = GuideInputs(riderWeight: 82);

    test('Lefty Ocho Carbon at 82 kg', () {
      final results = _evaluate(
        _real('fork/cannondale.yaml', 'lefty-ocho/carbon', {
          'damper': 'chamber_ocho_2018',
          'travel_mm': 100,
          'wheel_size': '29',
        }),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(144)); // 143 → 151 psi: 143.6
      expect(_of(results, 'rebound').value, const StepValue(7)); // 7 → 6 clicks out from closed: 6.9
      expect(_of(results, 'sag').value, const NumericalValue(25));
    });

    test('Lefty Oliver Carbon at 82 kg', () {
      final results = _evaluate(
        _real('fork/cannondale.yaml', 'lefty-oliver/carbon', {'damper': 'oliver', 'travel_mm': 30, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(97)); // 97 → 102 psi: 97.4
      expect(_of(results, 'rebound').value, const StepValue(7)); // 7 → 6: 6.9
      expect(_of(results, 'sag').value, const NumericalValue(0));
      expect(_of(results, 'volume_spacers').value, const StepValue(3));
    });

    test('Lefty 2.0 reads the column of its travel and wheel size', () {
      ResolvedPreset pbr(int travel, String wheel) => _real('fork/cannondale.yaml', 'lefty-2-0/pbr', {
        'damper': 'lefty_2_2016',
        'travel_mm': travel,
        'wheel_size': wheel,
      });
      // 100/29 column: 117 → 125 psi between 180 and 190 lb: 117.6.
      expect(_of(_evaluate(pbr(100, '29'), inputs: weight), 'pressure').value, const NumericalValue(118));
      // 50 kg = 110.2 lb, the "<120" row: a printed 65 psi on the 120/27.5 column.
      expect(
        _of(_evaluate(pbr(120, '27.5'), inputs: const GuideInputs(riderWeight: 50)), 'pressure').value,
        const NumericalValue(65),
      );
      // "<71" on the 100mm columns is a band to the 50 psi minimum.
      final light = _of(_evaluate(pbr(100, '27.5'), inputs: const GuideInputs(riderWeight: 50)), 'pressure');
      expect(light.band!.min, closeTo(50, 1e-6));
      expect(light.band!.max, closeTo(71, 1e-6));
      // 120mm on 29in wheels has no printed column; above 240 lb is left out.
      expect(_evaluate(pbr(120, '29'), inputs: weight).where((result) => result.rule.target == 'pressure'), isEmpty);
      expect(
        _of(_evaluate(pbr(100, '29'), inputs: const GuideInputs(riderWeight: 115)), 'pressure').issue,
        GuideIssue.outsideRange,
      );
    });
  });

  group('RST catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/rst.md:
    // 82 kg lies 60 % of the way from the 60-80 kg midpoint (70) to the
    // 80-100 kg midpoint (90).
    const weight = GuideInputs(riderWeight: 82);

    test('ROGUE V2 Air reads Table A', () {
      final rogue = _real('fork/rst.yaml', 'rogue-v2/air', {
        'damper': 'ocr2_plus_lockout',
        'travel_mm': 150,
        'wheel_size': '29',
      });
      final results = _evaluate(rogue, inputs: weight);
      expect(_of(results, 'pressure').value, const NumericalValue(82)); // [60, 80] → [80, 100]: [72, 92]
      expect(_of(results, 'sag').value, const NumericalValue(20)); // 15-25 %
      // 115 kg, the 110-120 kg bracket's midpoint: [120, 150].
      expect(
        _of(_evaluate(rogue, inputs: const GuideInputs(riderWeight: 115)), 'pressure').value,
        const NumericalValue(135),
      );
    });

    test('STITCH reads Table B without its misprinted last row', () {
      ResolvedPreset stitch(String trim) => _real('fork/rst.yaml', 'stitch/$trim', {
        'damper': 'ocrc_plus',
        'travel_mm': 170,
        'wheel_size': '27.5',
      });
      final air = _evaluate(stitch('air'), inputs: weight);
      expect(_of(air, 'pressure').value, const NumericalValue(56)); // [45, 55] → [55, 65]: [51, 61]
      expect(
        _of(_evaluate(stitch('air'), inputs: const GuideInputs(riderWeight: 110)), 'pressure').issue,
        GuideIssue.outsideRange,
      );
      final coil = _evaluate(stitch('coil'), inputs: weight);
      expect(coil.where((result) => result.rule.target == 'pressure'), isEmpty);
      expect(_of(coil, 'sag').value, const NumericalValue(20));
    });
  });

  group('SR Suntour catalog data', () {
    // Expected values are hand-computed from docs/research/setup_guides/suntour.md:
    // 80 kg is the 75-85 kg bracket's midpoint.
    const weight = GuideInputs(riderWeight: 80);

    test('AION 36 at 80 kg and 160mm', () {
      final results = _evaluate(
        _real('fork/suntour.yaml', 'aion-36/boost', {'damper': 'cr3_pcs', 'travel_mm': 160, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(95)); // [90, 100] psi
      expect(_of(results, 'sag').value, const NumericalValue(25)); // 160mm sits in 25-30 % and 20-25 %: 20-30 %
      expect(_of(results, 'volume_spacers').value, const StepValue(3)); // factory setting
    });

    test('AION 38X takes the spacer row of its wheel size, the 38mm columns start at 55 kg', () {
      ResolvedPreset aion(String wheel, int travel) => _real('fork/suntour.yaml', 'aion-38x/boost', {
        'damper': 'cr2_pcs',
        'travel_mm': travel,
        'wheel_size': wheel,
      });
      expect(_of(_evaluate(aion('29', 170)), 'volume_spacers').value, const StepValue(3));
      expect(_of(_evaluate(aion('27.5', 170)), 'volume_spacers').value, const StepValue(1));
      expect(_of(_evaluate(aion('27.5', 180)), 'volume_spacers').issue, GuideIssue.outsideRange);
      expect(_of(_evaluate(aion('29', 170), inputs: weight), 'pressure').value, const NumericalValue(65)); // [60, 70]
      expect(
        _of(_evaluate(aion('29', 170), inputs: const GuideInputs(riderWeight: 50)), 'pressure').issue,
        GuideIssue.outsideRange,
      );
      expect(_of(_evaluate(aion('29', 170)), 'sag').value, const NumericalValue(27.5)); // 25-30 %
    });

    test('AXON 34 Elite gets the Werx spacer row', () {
      final results = _evaluate(
        _real('fork/suntour.yaml', 'axon-34-werx/elite', {'damper': 'rlrc_pcs', 'travel_mm': 120, 'wheel_size': '29'}),
        inputs: weight,
      );
      expect(_of(results, 'pressure').value, const NumericalValue(80)); // [75, 85] psi
      expect(_of(results, 'volume_spacers').value, const StepValue(3));
    });

    test('EDGE Evo SAG follows the stroke', () {
      ResolvedPreset edge(String size) =>
          _real('shock/suntour.yaml', 'edge-evo/2cr', {'damper': 'edge_2cr', 'size': size});
      expect(_of(_evaluate(edge('230x60')), 'sag').value, const NumericalValue(30)); // 25-35 %
      // 52.5mm lies halfway between 50mm (20-25 %) and 55mm (25-30 %): 22.5-27.5 %.
      expect(_of(_evaluate(edge('210x52.5')), 'sag').value, const NumericalValue(25));
      final short = _real('shock/suntour.yaml', 'edge-x/r', {'damper': 'edge_r', 'size': '170x27.5'});
      expect(_of(_evaluate(short), 'sag').issue, GuideIssue.outsideRange);
    });
  });
}

ResolvedPreset _real(String file, String path, Map<String, Object> options) {
  final yaml = File(p.join('data', 'component_presets', file)).readAsStringSync();
  var preset = catalogProducts(
    parseCatalogFile(yaml),
  ).firstWhere((preset) => preset.path.map((node) => node.id).join('/') == path);
  for (final MapEntry(key: axisId, value: valueId) in options.entries) {
    final axis = preset.axes.firstWhere((axis) => axis.id == axisId);
    preset = preset.select(axis, axis.values.firstWhere((value) => value.id == valueId));
  }
  return preset;
}
