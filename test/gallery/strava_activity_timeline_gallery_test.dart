// Renders every state of StravaActivityTimeline (the setups and feedback of a
// Strava activity page) to PNGs in build/gallery/strava_activity_timeline/
// (git-ignored), for a quick visual check after changing it. Skipped by default
// (see dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/strava_activity_timeline_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; each
// state is also written on its own.
//
// Names that start with "my" are user data (Setup.name, TestSession.name,
// RideFeedback.notes, Adjustment.name). Anything else on screen (START, END,
// "2 DAYS BEFORE START", placeholders, hints) comes from the UI.
//
// Each state gets its own bike, linked to its own Strava gear, so the
// repository resolves current setups and feedback per state exactly like the
// activity page does.
//
// Besides the pictures, the second test checks that no state traps the user:
// every missing-setup placeholder either adds a setup or says why it can't.
@Tags(['gallery'])
library;

import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/l10n/entity_names.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/activity_timeline.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/widgets/empty_state_placeholder2.dart';
import 'package:bike_setup_tracker/widgets/strava_activity_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

const _pageWidth = 400.0;

/// Every activity starts here unless a state says otherwise.
final _start = DateTime(2026, 5, 10, 9);
const _rideLength = Duration(hours: 2, minutes: 45);

DateTime _at(Duration offset) => _start.add(offset);

/// The repository keeps scheduling frames while its drift streams churn, so
/// `pumpAndSettle` never returns; advance time explicitly instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 80 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

class _Case {
  final int n;
  final String slug;
  final String title;
  final Duration elapsed;
  final double width;

  /// Whether the placeholder for a missing setup must show (some states have
  /// one ridden-on setup and so none).
  final bool expectsPlaceholder;

  const _Case(
    this.n,
    this.slug,
    this.title, {
    this.elapsed = _rideLength,
    this.width = _pageWidth,
    this.expectsPlaceholder = false,
  });

  String get bikeId => 'bike-$n';
  String get gearId => 'gear-$n';

  StravaActivity get activity => StravaActivity(
    id: 1000 + n,
    name: 'myRide$n',
    athlete: 1,
    sportType: SportType.MountainBikeRide,
    startDate: _start.toUtc(),
    startDateLocal: _start,
    gearId: gearId,
    startLat: null,
    startLon: null,
    distance: 32000,
    totalElevationGain: 900,
    movingTime: elapsed,
    elapsedTime: elapsed,
  );
}

const _cases = [
  _Case(1, 'typical', 'Ridden on mySetup2 (older mySetup1 hidden) · changed mid-ride · feedback during and after'),
  _Case(2, 'at-start', 'Setup saved at the start · feedback at its default time (1 min before end)'),
  _Case(3, 'session-ended', 'Ended test session during the ride: 3 runs, feedback after each'),
  _Case(
    4,
    'session-running',
    'Running test session, no setup before: adding is blocked, placeholder says why',
    expectsPlaceholder: true,
  ),
  _Case(5, 'no-setup', 'No setup, no feedback', expectsPlaceholder: true),
  _Case(
    6,
    'only-feedback-hard-deleted',
    'Only feedback · its setup hard-deleted (id dangling)',
    expectsPlaceholder: true,
  ),
  _Case(
    7,
    'only-feedback-soft-deleted',
    'Only feedback · its setup soft-deleted (repository drops it, same as hard)',
    expectsPlaceholder: true,
  ),
  _Case(8, 'mid-ride-only', 'Setup only recorded mid-ride, none before', expectsPlaceholder: true),
  _Case(9, 'feedback-before-start', 'Linked feedback dated before the start (import / edited date)'),
  _Case(10, 'zero-length', 'Zero-length activity (start = end) · feedback after it', elapsed: Duration.zero),
  _Case(11, 'multi-day', '30 h activity · ridden-on setup 400 days old', elapsed: Duration(hours: 30)),
  _Case(12, 'long-names-narrow', 'Long names on a 320 px screen', width: 320),
];

/// One bike per state with a fork carrying myRebound, so setup cards show values.
Bike _bike(_Case c) => Bike(id: c.bikeId, name: 'myBike${c.n}', person: null, stravaGear: c.gearId);

String _adjustmentId(_Case c) => 'rebound-${c.n}';

Component _fork(_Case c) => Component(
  id: 'fork-${c.n}',
  name: 'myFork${c.n}',
  componentType: ComponentType.fork,
  installations: [Installation.sinceBeginning(parent: c.bikeId)],
  adjustments: [
    StepAdjustment(
      id: _adjustmentId(c),
      name: 'myRebound',
      notes: '',
      unit: AdjustmentUnit.fromLegacy('clicks'),
      min: 0,
      max: 20,
      step: 1,
      visualization: StepAdjustmentVisualization.slider,
    ),
  ],
);

Setup _setup(_Case c, String id, String name, DateTime local, int rebound, {String? sessionId}) => Setup(
  id: id,
  name: name,
  datetime: local.toUtc(),
  datetimeLocal: local,
  tags: const {},
  bike: c.bikeId,
  person: null,
  bikeAdjustmentValues: {_adjustmentId(c): StepValue(rebound)},
  personAdjustmentValues: const {},
  testSessionId: sessionId,
);

RideFeedback _feedback(
  _Case c,
  String id,
  DateTime local, {
  required String setupId,
  String? comparedWith,
  int outcome = 1,
  bool linked = false,
  String? notes,
}) => RideFeedback(
  id: id,
  bike: c.bikeId,
  setupId: setupId,
  stravaActivityId: linked ? c.activity.id : null,
  dateTimeUTC: local.toUtc(),
  dateTimeLocal: local,
  notes: notes,
  comparisons: {
    if (comparedWith != null)
      FeedbackComparison(referenceSetupId: comparedWith, aspect: const OverallAspect(), outcome: outcome),
  },
);

class _Seed {
  final setups = <Setup>[];
  final feedbacks = <RideFeedback>[];
  final sessions = <TestSession>[];
  final softDeleted = <String>[];
}

_Seed _seed() {
  final seed = _Seed();
  final s = seed.setups;
  final f = seed.feedbacks;
  const h = Duration(hours: 1);
  const m = Duration(minutes: 1);
  const d = Duration(days: 1);

  // 1 · typical
  final c1 = _cases[0];
  s.addAll([
    _setup(c1, 's1-1', 'mySetup1', _at(-d * 5), 8),
    _setup(c1, 's1-2', 'mySetup2', _at(-d * 2), 10),
    _setup(c1, 's1-3', 'mySetup3', _at(h + m * 13), 12),
  ]);
  f.addAll([
    _feedback(c1, 'f1-1', _at(h * 2), setupId: 's1-3', comparedWith: 's1-2'),
    _feedback(c1, 'f1-2', _at(_rideLength + h * 3), setupId: 's1-3', linked: true, notes: 'myNotes1'),
  ]);

  // 2 · at start
  final c2 = _cases[1];
  s.add(_setup(c2, 's2-1', 'mySetup4', _start, 9));
  final (_, endMinusOne) = c2.activity.feedbackTime(now: _at(d));
  f.add(_feedback(c2, 'f2-1', endMinusOne, setupId: 's2-1', linked: true, notes: 'myNotes2'));

  // 3 · ended session
  final c3 = _cases[2];
  final session1 = TestSession(
    id: 'session-3',
    bike: c3.bikeId,
    name: 'mySession1',
    adjustmentIds: [_adjustmentId(c3)],
    startedAtUTC: _at(m * 15).toUtc(),
    startedAtLocal: _at(m * 15),
    endedAtUTC: _at(h * 2 + m * 30).toUtc(),
    endedAtLocal: _at(h * 2 + m * 30),
  );
  seed.sessions.add(session1);
  s.addAll([
    _setup(c3, 's3-0', 'mySetup5', _at(-h), 10),
    _setup(c3, 's3-1', 'myRun1', _at(m * 15), 8, sessionId: session1.id),
    _setup(c3, 's3-2', 'myRun2', _at(m * 50), 12, sessionId: session1.id),
    _setup(c3, 's3-3', 'myRun3', _at(h + m * 30), 14, sessionId: session1.id),
  ]);
  f.addAll([
    _feedback(c3, 'f3-1', _at(m * 40), setupId: 's3-1', comparedWith: 's3-0', outcome: -1),
    _feedback(c3, 'f3-2', _at(h + m * 15), setupId: 's3-2', comparedWith: 's3-1'),
    _feedback(c3, 'f3-3', _at(h * 2), setupId: 's3-3', comparedWith: 's3-2', outcome: 0),
  ]);

  // 4 · running session, nothing before the ride
  final c4 = _cases[3];
  final session2 = TestSession(
    id: 'session-4',
    bike: c4.bikeId,
    name: 'mySession2',
    adjustmentIds: [_adjustmentId(c4)],
    startedAtUTC: _at(m * 20).toUtc(),
    startedAtLocal: _at(m * 20),
  );
  seed.sessions.add(session2);
  s.addAll([
    _setup(c4, 's4-1', 'myRun4', _at(m * 20), 8, sessionId: session2.id),
    _setup(c4, 's4-2', 'myRun5', _at(h), 11, sessionId: session2.id),
  ]);
  f.add(_feedback(c4, 'f4-1', _at(m * 50), setupId: 's4-1'));

  // 5 · nothing at all (no data)

  // 6 · only feedback, its setup never stored
  final c6 = _cases[5];
  f.add(_feedback(c6, 'f6-1', _at(h), setupId: 'setup-hard-deleted', linked: true, notes: 'myNotes6'));

  // 7 · only feedback, its setup soft-deleted
  final c7 = _cases[6];
  s.add(_setup(c7, 's7-1', 'mySetup6', _at(-d), 10));
  seed.softDeleted.add('s7-1');
  f.add(_feedback(c7, 'f7-1', _at(h * 2), setupId: 's7-1', linked: true, notes: 'myNotes7'));

  // 8 · setup only mid-ride
  final c8 = _cases[7];
  s.add(_setup(c8, 's8-1', 'mySetup7', _at(m * 30), 10));

  // 9 · linked feedback dated before the start
  final c9 = _cases[8];
  s.add(_setup(c9, 's9-1', 'mySetup8', _at(-h * 3), 10));
  f.add(_feedback(c9, 'f9-1', _at(-h), setupId: 's9-1', linked: true, notes: 'myNotes9'));

  // 10 · zero-length activity
  final c10 = _cases[9];
  s.add(_setup(c10, 's10-1', 'mySetup9', _at(-m * 10), 10));
  f.add(_feedback(c10, 'f10-1', _at(m * 5), setupId: 's10-1', linked: true));

  // 11 · 30 h activity
  final c11 = _cases[10];
  s.addAll([
    _setup(c11, 's11-1', 'mySetup10', _at(-d * 400), 10),
    _setup(c11, 's11-2', 'mySetup11', _at(h * 26), 13),
  ]);
  f.add(_feedback(c11, 'f11-1', _at(h * 30 + d * 2), setupId: 's11-2', linked: true));

  // 12 · long names, narrow
  final c12 = _cases[11];
  final long = 'myVeryLongSetupNameThatKeepsGoingAndGoing ' * 2;
  s.addAll([
    _setup(c12, 's12-1', long.trim(), _at(-h * 5), 10),
    _setup(c12, 's12-2', '${long}2'.trim(), _at(h), 12),
  ]);
  f.add(
    _feedback(c12, 'f12-1', _at(h * 2), setupId: 's12-2', comparedWith: 's12-1', notes: 'myNotes12 ' * 20),
  );

  return seed;
}

class _World {
  final AppDatabase database;
  final AppRepository repository;
  final AppSettings settings;
  final AppHintService hints;

  _World(this.database, this.repository, this.settings, this.hints);

  /// Writes through one repository, then reads it back through a fresh one,
  /// the way an app launch does: that resolves current setups and the values
  /// each setup inherits.
  static Future<_World> create() async {
    final database = AppDatabase.memory();
    final writer = AppRepository(database);
    final seed = _seed();
    await writer.addBikes(_cases.map(_bike));
    await writer.addComponents(_cases.map(_fork));
    await writer.addTestSessions(seed.sessions);
    for (final setup in seed.setups) {
      await writer.addSetups([setup]);
    }
    await writer.addFeedbacks(seed.feedbacks);
    await _waitFor(() => writer.setups.length == seed.setups.length);
    await writer.removeSetups(seed.setups.where((s) => seed.softDeleted.contains(s.id)));
    await writer.disposeAndAwaitCancellation();

    final repository = AppRepository(database);
    await _waitFor(
      () =>
          repository.setups.length == seed.setups.length - seed.softDeleted.length &&
          repository.feedbacks.length == seed.feedbacks.length &&
          repository.testSessions.length == seed.sessions.length,
    );
    final settings = AppSettings()
      ..showOnboarding = false
      ..enableRating = true;
    final hints = AppHintService(appRepository: repository, appSettings: settings);
    await hints.load();
    return _World(database, repository, settings, hints);
  }

  Future<void> dispose() async {
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    hints.dispose();
    await database.close();
  }

  Widget providers(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<AppSettings>.value(value: settings),
      ChangeNotifierProvider<AppRepository>.value(value: repository),
      ChangeNotifierProvider<AppHintService>.value(value: hints),
      ChangeNotifierProvider<SubscriptionService>(create: (_) => SubscriptionService()),
    ],
    child: child,
  );
}

/// What the activity page passes for [c]: its gear's setups, its feedbacks and,
/// while a test session runs on the bike, no way to add a setup plus the reason.
Widget _timeline(_Case c, {VoidCallback? onAddSetup}) => Builder(
  builder: (context) {
    final repository = context.watch<AppRepository>();
    final activity = c.activity;
    final timeline = ActivityTimeline.of(
      activity,
      setups: repository.setups.values.where((s) => repository.bikes[s.bike]?.stravaGear == c.gearId),
      feedbacks: repository.feedbacksForActivity(activity),
    );
    final running = repository.runningSessionFor(c.bikeId);
    return StravaActivityTimeline(
      timeline: timeline,
      onAddSetup: running == null ? (onAddSetup ?? () {}) : null,
      addSetupHint: running == null ? null : context.l10n.stravaActivitySessionRunning(running.label(context.l10n)),
    );
  },
);

Widget _app(_World world, ThemeData theme, _Case c, Key key, {VoidCallback? onAddSetup}) => world.providers(
  localizedTestApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: SizedBox(
                width: c.width,
                child: Padding(
                  // The page's ExpansionTile insets.
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: _timeline(c, onAddSetup: onAddSetup),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  late Directory output;
  late _World world;

  setUpAll(() async => output = await prepareGallery('strava_activity_timeline'));

  // A repository built inside the widget-test zone deadlocks on its first write.
  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    world = await _World.create();
  });

  tearDown(() => world.dispose());

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(_pageWidth, 4000);
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      for (final c in _cases) {
        final key = ValueKey('${c.slug}-$name');
        await tester.pumpWidget(_app(world, theme, c, key));
        await _settle(tester);
        await session.add(c.slug, '${c.n} · ${c.title}', tester.renderObject(find.byKey(key)));
      }

      await session.finish();
    });
  }

  testWidgets('every missing-setup placeholder adds a setup or says why it cannot', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(_pageWidth, 4000);

    for (final c in _cases) {
      var added = 0;
      await tester.pumpWidget(_app(world, galleryThemes.first.$2, c, ValueKey(c.slug), onAddSetup: () => added++));
      await _settle(tester);

      final placeholder = find.byType(EmptyStatePlaceholder2);
      expect(placeholder, c.expectsPlaceholder ? findsOneWidget : findsNothing, reason: c.title);
      if (!c.expectsPlaceholder) continue;

      await tester.tap(placeholder);
      await _settle(tester);
      if (world.repository.runningSessionFor(c.bikeId) case final running?) {
        expect(added, 0, reason: '"${c.title}" must not add a setup between the runs of a session');
        expect(
          find.textContaining(running.label(lookupAppLocalizations(const Locale('en')))),
          findsOneWidget,
          reason: '"${c.title}" must say which session blocks it',
        );
      } else {
        expect(added, 1, reason: '"${c.title}" placeholder does not add a setup');
      }
    }
  });
}
