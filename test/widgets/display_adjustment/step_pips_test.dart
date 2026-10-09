import 'package:bike_setup_tracker/widgets/display_adjustment/step_pips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepPips.fitsPips', () {
    test('draws pips while each stays at least the minimum width', () {
      // 12 pips and 11 gaps of 2: (70 - 22) / 12 = 4.
      expect(StepPips.fitsPips(70, 12), isTrue);
      expect(StepPips.fitsPips(69, 12), isFalse);
    });

    test('falls back to a bar for a wide range in a narrow column', () {
      expect(StepPips.fitsPips(150, 50), isFalse);
      expect(StepPips.fitsPips(400, 50), isTrue);
    });

    test('has no pips for a range without steps', () {
      expect(StepPips.fitsPips(150, 0), isFalse);
    });
  });
}
