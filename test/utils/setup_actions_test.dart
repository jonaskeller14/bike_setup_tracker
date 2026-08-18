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
}
