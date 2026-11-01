import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:bike_setup_tracker/services/weather_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  late AppSettings settings;

  setUp(() => settings = AppSettings());
  tearDown(() => settings.dispose());

  testWidgets('pre-fills German values with a decimal comma', (tester) async {
    final selectedDateTime = DateTime(2026, 10, 30);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: localizedTestApp(
          locale: const Locale('de'),
          theme: materialAppTheme,
          home: Scaffold(
            body: SetWeatherSheetContent(
              weatherService: WeatherService(),
              locationService: LocationService(),
              currentLocation: null,
              selectedDateTime: selectedDateTime,
              currentWeather: ContextWeather(
                currentDateTime: selectedDateTime,
                currentTemperature: 12.5,
                dayAccumulatedPrecipitation: 1.5,
                currentHumidity: 55.5,
                currentWindSpeed: 7.5,
                currentSoilMoisture0to7cm: 0.35,
              ),
            ),
          ),
        ),
      ),
    );

    for (final text in ['12,5', '1,5', '55,5', '7,5', '0,35']) {
      expect(find.widgetWithText(TextFormField, text), findsOneWidget, reason: text);
    }
  });
}
