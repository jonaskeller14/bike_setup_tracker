import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/utils/adjustment_role.dart';
import 'package:flutter_test/flutter_test.dart';

/// [adjustmentRole] names what an adjustment is in the catalog's id space, so a
/// guide rule finds its adjuster whether it came from the catalog, a template
/// or the rider's own hands.

StepAdjustment _step(String name, {String? presetKey}) => StepAdjustment(
  name: name,
  notes: null,
  unit: null,
  presetKey: presetKey,
  step: 1,
  min: 0,
  max: 10,
  visualization: StepAdjustmentVisualization.slider,
);

void main() {
  group('adjustmentRole', () {
    test('a catalog-built adjustment keeps its role after a rename', () {
      final adjustment = _step('Rebound (slow)', presetKey: 'fork:lsr');

      expect(adjustmentRole(adjustment), 'lsr');
    });

    test('a template-built adjustment resolves through its preset key without the prefix', () {
      expect(adjustmentRole(_step('Renamed', presetKey: 'fork:hsc')), 'hsc');
      expect(adjustmentRole(_step('Volume', presetKey: 'shock:volume_spacers')), 'volume_spacers');
    });

    test('a hand-built adjustment falls back to the slug of its name', () {
      expect(adjustmentRole(_step('Volume Spacers')), 'volume_spacers');
      expect(adjustmentRole(_step('  HSC ')), 'hsc');
    });

    test('a name without letters or digits has no role', () {
      expect(adjustmentRole(_step('—')), isNull);
    });

    test('a preset key without a prefix is used as is', () {
      expect(adjustmentRole(_step('x', presetKey: 'pressure')), 'pressure');
    });
  });
}
