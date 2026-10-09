import 'package:bike_setup_tracker/widgets/component_stats_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  final fmt = NumberFormat.decimalPattern('en');

  group('ComponentStatsBar.formatDuration', () {
    test('keeps minutes below 100 hours', () {
      expect(ComponentStatsBar.formatDuration(const Duration(hours: 99, minutes: 59), fmt), '99h 59m');
    });

    test('drops minutes from 100 hours on', () {
      expect(ComponentStatsBar.formatDuration(const Duration(hours: 100, minutes: 30), fmt), '100h');
      expect(ComponentStatsBar.formatDuration(const Duration(hours: 1234, minutes: 5), fmt), '1,234h');
    });
  });

  group('ComponentStatsBar.formatAmount', () {
    test('uses grouped digits below 100,000', () {
      expect(ComponentStatsBar.formatAmount(99999.4, fmt), '99,999');
    });

    test('compacts from 100,000 on', () {
      expect(ComponentStatsBar.formatAmount(100000, fmt), '100K');
      expect(ComponentStatsBar.formatAmount(123456, fmt), '123K');
    });
  });
}
