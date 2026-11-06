import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/widgets/chips/setup_list_search.dart';
import 'package:bike_setup_tracker/widgets/items/test_session_timeline_item.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../items/setup_tile_harness.dart';

void main() {
  late SetupTileHarness harness;

  // A session started with a first run, which was then deleted.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await SetupTileHarness.create();
    await harness.hintService.dismiss(AppHint.gettingStartedV1);
    await harness.hintService.dismiss(AppHint.setupTasksV1);
    await harness.hintService.dismiss(AppHint.setupCalendarV1);
    harness.settings.enableRating = true;

    final started = DateTime(2026, 7, 2, 9);
    final repository = harness.repository;
    await repository.addTestSessions([
      TestSession(
        id: 'ts',
        bike: SetupTileHarness.bikeId,
        name: 'Rebound sweep',
        adjustmentIds: const [SetupTileHarness.reboundId],
        startedAtUTC: started.toUtc(),
        startedAtLocal: started,
      ),
    ]);
    final run = Setup(
      id: 'run',
      name: 'First run',
      datetime: started.toUtc(),
      datetimeLocal: started,
      tags: const {},
      bike: SetupTileHarness.bikeId,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
      testSessionId: 'ts',
    );
    await repository.addSetups([run]);
    await repository.removeSetups([run]);
    for (var attempt = 0; attempt < 100; attempt++) {
      if (repository.testSessions.containsKey('ts') && repository.setups.isEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });

  tearDown(() => harness.dispose());

  testWidgets('the timeline keeps a session whose only run was deleted', (tester) async {
    await tester.pumpWidget(harness.wrapFullScreen(const SetupList()));
    await settle(tester);

    expect(find.byType(TestSessionTimelineItem), findsOneWidget);
    expect(find.text('Rebound sweep'), findsOneWidget);
    expect(find.text('This session has no runs. Record one to go on.'), findsOneWidget);
    expect(find.text('First run'), findsNothing);
  });

  group('the search', () {
    Future<void> search(WidgetTester tester, String query) async {
      await tester.pumpWidget(harness.wrapFullScreen(const SetupListSearch()));
      await settle(tester);
      await tester.tap(find.byType(FilterChip));
      await settle(tester);
      await tester.enterText(find.byType(TextField), query);
      await settle(tester);
    }

    testWidgets('finds it by name', (tester) async {
      await search(tester, 'rebound');

      expect(find.byType(TestSessionTimelineItem), findsOneWidget);
      expect(find.text('This session has no runs. Record one to go on.'), findsOneWidget);
    });

    testWidgets('leaves it out when the query does not match', (tester) async {
      await search(tester, 'something else');

      expect(find.byType(TestSessionTimelineItem), findsNothing);
    });
  });
}
