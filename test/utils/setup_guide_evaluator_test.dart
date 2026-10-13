import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

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
    test('step values round to the nearest click and are capped', () {
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
      expect(lsr.value, const StepValue(10));
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
      expect(pressure(weight: 85, now: 86).deviation!.onGuide, isFalse);
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
}
