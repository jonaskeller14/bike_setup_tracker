import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/widgets/component_ancestors_column.dart';
import 'package:bike_setup_tracker/widgets/sheets/picker_tile.dart';
import 'package:bike_setup_tracker/widgets/sheets/task_association_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../../goldens/support/localized_test_app.dart';

class _MockAppRepository extends Mock implements AppRepository {}

const _bikeId = 'bike';

Component _part(String id, Installation installation, {required int order}) => Component(
      id: id,
      name: id,
      componentType: ComponentType.other,
      installations: [installation],
      adjustments: const [],
      orderIndex: order,
    );

Installation _onBike() => Installation.sinceBeginning(parent: _bikeId);
Installation _onShelf() => Installation.sinceBeginning(parent: null);
Installation _on(String id) => Installation.componentSinceBeginning(parentComponentId: id);

void main() {
  Future<void> openSheet(WidgetTester tester, List<Component> parts) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 3000);
    addTearDown(tester.view.reset);

    final components = {for (final part in parts) part.id: part};
    final repository = _MockAppRepository();
    when(() => repository.bikes).thenReturn({_bikeId: Bike(id: _bikeId, name: _bikeId, person: 'p')});
    when(() => repository.components).thenReturn(components);
    when(() => repository.componentHierarchy).thenReturn(ComponentHierarchyResolver(components));

    await tester.pumpWidget(
      ChangeNotifierProvider<AppRepository>.value(
        value: repository,
        child: localizedTestApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTaskAssociationSheet(context: context, selected: const GeneralTaskAssociation()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  List<(String, int, bool)> rows(WidgetTester tester) => tester
      .widgetList<PickerTile>(find.byType(PickerTile))
      .where((tile) => tile.label != 'General Task')
      .map((tile) => (tile.label, tile.depth, tile.showArrow))
      .toList();

  testWidgets('sub-components sit right below their parent, one level deeper', (tester) async {
    await openSheet(tester, [
      _part('insert', _on('tire'), order: 0),
      _part('tire', _on('wheel'), order: 1),
      _part('shock', _onBike(), order: 2),
      _part('wheel', _onBike(), order: 3),
      _part('fork', _onBike(), order: 4),
    ]);

    expect(rows(tester), [
      (_bikeId, 0, false),
      ('shock', 1, false),
      ('wheel', 1, false),
      ('tire', 2, true),
      ('insert', 3, true),
      ('fork', 1, false),
    ]);
  });

  testWidgets('every component shows its hierarchy, bucketed ones are nested too', (tester) async {
    await openSheet(tester, [
      _part('fork', _onBike(), order: 0),
      _part('wheel', _onShelf(), order: 1),
      _part('tire', _on('wheel'), order: 2),
    ]);

    expect(rows(tester), [
      (_bikeId, 0, false),
      ('fork', 1, false),
      ('Not installed', 0, false),
      ('wheel', 1, false),
      ('tire', 2, true),
    ]);
    expect(find.byType(ComponentAncestorsColumn), findsNWidgets(3));
  });

  testWidgets('the Not installed row cannot be selected', (tester) async {
    await openSheet(tester, [_part('wheel', _onShelf(), order: 0)]);

    final header = tester.widget<PickerTile>(find.widgetWithText(PickerTile, 'Not installed'));
    expect(header.enabled, isFalse);
    expect(header.onTap, isNull);
  });

  testWidgets('a component with a missing bike or parent counts as not installed', (tester) async {
    await openSheet(tester, [
      _part('fork', _onBike(), order: 0),
      _part('lost-on-bike', Installation.sinceBeginning(parent: 'deleted-bike'), order: 1),
      _part('lost-on-part', _on('deleted-part'), order: 2),
    ]);

    expect(rows(tester), [
      (_bikeId, 0, false),
      ('fork', 1, false),
      ('Not installed', 0, false),
      ('lost-on-bike', 1, false),
      ('lost-on-part', 1, false),
    ]);
  });

  testWidgets('a parent hidden by the search takes no level', (tester) async {
    await openSheet(tester, [
      _part('wheel', _onBike(), order: 0),
      _part('tire', _on('wheel'), order: 1),
      _part('insert', _on('tire'), order: 2),
    ]);

    await tester.enterText(find.byType(TextField), 'tire');
    await tester.pumpAndSettle();

    expect(rows(tester), [(_bikeId, 0, false), ('tire', 1, false)]);
    expect(find.descendant(of: find.byType(ComponentAncestorsColumn), matching: find.text('wheel')), findsOneWidget);
  });

  testWidgets('components in a cycle stay reachable', (tester) async {
    await openSheet(tester, [
      _part('loop-1', _on('loop-2'), order: 0),
      _part('loop-2', _on('loop-1'), order: 1),
    ]);

    expect(rows(tester), [
      (_bikeId, 0, false),
      ('Not installed', 0, false),
      ('loop-1', 1, false),
      ('loop-2', 2, true),
    ]);
  });
}
