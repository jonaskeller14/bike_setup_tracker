import 'dart:io';

import '../models/app_settings.dart';
import '../models/context/context_weather.dart';
import '../models/strava/strava_plan.dart';
import '../repositories/app_repository.dart';
import '../services/account_service.dart';
import '../services/elevation_service.dart';
import '../services/strava_service.dart';
import '../services/subscription_service.dart';
import '../services/weather_service.dart';

/// Reports an active yearly Strava subscription without touching the store,
/// Firebase Auth or Firestore.
class ScreenshotSubscriptionService extends SubscriptionService {
  final StravaEntitlement _screenshotEntitlement = StravaEntitlement(
    plan: StravaPlan.yearly,
    expiresAt: DateTime.now().add(const Duration(days: 365)),
    productId: Platform.isIOS ? StravaPlan.yearly.iosProductId : StravaPlan.androidProductId,
    platform: Platform.isIOS ? 'ios' : 'android',
    autoRenewing: true,
    billingPhase: StravaBillingPhase.standard,
  );

  @override
  StravaEntitlement? get entitlement => _screenshotEntitlement;

  @override
  bool get hasStravaEntitlement => true;

  @override
  StravaPlan? get activePlan => _screenshotEntitlement.plan;

  @override
  Future<void> initialize({required bool enableStrava, required AccountService accountService}) async {}

  @override
  Future<void> buy(StravaPlan plan) async {}

  @override
  Future<void> restorePurchases() async {}
}

/// Appears connected to Strava. Activities are seeded into the database up
/// front, so no listener, Cloud Function or OAuth flow ever runs.
class ScreenshotStravaService extends StravaService {
  final DateTime _syncedAt = DateTime.now().subtract(const Duration(hours: 1));

  ScreenshotStravaService(super.appRepository, super.appSettings);

  @override
  bool get isConnected => true;

  @override
  DateTime? get lastRecentSync => _syncedAt;

  @override
  DateTime? get lastFullSync => _syncedAt;

  @override
  Future<void> update({
    required AppRepository appRepository,
    required AppSettings appSettings,
    required AccountService accountService,
  }) async {}

  @override
  Future<StravaAvailability> checkAvailability({bool force = false}) async => StravaAvailability.available;

  @override
  Future<void> launchStravaLogin() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> triggerManualSync() async {}

  @override
  Future<void> triggerFullHistorySync() async {}

  @override
  Future<void> setStravaNotificationsEnabled(bool enabled) async {}
}

/// Returns fixed clear, dry weather for any place and time, so the Add
/// Setup form shows weather and trail condition without calling Open-Meteo.
class ScreenshotWeatherService extends WeatherService {
  final double temperature;

  ScreenshotWeatherService({this.temperature = 21.4});

  @override
  Future<ContextWeather?> fetchWeather({
    required double lat,
    required double lon,
    required DateTime datetime,
    int counter = 1,
  }) async {
    setStatus(const WeatherSuccess());
    return ContextWeather(
      currentDateTime: datetime.copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0),
      currentTemperature: temperature,
      currentWeatherCode: 0,
      currentHumidity: 48,
      currentWindSpeed: 9.5,
      currentPrecipitation: 0,
      currentSoilMoisture0to7cm: 0.08,
      dayAccumulatedPrecipitation: 0,
      currentIsDay: true,
    );
  }
}

/// Returns a fixed altitude for any place, so a demo's pressure check compares
/// the same conditions on every run.
class ScreenshotElevationService extends ElevationService {
  final double altitude;

  ScreenshotElevationService(this.altitude);

  @override
  Future<double?> fetchElevation({required double lat, required double lon}) async {
    setStatus(ElevationStatus.success);
    return altitude;
  }
}
