import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_installation.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/timeline_entry.dart';
import 'package:bike_setup_tracker/utils/timeline_grouping.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime local(DateTime utc) =>
    DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);

SetupEntry setupEntry({
  required String id,
  required DateTime utc,
  String bike = 'b1',
}) {
  return SetupEntry(Setup(
    id: id,
    datetime: utc,
    datetimeLocal: local(utc),
    tags: {},
    bike: bike,
    person: null,
    bikeAdjustmentValues: {},
    personAdjustmentValues: {},
  ));
}

StravaEntry stravaEntry({
  required int id,
  required DateTime startUtc,
  Duration elapsed = const Duration(hours: 1),
}) {
  return StravaEntry(StravaActivity(
    id: id,
    name: 'Ride $id',
    athlete: 1,
    sportType: SportType.Other,
    startDate: startUtc,
    startDateLocal: local(startUtc),
    gearId: null,
    startLat: null,
    startLon: null,
    distance: null,
    totalElevationGain: null,
    movingTime: elapsed,
    elapsedTime: elapsed,
  ));
}

Component makeComponent({
  required String id,
  ComponentType type = ComponentType.fork,
}) {
  return Component(
    id: id,
    name: 'Component $id',
    componentType: type,
    installations: [],
  );
}

/// An Uninstallation event of [component] coming off [originBike].
InstallationEntry deinstallEntry({
  required Component component,
  required DateTime utc,
  required String installationId,
  String? originBike = 'b1',
}) {
  return InstallationEntry(ComponentInstallation(
    component: component,
    installation: Uninstallation(
      id: installationId,
      componentId: component.id,
      dateTimeUTC: utc,
      dateTimeLocal: local(utc),
    ),
    originParent: originBike,
    originParentType:
        originBike == null ? InstallationParentType.none : InstallationParentType.bike,
    isInitial: false,
  ));
}

/// A BikeInstallation event of [component] onto [bike].
InstallationEntry installEntry({
  required Component component,
  required DateTime utc,
  required String installationId,
  String bike = 'b1',
  bool isInitial = false,
}) {
  return InstallationEntry(ComponentInstallation(
    component: component,
    installation: BikeInstallation(
      bikeId: bike,
      id: installationId,
      componentId: component.id,
      dateTimeUTC: utc,
      dateTimeLocal: local(utc),
    ),
    originParent: null,
    originParentType: isInitial ? null : InstallationParentType.none,
    isInitial: isInitial,
  ));
}

/// An Archival event of [component]. When [originBike] is set the component
/// was on that bike immediately before (so the archival removes it from the
/// bike); when null it was already off the bike.
InstallationEntry archivalEntry({
  required Component component,
  required DateTime utc,
  required String installationId,
  String? originBike = 'b1',
}) {
  return InstallationEntry(ComponentInstallation(
    component: component,
    installation: Archival(
      id: installationId,
      componentId: component.id,
      dateTimeUTC: utc,
      dateTimeLocal: local(utc),
    ),
    originParent: originBike,
    originParentType:
        originBike == null ? InstallationParentType.none : InstallationParentType.bike,
    isInitial: false,
  ));
}

List<TimelineEntry> sorted(List<TimelineEntry> entries, {required bool ascending}) {
  final copy = List<TimelineEntry>.from(entries);
  copy.sort((a, b) =>
      ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
  return copy;
}

/// Tests exercise one pass at a time by *disabling* the one under test, so
/// every pass is on unless a test says otherwise (the app defaults are off).
AppSettings groupingSettings({
  bool setupGrouping = true,
  bool replacementDetection = true,
  bool stravaContext = true,
}) {
  return AppSettings()
    ..enableTimelineSetupGrouping = setupGrouping
    ..enableTimelineReplacementDetection = replacementDetection
    ..enableTimelineStravaContext = stravaContext;
}

List<TimelineRow> build(
  List<TimelineEntry> entries, {
  required bool ascending,
  AppSettings? settings,
}) {
  return buildTimelineRows(
    sorted(entries, ascending: ascending),
    sortAscending: ascending,
    appSettings: settings ?? groupingSettings(),
  );
}

void main() {
  // AppSettings setters persist through SharedPreferences.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('day headers', () {
    final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
    final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 2, 10));

    test('inserts one header per local day (DESC)', () {
      final rows = build([s1, s2], ascending: false);
      expect(rows, hasLength(4));
      expect((rows[0] as DayHeaderRow).day, DateTime(2026, 7, 2));
      expect((rows[1] as SingleEntryRow).entry, s2);
      expect((rows[2] as DayHeaderRow).day, DateTime(2026, 7, 1));
      expect((rows[3] as SingleEntryRow).entry, s1);
    });

    test('inserts one header per local day (ASC)', () {
      final rows = build([s1, s2], ascending: true);
      expect(rows, hasLength(4));
      expect((rows[0] as DayHeaderRow).day, DateTime(2026, 7, 1));
      expect((rows[1] as SingleEntryRow).entry, s1);
      expect((rows[2] as DayHeaderRow).day, DateTime(2026, 7, 2));
      expect((rows[3] as SingleEntryRow).entry, s2);
    });

    test('same day gets a single header', () {
      final s3 = setupEntry(id: 's3', utc: DateTime.utc(2026, 7, 1, 16), bike: 'b2');
      final rows = build([s1, s3], ascending: false);
      expect(rows.whereType<DayHeaderRow>(), hasLength(1));
    });

  });

  group('setup grouping', () {
    test('groups adjacent same-bike setups within the window (DESC)', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11));
      final s3 = setupEntry(id: 's3', utc: DateTime.utc(2026, 7, 1, 12));
      final rows = build([s1, s2, s3], ascending: false);
      expect(rows, hasLength(2)); // header + group
      final group = rows[1] as SetupGroupRow;
      expect(group.setups.map((e) => e.setup.id), ['s3', 's2', 's1']);
    });

    test('groups adjacent same-bike setups within the window (ASC)', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11));
      final rows = build([s1, s2], ascending: true);
      final group = rows[1] as SetupGroupRow;
      expect(group.setups.map((e) => e.setup.id), ['s1', 's2']);
    });

    test('chains consecutive gaps even when the total span exceeds the window', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11, 30));
      final s3 = setupEntry(id: 's3', utc: DateTime.utc(2026, 7, 1, 13));
      final rows = build([s1, s2, s3], ascending: true);
      expect((rows[1] as SetupGroupRow).setups, hasLength(3));
    });

    test('does not group different bikes', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10), bike: 'b1');
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11), bike: 'b2');
      final rows = build([s1, s2], ascending: false);
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
      expect(rows.whereType<SingleEntryRow>(), hasLength(2));
    });

    test('does not group beyond the window', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 13));
      final rows = build([s1, s2], ascending: false);
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
    });

    test('groups same-activity setups beyond the ordinary window', () {
      final activity = stravaEntry(
        id: 1,
        startUtc: DateTime.utc(2026, 7, 1, 10),
        elapsed: const Duration(hours: 10),
      );
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 15));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 19, 45));
      final rows = build([activity, s1, s2], ascending: true);

      expect(rows.whereType<SetupGroupRow>().single.setups, [s1, s2]);
    });

    test('uses activity grouping when Strava context UI is disabled', () {
      final activity = stravaEntry(
        id: 1,
        startUtc: DateTime.utc(2026, 7, 1, 10),
        elapsed: const Duration(hours: 10),
      );
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 15));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 19, 45));
      final rows = build(
        [activity, s1, s2],
        ascending: true,
        settings: groupingSettings(stravaContext: false),
      );

      final group = rows.whereType<SetupGroupRow>().single;
      expect(group.setups, [s1, s2]);
      expect(group.stravaContext, isNull);
    });

    test('a non-setup entry between setups breaks the run', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final component = makeComponent(id: 'c1');
      final inst = installEntry(
        component: component,
        utc: DateTime.utc(2026, 7, 1, 10, 30),
        installationId: 'i1',
      );
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11));
      final rows = build([s1, inst, s2], ascending: true);
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
      expect(rows.whereType<SingleEntryRow>(), hasLength(3));
    });

    test('setups on different local days are not grouped', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 23));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 2, 0, 30));
      final rows = build([s1, s2], ascending: false);
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
      expect(rows.whereType<DayHeaderRow>(), hasLength(2));
    });

    test('can be disabled via settings', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11));
      final rows = build(
        [s1, s2],
        ascending: false,
        settings: groupingSettings(setupGrouping: false),
      );
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
    });
  });

  group('replacement detection', () {
    final oldFork = makeComponent(id: 'old');
    final newFork = makeComponent(id: 'new');

    for (final ascending in [true, false]) {
      test('pairs deinstall + install of same type on same bike (${ascending ? "ASC" : "DESC"})', () {
        final removed = deinstallEntry(
          component: oldFork,
          utc: DateTime.utc(2026, 7, 1, 10),
          installationId: 'd1',
        );
        final installed = installEntry(
          component: newFork,
          utc: DateTime.utc(2026, 7, 1, 10, 3),
          installationId: 'i1',
        );
        final rows = build([removed, installed], ascending: ascending);
        expect(rows, hasLength(2)); // header + replacement
        final replacement = rows[1] as ReplacementRow;
        expect(replacement.removed.component.id, 'old');
        expect(replacement.installed.component.id, 'new');
      });
    }

    test('unmatched deinstall stays a normal tile', () {
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final rows = build([removed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
      expect(rows.whereType<SingleEntryRow>(), hasLength(1));
    });

    test('same component moved back is a move, not a replacement', () {
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
      );
      final rows = build([removed, installed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    for (final ascending in [true, false]) {
      test('a freshly created component (initial-only bike install) pairs as the '
          'install half (${ascending ? "ASC" : "DESC"})', () {
        final removed = deinstallEntry(
          component: oldFork,
          utc: DateTime.utc(2026, 7, 1, 10),
          installationId: 'd1',
        );
        final installed = installEntry(
          component: newFork,
          utc: DateTime.utc(2026, 7, 1, 10, 3),
          installationId: 'i1',
          isInitial: true,
        );
        final rows = build([removed, installed], ascending: ascending);
        expect(rows, hasLength(2)); // header + replacement
        final replacement = rows[1] as ReplacementRow;
        expect(replacement.removed.component.id, 'old');
        expect(replacement.installed.component.id, 'new');
        expect(replacement.installed.isInitial, isTrue);
      });
    }

    test('an initial install with no matching removal stays a normal tile', () {
      final installed = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
        isInitial: true,
      );
      final rows = build([installed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
      expect(rows.whereType<SingleEntryRow>(), hasLength(1));
    });

    test('an initial install is never the removed half', () {
      // Two same-type components both first added onto the same bike close
      // together must not pair with each other — neither came off the bike.
      final a = installEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'i1',
        isInitial: true,
      );
      final b = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i2',
        isInitial: true,
      );
      final rows = build([a, b], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    for (final ascending in [true, false]) {
      test('archival off the bike pairs as the removal (${ascending ? "ASC" : "DESC"})', () {
        final archived = archivalEntry(
          component: oldFork,
          utc: DateTime.utc(2026, 7, 1, 10),
          installationId: 'a1',
        );
        final installed = installEntry(
          component: newFork,
          utc: DateTime.utc(2026, 7, 1, 10, 3),
          installationId: 'i1',
        );
        final rows = build([archived, installed], ascending: ascending);
        expect(rows, hasLength(2)); // header + replacement
        final replacement = rows[1] as ReplacementRow;
        expect(replacement.removed.installation, isA<Archival>());
        expect(replacement.removed.component.id, 'old');
        expect(replacement.installed.component.id, 'new');
      });
    }

    test('archival that was not on a bike does not pair', () {
      final archived = archivalEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'a1',
        originBike: null,
      );
      final installed = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
      );
      final rows = build([archived, installed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    test('an archival is never picked as the installed half', () {
      // A deinstall looking for a partner must not match an archival, which
      // takes a component off a bike rather than onto it.
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final archived = archivalEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'a1',
      );
      final rows = build([removed, archived], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    test('different component types are not paired', () {
      final shock = makeComponent(id: 'shock', type: ComponentType.shock);
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: shock,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
      );
      final rows = build([removed, installed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    test('install on a different bike is not a replacement', () {
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
        originBike: 'b1',
      );
      final installed = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
        bike: 'b2',
      );
      final rows = build([removed, installed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    test('events outside the window are not paired', () {
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 10),
        installationId: 'i1',
      );
      final rows = build([removed, installed], ascending: false);
      expect(rows.whereType<ReplacementRow>(), isEmpty);
    });

    test('a pair straddling midnight anchors to the earlier day', () {
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 23, 58),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 2, 0, 1),
        installationId: 'i1',
      );
      final rows = build([removed, installed], ascending: false);
      expect(rows.whereType<DayHeaderRow>(), hasLength(1));
      expect((rows[0] as DayHeaderRow).day, DateTime(2026, 7, 1));
      expect(rows[1], isA<ReplacementRow>());
    });

    test('can be disabled via settings', () {
      final removed = deinstallEntry(
        component: oldFork,
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: newFork,
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
      );
      final rows = build(
        [removed, installed],
        ascending: false,
        settings: groupingSettings(replacementDetection: false),
      );
      expect(rows.whereType<ReplacementRow>(), isEmpty);
      expect(rows.whereType<SingleEntryRow>(), hasLength(2));
    });
  });

  group('strava context', () {
    test('annotates entries inside the activity window (DESC)', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 30));
      final after = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 13));
      final rows = build([activity, during, after], ascending: false);

      final entryRows = rows.whereType<SingleEntryRow>().toList();
      // DESC: after (13:00), during (10:30), activity (10:00)
      expect(entryRows[0].stravaContext, isNull);
      expect(entryRows[1].stravaContext?.activity.id, 1);
      expect(entryRows[1].stravaContext?.isFirst, isTrue);
      expect(entryRows[1].stravaContext?.isLast, isFalse);
      expect(entryRows[2].stravaContext?.activity.id, 1);
      expect(entryRows[2].stravaContext?.isFirst, isFalse);
      expect(entryRows[2].stravaContext?.isLast, isTrue);
    });

    test('annotates entries inside the activity window (ASC)', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 30));
      final rows = build([activity, during], ascending: true);

      final entryRows = rows.whereType<SingleEntryRow>().toList();
      // ASC: activity (10:00), during (10:30)
      expect(entryRows[0].stravaContext?.isFirst, isTrue);
      expect(entryRows[0].stravaContext?.isLast, isFalse);
      expect(entryRows[1].stravaContext?.isFirst, isFalse);
      expect(entryRows[1].stravaContext?.isLast, isTrue);
    });

    test('an activity without during-entries gets its own single-row block', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final after = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 13));
      final rows = build([activity, after], ascending: false);
      final entryRows = rows.whereType<SingleEntryRow>().toList();
      // DESC: after (13:00) has no bar, activity carries its own block.
      expect(entryRows[0].stravaContext, isNull);
      expect(entryRows[1].stravaContext?.activity.id, 1);
      expect(entryRows[1].stravaContext?.isFirst, isTrue);
      expect(entryRows[1].stravaContext?.isLast, isTrue);
    });

    test('back-to-back activities form separate blocks', () {
      final a1 = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final a2 = stravaEntry(id: 2, startUtc: DateTime.utc(2026, 7, 1, 11, 30));
      final rows = build([a1, a2], ascending: false);
      final entryRows = rows.whereType<SingleEntryRow>().toList();
      for (final row in entryRows) {
        expect(row.stravaContext?.isFirst, isTrue);
        expect(row.stravaContext?.isLast, isTrue);
      }
      expect(entryRows[0].stravaContext?.activity.id,
          isNot(entryRows[1].stravaContext?.activity.id));
    });

    test('with overlapping activities the innermost (latest start) wins', () {
      final outer = stravaEntry(
        id: 1,
        startUtc: DateTime.utc(2026, 7, 1, 10),
        elapsed: const Duration(hours: 4),
      );
      final inner = stravaEntry(id: 2, startUtc: DateTime.utc(2026, 7, 1, 11));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 11, 30));
      final rows = build([outer, inner, during], ascending: false);
      final setupRow = rows
          .whereType<SingleEntryRow>()
          .firstWhere((r) => r.entry is SetupEntry);
      expect(setupRow.stravaContext?.activity.id, 2);
    });

    test('entry inside both overlapping windows stays with the inner block (ASC)', () {
      // a1 10:00–14:00, a2 starts 11:00 (during a1), setup 11:30 inside both.
      final a1 = stravaEntry(
        id: 1,
        startUtc: DateTime.utc(2026, 7, 1, 10),
        elapsed: const Duration(hours: 4),
      );
      final a2 = stravaEntry(id: 2, startUtc: DateTime.utc(2026, 7, 1, 11));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 11, 30));
      final rows = build([a1, a2, during], ascending: true);
      final entryRows = rows.whereType<SingleEntryRow>().toList();
      // Chronological order already yields contiguous blocks: a1 | a2, setup.
      expect(entryRows.map((r) => r.entry), [a1, a2, during]);
      expect(entryRows[1].stravaContext?.activity.id, 2);
      expect(entryRows[2].stravaContext?.activity.id, 2);
      expect(entryRows[2].stravaContext?.isLast, isTrue);
    });

    for (final ascending in [true, false]) {
      test(
          'entry during an outer ride only is pulled next to it '
          '(${ascending ? "ASC" : "DESC"})', () {
        // a1 10:00–12:00; a2 10:30–10:40 (starts during a1, already over);
        // setup 10:45 is inside a1's window only.
        final a1 = stravaEntry(
          id: 1,
          startUtc: DateTime.utc(2026, 7, 1, 10),
          elapsed: const Duration(hours: 2),
        );
        final a2 = stravaEntry(
          id: 2,
          startUtc: DateTime.utc(2026, 7, 1, 10, 30),
          elapsed: const Duration(minutes: 10),
        );
        final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 45));
        final rows = build([a1, a2, during], ascending: ascending);
        final entryRows = rows.whereType<SingleEntryRow>().toList();
        // Chronological would interleave (a1, a2, setup) — block regrouping
        // keeps a1's block contiguous: ASC a1, setup, a2 / DESC a2, setup, a1.
        expect(
          entryRows.map((r) => r.entry),
          ascending ? [a1, during, a2] : [a2, during, a1],
        );
        final duringRow = entryRows.firstWhere((r) => r.entry == during);
        expect(duringRow.stravaContext?.activity.id, 1);
        final a1Row = entryRows.firstWhere((r) => r.entry == a1);
        final a2Row = entryRows.firstWhere((r) => r.entry == a2);
        expect(a1Row.stravaContext?.activity.id, 1);
        expect(a2Row.stravaContext?.isFirst, isTrue);
        expect(a2Row.stravaContext?.isLast, isTrue);
      });
    }

    test('setups in different ride contexts are not grouped', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 30));
      final after = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11, 30));
      final rows = build([activity, during, after], ascending: true);
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
    });

    test('a setup group inside a ride is annotated as one row', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 15));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 10, 45));
      final rows = build([activity, s1, s2], ascending: true);
      final group = rows.whereType<SetupGroupRow>().single;
      expect(group.stravaContext?.activity.id, 1);
    });

    test('can be disabled via settings', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 30));
      final rows = build(
        [activity, during],
        ascending: false,
        settings: groupingSettings(stravaContext: false),
      );
      for (final row in rows.whereType<SingleEntryRow>()) {
        expect(row.stravaContext, isNull);
      }
    });
  });

  group('collapseIntoRows', () {
    List<EntryRow> collapse(
      List<TimelineEntry> entries, {
      bool ascending = false,
      AppSettings? settings,
    }) {
      return collapseIntoRows(
        sorted(entries, ascending: ascending),
        appSettings: settings ?? groupingSettings(),
      );
    }

    test('collapses a replacement pair into one row at the earlier slot', () {
      final removed = deinstallEntry(
        component: makeComponent(id: 'old'),
        utc: DateTime.utc(2026, 7, 1, 10),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: makeComponent(id: 'new'),
        utc: DateTime.utc(2026, 7, 1, 10, 3),
        installationId: 'i1',
      );
      final later = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 14));
      final rows = collapse([removed, installed, later], ascending: true);

      expect(rows, hasLength(2));
      final replacement = rows[0] as ReplacementRow;
      expect(replacement.removed.component.id, 'old');
      expect(replacement.installed.component.id, 'new');
      expect(replacement.anchorInstallation.id, 'd1');
      expect(rows[1], isA<SingleEntryRow>());
    });

    test('collapses a run of setups into a group row', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11));
      final rows = collapse([s1, s2], ascending: true);
      expect(rows, hasLength(1));
      expect((rows.single as SetupGroupRow).setups.map((e) => e.setup.id),
          ['s1', 's2']);
    });

    test('grouping passes off yields only single rows', () {
      final s1 = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10));
      final s2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11));
      final removed = deinstallEntry(
        component: makeComponent(id: 'old'),
        utc: DateTime.utc(2026, 7, 1, 12),
        installationId: 'd1',
      );
      final installed = installEntry(
        component: makeComponent(id: 'new'),
        utc: DateTime.utc(2026, 7, 1, 12, 3),
        installationId: 'i1',
      );
      final rows = collapse(
        [s1, s2, removed, installed],
        settings: groupingSettings(
          setupGrouping: false,
          replacementDetection: false,
          stravaContext: false,
        ),
      );
      expect(rows, hasLength(4));
      expect(rows.whereType<SingleEntryRow>(), hasLength(4));
    });

    test('never emits day headers or annotates strava context', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 15));
      final during2 = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 10, 45));
      final nextDay = setupEntry(id: 's3', utc: DateTime.utc(2026, 7, 2, 10));
      final rows = collapse([activity, during, during2, nextDay], ascending: true);

      // `EntryRow` cannot be a `DayHeaderRow`, but the row count proves no
      // header slots were emitted: activity + setup group + next-day setup.
      expect(rows, hasLength(3));
      expect(rows.whereType<SetupGroupRow>(), hasLength(1));
      for (final row in rows) {
        expect(row.stravaContext, isNull);
      }
    });

    test('setups in different ride contexts are still split', () {
      final activity = stravaEntry(id: 1, startUtc: DateTime.utc(2026, 7, 1, 10));
      final during = setupEntry(id: 's1', utc: DateTime.utc(2026, 7, 1, 10, 30));
      final after = setupEntry(id: 's2', utc: DateTime.utc(2026, 7, 1, 11, 30));
      final rows = collapse([activity, during, after], ascending: true);
      expect(rows.whereType<SetupGroupRow>(), isEmpty);
      expect(rows, hasLength(3));
    });
  });
}
