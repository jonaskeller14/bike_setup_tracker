import 'package:bike_setup_tracker/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeatherService rate limits after 12 requests', () async {
    final service = WeatherService();

    // Make 12 requests (they will likely fail with a network error, but that's fine for testing the rate limit)
    for (var i = 1; i <= 12; i++) {
      // ignore: b
      await service.fetchWeather(
        lat: 48.0, 
        lon: 7.0, 
        datetime: DateTime.now().subtract(const Duration(days: 1)),
      );
    }

    // The 13th request should be rate limited
    final weather = await service.fetchWeather(
      lat: 48.0, 
      lon: 7.0, 
      datetime: DateTime.now().subtract(const Duration(days: 1)),
    );

    expect(weather, isNull);
    expect(service.status, isA<WeatherError>());
    expect(service.errorMessage, contains("Rate limit exceeded"));
  });
}
