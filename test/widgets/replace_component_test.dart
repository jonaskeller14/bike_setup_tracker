import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/replace_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppRepository extends Mock implements AppRepository {}

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

void main() {
  late MockAppRepository mockRepository;
  late AppSettings appSettings;
  late Component currentComponent;
  late Component spareFork;
  late Component spareChain;
  late Map<String, Component> componentsMap;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepository = MockAppRepository();
    appSettings = AppSettings();

    // Installed on b1 -> bike != null (the component being replaced).
    currentComponent = Component(
      id: 'c1',
      name: 'Current Fork',
      componentType: ComponentType.fork,
      installations: [Installation.sinceBeginning(parent: 'b1')],
      adjustments: [],
    );
    // Never installed -> bike == null (uninstalled), same type as current.
    spareFork = Component(
      id: 'c2',
      name: 'Spare Fork',
      componentType: ComponentType.fork,
      installations: const [],
      adjustments: [],
    );
    // Uninstalled, different type than current.
    spareChain = Component(
      id: 'c3',
      name: 'Spare Chain',
      componentType: ComponentType.chain,
      installations: const [],
      adjustments: [],
    );

    componentsMap = {
      currentComponent.id: currentComponent,
      spareFork.id: spareFork,
      spareChain.id: spareChain,
    };
    // thenAnswer (not thenReturn) so mutating componentsMap is reflected on rebuild.
    when(() => mockRepository.components).thenAnswer((_) => componentsMap);
  });

  Widget harness({required ValueChanged<ReplaceComponentResult?> onResult}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider<AppRepository>.value(value: mockRepository),
        ChangeNotifierProvider<SubscriptionService>.value(value: MockSubscriptionService()),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async =>
                  onResult(await showReplaceComponentSheet(context, component: currentComponent)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('showReplaceComponentSheet', () {
    testWidgets('defaults to "New" and returns a result with no existing component', (tester) async {
      ReplaceComponentResult? result;
      var completed = false;
      await tester.pumpWidget(harness(onResult: (r) {
        result = r;
        completed = true;
      }));
      await openSheet(tester);

      // New is the default mode: the component dropdown is not shown.
      expect(find.text('Replacement Component'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(result, isNotNull);
      expect(result, isA<ReplaceComponentNewResult>());
    });

    testWidgets('"Existing" mode returns the selected uninstalled component', (tester) async {
      ReplaceComponentResult? result;
      await tester.pumpWidget(harness(onResult: (r) => result = r));
      await openSheet(tester);

      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();
      expect(find.text('Replacement Component'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spare Fork').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result, isA<ReplaceComponentExistingResult>());
      expect((result as ReplaceComponentExistingResult).existingComponent.id, 'c2');
    });

    testWidgets('"Existing" mode blocks continue until a component is selected', (tester) async {
      ReplaceComponentResult? result;
      var completed = false;
      await tester.pumpWidget(harness(onResult: (r) {
        result = r;
        completed = true;
      }));
      await openSheet(tester);

      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Validation fails, the sheet stays open and nothing is returned.
      expect(find.text('Please select a component'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(completed, isFalse);
      expect(result, isNull);
    });

    testWidgets('groups uninstalled components into same-type and "Other" sections', (tester) async {
      await tester.pumpWidget(harness(onResult: (_) {}));
      await openSheet(tester);

      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Same-type header is the current component's type label, then an "Other" group.
      expect(find.text(ComponentType.fork.label.toUpperCase()), findsWidgets);
      expect(find.text('Other'.toUpperCase()), findsWidgets);
      expect(find.text('Spare Fork'), findsWidgets);
      expect(find.text('Spare Chain'), findsWidgets);
    });

    testWidgets('omits section headers when only one component type is available', (tester) async {
      // Only fork-type components remain uninstalled -> flat list, no headers.
      componentsMap = {
        currentComponent.id: currentComponent,
        spareFork.id: spareFork,
      };

      await tester.pumpWidget(harness(onResult: (_) {}));
      await openSheet(tester);

      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text(ComponentType.fork.label.toUpperCase()), findsNothing);
      expect(find.text('Other'.toUpperCase()), findsNothing);
      expect(find.text('Spare Fork'), findsWidgets);
    });

    testWidgets('keeps the selected component in the dropdown after it gets installed (no crash)', (tester) async {
      await tester.pumpWidget(harness(onResult: (_) {}));
      await openSheet(tester);

      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spare Fork').last);
      await tester.pumpAndSettle();

      // Mirror the repository state right after the swap installs the chosen
      // component: it is no longer "uninstalled".
      final now = DateTime.now();
      componentsMap = {
        currentComponent.id: currentComponent,
        spareFork.id: spareFork.copyWith(installations: [
          Installation(parent: 'b1', dateTimeUTC: now.toUtc(), dateTimeLocal: now),
        ]),
        spareChain.id: spareChain,
      };

      // Force the sheet to rebuild against the mutated repository state.
      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();

      // Without keeping the selection in the item list, the dropdown asserts
      // "exactly one item with value <id>" and throws here.
      expect(tester.takeException(), isNull);
      expect(find.text('Spare Fork'), findsWidgets);
    });
  });
}
