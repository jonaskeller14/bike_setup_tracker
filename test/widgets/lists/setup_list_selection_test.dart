import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/timeline_selection.dart';
import 'package:bike_setup_tracker/widgets/items/setup_options_menu.dart';
import 'package:bike_setup_tracker/widgets/items/setup_tile.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../items/setup_tile_harness.dart';

void main() {
  final day = DateTime(2026, 7, 2);
  late SetupTileHarness harness;
  late Setup setup;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await SetupTileHarness.create();
    await harness.hintService.dismiss(AppHint.gettingStartedV1);
    await harness.hintService.dismiss(AppHint.setupTasksV1);
    await harness.hintService.dismiss(AppHint.setupCalendarV1);
    setup = harness.buildSetup(
      name: 'Timeline Setup',
      local: day.add(const Duration(hours: 12)),
      values: {SetupTileHarness.reboundId: 5},
    );
  });

  tearDown(() => harness.dispose());

  Future<void> pumpTimeline(
    WidgetTester tester, {
    Set<TimelineSelectionId> selection = const {},
    ValueChanged<TimelineSelectionId>? onSelectionChanged,
  }) async {
    await harness.addSetups(tester, [setup]);
    await harness.reload(tester);

    await tester.pumpWidget(
      harness.wrapFullScreen(
        SetupList(selection: selection, onSelectionChanged: onSelectionChanged),
      ),
    );
    await settle(tester);
  }

  testWidgets('long-pressing a setup row starts a selection', (tester) async {
    final toggled = <TimelineSelectionId>[];
    await pumpTimeline(tester, onSelectionChanged: toggled.add);

    expect(find.byType(SetupOptionsMenu), findsOneWidget);

    await tester.longPress(find.byType(SetupTile));
    await settle(tester);

    expect(toggled, [setupSelectionId(setup.id)]);
  });

  testWidgets('in selection mode a tap toggles instead of opening the row', (tester) async {
    final toggled = <TimelineSelectionId>[];
    await pumpTimeline(
      tester,
      selection: {setupSelectionId(setup.id)},
      onSelectionChanged: toggled.add,
    );

    // The options menu would compete with the toggle for the same row.
    expect(find.byType(SetupOptionsMenu), findsNothing);

    final primary = Theme.of(tester.element(find.byType(SetupTile))).colorScheme.primary;
    final leadingIcon = tester.widget<Icon>(
      find.descendant(of: find.byType(SetupTile), matching: find.byIcon(Setup.iconData)),
    );
    final title = tester.widget<Text>(
      find.descendant(of: find.byType(SetupTile), matching: find.text(setup.displayName)),
    );
    expect(leadingIcon.color, primary);
    expect(title.style?.color, primary);

    await tester.tap(find.byType(SetupTile));
    await settle(tester);

    expect(toggled, [setupSelectionId(setup.id)]);
  });
}
