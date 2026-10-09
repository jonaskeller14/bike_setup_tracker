import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/adjustment/adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/boolean_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/categorical_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/duration_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/sag_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/step_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/text_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _PageCase {
  final String typeLabel;
  final Widget Function() addDefault;
  final Widget Function(AdjustmentTerm term) add;
  final Widget Function(AdjustmentTerm term) edit;

  const _PageCase(this.typeLabel, {required this.addDefault, required this.add, required this.edit});
}

final _cases = [
  _PageCase(
    'On/Off',
    addDefault: () => BooleanAdjustmentPage.add(),
    add: (term) => BooleanAdjustmentPage.add(term: term),
    edit: (term) => BooleanAdjustmentPage.edit(
      adjustment: BooleanAdjustment(name: 'A', notes: null, unit: null),
      term: term,
    ),
  ),
  _PageCase(
    'Categorical',
    addDefault: () => CategoricalAdjustmentPage.add(),
    add: (term) => CategoricalAdjustmentPage.add(term: term),
    edit: (term) => CategoricalAdjustmentPage.edit(
      adjustment: CategoricalAdjustment(name: 'A', notes: null, unit: null, options: const {'X', 'Y'}),
      term: term,
    ),
  ),
  _PageCase(
    'Duration',
    addDefault: () => DurationAdjustmentPage.add(),
    add: (term) => DurationAdjustmentPage.add(term: term),
    edit: (term) => DurationAdjustmentPage.edit(
      adjustment: DurationAdjustment(name: 'A', notes: null, unit: null),
      term: term,
    ),
  ),
  _PageCase(
    'Numerical',
    addDefault: () => NumericalAdjustmentPage.add(),
    add: (term) => NumericalAdjustmentPage.add(term: term),
    edit: (term) => NumericalAdjustmentPage.edit(
      adjustment: NumericalAdjustment(name: 'A', notes: null, unit: null, min: 0),
      term: term,
    ),
  ),
  _PageCase(
    'SAG',
    addDefault: () => SagAdjustmentPage.add(),
    add: (term) => SagAdjustmentPage.add(term: term),
    edit: (term) => SagAdjustmentPage.edit(
      adjustment: SagAdjustment(name: 'A', notes: null),
      term: term,
    ),
  ),
  _PageCase(
    'Step',
    addDefault: () => StepAdjustmentPage.add(),
    add: (term) => StepAdjustmentPage.add(term: term),
    edit: (term) => StepAdjustmentPage.edit(
      adjustment: StepAdjustment(
        name: 'A',
        notes: null,
        unit: null,
        step: 1,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.slider,
      ),
      term: term,
    ),
  ),
  _PageCase(
    'Text',
    addDefault: () => TextAdjustmentPage.add(),
    add: (term) => TextAdjustmentPage.add(term: term),
    edit: (term) => TextAdjustmentPage.edit(
      adjustment: TextAdjustment(name: 'A', notes: null, unit: null),
      term: term,
    ),
  ),
];

Future<void> _pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppSettings>(
      create: (_) => AppSettings(),
      child: MaterialApp(theme: materialAppTheme, home: page),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _appBarTitle(String text) => find.descendant(of: find.byType(AppBar), matching: find.text(text));

void main() {
  for (final c in _cases) {
    group('${c.typeLabel} page', () {
      testWidgets('says "Adjustment" by default', (tester) async {
        await _pumpPage(tester, c.addDefault());

        expect(_appBarTitle('Add ${c.typeLabel} Adjustment'), findsOneWidget);
        expect(find.text('Adjustment Name'), findsOneWidget);
        expect(find.textContaining('Attribute'), findsNothing);
      });

      testWidgets('says "Attribute" in add mode with AdjustmentTerm.attribute', (tester) async {
        await _pumpPage(tester, c.add(AdjustmentTerm.attribute));

        expect(_appBarTitle('Add ${c.typeLabel} Attribute'), findsOneWidget);
        expect(find.text('Attribute Name'), findsOneWidget);
        expect(find.textContaining('Adjustment'), findsNothing);
      });

      testWidgets('says "Attribute" in edit mode with AdjustmentTerm.attribute', (tester) async {
        await _pumpPage(tester, c.edit(AdjustmentTerm.attribute));

        expect(_appBarTitle('Edit ${c.typeLabel} Attribute'), findsOneWidget);
        expect(find.text('Attribute Name'), findsOneWidget);
      });
    });
  }

  testWidgets('SAG → numerical conversion keeps the term', (tester) async {
    await _pumpPage(
      tester,
      SagAdjustmentPage.edit(
        adjustment: SagAdjustment(name: 'Sag', notes: null),
        term: AdjustmentTerm.attribute,
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Convert to plain numerical'));
    await tester.pumpAndSettle();

    expect(_appBarTitle('Edit Numerical Attribute'), findsOneWidget);
  });
}
