import 'dart:async';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:bike_setup_tracker/models/rating_entry.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/rating_entry_page.dart';
import 'package:bike_setup_tracker/pages/setup_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end coverage for the Weather/Condition chip highlighting split on
/// SetupPage and RatingEntryPage: manually overriding the trail condition
/// must not flag the Weather chip, and editing weather data must not flag
/// the Condition chip. Both chips are rendered as the 4th/5th [ActionChip]
/// in the pages' context Wrap (date, time, location, weather, condition).
const _weatherChipIndex = 3;
const _conditionChipIndex = 4;

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  final baseWeather = ContextWeather(
    currentDateTime: DateTime(2026, 1, 1, 12),
    currentTemperature: 10,
    currentWeatherCode: 0, // Clear sky
    currentHumidity: 50,
    currentWindSpeed: 5,
    currentPrecipitation: 0,
    currentSoilMoisture0to7cm: 0.05, // resolves to Condition.dry
    dayAccumulatedPrecipitation: 0,
    currentIsDay: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.showOnboarding = false;
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
      ],
      child: MaterialApp(theme: materialAppTheme, home: home),
    );
  }

  Future<Bike> seedBike(WidgetTester tester) async {
    final bike = Bike(name: 'Test Bike', person: null);
    await tester.runAsync(() => appRepository.addBike(bike));
    await _waitForRepositoryUpdate(tester, appRepository);
    return bike;
  }

  Color? chipBackgroundColor(WidgetTester tester, int index) {
    return tester.widgetList<ActionChip>(find.byType(ActionChip)).elementAt(index).backgroundColor;
  }

  Color highlightColor(WidgetTester tester) {
    final context = tester.element(find.byType(Scaffold).first);
    return Theme.of(context).extension<ValueHighlightColors>()!.changedFill;
  }

  group('SetupPage', () {
    testWidgets('manually setting the condition highlights only the Condition chip', (tester) async {
      final bike = await seedBike(tester);
      final setup = Setup(
        datetime: baseWeather.currentDateTime,
        datetimeLocal: baseWeather.currentDateTime,
        tags: {},
        bike: bike.id,
        person: null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
        weather: baseWeather,
      );

      await tester.pumpWidget(wrap(SetupPage.edit(setup: setup)));
      await tester.pumpAndSettle();

      final highlight = highlightColor(tester);
      expect(chipBackgroundColor(tester, _weatherChipIndex), isNot(highlight));
      expect(chipBackgroundColor(tester, _conditionChipIndex), isNot(highlight));

      // Open the Condition sheet and manually pick a different condition.
      await tester.tap(find.byType(ActionChip).at(_conditionChipIndex));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<Condition?>, 'Muddy'));
      await tester.pumpAndSettle();

      expect(chipBackgroundColor(tester, _weatherChipIndex), isNot(highlight),
          reason: 'Manually setting the condition must not flag the Weather chip');
      expect(chipBackgroundColor(tester, _conditionChipIndex), highlight,
          reason: 'Manually setting the condition must flag the Condition chip');
    });

    testWidgets('editing weather data highlights only the Weather chip', (tester) async {
      final bike = await seedBike(tester);
      final setup = Setup(
        datetime: baseWeather.currentDateTime,
        datetimeLocal: baseWeather.currentDateTime,
        tags: {},
        bike: bike.id,
        person: null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
        weather: baseWeather,
      );

      await tester.pumpWidget(wrap(SetupPage.edit(setup: setup)));
      await tester.pumpAndSettle();

      final highlight = highlightColor(tester);

      // Open the Weather sheet and edit a field, then save.
      await tester.tap(find.byType(ActionChip).at(_weatherChipIndex));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, "Current Air Temperature in °C."), '22');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(chipBackgroundColor(tester, _weatherChipIndex), highlight,
          reason: 'Editing weather data must flag the Weather chip');
      expect(chipBackgroundColor(tester, _conditionChipIndex), isNot(highlight),
          reason: 'Editing weather data must not flag the Condition chip');
    });
  });

  group('RatingEntryPage', () {
    testWidgets('manually setting the condition highlights only the Condition chip', (tester) async {
      final bike = await seedBike(tester);
      final ratingEntry = RatingEntry(
        bike: bike.id,
        setupId: 'dummy-setup',
        dateTimeUTC: baseWeather.currentDateTime.toUtc(),
        dateTimeLocal: baseWeather.currentDateTime,
        weather: baseWeather,
      );

      await tester.pumpWidget(wrap(RatingEntryPage.edit(ratingEntry: ratingEntry)));
      await tester.pumpAndSettle();

      final highlight = highlightColor(tester);
      expect(chipBackgroundColor(tester, _weatherChipIndex), isNot(highlight));
      expect(chipBackgroundColor(tester, _conditionChipIndex), isNot(highlight));

      await tester.tap(find.byType(ActionChip).at(_conditionChipIndex));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<Condition?>, 'Muddy'));
      await tester.pumpAndSettle();

      expect(chipBackgroundColor(tester, _weatherChipIndex), isNot(highlight),
          reason: 'Manually setting the condition must not flag the Weather chip');
      expect(chipBackgroundColor(tester, _conditionChipIndex), highlight,
          reason: 'Manually setting the condition must flag the Condition chip');
    });

    testWidgets('editing weather data highlights only the Weather chip', (tester) async {
      final bike = await seedBike(tester);
      final ratingEntry = RatingEntry(
        bike: bike.id,
        setupId: 'dummy-setup',
        dateTimeUTC: baseWeather.currentDateTime.toUtc(),
        dateTimeLocal: baseWeather.currentDateTime,
        weather: baseWeather,
      );

      await tester.pumpWidget(wrap(RatingEntryPage.edit(ratingEntry: ratingEntry)));
      await tester.pumpAndSettle();

      final highlight = highlightColor(tester);

      await tester.tap(find.byType(ActionChip).at(_weatherChipIndex));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, "Current Air Temperature in °C."), '22');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(chipBackgroundColor(tester, _weatherChipIndex), highlight,
          reason: 'Editing weather data must flag the Weather chip');
      expect(chipBackgroundColor(tester, _conditionChipIndex), isNot(highlight),
          reason: 'Editing weather data must not flag the Condition chip');
    });
  });
}

Future<void> _waitForRepositoryUpdate(WidgetTester tester, AppRepository repository) async {
  final completer = Completer<void>();
  void listener() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  repository.addListener(listener);

  await tester.runAsync(() async {
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      // Timeout is handled by falling back to pumps below
    }
  });

  repository.removeListener(listener);

  await tester.pump();
}
