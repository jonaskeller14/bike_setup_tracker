import 'package:bike_setup_tracker/models/component/year_span.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParse', () {
    test('reads a single year and an ascending range', () {
      expect(YearSpan.tryParse('2026'), const YearSpan(2026, 2026));
      expect(YearSpan.tryParse('2021-2025'), const YearSpan(2021, 2025));
    });

    test('rejects every other format', () {
      for (final text in ['2025–2026', '2025 - 2026', '2026-2025', '25-26', '2025-', '2025-2026-2027', 'n/a', '']) {
        expect(YearSpan.tryParse(text), isNull, reason: text);
      }
    });
  });

  test('contains is inclusive on both ends', () {
    const span = YearSpan(2021, 2025);
    expect([2020, 2021, 2025, 2026].map(span.contains), [false, true, true, false]);
  });

  test('cover spans the earliest to the latest year', () {
    expect(YearSpan.cover(const [YearSpan(2024, 2026), YearSpan(2019, 2020)]), const YearSpan(2019, 2026));
    expect(YearSpan.cover(const []), isNull);
  });

  test('toString is the ASCII form of the data files', () {
    expect(const YearSpan(2026, 2026).toString(), '2026');
    expect(const YearSpan(2021, 2025).toString(), '2021-2025');
  });
}
