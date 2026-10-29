import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/setup_carry_over.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/carry_over_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StepAdjustment _rebound(String id) => StepAdjustment(
  id: id,
  name: 'Rebound',
  notes: '',
  unit: null,
  min: 0,
  max: 20,
  step: 1,
  visualization: StepAdjustmentVisualization.slider,
);

Component _fork(String id, String adjustmentId) => Component(
  id: id,
  name: id,
  componentType: ComponentType.fork,
  installations: const [],
  adjustments: [_rebound(adjustmentId)],
);

void main() {
  final oldFork = _fork('Old fork', 'old');
  final newFork = _fork('New fork', 'new');
  final candidate = Setup(
    name: 'Alpine day',
    datetime: DateTime.utc(2026, 1, 2),
    datetimeLocal: DateTime(2026, 1, 2),
    tags: const {},
    bike: 'bike',
    person: null,
    bikeAdjustmentValues: const {'old': StepValue(8)},
    personAdjustmentValues: const {},
  );
  final moved = CarryOverEntry(
    fromComponent: oldFork,
    from: oldFork.adjustments.single,
    value: const StepValue(8),
    toComponent: newFork,
    to: newFork.adjustments.single,
  );
  final blocked = CarryOverEntry(
    fromComponent: oldFork,
    from: oldFork.adjustments.single,
    value: const StepValue(15),
    toComponent: newFork,
    to: newFork.adjustments.single,
    issue: CarryOverIssue.valueNotAllowed,
  );

  /// Opens the sheet; [results] collects what it returns once closed.
  Future<void> open(WidgetTester tester, SetupCarryOver carryOver, List<bool?> results) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showCarryOverSheet(context, setup: candidate, carryOver: carryOver),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists what moves and what stays, and moving returns true', (tester) async {
    final results = <bool?>[];
    await open(tester, SetupCarryOver([moved, blocked]), results);

    expect(find.text('Rebound: 8'), findsOneWidget);
    expect(find.text("From 'Old fork' to 'New fork'"), findsOneWidget);
    expect(find.text('Rebound: 15'), findsOneWidget);
    expect(find.text("Not allowed by 'Rebound' on 'New fork'."), findsOneWidget);

    await tester.tap(find.text('Apply 1 value'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('not applying returns false', (tester) async {
    final results = <bool?>[];
    await open(tester, SetupCarryOver([moved]), results);

    await tester.tap(find.text("Don't apply"));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('only continues when nothing fits', (tester) async {
    final results = <bool?>[];
    await open(tester, SetupCarryOver([blocked]), results);

    expect(find.textContaining('Apply'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });
}
