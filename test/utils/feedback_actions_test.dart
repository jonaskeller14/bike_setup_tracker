import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/feedback_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/feedback_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bikeId = 'bike';

/// The feedback form keeps a location spinner running, so pumpAndSettle never returns.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Setup _setup(String id, DateTime local) => Setup(
  id: id,
  name: id.toUpperCase(),
  datetime: local.toUtc(),
  datetimeLocal: local,
  tags: const {},
  bike: _bikeId,
  person: null,
  bikeAdjustmentValues: const {},
  personAdjustmentValues: const {},
);

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  final s1Local = DateTime(2026, 5, 1, 10);
  final s2Local = DateTime(2026, 5, 2, 10);

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

  Future<void> seed(WidgetTester tester, {List<RideFeedback> feedbacks = const []}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
      await appRepository.addSetups([_setup('s1', s1Local), _setup('s2', s2Local)]);
      await appRepository.addFeedbacks(feedbacks);
      await waitFor(() => appRepository.setups.length == 2 && appRepository.feedbacks.length == feedbacks.length);
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
  }

  Future<void> pumpButton(WidgetTester tester, String label, Future<void> Function(BuildContext) onPressed) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(onPressed: () => onPressed(context), child: Text(label)),
            ),
          ),
        ),
      ),
    );
  }

  group('feedbackTimeFor', () {
    testWidgets('dates feedback on the active setup now', (tester) async {
      await seed(tester);
      final now = DateTime(2026, 6, 1, 18);

      final (utc, local) = FeedbackActions.feedbackTimeFor(appRepository, appRepository.setups['s2']!, now: now);

      expect(local, now);
      expect(utc, now.toUtc());
    });

    testWidgets('dates feedback on an older setup at its start, so it resolves to it', (tester) async {
      await seed(tester);
      final s1 = appRepository.setups['s1']!;

      final (utc, local) = FeedbackActions.feedbackTimeFor(appRepository, s1, now: DateTime(2026, 6, 1, 18));

      expect(local, s1Local);
      expect(appRepository.resolveSetupId(bikeId: _bikeId, atUtc: utc), 's1');
    });
  });

  testWidgets('addFeedbackForSetup saves a feedback that resolves to the setup', (tester) async {
    await seed(tester);
    await pumpButton(
      tester,
      'add',
      (context) => FeedbackActions.addFeedbackForSetup(context, setup: appRepository.setups['s1']!),
    );

    await tester.tap(find.text('add'));
    await settle(tester);
    expect(find.byType(FeedbackPage), findsOneWidget);

    final chip = find.widgetWithText(FilterChip, FeedbackVocabulary.nothingStoodOut);
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await settle(tester);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.runAsync(() => waitFor(() => appRepository.feedbacks.length == 1));
    await settle(tester);

    final saved = appRepository.feedbacks.values.single;
    expect(saved.setupId, 's1');
    expect(saved.dateTimeLocal, s1Local);
    expect(saved.nothingStoodOut, isTrue);
    expect(find.text('Feedback saved.'), findsOneWidget);
  });

  testWidgets('removeFeedback moves it to trash and UNDO restores it', (tester) async {
    final local = DateTime(2026, 5, 2, 12);
    final feedback = RideFeedback(
      id: 'f',
      bike: _bikeId,
      setupId: 's2',
      dateTimeUTC: local.toUtc(),
      dateTimeLocal: local,
      observations: {const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.grip))},
    );
    await seed(tester, feedbacks: [feedback]);
    await pumpButton(
      tester,
      'remove',
      (context) => FeedbackActions.removeFeedback(context, feedback: appRepository.feedbacks['f']!),
    );

    await tester.tap(find.text('remove'));
    await tester.pump();
    await tester.runAsync(() => waitFor(() => appRepository.feedbacks.isEmpty));
    await settle(tester);

    expect(appRepository.deletedFeedbacks.map((f) => f.id), ['f']);
    expect(find.text('Feedback moved to trash.'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pump();
    await tester.runAsync(() => waitFor(() => appRepository.feedbacks.length == 1));

    expect(appRepository.feedbacks['f']!.issues, {const IssueKey(FeedbackEnd.front, FeedbackAttribute.grip)});
  });
}

Future<void> waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
