import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

/// A catalog step adjuster whose range the manufacturer does not publish is
/// authored as `max: ~`. `fromYaml` substitutes a placeholder and says so in
/// the notes, so a guessed number never looks like a sourced one.
void main() {
  group('StepAdjustment.fromYaml with an unknown max', () {
    test('a null max becomes the placeholder with a warning as notes', () {
      final adjustment = StepAdjustment.fromYaml(const {
        'name': 'HSC',
        'type': 'step',
        'max': null,
      });

      expect(adjustment.min, 0);
      expect(adjustment.max, StepAdjustment.unknownMaxPlaceholder);
      expect(adjustment.notes, StepAdjustment.unknownMaxWarning);
    });

    test('the warning is appended to authored notes', () {
      final adjustment = StepAdjustment.fromYaml(const {
        'name': 'HSC',
        'type': 'step',
        'max': null,
        'notes': 'High-Speed Compression',
      });

      expect(
        adjustment.notes,
        'High-Speed Compression; ${StepAdjustment.unknownMaxWarning}',
      );
    });

    test('an explicit min of 0 is accepted', () {
      final adjustment = StepAdjustment.fromYaml(const {
        'name': 'Rebound',
        'type': 'step',
        'min': 0,
        'max': null,
      });

      expect(adjustment.max, StepAdjustment.unknownMaxPlaceholder);
    });

    test('a non-zero min throws, a from-middle range has no placeholder', () {
      expect(
        () => StepAdjustment.fromYaml(const {
          'name': 'LSC',
          'type': 'step',
          'min': -7,
          'max': null,
        }),
        throwsArgumentError,
      );
    });

    test('an absent max key still throws', () {
      expect(
        () => StepAdjustment.fromYaml(const {'name': 'HSC', 'type': 'step'}),
        throwsArgumentError,
      );
    });

    test('a published max is left alone', () {
      final adjustment = StepAdjustment.fromYaml(const {
        'name': 'HSC',
        'type': 'step',
        'max': 8,
        'notes': 'High-Speed Compression',
      });

      expect(adjustment.max, 8);
      expect(adjustment.notes, 'High-Speed Compression');
    });

    test('is reached through Adjustment.fromYaml', () {
      final adjustment = Adjustment.fromYaml({
        'name': 'HSC',
        'type': 'step',
        'max': null,
      });

      expect(adjustment, isA<StepAdjustment>());
      expect((adjustment as StepAdjustment).max, StepAdjustment.unknownMaxPlaceholder);
    });
  });
}
