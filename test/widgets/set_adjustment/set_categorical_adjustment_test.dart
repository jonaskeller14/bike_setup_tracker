import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_categorical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = {"Option #1", "Option #2", "Option #3"};
  final validOption = options.first;
  const invalidOption1 = "Invalid Option #1";

  Widget buildWidget({
    required List<String>? initialValue,
    required List<String>? value,
    required Key formKey,
    bool multiSelect = false,
    bool counted = false,
  }) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetCategoricalAdjustmentWidget(
            key: const ValueKey("CategoricalAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: CategoricalAdjustment(
              name: "CategoricalAdjustment #1",
              notes: null,
              unit: null,
              options: options,
              multiSelect: multiSelect,
              counted: counted,
            ),
          ),
        ),
      ),
    );
  }

  group("SetCategoricalAdjustmentWidget/field display & validation", () {
    testWidgets('valid value renders and validates', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      // A dangling *initialValue* (previous value) does not affect validity —
      // only the current value is validated.
      await tester.pumpWidget(buildWidget(initialValue: [invalidOption1], value: [validOption], formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text(validOption), findsOneWidget);
      expect(find.text("Please select"), findsNothing);
    });

    testWidgets('a dangling value is invalid and not shown in the field', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: [invalidOption1], formKey: formKey));
      expect(formKey.currentState!.validate(), isFalse);
      expect(find.text(invalidOption1), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
      await tester.pump();
      expect(find.text('Contains options that no longer exist'), findsOneWidget);
    });

    testWidgets('a dangling value with a valid previous value is still invalid', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: [validOption], value: [invalidOption1], formKey: formKey));
      expect(formKey.currentState!.validate(), isFalse);
      expect(find.text(invalidOption1), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
    });

    testWidgets('single-select rejects more than one selected option', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: ["Option #1", "Option #2"],
        formKey: formKey,
      ));
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Only one option can be selected'), findsOneWidget);
    });
  });

  group("SetCategoricalAdjustmentWidget/multi-select", () {
    testWidgets('shows selected options comma-separated in option order', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      // Passed out of order; the field should render them in option order.
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #3", "Option #1"],
        formKey: formKey,
        multiSelect: true,
      ));
      expect(find.text("Option #1, Option #3"), findsOneWidget);
      expect(find.text("Please select"), findsNothing);
    });

    testWidgets('multiple valid options are allowed', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #1", "Option #2"],
        formKey: formKey,
        multiSelect: true,
      ));
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('ignores dangling values in the field but flags them invalid', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #2", invalidOption1],
        formKey: formKey,
        multiSelect: true,
      ));
      // Only the still-valid option is shown; the dangling one surfaces in the sheet.
      expect(find.text("Option #2"), findsOneWidget);
      expect(find.text(invalidOption1), findsNothing);
      // ...but the dangling value still makes the field invalid.
      expect(formKey.currentState!.validate(), isFalse);
    });
  });

  group("SetCategoricalAdjustmentWidget/counted", () {
    testWidgets('field renders grouped counts in option order', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #1", "Option #1", "Option #2", "Option #2", "Option #2"],
        formKey: formKey,
        multiSelect: true,
        counted: true,
      ));
      expect(find.text("Option #1 (2), Option #2 (3)"), findsOneWidget);
    });

    testWidgets('a counted value validates when counted:true', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #1", "Option #1", "Option #1"],
        formKey: formKey,
        counted: true,
      ));
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('repeats are rejected when counted:false', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #1", "Option #1"],
        formKey: formKey,
        multiSelect: true,
      ));
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('An option cannot be selected more than once'), findsOneWidget);
    });
  });

  group("SetCategoricalAdjustmentWidget/revert & explicit empty", () {
    Widget captureWidget({
      List<String>? initialValue,
      required List<String>? value,
      required void Function(List<String>?) onChanged,
    }) {
      return MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: SetCategoricalAdjustmentWidget(
            key: const ValueKey("cat"),
            initialValue: initialValue,
            value: value,
            onChanged: onChanged,
            adjustment: CategoricalAdjustment(
              name: "CategoricalAdjustment #1",
              notes: null,
              unit: null,
              options: options,
              multiSelect: true,
            ),
          ),
        ),
      );
    }

    testWidgets('revert button restores the previous value', (WidgetTester tester) async {
      List<String>? emitted = const ["sentinel"];
      var calls = 0;
      await tester.pumpWidget(captureWidget(
        initialValue: const ["Option #2"],
        value: const ["Option #1"],
        onChanged: (v) {
          calls++;
          emitted = v;
        },
      ));

      expect(find.byIcon(Icons.replay), findsOneWidget);
      await tester.tap(find.byIcon(Icons.replay));
      await tester.pump();

      expect(calls, 1);
      expect(emitted, const ["Option #2"], reason: 'reverts to the inherited value');
    });

    testWidgets('revert with no previous value clears to unset (null)', (WidgetTester tester) async {
      List<String>? emitted = const ["sentinel"];
      await tester.pumpWidget(captureWidget(
        initialValue: null,
        value: [validOption],
        onChanged: (v) => emitted = v,
      ));

      await tester.tap(find.byIcon(Icons.replay));
      await tester.pump();

      expect(emitted, isNull);
    });

    testWidgets('no revert button when the value already matches the previous value', (WidgetTester tester) async {
      await tester.pumpWidget(captureWidget(
        initialValue: [validOption],
        value: [validOption],
        onChanged: (_) {},
      ));
      expect(find.byIcon(Icons.replay), findsNothing);
    });

    testWidgets('no revert button when unset (value null)', (WidgetTester tester) async {
      await tester.pumpWidget(captureWidget(initialValue: null, value: null, onChanged: (_) {}));
      expect(find.byIcon(Icons.replay), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
    });

    testWidgets('explicit empty [] over a previous value offers a revert', (WidgetTester tester) async {
      await tester.pumpWidget(captureWidget(
        initialValue: [validOption],
        value: const <String>[],
        onChanged: (_) {},
      ));
      // Empty differs from the previous value, so a revert is offered.
      expect(find.byIcon(Icons.replay), findsOneWidget);
      expect(find.text("Please select"), findsOneWidget);
    });

    testWidgets('deselecting the last chip in the sheet emits [] (explicit none), not null', (WidgetTester tester) async {
      List<String>? emitted = const ["sentinel"];
      await tester.pumpWidget(captureWidget(
        value: [validOption],
        onChanged: (v) => emitted = v,
      ));

      // Open the sheet from the field, then toggle the only selected chip off.
      await tester.tap(find.text(validOption));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, validOption));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull, reason: 'deselect-all is an explicit empty, not unset');
      expect(emitted, isEmpty);
    });
  });

  group("SetCategoricalAdjustmentWidget/add option", () {
    Widget buildAddWidget({
      List<String>? value,
      Future<void> Function(String option)? onAddOption,
      void Function(List<String>?)? onChanged,
      bool multiSelect = false,
      bool counted = false,
    }) {
      return MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: SetCategoricalAdjustmentWidget(
            key: const ValueKey("cat-add"),
            initialValue: null,
            value: value,
            onChanged: onChanged ?? (_) {},
            onAddOption: onAddOption,
            adjustment: CategoricalAdjustment(
              name: "CategoricalAdjustment #1",
              notes: null,
              unit: null,
              options: options,
              multiSelect: multiSelect,
              counted: counted,
            ),
          ),
        ),
      );
    }

    testWidgets('no "+" chip in the sheet when onAddOption is null', (WidgetTester tester) async {
      await tester.pumpWidget(buildAddWidget(value: [validOption]));
      await tester.tap(find.text(validOption));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNothing);
    });

    testWidgets('"+" chip persists the typed option and auto-selects it', (WidgetTester tester) async {
      final added = <String>[];
      List<String>? emitted;
      await tester.pumpWidget(buildAddWidget(
        value: [validOption],
        multiSelect: true,
        onChanged: (v) => emitted = v,
        onAddOption: (option) async {
          added.add(option);
        },
      ));
      await tester.tap(find.text(validOption));
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsOneWidget);
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Option');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(added, ['New Option']);
      expect(emitted, contains('New Option'));
    });

    testWidgets('a duplicate option is rejected before persisting', (WidgetTester tester) async {
      final added = <String>[];
      await tester.pumpWidget(buildAddWidget(
        value: [validOption],
        multiSelect: true,
        onAddOption: (option) async {
          added.add(option);
        },
      ));
      await tester.tap(find.text(validOption));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), validOption);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(added, isEmpty, reason: 'a duplicate never reaches the persist callback');
      expect(find.text('Already exists'), findsOneWidget);
    });
  });

  group("CategoricalAdjustment.copyWith", () {
    test('overrides only the given fields and keeps the rest', () {
      final adjustment = CategoricalAdjustment(
        name: 'n',
        notes: 'note',
        unit: null,
        options: {'a', 'b'},
        multiSelect: true,
        counted: true,
      );
      final result = adjustment.copyWith(options: {...adjustment.options, 'c'});
      expect(result.options, {'a', 'b', 'c'});
      expect(result.id, adjustment.id);
      expect(result.name, 'n');
      expect(result.notes, 'note');
      expect(result.multiSelect, isTrue);
      expect(result.counted, isTrue);
    });

    test('with no arguments returns an equal copy', () {
      final adjustment = CategoricalAdjustment(
        name: 'n',
        notes: 'note',
        unit: null,
        options: {'a'},
        multiSelect: true,
      );
      expect(adjustment.copyWith(), adjustment);
    });

    test('can clear a nullable field explicitly', () {
      final adjustment = CategoricalAdjustment(name: 'n', notes: 'note', unit: null, options: {'a'});
      expect(adjustment.copyWith(notes: null).notes, isNull);
    });
  });
}
