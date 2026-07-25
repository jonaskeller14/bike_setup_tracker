import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_set_list.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_categorical.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required Future<void> Function(String) onAddOption,
    Set<String> options = const {},
    bool multiSelect = true,
  }) async {
    final adjustment = CategoricalAdjustment(
      name: 'Tyre',
      notes: null,
      unit: null,
      options: options,
      multiSelect: multiSelect,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSetCategoricalSheet(
                  context: context,
                  adjustment: adjustment,
                  selected: const [],
                  onChanged: (_) {},
                  onAddOption: onAddOption,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  // Expand the plus into the field, type [value], submit via the in-field check
  // icon (not the keyboard action), and let the async add resolve.
  Future<void> addViaCheckIcon(WidgetTester tester, String value) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), value);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(); // spinner frame
    await tester.pump(const Duration(milliseconds: 40)); // resolve async add
    await tester.pumpAndSettle();
  }

  testWidgets('check-icon submit adds the option, closes the field, shows the plus again',
      (tester) async {
    final added = <String>[];
    await openSheet(
      tester,
      options: const {'Front', 'Rear'},
      onAddOption: (o) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        added.add(o);
      },
    );

    await addViaCheckIcon(tester, 'Slick');

    expect(added, ['Slick']);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Already exists'), findsNothing);
  });

  testWidgets('adding two options in a row collapses back to the plus each time',
      (tester) async {
    final added = <String>[];
    await openSheet(
      tester,
      onAddOption: (o) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        added.add(o);
      },
    );

    await addViaCheckIcon(tester, 'Slick');
    expect(find.byType(TextField), findsNothing, reason: 'field should close after first add');

    await addViaCheckIcon(tester, 'Knobby');

    expect(added, ['Slick', 'Knobby']);
    expect(find.byType(TextField), findsNothing, reason: 'field should close after second add');
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Already exists'), findsNothing);
  });

  // Regression: persisting an added option rebuilds the host list with an updated
  // adjustment. The list must key its rows by identity, not content — otherwise the
  // row (and the FormField the open sheet's onChanged writes to) is torn down, the
  // second onChanged throws on the defunct state, and the field is left open with
  // the second option still inside instead of collapsing back to the plus.
  testWidgets('two adds survive the host rebuild when the persisted adjustment changes',
      (tester) async {
    CategoricalAdjustment adj = CategoricalAdjustment(
      id: 'a1',
      name: 'Tyre',
      notes: null,
      unit: null,
      options: const {},
      multiSelect: true,
      counted: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AdjustmentSetList(
              adjustments: [adj],
              initialAdjustmentValues: const {},
              adjustmentValues: const {},
              onAdjustmentValueChanged: ({required adjustment, required newValue}) {},
              removeFromAdjustmentValues: ({required adjustment}) {},
              onAddCategoricalOption: ({required adjustment, required option}) async {
                await Future<void>.delayed(const Duration(milliseconds: 20));
                // Mimic repository persist + notify: a new adjustment object with
                // the option added flows back into the list.
                setState(() => adj = adj.copyWith(options: {...adj.options, option}));
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    Future<void> add(String value) async {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), value);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpAndSettle();
    }

    await add('Slick');
    expect(find.byType(TextField), findsNothing, reason: 'field should close after first add');

    await add('Knobby');
    expect(find.byType(TextField), findsNothing, reason: 'field should close after second add');
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Slick'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Knobby'), findsOneWidget);
  });
}
