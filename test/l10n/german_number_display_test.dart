import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:bike_setup_tracker/services/weather_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/table_column.dart';
import 'package:bike_setup_tracker/widgets/display_data/setup_line_chart.dart';
import 'package:bike_setup_tracker/widgets/items/context_location_weather_card.dart';
import 'package:bike_setup_tracker/widgets/items/context_location_weather_card_diff.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';

/// Number text that only shares the tested `formatLocalizedDouble` helper: a
/// German screen must show a decimal comma wherever it formats a number.
void main() {
  const de = Locale('de');
  late AppSettings settings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = AppSettings();
  });

  tearDown(() {
    settings.dispose();
  });

  Widget app(Widget home) => ChangeNotifierProvider.value(
    value: settings,
    child: localizedTestApp(theme: materialAppTheme, locale: de, home: home),
  );

  Future<void> expandAll(WidgetTester tester) async {
    for (var i = 0; i < tester.widgetList(find.byType(ExpansionTile)).length; i++) {
      // The title is selectable text and swallows the tap, so tap the icon.
      final icon = find.descendant(of: find.byType(ExpansionTile).at(i), matching: find.byType(Icon)).first;
      await tester.ensureVisible(icon);
      await tester.tap(icon);
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  final weather = ContextWeather(
    currentDateTime: DateTime(2026, 10, 30),
    currentTemperature: 12.5,
    currentHumidity: 55,
    currentWindSpeed: 7,
    currentSoilMoisture0to7cm: 0.35,
  );
  const position = ContextPosition(latitude: 52.52, longitude: 13.405, altitude: 34);

  testWidgets('the weather card shows coordinates and soil moisture with a comma', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(
            child: ContextLocationWeatherCard(
              position: position,
              place: null,
              displayName: 'Setup',
              mapPin: const Icon(Icons.pin),
              weather: weather,
              onViewOnMap: null,
            ),
          ),
        ),
      ),
    );

    await expandAll(tester);

    expect(find.textContaining('0,35 m³/m³', findRichText: true), findsOneWidget);
    expect(find.textContaining('52,5200', findRichText: true), findsOneWidget);
    expect(find.textContaining('52.52', findRichText: true), findsNothing);
  });

  testWidgets('the weather comparison shows coordinates and soil moisture with a comma', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(
            child: ContextLocationWeatherCardDiff(
              positionA: position,
              placeA: null,
              weatherA: weather,
              displayNameA: 'A',
              positionB: position.copyWith(latitude: 48.1374),
              placeB: null,
              weatherB: weather.copyWith(currentSoilMoisture0to7cm: 0.4),
              displayNameB: 'B',
              onViewOnMap: null,
            ),
          ),
        ),
      ),
    );

    await expandAll(tester);

    expect(find.textContaining('0,35 m³/m³', findRichText: true), findsOneWidget);
    expect(find.textContaining('0,40 m³/m³', findRichText: true), findsOneWidget);
    expect(find.textContaining('48,1374', findRichText: true), findsOneWidget);
  });

  testWidgets('a value typed with a comma in the weather sheet is saved as a number', (tester) async {
    ContextWeather? saved;
    final selectedDateTime = DateTime(2026, 10, 30);
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<ContextWeather>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: SetWeatherSheetContent(
                        weatherService: WeatherService(),
                        locationService: LocationService(),
                        currentLocation: null,
                        selectedDateTime: selectedDateTime,
                        currentWeather: ContextWeather(currentDateTime: selectedDateTime, currentTemperature: 12.5),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextFormField, '12,5');
    expect(field, findsOneWidget);
    await tester.enterText(field, '8,25');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(saved?.currentTemperature, 8.25);
  });

  testWidgets('the line chart labels its value axis with a decimal comma', (tester) async {
    final pressure = NumericalAdjustment(name: 'Druck', unit: null, notes: null);
    final column = ComponentAdjustmentColumn(pressure.id, active: true);
    Setup setup(String id, double value, int day) => Setup(
      id: id,
      name: id,
      datetime: DateTime.utc(2026, 6, day),
      datetimeLocal: DateTime(2026, 6, day),
      tags: const {},
      bike: 'bike',
      person: null,
      bikeAdjustmentValues: {pressure.id: NumericalValue(value)},
      personAdjustmentValues: const {},
    );
    final setups = [setup('a', 1.25, 1), setup('b', 1.75, 2)];

    await tester.pumpWidget(
      app(
        Scaffold(
          body: SingleChildScrollView(
            child: SetupLineChart(
              activeColumns: [column],
              setups: setups,
              selectedSetups: setups,
              showDateAxisLabels: true,
              selectedLineChartColumn: null,
              valueFor: (setup, _) => setup.bikeAdjustmentValues[pressure.id],
              adjustmentFor: (_) => pressure,
              columnLabel: (_) => 'Druck',
              onSelectedColumnChanged: (_) {},
              onColumnRemoved: (_) {},
            ),
          ),
        ),
      ),
    );

    final labels = [for (final text in tester.widgetList<Text>(find.byType(Text))) text.data ?? ''];
    expect(labels.where((label) => label.contains(',')), isNotEmpty, reason: '$labels');
    expect(labels.where((label) => RegExp(r'^\d+\.\d+$').hasMatch(label)), isEmpty, reason: '$labels');
  });
}
