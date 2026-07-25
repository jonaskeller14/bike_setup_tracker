import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/set_categorical.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = {"Bar", "Gel", "Bottle"};

  Widget buildHarness({
    required List<String> selected,
    required bool multiSelect,
    required ValueChanged<List<String>> onChanged,
    List<String>? initialValue,
  }) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSetCategoricalSheet(
              context: context,
              adjustment: CategoricalAdjustment(
                name: "Nutrition",
                notes: null,
                unit: null,
                options: options,
                multiSelect: multiSelect,
                counted: true,
              ),
              selected: selected,
              initialValue: initialValue,
              onChanged: onChanged,
            ),
            child: const Text("Open"),
          ),
        ),
      ),
    );
  }

  group("showSetCategoricalSheet/counted (multi)", () {
    testWidgets(
      'tapping Bar twice then Gel thrice emits repeats grouped in option order; the x on Gel decrements by one',
      (WidgetTester tester) async {
        List<String>? emitted;
        await tester.pumpWidget(buildHarness(
          selected: const [],
          multiSelect: true,
          onChanged: (v) => emitted = v,
        ));
        await tester.tap(find.text("Open"));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(InputChip, "Bar"));
        await tester.pump();
        // A count of 1 shows no "(1)" suffix, so the chip is still labelled "Bar".
        expect(find.widgetWithText(InputChip, "Bar (1)"), findsNothing);
        await tester.tap(find.widgetWithText(InputChip, "Bar"));
        await tester.pump();

        await tester.tap(find.widgetWithText(InputChip, "Gel"));
        await tester.pump();
        await tester.tap(find.widgetWithText(InputChip, "Gel"));
        await tester.pump();
        await tester.tap(find.widgetWithText(InputChip, "Gel (2)"));
        await tester.pump();

        expect(emitted, const ["Bar", "Bar", "Gel", "Gel", "Gel"]);

        await tester.tap(find.descendant(
          of: find.widgetWithText(InputChip, "Gel (3)"),
          matching: find.byIcon(Icons.close),
        ));
        await tester.pump();

        expect(emitted, const ["Bar", "Bar", "Gel", "Gel"]);
      },
    );
  });

  group("showSetCategoricalSheet/counted-single", () {
    testWidgets('tapping Bar three times then Gel resets to [Gel]', (WidgetTester tester) async {
      List<String>? emitted;
      await tester.pumpWidget(buildHarness(
        selected: const [],
        multiSelect: false,
        onChanged: (v) => emitted = v,
      ));
      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InputChip, "Bar"));
      await tester.pump();
      await tester.tap(find.widgetWithText(InputChip, "Bar"));
      await tester.pump();
      await tester.tap(find.widgetWithText(InputChip, "Bar (2)"));
      await tester.pump();

      expect(emitted, const ["Bar", "Bar", "Bar"]);

      await tester.tap(find.widgetWithText(InputChip, "Gel"));
      await tester.pump();

      expect(emitted, const ["Gel"]);
      // The sheet stays open (no auto-close) so counting can continue.
      expect(find.widgetWithText(InputChip, "Bar"), findsOneWidget);
    });
  });

  group("showSetCategoricalSheet/counted highlighting", () {
    testWidgets('an unchanged count stays unhighlighted, an increased count turns orange', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildHarness(
        selected: const ["Bar"],
        initialValue: const ["Bar"],
        multiSelect: true,
        onChanged: (_) {},
      ));
      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();

      final unchangedChip = tester.widget<InputChip>(find.widgetWithText(InputChip, "Bar"));
      expect(unchangedChip.checkmarkColor, isNull, reason: 'count matches the previous value');

      await tester.tap(find.widgetWithText(InputChip, "Bar"));
      await tester.pump();

      final highlights = materialAppTheme.extension<ValueHighlightColors>()!;
      final increasedChip = tester.widget<InputChip>(find.widgetWithText(InputChip, "Bar (2)"));
      expect(increasedChip.checkmarkColor, highlights.changed);
      expect(increasedChip.selectedColor, highlights.changed.withValues(alpha: 0.18));
    });
  });
}
