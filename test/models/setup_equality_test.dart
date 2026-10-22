import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Setup equality', () {
    Map<String, dynamic> setupJson({List<String> categorical = const ['Front']}) => {
      'version': 7,
      'id': 's1',
      'isDeleted': false,
      'lastModified': '2026-09-27T10:00:00.000Z',
      'datetime': '2026-09-27T09:00:00.000Z',
      'datetimeLocal': '2026-09-27T11:00:00.000',
      'tags': ['race'],
      'bike': 'b1',
      'person': 'p1',
      'bikeAdjustmentValues': {'cat': categorical, 'step': 3, 'dur': '0:01:30.000000'},
      'personAdjustmentValues': {
        'multi': ['A', 'B'],
      },
      'attachments': <Map<String, dynamic>>[],
    };
    const adjustmentTypes = {
      'cat': AdjustmentType.categorical,
      'step': AdjustmentType.step,
      'dur': AdjustmentType.duration,
      'multi': AdjustmentType.categorical,
    };
    Setup decode(Map<String, dynamic> json) => Setup.fromJson(json: json, adjustmentTypes: adjustmentTypes);

    test('independently decoded setups with equal categorical values are equal', () {
      final a = decode(setupJson());
      final b = decode(setupJson());

      expect(a.bikeAdjustmentValues['cat'], isA<CategoricalValue>());
      expect(identical(a.bikeAdjustmentValues['cat'], b.bikeAdjustmentValues['cat']), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('setups with different categorical values are not equal', () {
      final a = decode(setupJson());
      final b = decode(setupJson(categorical: ['Rear']));

      expect(a, isNot(b));
    });

    test('categorical order matters', () {
      final a = decode(setupJson(categorical: ['A', 'B']));
      final b = decode(setupJson(categorical: ['B', 'A']));

      expect(a, isNot(b));
    });
  });
}
