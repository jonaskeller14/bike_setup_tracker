import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_installation.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/timeline_entry.dart';
import 'package:bike_setup_tracker/pages/calendar_page.dart';
import 'package:bike_setup_tracker/utils/timeline_grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime local(DateTime utc) => DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);

SetupEntry setupEntry({required String id, required DateTime utc}) => SetupEntry(
  Setup(
    id: id,
    name: id,
    datetime: utc,
    datetimeLocal: local(utc),
    tags: {},
    bike: 'bike',
    person: null,
    bikeAdjustmentValues: {},
    personAdjustmentValues: {},
  ),
);

StravaEntry stravaEntry({
  required DateTime utc,
  required DateTime localStart,
  Duration elapsed = const Duration(hours: 1),
}) => StravaEntry(
  StravaActivity(
    id: 1,
    name: 'Ride',
    athlete: 1,
    sportType: SportType.Other,
    startDate: utc,
    startDateLocal: localStart,
    gearId: null,
    startLat: null,
    startLon: null,
    distance: null,
    totalElevationGain: null,
    movingTime: elapsed,
    elapsedTime: elapsed,
  ),
);

Component component(String id) => Component(
  id: id,
  name: id,
  componentType: ComponentType.fork,
  installations: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('calendarDisplayDateForDay', () {
    test('uses the earliest entry on the selected local day with a lead-in', () {
      final earlier = setupEntry(id: 'earlier', utc: DateTime.utc(2026, 7, 4, 10));
      final later = setupEntry(id: 'later', utc: DateTime.utc(2026, 7, 4, 12));
      final day = earlier.date.toLocal();

      expect(
        calendarDisplayDateForDay(day, [later, earlier]),
        earlier.date.toLocal().subtract(kCalendarScrollLeadIn),
      );
    });

    test('falls back to 06:00 when the selected day has no entries', () {
      final day = DateTime(2026, 7, 5, 18);

      expect(
        calendarDisplayDateForDay(day, []),
        DateTime(2026, 7, 5, kCalendarFallbackHour),
      );
    });
  });

  test('buildCalendarRows expands setup groups but preserves replacements', () {
    final settings = AppSettings()..enableTimelineSetupGrouping = true;
    final oldComponent = component('old');
    final newComponent = component('new');
    final removed = InstallationEntry(
      ComponentInstallation(
        component: oldComponent,
        installation: Uninstallation(
          id: 'remove',
          componentId: oldComponent.id,
          dateTimeUTC: DateTime.utc(2026, 7, 4, 12),
          dateTimeLocal: DateTime(2026, 7, 4, 12),
        ),
        originParent: 'bike',
        originParentType: InstallationParentType.bike,
      ),
    );
    final installed = InstallationEntry(
      ComponentInstallation(
        component: newComponent,
        installation: BikeInstallation(
          id: 'install',
          componentId: newComponent.id,
          bikeId: 'bike',
          dateTimeUTC: DateTime.utc(2026, 7, 4, 12, 3),
          dateTimeLocal: DateTime(2026, 7, 4, 12, 3),
        ),
      ),
    );

    final rows = buildCalendarRows([
      setupEntry(id: 'first', utc: DateTime.utc(2026, 7, 4, 9)),
      setupEntry(id: 'second', utc: DateTime.utc(2026, 7, 4, 10)),
      removed,
      installed,
    ], settings);

    expect(rows.whereType<SetupGroupRow>(), isEmpty);
    expect(
      rows
          .whereType<SingleEntryRow>()
          .map((row) => row.entry)
          .whereType<SetupEntry>()
          .map((entry) => entry.setup.id),
      unorderedEquals(['first', 'second']),
    );
    expect(rows.whereType<ReplacementRow>(), hasLength(1));
  });

  group('CalendarTimelineDataSource', () {
    test('uses a Strava entry local anchor and elapsed duration', () {
      final entry = stravaEntry(
        utc: DateTime.utc(2026, 7, 4, 10),
        localStart: DateTime(2026, 7, 4, 4),
        elapsed: const Duration(hours: 2),
      );
      final source = CalendarTimelineDataSource(
        [SingleEntryRow(entry)],
        const ColorScheme.light(),
      );

      expect(source.getStartTime(0), DateTime(2026, 7, 4, 4));
      expect(source.getEndTime(0), DateTime(2026, 7, 4, 6));
    });

    test('keeps replacement appointments visible for at least 30 minutes', () {
      final oldComponent = component('old');
      final newComponent = component('new');
      final row = ReplacementRow(
        removed: ComponentInstallation(
          component: oldComponent,
          installation: Uninstallation(
            id: 'remove',
            componentId: oldComponent.id,
            dateTimeUTC: DateTime.utc(2026, 7, 4, 10),
            dateTimeLocal: DateTime(2026, 7, 4, 10),
          ),
        ),
        installed: ComponentInstallation(
          component: newComponent,
          installation: BikeInstallation(
            id: 'install',
            componentId: newComponent.id,
            bikeId: 'bike',
            dateTimeUTC: DateTime.utc(2026, 7, 4, 10, 3),
            dateTimeLocal: DateTime(2026, 7, 4, 10, 3),
          ),
        ),
      );
      final source = CalendarTimelineDataSource(
        [row],
        const ColorScheme.light(),
      );

      expect(source.getEndTime(0), DateTime(2026, 7, 4, 10, 30));
    });
  });
}
