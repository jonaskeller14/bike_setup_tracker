import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/strava/strava_gear.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/pages/details/strava_activity_details_page.dart';
import 'package:bike_setup_tracker/pages/forms/bike_page.dart';
import 'package:bike_setup_tracker/pages/forms/component_page.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/pages/forms/task_entry_page.dart';
import 'package:bike_setup_tracker/pages/home_page.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/utils/automation_ids.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_list_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/rider_sheet.dart';
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

  /// The merged node a platform receives for [id], e.g. a menu item whose
  /// label carries the identifier.
  SemanticsFinder mergedNode(String id) => find.semantics.byPredicate(
    (node) => !node.isMergedIntoParent && node.getSemanticsData().identifier == id,
  );

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
      expect(find.bySemanticsIdentifier(AutomationIds.garageAddComponent(GoldenTestHarness.trailBikeId)), findsOneWidget);

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

    testWidgets('HomePage exposes the rider button identifier', (tester) async {
      useGoldenViewport(tester);
      harness.settings.enablePerson = true;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ChangeNotifierProvider<StravaService>(
          create: (_) => StravaService(harness.repository, harness.settings),
          child: harness.wrap(brightness: Brightness.light, child: const HomePage()),
        ),
      );
      await settleGolden(tester);

      final riderButton = find.bySemanticsIdentifier(AutomationIds.appBarRider);
      expect(riderButton, findsOneWidget);
      await tester.tap(riderButton);
      await settleGolden(tester);
      expect(find.byType(RiderSheetContent), findsOneWidget);
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
        AutomationIds.setupFormSave,
        AutomationIds.setupFormName,
        AutomationIds.setupFormNotes,
        AutomationIds.setupFormCondition,
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
    testWidgets('HomePage exposes the map, Strava and setup actions identifiers', (tester) async {
      useGoldenViewport(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ChangeNotifierProvider<StravaService>(
          create: (_) => StravaService(harness.repository, harness.settings),
          child: harness.wrap(brightness: Brightness.light, child: const HomePage()),
        ),
      );
      await settleGolden(tester);

      expect(find.bySemanticsIdentifier(AutomationIds.setupListMap), findsOneWidget);
      expect(find.bySemanticsIdentifier(AutomationIds.appBarStrava), findsOneWidget);

      final actions = find.bySemanticsIdentifier(AutomationIds.setupActions(GoldenTestHarness.newerSetupId));
      expect(actions, findsOneWidget);
      await tester.tap(actions);
      // The setup tile's onDoubleTap holds single taps until the timeout.
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();

      final compare = mergedNode(AutomationIds.setupActionsCompare);
      expect(compare, findsOne);
      expect(compare.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('BikePage exposes the save identifier', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness.wrap(brightness: Brightness.light, child: BikePage.add()));
      await settleGolden(tester);

      expect(find.bySemanticsIdentifier(AutomationIds.bikeFormSave), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('ComponentPage exposes the type, suggestion and adjustment form identifiers', (tester) async {
      useGoldenViewport(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness.wrap(brightness: Brightness.light, child: ComponentPage.add()));
      await settleGolden(tester);

      for (final id in [
        AutomationIds.componentFormType,
        AutomationIds.componentFormName,
        AutomationIds.componentFormAddAdjustment,
        AutomationIds.componentFormSave,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }

      await tester.tap(find.bySemanticsIdentifier(AutomationIds.componentFormType));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier(AutomationIds.componentType('fork')));
      await tester.pumpAndSettle();

      // Pressure opens the numerical form, Rebound the step form.
      for (final presetKey in ['fork:pressure', 'fork:rebound']) {
        await tester.tap(find.bySemanticsIdentifier(AutomationIds.componentFormAddAdjustment));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsIdentifier(AutomationIds.adjustmentPreset(presetKey)));
        await tester.pumpAndSettle();
        final save = find.bySemanticsIdentifier(AutomationIds.adjustmentFormSave);
        expect(save, findsOneWidget, reason: presetKey);
        await tester.tap(save);
        await tester.pumpAndSettle();
      }
      semantics.dispose();
    });

    testWidgets('Task list card and TaskEntryPage expose the complete and save identifiers', (tester) async {
      final rule = TaskRule(name: 'Bolt torque check', tags: const {});
      // Drift's I/O and the repository's watch stream run on real timers,
      // which testWidgets' fake clock doesn't advance.
      await tester.runAsync(() async {
        await harness.repository.addTaskRules([rule]);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness.wrap(
          brightness: Brightness.light,
          child: Scaffold(body: ListView(children: [TaskRuleListCard(taskRuleId: rule.id)])),
        ),
      );
      await settleGolden(tester);
      expect(find.bySemanticsIdentifier(AutomationIds.taskRuleComplete(rule.id)), findsOneWidget);

      await tester.pumpWidget(harness.wrap(brightness: Brightness.light, child: TaskEntryPage.add(taskRule: rule)));
      await settleGolden(tester);
      expect(find.bySemanticsIdentifier(AutomationIds.taskEntryFormSave), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Strava activity page exposes the setups identifier', (tester) async {
      const gearId = 'golden-gear';
      await tester.runAsync(() async {
        await harness.repository.setStravaGears([StravaGear(id: gearId, name: 'Trail bike')]);
        await harness.repository.editBikes([
          harness.repository.bikes[GoldenTestHarness.trailBikeId]!.copyWith(stravaGear: gearId),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      final semantics = tester.ensureSemantics();
      final activity = StravaActivity(
        id: 1,
        name: 'Activity',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2026, 6, 20),
        startDateLocal: DateTime(2026, 6, 20),
        gearId: gearId,
        startLat: 44.0,
        startLon: 8.0,
        distance: 1000,
        totalElevationGain: 100,
        movingTime: const Duration(minutes: 30),
        elapsedTime: const Duration(minutes: 35),
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<StravaService>(
          create: (_) => StravaService(harness.repository, harness.settings),
          child: harness.wrap(
            brightness: Brightness.light,
            child: Scaffold(body: StravaActivityPageContent(stravaActivity: activity)),
          ),
        ),
      );
      await settleGolden(tester);

      // The title keeps its own node inside the expansion header; Maestro taps
      // its bounds, which lie on the header.
      expect(mergedNode(AutomationIds.stravaActivitySetups), findsOne);
      semantics.dispose();
    });
  });
}
