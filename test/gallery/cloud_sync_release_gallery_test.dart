// Renders every state of the cloud sync release UI to PNGs in
// build/gallery/cloud_sync_release/ (git-ignored), for a visual check after
// changing any of it. Skipped by default (see dart_test.yaml); run it on
// demand with:
//
//   flutter test test/gallery/cloud_sync_release_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; each
// state is also written on its own.
//
// Phase 9a (#17) covers the move from Google Drive into cloud sync, the notice
// for Drive users without active cloud sync and their entries in the Google Drive
// sheet. Names that start with "my" are user data (the Google account).
//
// Besides the pictures, the second group checks that no state traps the
// user: every failed move can be retried, every state but the running one can
// be closed, and a dismissed notice can be opened again from the Drive sheet.
@Tags(['gallery'])
library;

import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/account_service.dart';
import 'package:bike_setup_tracker/services/cloud_sync_service.dart';
import 'package:bike_setup_tracker/services/drive_move.dart';
import 'package:bike_setup_tracker/services/google_drive_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/utils/drive_move_actions.dart';
import 'package:bike_setup_tracker/widgets/sheets/google_drive_sync.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

class _MockAppRepository extends Mock implements AppRepository {}

class _MockCloudSyncService extends Mock implements CloudSyncService {}

class _MockSubscriptionService extends Mock implements SubscriptionService {}

class _MockGoogleDriveService extends Mock implements GoogleDriveService {}

class _MockAccountService extends Mock implements AccountService {}

const _phone = Size(360, 760);
const _narrow = Size(320, 568);
const _tablet = Size(800, 1100);

/// How reading the Drive copy ends.
enum _Drive { copy, empty, signIn, offline, broken, hangs }

Future<SelectedData?> _read(_Drive drive) async => switch (drive) {
  _Drive.copy => SelectedData(
    bikes: {'drive-bike': Bike(id: 'drive-bike', name: 'myDriveBike', person: null)},
  ),
  _Drive.empty => null,
  _Drive.signIn => throw const DriveReadException(DriveReadFailure.signIn),
  _Drive.offline => throw const DriveReadException(DriveReadFailure.offline),
  _Drive.broken => throw Exception('Drive API not initialized'),
  _Drive.hangs => Completer<SelectedData?>().future,
};

class _World {
  final AppDatabase database = AppDatabase.memory();
  final _MockAppRepository repository = _MockAppRepository();
  final _MockCloudSyncService sync = _MockCloudSyncService();
  final _MockSubscriptionService subscription = _MockSubscriptionService();
  final _MockGoogleDriveService drive = _MockGoogleDriveService();
  final _MockAccountService account = _MockAccountService();
  final AppSettings settings = AppSettings();
  _Drive driveResult;

  _World({
    this.driveResult = _Drive.copy,
    bool syncActive = true,
    bool? premium = true,
    bool signedIn = false,
    bool syncOn = false,
    bool onAccount = true,
  }) {
    when(() => account.isOnAccount).thenReturn(onAccount);
    when(repository.refreshTaskEntrySnapshots).thenAnswer((_) async {});
    when(() => sync.isActive).thenReturn(syncActive);
    when(sync.syncNow).thenAnswer((_) async => CloudSyncStatus.idle);
    when(() => subscription.premiumIfKnown).thenReturn(premium);
    when(drive.readSyncData).thenAnswer((_) => _read(driveResult));
    when(() => drive.isSignedIn).thenReturn(signedIn);
    when(() => drive.status).thenReturn(GoogleDriveServiceStatus.idle);
    when(() => drive.error).thenReturn(null);
    when(() => drive.displayName).thenReturn(signedIn ? 'myGoogleName' : null);
    when(() => drive.email).thenReturn(signedIn ? 'my.google.account@example.com' : null);
    when(() => drive.photoUrl).thenReturn(null);
    when(() => drive.lastSync).thenReturn(null);
    settings
      ..showOnboarding = false
      ..enableGoogleDrive = true
      ..developerMode = true
      ..enableCloudSync = syncOn;
  }
}

const _homeKey = ValueKey('home');

Widget _app(ThemeData theme, _World world, {required Key key}) {
  return RepaintBoundary(
    key: key,
    child: MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: world.database),
        ChangeNotifierProvider<AppRepository>.value(value: world.repository),
        ChangeNotifierProvider<AppSettings>.value(value: world.settings),
        ChangeNotifierProvider<CloudSyncService>.value(value: world.sync),
        ChangeNotifierProvider<SubscriptionService>.value(value: world.subscription),
        ChangeNotifierProvider<GoogleDriveService>.value(value: world.drive),
        ChangeNotifierProvider<AccountService>.value(value: world.account),
      ],
      child: localizedTestApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(key: _homeKey),
      ),
    ),
  );
}

/// Pumps long enough for sheet transitions, without waiting for the
/// spinners to settle (they never do).
Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

BuildContext _home(WidgetTester tester) => tester.element(find.byKey(_homeKey));

Future<void> _openMove(WidgetTester tester) async {
  unawaited(offerDriveMove(_home(tester)));
  await _pump(tester);
}

Future<void> _startMove(WidgetTester tester) async {
  await _openMove(tester);
  await tester.tap(find.text('Move now'));
  await _pump(tester);
}

Future<void> _openEnding(WidgetTester tester) async {
  unawaited(offerDriveEnding(_home(tester)));
  await _pump(tester);
}

Future<void> _openDriveSheet(WidgetTester tester) async {
  unawaited(showGoogleDriveSheet(context: _home(tester)));
  await _pump(tester);
}

enum _Shot { sheet, snackBar }

class _Case {
  final String slug;
  final String title;
  final _World Function() world;
  final Future<void> Function(WidgetTester tester) open;
  final Size size;
  final double textScale;
  final _Shot shot;

  const _Case(
    this.slug,
    this.title,
    this.world,
    this.open, {
    this.size = _phone,
    this.textScale = 1,
    this.shot = _Shot.sheet,
  });
}

final _cases = <_Case>[
  // Move sheet.
  const _Case('move_offered', 'Move · offered', _World.new, _openMove),
  const _Case('move_running', 'Move · running', _running, _startMove),
  const _Case('move_done', 'Move · done', _World.new, _startMove),
  _Case('move_nothing', 'Move · nothing to move', () => _World(driveResult: _Drive.empty), _startMove),
  _Case('move_sign_in_failed', 'Move · Google sign-in failed', () => _World(driveResult: _Drive.signIn), _startMove),
  _Case('move_offline', 'Move · offline', () => _World(driveResult: _Drive.offline), _startMove),
  _Case('move_failed', 'Move · failed for another reason', () => _World(driveResult: _Drive.broken), _startMove),
  const _Case(
    'move_offered_narrow_large',
    'Move · offered, narrow phone, large text',
    _World.new,
    _openMove,
    size: _narrow,
    textScale: 2,
  ),
  _Case(
    'move_failed_narrow_large',
    'Move · failed, narrow phone, large text',
    () => _World(driveResult: _Drive.broken),
    _startMove,
    size: _narrow,
    textScale: 2,
  ),
  const _Case('move_done_large', 'Move · done, large text', _World.new, _startMove, textScale: 2),
  const _Case('move_running_large', 'Move · running, large text', _running, _startMove, size: _narrow, textScale: 2),
  const _Case('move_offered_tablet', 'Move · offered, tablet', _World.new, _openMove, size: _tablet),
  // Ending notice (no subscription).
  const _Case('ending', 'Ending · no subscription', _noPremium, _openEnding),
  const _Case(
    'ending_narrow_large',
    'Ending · narrow phone, large text',
    _noPremium,
    _openEnding,
    size: _narrow,
    textScale: 2,
  ),
  const _Case('ending_tablet', 'Ending · tablet', _noPremium, _openEnding, size: _tablet),
  const _Case('ending_premium', 'Ending · subscriber, cloud sync off', _premiumNoSync, _openEnding),
  const _Case(
    'ending_premium_narrow_large',
    'Ending · subscriber, cloud sync off, narrow phone, large text',
    _premiumNoSync,
    _openEnding,
    size: _narrow,
    textScale: 2,
  ),
  const _Case(
    'ending_connect',
    'Ending · subscriber, cloud sync on, no account (Strava not connected)',
    _noAccount,
    _openEnding,
  ),
  _Case(
    'ending_turned_on',
    'Ending · subscriber turned cloud sync on (SnackBar)',
    _premiumNoSync,
    (tester) async {
      await _openEnding(tester);
      await tester.tap(find.text('Turn on cloud sync'));
      await _pump(tester);
    },
    shot: _Shot.snackBar,
  ),
  // Google Drive sheet entries.
  const _Case('drive_sheet_move', 'Drive sheet · signed out, move entry', _World.new, _openDriveSheet),
  _Case(
    'drive_sheet_move_signed_in',
    'Drive sheet · signed in, move entry',
    () => _World(signedIn: true),
    _openDriveSheet,
  ),
  const _Case('drive_sheet_ending', 'Drive sheet · signed out, ending entry', _noPremium, _openDriveSheet),
  const _Case(
    'drive_sheet_ending_premium',
    'Drive sheet · subscriber, cloud sync off, ending entry',
    _premiumNoSync,
    _openDriveSheet,
  ),
  const _Case(
    'drive_sheet_ending_connect',
    'Drive sheet · subscriber, cloud sync on, no account, ending entry',
    _noAccount,
    _openDriveSheet,
  ),
  _Case(
    'drive_sheet_none_starting',
    'Drive sheet · subscriber on an account, cloud sync starting, no entry',
    () => _World(syncActive: false, syncOn: true),
    _openDriveSheet,
  ),
  _Case(
    'drive_sheet_none_unknown',
    'Drive sheet · subscription not known yet, no entry',
    () => _World(syncActive: false, premium: null),
    _openDriveSheet,
  ),
  _Case(
    'drive_sheet_ending_narrow_large',
    'Drive sheet · ending entry, narrow phone, large text',
    () => _World(syncActive: false, premium: false, signedIn: true),
    _openDriveSheet,
    size: _narrow,
    textScale: 2,
  ),
];

_World _running() => _World(driveResult: _Drive.hangs);

_World _noPremium() => _World(syncActive: false, premium: false);

_World _premiumNoSync() => _World(syncActive: false);

_World _noAccount() => _World(syncActive: false, syncOn: true, onAccount: false);

Future<_World> _show(WidgetTester tester, ThemeData theme, _Case c, Key key, {_World? world}) async {
  final w = world ?? c.world();
  addTearDown(w.database.close);
  tester.view.physicalSize = c.size;
  tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
  await tester.pumpWidget(_app(theme, w, key: key));
  await _pump(tester);
  await c.open(tester);
  return w;
}

Rect _crop(WidgetTester tester, _Case c) {
  final screen = Offset.zero & c.size;
  switch (c.shot) {
    case _Shot.sheet:
      return tester.getRect(find.byType(BottomSheet)).intersect(screen);
    case _Shot.snackBar:
      final bar = tester.getRect(find.byType(SnackBar));
      return Rect.fromLTRB(0, (bar.top - 24).clamp(0, screen.bottom), screen.right, screen.bottom);
  }
}

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('cloud_sync_release'));
  // Each state opens its own in-memory database; they close at the end of the test.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
  });

  for (final (name, theme, background, textColor) in galleryThemes) {
    testWidgets('renders the $name gallery', (tester) async {
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      final session = GallerySession(tester, output, themeName: name, background: background, textColor: textColor);

      for (final (index, c) in _cases.indexed) {
        final key = ValueKey('$name-$index');
        await _show(tester, theme, c, key);
        await session.add(
          c.slug,
          c.title,
          tester.renderObject(find.byKey(key)),
          crop: _crop(tester, c),
        );
      }

      await session.finish();
    });
  }

  group('no state traps the user', () {
    Future<_World> open(WidgetTester tester, _World world, Future<void> Function(WidgetTester) steps) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      return _show(
        tester,
        galleryThemes.first.$2,
        _Case('trap', 'trap', () => world, steps),
        UniqueKey(),
        world: world,
      );
    }

    for (final failure in [_Drive.signIn, _Drive.offline, _Drive.broken]) {
      testWidgets('${failure.name}: trying again moves the data', (tester) async {
        final world = await open(tester, _World(driveResult: failure), _startMove);
        expect(world.settings.enableGoogleDrive, isTrue, reason: '${failure.name}: Drive stays on');

        world.driveResult = _Drive.copy;
        await tester.tap(find.text('Try again'));
        await _pump(tester);

        expect(find.text('Moved to cloud sync'), findsOneWidget, reason: failure.name);
        expect(world.settings.enableGoogleDrive, isFalse, reason: failure.name);
      });
    }

    for (final (label, world, steps, button)
        in <(String, _World Function(), Future<void> Function(WidgetTester), String)>[
          ('offered', _World.new, _openMove, 'Not now'),
          ('done', _World.new, _startMove, 'Close'),
          ('nothing to move', () => _World(driveResult: _Drive.empty), _startMove, 'Close'),
          ('sign-in failed', () => _World(driveResult: _Drive.signIn), _startMove, 'Not now'),
          ('offline', () => _World(driveResult: _Drive.offline), _startMove, 'Not now'),
          ('failed', () => _World(driveResult: _Drive.broken), _startMove, 'Not now'),
          ('ending', _noPremium, _openEnding, 'Not now'),
          ('ending, subscriber', _premiumNoSync, _openEnding, 'Not now'),
          ('ending, connect Strava', _noAccount, _openEnding, 'Not now'),
        ]) {
      testWidgets('$label: the sheet can be closed', (tester) async {
        await open(tester, world(), steps);
        await tester.tap(find.text(button));
        await _pump(tester);
        expect(find.byType(BottomSheet), findsNothing, reason: label);
      });
    }

    testWidgets('running: the sheet stays until the move ends, then shows the result', (tester) async {
      final read = Completer<SelectedData?>();
      final world = _World();
      when(world.drive.readSyncData).thenAnswer((_) => read.future);
      await open(tester, world, _startMove);

      await tester.binding.handlePopRoute();
      await _pump(tester);
      expect(find.text('Moving your Google Drive data…'), findsOneWidget, reason: 'back does not close a running move');

      read.complete(null);
      await _pump(tester);
      expect(find.text('Nothing to move'), findsOneWidget);
    });

    testWidgets('ending, subscriber: turning on cloud sync closes the notice and turns the flag on', (tester) async {
      final world = await open(tester, _premiumNoSync(), _openEnding);
      await tester.tap(find.text('Turn on cloud sync'));
      await _pump(tester);

      expect(world.settings.enableCloudSync, isTrue);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Cloud sync is on.'), findsOneWidget);
    });

    for (final (label, world, title) in <(String, _World Function(), String)>[
      ('move', _World.new, 'Move to cloud sync'),
      ('ending', _noPremium, 'Google Drive sync is ending'),
    ]) {
      testWidgets('$label: a dismissed notice opens again from the Drive sheet', (tester) async {
        await open(tester, world(), _openDriveSheet);
        await tester.tap(find.text(title));
        await _pump(tester);

        expect(find.byType(GoogleDriveSheet), findsNothing, reason: '$label: the Drive sheet makes room');
        expect(find.byType(BottomSheet), findsOneWidget, reason: label);
        expect(find.text('Not now'), findsOneWidget, reason: label);
      });
    }
  });
}
