import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_ancestor.dart';
import 'package:bike_setup_tracker/widgets/sheets/pick_adjustments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/localized_test_app.dart';

Adjustment _adjustment(String id) => BooleanAdjustment(id: id, name: id, notes: null, unit: null);

Component _component(String id) =>
    Component(id: id, name: id, componentType: ComponentType.other, installations: const []);

PickAdjustmentsGroup _group(String id, List<String> adjustments, {List<Component> ancestors = const []}) =>
    PickAdjustmentsGroup(
      id: id,
      title: id,
      icon: Icons.tune,
      ancestors: [for (final ancestor in ancestors) ParentComponentAncestor(ancestor)],
      adjustments: [for (final adjustment in adjustments) _adjustment(adjustment)],
    );

void main() {
  late List<String> picked;

  setUp(() => picked = []);

  Future<void> open(
    WidgetTester tester, {
    required List<PickAdjustmentsGroup> groups,
    List<String> selectedIds = const [],
    VoidCallback? onEmptyAction,
  }) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPickAdjustmentsSheet(
              context,
              title: 'Pick',
              groups: groups,
              selectedIds: selectedIds,
              onChanged: (ids) => picked = ids,
              emptyHint: 'hint',
              emptyActionLabel: 'action',
              onEmptyAction: onEmptyAction,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder arrows() => find.byIcon(Icons.subdirectory_arrow_right);

  double top(WidgetTester tester, String text) => tester.getTopLeft(find.text(text)).dy;

  group('hierarchy', () {
    testWidgets('lists sub-components below their parent, whatever order they came in', (tester) async {
      final wheel = _component('wheel');
      await open(
        tester,
        groups: [
          _group('fork', ['forkA']),
          _group('tire', ['tireA'], ancestors: [wheel]),
          _group('shock', ['shockA']),
          _group('wheel', ['wheelA']),
        ],
      );

      expect(arrows(), findsOneWidget, reason: 'only the sub-component');
      final inOrder = ['fork', 'forkA', 'wheel', 'wheelA', 'tire', 'tireA', 'shock', 'shockA'];
      for (final (index, text) in inOrder.indexed.skip(1)) {
        expect(top(tester, text), greaterThan(top(tester, inOrder[index - 1])), reason: text);
      }
    });

    testWidgets('keeps a parent without adjustments and steps right per level', (tester) async {
      final wheel = _component('wheel');
      final tire = _component('tire');
      await open(
        tester,
        groups: [
          _group('insert', ['insertA'], ancestors: [tire, wheel]),
        ],
      );

      expect(arrows(), findsNWidgets(2));
      final wheelStart = tester.getTopLeft(find.text('wheel')).dx;
      final tireStart = tester.getTopLeft(find.text('tire')).dx;
      final insertStart = tester.getTopLeft(find.text('insert')).dx;
      expect(tireStart, greaterThan(wheelStart));
      expect(insertStart, greaterThan(tireStart));
    });
  });

  group('selection', () {
    testWidgets('numbers the picks in tap order and closes the gap when one is removed', (tester) async {
      await open(
        tester,
        groups: [
          _group('fork', ['a', 'b', 'c']),
        ],
      );

      await tester.tap(find.text('c'));
      await tester.pump();
      await tester.tap(find.text('a'));
      await tester.pump();
      expect(picked, ['c', 'a']);
      expect(find.text('Pick (2)'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('c'));
      await tester.pump();
      expect(picked, ['a']);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('starts from the given selection and its order', (tester) async {
      await open(
        tester,
        groups: [
          _group('fork', ['a', 'b']),
        ],
        selectedIds: const ['b', 'a'],
      );

      final tileOfB = find.ancestor(of: find.text('b'), matching: find.byType(Row)).first;
      expect(find.descendant(of: tileOfB, matching: find.text('1')), findsOneWidget);
    });
  });

  group('empty', () {
    testWidgets('closes the sheet, then runs the action', (tester) async {
      var acted = 0;
      await open(tester, groups: const [], onEmptyAction: () => acted++);
      expect(find.text('hint'), findsOneWidget);

      await tester.tap(find.text('action'));
      await tester.pumpAndSettle();

      expect(acted, 1);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('shows no button without an action', (tester) async {
      await open(tester, groups: const []);

      expect(find.text('hint'), findsOneWidget);
      expect(find.text('action'), findsNothing);
    });
  });
}
