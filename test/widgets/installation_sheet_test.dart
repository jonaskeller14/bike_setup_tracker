import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/widgets/sheets/installation_sheet.dart';
import 'package:bike_setup_tracker/widgets/set_installation_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
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
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('InstallationSheet', () {
    testWidgets('renders correct origin and target', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        InstallationSheet(
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
        InstallationSheet(
          component: component,
          targetBikeId: 'b2',
        ),
      ));

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.editComponent(any())).called(1);
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
          isEntryEditable: (index) => index == 1, // Only the second one is editable
          onChanged: (_) {},
        ),
      ));

      // Check first entry (index 0)
      // The dropdown for the first entry should be disabled (onChanged is null)
      final firstDropdown = tester.widget<DropdownButtonFormField<String?>>(
        find.byType(DropdownButtonFormField<String?>).first
      );
      expect(firstDropdown.onChanged, isNull);

      // Check second entry (index 1)
      final secondDropdown = tester.widget<DropdownButtonFormField<String?>>(
        find.byType(DropdownButtonFormField<String?>).at(1)
      );
      expect(secondDropdown.onChanged, isNotNull);
      
      // Add button should be disabled when isEntryEditable is provided
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsNothing); 
    });
  });
}
