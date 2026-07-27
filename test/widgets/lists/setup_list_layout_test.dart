import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/widgets/items/installation_list_tile.dart';
import 'package:bike_setup_tracker/widgets/items/setup_list_tile.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../items/setup_tile_harness.dart';

/// Guards the full-bleed timeline (2026-07-27): every row carries its own
/// 16 px content inset and adjacent rows are divided.
void main() {
  final day = DateTime(2026, 7, 2);
  late SetupTileHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = await SetupTileHarness.create(
      installationLocal: day.add(const Duration(hours: 9)),
    );
    harness.settings.showGettingStartedGuideHint = false;
    harness.settings.showSetupTaskHint = false;
    harness.settings.showSetupCalendarHint = false;
  });

  tearDown(() => harness.dispose());

  Future<void> pumpTimeline(WidgetTester tester, {required bool dayHeaders}) async {
    harness.settings.enableTimelineDayHeaders = dayHeaders;
    await harness.addSetups(tester, [
      harness.buildSetup(
        name: 'Timeline Setup',
        local: day.add(const Duration(hours: 12)),
        values: {SetupTileHarness.reboundId: 5},
      ),
    ]);
    await harness.reload(tester);

    await tester.pumpWidget(harness.wrapFullScreen(const SetupList()));
    await settle(tester);
  }

  for (final dayHeaders in [false, true]) {
    testWidgets('rows share one 16px inset (day headers: $dayHeaders)', (tester) async {
      await pumpTimeline(tester, dayHeaders: dayHeaders);

      expect(find.byType(SetupListTile), findsOneWidget);
      expect(find.byType(InstallationListTile), findsOneWidget);

      final setupIcon = find.descendant(
        of: find.byType(SetupListTile),
        matching: find.byIcon(Setup.iconData),
      );
      // The glyph itself is Transform.scale'd, which shifts its painted box —
      // measure the leading slot that holds it.
      final installationLeading = find
          .ancestor(
            of: find.descendant(
              of: find.byType(InstallationListTile),
              matching: find.byIcon(Icons.arrow_right_alt),
            ),
            matching: find.byType(Padding),
          )
          .first;

      expect(tester.getTopLeft(setupIcon).dx, 16);
      expect(tester.getTopLeft(installationLeading).dx, 16);
    });

    testWidgets('adjacent rows are divided (day headers: $dayHeaders)', (tester) async {
      await pumpTimeline(tester, dayHeaders: dayHeaders);

      expect(find.byType(Divider), findsWidgets);
    });
  }
}
