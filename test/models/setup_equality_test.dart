import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
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
      'images': <String>[],
    };

    test('independently decoded setups with equal categorical values are equal', () {
      final a = Setup.fromJson(json: setupJson());
      final b = Setup.fromJson(json: setupJson());

      expect(identical(a.bikeAdjustmentValues['cat'], b.bikeAdjustmentValues['cat']), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('setups with different categorical values are not equal', () {
      final a = Setup.fromJson(json: setupJson());
      final b = Setup.fromJson(json: setupJson(categorical: ['Rear']));

      expect(a, isNot(b));
    });

    test('categorical order matters', () {
      final a = Setup.fromJson(json: setupJson(categorical: ['A', 'B']));
      final b = Setup.fromJson(json: setupJson(categorical: ['B', 'A']));

      expect(a, isNot(b));
    });
  });

  group('RatingEntry equality', () {
    Map<String, dynamic> entryJson({List<String> categorical = const ['Front']}) => {
      'version': 1,
      'id': 'r1',
      'isDeleted': false,
      'lastModified': '2026-09-27T10:00:00.000Z',
      'bike': 'b1',
      'setupId': 's1',
      'dateTimeUTC': '2026-09-27T09:00:00.000Z',
      'dateTimeLocal': '2026-09-27T11:00:00.000',
      'metricValues': {'cat': categorical, 'score': 4},
    };

    test('independently decoded entries with equal categorical values are equal', () {
      final a = RatingEntry.fromJson(json: entryJson());
      final b = RatingEntry.fromJson(json: entryJson());

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('entries with different categorical values are not equal', () {
      final a = RatingEntry.fromJson(json: entryJson());
      final b = RatingEntry.fromJson(json: entryJson(categorical: ['Rear']));

      expect(a, isNot(b));
    });
  });
}
