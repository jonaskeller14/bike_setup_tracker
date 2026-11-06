import 'package:bike_setup_tracker/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeatherService rate limits after 12 requests', () async {
    final service = WeatherService();
    // A future date is rejected after the rate limit counted it, before any network call.
    // counter: 3 skips the retries, so each call counts once and returns at once.
    final future = DateTime.now().add(const Duration(days: 1));

    for (var i = 1; i <= WeatherService.maxRequestsPerHour; i++) {
      await service.fetchWeather(lat: 48.0, lon: 7.0, datetime: future, counter: 3);
      expect((service.status as WeatherError).kind, WeatherErrorKind.failed);
    }

    final weather = await service.fetchWeather(lat: 48.0, lon: 7.0, datetime: future, counter: 3);

    expect(weather, isNull);
    expect(service.status, isA<WeatherError>());
    expect((service.status as WeatherError).kind, WeatherErrorKind.rateLimit);
  });
}
