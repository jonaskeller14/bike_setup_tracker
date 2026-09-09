import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/strava/strava_gear.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/strava_gear_link_tile.dart';
import 'package:bike_setup_tracker/widgets/lists/strava_gear_link_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StravaGear gear(int index) => StravaGear(id: "g$index", name: "Gear $index");

  Bike bikeFor(StravaGear g) => Bike(name: "Bike ${g.name}", person: null, stravaGear: g.id);

  Widget buildList({required List<StravaGear> gears, required List<Bike> bikes}) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: StravaGearLinkList(gears: gears, bikes: bikes),
        ),
      ),
    );
  }

  group("StravaGearLinkList visibility", () {
    testWidgets("shows every gear and no toggle at or below the cap", (tester) async {
      final gears = [gear(1), gear(2), gear(3)];
      await tester.pumpWidget(buildList(gears: gears, bikes: [bikeFor(gears.first)]));

      expect(find.byType(StravaGearLinkTile), findsNWidgets(3));
      expect(find.textContaining("Show all"), findsNothing);
    });

    testWidgets("fills the collapsed list with unlinked gear first", (tester) async {
      final gears = [gear(1), gear(2), gear(3), gear(4), gear(5)];
      final bikes = [bikeFor(gears[0]), bikeFor(gears[1]), bikeFor(gears[2])];

      await tester.pumpWidget(buildList(gears: gears, bikes: bikes));

      expect(find.byType(StravaGearLinkTile), findsNWidgets(3));
      expect(find.text("Gear 4"), findsOneWidget);
      expect(find.text("Gear 5"), findsOneWidget);
      expect(find.text("Show all (5)"), findsOneWidget);
    });

    testWidgets("caps the collapsed list at three even when nothing is linked", (tester) async {
      final gears = [gear(1), gear(2), gear(3), gear(4), gear(5)];

      await tester.pumpWidget(buildList(gears: gears, bikes: const []));

      expect(find.byType(StravaGearLinkTile), findsNWidgets(3));
      expect(find.text("Gear 4"), findsNothing);
      expect(find.text("Show all (5)"), findsOneWidget);
    });

    testWidgets("hides linked gear while unlinked gear fills the cap", (tester) async {
      final gears = [gear(1), gear(2), gear(3), gear(4), gear(5)];
      final bikes = [bikeFor(gears[0]), bikeFor(gears[1])];

      await tester.pumpWidget(buildList(gears: gears, bikes: bikes));

      expect(find.text("Gear 1"), findsNothing);
      expect(find.text("Gear 2"), findsNothing);
      expect(find.text("Gear 3"), findsOneWidget);
      expect(find.text("Gear 4"), findsOneWidget);
      expect(find.text("Gear 5"), findsOneWidget);
    });

    testWidgets("expands and collapses again via the toggle", (tester) async {
      final gears = [gear(1), gear(2), gear(3), gear(4), gear(5)];
      final bikes = gears.map(bikeFor).toList();

      await tester.pumpWidget(buildList(gears: gears, bikes: bikes));
      expect(find.byType(StravaGearLinkTile), findsNWidgets(3));

      await tester.tap(find.text("Show all (5)"));
      await tester.pumpAndSettle();
      expect(find.byType(StravaGearLinkTile), findsNWidgets(5));

      await tester.tap(find.text("Show less"));
      await tester.pumpAndSettle();
      expect(find.byType(StravaGearLinkTile), findsNWidgets(3));
    });
  });

  group("StravaGearLinkList header", () {
    testWidgets("counts linked gear while some is still unlinked", (tester) async {
      final gears = [gear(1), gear(2), gear(3)];
      await tester.pumpWidget(buildList(gears: gears, bikes: [bikeFor(gears.first)]));

      expect(find.text("1 of 3 linked"), findsOneWidget);
    });

    testWidgets("hides the counter once every gear is linked", (tester) async {
      final gears = [gear(1), gear(2)];
      await tester.pumpWidget(buildList(gears: gears, bikes: gears.map(bikeFor).toList()));

      expect(find.textContaining("linked"), findsNothing);
    });
  });
}
