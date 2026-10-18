// Store-screenshot entry point: `flutter run -t lib/main_screenshots.dart`.
//
// WIPES all app data and preferences on every launch and replaces them with
// the sample dataset — run it on emulators/simulators only, never on a device
// that holds real data.
//
// Firebase is deliberately never initialized, so screenshot runs send no
// analytics, crash reports or push registrations; Strava and the subscription
// are served by offline fakes instead.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'database/app_database.dart';
import 'main.dart';
import 'models/app_settings.dart';
import 'repositories/app_repository.dart';
import 'screenshots/demo_scenario.dart';
import 'screenshots/screenshot_seed.dart';
import 'screenshots/screenshot_services.dart';
import 'screenshots/touch_indicator.dart';
import 'services/app_hint_service.dart';
import 'services/weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  recordBootError = (error, stack, {required reason}) => debugPrint('$reason: $error\n$stack');
  createWeatherService = ScreenshotWeatherService.new;
  configureSystemChrome();

  final appDatabase = AppDatabase();
  final appSettings = AppSettings();
  final appRepository = AppRepository(appDatabase);
  final appHintService = AppHintService(
    appRepository: appRepository,
    appSettings: appSettings,
  );

  // The run scripts write the flow's `# scenario:` name here, and
  // `run_ios.sh --preview` drops the touch marker for recordings; screenshots
  // stay dot-free. Files, because Dart can't read environment variables on iOS.
  final documents = await getApplicationDocumentsDirectory();
  final scenarioMarker = File('${documents.path}/${DemoScenario.markerFile}');
  final scenario = scenarioMarker.existsSync()
      ? DemoScenario.fromId(scenarioMarker.readAsStringSync().trim())
      : DemoScenario.full;

  await ScreenshotSeed.resetPreferences(appHintService, scenario: scenario);
  await ScreenshotSeed.seedDatabase(appRepository, today: DateTime.now(), scenario: scenario);

  final app = LoadingGate(
    appSettings: appSettings,
    appRepository: appRepository,
    appHintService: appHintService,
    createSubscriptionService: ScreenshotSubscriptionService.new,
    createStravaService: ScreenshotStravaService.new,
    enablePushNotifications: false,
  );
  final showTouches = File('${documents.path}/${TouchIndicator.markerFile}').existsSync();
  runApp(showTouches ? TouchIndicator(child: app) : app);
}
