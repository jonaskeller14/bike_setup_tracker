import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_installation_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest({
    List<Installation> initialInstallations = const [],
    List<Installation>? originalInstallations,
    Function(List<Installation>)? onChanged,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          // Wrap in SingleChildScrollView to avoid layout overflows in test environment
          body: SingleChildScrollView(
            child: SetInstallationTimeline(
              initialInstallations: initialInstallations,
              originalInstallations: originalInstallations,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('SetInstallationTimeline', () {
    testWidgets('renders initial installations with bike names', (WidgetTester tester) async {
      final bike = Bike(id: 'bike1', name: 'Mountain Bike', person: 'Me');
      
      await tester.runAsync(() async {
        await appRepository.addBike(bike);
        // Wait for repository cache to pick up the change from the stream
        // to avoid DropdownButton assertion errors
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      final now = DateTime.now();
      final installations = [
        Installation(parent: 'bike1', dateTimeUTC: now, dateTimeLocal: now),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: installations,
      ));
      
      // Give it time to build the items
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Mountain Bike'), findsOneWidget);
    });

    testWidgets('disables delete button if only one entry', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBike(Bike(id: 'bike1', name: 'Bike 1', person: 'Me'));
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      final installations = [
        Installation.sinceBeginning(parent: 'bike1'),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: installations,
      ));
      await tester.pumpAndSettle();

      final deleteButton = find.ancestor(of: find.byIcon(Icons.delete_outline), matching: find.byType(IconButton));
      expect(deleteButton, findsOneWidget);
      expect(tester.widget<IconButton>(deleteButton).onPressed, isNull);
    });

    // testWidgets('validation: prevents uninstalled from beginning', (WidgetTester tester) async {
    //   final installations = [
    //     Installation.sinceBeginning(parent: null),
    //   ];

    //   await tester.pumpWidget(createWidgetUnderTest(
    //     initialInstallations: installations,
    //   ));
    //   await tester.pumpAndSettle();

    //   final formFieldState = tester.state<FormFieldState<List<Installation>>>(find.byType(FormField<List<Installation>>));
    //   formFieldState.validate();
    //   await tester.pumpAndSettle();

    //   expect(find.text('"From beginning" entries must be associated with a bike'), findsOneWidget);
    // });

    testWidgets('validation: prevents consecutive installations on same bike', (WidgetTester tester) async {
      final bike = Bike(id: 'bike1', name: 'Bike A', person: 'Me');
      await tester.runAsync(() async {
        await appRepository.addBike(bike);
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      final now = DateTime.now();
      final installations = [
        Installation(parent: 'bike1', dateTimeUTC: now.subtract(const Duration(hours: 1)), dateTimeLocal: now.subtract(const Duration(hours: 1))),
        Installation(parent: 'bike1', dateTimeUTC: now, dateTimeLocal: now),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: installations,
      ));
      await tester.pumpAndSettle();

      final formFieldState = tester.state<FormFieldState<List<Installation>>>(find.byType(FormField<List<Installation>>));
      formFieldState.validate();
      await tester.pump(); // Allow error text to appear
      await tester.pumpAndSettle();

      expect(find.text('Cannot have consecutive installations on the same bike'), findsOneWidget);
    });

    testWidgets('validation: prevents multiple from beginning entries', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBike(Bike(id: 'bike1', name: 'Bike 1', person: 'Me'));
        await appRepository.addBike(Bike(id: 'bike2', name: 'Bike 2', person: 'Me'));
        int attempts = 0;
        while (appRepository.bikes.length < 2 && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      final installations = [
        Installation.sinceBeginning(parent: 'bike1'),
        Installation.sinceBeginning(parent: 'bike2'),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: installations,
      ));
      await tester.pumpAndSettle();

      final formFieldState = tester.state<FormFieldState<List<Installation>>>(find.byType(FormField<List<Installation>>));
      formFieldState.validate();
      await tester.pumpAndSettle();

      expect(formFieldState.errorText, contains('Multiple "From beginning"'));
      expect(find.textContaining('Multiple "From beginning"'), findsOneWidget);
    });

    testWidgets('popup menu disables "From beginning" if another entry has it', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBike(Bike(id: 'bike1', name: 'Bike 1', person: 'Me'));
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      final now = DateTime.now();
      final installations = [
        Installation.sinceBeginning(parent: 'bike1'),
        Installation(parent: null, dateTimeUTC: now, dateTimeLocal: now),
      ];

      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: installations,
      ));
      await tester.pumpAndSettle();

      final popups = find.bySubtype<PopupMenuButton<dynamic>>();
      await tester.tap(popups.at(1));
      await tester.pumpAndSettle();

      // Look for the item in the overlay (popup menu)
      final popupMenuItemFinder = find.byWidgetPredicate((widget) => 
        widget is PopupMenuItem && 
        widget.child is Text && 
        (widget.child as Text).data == 'From beginning'
      );
      
      final menuItem = tester.widget<PopupMenuItem<dynamic>>(popupMenuItemFinder);
      expect(menuItem.enabled, isFalse);
    });
  });
}
