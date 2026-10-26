import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/utils/setup_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/sheets/compare_setups_harness.dart';

void main() {
  testWidgets('duplicateSetup returns null when the duplicate form is cancelled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final harness = await CompareSetupsHarness.create();
    addTearDown(harness.dispose);
    final setup = harness.setup(id: 'source', name: 'Source', local: DateTime(2026, 8, 1, 10));
    Setup? result;

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => result = await SetupActions.duplicateSetup(context, setup: setup),
            child: const Text('Duplicate'),
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Duplicate'));
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    expect(result, isNull);
  });

  testWidgets('duplicateSetup moves the values of a replaced fork to its successor when asked', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final harness = await CompareSetupsHarness.create();
    addTearDown(harness.dispose);
    final old = harness.setup(
      id: 'old',
      name: 'Old',
      local: DateTime(2026, 8, 1, 10),
      values: const {CompareSetupsHarness.changedAdjustmentId: StepValue(8)},
    );
    await harness.addSetups(tester, [old]);
    final swapped = DateTime(2026, 8, 2);
    await tester.runAsync(() async {
      final fork = harness.repository.components[CompareSetupsHarness.componentId]!;
      await harness.repository.editComponents([
        fork.copyWith(
          installations: [
            ...fork.installations,
            Uninstallation(dateTimeUTC: swapped.toUtc(), dateTimeLocal: swapped),
          ],
        ),
      ]);
      await harness.repository.addComponents([
        Component(
          id: 'new-fork',
          name: 'New fork',
          componentType: ComponentType.fork,
          installations: [
            BikeInstallation(bikeId: CompareSetupsHarness.bikeId, dateTimeUTC: swapped.toUtc(), dateTimeLocal: swapped),
          ],
          adjustments: [
            StepAdjustment(
              id: 'new-rebound',
              name: 'Rebound',
              notes: '',
              unit: AdjustmentUnit.fromLegacy('clicks'),
              min: 0,
              max: 100,
              step: 1,
              visualization: StepAdjustmentVisualization.slider,
            ),
          ],
        ),
      ]);
      for (var attempt = 0; attempt < 50 && harness.repository.components.length < 2; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    Setup? result;

    await tester.pumpWidget(
      harness.wrap(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => result = await SetupActions.duplicateSetup(context, setup: old),
            child: const Text('Duplicate'),
          ),
        ),
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Duplicate'));
    await settle(tester);
    expect(find.text('Apply values to current components?'), findsOneWidget);
    await tester.tap(find.text('Apply 1 value'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);

    expect(result, isNotNull);
    expect(result!.bikeAdjustmentValues['new-rebound'], const StepValue(8));
    expect(result!.bikeAdjustmentValues.containsKey(CompareSetupsHarness.changedAdjustmentId), isFalse);
  });
}
