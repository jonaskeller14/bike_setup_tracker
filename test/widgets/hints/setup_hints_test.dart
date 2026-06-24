import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/widgets/hints/setup_hint_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lets fire-and-forget setter persistence (`void async`) complete.
Future<void> flushWrites() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // AppSettings — persistence & session-cooldown semantics for the new flags.
  // ---------------------------------------------------------------------------
  group('AppSettings — hint flags', () {
    const prefix = 'app_settings.';

    test('new hint flags default to true; session flag defaults to false',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      expect(settings.showSetupTaskHint, isTrue);
      expect(settings.showSetupCalendarHint, isTrue);
      expect(settings.hintShownThisSession, isFalse);
    });

    test('show*Hint setters persist their own key', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.showSetupTaskHint = false;
      settings.showSetupCalendarHint = false;
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${prefix}showSetupTaskHint'), isFalse);
      expect(prefs.getBool('${prefix}showSetupCalendarHint'), isFalse);
    });

    test('persisted hint flags survive a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.showSetupTaskHint = false;
      await flushWrites();

      final reloaded = AppSettings();
      await reloaded.loadAppSettings();

      expect(reloaded.showSetupTaskHint, isFalse);
      expect(reloaded.showSetupCalendarHint, isTrue); // untouched
    });

    test('hintShownThisSession is in-memory only and resets on reload',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.hintShownThisSession = true;
      await flushWrites();

      // Not persisted...
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${prefix}hintShownThisSession'), isNull);

      // ...and a fresh load (next app launch) starts the session clean.
      final reloaded = AppSettings();
      await reloaded.loadAppSettings();
      expect(reloaded.hintShownThisSession, isFalse);
    });

    test('showAllHints re-enables hint flags and clears the session guard',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      settings.showSetupTaskHint = false;
      settings.showSetupCalendarHint = false;
      settings.hintShownThisSession = true;

      settings.showAllHints();

      expect(settings.showSetupTaskHint, isTrue);
      expect(settings.showSetupCalendarHint, isTrue);
      expect(settings.hintShownThisSession, isFalse);
    });

    test('setting equal to current value writes nothing to SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = AppSettings();
      await settings.loadAppSettings();

      // Both flags already default to true — no write should occur.
      settings.showSetupTaskHint = true;
      settings.showSetupCalendarHint = true;
      await flushWrites();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('${prefix}showSetupTaskHint'), isNull);
      expect(prefs.getBool('${prefix}showSetupCalendarHint'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // selectSetupHint — the at-most-one selection logic and all edge cases.
  // ---------------------------------------------------------------------------
  group('selectSetupHint', () {
    AppSettings make([void Function(AppSettings)? configure]) {
      SharedPreferences.setMockInitialValues({});
      final s = AppSettings();
      configure?.call(s);
      return s;
    }

    SetupHint select(
      AppSettings s, {
      int setupCount = 0,
      int stravaActivityCount = 0,
    }) =>
        selectSetupHint(
          settings: s,
          setupCount: setupCount,
          stravaActivityCount: stravaActivityCount,
        );

    // --- No-hint baselines ---

    test('no setups and no activities → none', () {
      expect(select(make(), setupCount: 0), SetupHint.none);
    });

    test('both features already on → none regardless of data volume', () {
      final s = make((x) {
        x.enableTask = true;
        x.enableCalendar = true;
      });
      expect(select(s, setupCount: 10, stravaActivityCount: 20), SetupHint.none);
    });

    test('session guard overrides everything (the core cooldown guarantee)', () {
      // Tasks off + calendar off + plenty of data — still suppressed.
      final s = make((x) => x.hintShownThisSession = true);
      expect(select(s, setupCount: 5, stravaActivityCount: 9), SetupHint.none);
    });

    // --- Task hint ---

    test('one setup, defaults → task hint', () {
      expect(select(make(), setupCount: 1), SetupHint.task);
    });

    test('task hint shown flag false → no task hint', () {
      final s = make((x) => x.showSetupTaskHint = false);
      expect(select(s, setupCount: 1), SetupHint.none);
    });

    test('task already on → no task hint', () {
      final s = make((x) => x.enableTask = true);
      expect(select(s, setupCount: 1), SetupHint.none);
    });

    // --- Calendar hint ---

    test('tasks on + two setups → calendar hint', () {
      final s = make((x) => x.enableTask = true);
      expect(select(s, setupCount: 2), SetupHint.calendar);
    });

    test('calendar boundary: exactly two setups qualifies', () {
      final s = make((x) => x.enableTask = true);
      expect(select(s, setupCount: 2), SetupHint.calendar);
    });

    test('tasks on but only one setup → none (calendar threshold not met)', () {
      final s = make((x) => x.enableTask = true);
      expect(select(s, setupCount: 1), SetupHint.none);
    });

    test('Strava boundary: exactly 2 activities does NOT qualify (needs > 2)', () {
      final s = make((x) => x.enableTask = true);
      expect(select(s, setupCount: 0, stravaActivityCount: 2), SetupHint.none);
    });

    test('Strava: 3 activities qualifies the calendar hint', () {
      final s = make((x) => x.enableTask = true);
      expect(select(s, setupCount: 0, stravaActivityCount: 3), SetupHint.calendar);
    });

    test('calendar hint shown flag false + tasks on → none', () {
      final s = make((x) {
        x.enableTask = true;
        x.showSetupCalendarHint = false;
      });
      expect(select(s, setupCount: 2), SetupHint.none);
    });

    test('calendar already on + tasks on → none', () {
      final s = make((x) {
        x.enableTask = true;
        x.enableCalendar = true;
      });
      expect(select(s, setupCount: 2), SetupHint.none);
    });

    // --- Priority: task wins over calendar ---

    test('two setups, defaults → task wins over calendar', () {
      // Calendar would qualify (≥2 setups) but task takes priority.
      expect(select(make(), setupCount: 2), SetupHint.task);
    });

    test('task hint dismissed, two setups → calendar now surfaces', () {
      // Dismissing the task hint permanently clears it; the session guard
      // does NOT apply here (dismissal only sets hintShownThisSession via the
      // button callback, not the flag itself), so the next cold launch shows
      // the calendar hint.
      final s = make((x) => x.showSetupTaskHint = false);
      expect(select(s, setupCount: 2), SetupHint.calendar);
    });

    test('task hint dismissed + only one setup → none (calendar needs ≥2)', () {
      final s = make((x) => x.showSetupTaskHint = false);
      expect(select(s, setupCount: 1), SetupHint.none);
    });
  });
}
