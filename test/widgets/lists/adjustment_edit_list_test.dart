import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_edit_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int counter = 0;

  RecordedValue record(
    AdjustmentValue value, {
    bool deleted = false,
    RecordedValueSource source = RecordedValueSource.setup,
  }) {
    final id = 'r${counter++}';
    return RecordedValue(
      recordId: id,
      source: source,
      label: id,
      dateTimeLocal: DateTime(2024),
      value: value,
      isDeleted: deleted,
    );
  }

  NumericalAdjustment pressure({double? max = 20, String name = 'Pressure'}) =>
      NumericalAdjustment(id: 'pressure', name: name, notes: null, unit: null, min: 0, max: max);

  NumericalAdjustment rebound() => NumericalAdjustment(id: 'rebound', name: 'Rebound', notes: null, unit: null);

  MigrationProposal narrowed(List<RecordedValue> recorded) =>
      MigrationProposal.build(before: pressure(), after: pressure(max: 10), recorded: recorded);

  Future<void> pumpList(
    WidgetTester tester, {
    required List<Adjustment> adjustments,
    Map<String, Adjustment>? initialAdjustments,
    Map<String, MigrationProposal>? pendingMigrations,
    ThemeData? theme,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdjustmentEditList(
              adjustments: adjustments,
              initialAdjustments: initialAdjustments,
              pendingMigrations: pendingMigrations,
              editAdjustment: (_) {},
              duplicateAdjustment: (_) {},
              removeAdjustment: (_) {},
              onReorderAdjustments: (_, _) {},
            ),
          ),
        ),
      ),
    );
  }

  Color? textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

  group('pending migrations', () {
    testWidgets('a line shows only for the adjustment with a pending change', (tester) async {
      await pumpList(
        tester,
        adjustments: [pressure(max: 10), rebound()],
        pendingMigrations: {
          'pressure': narrowed([record(const NumericalValue(20)), record(const NumericalValue(15), deleted: true)]),
        },
      );

      expect(find.text('Updates 1 setup (+1 deleted) on save'), findsOneWidget);
      expect(find.byIcon(Icons.sync_alt), findsOneWidget);
      expect(textColor(tester, 'Updates 1 setup (+1 deleted) on save'), materialAppTheme.colorScheme.primary);
    });

    testWidgets('an empty pending proposal shows nothing', (tester) async {
      await pumpList(
        tester,
        adjustments: [pressure(max: 10)],
        pendingMigrations: {'pressure': narrowed(const [])},
      );

      expect(find.byIcon(Icons.sync_alt), findsNothing);
    });

    testWidgets('rating metrics count rating entries', (tester) async {
      await pumpList(
        tester,
        adjustments: [pressure(max: 10)],
        pendingMigrations: {
          'pressure': narrowed([
            record(const NumericalValue(20), source: RecordedValueSource.ratingEntry),
            record(const NumericalValue(30), source: RecordedValueSource.ratingEntry),
          ]),
        },
      );

      expect(find.text('Updates 2 rating entries on save'), findsOneWidget);
    });

    testWidgets('a cleared value is called out in the error color', (tester) async {
      final pending = narrowed([
        record(const NumericalValue(20)),
        record(const NumericalValue(30)),
      ]).withChoice('range', MigrationChoice.clear);
      await pumpList(tester, adjustments: [pressure(max: 10)], pendingMigrations: {'pressure': pending});

      const line = 'Updates 2 setups on save · 2 setups lose their value';
      expect(find.text(line), findsOneWidget);
      expect(textColor(tester, line), materialAppTheme.colorScheme.error);
    });

    CategoricalAdjustment mode(Set<String> options, {bool multiSelect = false}) => CategoricalAdjustment(
      id: 'mode',
      name: 'Mode',
      notes: null,
      unit: null,
      options: options,
      multiSelect: multiSelect,
    );

    testWidgets('counts every updated record, and separately the ones left empty', (tester) async {
      // A rename and a deleted option cleared: two setups change, one loses its value.
      final pending = MigrationProposal.build(
        before: mode({'open', 'pedal', 'lock'}),
        after: mode({'open', 'pedal2'}),
        optionOrigins: const {'open': 'open', 'pedal2': 'pedal'},
        recorded: [record(CategoricalValue(const ['pedal'])), record(CategoricalValue(const ['lock']))],
      ).withChoice('delete:lock', MigrationChoice.clear);
      await pumpList(tester, adjustments: [mode({'open', 'pedal2'})], pendingMigrations: {'mode': pending});

      const line = 'Updates 2 setups on save · 1 setup loses its value';
      expect(find.text(line), findsOneWidget);
      expect(textColor(tester, line), materialAppTheme.colorScheme.error);
    });

    testWidgets('an option removed from a selection that keeps others leaves no record empty', (tester) async {
      final pending = MigrationProposal.build(
        before: mode({'open', 'lock'}, multiSelect: true),
        after: mode({'open'}, multiSelect: true),
        recorded: [record(CategoricalValue(const ['open', 'lock']))],
      ).withChoice('delete:lock', MigrationChoice.clear);
      await pumpList(
        tester,
        adjustments: [mode({'open'}, multiSelect: true)],
        pendingMigrations: {'mode': pending},
      );

      const line = 'Updates 1 setup on save';
      expect(find.text(line), findsOneWidget);
      expect(textColor(tester, line), materialAppTheme.colorScheme.error);
    });

    for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('a long name and line fit 320 px in the $name theme', (tester) async {
        await pumpList(
          tester,
          adjustments: [pressure(max: 10, name: 'A very long adjustment name that keeps going past the edge')],
          pendingMigrations: {
            'pressure': narrowed([for (var i = 0; i < 12; i++) record(NumericalValue(20.0 + i), deleted: i.isEven)]),
          },
          theme: theme,
          width: 320,
        );

        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.sync_alt), findsOneWidget);
      });
    }
  });

  group('changed tint', () {
    Color? cardColor(WidgetTester tester) => tester.widget<Card>(find.byType(Card)).color;

    testWidgets('an edited adjustment is tinted', (tester) async {
      await pumpList(tester, adjustments: [pressure(max: 10)], initialAdjustments: {'pressure': pressure()});
      final fill = materialAppTheme.extension<ValueHighlightColors>()!.changedFill;
      expect(cardColor(tester), Color.alphaBlend(fill, materialAppTheme.colorScheme.surface));
      expect(cardColor(tester)!.a, 1, reason: 'A see-through card shows its shadow');
    });

    testWidgets('an unchanged adjustment is not', (tester) async {
      await pumpList(tester, adjustments: [pressure()], initialAdjustments: {'pressure': pressure()});
      expect(cardColor(tester), isNull);
    });
  });
}
