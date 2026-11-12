// Renders every state of the account UI (account page, its dialogs and
// SnackBars, the unrequested sign-out notices, the Strava disconnect dialog
// and the account errors on the Strava sheet) to PNGs in
// build/gallery/account/ (git-ignored), for a visual check after changing any
// of them. Skipped by default (see dart_test.yaml); run it on demand with:
//
//   flutter test test/gallery/account_gallery_test.dart --run-skipped
//
// overview_light.png and overview_dark.png hold everything on one page; each
// state is also written on its own.
//
// Names that start with "my" are user data (Strava athlete, device names).
// "STAND-IN SETTINGS" is the page the account page returns to, not real UI.
//
// Besides the pictures, the second group checks that no state traps the
// user: sign out stays reachable while the devices can't be shown, a failed
// call can be retried, and the Strava errors leave a way back.
@Tags(['gallery'])
library;

import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/daos/sync_dao.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/service_error.dart';
import 'package:bike_setup_tracker/models/strava/strava_athlete.dart';
import 'package:bike_setup_tracker/models/strava/strava_plan.dart';
import 'package:bike_setup_tracker/pages/settings/account_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/account_service.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/widgets/account_notice_listener.dart';
import 'package:bike_setup_tracker/widgets/dialogs/strava_disconnect.dart';
import 'package:bike_setup_tracker/widgets/sheets/strava.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';
import 'gallery_harness.dart';

class _MockAppRepository extends Mock implements AppRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockSyncDao extends Mock implements SyncDao {}

class _MockSubscriptionService extends Mock implements SubscriptionService {}

class _MockStravaService extends Mock implements StravaService {}

const _phone = Size(360, 760);
const _narrow = Size(320, 568);
const _tablet = Size(800, 1100);

const _thisDevice = 'device-this';
final _lastSeen = DateTime(2026, 11, 12, 9, 30);

AccountDevice _device(String id, String platform, String name, {DateTime? lastSeen}) =>
    AccountDevice(deviceId: id, platform: platform, deviceName: name, lastSeenAt: lastSeen);

final _thisPhone = _device(_thisDevice, 'android', 'myPixel 8', lastSeen: _lastSeen);
final _otherPhone = _device('device-ipad', 'ios', 'myiPhone 15', lastSeen: DateTime(2026, 11, 3));

final _manyDevices = [
  _thisPhone,
  _otherPhone,
  _device('device-tablet', 'android', 'myGalaxy Tab S9', lastSeen: DateTime(2026, 10, 20)),
  _device('device-mac', 'macos', 'myMacBook Pro', lastSeen: DateTime(2026, 9, 1)),
  _device('device-web', 'web', '', lastSeen: DateTime(2026, 8, 15)),
  _device('device-win', 'windows', '', lastSeen: DateTime(2026, 7, 2)),
  _device('device-unknown', 'fuchsia', '', lastSeen: DateTime(2026, 6, 30)),
  _device('device-never', 'ios', 'myOld iPad'),
];

final _longNames = [
  _device(
    _thisDevice,
    'android',
    'myVeryLongDeviceNameThatKeepsGoing Ultra Pro Max 5G (2026 edition)',
    lastSeen: _lastSeen,
  ),
  _device('device-long', 'ios', 'myAnotherExtremelyLongDeviceNameWithoutAnySpacesAtAllToBreak', lastSeen: _lastSeen),
];

final _activeEntitlement = StravaEntitlement(
  plan: StravaPlan.values.first,
  expiresAt: DateTime(2027, 3, 1),
  productId: 'strava_sync',
  platform: 'android',
  autoRenewing: true,
  billingPhase: StravaBillingPhase.standard,
);

final _cancelledEntitlement = StravaEntitlement(
  plan: StravaPlan.values.first,
  expiresAt: DateTime(2027, 3, 1),
  productId: 'strava_sync',
  platform: 'android',
  autoRenewing: false,
  billingPhase: StravaBillingPhase.standard,
);

final _expiredEntitlement = StravaEntitlement(
  plan: StravaPlan.values.first,
  expiresAt: DateTime(2025, 1, 1),
  productId: 'strava_sync',
  platform: 'android',
  autoRenewing: false,
  billingPhase: StravaBillingPhase.standard,
);

typedef _DevicesSource = Stream<List<AccountDevice>> Function();

Stream<List<AccountDevice>> _loaded(List<AccountDevice> devices) => Stream.value(devices);

Stream<List<AccountDevice>> _neverLoads() => StreamController<List<AccountDevice>>().stream;

Stream<List<AccountDevice>> _fails() => Stream.error(StateError('permission-denied'));

/// [AccountService] with the server calls replaced, so each state can be set
/// up directly.
class _GalleryAccountService extends AccountService {
  _GalleryAccountService({required this.devices}) : super(clearLocalData: ({required removeData}) async {});

  _DevicesSource devices;
  String? thisDeviceId = _thisDevice;
  Future<void> Function() onSignOut = () async {};
  Future<void> Function() onRevoke = () async {};
  Future<AccountDeletionResult> Function() onDelete = () async => (subscriptionRenews: false, platform: null);
  final signOutCalls = <bool>[];
  final revokeCalls = <String>[];
  AccountNotice? _pending;

  @override
  String? get deviceId => thisDeviceId;

  @override
  bool get isOnAccount => true;

  @override
  Stream<List<AccountDevice>> watchDevices() => devices();

  @override
  Future<void> signOut({required bool removeData}) {
    signOutCalls.add(removeData);
    return onSignOut();
  }

  @override
  Future<void> revokeDevice(String deviceId) {
    revokeCalls.add(deviceId);
    return onRevoke();
  }

  @override
  Future<AccountDeletionResult> deleteAccount({required bool removeData}) => onDelete();

  @override
  AccountNotice? takeNotice() {
    final notice = _pending;
    _pending = null;
    return notice;
  }

  void announce(AccountNotice notice) {
    _pending = notice;
    notifyListeners();
  }
}

class _World {
  final _GalleryAccountService account;
  final _MockSubscriptionService subscription;
  final _MockStravaService strava;
  final _MockAppRepository repository;
  final AppSettings settings;

  _World._(this.account, this.subscription, this.strava, this.repository, this.settings);

  factory _World({
    String? firstname = 'myAthleteFirst',
    String? lastname = 'myAthleteLast',
    bool hasAthlete = true,
    StravaEntitlement? entitlement,
    bool noEntitlement = false,
    _DevicesSource? devices,
    bool cloudSync = false,
    int pendingChanges = 0,
    StravaFailure? stravaFailure,
  }) {
    final repository = _MockAppRepository();
    when(() => repository.stravaAthletes).thenReturn({
      if (hasAthlete) 1: StravaAthlete(id: 1, firstname: firstname, lastname: lastname, profile: null, gears: const {}),
    });
    final database = _MockAppDatabase();
    final syncDao = _MockSyncDao();
    when(() => repository.database).thenReturn(database);
    when(() => database.syncDao).thenReturn(syncDao);
    when(syncDao.watchPendingCount).thenAnswer((_) => Stream.value(pendingChanges));

    final subscription = _MockSubscriptionService();
    final effective = noEntitlement ? null : entitlement ?? _activeEntitlement;
    when(() => subscription.entitlement).thenReturn(effective);
    when(() => subscription.hasStravaEntitlement).thenReturn(effective?.isActive ?? false);
    when(() => subscription.isRestoring).thenReturn(false);
    when(() => subscription.justPurchasedStrava).thenReturn(false);

    final strava = _MockStravaService();
    when(() => strava.isConnected).thenReturn(false);
    when(() => strava.failure).thenReturn(stravaFailure);
    when(() => strava.state).thenReturn(stravaFailure == null ? const StravaIdle() : StravaFailed(stravaFailure.kind));
    when(strava.clearError).thenReturn(null);
    when(strava.launchStravaLogin).thenAnswer((_) async {});

    final settings = AppSettings()
      ..enableAccounts = true
      ..enableCloudSync = cloudSync;

    return _World._(
      _GalleryAccountService(devices: devices ?? () => _loaded([_thisPhone, _otherPhone])),
      subscription,
      strava,
      repository,
      settings,
    );
  }
}

const _homeKey = ValueKey('home');

/// The app around the account UI, with the page the account page returns to.
Widget _app(ThemeData theme, _World world, {required Key key, required GlobalKey<NavigatorState> navigator}) {
  return RepaintBoundary(
    key: key,
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider<AppRepository>.value(value: world.repository),
        ChangeNotifierProvider<AppSettings>.value(value: world.settings),
        ChangeNotifierProvider<AccountService>.value(value: world.account),
        ChangeNotifierProvider<SubscriptionService>.value(value: world.subscription),
        ChangeNotifierProvider<StravaService>.value(value: world.strava),
      ],
      child: localizedTestApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigator,
        theme: theme,
        builder: (context, child) => AccountNoticeListener(child: child!),
        home: Scaffold(
          key: _homeKey,
          appBar: AppBar(title: const Text('STAND-IN SETTINGS')),
        ),
      ),
    ),
  );
}

/// Pumps long enough for route, dialog and SnackBar transitions, without
/// waiting for the spinners to settle (they never do).
Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

enum _Shot { screen, dialog, snackBar, sheet }

class _Case {
  final String slug;
  final String title;
  final _World Function() world;
  final Size size;
  final double textScale;
  final TargetPlatform? platform;
  final bool openPage;
  final _Shot shot;

  /// Taps and calls that lead from the opened page (or the stand-in settings
  /// page) to the state.
  final Future<void> Function(WidgetTester tester, _World world)? steps;

  const _Case(
    this.slug,
    this.title,
    this.world, {
    this.size = _phone,
    this.textScale = 1,
    this.platform,
    this.openPage = true,
    this.shot = _Shot.screen,
    this.steps,
  });
}

Future<void> _tapText(WidgetTester tester, String text, {Type? within}) async {
  final finder = within == null ? find.text(text) : find.descendant(of: find.byType(within), matching: find.text(text));
  await tester.tap(finder.last);
  await _pump(tester);
}

Future<void> _openSignOut(WidgetTester tester, _World world) => _tapText(tester, 'Sign out of this device');

Future<void> _confirmSignOut(WidgetTester tester, _World world) async {
  await _openSignOut(tester, world);
  await _tapText(tester, 'Sign out', within: AlertDialog);
}

Future<void> _openSignOutOther(WidgetTester tester, _World world) async {
  await tester.tap(find.byTooltip('Sign out device').first);
  await _pump(tester);
}

Future<void> _confirmSignOutOther(WidgetTester tester, _World world) async {
  await _openSignOutOther(tester, world);
  await tester.tap(find.widgetWithText(TextButton, 'Sign out').last);
  await _pump(tester);
}

Future<void> _openDelete(WidgetTester tester, _World world) => _tapText(tester, 'Delete account');

Future<void> _confirmDelete(WidgetTester tester, _World world) async {
  await _openDelete(tester, world);
  await _tapText(tester, 'Delete account', within: AlertDialog);
}

Future<void> Function(WidgetTester, _World) _announce(AccountNotice notice) => (tester, world) async {
  world.account.announce(notice);
  await _pump(tester);
};

BuildContext _homeContext(WidgetTester tester) => tester.element(find.byKey(_homeKey));

Future<void> _openStravaDisconnect(WidgetTester tester, _World world) async {
  unawaited(showStravaDisconnectDialog(_homeContext(tester)));
  await _pump(tester);
}

Future<void> _openStravaSheet(WidgetTester tester, _World world) async {
  unawaited(showStravaSheet(context: _homeContext(tester)));
  await _pump(tester);
}

final _cases = <_Case>[
  // Account page: header.
  const _Case('page_header_athlete', 'Page · athlete name, subscription renews', _World.new),
  _Case('page_header_no_athlete', 'Page · no athlete (Strava disconnected)', () => _World(hasAthlete: false)),
  _Case('page_header_first_name_only', 'Page · athlete with first name only', () => _World(lastname: null)),
  _Case(
    'page_header_empty_names',
    'Page · athlete without a name (same as none)',
    () => _World(firstname: null, lastname: null),
  ),
  _Case(
    'page_header_long_name',
    'Page · long athlete name',
    () => _World(firstname: 'myAthleteWithAVeryLongFirstNameIndeed', lastname: 'myAndAnEvenLongerLastName'),
  ),
  _Case(
    'page_premium_cancelled',
    'Page · subscription cancelled, ends later',
    () => _World(entitlement: _cancelledEntitlement),
  ),
  _Case('page_premium_expired', 'Page · subscription expired', () => _World(entitlement: _expiredEntitlement)),
  _Case('page_premium_none', 'Page · never subscribed', () => _World(noEntitlement: true)),
  // Account page: devices.
  _Case('page_devices_loading', 'Page · devices loading', () => _World(devices: _neverLoads)),
  _Case('page_devices_error', 'Page · devices failed to load', () => _World(devices: _fails)),
  _Case('page_devices_empty', 'Page · no devices (session list empty)', () => _World(devices: () => _loaded(const []))),
  _Case('page_devices_one', 'Page · only this device', () => _World(devices: () => _loaded([_thisPhone]))),
  _Case(
    'page_devices_this_missing',
    'Page · this device missing from the list',
    () => _World(devices: () => _loaded([_otherPhone])),
  ),
  _Case(
    'page_devices_many',
    'Page · many devices (platform names, unknown platform, never seen)',
    () => _World(devices: () => _loaded(_manyDevices)),
  ),
  _Case('page_devices_long', 'Page · long device names', () => _World(devices: () => _loaded(_longNames))),
  _Case(
    'page_busy',
    'Page · busy (signing out)',
    _World.new,
    steps: (tester, world) async {
      world.account.onSignOut = () => Completer<void>().future;
      await _confirmSignOut(tester, world);
    },
  ),
  // Sizes.
  _Case(
    'page_narrow',
    'Page · narrow phone (320 pt)',
    () => _World(devices: () => _loaded(_manyDevices)),
    size: _narrow,
  ),
  _Case('page_tablet', 'Page · tablet', () => _World(devices: () => _loaded(_manyDevices)), size: _tablet),
  _Case(
    'page_large_text',
    'Page · large text (200 %)',
    () => _World(devices: () => _loaded(_longNames)),
    textScale: 2,
  ),
  // Dialogs.
  const _Case(
    'dialog_sign_out',
    'Dialog · sign out, remove data on (default)',
    _World.new,
    shot: _Shot.dialog,
    steps: _openSignOut,
  ),
  _Case(
    'dialog_sign_out_keep',
    'Dialog · sign out, remove data off',
    _World.new,
    shot: _Shot.dialog,
    steps: (tester, world) async {
      await _openSignOut(tester, world);
      await tester.tap(find.byType(CheckboxListTile));
      await _pump(tester);
    },
  ),
  _Case(
    'dialog_unsynced',
    'Dialog · unsynced changes (cloud sync on, 3 pending)',
    () => _World(cloudSync: true, pendingChanges: 3),
    shot: _Shot.dialog,
    steps: _confirmSignOut,
  ),
  _Case(
    'dialog_unsynced_one',
    'Dialog · unsynced changes (1 pending)',
    () => _World(cloudSync: true, pendingChanges: 1),
    shot: _Shot.dialog,
    steps: _confirmSignOut,
  ),
  const _Case(
    'dialog_sign_out_other',
    'Dialog · sign out another device',
    _World.new,
    shot: _Shot.dialog,
    steps: _openSignOutOther,
  ),
  _Case(
    'dialog_sign_out_other_long',
    'Dialog · sign out another device, long name',
    () => _World(devices: () => _loaded(_longNames)),
    shot: _Shot.dialog,
    steps: _openSignOutOther,
  ),
  const _Case('dialog_delete', 'Dialog · delete account', _World.new, shot: _Shot.dialog, steps: _openDelete),
  _Case(
    'dialog_renewing_android',
    'Dialog · subscription still renews (Play)',
    _World.new,
    shot: _Shot.dialog,
    steps: (tester, world) async {
      world.account.onDelete = () async => (subscriptionRenews: true, platform: 'android');
      await _confirmDelete(tester, world);
    },
  ),
  _Case(
    'dialog_renewing_ios',
    'Dialog · subscription still renews (App Store)',
    _World.new,
    shot: _Shot.dialog,
    steps: (tester, world) async {
      world.account.onDelete = () async => (subscriptionRenews: true, platform: 'ios');
      await _confirmDelete(tester, world);
    },
  ),
  const _Case(
    'dialog_sign_out_ios',
    'Dialog · sign out on iOS',
    _World.new,
    platform: TargetPlatform.iOS,
    shot: _Shot.dialog,
    steps: _openSignOut,
  ),
  const _Case(
    'dialog_sign_out_other_ios',
    'Dialog · sign out another device on iOS',
    _World.new,
    platform: TargetPlatform.iOS,
    shot: _Shot.dialog,
    steps: _openSignOutOther,
  ),
  const _Case(
    'dialog_delete_ios',
    'Dialog · delete account on iOS',
    _World.new,
    platform: TargetPlatform.iOS,
    shot: _Shot.dialog,
    steps: _openDelete,
  ),
  const _Case(
    'dialog_delete_narrow',
    'Dialog · delete account, narrow phone',
    _World.new,
    size: _narrow,
    shot: _Shot.dialog,
    steps: _openDelete,
  ),
  const _Case(
    'dialog_delete_large_text',
    'Dialog · delete account, large text',
    _World.new,
    textScale: 2,
    shot: _Shot.dialog,
    steps: _openDelete,
  ),
  const _Case(
    'dialog_sign_out_tablet',
    'Dialog · sign out, tablet',
    _World.new,
    size: _tablet,
    shot: _Shot.dialog,
    steps: _openSignOut,
  ),
  // SnackBars after an action.
  const _Case('snack_signed_out', 'SnackBar · signed out', _World.new, shot: _Shot.snackBar, steps: _confirmSignOut),
  _Case(
    'snack_sign_out_failed',
    'SnackBar · sign out failed',
    _World.new,
    shot: _Shot.snackBar,
    steps: (tester, world) async {
      world.account.onSignOut = () async => throw StateError('offline');
      await _confirmSignOut(tester, world);
    },
  ),
  const _Case(
    'snack_device_signed_out',
    'SnackBar · other device signed out',
    _World.new,
    shot: _Shot.snackBar,
    steps: _confirmSignOutOther,
  ),
  _Case(
    'snack_device_signed_out_long',
    'SnackBar · other device signed out, long name',
    () => _World(devices: () => _loaded(_longNames)),
    shot: _Shot.snackBar,
    steps: _confirmSignOutOther,
  ),
  _Case(
    'snack_device_failed',
    'SnackBar · other device sign out failed',
    _World.new,
    shot: _Shot.snackBar,
    steps: (tester, world) async {
      world.account.onRevoke = () async => throw StateError('offline');
      await _confirmSignOutOther(tester, world);
    },
  ),
  const _Case('snack_deleted', 'SnackBar · account deleted', _World.new, shot: _Shot.snackBar, steps: _confirmDelete),
  _Case(
    'snack_delete_failed',
    'SnackBar · delete failed',
    _World.new,
    shot: _Shot.snackBar,
    steps: (tester, world) async {
      world.account.onDelete = () async => throw StateError('offline');
      await _confirmDelete(tester, world);
    },
  ),
  // Notices of an unrequested sign-out (shown wherever the user is).
  _Case(
    'notice_revoked',
    'Notice · signed out from another device, data removed',
    _World.new,
    openPage: false,
    shot: _Shot.snackBar,
    steps: _announce(AccountNotice.sessionRevoked),
  ),
  _Case(
    'notice_revoked_kept',
    'Notice · signed out from another device, data kept',
    _World.new,
    openPage: false,
    shot: _Shot.snackBar,
    steps: _announce(AccountNotice.sessionRevokedDataKept),
  ),
  _Case(
    'notice_deleted',
    'Notice · account deleted on another device',
    _World.new,
    openPage: false,
    shot: _Shot.snackBar,
    steps: _announce(AccountNotice.accountDeleted),
  ),
  _Case(
    'notice_deleted_large_text',
    'Notice · account deleted, large text',
    _World.new,
    textScale: 2,
    openPage: false,
    shot: _Shot.snackBar,
    steps: _announce(AccountNotice.accountDeleted),
  ),
  // Strava.
  const _Case(
    'strava_disconnect_account',
    'Strava · disconnect on an account',
    _World.new,
    openPage: false,
    shot: _Shot.dialog,
    steps: _openStravaDisconnect,
  ),
  const _Case(
    'strava_disconnect_account_ios',
    'Strava · disconnect on an account, iOS',
    _World.new,
    platform: TargetPlatform.iOS,
    openPage: false,
    shot: _Shot.dialog,
    steps: _openStravaDisconnect,
  ),
  _Case(
    'strava_owned_by_other',
    'Strava sheet · athlete owned by another account',
    () => _World(stravaFailure: const StravaFailure(StravaErrorKind.ownedByOtherAccount)),
    openPage: false,
    shot: _Shot.sheet,
    steps: _openStravaSheet,
  ),
  _Case(
    'strava_limit_reached',
    'Strava sheet · limit reached (also manual stop)',
    () => _World(stravaFailure: const StravaFailure(StravaErrorKind.limitReached)),
    openPage: false,
    shot: _Shot.sheet,
    steps: _openStravaSheet,
  ),
  _Case(
    'strava_owned_by_other_large_text',
    'Strava sheet · owned by another account, large text',
    () => _World(stravaFailure: const StravaFailure(StravaErrorKind.ownedByOtherAccount)),
    textScale: 2,
    openPage: false,
    shot: _Shot.sheet,
    steps: _openStravaSheet,
  ),
];

Future<_World> _show(
  WidgetTester tester,
  ThemeData theme,
  _Case c,
  Key key, {
  _World? world,
}) async {
  final w = world ?? c.world();
  final navigator = GlobalKey<NavigatorState>();
  tester.view.physicalSize = c.size;
  tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
  await tester.pumpWidget(
    _app(
      c.platform == null ? theme : theme.copyWith(platform: c.platform),
      w,
      key: key,
      navigator: navigator,
    ),
  );
  await _pump(tester);
  if (c.openPage) {
    unawaited(navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const AccountPage())));
    await _pump(tester);
  }
  await c.steps?.call(tester, w);
  return w;
}

Rect? _crop(WidgetTester tester, _Case c) {
  final screen = Offset.zero & c.size;
  switch (c.shot) {
    case _Shot.screen || _Shot.dialog:
      return null;
    case _Shot.snackBar:
      final bar = tester.getRect(find.byType(SnackBar));
      return Rect.fromLTRB(0, (bar.top - 24).clamp(0, screen.bottom), screen.right, screen.bottom);
    case _Shot.sheet:
      return tester.getRect(find.byType(BottomSheet)).intersect(screen);
  }
}

void main() {
  late Directory output;

  setUpAll(() async => output = await prepareGallery('account'));

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
        await session.add(c.slug, c.title, tester.renderObject(find.byKey(key)), crop: _crop(tester, c));
      }

      await session.finish();
    });
  }

  group('no state traps the user', () {
    Future<_World> open(WidgetTester tester, _World world) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      return _show(tester, galleryThemes.first.$2, _Case('trap', 'trap', () => world), UniqueKey(), world: world);
    }

    for (final (label, source) in <(String, _DevicesSource)>[
      ('devices loading', _neverLoads),
      ('devices failed to load', _fails),
      ('no devices', () => _loaded(const [])),
      ('this device missing from the list', () => _loaded([_otherPhone])),
    ]) {
      testWidgets('$label: signing out still works', (tester) async {
        final world = await open(tester, _World(devices: source));
        await _confirmSignOut(tester, world);
        expect(world.account.signOutCalls, [true], reason: label);
        expect(find.byType(AccountPage), findsNothing, reason: '$label: the page stays open after signing out');
      });
    }

    testWidgets('devices failed to load: reopening the page loads them', (tester) async {
      var attempt = 0;
      final world = await open(tester, _World(devices: () => attempt++ == 0 ? _fails() : _loaded([_thisPhone])));
      expect(find.text('Your devices could not be loaded.'), findsOneWidget);
      await tester.pageBack();
      await _pump(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => const AccountPage())));
      await _pump(tester);
      expect(find.text('myPixel 8'), findsOneWidget);
      expect(world.account.signOutCalls, isEmpty);
    });

    testWidgets('a failed sign out can be retried', (tester) async {
      final world = await open(tester, _World());
      world.account.onSignOut = () async => throw StateError('offline');
      await _confirmSignOut(tester, world);
      expect(find.byType(AccountPage), findsOneWidget);
      world.account.onSignOut = () async {};
      await _confirmSignOut(tester, world);
      expect(world.account.signOutCalls, [true, true]);
      expect(find.byType(AccountPage), findsNothing);
    });

    testWidgets('a failed sign out of another device can be retried', (tester) async {
      final world = await open(tester, _World());
      world.account.onRevoke = () async => throw StateError('offline');
      await _confirmSignOutOther(tester, world);
      world.account.onRevoke = () async {};
      await tester.pump(const Duration(seconds: 6));
      await _confirmSignOutOther(tester, world);
      expect(world.account.revokeCalls, ['device-ipad', 'device-ipad']);
    });

    testWidgets('a failed account deletion can be retried', (tester) async {
      final world = await open(tester, _World());
      world.account.onDelete = () async => throw StateError('offline');
      await _confirmDelete(tester, world);
      expect(find.byType(AccountPage), findsOneWidget);
      world.account.onDelete = () async => (subscriptionRenews: false, platform: null);
      await _confirmDelete(tester, world);
      expect(find.byType(AccountPage), findsNothing);
    });

    testWidgets('unsynced changes: cancelling keeps the device signed in', (tester) async {
      final world = await open(tester, _World(cloudSync: true, pendingChanges: 3));
      await _confirmSignOut(tester, world);
      await _tapText(tester, 'Cancel');
      expect(world.account.signOutCalls, isEmpty);
      expect(find.byType(AccountPage), findsOneWidget);
    });

    for (final kind in [StravaErrorKind.ownedByOtherAccount, StravaErrorKind.limitReached]) {
      testWidgets('Strava sheet ${kind.name}: signing in again clears the error', (tester) async {
        final world = _World(stravaFailure: StravaFailure(kind));
        await open(tester, world);
        await tester.pageBack();
        await _pump(tester);
        await _openStravaSheet(tester, world);
        await tester.tap(find.text('Sign in to Strava'));
        await _pump(tester);
        verify(world.strava.clearError).called(1);
        verify(world.strava.launchStravaLogin).called(1);
      });
    }
  });
}
