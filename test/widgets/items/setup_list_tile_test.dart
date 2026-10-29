import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/widgets/current_setup_badge.dart';
import 'package:bike_setup_tracker/widgets/current_setup_highlight.dart';
import 'package:bike_setup_tracker/widgets/feedback/open_issues_chips.dart';
import 'package:bike_setup_tracker/widgets/feedback/setup_rank_badge.dart';
import 'package:bike_setup_tracker/widgets/items/setup_tile.dart';
import 'package:bike_setup_tracker/widgets/items/setup_tile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'setup_tile_harness.dart';

/// Guards the card → tile conversion (2026-07-27): the setup row is a plain
/// full-bleed row, it carries at most one trailing badge, and the current
/// setup is marked by [CurrentSetupHighlight] rather than a border.
void main() {
  late SetupTileHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await SetupTileHarness.create();
  });

  tearDown(() => harness.dispose());

  Future<void> pumpTile(
    WidgetTester tester,
    Setup setup, {
    double width = 400,
    bool showCurrentBadge = false,
  }) async {
    await tester.pumpWidget(
      harness.wrap(
        SetupTile(
          setupId: setup.id,
          onTap: null,
          showCurrentBadge: showCurrentBadge,
        ),
        width: width,
      ),
    );
    await settle(tester);
  }

  /// Two setups a day apart; only Rebound changes, so collapsed hides the
  /// Pressure cell. Returns (older, newer).
  Future<(Setup, Setup)> seedPair(WidgetTester tester) async {
    final older = harness.buildSetup(
      name: 'Older Setup',
      local: DateTime(2026, 7, 1, 10),
      values: {SetupTileHarness.reboundId: const StepValue(5), SetupTileHarness.pressureId: const StepValue(80)},
    );
    final newer = harness.buildSetup(
      name: 'Newer Setup',
      local: DateTime(2026, 7, 2, 10),
      values: {SetupTileHarness.reboundId: const StepValue(7), SetupTileHarness.pressureId: const StepValue(80)},
    );
    await harness.addSetups(tester, [older, newer]);
    await harness.reload(tester);
    return (older, newer);
  }

  testWidgets('renders without a Card of its own', (tester) async {
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup);

    expect(find.byType(SetupTile), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SetupTile), matching: find.byType(Card)),
      findsNothing,
    );
  });

  testWidgets('the current setup gets the bar/tint highlight', (tester) async {
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup);

    // The latest setup of a bike is its current one.
    expect(harness.repository.setupHistory.isCurrent(setup.id), isTrue);
    expect(find.byType(CurrentSetupHighlight), findsOneWidget);
  });

  testWidgets('the Current badge shows when requested', (tester) async {
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup, showCurrentBadge: true);

    expect(find.byType(CurrentSetupBadge), findsOneWidget);
  });

  testWidgets('a non-current setup renders neither badge nor highlight', (tester) async {
    final (older, _) = await seedPair(tester);
    await pumpTile(tester, older);

    expect(find.byType(CurrentSetupBadge), findsNothing);
    expect(find.byType(CurrentSetupHighlight), findsNothing);
  });

  testWidgets('the expand icon toggles between changed-only and all values', (tester) async {
    final (_, newer) = await seedPair(tester);
    await pumpTile(tester, newer);

    expect(find.text('Rebound'), findsOneWidget);
    expect(find.text('Pressure'), findsNothing);

    await tester.tap(find.byType(ExpandIcon));
    await settle(tester);

    expect(find.text('Rebound'), findsOneWidget);
    expect(find.text('Pressure'), findsOneWidget);
  });

  testWidgets('a very long setup name does not overflow a narrow row', (tester) async {
    final setup = harness.buildSetup(
      name: 'L' * 200,
      local: DateTime(2026, 7, 2, 10),
      values: {SetupTileHarness.reboundId: const StepValue(5)},
    );
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup, width: 320);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Compare is present for a current only setup', (tester) async {
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);

    expect(find.text('Compare'), findsOneWidget);
  });

  testWidgets('Compare is present for a historical setup with a current peer', (tester) async {
    final (older, _) = await seedPair(tester);
    await pumpTile(tester, older);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);

    expect(find.text('Compare'), findsOneWidget);
  });

  group('feedback', () {
    /// A ride on [newer], rated better than [older], that flagged a harsh front.
    RideFeedback rideOn(Setup newer, Setup older, {required int hour}) {
      final local = DateTime(2026, 7, 2, hour);
      return RideFeedback(
        bike: SetupTileHarness.bikeId,
        setupId: newer.id,
        dateTimeUTC: local.toUtc(),
        dateTimeLocal: local,
        observations: {const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort))},
        comparisons: {FeedbackComparison(referenceSetupId: older.id, aspect: const OverallAspect(), outcome: 1)},
      );
    }

    Future<void> seedFeedback(WidgetTester tester, List<RideFeedback> feedbacks) async {
      await tester.runAsync(() => harness.repository.addFeedbacks(feedbacks));
      await harness.reload(tester);
      await tester.runAsync(() async {
        var attempts = 0;
        while (!feedbacks.every((f) => harness.repository.feedbacks.containsKey(f.id)) && attempts < 20) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          attempts++;
        }
      });
    }

    testWidgets('shows the rank only once it is confident, and open issues only when tiles list them', (tester) async {
      harness.settings.enableRating = true;
      final (older, newer) = await seedPair(tester);
      await seedFeedback(tester, [rideOn(newer, older, hour: 12)]);
      await pumpTile(tester, newer);

      expect(harness.repository.rankFor(newer.id)!.isConfident, isFalse);
      expect(find.byType(SetupRankBadge), findsNothing);
      expect(
        find.descendant(of: find.byType(OpenIssuesChips), matching: find.text('Front: Harsh')),
        SetupTileHeader.showOpenIssuesInTiles ? findsOneWidget : findsNothing,
      );

      await seedFeedback(tester, [rideOn(newer, older, hour: 14)]);
      await pumpTile(tester, newer);

      expect(find.text('1/2 compared'), findsOneWidget);
    });

    testWidgets('lists the open issues below the notes', (tester) async {
      harness.settings.enableRating = true;
      final older = harness.buildSetup(name: 'Older Setup', local: DateTime(2026, 7, 1, 10));
      final newer = harness.buildSetup(name: 'Newer Setup', local: DateTime(2026, 7, 2, 10), notes: 'Setup notes');
      await harness.addSetups(tester, [older, newer]);
      await harness.reload(tester);
      await seedFeedback(tester, [rideOn(newer, older, hour: 12)]);
      await pumpTile(tester, newer);

      final notesBottom = tester.getBottomLeft(find.text('Setup notes')).dy;
      expect(tester.getTopLeft(find.text('Front: Harsh')).dy, greaterThanOrEqualTo(notesBottom));
    }, skip: !SetupTileHeader.showOpenIssuesInTiles);

    testWidgets('shows nothing while Feedback is off', (tester) async {
      harness.settings.enableRating = false;
      final (older, newer) = await seedPair(tester);
      await seedFeedback(tester, [rideOn(newer, older, hour: 12), rideOn(newer, older, hour: 14)]);
      await pumpTile(tester, newer);

      expect(find.byType(SetupRankBadge), findsNothing);
      expect(find.byType(OpenIssuesChips), findsNothing);
    });
  });
}
