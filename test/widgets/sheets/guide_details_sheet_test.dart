import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/widgets/sheets/guide_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../goldens/support/localized_test_app.dart';

const _catalog = '''
brand: FOX
component_type: fork
nodes:
  - label: "38"
    level: model
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 100 }
    options:
      travel_mm: [160, 170]
      wheel_size: [29, 27.5]
''';

void main() {
  final preset = catalogProducts(parseCatalogFile(_catalog)).single;

  /// What the sheet resolved to, once closed.
  ResolvedPreset? result;

  Future<void> open(WidgetTester tester, {ThemeData? theme}) async {
    result = null;
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedTestApp(
        theme: theme ?? materialAppTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showGuideDetailsSheet(
              context,
              componentName: 'A very long component name on a narrow screen',
              preset: preset,
              axisIds: const ['travel_mm'],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(of: find.text('Save'), matching: find.byWidgetPredicate((w) => w is FilledButton)),
  );

  testWidgets('shows only the asked-for detail, and saves once one is chosen', (tester) async {
    await open(tester);

    expect(find.text('Missing catalog details'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Wheel size'), findsNothing);
    expect(saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('170 mm'));
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result?.selections['travel_mm']?.id, 170);
    expect(result?.selections.containsKey('wheel_size'), isFalse);
  });

  testWidgets('tapping the chosen value again clears it', (tester) async {
    await open(tester);

    await tester.tap(find.text('160 mm'));
    await tester.pump();
    await tester.tap(find.text('160 mm'));
    await tester.pump();

    expect(saveButton(tester).onPressed, isNull);
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('fits a narrow screen ($label)', (tester) async {
      await open(tester, theme: theme);

      expect(tester.takeException(), isNull);
    });
  }
}
