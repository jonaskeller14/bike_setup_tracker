import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/utils/adjustment_preset_consumption.dart';
import 'package:flutter_test/flutter_test.dart';

NumericalAdjustment pressure({required String name, String? presetKey}) => NumericalAdjustment(
      name: name,
      notes: null,
      unit: AdjustmentUnit.fromLegacy("psi"),
      presetKey: presetKey,
    );

void main() {
  group('isAdjustmentPresetConsumed', () {
    final preset = pressure(name: "Pressure", presetKey: "fork:pressure");

    test('no adjustments means nothing is consumed', () {
      expect(isAdjustmentPresetConsumed(preset, const []), isFalse);
    });

    test('an adjustment added from the preset consumes it', () {
      // The adjustment pages drop presetKey when saving, so the stored
      // adjustment usually carries none.
      expect(isAdjustmentPresetConsumed(preset, [pressure(name: "Pressure")]), isTrue);
    });

    test('name match ignores case and surrounding whitespace', () {
      expect(isAdjustmentPresetConsumed(preset, [pressure(name: "  pressure ")]), isTrue);
    });

    test('a renamed adjustment leaves the preset available', () {
      expect(isAdjustmentPresetConsumed(preset, [pressure(name: "Air Pressure", presetKey: "fork:pressure")]), isFalse);
    });

    test('a same-named adjustment from another preset does not consume it', () {
      expect(isAdjustmentPresetConsumed(preset, [pressure(name: "Pressure", presetKey: "shock:pressure")]), isFalse);
    });

    test('matching presetKey and name consumes it', () {
      expect(isAdjustmentPresetConsumed(preset, [pressure(name: "Pressure", presetKey: "fork:pressure")]), isTrue);
    });

    test('only the matching preset in a longer list is consumed', () {
      final existing = [pressure(name: "Pressure"), pressure(name: "Rebound")];
      expect(isAdjustmentPresetConsumed(preset, existing), isTrue);
      expect(isAdjustmentPresetConsumed(pressure(name: "SAG", presetKey: "fork:sag"), existing), isFalse);
    });
  });
}
