import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/garage_bike_card.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_group.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_icon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bikeId = 'bike';
const _wheelId = 'wheel';
const _tireId = 'tire';
const _tubeId = 'tube';
const _forkId = 'fork';
const _spacing = 8.0;
const _longName =
    'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

/// Records reorder calls instead of writing them, so a test can assert which
/// list the wrap handed to the repository.
class _RecordingRepository extends AppRepository {
  _RecordingRepository(super.database);

  final List<({int oldIndex, int newIndex, List<String> ids})> reorders = [];

  @override
  Future<void> reorderComponent({
    required int oldIndex,
    required int newIndex,
    required List<Component> filteredComponentsList,
  }) async {
    reorders.add((
      oldIndex: oldIndex,
      newIndex: newIndex,
      ids: filteredComponentsList.map((component) => component.id).toList(),
    ));
  }
}

Component _component(String id, String name, List<Installation> installations, {int orderIndex = 0}) => Component(
  id: id,
  name: name,
  installations: installations,
  componentType: ComponentType.other,
  orderIndex: orderIndex,
);

Installation _onBike(String componentId) => BikeInstallation(
  componentId: componentId,
  bikeId: _bikeId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Installation _onComponent(String componentId, String parentId) => ComponentInstallation(
  componentId: componentId,
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

void main() {
  late AppDatabase database;
  late _RecordingRepository repository;
  late AppSettings settings;
  late SubscriptionService subscriptionService;

  Future<void> seed(List<Component> components) async {
    final seedRepository = AppRepository(database);
    await seedRepository.initialDataLoaded;
    await seedRepository.addBikes([Bike(id: _bikeId, name: 'Bike', person: null)]);
    await seedRepository.addComponents(components);
    seedRepository.dispose();

    repository = _RecordingRepository(database);
    await repository.initialDataLoaded;
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );

    database = AppDatabase.memory();
    settings = AppSettings()
      ..showOnboarding = false
      ..enablePerson = false;
    subscriptionService = _MockSubscriptionService();
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(false);
  });

  tearDown(() async {
    await repository.disposeAndAwaitCancellation();
    settings.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  Future<void> pumpBikeCard(
    WidgetTester tester, {
    double width = 390,
    Brightness brightness = Brightness.light,
    String? componentToShowDetails,
  }) async {
    final draggedComponentNotifier = ValueNotifier<Component?>(null);
    addTearDown(draggedComponentNotifier.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<AppRepository>.value(value: repository),
          ChangeNotifierProvider<SubscriptionService>.value(value: subscriptionService),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.light ? materialAppTheme : materialAppDarkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: width,
                child: GarageBikeCard(
                  bike: repository.bikes[_bikeId]!,
                  index: 0,
                  componentToShowDetails: componentToShowDetails,
                  onPressedComponent: (_) {},
                  onAcceptWithDetails: ({required String? newBike}) {},
                  setDraggedComponent: (_) {},
                  draggedComponentNotifier: draggedComponentNotifier,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder cellFor(String id) => find.byWidgetPredicate(
    (widget) => widget is GarageComponentIconCard && widget.component.id == id,
  );

  group('grouping inside the bike card', () {
    testWidgets('renders one group holding the parent and its children in order, without duplicates', (tester) async {
      await tester.runAsync(
        () => seed([
          _component(_forkId, 'Fork', [_onBike(_forkId)], orderIndex: 0),
          _component(_wheelId, 'Wheel', [_onBike(_wheelId)], orderIndex: 1),
          _component(_tireId, 'Tire', [_onComponent(_tireId, _wheelId)], orderIndex: 2),
          _component(_tubeId, 'Tube', [_onComponent(_tubeId, _tireId)], orderIndex: 3),
        ]),
      );
      await pumpBikeCard(tester);

      expect(find.byType(GarageComponentGroup), findsOneWidget);
      for (final id in [_forkId, _wheelId, _tireId, _tubeId]) {
        expect(cellFor(id), findsOneWidget, reason: '$id must render exactly once');
      }

      final group = tester.widget<GarageComponentGroup>(find.byType(GarageComponentGroup));
      expect(group.group.parent.id, _wheelId);
      expect(group.group.children.map((component) => component.id), [_tireId, _tubeId]);

      // The grandchild is flattened into the group, not nested in a second one.
      final groupRect = tester.getRect(find.byType(GarageComponentGroup));
      for (final id in [_wheelId, _tireId, _tubeId]) {
        expect(groupRect.contains(tester.getCenter(cellFor(id))), isTrue, reason: '$id sits inside the group');
      }
      expect(groupRect.contains(tester.getCenter(cellFor(_forkId))), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the group spans whole cells of the outer grid', (tester) async {
      await tester.runAsync(
        () => seed([
          _component(_wheelId, 'Wheel', [_onBike(_wheelId)], orderIndex: 0),
          _component(_tireId, 'Tire', [_onComponent(_tireId, _wheelId)], orderIndex: 1),
        ]),
      );
      await pumpBikeCard(tester);

      final cellWidth = tester.getSize(cellFor(_wheelId)).width;
      final groupWidth = tester.getSize(find.byType(GarageComponentGroup)).width;

      expect(groupWidth, closeTo(2 * cellWidth + _spacing, 1e-6));
      expect(tester.getTopLeft(cellFor(_tireId)).dy, tester.getTopLeft(cellFor(_wheelId)).dy);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a group wider than one row wraps and stays overflow-safe', (tester) async {
      await tester.runAsync(
        () => seed([
          _component(_wheelId, _longName, [_onBike(_wheelId)], orderIndex: 0),
          for (var index = 0; index < 12; index++)
            _component('child-$index', _longName, [_onComponent('child-$index', _wheelId)], orderIndex: index + 1),
        ]),
      );
      await pumpBikeCard(tester, width: 320);

      final cardWidth = tester.getSize(find.byType(GarageBikeCard)).width;
      final groupRect = tester.getRect(find.byType(GarageComponentGroup));

      expect(groupRect.width, lessThanOrEqualTo(cardWidth));
      expect(groupRect.height, greaterThan(tester.getSize(cellFor(_wheelId)).height));
      expect(tester.getTopLeft(cellFor('child-11')).dy, greaterThan(tester.getTopLeft(cellFor(_wheelId)).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in the dark theme without overflow', (tester) async {
      await tester.runAsync(
        () => seed([
          _component(_wheelId, _longName, [_onBike(_wheelId)], orderIndex: 0),
          _component(_tireId, _longName, [_onComponent(_tireId, _wheelId)], orderIndex: 1),
        ]),
      );
      await pumpBikeCard(tester, brightness: Brightness.dark);

      expect(find.byType(GarageComponentGroup), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('selection', () {
    setUp(() async {
      await seed([
        _component(_wheelId, 'Wheel', [_onBike(_wheelId)], orderIndex: 0),
        _component(_tireId, 'Tire', [_onComponent(_tireId, _wheelId)], orderIndex: 1),
      ]);
    });

    BoxDecoration groupDecoration(WidgetTester tester) => tester
        .widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(GarageComponentGroup),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .decoration as BoxDecoration;

    BoxDecoration cellDecoration(WidgetTester tester, String id) => tester
        .widget<Container>(
          find.descendant(of: cellFor(id), matching: find.byType(Container)).first,
        )
        .decoration as BoxDecoration;

    testWidgets('selecting the parent highlights the whole group instead of the head cell', (tester) async {
      await pumpBikeCard(tester, componentToShowDetails: _wheelId);

      final colorScheme = materialAppTheme.colorScheme;
      expect(groupDecoration(tester).color, colorScheme.tertiaryContainer);
      expect(groupDecoration(tester).border?.top.color, colorScheme.tertiary);
      expect(cellDecoration(tester, _wheelId).color, Colors.transparent);
      expect(cellDecoration(tester, _wheelId).border?.top.color, Colors.transparent);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting a child highlights only that cell', (tester) async {
      await pumpBikeCard(tester, componentToShowDetails: _tireId);

      final colorScheme = materialAppTheme.colorScheme;
      expect(groupDecoration(tester).color, isNot(colorScheme.tertiaryContainer));
      expect(groupDecoration(tester).border?.top.color, colorScheme.outlineVariant);
      expect(cellDecoration(tester, _tireId).color, colorScheme.tertiaryContainer);
      expect(cellDecoration(tester, _tireId).border?.top.color, colorScheme.tertiary);
      expect(tester.takeException(), isNull);
    });
  });

  group('drag and reorder', () {
    setUp(() async {
      await seed([
        _component(_forkId, 'Fork', [_onBike(_forkId)], orderIndex: 0),
        _component(_wheelId, 'Wheel', [_onBike(_wheelId)], orderIndex: 1),
        _component(_tireId, 'Tire', [_onComponent(_tireId, _wheelId)], orderIndex: 2),
        _component(_tubeId, 'Tube', [_onComponent(_tubeId, _wheelId)], orderIndex: 3),
      ]);
    });

    testWidgets('a long press on a child reorders within the group, not the roots', (tester) async {
      await pumpBikeCard(tester);

      final gesture = await tester.startGesture(tester.getCenter(cellFor(_tireId)));
      await tester.pump(const Duration(seconds: 1));
      await gesture.moveTo(tester.getCenter(cellFor(_tubeId)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repository.reorders, hasLength(1));
      expect(repository.reorders.single.ids, [_tireId, _tubeId]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long press on the group head reorders the roots', (tester) async {
      await pumpBikeCard(tester);

      final gesture = await tester.startGesture(tester.getCenter(cellFor(_wheelId)));
      await tester.pump(const Duration(seconds: 1));
      await gesture.moveTo(tester.getCenter(cellFor(_forkId)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repository.reorders, hasLength(1));
      expect(repository.reorders.single.ids, [_forkId, _wheelId]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the group drag feedback is a static snapshot without a live inner wrap', (tester) async {
      await pumpBikeCard(tester);

      final gesture = await tester.startGesture(tester.getCenter(cellFor(_wheelId)));
      await tester.pump(const Duration(seconds: 1));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      final snapshots = tester
          .widgetList<GarageComponentGroup>(find.byType(GarageComponentGroup))
          .where((group) => group.isSnapshot);
      expect(snapshots, hasLength(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
