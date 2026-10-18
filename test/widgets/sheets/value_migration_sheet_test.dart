import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:bike_setup_tracker/widgets/sheets/value_migration_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
const _bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

int _counter = 0;

RecordedValue _record(
  AdjustmentValue value, {
  String? label,
  bool deleted = false,
  DateTime? day,
  RecordedValueSource source = RecordedValueSource.setup,
}) {
  final id = 'r${_counter++}';
  return RecordedValue(
    recordId: id,
    source: source,
    label: label ?? 'Record $id',
    dateTimeLocal: day ?? DateTime(2024, 3, 1),
    value: value,
    isDeleted: deleted,
  );
}

NumericalAdjustment _numerical({AdjustmentUnit? unit, double? max}) =>
    NumericalAdjustment(id: 'a', name: 'A', notes: null, unit: unit, max: max);

CategoricalAdjustment _categorical(Set<String> options, {bool multiSelect = false}) =>
    CategoricalAdjustment(id: 'a', name: 'A', notes: null, unit: null, options: options, multiSelect: multiSelect);

MigrationProposal _rangeProposal({List<RecordedValue>? recorded}) => MigrationProposal.build(
  before: _numerical(unit: _bar, max: 100),
  after: _numerical(unit: _bar, max: 50),
  recorded:
      recorded ??
      [
        _record(const NumericalValue(80), label: 'Alpine', day: DateTime(2024, 3, 2)),
        _record(const NumericalValue(90), label: 'Bike park', day: DateTime(2024, 3, 1)),
        _record(const NumericalValue(95), label: 'Old setup', deleted: true),
      ],
);

void main() {
  late ValueMigration? result;
  late bool resultReported;

  Future<void> openSheet(
    WidgetTester tester,
    MigrationProposal proposal, {
    ThemeData? theme,
    String adjustmentName = 'Pressure',
    Size size = const Size(400, 900),
    bool replacesEarlier = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    result = null;
    resultReported = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await showValueMigrationSheet(
                    context,
                    adjustmentName: adjustmentName,
                    proposal: proposal,
                    replacesEarlier: replacesEarlier,
                  );
                  result = confirmed?.toMigration();
                  resultReported = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('summarises the affected records, with deleted ones counted separately', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.text('Update recorded values'), findsOneWidget);
    expect(
      find.text("Your change to 'Pressure' affects 2 setups (+1 deleted). Choose what happens to their values."),
      findsOneWidget,
    );
    expect(find.text('Values outside the new range'), findsOneWidget);
  });

  group('the confirm button names how many records it updates', () {
    testWidgets('live records, without the deleted ones', (tester) async {
      await openSheet(tester, _rangeProposal());
      expect(find.widgetWithText(FilledButton, 'Update 2 setups'), findsOneWidget);
    });

    testWidgets('deleted records when there are no live ones', (tester) async {
      await openSheet(tester, _rangeProposal(recorded: [_record(const NumericalValue(80), deleted: true)]));
      expect(find.widgetWithText(FilledButton, 'Update 1 deleted setup'), findsOneWidget);
    });

    testWidgets('rating entries', (tester) async {
      await openSheet(
        tester,
        _rangeProposal(recorded: [_record(const NumericalValue(80), source: RecordedValueSource.ratingEntry)]),
      );
      expect(find.widgetWithText(FilledButton, 'Update 1 rating entry'), findsOneWidget);
    });
  });

  testWidgets('without a decision the summary does not ask for one', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B'}),
      after: _categorical({'A2', 'B'}),
      optionOrigins: const {'A2': 'A', 'B': 'B'},
      recorded: [_record(CategoricalValue(const ['A']))],
    );
    await openSheet(tester, proposal);

    expect(find.text("Your change to 'Pressure' affects 1 setup."), findsOneWidget);
    expect(find.textContaining('Need different values'), findsNothing);
  });

  testWidgets('a decision points to editing the records one by one', (tester) async {
    await openSheet(tester, _rangeProposal());
    expect(
      find.text('Need different values in different setups? Cancel, change those setups first, then make this edit.'),
      findsOneWidget,
    );
  });

  testWidgets('rating metrics point to editing rating entries', (tester) async {
    await openSheet(
      tester,
      _rangeProposal(recorded: [_record(const NumericalValue(80), source: RecordedValueSource.ratingEntry)]),
    );
    expect(find.textContaining('Cancel, change those rating entries first'), findsOneWidget);
  });

  testWidgets('has no record list to open', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.textContaining('Show affected'), findsNothing);
    expect(find.text('Alpine'), findsNothing);
  });

  testWidgets('counts rating entries', (tester) async {
    final proposal = _rangeProposal(
      recorded: [_record(const NumericalValue(80), source: RecordedValueSource.ratingEntry)],
    );
    await openSheet(tester, proposal);

    expect(find.textContaining('affects 1 rating entry.'), findsOneWidget);
  });

  testWidgets('shows a single example card with the value before and after', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.text('Example'), findsOneWidget);
    expect(find.text('80 bar'), findsOneWidget);
    expect(find.text('50 bar'), findsOneWidget);
  });

  testWidgets('one chain shows the example through a unit change and a range change', (tester) async {
    final proposal = MigrationProposal.build(
      before: _numerical(unit: _psi, max: 100),
      after: _numerical(unit: _bar, max: 0.5),
      recorded: [_record(const NumericalValue(10))],
    );
    await openSheet(tester, proposal);

    expect(find.text('Example'), findsOneWidget);
    expect(find.text('10 psi'), findsOneWidget);
    expect(find.text('≈ 0.689 bar'), findsOneWidget);
    expect(find.text('0.5 bar'), findsOneWidget);
    expect(find.text('1: Unit changed from psi to bar'), findsOneWidget);
    expect(find.text('2: Values outside the new range'), findsOneWidget);
  });

  testWidgets('shows the interim value of a chain smaller and muted', (tester) async {
    final proposal = MigrationProposal.build(
      before: _numerical(unit: _psi, max: 100),
      after: _numerical(unit: _bar, max: 0.5),
      recorded: [_record(const NumericalValue(10))],
    );
    await openSheet(tester, proposal);

    final context = tester.element(find.text('Example'));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    TextStyle? styleOf(String text) => tester.widget<Text>(find.text(text)).style;
    expect(styleOf('≈ 0.689 bar')?.color, muted);
    expect(styleOf('10 psi')?.color, isNot(muted));
    expect(styleOf('0.5 bar')?.color, isNot(muted));
    expect(styleOf('≈ 0.689 bar')!.fontSize!, lessThan(styleOf('0.5 bar')!.fontSize!));
  });

  testWidgets('rounds a converted example value but keeps exact ones', (tester) async {
    final proposal = MigrationProposal.build(
      before: _numerical(unit: _psi),
      after: _numerical(unit: _bar),
      recorded: [_record(const NumericalValue(83))],
    );
    await openSheet(tester, proposal);

    expect(find.text('83 psi'), findsOneWidget);
    expect(find.text('≈ 5.72 bar'), findsOneWidget);
  });

  testWidgets('the hint counts the records the selected choice changes', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.text('2 setups (+1 deleted) move to the nearest limit.'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('2 setups (+1 deleted) lose their value.'), findsOneWidget);
  });

  testWidgets('the hint uses the singular for one record', (tester) async {
    await openSheet(tester, _rangeProposal(recorded: [_record(const NumericalValue(80))]));

    expect(find.text('1 setup moves to the nearest limit.'), findsOneWidget);
  });

  testWidgets('a deleted option hint names the option and its target', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B', 'C'}),
      after: _categorical({'A', 'B'}),
      optionOrigins: const {'A': 'A', 'B': 'B'},
      recorded: [_record(CategoricalValue(const ['C'])), _record(CategoricalValue(const ['C']))],
    );
    await openSheet(tester, proposal);

    expect(find.text("'C' becomes 'A' in 2 setups."), findsOneWidget);
  });

  testWidgets('choosing Clear turns the confirm button into the error color', (tester) async {
    await openSheet(tester, _rangeProposal());

    final context = tester.element(find.byKey(const Key('value-migration-confirm')));
    final error = Theme.of(context).colorScheme.error;
    Color? background() => tester
        .widget<FilledButton>(find.byKey(const Key('value-migration-confirm')))
        .style
        ?.backgroundColor
        ?.resolve({});
    expect(background(), isNot(error));

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(background(), error);
  });

  testWidgets('a single decision has no step number', (tester) async {
    await openSheet(tester, _rangeProposal());

    expect(find.text('Values outside the new range'), findsOneWidget);
    expect(find.textContaining('1: '), findsNothing);
  });


  testWidgets('picking Clear updates the example and the returned migration', (tester) async {
    final proposal = _rangeProposal();
    await openSheet(tester, proposal);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No value'), findsOneWidget);
    expect(find.text('50 bar'), findsNothing);

    await tester.tap(find.byKey(const Key('value-migration-confirm')));
    await tester.pumpAndSettle();

    expect(result, proposal.withChoice('range', MigrationChoice.clear).toMigration());
    expect(result!.apply(const NumericalValue(80)), isNull);
  });

  testWidgets('confirming with the defaults returns the default migration', (tester) async {
    final proposal = _rangeProposal();
    await openSheet(tester, proposal);

    await tester.tap(find.byKey(const Key('value-migration-confirm')));
    await tester.pumpAndSettle();

    expect(result, proposal.toMigration());
  });

  testWidgets('Cancel returns null', (tester) async {
    await openSheet(tester, _rangeProposal());

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(resultReported, isTrue);
    expect(result, isNull);
  });

  testWidgets('a choice that creates a later issue shows it', (tester) async {
    final proposal = MigrationProposal.build(
      before: _numerical(unit: _psi),
      after: _numerical(unit: _bar, max: 2),
      recorded: [_record(const NumericalValue(10))],
    );
    await openSheet(tester, proposal);

    expect(find.text('Unit changed from psi to bar'), findsOneWidget);
    expect(find.text('Values outside the new range'), findsNothing);
    expect(find.text('≈ 0.689 bar'), findsOneWidget);

    await tester.tap(find.text('Keep numbers'));
    await tester.pumpAndSettle();

    expect(find.text('1: Unit changed from psi to bar'), findsOneWidget);
    expect(find.text('2: Values outside the new range'), findsOneWidget);
    expect(find.text('2 bar'), findsOneWidget);
  });

  testWidgets('an automatic issue shows its example but no choice', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B'}),
      after: _categorical({'A2', 'B'}),
      optionOrigins: const {'A2': 'A', 'B': 'B'},
      recorded: [_record(CategoricalValue(const ['A']))],
    );
    await openSheet(tester, proposal);

    expect(find.text('Renamed options'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.byType(SegmentedButton<MigrationChoice>), findsNothing);
    expect(find.byType(DropdownButtonFormField<MigrationChoice>), findsNothing);
  });

  testWidgets('a deleted option is replaced through a dropdown', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B', 'C'}),
      after: _categorical({'A', 'B'}),
      optionOrigins: const {'A': 'A', 'B': 'B'},
      recorded: [_record(CategoricalValue(const ['C']))],
    );
    await openSheet(tester, proposal);

    expect(find.text("'C' was deleted"), findsNWidgets(2)); // example caption and choice title

    await tester.tap(find.byType(DropdownButtonFormField<MigrationChoice>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('value-migration-confirm')));
    await tester.pumpAndSettle();

    expect(result!.apply(CategoricalValue(const ['C'])), CategoricalValue(const ['B']));
  });

  group('option dropdown wording', () {
    Future<void> openDropdown(WidgetTester tester) async {
      await tester.tap(find.byType(DropdownButtonFormField<MigrationChoice>));
      await tester.pumpAndSettle();
    }

    testWidgets('a deleted single-select option is replaced or left without a value', (tester) async {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'C'}),
        after: _categorical({'A'}),
        recorded: [_record(CategoricalValue(const ['C']))],
      );
      await openSheet(tester, proposal);

      expect(find.text("Replace 'C' with"), findsOneWidget);
      await openDropdown(tester);
      await tester.tap(find.text('No value').last);
      await tester.pumpAndSettle();
      expect(find.text('1 setup loses its value.'), findsOneWidget);
    });

    testWidgets('a deleted multi-select option is removed from the selection', (tester) async {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'C'}, multiSelect: true),
        after: _categorical({'A'}, multiSelect: true),
        recorded: [_record(CategoricalValue(const ['A', 'C']))],
      );
      await openSheet(tester, proposal);

      await openDropdown(tester);
      expect(find.text('No value'), findsNothing);
      await tester.tap(find.text("Remove 'C' from the selection").last);
      await tester.pumpAndSettle();
      expect(find.text("'C' is removed from 1 setup."), findsOneWidget);

      await tester.tap(find.byKey(const Key('value-migration-confirm')));
      await tester.pumpAndSettle();
      expect(result!.apply(CategoricalValue(const ['A', 'C'])), CategoricalValue(const ['A']));
    });

    testWidgets('a combination names both options and can be left without a value', (tester) async {
      final proposal = MigrationProposal.build(
        before: _categorical({'Soft', 'Firm'}, multiSelect: true),
        after: _categorical({'Soft', 'Firm'}),
        recorded: [_record(CategoricalValue(const ['Soft', 'Firm']))],
      );
      await openSheet(tester, proposal);

      expect(find.text("Only one option can be picked now: 'Soft' + 'Firm'"), findsWidgets);
      expect(find.text("Replace 'Soft' + 'Firm' with"), findsOneWidget);
      await openDropdown(tester);
      expect(find.text('No value'), findsWidgets);
    });
  });

  testWidgets('says when it replaces an earlier confirmed change', (tester) async {
    await openSheet(tester, _rangeProposal(), replacesEarlier: true);
    expect(find.textContaining('This replaces the change you confirmed earlier.'), findsOneWidget);
  });

  testWidgets('a first change does not mention an earlier one', (tester) async {
    await openSheet(tester, _rangeProposal());
    expect(find.textContaining('replaces'), findsNothing);
  });

  testWidgets('a renamed option deleted later is shown by its newer name', (tester) async {
    final renamed = MigrationProposal.build(
      before: _categorical({'A', 'X'}),
      after: _categorical({'B', 'X'}),
      optionOrigins: const {'B': 'A', 'X': 'X'},
      recorded: [_record(CategoricalValue(const ['A']))],
    );
    await openSheet(tester, renamed.rebuild(after: _categorical({'X'}), pageOrigins: const {'X': 'X'}));

    expect(find.text("'B' was deleted"), findsNWidgets(2));
    expect(find.text("'B' becomes 'X' in 1 setup."), findsOneWidget);
  });

  testWidgets('a deleted text another row was renamed to says the values merge', (tester) async {
    final proposal = MigrationProposal.build(
      before: _categorical({'A', 'B'}),
      after: _categorical({'A'}),
      optionOrigins: const {'A': 'B'},
      recorded: [_record(CategoricalValue(const ['A'])), _record(CategoricalValue(const ['B']))],
    );
    await openSheet(tester, proposal);

    expect(find.text("1 setup keeps 'A', now the option renamed from 'B'."), findsOneWidget);
  });

  testWidgets('long names render without overflow at 320 px', (tester) async {
    const longName = 'A very long adjustment name that keeps going and going well past the edge of the screen';
    final proposal = MigrationProposal.build(
      before: _categorical({'Option one', 'Option two', longName}),
      after: _categorical({'Option one', 'Option two'}),
      optionOrigins: const {'Option one': 'Option one', 'Option two': 'Option two'},
      recorded: [
        _record(CategoricalValue(const [longName]), label: longName),
        _record(CategoricalValue(const [longName]), label: longName, deleted: true),
      ],
    );
    await openSheet(tester, proposal, adjustmentName: longName, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
  });

  for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('renders in the $name theme', (tester) async {
      await openSheet(tester, _rangeProposal(), theme: theme);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('value-migration-confirm')), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
