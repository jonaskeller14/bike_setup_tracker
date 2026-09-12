import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON guard for the dial style (color + size) stored on StepAdjustment.
///
/// v2 added `dialColor`/`dialSize`. v1 payloads predate the fields and must
/// still load, falling back to the defaults the dial has always been drawn in.
void main() {
  StepAdjustment build({
    StepAdjustmentDialColor dialColor = StepAdjustmentDialColor.primary,
    StepAdjustmentDialSize dialSize = StepAdjustmentDialSize.normal,
  }) =>
      StepAdjustment(
        id: 'adj1',
        name: 'Rebound',
        notes: null,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        dialColor: dialColor,
        dialSize: dialSize,
      );

  group('StepAdjustment dial style', () {
    test('defaults to the primary color at normal size', () {
      final adjustment = build();
      expect(adjustment.dialColor, StepAdjustmentDialColor.primary);
      expect(adjustment.dialSize, StepAdjustmentDialSize.normal);
    });

    test('toJson writes the enum names', () {
      final json = build(
        dialColor: StepAdjustmentDialColor.accent3,
        dialSize: StepAdjustmentDialSize.small,
      ).toJson();
      expect(json['dialColor'], 'accent3');
      expect(json['dialSize'], 'small');
    });

    test('round-trips through toJson/fromJson', () {
      final original = build(
        dialColor: StepAdjustmentDialColor.accent5,
        dialSize: StepAdjustmentDialSize.small,
      );
      expect(StepAdjustment.fromJson(original.toJson()), equals(original));
    });

    test('deepCopy keeps the dial style', () {
      final copy = build(
        dialColor: StepAdjustmentDialColor.accent2,
        dialSize: StepAdjustmentDialSize.small,
      ).deepCopy();
      expect(copy.dialColor, StepAdjustmentDialColor.accent2);
      expect(copy.dialSize, StepAdjustmentDialSize.small);
    });

    test('a v1 payload without dial fields falls back to the defaults', () {
      final restored = StepAdjustment.fromJson({
        'version': 1,
        'id': 'adj1',
        'name': 'Rebound',
        'notes': null,
        'type': AdjustmentType.step.name,
        'unit': null,
        'min': 0,
        'max': 20,
        'step': 1,
        'visualization': StepAdjustmentVisualization.slider.toString(),
      });
      expect(restored.dialColor, StepAdjustmentDialColor.primary);
      expect(restored.dialSize, StepAdjustmentDialSize.normal);
    });

    test('an unknown dial color falls back to primary', () {
      final json = build().toJson()..['dialColor'] = 'accent42';
      expect(StepAdjustment.fromJson(json).dialColor, StepAdjustmentDialColor.primary);
    });
  });

  group('StepAdjustmentVisualization', () {
    test('hasDial only for the dial variants', () {
      expect(StepAdjustmentVisualization.slider.hasDial, isFalse);
      expect(StepAdjustmentVisualization.minusButtonValuePlusButton.hasDial, isFalse);
      expect(StepAdjustmentVisualization.sliderWithClockwiseDial.hasDial, isTrue);
      expect(StepAdjustmentVisualization.sliderWithCounterclockwiseDial.hasDial, isTrue);
      expect(StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial.hasDial, isTrue);
      expect(StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial.hasDial, isTrue);
    });

    test('isClockwiseDial only for the clockwise variants', () {
      expect(StepAdjustmentVisualization.sliderWithClockwiseDial.isClockwiseDial, isTrue);
      expect(StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial.isClockwiseDial, isTrue);
      expect(StepAdjustmentVisualization.sliderWithCounterclockwiseDial.isClockwiseDial, isFalse);
      expect(StepAdjustmentVisualization.slider.isClockwiseDial, isFalse);
    });
  });
}
