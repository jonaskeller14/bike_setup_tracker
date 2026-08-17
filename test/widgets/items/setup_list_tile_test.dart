import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/widgets/current_setup_badge.dart';
import 'package:bike_setup_tracker/widgets/current_setup_highlight.dart';
import 'package:bike_setup_tracker/widgets/items/setup_list_tile.dart';
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
        SetupListTile(
          setupId: setup.id,
          onTap: null,
          displayBikeAdjustmentValues: true,
          displayPersonAdjustmentValues: true,
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
      values: {SetupTileHarness.reboundId: 5, SetupTileHarness.pressureId: 80},
    );
    final newer = harness.buildSetup(
      name: 'Newer Setup',
      local: DateTime(2026, 7, 2, 10),
      values: {SetupTileHarness.reboundId: 7, SetupTileHarness.pressureId: 80},
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

    expect(find.byType(SetupListTile), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SetupListTile), matching: find.byType(Card)),
      findsNothing,
    );
  });

  testWidgets('the current setup gets the bar/tint highlight', (tester) async {
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup);

    // The latest setup of a bike is its current one.
    expect(harness.repository.setups[setup.id]!.isCurrent, isTrue);
    expect(find.byType(CurrentSetupHighlight), findsOneWidget);
  });

  testWidgets('the Current badge shows only while there is no score', (tester) async {
    harness.settings.enableRating = true;
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup, showCurrentBadge: true);

    // No rating entries yet, so the row has no score to show instead.
    expect(harness.repository.scoreForSetup(setup.id), isNull);
    expect(find.byType(CurrentSetupBadge), findsOneWidget);
    expect(find.textContaining('/ 10'), findsNothing);
  });

  testWidgets('a non-current setup renders neither badge nor highlight', (tester) async {
    final (older, _) = await seedPair(tester);
    await pumpTile(tester, older);

    expect(find.byType(CurrentSetupBadge), findsNothing);
    expect(find.byType(CurrentSetupHighlight), findsNothing);
  });

  testWidgets('no score badge when rating is disabled', (tester) async {
    harness.settings.enableRating = false;
    final (_, newer) = await seedPair(tester);
    await pumpTile(tester, newer);

    expect(find.textContaining('/ 10'), findsNothing);
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
      values: {SetupTileHarness.reboundId: 5},
    );
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup, width: 320);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Compare is absent for a current only setup', (tester) async {
    final setup = harness.buildSetup(name: 'Solo', local: DateTime(2026, 7, 2, 10));
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);
    await pumpTile(tester, setup);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);

    expect(find.text('Compare'), findsNothing);
  });

  testWidgets('Compare is present for a historical setup with a current peer', (tester) async {
    final (older, _) = await seedPair(tester);
    harness.settings.enableSetupComparison = true;
    await pumpTile(tester, older);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);

    expect(find.text('Compare'), findsOneWidget);
  });

  testWidgets('Compare stays hidden while the setup comparison flag is off', (tester) async {
    final (older, _) = await seedPair(tester);
    await pumpTile(tester, older);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);

    expect(find.text('Compare'), findsNothing);
  });
}
