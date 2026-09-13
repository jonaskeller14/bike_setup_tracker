import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON guard for the dial style (color + size) stored on StepAdjustment.
///
/// v2 added `dialColor`/`dialSize`. v1 payloads predate the fields and must
/// still load, falling back to the defaults the dial has always been drawn in.
void main() {
  StepAdjustment build({
    StepAdjustmentDialColor dialColor = StepAdjustmentDialColor.blue,
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
    test('defaults to blue at normal size', () {
      final adjustment = build();
      expect(adjustment.dialColor, StepAdjustmentDialColor.blue);
      expect(adjustment.dialSize, StepAdjustmentDialSize.normal);
    });

    test('toJson writes the enum names', () {
      final json = build(
        dialColor: StepAdjustmentDialColor.green,
        dialSize: StepAdjustmentDialSize.small,
      ).toJson();
      expect(json['dialColor'], 'green');
      expect(json['dialSize'], 'small');
    });

    test('round-trips through toJson/fromJson', () {
      final original = build(
        dialColor: StepAdjustmentDialColor.grey,
        dialSize: StepAdjustmentDialSize.small,
      );
      expect(StepAdjustment.fromJson(original.toJson()), equals(original));
    });

    test('deepCopy keeps the dial style', () {
      final copy = build(
        dialColor: StepAdjustmentDialColor.brown,
        dialSize: StepAdjustmentDialSize.small,
      ).deepCopy();
      expect(copy.dialColor, StepAdjustmentDialColor.brown);
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
      expect(restored.dialColor, StepAdjustmentDialColor.blue);
      expect(restored.dialSize, StepAdjustmentDialSize.normal);
    });

    test('an unknown dial color falls back to blue', () {
      final json = build().toJson()..['dialColor'] = 'turquoise';
      expect(StepAdjustment.fromJson(json).dialColor, StepAdjustmentDialColor.blue);
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
