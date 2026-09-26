// Store-screenshot entry point: `flutter run -t lib/main_screenshots.dart`.
//
// WIPES all app data and preferences on every launch and replaces them with
// the sample dataset — run it on emulators/simulators only, never on a device
// that holds real data.
//
// Firebase is deliberately never initialized, so screenshot runs send no
// analytics, crash reports or push registrations; Strava and the subscription
// are served by offline fakes instead.
import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'main.dart';
import 'models/app_settings.dart';
import 'repositories/app_repository.dart';
import 'screenshots/screenshot_seed.dart';
import 'screenshots/screenshot_services.dart';
import 'services/app_hint_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  recordBootError = (error, stack, {required reason}) => debugPrint('$reason: $error\n$stack');
  configureSystemChrome();

  final appDatabase = AppDatabase();
  final appSettings = AppSettings();
  final appRepository = AppRepository(appDatabase);
  final appHintService = AppHintService(
    appRepository: appRepository,
    appSettings: appSettings,
  );

  await ScreenshotSeed.resetPreferences(appHintService);
  await ScreenshotSeed.seedDatabase(appRepository, today: DateTime.now());

  runApp(
    LoadingGate(
      appSettings: appSettings,
      appRepository: appRepository,
      appHintService: appHintService,
      createSubscriptionService: ScreenshotSubscriptionService.new,
      createStravaService: ScreenshotStravaService.new,
      enablePushNotifications: false,
    ),
  );
}
