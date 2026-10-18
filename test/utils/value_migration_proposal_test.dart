import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:flutter_test/flutter_test.dart';

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
const _bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');
const _kpa = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'kiloPascal');

int _counter = 0;

RecordedValue _record(AdjustmentValue value, {bool deleted = false, DateTime? day, String? label}) {
  final id = 'r${_counter++}';
  return RecordedValue(
    recordId: id,
    source: RecordedValueSource.setup,
    label: label ?? id,
    dateTimeLocal: day ?? DateTime(2024),
    value: value,
    isDeleted: deleted,
  );
}

NumericalAdjustment _numerical({AdjustmentUnit? unit, double? min, double? max}) =>
    NumericalAdjustment(id: 'a', name: 'A', notes: null, unit: unit, min: min, max: max);

StepAdjustment _step({int min = 0, int max = 10, int step = 1}) => StepAdjustment(
  id: 'a',
  name: 'A',
  notes: null,
  unit: null,
  min: min,
  max: max,
  step: step,
  visualization: StepAdjustmentVisualization.slider,
);

CategoricalAdjustment _categorical(Set<String> options, {bool multiSelect = false, bool counted = false}) =>
    CategoricalAdjustment(
      id: 'a',
      name: 'A',
      notes: null,
      unit: null,
      options: options,
      multiSelect: multiSelect,
      counted: counted,
    );

CategoricalValue _cat(List<String> options) => CategoricalValue(options);

MigrationIssue _issue(MigrationProposal proposal, MigrationIssueKind kind) =>
    proposal.issues.singleWhere((i) => i.kind == kind);

void main() {
  group('no recorded values', () {
    test('a unit change gives an empty proposal', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: const [],
      );
      expect(proposal.isEmpty, isTrue);
      expect(proposal.toMigration().isNoOp, isTrue);
    });

    test('a categorical edit gives an empty proposal', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'C'}),
        optionOrigins: const {'C': 'A'},
        recorded: const [],
      );
      expect(proposal.isEmpty, isTrue);
    });
  });

  group('numerical', () {
    test('a narrowed range where every value still fits gives an empty proposal', () {
      final proposal = MigrationProposal.build(
        before: _numerical(max: 100),
        after: _numerical(max: 50),
        recorded: [_record(const NumericalValue(10)), _record(const NumericalValue(50))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('a narrowed range offers clamp or clear for the values outside it', () {
      final inside = _record(const NumericalValue(10));
      final outside = _record(const NumericalValue(80));
      final proposal = MigrationProposal.build(
        before: _numerical(max: 100),
        after: _numerical(max: 50),
        recorded: [inside, outside],
      );

      final issue = _issue(proposal, MigrationIssueKind.outOfRange);
      expect(issue.records, [outside]);
      expect(issue.choices, [MigrationChoice.clamp, MigrationChoice.clear]);
      expect(issue.choice, MigrationChoice.clamp);
      expect(issue.exampleBefore, const NumericalValue(80));
      expect(issue.exampleAfter, const NumericalValue(50));
      expect(proposal.toMigration().apply(const NumericalValue(80)), const NumericalValue(50));
    });

    test('clear removes the values outside the range and keeps the others', () {
      final proposal = MigrationProposal.build(
        before: _numerical(max: 100),
        after: _numerical(max: 50),
        recorded: [_record(const NumericalValue(80))],
        choices: const {'range': MigrationChoice.clear},
      );
      final issue = _issue(proposal, MigrationIssueKind.outOfRange);

      expect(issue.exampleAfter, isNull);
      final migration = proposal.toMigration();
      expect(migration.apply(const NumericalValue(80)), isNull);
      expect(migration.apply(const NumericalValue(10)), const NumericalValue(10));
    });

    test('a range that did not change is not checked', () {
      final proposal = MigrationProposal.build(
        before: _numerical(max: 50),
        after: _numerical(max: 50),
        recorded: [_record(const NumericalValue(80))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('a compatible unit change offers convert or keep and defaults to convert', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: [_record(const NumericalValue(10))],
      );

      final issue = _issue(proposal, MigrationIssueKind.unitConversion);
      expect(issue.choices, [MigrationChoice.convert, MigrationChoice.keep]);
      expect(issue.choice, MigrationChoice.convert);
      expect((issue.exampleAfter! as NumericalValue).value, closeTo(0.689476, 1e-5));
      expect(proposal.toMigration().steps, [const ConvertUnitStep(_psi, _bar)]);
    });

    test('keep leaves the numbers and adds no step', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: [_record(const NumericalValue(10))],
        choices: const {'unit': MigrationChoice.keep},
      );

      expect(_issue(proposal, MigrationIssueKind.unitConversion).exampleAfter, const NumericalValue(10));
      expect(proposal.toMigration().isNoOp, isTrue);
    });

    test('an incompatible unit offers keep or clear and defaults to keep', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: const CustomUnit('clicks')),
        recorded: [_record(const NumericalValue(10))],
      );

      final issue = _issue(proposal, MigrationIssueKind.incompatibleUnit);
      expect(issue.choices, [MigrationChoice.keep, MigrationChoice.clear]);
      expect(issue.choice, MigrationChoice.keep);
      expect(proposal.toMigration().isNoOp, isTrue);
    });

    test('an incompatible unit cleared removes every value', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: const CustomUnit('clicks')),
        recorded: [_record(const NumericalValue(10)), _record(const NumericalValue(20), deleted: true)],
        choices: const {'unit': MigrationChoice.clear},
      );

      final issue = _issue(proposal, MigrationIssueKind.incompatibleUnit);
      expect(issue.exampleAfter, isNull);
      expect(proposal.toMigration().apply(const NumericalValue(10)), isNull);
    });

    test('convert followed by out-of-range differs from keep followed by in-range', () {
      NumericalAdjustment before() => _numerical(unit: _psi);
      NumericalAdjustment after() => _numerical(unit: _bar, max: 2);
      final recorded = [_record(const NumericalValue(10))];

      final converted = MigrationProposal.build(before: before(), after: after(), recorded: recorded);
      expect(converted.issues.map((i) => i.kind), [MigrationIssueKind.unitConversion]);

      final kept = MigrationProposal.build(
        before: before(),
        after: after(),
        recorded: recorded,
        choices: const {'unit': MigrationChoice.keep},
      );
      expect(kept.issues.map((i) => i.kind), [MigrationIssueKind.unitConversion, MigrationIssueKind.outOfRange]);
      expect(_issue(kept, MigrationIssueKind.outOfRange).exampleAfter, const NumericalValue(2));
    });

    test('withChoice rebuilds the later issues from the values the choice leaves', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar, max: 2),
        recorded: [_record(const NumericalValue(10))],
      );
      expect(proposal.issues, hasLength(1));

      final rebuilt = proposal.withChoice('unit', MigrationChoice.keep);
      expect(rebuilt.issues, hasLength(2));
      expect(rebuilt.toMigration().steps, [ClampToRangeStep(_numerical(unit: _bar, max: 2).range)]);
    });

    test('a choice that is not offered falls back to the default', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: [_record(const NumericalValue(10))],
        choices: const {'unit': MigrationChoice.clamp},
      );
      expect(_issue(proposal, MigrationIssueKind.unitConversion).choice, MigrationChoice.convert);
    });

  });

  group('step and duration', () {
    test('a step change that puts values off the grid offers snap', () {
      final off = _record(const StepValue(3));
      final on = _record(const StepValue(4));
      final proposal = MigrationProposal.build(
        before: _step(),
        after: _step(step: 2),
        recorded: [off, on],
      );

      final issue = _issue(proposal, MigrationIssueKind.outOfRange);
      expect(issue.records, [off]);
      expect(issue.exampleAfter, const StepValue(4));
    });

    test('values still on the grid give an empty proposal', () {
      final proposal = MigrationProposal.build(
        before: _step(),
        after: _step(step: 2),
        recorded: [_record(const StepValue(4)), _record(const StepValue(6))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('a narrowed step range snaps to the new maximum', () {
      final proposal = MigrationProposal.build(
        before: _step(),
        after: _step(max: 6),
        recorded: [_record(const StepValue(9))],
      );
      expect(_issue(proposal, MigrationIssueKind.outOfRange).exampleAfter, const StepValue(6));
    });

    test('a lowered duration maximum offers clamp', () {
      DurationAdjustment duration(Duration? max) =>
          DurationAdjustment(id: 'a', name: 'A', notes: null, unit: null, min: null, max: max);
      final proposal = MigrationProposal.build(
        before: duration(const Duration(minutes: 10)),
        after: duration(const Duration(minutes: 5)),
        recorded: [_record(const DurationValue(Duration(minutes: 8)))],
      );

      expect(
        _issue(proposal, MigrationIssueKind.outOfRange).exampleAfter,
        const DurationValue(Duration(minutes: 5)),
      );
    });
  });

  group('categorical', () {
    test('a rename is an automatic row listing the records that hold the option', () {
      final holder = _record(_cat(['A']));
      final other = _record(_cat(['B']));
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'A2', 'B'}),
        optionOrigins: const {'A2': 'A', 'B': 'B'},
        recorded: [holder, other],
      );

      final issue = _issue(proposal, MigrationIssueKind.renamedOptions);
      expect(issue.isAutomatic, isTrue);
      expect(issue.records, [holder]);
      expect(issue.exampleAfter, _cat(['A2']));
      expect(proposal.toMigration().apply(_cat(['A'])), _cat(['A2']));
      expect(proposal.toMigration().apply(_cat(['B'])), _cat(['B']));
    });

    test('a rename without a record holding the option gives an empty proposal', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'A2', 'B'}),
        optionOrigins: const {'A2': 'A', 'B': 'B'},
        recorded: [_record(_cat(['B']))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('swapping two options maps both ways at once', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'B', 'A'}),
        optionOrigins: const {'B': 'A', 'A': 'B'},
        recorded: [_record(_cat(['A'])), _record(_cat(['B']))],
      );

      final migration = proposal.toMigration();
      expect(migration.apply(_cat(['A'])), _cat(['B']));
      expect(migration.apply(_cat(['B'])), _cat(['A']));
    });

    test('a deleted option offers the remaining options and clear, defaulting to the first', () {
      final holder = _record(_cat(['C']));
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B', 'C'}),
        after: _categorical({'A', 'B'}),
        optionOrigins: const {'A': 'A', 'B': 'B'},
        recorded: [holder],
      );

      final issue = _issue(proposal, MigrationIssueKind.deletedOption);
      expect(issue.options, ['C']);
      expect(issue.records, [holder]);
      expect(issue.choices, [const MigrationChoice.mapTo('A'), const MigrationChoice.mapTo('B'), MigrationChoice.clear]);
      expect(issue.choice, const MigrationChoice.mapTo('A'));
      expect(proposal.toMigration().apply(_cat(['C'])), _cat(['A']));
    });

    test('a deleted option mapped to another option', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B', 'C'}),
        after: _categorical({'A', 'B'}),
        optionOrigins: const {'A': 'A', 'B': 'B'},
        recorded: [_record(_cat(['C']))],
        choices: const {'delete:C': MigrationChoice.mapTo('B')},
      );
      expect(proposal.toMigration().apply(_cat(['C'])), _cat(['B']));
    });

    test('a deleted option cleared removes the row', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'C'}),
        after: _categorical({'A'}),
        optionOrigins: const {'A': 'A'},
        recorded: [_record(_cat(['C']))],
        choices: const {'delete:C': MigrationChoice.clear},
      );

      expect(_issue(proposal, MigrationIssueKind.deletedOption).exampleAfter, isNull);
      expect(proposal.toMigration().apply(_cat(['C'])), isNull);
    });

    test('deleting an option that no record holds gives an empty proposal', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'C'}),
        after: _categorical({'A'}),
        optionOrigins: const {'A': 'A'},
        recorded: [_record(_cat(['A']))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('a removed row re-added with the same text keeps its values', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'B', 'A'}),
        optionOrigins: const {'B': 'B', 'A': null},
        recorded: [_record(_cat(['A']))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('turning counted off removes duplicates automatically', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'Spacer'}, multiSelect: true, counted: true),
        after: _categorical({'Spacer'}, multiSelect: true),
        recorded: [_record(_cat(['Spacer', 'Spacer', 'Spacer'])), _record(_cat(['Spacer']))],
      );

      final issue = _issue(proposal, MigrationIssueKind.duplicateOptions);
      expect(issue.isAutomatic, isTrue);
      expect(issue.records, hasLength(1));
      expect(issue.exampleAfter, _cat(['Spacer']));
      expect(proposal.toMigration().apply(_cat(['Spacer', 'Spacer'])), _cat(['Spacer']));
    });

    test('a deletion that merges into a selected option removes the duplicate when not counted', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}, multiSelect: true),
        after: _categorical({'A'}, multiSelect: true),
        optionOrigins: const {'A': 'A'},
        recorded: [_record(_cat(['A', 'B']))],
      );

      expect(proposal.issues.map((i) => i.kind), [
        MigrationIssueKind.deletedOption,
        MigrationIssueKind.duplicateOptions,
      ]);
      expect(proposal.toMigration().apply(_cat(['A', 'B'])), _cat(['A']));
    });

    test('turning multi-select off gives one issue per distinct combination', () {
      final softFirm = _record(_cat(['Soft', 'Firm']));
      final softFirmAgain = _record(_cat(['Firm', 'Soft']));
      final all = _record(_cat(['Soft', 'Medium', 'Firm']));
      final single = _record(_cat(['Soft']));
      final proposal = MigrationProposal.build(
        before: _categorical({'Soft', 'Medium', 'Firm'}, multiSelect: true),
        after: _categorical({'Soft', 'Medium', 'Firm'}),
        recorded: [softFirm, softFirmAgain, all, single],
      );

      final combinations = proposal.issues.where((i) => i.kind == MigrationIssueKind.combination).toList();
      expect(combinations, hasLength(2));
      final pair = combinations.firstWhere((i) => i.options.length == 2);
      expect(pair.records, containsAll([softFirm, softFirmAgain]));
      expect(pair.choice, MigrationChoice.mapTo(pair.options.first));
      expect(pair.choices.last, MigrationChoice.clear);
      expect(proposal.toMigration().apply(_cat(['Soft', 'Firm'])), _cat([pair.options.first]));
      expect(proposal.toMigration().apply(_cat(['Soft'])), _cat(['Soft']));
    });

    test('a combination mapped to another option or cleared', () {
      final base = MigrationProposal.build(
        before: _categorical({'Soft', 'Firm'}, multiSelect: true),
        after: _categorical({'Soft', 'Firm'}),
        recorded: [_record(_cat(['Soft', 'Firm']))],
      );
      final key = base.issues.single.key;

      expect(
        base.withChoice(key, const MigrationChoice.mapTo('Firm')).toMigration().apply(_cat(['Soft', 'Firm'])),
        _cat(['Firm']),
      );
      expect(base.withChoice(key, MigrationChoice.clear).toMigration().apply(_cat(['Soft', 'Firm'])), isNull);
    });

    test('a counted single-select keeps repeats of one option', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'Spacer'}, multiSelect: true, counted: true),
        after: _categorical({'Spacer'}, counted: true),
        recorded: [_record(_cat(['Spacer', 'Spacer']))],
      );
      expect(proposal.isEmpty, isTrue);
    });

    test('mapping an option, then clearing the selection it empties, drops the record from later issues', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}, multiSelect: true, counted: true),
        after: _categorical({'A'}, multiSelect: true),
        optionOrigins: const {'A': 'A'},
        recorded: [_record(_cat(['B', 'B']))],
        choices: const {'delete:B': MigrationChoice.clear},
      );

      expect(proposal.issues.map((i) => i.kind), [MigrationIssueKind.deletedOption]);
    });
  });

  group('deleted text reused by a renamed row', () {
    test('the saved option counts as deleted and merges into that row by default', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'A'}),
        optionOrigins: const {'A': 'B'},
        recorded: [_record(_cat(['A'])), _record(_cat(['B']))],
      );

      final deleted = _issue(proposal, MigrationIssueKind.deletedOption);
      expect(deleted.options, ['A']);
      expect(deleted.choice, const MigrationChoice.mapTo('A'));
      expect(proposal.toMigration().apply(_cat(['A'])), _cat(['A']));
      expect(proposal.toMigration().apply(_cat(['B'])), _cat(['A']));
    });

    test('the merge can be cleared instead', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B'}),
        after: _categorical({'A'}),
        optionOrigins: const {'A': 'B'},
        recorded: [_record(_cat(['A'])), _record(_cat(['B']))],
      ).withChoice('delete:A', MigrationChoice.clear);

      expect(proposal.toMigration().apply(_cat(['A'])), isNull);
      expect(proposal.toMigration().apply(_cat(['B'])), _cat(['A']));
      expect(proposal.clearsValues, isTrue);
    });
  });

  group('rebuild', () {
    test('a narrowed range widened again clamps to the newest maximum', () {
      final first = MigrationProposal.build(
        before: _numerical(max: 20),
        after: _numerical(max: 10),
        recorded: [_record(const NumericalValue(20))],
      );
      final second = first.rebuild(after: _numerical(max: 15));

      expect(second.toMigration().steps, [const ClampToRangeStep(NumericalRange(double.negativeInfinity, 15))]);
      expect(second.toMigration().apply(const NumericalValue(20)), const NumericalValue(15));
      expect(second.previews.single.values, [const NumericalValue(20), const NumericalValue(15)]);
    });

    test('a rebuild back to the saved definition is empty', () {
      final first = MigrationProposal.build(
        before: _numerical(max: 20),
        after: _numerical(max: 10),
        recorded: [_record(const NumericalValue(20))],
      );
      expect(first.rebuild(after: _numerical(max: 20)).isEmpty, isTrue);
    });

    test('multi-select or counted turned off and on again is empty', () {
      final multi = MigrationProposal.build(
        before: _categorical({'A', 'B'}, multiSelect: true),
        after: _categorical({'A', 'B'}),
        recorded: [_record(_cat(['A', 'B']))],
      );
      expect(multi.isEmpty, isFalse);
      expect(multi.rebuild(after: _categorical({'A', 'B'}, multiSelect: true)).isEmpty, isTrue);

      final counted = MigrationProposal.build(
        before: _categorical({'A'}, counted: true),
        after: _categorical({'A'}),
        recorded: [_record(_cat(['A', 'A']))],
      );
      expect(counted.isEmpty, isFalse);
      expect(counted.rebuild(after: _categorical({'A'}, counted: true)).isEmpty, isTrue);
    });

    test('a deleted option re-added as a new row is empty', () {
      final first = MigrationProposal.build(
        before: _categorical({'A', 'C'}),
        after: _categorical({'A'}),
        recorded: [_record(_cat(['C']))],
      );
      final second = first.rebuild(after: _categorical({'A', 'C'}), pageOrigins: const {'A': 'A', 'C': null});
      expect(second.isEmpty, isTrue);
    });

    test('rename A to B, then B to C, renames A to C', () {
      final first = MigrationProposal.build(
        before: _categorical({'A'}),
        after: _categorical({'B'}),
        optionOrigins: const {'B': 'A'},
        recorded: [_record(_cat(['A']))],
      );
      final second = first.rebuild(after: _categorical({'C'}), pageOrigins: const {'C': 'B'});

      expect(second.optionOrigins, {'C': 'A'});
      expect(second.toMigration().apply(_cat(['A'])), _cat(['C']));
      expect(_issue(second, MigrationIssueKind.renamedOptions).exampleBefore, _cat(['A']));
    });

    test('a renamed option deleted later is shown by its newer name', () {
      final first = MigrationProposal.build(
        before: _categorical({'A', 'X'}),
        after: _categorical({'B', 'X'}),
        optionOrigins: const {'B': 'A', 'X': 'X'},
        recorded: [_record(_cat(['A']))],
      );
      final second = first.rebuild(after: _categorical({'X'}), pageOrigins: const {'X': 'X'});

      final deleted = _issue(second, MigrationIssueKind.deletedOption);
      expect(deleted.options, ['A']);
      expect(second.optionLabel('A'), 'B');
      expect(second.toMigration().apply(_cat(['A'])), _cat(['X']));
    });

    test('a label goes away when the option gets its saved name back', () {
      final first = MigrationProposal.build(
        before: _categorical({'A', 'X'}),
        after: _categorical({'B', 'X'}),
        optionOrigins: const {'B': 'A'},
        recorded: [_record(_cat(['A']))],
      );
      final renamedBack = first.rebuild(after: _categorical({'A', 'X'}), pageOrigins: const {'A': 'B'});
      expect(renamedBack.isEmpty, isTrue);
      final deleted = renamedBack.rebuild(after: _categorical({'X'}));
      expect(deleted.optionLabel('A'), 'A');
    });

    test('psi to bar to kPa is one conversion, and back to psi is empty', () {
      final first = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: [_record(const NumericalValue(10))],
      );
      expect(first.rebuild(after: _numerical(unit: _kpa)).toMigration().steps, [const ConvertUnitStep(_psi, _kpa)]);
      expect(first.rebuild(after: _numerical(unit: _psi)).isEmpty, isTrue);
    });

    test('a conversion rebuilt with a lower maximum checks the converted values', () {
      final first = MigrationProposal.build(
        before: _numerical(unit: _psi, max: 100),
        after: _numerical(unit: _bar, max: 100),
        recorded: [_record(const NumericalValue(10))],
      );
      // 10 psi is 0.69 bar, which still fits.
      expect(first.rebuild(after: _numerical(unit: _bar, max: 1)).issues.map((i) => i.kind), [
        MigrationIssueKind.unitConversion,
      ]);
    });

    test('an earlier choice is kept', () {
      final first = MigrationProposal.build(
        before: _numerical(max: 20),
        after: _numerical(max: 10),
        recorded: [_record(const NumericalValue(20))],
      ).withChoice('range', MigrationChoice.clear);
      final second = first.rebuild(after: _numerical(max: 15));

      expect(second.issues.single.choice, MigrationChoice.clear);
      expect(second.toMigration().apply(const NumericalValue(20)), isNull);
    });

    test('an earlier target that was deleted since falls back to the default', () {
      final first = MigrationProposal.build(
        before: _categorical({'A', 'B', 'C'}),
        after: _categorical({'A', 'B'}),
        recorded: [_record(_cat(['C']))],
      ).withChoice('delete:C', const MigrationChoice.mapTo('B'));
      final second = first.rebuild(after: _categorical({'A'}));

      expect(second.issues.firstWhere((i) => i.key == 'delete:C').choice, const MigrationChoice.mapTo('A'));
    });

    test('defaults to the stored records and accepts fresh ones', () {
      final first = MigrationProposal.build(
        before: _numerical(max: 20),
        after: _numerical(max: 10),
        recorded: [_record(const NumericalValue(20))],
      );
      expect(first.rebuild(after: _numerical(max: 5)).recorded, first.recorded);
      expect(first.rebuild(after: _numerical(max: 5), recorded: const []).isEmpty, isTrue);
    });
  });

  group('summary', () {
    test('counts distinct records across issues, live and deleted apart', () {
      final shared = _record(_cat(['A', 'C']));
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B', 'C'}, multiSelect: true),
        after: _categorical({'X', 'B'}),
        optionOrigins: const {'X': 'A', 'B': 'B'},
        recorded: [shared, _record(_cat(['B', 'C']), deleted: true), _record(_cat(['B']))],
      );

      expect(proposal.affected.live, 1);
      expect(proposal.affected.deleted, 1);
      expect(proposal.clearsValues, isFalse);
    });
  });

  group('invariant', () {
    // Each edit with values it might affect; after the migration every value
    // the edit touched is cleared or valid for the new definition.
    final cases = <String, (Adjustment, Adjustment, Map<String, String?>, List<AdjustmentValue>)>{
      'narrowed range': (
        _numerical(min: -10, max: 100),
        _numerical(min: 0, max: 50),
        const {},
        const [NumericalValue(-10), NumericalValue(75), NumericalValue(20)],
      ),
      'unit and range': (
        _numerical(unit: _psi, max: 1000),
        _numerical(unit: _bar, max: 5),
        const {},
        const [NumericalValue(10), NumericalValue(300)],
      ),
      'step grid': (_step(max: 20), _step(min: 2, max: 12, step: 5), const {}, const [StepValue(0), StepValue(9), StepValue(20)]),
      'options': (
        _categorical({'A', 'B', 'C'}, multiSelect: true, counted: true),
        _categorical({'X', 'B'}),
        const {'X': 'A', 'B': 'B'},
        [_cat(['A', 'A']), _cat(['A', 'C']), _cat(['B', 'C']), _cat(['C'])],
      ),
    };

    for (final MapEntry(key: name, value: (before, after, origins, values)) in cases.entries) {
      for (final clear in [false, true]) {
        test('$name${clear ? ' with every choice cleared' : ''}', () {
          var proposal = MigrationProposal.build(
            before: before,
            after: after,
            optionOrigins: origins,
            recorded: [for (final value in values) _record(value)],
          );
          if (clear) {
            for (final issue in proposal.issues) {
              if (issue.choices.contains(MigrationChoice.clear)) {
                proposal = proposal.withChoice(issue.key, MigrationChoice.clear);
              }
            }
          }
          final migration = proposal.toMigration();
          for (final value in values) {
            final migrated = migration.apply(value);
            expect(migrated == null || after.isValidValue(migrated), isTrue, reason: '$value -> $migrated');
          }
        });
      }
    }
  });

  group('records', () {
    test('live and deleted records are kept apart', () {
      final live = _record(const NumericalValue(80));
      final deleted = _record(const NumericalValue(90), deleted: true);
      final proposal = MigrationProposal.build(
        before: _numerical(),
        after: _numerical(max: 50),
        recorded: [live, deleted],
      );

      final issue = _issue(proposal, MigrationIssueKind.outOfRange);
      expect(issue.liveRecords, [live]);
      expect(issue.deletedRecords, [deleted]);
    });

    test('the example is the newest live record', () {
      final older = _record(const NumericalValue(80), day: DateTime(2023));
      final newest = _record(const NumericalValue(70), day: DateTime(2024));
      final deletedNewer = _record(const NumericalValue(90), deleted: true, day: DateTime(2025));
      final proposal = MigrationProposal.build(
        before: _numerical(),
        after: _numerical(max: 50),
        recorded: [older, deletedNewer, newest],
      );

      expect(_issue(proposal, MigrationIssueKind.outOfRange).example, newest);
    });

    test('the example is the newest deleted record without a live one', () {
      final older = _record(const NumericalValue(80), deleted: true, day: DateTime(2023));
      final newer = _record(const NumericalValue(70), deleted: true, day: DateTime(2024));
      final proposal = MigrationProposal.build(
        before: _numerical(),
        after: _numerical(max: 50),
        recorded: [older, newer],
      );

      expect(_issue(proposal, MigrationIssueKind.outOfRange).example, newer);
    });
  });

  group('mayAffectValues', () {
    bool may(Adjustment before, Adjustment after, {Map<String, String?> optionOrigins = const {}}) =>
        MigrationProposal.mayAffectValues(before: before, after: after, optionOrigins: optionOrigins);

    test('is false for an edit that leaves the definition alone', () {
      expect(may(_numerical(unit: _psi, max: 10), _numerical(unit: _psi, max: 10)), isFalse);
      expect(may(_step(), _step()), isFalse);
      expect(may(_categorical({'A'}), _categorical({'A'}), optionOrigins: const {'A': 'A'}), isFalse);
    });

    test('is true for a changed unit or range', () {
      expect(may(_numerical(unit: _psi), _numerical(unit: _bar)), isTrue);
      expect(may(_numerical(max: 10), _numerical(max: 5)), isTrue);
      expect(may(_step(), _step(step: 2)), isTrue);
      expect(may(_step(), _step(max: 5)), isTrue);
    });

    test('is true for a renamed, deleted or swapped option', () {
      expect(may(_categorical({'A'}), _categorical({'B'}), optionOrigins: const {'B': 'A'}), isTrue);
      expect(may(_categorical({'A', 'B'}), _categorical({'A'}), optionOrigins: const {'A': 'A'}), isTrue);
      expect(may(_categorical({'A', 'B'}), _categorical({'B', 'A'}), optionOrigins: const {'B': 'A', 'A': 'B'}), isTrue);
    });

    test('is false for an added option', () {
      expect(
        may(_categorical({'A'}), _categorical({'A', 'B'}), optionOrigins: const {'A': 'A', 'B': null}),
        isFalse,
      );
    });

    test('is true only for counted or multi-select turned off', () {
      expect(may(_categorical({'A'}, counted: true), _categorical({'A'})), isTrue);
      expect(may(_categorical({'A'}, multiSelect: true), _categorical({'A'})), isTrue);
      expect(may(_categorical({'A'}), _categorical({'A'}, multiSelect: true, counted: true)), isFalse);
    });

    test('is false for types without a range', () {
      final boolean = BooleanAdjustment(id: 'a', name: 'A', notes: null, unit: null);
      expect(may(boolean, boolean.copyWith(name: 'B')), isFalse);
    });
  });

  group('previews', () {
    test('a numerical edit gives one chain through every issue', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _bar, max: 100),
        after: _numerical(unit: _psi, max: 10),
        recorded: [_record(const NumericalValue(5.8))],
      );

      expect(proposal.issues.map((i) => i.kind), [MigrationIssueKind.unitConversion, MigrationIssueKind.outOfRange]);
      final preview = proposal.previews.single;
      expect(preview.issueKeys, ['unit', 'range']);
      expect(preview.values.first, const NumericalValue(5.8));
      expect((preview.values[1]! as NumericalValue).value, closeTo(84.1, 0.1));
      expect(preview.values.last, const NumericalValue(10));
    });

    test('a value the migration leaves alone does not illustrate it', () {
      final zero = _record(const NumericalValue(0));
      final ten = _record(const NumericalValue(10));
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: [zero, zero, zero, ten],
      );

      expect(proposal.previews.single.values.first, const NumericalValue(10));
      expect(_issue(proposal, MigrationIssueKind.unitConversion).exampleBefore, const NumericalValue(10));
    });

    test('with several changed values the most common one is the example', () {
      final proposal = MigrationProposal.build(
        before: _numerical(max: 100),
        after: _numerical(max: 50),
        recorded: [
          _record(const NumericalValue(80), day: DateTime(2025)),
          _record(const NumericalValue(90), day: DateTime(2023)),
          _record(const NumericalValue(90), day: DateTime(2022)),
        ],
      );

      expect(_issue(proposal, MigrationIssueKind.outOfRange).exampleBefore, const NumericalValue(90));
      expect(proposal.previews.single.values.first, const NumericalValue(90));
    });

    test('a chain prefers the value that more issues change', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi, max: 100),
        after: _numerical(unit: _bar, max: 1),
        // 10 psi is 0.69 bar and fits; 30 psi is 2.07 bar and is clamped as well.
        recorded: [_record(const NumericalValue(10)), _record(const NumericalValue(10)), _record(const NumericalValue(30))],
      );

      expect(proposal.previews.single.values.first, const NumericalValue(30));
      expect(proposal.previews.single.values.last, const NumericalValue(1));
    });

    test('keeping the numbers still shows the relabelling', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi),
        after: _numerical(unit: _bar),
        recorded: [_record(const NumericalValue(10))],
        choices: const {'unit': MigrationChoice.keep},
      );
      expect(proposal.previews.single.values, const [NumericalValue(10), NumericalValue(10)]);
    });

    test('a cleared value ends the chain with null', () {
      final proposal = MigrationProposal.build(
        before: _numerical(unit: _psi, max: 100),
        after: _numerical(unit: _bar, max: 1),
        recorded: [_record(const NumericalValue(30))],
        choices: const {'range': MigrationChoice.clear},
      );
      expect(proposal.previews.single.values.last, isNull);
    });

    test('a categorical edit gives one before / after pair per issue', () {
      final proposal = MigrationProposal.build(
        before: _categorical({'A', 'B', 'C'}),
        after: _categorical({'A2', 'B'}),
        optionOrigins: const {'A2': 'A', 'B': 'B'},
        recorded: [_record(_cat(['A'])), _record(_cat(['C']))],
      );

      expect(proposal.previews.map((p) => p.issueKeys), [
        ['rename'],
        ['delete:C'],
      ]);
      expect(proposal.previews[0].values, [_cat(['A']), _cat(['A2'])]);
      expect(proposal.previews[1].values, [_cat(['C']), _cat(['A2'])]);
    });

    test('an empty proposal has no previews', () {
      final proposal = MigrationProposal.build(before: _numerical(), after: _numerical(max: 5), recorded: const []);
      expect(proposal.previews, isEmpty);
    });
  });
}
