import 'package:bike_setup_tracker/widgets/items/task_rule_display_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('taskForecastDueLabel', () {
    final now = DateTime(2026, 9, 9, 14, 30);

    String label(DateTime due) => taskForecastDueLabel(due, now, 'yyyy-MM-dd');

    test('reads as today for the rest of the current day', () {
      expect(label(DateTime(2026, 9, 9, 23, 59)), 'today');
    });

    test('reads as tomorrow across the day boundary, not "in 0 days"', () {
      expect(label(DateTime(2026, 9, 10, 0, 5)), 'tomorrow');
    });

    test('counts days while the estimate is close enough to plan around', () {
      expect(label(DateTime(2026, 9, 12)), 'in 3 days');
      expect(label(DateTime(2026, 9, 22)), 'in 13 days');
    });

    test('switches to whole weeks past the two-week mark', () {
      expect(label(DateTime(2026, 9, 23)), 'in 2 weeks');
      expect(label(DateTime(2026, 11, 3)), 'in 7 weeks');
    });

    test('switches to an absolute date once counting stops helping', () {
      expect(label(DateTime(2026, 11, 4)), '2026-11-04');
    });

    test('honours the configured date format', () {
      expect(
        taskForecastDueLabel(DateTime(2026, 11, 4), now, 'dd.MM.yyyy'),
        '04.11.2026',
      );
    });

    test('never counts backwards for a date that slipped into the past', () {
      expect(label(DateTime(2026, 9, 8)), 'today');
    });
  });
}
