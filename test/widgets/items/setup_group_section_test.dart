import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/widgets/current_setup_highlight.dart';
import 'package:bike_setup_tracker/widgets/items/setup_group_section.dart';
import 'package:bike_setup_tracker/widgets/items/setup_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'setup_tile_harness.dart';

/// Guards the group card → section conversion (2026-07-27): a header row plus
/// member rows, all members bound by one outlined container, no `Card`.
void main() {
  late SetupTileHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await SetupTileHarness.create();
  });

  tearDown(() => harness.dispose());

  // Rounded + bordered: excludes the hairline Dividers, which are Containers
  // with a bottom-only border and no radius.
  Finder borderedContainer() => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).border != null &&
        (w.decoration! as BoxDecoration).borderRadius != null,
  );

  Future<void> pumpGroup(WidgetTester tester, {int members = 3}) async {
    final setups = [
      for (var i = 0; i < members; i++)
        harness.buildSetup(
          name: 'Setup ${i + 1}',
          local: DateTime(2026, 7, 2, 10 + i),
          values: {SetupTileHarness.reboundId: 3 + i},
        ),
    ];
    await harness.addSetups(tester, setups);
    await harness.reload(tester);

    await tester.pumpWidget(
      harness.wrap(
        SetupGroupSection(
          setupIds: setups.map((s) => s.id).toList(),
          onTapSetup: null,
          displayBikeAdjustmentValues: true,
          displayPersonAdjustmentValues: true,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('renders a header plus one row per member, without a Card', (tester) async {
    await pumpGroup(tester);

    expect(find.text('3 Setups'), findsOneWidget);
    expect(find.byType(SetupListTile), findsNWidgets(3));
    expect(
      find.descendant(of: find.byType(SetupGroupSection), matching: find.byType(Card)),
      findsNothing,
    );
  });

  testWidgets('embedded setup rows omit the setup icon', (tester) async {
    await pumpGroup(tester);

    expect(find.byIcon(Setup.iconData), findsOneWidget);
  });

  testWidgets('one container binds every member', (tester) async {
    await pumpGroup(tester);

    final tiles = find.byType(SetupListTile);
    for (var i = 0; i < 3; i++) {
      expect(
        find.ancestor(of: tiles.at(i), matching: borderedContainer()),
        findsOneWidget,
        reason: 'member $i must sit inside exactly one bordered container',
      );
    }
    // ...and it is the same one for all of them.
    expect(borderedContainer(), findsOneWidget);
  });

  testWidgets('only the current member is highlighted', (tester) async {
    await pumpGroup(tester);

    expect(find.byType(CurrentSetupHighlight), findsOneWidget);

    final highlighted = tester.widget<SetupListTile>(
      find.ancestor(
        of: find.byType(CurrentSetupHighlight),
        matching: find.byType(SetupListTile),
      ),
    );
    final currentId =
        harness.repository.setups.values.firstWhere((s) => s.isCurrent).id;
    expect(highlighted.setupId, currentId);
  });

  testWidgets('a single-setup group renders a plain tile', (tester) async {
    await pumpGroup(tester, members: 1);

    expect(find.textContaining('Setups'), findsNothing);
    expect(find.byType(SetupListTile), findsOneWidget);
    expect(borderedContainer(), findsNothing);
  });
}
