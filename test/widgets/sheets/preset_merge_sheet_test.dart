import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/preset_merge.dart';
import 'package:bike_setup_tracker/widgets/sheets/preset_merge_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');

final _own = [
  NumericalAdjustment(
    id: 'pressure',
    name: 'Air pressure in the positive chamber, measured cold',
    notes: null,
    unit: _psi,
  ),
  StepAdjustment(
    id: 'lsr',
    name: 'Low-speed rebound counted from fully closed',
    notes: null,
    unit: null,
    step: 1,
    min: 0,
    max: 20,
    visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
  ),
];

final _catalog = [
  NumericalAdjustment(name: 'Pressure', notes: null, unit: _psi, presetKey: 'fork:pressure', min: 0, max: 120),
  StepAdjustment(
    name: 'LSR',
    notes: null,
    unit: null,
    presetKey: 'fork:lsr',
    step: 1,
    min: 0,
    max: 16,
    visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
  ),
  SagAdjustment(name: 'SAG', notes: null, presetKey: 'fork:sag'),
];

void main() {
  Future<void> open(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPresetMergeSheet(
              context,
              productName: 'A very long catalog product name with damper and travel',
              existing: _own,
              proposal: [
                PresetMergeRow.merged(_catalog[0], _own[0]),
                PresetMergeRow.merged(_catalog[1], _own[1]),
                PresetMergeRow.notAdded(_catalog[2]),
              ],
              recordedValues: const {
                'lsr': [StepValue(18)],
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('long names fit a narrow screen in both modes ($label)', (tester) async {
      await open(tester, theme);

      expect(find.text('Result · 2 merged'), findsOneWidget);
      expect(find.text('Not added'), findsNWidgets(2), reason: 'Section header and badge');
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 of your adjustments has 1 recorded value.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the status badge opens the choices for its card', (tester) async {
    await open(tester, materialAppTheme);

    expect(find.byIcon(Icons.more_vert), findsNothing);
    await tester.tap(find.text('Merged').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Separate again'));
    await tester.pumpAndSettle();

    expect(find.text('Result · 1 merged · 1 new · 1 unchanged'), findsOneWidget);
  });
}
