import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/pages/home_page.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/utils/automation_ids.dart';
import 'package:flutter/material.dart';
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

      await tester.tap(find.bySemanticsIdentifier(AutomationIds.navBikes));
      await settleGolden(tester);

      expect(find.bySemanticsIdentifier(AutomationIds.garageBike(GoldenTestHarness.trailBikeId)), findsOneWidget);
      expect(find.bySemanticsIdentifier(AutomationIds.garageComponent(GoldenTestHarness.forkId)), findsOneWidget);
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
  });
}
