import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/test_session_options_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../goldens/support/localized_test_app.dart';

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const blockedReason = 'Only the latest session on a bike can be resumed, and only if no setup was added since.';

  late AppDatabase database;
  late AppRepository appRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
  });

  Future<void> openMenu(WidgetTester tester, {required bool ended, bool newerSetup = false}) async {
    final started = DateTime(2026, 5, 2, 9);
    final finished = started.add(const Duration(hours: 3));
    final later = DateTime(2026, 5, 3, 9);
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      await appRepository.addBikes([Bike(id: 'bike', name: 'Test Bike', person: null)]);
      await appRepository.addTestSessions([
        TestSession(
          id: 'ts',
          bike: 'bike',
          adjustmentIds: const [],
          startedAtUTC: started.toUtc(),
          startedAtLocal: started,
          endedAtUTC: ended ? finished.toUtc() : null,
          endedAtLocal: ended ? finished : null,
        ),
      ]);
      if (newerSetup) {
        await appRepository.addSetups([
          Setup(
            id: 'newer',
            datetime: later.toUtc(),
            datetimeLocal: later,
            tags: const {},
            bike: 'bike',
            person: null,
            bikeAdjustmentValues: const {},
            personAdjustmentValues: const {},
          ),
        ]);
      }
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.testSessions.isNotEmpty && appRepository.setups.length == (newerSetup ? 1 : 0)) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        await database.close();
      });
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appRepository,
        child: localizedTestApp(
          theme: materialAppTheme,
          home: Scaffold(body: TestSessionOptionsMenu(session: appRepository.testSessions['ts']!)),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  bool resumeEnabled(WidgetTester tester) => tester
      .widget<PopupMenuItem<Object?>>(
        find.ancestor(of: find.text('Resume'), matching: find.byWidgetPredicate((w) => w is PopupMenuItem)),
      )
      .enabled;

  testWidgets('hides Resume while the session is running', (tester) async {
    await openMenu(tester, ended: false);

    expect(find.text('Resume'), findsNothing);
    expect(find.text(blockedReason), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('offers Resume without a reason when the session can run again', (tester) async {
    await openMenu(tester, ended: true);

    expect(resumeEnabled(tester), isTrue);
    expect(find.text(blockedReason), findsNothing);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.testSessions['ts']!.isRunning) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    expect(appRepository.testSessions['ts']!.isRunning, isTrue);
  });

  testWidgets('disables a blocked Resume and shows why, so a tap does nothing', (tester) async {
    await openMenu(tester, ended: true, newerSetup: true);

    expect(tester.takeException(), isNull);
    expect(resumeEnabled(tester), isFalse);
    expect(find.text(blockedReason), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Resume'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(blockedReason), findsOneWidget, reason: 'the menu stays open');
    expect(appRepository.testSessions['ts']!.isRunning, isFalse);
  });
}
