import 'package:bike_setup_tracker/utils/slider_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sliderBounds', () {
    test('rounds the data max up to the next round step', () {
      expect(sliderBounds(143, fallbackMax: 150), (max: 145.0, step: 5.0));
      expect(sliderBounds(1840, fallbackMax: 3000), (max: 1850.0, step: 50.0));
      expect(sliderBounds(23.4, fallbackMax: 150), (max: 24.0, step: 1.0));
    });

    test('keeps a max that already is a multiple of the step', () {
      expect(sliderBounds(150, fallbackMax: 100), (max: 150.0, step: 5.0));
      expect(sliderBounds(3000, fallbackMax: 100), (max: 3000.0, step: 100.0));
    });

    test('uses the fallback without data', () {
      expect(sliderBounds(null, fallbackMax: 150), (max: 150.0, step: 5.0));
      expect(sliderBounds(0, fallbackMax: 3000), (max: 3000.0, step: 100.0));
      expect(sliderBounds(null, fallbackMax: 100), (max: 100.0, step: 5.0));
      expect(sliderBounds(null, fallbackMax: 10000), (max: 10000.0, step: 500.0));
    });

    test('never exceeds the division budget and always covers the data', () {
      for (final dataMax in [0.3, 7.0, 41.0, 81.0, 99.9, 401.0, 2345.6, 98765.0]) {
        final bounds = sliderBounds(dataMax, fallbackMax: 150);
        final divisions = (bounds.max / bounds.step).round();
        expect(divisions, inInclusiveRange(1, 40), reason: '$dataMax');
        expect(bounds.max, greaterThanOrEqualTo(dataMax), reason: '$dataMax');
      }
    });
  });
}
