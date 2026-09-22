import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_group.dart';
import 'package:bike_setup_tracker/widgets/items/garage_component_icon_card.dart';
import 'package:bike_setup_tracker/widgets/items/garage_uninstalled_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Component _component(String id, List<Installation> installations, {int orderIndex = 0}) => Component(
  id: id,
  name: id,
  componentType: ComponentType.other,
  installations: installations,
  orderIndex: orderIndex,
);

Installation _uninstalled(String componentId) => Uninstallation(
  componentId: componentId,
  dateTimeUTC: DateTime.utc(2026, 1, 2),
  dateTimeLocal: DateTime(2026, 1, 2),
);

Installation _archived(String componentId) => Archival(
  componentId: componentId,
  dateTimeUTC: DateTime.utc(2026, 1, 2),
  dateTimeLocal: DateTime(2026, 1, 2),
);

Installation _onBike(String componentId, String bikeId) => BikeInstallation(
  componentId: componentId,
  bikeId: bikeId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Installation _onComponent(String componentId, String parentId) => ComponentInstallation(
  componentId: componentId,
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Future<void> _pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
  });

  tearDown(() async {
    settings.dispose();
    await repository.disposeAndAwaitCancellation();
    await database.close();
  });

  Future<void> seed(List<Component> components) async {
    await _pumpEventQueue();
    await repository.addBikes([Bike(id: 'bike', name: 'Bike', person: null)]);
    if (components.isNotEmpty) await repository.addComponents(components);
    await _pumpEventQueue();
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    ValueNotifier<Component?>? draggedComponentNotifier,
  }) async {
    final notifier = draggedComponentNotifier ?? ValueNotifier<Component?>(null);
    if (draggedComponentNotifier == null) addTearDown(notifier.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: settings),
          ChangeNotifierProvider<AppRepository>.value(value: repository),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: GarageUninstalledCard(
                componentToShowDetails: null,
                onPressedComponent: (_) {},
                onAcceptWithDetails: ({required String? newBike}) {},
                onArchiveAccept: () {},
                setDraggedComponent: (_) {},
                draggedComponentNotifier: notifier,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder cellFor(String id) => find.byWidgetPredicate(
    (widget) => widget is GarageComponentIconCard && widget.component.id == id,
  );

  Finder groupHeadedBy(String id) => find.byWidgetPredicate(
    (widget) => widget is GarageComponentGroup && widget.group.parent.id == id,
  );

  testWidgets('keeps components with a broken placement and badges them', (tester) async {
    await tester.runAsync(
      () => seed([
        _component('parked', [_uninstalled('parked')]),
        _component('orphan', [_onBike('orphan', 'gone')]),
        _component('detached', [_onComponent('detached', 'gone')]),
      ]),
    );
    await pumpCard(tester);

    expect(cellFor('parked'), findsOneWidget);
    expect(cellFor('orphan'), findsOneWidget);
    expect(cellFor('detached'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups a parked wheel with the component mounted on it', (tester) async {
    await tester.runAsync(
      () => seed([
        _component('wheel', [_uninstalled('wheel')], orderIndex: 0),
        _component('tire', [_onComponent('tire', 'wheel')], orderIndex: 1),
        _component('pedal', [_uninstalled('pedal')], orderIndex: 2),
      ]),
    );
    await pumpCard(tester);

    expect(find.byType(GarageComponentGroup), findsOneWidget);
    final group = tester.widget<GarageComponentGroup>(groupHeadedBy('wheel'));
    expect(group.group.children.map((component) => component.id), ['tire']);

    for (final id in ['wheel', 'tire', 'pedal']) {
      expect(cellFor(id), findsOneWidget, reason: '$id must render exactly once');
    }
    final groupRect = tester.getRect(groupHeadedBy('wheel'));
    expect(groupRect.contains(tester.getCenter(cellFor('tire'))), isTrue);
    expect(groupRect.contains(tester.getCenter(cellFor('pedal'))), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups an archived parent with its children', (tester) async {
    await tester.runAsync(
      () => seed([
        _component('shelf-wheel', [_archived('shelf-wheel')], orderIndex: 0),
        _component('shelf-tire', [_onComponent('shelf-tire', 'shelf-wheel')], orderIndex: 1),
      ]),
    );
    await pumpCard(tester);

    // The child is effectively archived through its parent, so both sit in the
    // archive section and must render as a single group.
    expect(find.text('Archive'), findsOneWidget);
    expect(find.byType(GarageComponentGroup), findsOneWidget);
    final group = tester.widget<GarageComponentGroup>(groupHeadedBy('shelf-wheel'));
    expect(group.group.children.map((component) => component.id), ['shelf-tire']);
    expect(cellFor('shelf-tire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a badged broken root still groups its descendants', (tester) async {
    await tester.runAsync(
      () => seed([
        _component('detached', [_onComponent('detached', 'gone')], orderIndex: 0),
        _component('child', [_onComponent('child', 'detached')], orderIndex: 1),
      ]),
    );
    await pumpCard(tester);

    final group = tester.widget<GarageComponentGroup>(groupHeadedBy('detached'));
    expect(group.group.children.map((component) => component.id), ['child']);
    expect(tester.widget<GarageComponentIconCard>(cellFor('detached')).issue, isNotNull);
    expect(tester.widget<GarageComponentIconCard>(cellFor('child')).issue, isNull);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the empty-state placeholders when nothing is parked', (tester) async {
    await tester.runAsync(() => seed([]));
    await pumpCard(tester);

    expect(find.text('Drag components here to uninstall from bike'), findsOneWidget);
    expect(find.byType(GarageComponentGroup), findsNothing);
    // The archive section only appears once something is archived or dragged.
    expect(find.text('Archive'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the drop-zone overlay covers a wrap containing a group', (tester) async {
    await tester.runAsync(
      () => seed([
        _component('wheel', [_uninstalled('wheel')], orderIndex: 0),
        _component('tire', [_onComponent('tire', 'wheel')], orderIndex: 1),
        _component('mounted', [_onBike('mounted', 'bike')], orderIndex: 2),
      ]),
    );
    final draggedComponentNotifier = ValueNotifier<Component?>(null);
    addTearDown(draggedComponentNotifier.dispose);
    await pumpCard(tester, draggedComponentNotifier: draggedComponentNotifier);

    final groupRect = tester.getRect(groupHeadedBy('wheel'));

    draggedComponentNotifier.value = repository.components['mounted'];
    await tester.pump();

    final hint = find.text('Drag here to uninstall');
    expect(hint, findsOneWidget);
    final overlayRect = tester.getRect(
      find.ancestor(of: hint, matching: find.byType(Stack)).first,
    );
    expect(overlayRect.contains(groupRect.topLeft), isTrue);
    expect(overlayRect.contains(groupRect.bottomRight - const Offset(1, 1)), isTrue);
    expect(tester.takeException(), isNull);
  });
}
