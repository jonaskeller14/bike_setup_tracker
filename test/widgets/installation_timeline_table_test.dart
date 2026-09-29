import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/installation_timeline_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

Component component(String id, ComponentType type, List<Installation> installations, {String? name}) =>
    Component(id: id, name: name ?? id, installations: installations, componentType: type);

Installation onBike(int day) => BikeInstallation(
  bikeId: 'bike',
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation onComponent(String parentId, int day) => ComponentInstallation(
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

void main() {
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings();
  });

  tearDown(() => appSettings.dispose());

  Widget createWidgetUnderTest(List<Component> components, {ThemeData? theme, double width = 800}) {
    return ChangeNotifierProvider.value(
      value: appSettings,
      child: MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: InstallationTimelineTable(
                  bikeId: 'bike',
                  componentHierarchy: ComponentHierarchyResolver({for (final c in components) c.id: c}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final wheelAndTire = [
    component('fork', ComponentType.fork, [onBike(1)], name: 'Fox 36'),
    component('wheel', ComponentType.wheelFront, [onBike(1)], name: 'Wheel A'),
    component('tire', ComponentType.tire, [onComponent('wheel', 3)], name: 'Tire X'),
  ];

  group('InstallationTimelineTable', () {
    testWidgets('shows direct and nested components with the parent caption', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(wheelAndTire));

      expect(find.byType(TableView), findsOneWidget);
      expect(find.text('Fox 36'), findsOneWidget);
      expect(find.text('Wheel A'), findsNWidgets(2)); // block + tire caption
      expect(find.text('Tire X'), findsOneWidget);
      expect(find.byIcon(Icons.subdirectory_arrow_right), findsOneWidget);
    });

    testWidgets('keeps the parent caption when the parent type is hidden', (tester) async {
      // Four active types; `other` sorts last and is hidden by default.
      await tester.pumpWidget(
        createWidgetUnderTest([
          component('frame', ComponentType.frame, [onBike(1)], name: 'Frame V2'),
          component('fork', ComponentType.fork, [onBike(1)], name: 'Fox 36'),
          component('mount', ComponentType.other, [onBike(1)], name: 'Mount'),
          component('shock', ComponentType.shock, [onComponent('mount', 2)], name: 'Float X2'),
        ]),
      );

      expect(find.text('Component Types 3/4'), findsOneWidget);
      expect(find.text('Float X2'), findsOneWidget);
      expect(find.text('Mount'), findsOneWidget, reason: 'only the caption, the other column is hidden');
    });

    testWidgets('groups row labels by day', (tester) async {
      final components = [
        component('fork', ComponentType.fork, [
          BikeInstallation(
            bikeId: 'bike',
            dateTimeUTC: DateTime.utc(2026, 1, 1, 8),
            dateTimeLocal: DateTime(2026, 1, 1, 8),
          ),
          Uninstallation(dateTimeUTC: DateTime.utc(2026, 1, 1, 12), dateTimeLocal: DateTime(2026, 1, 1, 12)),
        ]),
      ];
      await tester.pumpWidget(createWidgetUnderTest(components));

      expect(find.text(DateFormat(appSettings.dateFormat).format(DateTime(2026, 1, 1))), findsOneWidget);
    });

    testWidgets('long names render without overflow on a narrow screen', (tester) async {
      final longName = 'Very long component name ' * 5;
      final components = [
        component('wheel', ComponentType.wheelFront, [onBike(1)], name: longName),
        component('tire', ComponentType.tire, [onComponent('wheel', 1)], name: longName),
      ];
      await tester.pumpWidget(createWidgetUnderTest(components, width: 320));

      expect(tester.takeException(), isNull);
    });

    testWidgets('a one-row nested block grows its row beyond the minimum', (tester) async {
      DateTime utcAt(int hour) => DateTime.utc(2026, 1, 1, hour);
      DateTime localAt(int hour) => DateTime(2026, 1, 1, hour);
      // Rows at 08, 09, 10 and 12; the tire covers only the time-only row 09–10
      // and needs room for its parent caption.
      await tester.pumpWidget(
        createWidgetUnderTest([
          component('wheel', ComponentType.wheelFront, [
            BikeInstallation(bikeId: 'bike', dateTimeUTC: utcAt(8), dateTimeLocal: localAt(8)),
            Uninstallation(dateTimeUTC: utcAt(12), dateTimeLocal: localAt(12)),
          ], name: 'Wheel A'),
          component('tire', ComponentType.tire, [
            ComponentInstallation(parentComponentId: 'wheel', dateTimeUTC: utcAt(9), dateTimeLocal: localAt(9)),
            Uninstallation(dateTimeUTC: utcAt(10), dateTimeLocal: localAt(10)),
          ], name: 'Tire X'),
        ]),
      );

      final tireBlock = find.ancestor(of: find.text('Tire X'), matching: find.byType(InkWell));
      expect(tester.getSize(tireBlock).height, greaterThan(44));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the empty state when nothing was installed on the bike', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest([
          component('fork', ComponentType.fork, const []),
        ]),
      );

      expect(find.text('No installation history'), findsOneWidget);
      expect(find.byType(TableView), findsNothing);
    });

    testWidgets('tapping a block offers component details and installation editing', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(wheelAndTire));

      await tester.tap(find.text('Fox 36'));
      await tester.pumpAndSettle();

      expect(find.text('Component details'), findsOneWidget);
      expect(find.text('Edit installation'), findsOneWidget);
    });

    testWidgets('a block that starts with its parent\'s installation still offers editing', (tester) async {
      // The tire sits on the wheel before the wheel reaches the bike, so the
      // block starts at the wheel's event, not the tire's own one.
      await tester.pumpWidget(
        createWidgetUnderTest([
          component('wheel', ComponentType.wheelFront, [onBike(3)], name: 'Wheel A'),
          component('tire', ComponentType.tire, [onComponent('wheel', 1)], name: 'Tire X'),
        ]),
      );

      await tester.tap(find.text('Tire X'));
      await tester.pumpAndSettle();

      expect(find.text('Edit installation'), findsOneWidget);
    });

    for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('renders in $name theme', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(wheelAndTire, theme: theme));

        expect(find.text('Tire X'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
