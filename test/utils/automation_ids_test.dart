import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/pages/details/strava_activitiy_details_page.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/pages/home_page.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/utils/automation_ids.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../goldens/support/golden_test_harness.dart';

void main() {
  late GoldenTestHarness harness;

  setUp(() async {
    harness = await GoldenTestHarness.create();
    harness.settings
      ..enableTask = true
      ..enableCalendar = true;
  });

  tearDown(() => harness.dispose());

  void useGoldenViewport(WidgetTester tester) {
    tester.view
      ..physicalSize = goldenViewport
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('AutomationIds', () {
    testWidgets('HomePage exposes navigation, garage and setup list identifiers', (tester) async {
      useGoldenViewport(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ChangeNotifierProvider<StravaService>(
          create: (_) => StravaService(harness.repository, harness.settings),
          child: harness.wrap(brightness: Brightness.light, child: const HomePage()),
        ),
      );
      await settleGolden(tester);

      for (final id in [AutomationIds.navBikes, AutomationIds.navSetups, AutomationIds.navTasks]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      expect(find.bySemanticsIdentifier(AutomationIds.addSetupFab), findsOneWidget);
      expect(find.bySemanticsIdentifier(AutomationIds.setupListCalendar), findsOneWidget);
      final setupFabNodeId = tester.getSemantics(find.bySemanticsIdentifier(AutomationIds.addSetupFab)).id;

      await tester.tap(find.bySemanticsIdentifier(AutomationIds.navBikes));
      await settleGolden(tester);

      // The tabs share the FAB slot. An identifier-only change on a reused
      // node never reaches the platform (it doesn't mark the node dirty), so
      // the bike FAB must get a node of its own.
      expect(find.bySemanticsIdentifier(AutomationIds.addBikeFab), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsIdentifier(AutomationIds.addBikeFab)).id, isNot(setupFabNodeId));
      expect(find.bySemanticsIdentifier(AutomationIds.garageBike(GoldenTestHarness.trailBikeId)), findsOneWidget);
      expect(find.bySemanticsIdentifier(AutomationIds.garageComponent(GoldenTestHarness.forkId)), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier(AutomationIds.garageComponent(GoldenTestHarness.forkId)));
      await settleGolden(tester);
      await tester.ensureVisible(find.bySemanticsIdentifier(AutomationIds.componentActions));
      await settleGolden(tester);
      await tester.tap(find.bySemanticsIdentifier(AutomationIds.componentActions));
      // The bike card's onDoubleTap holds single taps inside it until the
      // double-tap timeout expires.
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();

      final duplicate = find.semantics.byPredicate(
        (node) =>
            !node.isMergedIntoParent && node.getSemanticsData().identifier == AutomationIds.componentActionsDuplicate,
      );
      expect(duplicate, findsOne);
      expect(duplicate.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('SetupPage exposes form and adjustment input identifiers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness.wrap(
          brightness: Brightness.light,
          child: SetupPage.edit(setup: harness.newerSetup),
        ),
      );
      await settleGolden(tester);

      for (final id in [
        AutomationIds.setupFormName,
        AutomationIds.setupFormNotes,
        AutomationIds.setAdjustment(GoldenTestHarness.pressureId),
        AutomationIds.setAdjustment(GoldenTestHarness.reboundId),
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      semantics.dispose();
    });

    testWidgets('Strava actions menu exposes view-on-map on the merged, tappable menu item', (tester) async {
      final semantics = tester.ensureSemantics();
      final activity = StravaActivity(
        id: 1,
        name: 'Activity',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2026, 6, 20),
        startDateLocal: DateTime(2026, 6, 20),
        gearId: null,
        startLat: 44.0,
        startLon: 8.0,
        distance: 1000,
        totalElevationGain: 100,
        movingTime: const Duration(minutes: 30),
        elapsedTime: const Duration(minutes: 35),
      );
      await tester.pumpWidget(
        harness.wrap(
          brightness: Brightness.light,
          child: Scaffold(
            appBar: AppBar(
              actions: [
                Semantics(
                  container: true,
                  identifier: AutomationIds.stravaActivityActions,
                  child: StravaActivityActionsMenu(stravaActivity: activity),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsIdentifier(AutomationIds.stravaActivityActions));
      await tester.pumpAndSettle();

      // The label's node merges up into the menu item; platforms only receive the
      // merged node, whose data inherits the identifier.
      final viewOnMap = find.semantics.byPredicate(
        (node) =>
            !node.isMergedIntoParent && node.getSemanticsData().identifier == AutomationIds.stravaActivityViewOnMap,
      );
      expect(viewOnMap, findsOne);
      expect(viewOnMap.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  });
}
