import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
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
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest({
    List<Installation> initialInstallations = const [],
    List<Installation>? originalInstallations,
    void Function(List<Installation>)? onChanged,
    String? componentId,
    ComponentType? componentType,
    ThemeData? theme,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Scaffold(
          // Wrap in SingleChildScrollView to avoid layout overflows in test environment
          body: SingleChildScrollView(
            child: SetInstallationTimeline(
              componentId: componentId,
              componentType: componentType,
              initialInstallations: initialInstallations,
              originalInstallations: originalInstallations,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  /// Counts the entry fields painted with the error-colored border: the date
  /// pickers (`isDense`) or the bike dropdowns.
  int invalidBorderCount(WidgetTester tester, {required bool dateFields}) {
    final errorColor = materialAppTheme.colorScheme.error;
    return tester
        .widgetList<InputDecorator>(find.byType(InputDecorator))
        .where((d) => (d.decoration.isDense ?? false) == dateFields)
        .where((d) => d.decoration.enabledBorder?.borderSide.color == errorColor)
        .length;
  }

  group('SetInstallationTimeline', () {
    testWidgets('renders initial installations with bike names', (WidgetTester tester) async {
      final bike = Bike(id: 'bike1', name: 'Mountain Bike', person: 'Me');
      
      await tester.runAsync(() async {
        await appRepository.addBikes([bike]);
        // Wait for repository cache to pick up the change from the stream
        // to avoid DropdownButton assertion errors
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
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
        await appRepository.addBikes([Bike(id: 'bike1', name: 'Bike 1', person: 'Me')]);
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
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
        await appRepository.addBikes([bike]);
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
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
        await appRepository.addBikes([
          Bike(id: 'bike1', name: 'Bike 1', person: 'Me'),
          Bike(id: 'bike2', name: 'Bike 2', person: 'Me'),
        ]);
        int attempts = 0;
        while (appRepository.bikes.length < 2 && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
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

    testWidgets('validation: highlights the date fields of duplicate "From beginning" entries', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([
          Bike(id: 'bike1', name: 'Bike 1', person: 'Me'),
          Bike(id: 'bike2', name: 'Bike 2', person: 'Me'),
        ]);
        int attempts = 0;
        while (appRepository.bikes.length < 2 && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: [
          Installation.sinceBeginning(parent: 'bike1'),
          Installation.sinceBeginning(parent: 'bike2'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(invalidBorderCount(tester, dateFields: true), 0);

      tester.state<FormFieldState<List<Installation>>>(find.byType(FormField<List<Installation>>)).validate();
      await tester.pumpAndSettle();

      expect(invalidBorderCount(tester, dateFields: true), 2);
      expect(invalidBorderCount(tester, dateFields: false), 0);

      final errorColor = materialAppTheme.colorScheme.error;
      for (final label in tester.widgetList<Text>(find.text('From beginning'))) {
        expect(label.style?.color, errorColor);
      }
    });

    testWidgets('validation: highlights the bike fields of consecutive installations on the same bike', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([Bike(id: 'bike1', name: 'Bike A', person: 'Me')]);
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          attempts++;
        }
      });

      final now = DateTime.now();
      await tester.pumpWidget(createWidgetUnderTest(
        initialInstallations: [
          Installation(parent: 'bike1', dateTimeUTC: now.subtract(const Duration(hours: 1)), dateTimeLocal: now.subtract(const Duration(hours: 1))),
          Installation(parent: 'bike1', dateTimeUTC: now, dateTimeLocal: now),
        ],
      ));
      await tester.pumpAndSettle();

      tester.state<FormFieldState<List<Installation>>>(find.byType(FormField<List<Installation>>)).validate();
      await tester.pumpAndSettle();

      expect(invalidBorderCount(tester, dateFields: false), 2);
      expect(invalidBorderCount(tester, dateFields: true), 0);

      final errorColor = materialAppTheme.colorScheme.error;
      final closedFieldLabels = tester.widgetList<Text>(find.text('Bike A'));
      expect(closedFieldLabels, hasLength(2));
      for (final label in closedFieldLabels) {
        expect(label.style?.color, errorColor);
      }

      // The menu offers the fix, so its entries keep their normal color.
      await tester.tap(find.byType(DropdownButtonFormField<Installation>).first);
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<Text>(find.text('Bike A')).where((t) => t.style?.color == null),
        isNotEmpty,
      );
    });

    group('component parents', () {
      Component component(
        String id,
        String name,
        List<Installation> installations, {
        ComponentType type = ComponentType.wheelFront,
      }) =>
          Component(
            id: id,
            name: name,
            componentType: type,
            installations: installations,
            adjustments: [],
          );

      Future<void> seed(WidgetTester tester, List<Component> components) async {
        await tester.runAsync(() async {
          await appRepository.addBikes([Bike(id: 'bike1', name: 'Bike 1', person: 'Me')]);
          await appRepository.addComponents(components);
          int attempts = 0;
          while (appRepository.components.length < components.length && attempts < 100) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            attempts++;
          }
        });
      }

      /// Opens the first row's parent dropdown (flag off) or picker sheet (flag on);
      /// the date field's arrow comes first.
      Future<void> openParentMenu(WidgetTester tester) async {
        await tester.tap(find.byIcon(Icons.arrow_drop_down).at(1));
        await tester.pumpAndSettle();
      }

      final now = DateTime.now();
      final nestedComponents = [
        component('wheel', 'Front Wheel', [Installation.sinceBeginning(parent: 'bike1')]),
        component('tire', 'Nested Tire', [
          ComponentInstallation(parentComponentId: 'wheel', dateTimeUTC: now.toUtc(), dateTimeLocal: now),
        ]),
        component('old', 'Archived Wheel', [
          Installation.sinceBeginning(parent: 'bike1'),
          Archival(dateTimeUTC: now.toUtc(), dateTimeLocal: now),
        ]),
      ];

      testWidgets('offers only top-level, non-archived components other than itself', (WidgetTester tester) async {
        await seed(tester, [...nestedComponents, component('self', 'Self Wheel', [Installation.sinceBeginning(parent: 'bike1')])]);
        appSettings.enableInstallOnComponent = true;

        await tester.pumpWidget(createWidgetUnderTest(
          componentId: 'self',
          initialInstallations: [Installation.sinceBeginning(parent: 'bike1')],
        ));
        await tester.pumpAndSettle();
        await openParentMenu(tester);

        expect(find.text('Front Wheel'), findsOneWidget);
        expect(find.text('Nested Tire'), findsNothing);
        expect(find.text('Archived Wheel'), findsNothing);
        expect(find.text('Self Wheel'), findsNothing);
      });

      testWidgets('offers no components when the feature is off', (WidgetTester tester) async {
        await seed(tester, nestedComponents);

        await tester.pumpWidget(createWidgetUnderTest(
          initialInstallations: [Installation.sinceBeginning(parent: 'bike1')],
        ));
        await tester.pumpAndSettle();
        await openParentMenu(tester);

        expect(find.text('Front Wheel'), findsNothing);
      });

      testWidgets('offers no components to a component that carries children', (WidgetTester tester) async {
        await seed(tester, [...nestedComponents, component('rim', 'Rim', [Installation.sinceBeginning(parent: 'bike1')])]);
        appSettings.enableInstallOnComponent = true;

        await tester.pumpWidget(createWidgetUnderTest(
          componentId: 'wheel',
          initialInstallations: [Installation.sinceBeginning(parent: 'bike1')],
        ));
        await tester.pumpAndSettle();
        await openParentMenu(tester);

        expect(find.text('Rim'), findsNothing);
      });

      testWidgets('shows every initial parent state, including non-candidate and missing parents', (WidgetTester tester) async {
        await seed(tester, nestedComponents);
        appSettings.enableInstallOnComponent = true;

        DateTime at(int day) => DateTime(2024, 1, day);
        await tester.pumpWidget(createWidgetUnderTest(
          componentId: 'valve',
          initialInstallations: [
            Installation.componentSinceBeginning(parentComponentId: 'tire'),
            BikeInstallation(bikeId: 'gone', dateTimeUTC: at(2).toUtc(), dateTimeLocal: at(2)),
            ComponentInstallation(parentComponentId: 'missing', dateTimeUTC: at(3).toUtc(), dateTimeLocal: at(3)),
            ComponentInstallation(parentComponentId: 'old', dateTimeUTC: at(4).toUtc(), dateTimeLocal: at(4)),
            Uninstallation(dateTimeUTC: at(5).toUtc(), dateTimeLocal: at(5)),
            Archival(dateTimeUTC: at(6).toUtc(), dateTimeLocal: at(6)),
          ],
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Nested Tire'), findsOneWidget);
        expect(find.text('BIKE NOT FOUND'), findsOneWidget);
        expect(find.text('COMPONENT NOT FOUND'), findsOneWidget);
        expect(find.text('Archived Wheel'), findsOneWidget);
        expect(find.text('UNINSTALLED'), findsOneWidget);
        expect(find.text('ARCHIVED'), findsOneWidget);
      });

      testWidgets('"From beginning" keeps the component parent and entry id', (WidgetTester tester) async {
        await seed(tester, nestedComponents);
        appSettings.enableInstallOnComponent = true;

        List<Installation>? changed;
        final entry = ComponentInstallation(
          id: 'entry',
          parentComponentId: 'tire',
          dateTimeUTC: now.toUtc(),
          dateTimeLocal: now,
        );
        await tester.pumpWidget(createWidgetUnderTest(
          componentId: 'valve',
          initialInstallations: [entry],
          onChanged: (value) => changed = value,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.bySubtype<PopupMenuButton<dynamic>>().first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('From beginning').last);
        await tester.pumpAndSettle();

        final updated = changed!.single;
        expect(updated, isA<ComponentInstallation>());
        expect(updated.parent, 'tire');
        expect(updated.id, 'entry');
        expect(updated.isFromBeginning, isTrue);
        expect(find.text('Nested Tire'), findsOneWidget);
        expect(find.text('BIKE NOT FOUND'), findsNothing);
      });

      testWidgets('closed field shows the component name over its bike', (WidgetTester tester) async {
        await seed(tester, nestedComponents);
        appSettings.enableInstallOnComponent = true;

        await tester.pumpWidget(createWidgetUnderTest(
          componentId: 'tire',
          initialInstallations: [Installation.componentSinceBeginning(parentComponentId: 'wheel')],
        ));
        await tester.pumpAndSettle();

        expect(find.text('Front Wheel'), findsOneWidget);
        expect(find.text('Bike 1'), findsOneWidget);

        final decorators = find.byType(InputDecorator);
        final dateField = decorators.evaluate().firstWhere((e) => (e.widget as InputDecorator).decoration.isDense ?? false);
        final parentField = decorators.evaluate().firstWhere((e) => !((e.widget as InputDecorator).decoration.isDense ?? false));
        expect(parentField.size!.height, dateField.size!.height);
      });

      for (final (themeName, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
        testWidgets('a very long parent name does not overflow at 320 px ($themeName)', (WidgetTester tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final longName = 'Maxxis Assegai 29x2.5 WT EXO+ MaxxGrip TR ' * 3;
          await seed(tester, [component('long', longName, [Installation.sinceBeginning(parent: 'bike1')])]);
          appSettings.enableInstallOnComponent = true;

          await tester.pumpWidget(createWidgetUnderTest(
            componentId: 'tire',
            theme: theme,
            initialInstallations: [Installation.componentSinceBeginning(parentComponentId: 'long')],
          ));
          await tester.pumpAndSettle();

          expect(longName.length, greaterThanOrEqualTo(120));
          expect(tester.takeException(), isNull);
          expect(find.text(longName), findsOneWidget);
        });
      }

      testWidgets('closed field shows the selected parent name in bold', (WidgetTester tester) async {
        await seed(tester, nestedComponents);
        appSettings.enableInstallOnComponent = true;

        await tester.pumpWidget(createWidgetUnderTest(
          componentId: 'tire',
          initialInstallations: [Installation.componentSinceBeginning(parentComponentId: 'wheel')],
        ));
        await tester.pumpAndSettle();

        expect(tester.widget<Text>(find.text('Front Wheel')).style?.fontWeight, FontWeight.w600);
        expect(tester.widget<Text>(find.text('Bike 1')).style?.fontWeight, isNot(FontWeight.w600));
      });

      group('type-aware suggestions', () {
        final typedComponents = [
          component('wheel', 'Front Wheel', [Installation.sinceBeginning(parent: 'bike1')]),
          component('pad', 'Brake Pad', [Installation.sinceBeginning(parent: 'bike1')], type: ComponentType.brakePad),
        ];

        Future<void> pumpTimeline(
          WidgetTester tester, {
          ComponentType? type,
          List<Installation>? installations,
          List<Installation>? original,
          void Function(List<Installation>)? onChanged,
        }) async {
          await tester.pumpWidget(createWidgetUnderTest(
            componentId: 'new',
            componentType: type,
            initialInstallations: installations ?? [Installation.sinceBeginning(parent: 'bike1')],
            originalInstallations: original,
            onChanged: onChanged,
          ));
          await tester.pumpAndSettle();
        }

        testWidgets('a tire hides the brake pad behind "Show all"', (WidgetTester tester) async {
          await seed(tester, typedComponents);
          appSettings.enableInstallOnComponent = true;
          List<Installation>? changed;

          await pumpTimeline(tester, type: ComponentType.tire, onChanged: (value) => changed = value);
          await openParentMenu(tester);

          expect(find.text('Front Wheel'), findsOneWidget);
          expect(find.text('Brake Pad'), findsNothing);
          expect(find.text('1 more hidden · Show all'), findsOneWidget);
          expect(find.text("Type doesn't fit a Tire"), findsOneWidget);

          await tester.tap(find.text('1 more hidden · Show all'));
          await tester.pumpAndSettle();

          expect(find.text('1 more hidden · Show all'), findsNothing);
          expect(find.text('Other components on Bike 1'), findsOneWidget);

          await tester.tap(find.text('Brake Pad'));
          await tester.pump(const Duration(milliseconds: 250));
          await tester.pumpAndSettle();

          expect(changed!.single, isA<ComponentInstallation>());
          expect(changed!.single.parent, 'pad');
          expect(find.text('Brake Pad'), findsOneWidget);
        });

        testWidgets('search finds hidden options without "Show all"', (WidgetTester tester) async {
          await seed(tester, [
            ...typedComponents,
            for (var i = 0; i < 6; i++) component('w$i', 'Spare Wheel $i', [Installation.sinceBeginning(parent: 'bike1')]),
          ]);
          appSettings.enableInstallOnComponent = true;

          await pumpTimeline(tester, type: ComponentType.tire);
          await openParentMenu(tester);
          await tester.enterText(find.byType(TextField), 'pad');
          await tester.pumpAndSettle();

          expect(find.text('Brake Pad'), findsOneWidget);
          expect(find.text('Other components on Bike 1'), findsOneWidget);
          expect(find.textContaining('more hidden'), findsNothing);
        });

        testWidgets('a saved unusual parent stays in its normal section', (WidgetTester tester) async {
          await seed(tester, typedComponents);
          appSettings.enableInstallOnComponent = true;
          final saved = [Installation.componentSinceBeginning(parentComponentId: 'pad')];

          await pumpTimeline(tester, type: ComponentType.tire, installations: saved, original: saved);
          await openParentMenu(tester);

          expect(find.text('Components on Bike 1'), findsOneWidget);
          expect(find.text('Other components on Bike 1'), findsNothing);
          expect(find.textContaining('more hidden'), findsNothing);
        });

        for (final type in [null, ComponentType.other]) {
          testWidgets('type $type hides nothing', (WidgetTester tester) async {
            await seed(tester, typedComponents);
            appSettings.enableInstallOnComponent = true;

            await pumpTimeline(tester, type: type);
            await openParentMenu(tester);

            expect(find.text('Front Wheel'), findsOneWidget);
            expect(find.text('Brake Pad'), findsOneWidget);
            expect(find.textContaining('more hidden'), findsNothing);
          });
        }

        testWidgets('changing the type keeps a picked parent without a form error', (WidgetTester tester) async {
          await seed(tester, typedComponents);
          appSettings.enableInstallOnComponent = true;
          final installations = [Installation.componentSinceBeginning(parentComponentId: 'wheel')];

          await pumpTimeline(tester, type: ComponentType.tire, installations: installations);
          await pumpTimeline(tester, type: ComponentType.brakeDisc, installations: installations);
          await pumpTimeline(tester, type: ComponentType.saddle, installations: installations);

          final formField = tester.state<FormFieldState<List<Installation>>>(find.byType(FormField<List<Installation>>));
          expect(formField.validate(), isTrue);
          expect(find.text('Front Wheel'), findsOneWidget);

          await openParentMenu(tester);
          expect(find.text('Front Wheel'), findsNWidgets(2));
          expect(find.text('Brake Pad'), findsNothing);
        });
      });
    });

    group('select date & time', () {
      Future<void> openPicker(WidgetTester tester, Installation installation) async {
        await tester.runAsync(() async {
          await appRepository.addBikes([Bike(id: 'bike1', name: 'Bike 1', person: 'Me')]);
          int attempts = 0;
          while (appRepository.bikes.isEmpty && attempts < 100) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            attempts++;
          }
        });
        await tester.pumpWidget(createWidgetUnderTest(initialInstallations: [installation]));
        await tester.pumpAndSettle();

        await tester.tap(find.bySubtype<PopupMenuButton<dynamic>>().first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Select date & time...'));
        await tester.pumpAndSettle();
      }

      testWidgets('opens for a "From beginning" entry whose local time is not epoch 0', (WidgetTester tester) async {
        // As loaded in a non-UTC zone: UTC is epoch 0, but the floating local value is not.
        await openPicker(tester, BikeInstallation(
          bikeId: 'bike1',
          dateTimeUTC: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          dateTimeLocal: DateTime(1970, 1, 1, 12),
        ));

        expect(tester.takeException(), isNull);
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets('opens for an entry dated before the picker range', (WidgetTester tester) async {
        final date = DateTime(1995, 6, 1);
        await openPicker(tester, BikeInstallation(bikeId: 'bike1', dateTimeUTC: date.toUtc(), dateTimeLocal: date));

        expect(tester.takeException(), isNull);
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });
    });

    testWidgets('popup menu disables "From beginning" if another entry has it', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await appRepository.addBikes([Bike(id: 'bike1', name: 'Bike 1', person: 'Me')]);
        int attempts = 0;
        while (appRepository.bikes.isEmpty && attempts < 100) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
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
