import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell_layout.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pressure = NumericalAdjustment(
    id: 'n',
    name: 'Fork Pressure',
    notes: null,
    unit: AdjustmentUnit.fromLegacy('psi'),
    min: 0,
    max: 200,
  );

  Future<void> pumpCell(WidgetTester tester, AdjustmentCell cell, {double? width}) => tester.pumpWidget(
    MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: AdjustmentCellView(cell: cell, highlightInitialValues: true),
          ),
        ),
      ),
    ),
  );

  String labelOf(WidgetTester tester) => tester.getSemantics(find.byType(AdjustmentCellView)).label;

  Finder richTextWithText(String text) => find.descendant(
    of: find.byType(AdjustmentCellView),
    matching: find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text),
  );

  final arrowFinder = find.descendant(
    of: find.byType(AdjustmentCellView),
    matching: find.byIcon(cellChangeArrowIcon),
  );

  group('AdjustmentCellView arrow', () {
    testWidgets('draws an icon, not the maths-axis text glyph', (tester) async {
      await pumpCell(tester, ChangedCell(pressure, 18, 16));

      expect(arrowFinder, findsOneWidget);
      expect(richTextWithText('16'), findsOneWidget);
      // `→` sits well below the optical centre of the bold digits, so it
      // must not come back as text.
      expect(find.textContaining('→', findRichText: true), findsNothing);
    });

    testWidgets('shares one centre line with the previous value, the value and the unit', (tester) async {
      await pumpCell(tester, ChangedCell(pressure, 18, 16));

      final centres = <String, double>{
        'previous': tester.getRect(richTextWithText('16')).center.dy,
        'arrow': tester.getRect(arrowFinder).center.dy,
        'value': tester.getRect(richTextWithText('18')).center.dy,
        'unit': tester.getRect(richTextWithText('psi')).center.dy,
      };

      // The value line mixes 10, 13 and 12 px text with the arrow's square.
      // Bottom-aligning boxes of different heights drops the smaller ones'
      // optical centres, which leaves the arrow right for the value and about
      // 2 px high for the previous value; one shared centre line is what makes
      // it correct for both at once.
      for (final entry in centres.entries) {
        expect(entry.value, closeTo(centres['value']!, 0.01), reason: entry.key);
      }
    });

    testWidgets('sizes the arrow with the value, not with the previous value', (tester) async {
      await pumpCell(tester, ChangedCell(pressure, 18, 16));

      expect(tester.widget<Icon>(arrowFinder).size, CellTextStyles.arrowSize);
      expect(CellTextStyles.arrowSize, greaterThan(CellTextStyles.change.fontSize!));
    });

    testWidgets('the measured natural width still fits the rendered rows', (tester) async {
      final cell = ChangedCell(pressure, 18, 16);
      late double measured;
      await tester.pumpWidget(
        MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                measured = measureCellNaturalWidth(context, cell);
                return Center(
                  child: SizedBox(
                    width: measured,
                    child: AdjustmentCellView(cell: cell, highlightInitialValues: true),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final rows = find.descendant(of: find.byType(AdjustmentCellView), matching: find.byType(Scrollable));
      expect(rows, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        expect(tester.state<ScrollableState>(rows.at(i)).position.maxScrollExtent, closeTo(0, 0.5));
      }
    });
  });

  group('AdjustmentCellView semantics', () {
    testWidgets('a changed cell announces the previous and the current value', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCell(tester, ChangedCell(pressure, 18, 16));

      expect(labelOf(tester), 'Fork Pressure, changed from 16 to 18 psi');
      // The rendered arrow must not reach the screen reader.
      expect(labelOf(tester), isNot(contains('→')));

      semantics.dispose();
    });

    testWidgets('an unchanged cell announces the plain value', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCell(tester, ConstantCell(pressure, 18));

      expect(labelOf(tester), 'Fork Pressure, 18 psi');

      semantics.dispose();
    });
  });

  group('AdjustmentCellView tooltip', () {
    testWidgets("shows the untruncated values with the cell's arrow", (tester) async {
      await pumpCell(tester, ChangedCell(pressure, 18, 'RockShox Lyrik Ultimate'));
      expect(arrowFinder, findsOneWidget, reason: "the cell's own arrow");

      await tester.longPress(find.byType(AdjustmentCellView));
      await tester.pumpAndSettle();

      // The cell head-truncates the previous value; the tooltip is where it
      // is recovered in full.
      expect(find.textContaining('RockShox Lyrik Ultimate', findRichText: true), findsOneWidget);
      expect(find.textContaining('18 psi', findRichText: true), findsOneWidget);
      // The same icon as the cell — one in the cell, one in the tooltip —
      // and never the text glyph, which would sit low the way it used to.
      expect(find.byIcon(cellChangeArrowIcon), findsNWidgets(2));
      expect(find.textContaining('→', findRichText: true), findsNothing);
      // The struck-through previous-value line is gone.
      expect(find.textContaining('RockShox Lyrik Ultimate psi', findRichText: true), findsNothing);
    });
  });
}
