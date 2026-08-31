import 'dart:convert';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-setting key namespace used by [AppSettings] (mirrors `_kPrefix`).
const String _kPrefix = 'app_settings.';

/// Legacy monolithic blob key (mirrors `_kLegacyBlobKey`).
const String _kLegacyBlobKey = 'app_settings';

/// Lets fire-and-forget setter persistence (`void async`) complete before we
/// inspect SharedPreferences.
Future<void> flushWrites() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettings — live defaults', () {
    test('uses code defaults when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      // A representative sample across both bool and string settings.
      expect(settings.showOnboarding, isTrue);
      expect(settings.enableStrava, isTrue);
      expect(settings.enableCalendar, isFalse);
      expect(settings.distanceUnit, 'km');
      expect(settings.themeMode, ThemeMode.system);
    });

    test('a stored per-key value overrides the default', () async {
      SharedPreferences.setMockInitialValues({
        '${_kPrefix}enableCalendar': true,
        '${_kPrefix}distanceUnit': 'mi',
        '${_kPrefix}themeMode': ThemeMode.dark.toString(),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.enableCalendar, isTrue);
      expect(settings.distanceUnit, 'mi');
      expect(settings.themeMode, ThemeMode.dark);
      // Untouched setting still reflects the live default.
      expect(settings.showOnboarding, isTrue);
    });
  });

  group('AppSettings — write on touch', () {
    test('Setup Comparison defaults on, notifies, persists, and reloads', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      var notifications = 0;
      settings.addListener(() => notifications++);

      expect(settings.enableSetupComparison, isTrue);
      settings.enableSetupComparison = false;
      await flushWrites();

      expect(notifications, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableSetupComparison'), isFalse);

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.enableSetupComparison, isFalse);
      settings.dispose();
      reloaded.dispose();
    });

    test('a setter persists only its own key', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.enableCalendar = true;
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableCalendar'), isTrue);
      // Nothing else was written — untouched settings stay absent so they keep
      // tracking future code defaults.
      expect(prefs.getBool('${_kPrefix}showOnboarding'), isNull);
      expect(prefs.getString('${_kPrefix}distanceUnit'), isNull);
    });

    test('setting equal to current value writes nothing', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      // enableCalendar already defaults to false.
      settings.enableCalendar = false;
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableCalendar'), isNull);
    });

    test('string setter persists under its namespaced key', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.distanceUnit = 'mi';
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${_kPrefix}distanceUnit'), 'mi');
    });
  });

  group('AppSettings — legacy blob migration (Option B)', () {
    test('preserves a value the user changed away from the default', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode({
          'enableCalendar': true, // default is false -> explicit choice
          'distanceUnit': 'mi', // default is 'km' -> explicit choice
        }),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.enableCalendar, isTrue);
      expect(settings.distanceUnit, 'mi');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableCalendar'), isTrue);
      expect(prefs.getString('${_kPrefix}distanceUnit'), 'mi');
      // Blob is consumed exactly once.
      expect(prefs.getString(_kLegacyBlobKey), isNull);
    });

    test('drops a value equal to the old default so it tracks code defaults', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode({
          'enableCalendar': false, // equals old default -> untouched
        }),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      final prefs = await SharedPreferences.getInstance();
      // Not migrated: the per-key entries stay absent...
      expect(prefs.getBool('${_kPrefix}enableCalendar'), isNull);
      // ...and the getters fall back to the live code defaults.
      expect(settings.enableCalendar, isFalse);
      expect(prefs.getString(_kLegacyBlobKey), isNull);
    });

    test('removes the legacy blob even when it is empty', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode(<String, dynamic>{}),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_kLegacyBlobKey), isNull);
    });

    test('migrates a changed themeMode string', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode({
          'themeMode': ThemeMode.dark.toString(),
        }),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.themeMode, ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${_kPrefix}themeMode'), ThemeMode.dark.toString());
    });

    // Regression: enableStrava was omitted from _legacyDefaults, so its old
    // default value (false) was being migrated and overrode the new default (true).
    test('enableStrava old default false does not override new default true', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode({
          'enableStrava': false, // old default — must not be persisted
        }),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.enableStrava, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableStrava'), isNull);
    });

    test('keys absent from _legacyDefaults are not migrated', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode({
          'someUnknownFutureKey': true,
          'anotherUnknownKey': 'value',
        }),
      });
      final settings = AppSettings();
      await settings.loadAppSettings();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}someUnknownFutureKey'), isNull);
      expect(prefs.getString('${_kPrefix}anotherUnknownKey'), isNull);
      expect(prefs.getString(_kLegacyBlobKey), isNull);
    });
  });

  group('AppSettings — distance conversion', () {
    test('null input returns null', () {
      expect(AppSettings.convertDistanceFromMeters(null, 'km'), isNull);
      expect(AppSettings.convertDistanceToMeters(null, 'mi'), isNull);
    });

    test('meters -> km', () {
      expect(AppSettings.convertDistanceFromMeters(1000, 'km'), closeTo(1, 1e-9));
      expect(AppSettings.convertDistanceFromMeters(0, 'km'), closeTo(0, 1e-9));
    });

    test('meters -> miles (exact 1609.344 m/mi)', () {
      expect(
        AppSettings.convertDistanceFromMeters(1609.344, 'mi'),
        closeTo(1, 1e-9),
      );
    });

    test('km -> meters and miles -> meters round-trip', () {
      expect(AppSettings.convertDistanceToMeters(1, 'km'), closeTo(1000, 1e-9));
      expect(
        AppSettings.convertDistanceToMeters(1, 'mi'),
        closeTo(1609.344, 1e-6),
      );
    });

    test('round-trips through meters for both units', () {
      for (final unit in ['km', 'mi']) {
        final meters = AppSettings.convertDistanceToMeters(42.0, unit)!;
        expect(
          AppSettings.convertDistanceFromMeters(meters, unit),
          closeTo(42.0, 1e-9),
        );
      }
    });

    test('unknown unit falls back to km (base display unit)', () {
      expect(
        AppSettings.convertDistanceFromMeters(1000, 'furlongs'),
        closeTo(1, 1e-9),
      );
      expect(
        AppSettings.convertDistanceToMeters(1, 'furlongs'),
        closeTo(1000, 1e-9),
      );
    });
  });

  group('AppSettings — elevation conversion', () {
    test('null input returns null', () {
      expect(AppSettings.convertElevationFromMeters(null, 'm'), isNull);
    });

    test('meters -> meters is identity', () {
      expect(AppSettings.convertElevationFromMeters(1234, 'm'), closeTo(1234, 1e-9));
    });

    test('meters -> feet (exact 0.3048 m/ft)', () {
      expect(
        AppSettings.convertElevationFromMeters(1, 'ft'),
        closeTo(1 / 0.3048, 1e-6),
      );
    });

    test('unknown unit falls back to meters', () {
      expect(AppSettings.convertElevationFromMeters(500, 'cubits'), closeTo(500, 1e-9));
    });
  });

  group('AppSettings — speedUnitForDistance', () {
    test('maps distance unit to matching speed unit', () {
      expect(AppSettings.speedUnitForDistance('mi'), 'mph');
      expect(AppSettings.speedUnitForDistance('km'), 'km/h');
    });
  });
}
