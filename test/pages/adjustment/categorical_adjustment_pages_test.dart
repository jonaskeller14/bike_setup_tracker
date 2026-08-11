import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/adjustment/categorical_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('CategoricalAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = CategoricalAdjustment(
      id: 'test-id',
      name: 'Test Categorical',
      notes: 'Some notes',
      unit: AdjustmentUnit.fromLegacy('some unit'),
      options: {'Option 1', 'Option 2'},
    );

    CategoricalAdjustment? result;

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>(
        create: (_) => AppSettings(),
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.push<CategoricalAdjustment>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoricalAdjustmentPage.edit(adjustment: initial),
                  ),
                );
              },
              child: const Text('Open Page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, equals(initial));
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required AppSettings appSettings,
    required CategoricalAdjustment? adjustment,
    required ValueSetter<CategoricalAdjustment?> onResult,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: appSettings,
        child: MaterialApp(
          theme: materialAppTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<CategoricalAdjustment>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => adjustment == null
                        ? CategoricalAdjustmentPage.add()
                        : CategoricalAdjustmentPage.edit(adjustment: adjustment),
                  ),
                );
                onResult(result);
              },
              child: const Text('Open Page'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();
  }

  testWidgets('Count Occurrences checkbox renders when enableCountedSelect is true and saving sets counted:true', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.enableCountedSelect = true;
    CategoricalAdjustment? result;

    await pumpPage(
      tester,
      appSettings: appSettings,
      adjustment: null,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Show Additional Fields'));
    await tester.pumpAndSettle();

    expect(find.text('Count Occurrences'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Adjustment Name'), 'Counted Adjustment');
    await tester.enterText(find.widgetWithText(TextFormField, 'Option 1'), 'Bar');

    await tester.tap(find.text('Count Occurrences'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.counted, isTrue);
  });

  testWidgets('Count Occurrences checkbox absent when flag is false and adjustment is not counted', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.enableCountedSelect = false;

    await pumpPage(
      tester,
      appSettings: appSettings,
      adjustment: null,
      onResult: (_) {},
    );

    expect(find.text('Count Occurrences'), findsNothing);
  });

  testWidgets('Count Occurrences checkbox shown for an existing counted adjustment even when flag is false', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.enableCountedSelect = false;
    final initial = CategoricalAdjustment(
      id: 'test-id',
      name: 'Counted Adjustment',
      notes: null,
      unit: null,
      options: {'Bar', 'Gel'},
      multiSelect: true,
      counted: true,
    );

    await pumpPage(
      tester,
      appSettings: appSettings,
      adjustment: initial,
      onResult: (_) {},
    );

    expect(find.text('Count Occurrences'), findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Count Occurrences'));
    expect(checkbox.value, isTrue);
  });
}
