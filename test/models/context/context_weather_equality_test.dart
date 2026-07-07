import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the Weather/Condition chip highlighting split on the Setup and
/// Rating pages: the two chips must react to disjoint sets of changes.
/// [ContextWeather.withoutCondition] normalizes the condition fields so
/// pages can compare "everything but condition" without the condition
/// itself (or whether it was set manually) leaking into that comparison.
void main() {
  final baseline = ContextWeather(
    currentDateTime: DateTime(2026, 1, 1, 12),
    currentTemperature: 10,
    currentWeatherCode: 1,
    currentHumidity: 50,
    currentWindSpeed: 5,
    currentPrecipitation: 0,
    currentSoilMoisture0to7cm: 0.15, // resolves to Condition.moist
    dayAccumulatedPrecipitation: 0,
    currentIsDay: true,
  );

  group('ContextWeather — condition set manually', () {
    test('withoutCondition() stays equal, so the weather chip is not flagged', () {
      final manuallySet = baseline.copyWith(condition: Condition.muddy, conditionManuallySet: true);

      expect(manuallySet.condition, isNot(baseline.condition));
      expect(manuallySet.withoutCondition(), equals(baseline.withoutCondition()));
    });
  });

  group('ContextWeather — weather data edited', () {
    test('withoutCondition() differs, so the weather chip is flagged, while condition chip stays unaffected', () {
      final edited = baseline.copyWith(currentTemperature: 22.0);

      expect(edited.condition, equals(baseline.condition));
      expect(edited.withoutCondition(), isNot(equals(baseline.withoutCondition())));
    });
  });
}
