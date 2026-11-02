import 'dart:convert';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/utils/regional_defaults.dart';
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

    test('enableAttachments persists under its own key, ignoring the old image flag', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}enableSetupImages': true});
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.enableAttachments, isFalse);

      settings.enableAttachments = true;
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableAttachments'), isTrue);
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

  group('AppSettings — resetToDefaults', () {
    test('restores defaults, clears stored keys and keeps onboarding state', () async {
      SharedPreferences.setMockInitialValues({
        '${_kPrefix}showOnboarding': false,
        '${_kPrefix}enableCalendar': true,
        '${_kPrefix}distanceUnit': 'mi',
        '${_kPrefix}themeMode': ThemeMode.dark.toString(),
        'unrelated.key': 'kept',
      });
      final settings = AppSettings();
      await settings.loadAppSettings();
      var notified = false;
      settings.addListener(() => notified = true);

      await settings.resetToDefaults();

      expect(settings.enableCalendar, isFalse);
      expect(settings.distanceUnit, 'km');
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.showOnboarding, isFalse);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'${_kPrefix}showOnboarding', 'unrelated.key'});

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.distanceUnit, 'km');
      expect(reloaded.showOnboarding, isFalse);
    });

    test('hasDefaultValues tracks changes and ignores onboarding state', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}showOnboarding': false});
      final settings = AppSettings();
      await settings.loadAppSettings();
      expect(settings.hasDefaultValues, isTrue);

      settings.enableCalendar = true;
      expect(settings.hasDefaultValues, isFalse);

      await settings.resetToDefaults();
      expect(settings.hasDefaultValues, isTrue);
    });
  });

  group('AppSettings — regional defaults', () {
    const markerKey = '${_kPrefix}regionalDefaultsApplied';
    const unitKeys = ['temperatureUnit', 'windSpeedUnit', 'altitudeUnit', 'precipitationUnit', 'distanceUnit'];
    final us = regionalDefaults('US', alwaysUse24HourFormat: false);
    final de = regionalDefaults('DE');

    Map<String, String> units(AppSettings settings) => {
      'temperatureUnit': settings.temperatureUnit,
      'windSpeedUnit': settings.windSpeedUnit,
      'altitudeUnit': settings.altitudeUnit,
      'precipitationUnit': settings.precipitationUnit,
      'distanceUnit': settings.distanceUnit,
      'timeFormat': settings.timeFormat,
    };

    test('the code defaults are the metric ones', () {
      expect(units(AppSettings()), RegionalDefaults.metric.settings);
    });

    test('a fresh install in the US stores imperial units and the 12-hour clock', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);

      expect(units(settings), us.settings);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${_kPrefix}distanceUnit'), 'mi');
      expect(prefs.getString('${_kPrefix}temperatureUnit'), '°F');
      expect(prefs.getString('${_kPrefix}timeFormat'), 'h:mm a');
      expect(prefs.getBool(markerKey), isTrue);
    });

    test('a fresh install in the UK stores the mixed units', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: regionalDefaults('GB'));

      expect(settings.distanceUnit, 'mi');
      expect(settings.windSpeedUnit, 'mph');
      expect(settings.temperatureUnit, '°C');
      expect(settings.altitudeUnit, 'm');
    });

    test('a fresh install in Germany stays metric and writes only the marker', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: de);

      expect(units(settings), RegionalDefaults.metric.settings);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {markerKey});
    });

    test('an existing install keeps its metric units in the US', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}showOnboarding': false});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);

      expect(units(settings), RegionalDefaults.metric.settings);
      final prefs = await SharedPreferences.getInstance();
      for (final key in unitKeys) {
        expect(prefs.containsKey('$_kPrefix$key'), isFalse, reason: key);
      }
      expect(prefs.getBool(markerKey), isTrue);
    });

    test('a legacy blob user keeps its metric units in the US', () async {
      SharedPreferences.setMockInitialValues({
        _kLegacyBlobKey: jsonEncode({'showOnboarding': false, 'themeMode': 'ThemeMode.dark'}),
      });
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);

      expect(units(settings), RegionalDefaults.metric.settings);
      expect(settings.themeMode, ThemeMode.dark);
    });

    test('an explicit unit survives a fresh install in the US', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}distanceUnit': 'km'});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);

      expect(settings.distanceUnit, 'km');
    });

    test('the units stay when the device region changes later', () async {
      SharedPreferences.setMockInitialValues({});
      await AppSettings().loadAppSettings(regionalDefaults: us);

      final afterTravel = AppSettings();
      await afterTravel.loadAppSettings(regionalDefaults: de);
      expect(afterTravel.distanceUnit, 'mi');
      expect(afterTravel.timeFormat, 'h:mm a');
    });

    test('the marker stops a second derivation', () async {
      SharedPreferences.setMockInitialValues({});
      final first = AppSettings();
      await first.loadAppSettings(regionalDefaults: us);
      first.distanceUnit = 'km';
      await flushWrites();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_kPrefix}temperatureUnit'); // would be derived again without the marker

      final second = AppSettings();
      await second.loadAppSettings(regionalDefaults: us);
      expect(second.distanceUnit, 'km');
      expect(second.temperatureUnit, '°C');
    });

    test('without regional defaults nothing is derived and nothing is written', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(units(settings), RegionalDefaults.metric.settings);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('a fresh install is at the derived defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);
      expect(settings.hasDefaultValues, isTrue);

      settings.distanceUnit = 'km';
      expect(settings.hasDefaultValues, isFalse);
    });

    test('an existing install in the US is not at the derived defaults', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}showOnboarding': false});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);

      expect(settings.hasDefaultValues, isFalse);
    });

    test('reset restores and persists the derived defaults', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}showOnboarding': false});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: us);
      settings.enableCalendar = true;
      await flushWrites();

      await settings.resetToDefaults();

      expect(units(settings), us.settings);
      expect(settings.enableCalendar, isFalse);
      expect(settings.hasDefaultValues, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${_kPrefix}distanceUnit'), 'mi');
      expect(prefs.containsKey('${_kPrefix}enableCalendar'), isFalse);
      expect(prefs.getBool(markerKey), isTrue);

      final reloaded = AppSettings();
      await reloaded.loadAppSettings(regionalDefaults: us);
      expect(units(reloaded), us.settings);
    });

    test('reset in Germany removes the stored units', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}showOnboarding': false});
      final settings = AppSettings();
      await settings.loadAppSettings(regionalDefaults: de);
      settings.distanceUnit = 'mi';
      await flushWrites();

      await settings.resetToDefaults();

      expect(settings.distanceUnit, 'km');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('${_kPrefix}distanceUnit'), isFalse);
    });
  });

  group('AppSettings — enablePersonAdvanced', () {
    test('persists, loads and resets', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();
      expect(settings.enablePersonAdvanced, isFalse);

      settings.enablePersonAdvanced = true;
      await flushWrites();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enablePersonAdvanced'), isTrue);
      expect(settings.hasDefaultValues, isFalse);

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.enablePersonAdvanced, isTrue);

      await reloaded.resetToDefaults();
      expect(reloaded.enablePersonAdvanced, isFalse);
      expect(prefs.getBool('${_kPrefix}enablePersonAdvanced'), isNull);
    });

    test('showAdvancedPersonUi needs enablePerson as well', () {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings()..enablePersonAdvanced = true;
      expect(settings.showAdvancedPersonUi, isFalse);

      settings.enablePerson = true;
      expect(settings.showAdvancedPersonUi, isTrue);

      settings.enablePersonAdvanced = false;
      expect(settings.showAdvancedPersonUi, isFalse);
    });
  });

  group('AppSettings — language', () {
    test('drops the retired flag and week start on load', () async {
      SharedPreferences.setMockInitialValues({
        '${_kPrefix}enableLanguageSelection': true,
        '${_kPrefix}firstDayOfWeek': DateTime.sunday,
        '${_kPrefix}localeCode': 'de',
      });
      await AppSettings().loadAppSettings();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'${_kPrefix}localeCode'});
    });

    test('defaults to the system language', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.localeCode, isNull);
    });

    test('persists, loads and resets', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.localeCode = 'de';
      await flushWrites();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('${_kPrefix}localeCode'), 'de');
      expect(settings.hasDefaultValues, isFalse);

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.localeCode, 'de');

      await reloaded.resetToDefaults();
      expect(reloaded.localeCode, isNull);
      expect(prefs.getString('${_kPrefix}localeCode'), isNull);
    });

    test('choosing the system language again removes the stored override', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}localeCode': 'de'});
      final settings = AppSettings();
      await settings.loadAppSettings();
      expect(settings.localeCode, 'de');

      settings.localeCode = null;
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('${_kPrefix}localeCode'), isFalse);
      expect(settings.hasDefaultValues, isTrue);
    });
  });

  group('AppSettings — enableTaskPresets', () {
    test('persists, loads and resets', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();
      expect(settings.enableTaskPresets, isTrue);

      settings.enableTaskPresets = false;
      await flushWrites();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableTaskPresets'), isFalse);
      expect(settings.hasDefaultValues, isFalse);

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.enableTaskPresets, isFalse);

      await reloaded.resetToDefaults();
      expect(reloaded.enableTaskPresets, isTrue);
      expect(prefs.getBool('${_kPrefix}enableTaskPresets'), isNull);
    });

    test('works without component presets', () {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings()..enableComponentPresets = false;
      expect(settings.enableTaskPresets, isTrue);
    });

    test('showTaskPresets needs tasks, task interval and task presets', () {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings()
        ..enableComponentPresets = true
        ..enableTask = true
        ..enableTaskPresets = true;
      expect(settings.enableTaskInterval, isTrue);
      expect(settings.showTaskPresets, isTrue);

      settings.enableTask = false;
      expect(settings.showTaskPresets, isFalse);
      settings.enableTask = true;

      settings.enableTaskInterval = false;
      expect(settings.showTaskPresets, isFalse);
      settings.enableTaskInterval = true;

      settings.enableTaskPresets = false;
      expect(settings.showTaskPresets, isFalse);
      settings.enableTaskPresets = true;
    });
  });

  group('AppSettings — enableSetupGuides', () {
    test('persists, loads and resets', () async {
      SharedPreferences.setMockInitialValues({'${_kPrefix}enableComponentPresets': true});
      final settings = AppSettings();
      await settings.loadAppSettings();
      expect(settings.enableSetupGuides, isFalse);

      settings.enableSetupGuides = true;
      await flushWrites();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${_kPrefix}enableSetupGuides'), isTrue);
      expect(settings.hasDefaultValues, isFalse);

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.enableSetupGuides, isTrue);

      await reloaded.resetToDefaults();
      expect(reloaded.enableSetupGuides, isFalse);
      expect(prefs.getBool('${_kPrefix}enableSetupGuides'), isNull);
    });

    test('requires component presets and keeps the stored choice', () {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings()
        ..enableComponentPresets = false
        ..enableSetupGuides = true;
      expect(settings.enableSetupGuides, isFalse);

      settings.enableComponentPresets = true;
      expect(settings.enableSetupGuides, isTrue);

      settings.enableComponentPresets = false;
      expect(settings.enableSetupGuides, isFalse);

      settings.enableComponentPresets = true;
      expect(settings.enableSetupGuides, isTrue);
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
      expect(AppSettings.convertElevationToMeters(null, 'ft'), isNull);
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

    test('meters -> meters and feet -> meters', () {
      expect(AppSettings.convertElevationToMeters(1234, 'm'), closeTo(1234, 1e-9));
      expect(AppSettings.convertElevationToMeters(1, 'ft'), closeTo(0.3048, 1e-9));
    });

    test('round-trips through meters for both units', () {
      for (final unit in ['m', 'ft']) {
        final meters = AppSettings.convertElevationToMeters(1500.0, unit)!;
        expect(AppSettings.convertElevationFromMeters(meters, unit), closeTo(1500.0, 1e-9));
      }
    });

    test('unknown unit falls back to meters', () {
      expect(AppSettings.convertElevationFromMeters(500, 'cubits'), closeTo(500, 1e-9));
      expect(AppSettings.convertElevationToMeters(500, 'cubits'), closeTo(500, 1e-9));
    });
  });

  group('AppSettings — speedUnitForDistance', () {
    test('maps distance unit to matching speed unit', () {
      expect(AppSettings.speedUnitForDistance('mi'), 'mph');
      expect(AppSettings.speedUnitForDistance('km'), 'km/h');
    });
  });
}
