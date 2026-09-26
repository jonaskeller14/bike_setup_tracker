import 'package:bike_setup_tracker/screenshots/sample_date_shift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sampleShiftDays', () {
    test('lands the newest date the given days before today', () {
      final json = {
        'setups': [
          {'datetime': '2026-06-08T16:05:00.000Z'},
          {'datetime': '2026-05-01T12:50:00.000Z'},
        ],
      };

      expect(sampleShiftDays(json, today: DateTime(2026, 6, 10)), 1);
      expect(sampleShiftDays(json, today: DateTime(2026, 6, 10), daysBeforeToday: 0), 2);
    });

    test('considers dates in any field, with or without Z', () {
      final json = {
        'setups': [
          {'lastModified': '2026-06-01T18:00:00.000Z'},
        ],
        'taskEntries': [
          {'dateTimeLocal': '2026-06-20T10:00:00.000'},
        ],
      };

      expect(sampleShiftDays(json, today: DateTime(2026, 9, 26)), 97);
    });

    test('ignores the epoch sentinel and non-date strings', () {
      final json = {
        'installations': [
          {'dateTimeUTC': '1970-01-01T00:00:00.000Z', 'name': '2026-12-31 notes'},
          {'dateTimeUTC': '2026-06-01T08:00:00.000Z'},
        ],
      };

      expect(sampleShiftDays(json, today: DateTime(2026, 6, 3)), 1);
    });

    test('returns 0 without any dates', () {
      expect(sampleShiftDays({'name': 'x'}, today: DateTime(2026, 6, 3)), 0);
    });
  });

  group('shiftSampleDates', () {
    test('keeps wall-clock time and format for UTC and local strings', () {
      final shifted =
          shiftSampleDates({
                'datetime': '2026-05-01T12:50:00.000Z',
                'datetimeLocal': '2026-05-01T14:50:00.000',
              }, 150)
              as Map<String, dynamic>;

      // Crosses the end of CEST: both strings still keep their time of day.
      expect(shifted['datetime'], '2026-09-28T12:50:00.000Z');
      expect(shifted['datetimeLocal'], '2026-09-28T14:50:00.000');
    });

    test('shifts nested lists and maps and leaves other values alone', () {
      final shifted =
          shiftSampleDates({
                'setups': [
                  {
                    'name': 'Hometrails',
                    'weather': {'currentDateTime': '2026-05-01T14:50:00.000', 'currentTemperature': 18.4},
                    'tags': ['Dry'],
                    'isDeleted': false,
                    'notes': null,
                  },
                ],
              }, 3)
              as Map<String, dynamic>;

      expect(shifted, {
        'setups': [
          {
            'name': 'Hometrails',
            'weather': {'currentDateTime': '2026-05-04T14:50:00.000', 'currentTemperature': 18.4},
            'tags': ['Dry'],
            'isDeleted': false,
            'notes': null,
          },
        ],
      });
    });

    test('leaves the epoch sentinel untouched', () {
      final shifted = shiftSampleDates({
        'dateTimeUTC': '1970-01-01T00:00:00.000Z',
        'dateTimeLocal': '1970-01-01T01:00:00.000',
      }, 42);

      expect(shifted, {
        'dateTimeUTC': '1970-01-01T00:00:00.000Z',
        'dateTimeLocal': '1970-01-01T01:00:00.000',
      });
    });

    test('shifts backwards across a month boundary', () {
      expect(shiftSampleDates('2026-03-02T09:00:00.000Z', -3), '2026-02-27T09:00:00.000Z');
    });
  });
}
