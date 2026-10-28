import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/utils/setup_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/sheets/compare_setups_harness.dart';

/// Swaps the harness fork for a new one at the same position whose rebound
/// accepts 0..[max].
Future<void> replaceFork(WidgetTester tester, CompareSetupsHarness harness, {int max = 100}) async {
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
            max: max,
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
}

void main() {
  // Built in setUp, never in a test body: a database created in the widget-test
  // zone deadlocks on its first transaction.
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late CompareSetupsHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
    harness = await CompareSetupsHarness.create();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    await harness.dispose();
  });

  testWidgets('duplicateSetup returns null when the duplicate form is cancelled', (tester) async {
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
    final old = harness.setup(
      id: 'old',
      name: 'Old',
      local: DateTime(2026, 8, 1, 10),
      values: const {CompareSetupsHarness.changedAdjustmentId: StepValue(8)},
    );
    await harness.addSetups(tester, [old]);
    await replaceFork(tester, harness);
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

  testWidgets('duplicateSetup keeps the values of a replaced fork when the rider does not apply them', (tester) async {
    final old = harness.setup(
      id: 'old',
      name: 'Old',
      local: DateTime(2026, 8, 1, 10),
      values: const {CompareSetupsHarness.changedAdjustmentId: StepValue(8)},
    );
    await harness.addSetups(tester, [old]);
    await replaceFork(tester, harness);
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
    await tester.tap(find.text("Don't apply"));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);

    expect(result, isNotNull);
    expect(result!.bikeAdjustmentValues[CompareSetupsHarness.changedAdjustmentId], const StepValue(8));
    expect(result!.bikeAdjustmentValues.containsKey('new-rebound'), isFalse);
  });

  testWidgets('duplicateSetup keeps the values of a replaced fork whose successor does not accept them', (tester) async {
    final old = harness.setup(
      id: 'old',
      name: 'Old',
      local: DateTime(2026, 8, 1, 10),
      values: const {CompareSetupsHarness.changedAdjustmentId: StepValue(8)},
    );
    await harness.addSetups(tester, [old]);
    await replaceFork(tester, harness, max: 5);
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
    await tester.tap(find.text('Continue'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);

    expect(result, isNotNull);
    expect(result!.bikeAdjustmentValues[CompareSetupsHarness.changedAdjustmentId], const StepValue(8));
  });
}
