import 'dart:async';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/account_service.dart';
import 'package:bike_setup_tracker/services/cloud_sync_service.dart';
import 'package:bike_setup_tracker/services/google_drive_service.dart';
import 'package:bike_setup_tracker/services/navigation_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/drive_notice_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../goldens/support/localized_test_app.dart';

class _MockAppRepository extends Mock implements AppRepository {}

/// Notifies like the real service when it becomes active or stops.
class _FakeCloudSyncService extends ChangeNotifier implements CloudSyncService {
  bool _active = true;

  @override
  bool get isActive => _active;

  set active(bool value) {
    _active = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSubscriptionService extends Mock implements SubscriptionService {}

class _MockGoogleDriveService extends Mock implements GoogleDriveService {}

class _MockAccountService extends Mock implements AccountService {}

void main() {
  late AppDatabase database;
  late AppSettings settings;
  late _FakeCloudSyncService sync;
  late _MockSubscriptionService subscription;
  late _MockAccountService account;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    settings = AppSettings();
    await settings.loadAppSettings();
    settings
      ..showOnboarding = false
      ..enableGoogleDrive = true;
    sync = _FakeCloudSyncService();
    subscription = _MockSubscriptionService();
    when(() => subscription.premiumIfKnown).thenReturn(true);
    account = _MockAccountService();
    when(() => account.isOnAccount).thenReturn(true);
  });

  tearDown(() => database.close());

  Widget app() => MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database),
      ChangeNotifierProvider<AppRepository>.value(value: _MockAppRepository()),
      ChangeNotifierProvider<AppSettings>.value(value: settings),
      ChangeNotifierProvider<CloudSyncService>.value(value: sync),
      ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
      ChangeNotifierProvider<GoogleDriveService>.value(value: _MockGoogleDriveService()),
      ChangeNotifierProvider<AccountService>.value(value: account),
    ],
    child: localizedTestApp(
      navigatorKey: NavigationService.navigatorKey,
      theme: materialAppTheme,
      home: const DriveNoticeListener(child: Scaffold()),
    ),
  );

  final moveTitle = find.text('Move to cloud sync');

  testWidgets('the move offer opens once, not after a rebuild or a restart', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(moveTitle, findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    sync.active = false;
    await tester.pumpAndSettle();
    sync.active = true;
    await tester.pumpAndSettle();
    expect(moveTitle, findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(moveTitle, findsNothing);
  });

  testWidgets('waits while a sheet covers the home route', (tester) async {
    sync.active = false;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    unawaited(
      showModalBottomSheet<void>(
        context: NavigationService.context!,
        builder: (_) => const Text('Other sheet'),
      ),
    );
    await tester.pumpAndSettle();

    sync.active = true;
    await tester.pumpAndSettle();
    expect(moveTitle, findsNothing);

    Navigator.of(NavigationService.context!).pop();
    await tester.pumpAndSettle();
    expect(moveTitle, findsOneWidget);
  });

  testWidgets('without a subscription the ending notice opens instead', (tester) async {
    sync.active = false;
    when(() => subscription.premiumIfKnown).thenReturn(false);
    settings.developerMode = true;

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Google Drive sync is ending'), findsOneWidget);
    expect(moveTitle, findsNothing);
  });

  testWidgets('a subscriber without cloud sync can turn it on, then gets the move offer', (tester) async {
    sync.active = false;
    settings.developerMode = true;

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Google Drive sync is ending'), findsOneWidget);

    await tester.tap(find.text('Turn on cloud sync'));
    await tester.pumpAndSettle();
    expect(settings.enableCloudSync, isTrue);
    expect(find.text('Cloud sync is on.'), findsOneWidget);
    expect(find.text('Google Drive sync is ending'), findsNothing, reason: 'the sync is starting, no notice');

    sync.active = true;
    await tester.pumpAndSettle();
    expect(moveTitle, findsOneWidget);
  });

  testWidgets('a subscriber with sync on but no account is asked to connect Strava', (tester) async {
    sync.active = false;
    settings
      ..developerMode = true
      ..enableCloudSync = true;
    when(() => account.isOnAccount).thenReturn(false);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Connect Strava'), findsOneWidget);
  });

  testWidgets('nothing opens for users without Google Drive', (tester) async {
    settings.enableGoogleDrive = false;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
  });
}
