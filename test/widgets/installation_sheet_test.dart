import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_installation.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_installation_timeline.dart';
import 'package:bike_setup_tracker/widgets/sheets/installation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppRepository extends Mock implements AppRepository {}

void main() {
  late MockAppRepository mockRepository;
  late AppSettings appSettings;
  late Bike bike1;
  late Bike bike2;
  late Component component;

  setUpAll(() {
    registerFallbackValue(Component(
      id: 'dummy',
      name: 'dummy',
      componentType: ComponentType.fork,
      installations: [],
      adjustments: [],
    ));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = MockAppRepository();
    appSettings = AppSettings();
    appSettings.enableInstallationTimeline = true;
    bike1 = Bike(id: 'b1', name: 'Bike 1', person: 'P1');
    bike2 = Bike(id: 'b2', name: 'Bike 2', person: 'P2');
    component = Component(
      id: 'c1',
      name: 'Fork',
      componentType: ComponentType.fork,
      installations: [
        Installation.sinceBeginning(parent: 'b1'),
      ],
      adjustments: [],
    );

    when(() => mockRepository.bikes).thenReturn({'b1': bike1, 'b2': bike2});
    when(() => mockRepository.filteredBikes).thenReturn({'b1': bike1, 'b2': bike2});
    when(() => mockRepository.editComponent(any())).thenAnswer((_) async => {});
  });

  Widget createWidgetUnderTest(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider<AppRepository>.value(value: mockRepository),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('InstallationSheet', () {
    testWidgets('renders correct origin and target', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        InstallationSheet.add(
          component: component,
          targetBikeId: 'b2',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bike 1'), findsAtLeast(1)); // Origin
      expect(find.text('Bike 2'), findsAtLeast(1)); // Target in preview AND in dropdown
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('confirms changes calls editComponent', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        InstallationSheet.add(
          component: component,
          targetBikeId: 'b2',
        ),
      ));

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.editComponent(any())).called(1);
    });
  });

  group('InstallationSheet preview panel', () {
    group('add mode', () {
      testWidgets('bike to bike: shows origin, arrow and target', (WidgetTester tester) async {
        // component.bike = 'b1', targeting b2
        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.add(component: component, targetBikeId: 'b2'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('Bike 2'), findsAtLeast(1));
      });

      testWidgets('initial installation: shows arrow and target only, no origin', (WidgetTester tester) async {
        final freshComponent = Component(
          id: 'c_new',
          name: 'Fork',
          componentType: ComponentType.fork,
          installations: [],
          adjustments: [],
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.add(component: freshComponent, targetBikeId: 'b1'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        // No origin _BikePreview — 'Archive' must not appear (target is a valid bike)
        expect(find.text('Archive'), findsNothing);
      });

      testWidgets('archive origin: shows Archive label for origin', (WidgetTester tester) async {
        // Component whose latest installation has parent=null (archived/uninstalled)
        final now = DateTime.now();
        final archivedComponent = Component(
          id: 'c_arch',
          name: 'Fork',
          componentType: ComponentType.fork,
          installations: [
            Installation.sinceBeginning(parent: 'b1'),
            Archival(dateTimeUTC: now.toUtc(), dateTimeLocal: now),
          ],
          adjustments: [],
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.add(component: archivedComponent, targetBikeId: 'b2'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Archive'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('Bike 2'), findsAtLeast(1));
      });

      testWidgets('bike to archive: shows Archive label for target', (WidgetTester tester) async {
        // component.bike = 'b1', archiving → target is an Archival
        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.add(component: component, targetBikeId: null, isArchiving: true),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('Archive'), findsAtLeast(1));
      });

      testWidgets('invalid target bike: shows BIKE NOT FOUND for target', (WidgetTester tester) async {
        // component.bike = 'b1', targeting a bike ID absent from the bikes map
        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.add(component: component, targetBikeId: 'b_missing'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('BIKE NOT FOUND'), findsAtLeast(1));
      });

      testWidgets('invalid origin bike: shows BIKE NOT FOUND for origin', (WidgetTester tester) async {
        // Component whose latest installation references a deleted/missing bike
        final componentOnMissing = Component(
          id: 'c_miss',
          name: 'Fork',
          componentType: ComponentType.fork,
          installations: [
            Installation.sinceBeginning(parent: 'b_missing'),
          ],
          adjustments: [],
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.add(component: componentOnMissing, targetBikeId: 'b1'),
        ));
        await tester.pumpAndSettle();

        expect(find.text('BIKE NOT FOUND'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('Bike 1'), findsAtLeast(1));
      });
    });

    group('edit mode', () {
      testWidgets('non-initial: shows origin, arrow and target', (WidgetTester tester) async {
        final now = DateTime.now();
        final installation = Installation(
          parent: 'b2',
          dateTimeUTC: now.toUtc(),
          dateTimeLocal: now,
        );
        final editEntry = ComponentInstallation(
          component: component,
          installation: installation,
          originParent: 'b1',
          originParentType: InstallationParentType.bike,
          isInitial: false,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.edit(component: component, editEntry: editEntry),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('Bike 2'), findsAtLeast(1));
      });

      testWidgets('initial: shows arrow and target only, no origin', (WidgetTester tester) async {
        final installation = Installation.sinceBeginning(parent: 'b1');
        final editEntry = ComponentInstallation(
          component: component,
          installation: installation,
          originParent: null,
          isInitial: true,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.edit(component: component, editEntry: editEntry),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        // No origin _BikePreview — 'Archive' must not appear
        expect(find.text('Archive'), findsNothing);
      });

      testWidgets('invalid target bike: shows BIKE NOT FOUND for target', (WidgetTester tester) async {
        final now = DateTime.now();
        final installation = Installation(
          parent: 'b_missing',
          dateTimeUTC: now.toUtc(),
          dateTimeLocal: now,
        );
        final editEntry = ComponentInstallation(
          component: component,
          installation: installation,
          originParent: 'b1',
          originParentType: InstallationParentType.bike,
          isInitial: false,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.edit(component: component, editEntry: editEntry),
        ));
        await tester.pumpAndSettle();

        expect(find.text('Bike 1'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('BIKE NOT FOUND'), findsAtLeast(1));
      });

      testWidgets('invalid origin bike: shows BIKE NOT FOUND for origin', (WidgetTester tester) async {
        final now = DateTime.now();
        final installation = Installation(
          parent: 'b2',
          dateTimeUTC: now.toUtc(),
          dateTimeLocal: now,
        );
        final editEntry = ComponentInstallation(
          component: component,
          installation: installation,
          originParent: 'b_missing',
          originParentType: InstallationParentType.bike,
          isInitial: false,
        );

        await tester.pumpWidget(createWidgetUnderTest(
          InstallationSheet.edit(component: component, editEntry: editEntry),
        ));
        await tester.pumpAndSettle();

        expect(find.text('BIKE NOT FOUND'), findsAtLeast(1));
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
        expect(find.text('Bike 2'), findsAtLeast(1));
      });
    });
  });

  group('SetInstallationTimeline with isEntryEditable', () {
    testWidgets('disables editing for non-editable entries', (WidgetTester tester) async {
      final now = DateTime.now();
      final installations = [
        Installation.sinceBeginning(parent: 'b1'),
        Installation(parent: 'b2', dateTimeUTC: now.toUtc(), dateTimeLocal: now),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        SetInstallationTimeline(
          initialInstallations: installations,
          isEntryEditable: (installation) => installation == installations[1], // Only the second one is editable
          onChanged: (_) {},
        ),
      ));

      // Check first entry (index 0)
      // The dropdown for the first entry should be disabled (onChanged is null)
      final firstDropdown = tester.widget<DropdownButtonFormField<Installation>>(
        find.byType(DropdownButtonFormField<Installation>).first
      );
      expect(firstDropdown.onChanged, isNull);

      // Check second entry (index 1)
      final secondDropdown = tester.widget<DropdownButtonFormField<Installation>>(
        find.byType(DropdownButtonFormField<Installation>).at(1)
      );
      expect(secondDropdown.onChanged, isNotNull);

      // Add button should be disabled when isEntryEditable is provided
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsNothing);
    });
  });
}
