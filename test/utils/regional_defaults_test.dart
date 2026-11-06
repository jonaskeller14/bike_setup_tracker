import 'package:bike_setup_tracker/utils/regional_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('regionalDefaults', () {
    test('the US is imperial', () {
      final defaults = regionalDefaults('US');
      expect(defaults.temperatureUnit, '°F');
      expect(defaults.windSpeedUnit, 'mph');
      expect(defaults.altitudeUnit, 'ft');
      expect(defaults.precipitationUnit, 'in');
      expect(defaults.distanceUnit, 'mi');
    });

    test('US territories follow the US', () {
      for (final region in const ['PR', 'GU', 'VI', 'AS', 'MP']) {
        expect(regionalDefaults(region).distanceUnit, 'mi', reason: region);
        expect(regionalDefaults(region).temperatureUnit, '°F', reason: region);
      }
    });

    test('the UK is mixed', () {
      final defaults = regionalDefaults('GB');
      expect(defaults.temperatureUnit, '°C');
      expect(defaults.windSpeedUnit, 'mph');
      expect(defaults.altitudeUnit, 'm');
      expect(defaults.precipitationUnit, 'mm');
      expect(defaults.distanceUnit, 'mi');
    });

    test('everything else is metric', () {
      for (final region in const ['DE', 'CH', 'AU', 'CA', 'IE', 'FR']) {
        expect(regionalDefaults(region).settings, RegionalDefaults.metric.settings, reason: region);
      }
    });

    test('no region and an empty region are metric', () {
      expect(regionalDefaults(null).settings, RegionalDefaults.metric.settings);
      expect(regionalDefaults('').settings, RegionalDefaults.metric.settings);
    });

    test('the region code is case-insensitive', () {
      expect(regionalDefaults('us').distanceUnit, 'mi');
    });

    test('the clock follows the system setting, not the region', () {
      expect(regionalDefaults('US').timeFormat, 'HH:mm');
      expect(regionalDefaults('US', alwaysUse24HourFormat: false).timeFormat, 'h:mm a');
      expect(regionalDefaults('DE', alwaysUse24HourFormat: false).timeFormat, 'h:mm a');
      expect(regionalDefaults('DE').timeFormat, 'HH:mm');
    });
  });
}
