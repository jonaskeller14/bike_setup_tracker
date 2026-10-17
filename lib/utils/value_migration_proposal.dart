import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/adjustment/adjustment.dart';
import '../models/recorded_value.dart';

enum MigrationIssueKind {
  unitConversion,
  incompatibleUnit,
  renamedOptions,
  deletedOption,
  duplicateOptions,
  combination,
  outOfRange,
}

enum MigrationChoiceKind { automatic, convert, keep, clamp, clear, mapTo }

/// What the user can pick for a [MigrationIssue]. [clamp] also stands for
/// snapping a step value to its grid.
@immutable
class MigrationChoice {
  final MigrationChoiceKind kind;

  /// The option a [MigrationChoiceKind.mapTo] choice maps to.
  final String? option;

  const MigrationChoice._(this.kind) : option = null;

  static const automatic = MigrationChoice._(MigrationChoiceKind.automatic);
  static const convert = MigrationChoice._(MigrationChoiceKind.convert);
  static const keep = MigrationChoice._(MigrationChoiceKind.keep);
  static const clamp = MigrationChoice._(MigrationChoiceKind.clamp);
  static const clear = MigrationChoice._(MigrationChoiceKind.clear);

  const MigrationChoice.mapTo(String this.option) : kind = MigrationChoiceKind.mapTo;

  @override
  bool operator ==(Object other) => other is MigrationChoice && other.kind == kind && other.option == option;

  @override
  int get hashCode => Object.hash(kind, option);

  @override
  String toString() => option == null ? 'MigrationChoice(${kind.name})' : 'MigrationChoice(${kind.name} $option)';
}

/// One kind of recorded value an edit leaves outdated, with the records it
/// touches, the choices offered and a real example for the preview.
@immutable
class MigrationIssue {
  /// Stable across rebuilds, so a choice made for it survives a rebuild.
  final String key;
  final MigrationIssueKind kind;

  /// The deleted option, or the options of the combination, in selection order.
  final List<String> options;
  final List<RecordedValue> liveRecords;
  final List<RecordedValue> deletedRecords;

  /// A single [MigrationChoice.automatic] for issues without a decision.
  final List<MigrationChoice> choices;
  final MigrationChoice choice;

  /// The newest live affected record, or the newest deleted one without any.
  final RecordedValue example;

  /// The example's value as this issue sees it, after the earlier issues' choices.
  final AdjustmentValue exampleBefore;

  /// The example's value under [choice]; `null` when it is cleared.
  final AdjustmentValue? exampleAfter;

  const MigrationIssue({
    required this.key,
    required this.kind,
    required this.options,
    required this.liveRecords,
    required this.deletedRecords,
    required this.choices,
    required this.choice,
    required this.example,
    required this.exampleBefore,
    required this.exampleAfter,
  });

  bool get isAutomatic => choice == MigrationChoice.automatic;
  List<RecordedValue> get records => [...liveRecords, ...deletedRecords];
}

/// What saving an edited adjustment or metric would do to its recorded values,
/// and the choices that decide it. Empty when no recorded value is affected.
@immutable
class MigrationProposal {
  /// The definition the edit page opened with.
  final Adjustment before;
  final Adjustment after;

  /// Each new option text mapped to the text its row started with; `null` for
  /// an added row. An option without an entry counts as unchanged.
  final Map<String, String?> optionOrigins;

  /// Every recorded value of the adjustment, as stored.
  final List<RecordedValue> recorded;

  /// The migration an earlier edit of the parent form still has pending.
  final ValueMigration? staged;
  final Map<String, MigrationChoice> choices;
  final List<MigrationIssue> issues;
  final List<ValueMigrationStep> steps;

  const MigrationProposal._({
    required this.before,
    required this.after,
    required this.optionOrigins,
    required this.recorded,
    required this.staged,
    required this.choices,
    required this.issues,
    required this.steps,
  });

  /// [recorded] is run through [staged] first, as the values will be once the
  /// parent form is saved. A [choices] entry that does not fit its issue falls
  /// back to the issue's default.
  factory MigrationProposal.build({
    required Adjustment before,
    required Adjustment after,
    Map<String, String?> optionOrigins = const {},
    required List<RecordedValue> recorded,
    ValueMigration? staged,
    Map<String, MigrationChoice> choices = const {},
  }) {
    final builder = _ProposalBuilder(
      before: before,
      after: after,
      optionOrigins: optionOrigins,
      recorded: recorded,
      staged: staged,
      choices: choices,
    )..run();
    return MigrationProposal._(
      before: before,
      after: after,
      optionOrigins: optionOrigins,
      recorded: recorded,
      staged: staged,
      choices: choices,
      issues: List.unmodifiable(builder.issues),
      steps: List.unmodifiable(builder.steps),
    );
  }

  bool get isEmpty => issues.isEmpty;

  /// This proposal with [choice] picked for the issue [key], and every later
  /// issue worked out from the values that choice leaves.
  MigrationProposal withChoice(String key, MigrationChoice choice) => MigrationProposal.build(
    before: before,
    after: after,
    optionOrigins: optionOrigins,
    recorded: recorded,
    staged: staged,
    choices: {...choices, key: choice},
  );

  /// The migration for the current choices, without the [staged] one.
  ValueMigration toMigration() => ValueMigration(after.id, steps);
}

class _Entry {
  final RecordedValue record;
  final AdjustmentValue value;

  const _Entry(this.record, this.value);
}

class _ProposalBuilder {
  final Adjustment before;
  final Adjustment after;
  final Map<String, String?> optionOrigins;
  final List<RecordedValue> recorded;
  final ValueMigration? staged;
  final Map<String, MigrationChoice> choices;

  final issues = <MigrationIssue>[];
  final steps = <ValueMigrationStep>[];
  late List<_Entry> _entries;

  _ProposalBuilder({
    required this.before,
    required this.after,
    required this.optionOrigins,
    required this.recorded,
    required this.staged,
    required this.choices,
  });

  void run() {
    _entries = [
      for (final record in recorded)
        if (_afterStaged(record.value) case final value?) _Entry(record, value),
    ];
    switch ((before, after)) {
      case (final NumericalAdjustment before, final NumericalAdjustment after):
        final converted = _unit(before, after);
        if (converted || before.min != after.min || before.max != after.max) _range();
      case (final StepAdjustment before, final StepAdjustment after):
        if (before.min != after.min || before.max != after.max || before.step != after.step) _range();
      case (final DurationAdjustment before, final DurationAdjustment after):
        if (before.min != after.min || before.max != after.max) _range();
      case (final CategoricalAdjustment before, final CategoricalAdjustment after):
        _categorical(before, after);
      default:
        break;
    }
  }

  AdjustmentValue? _afterStaged(AdjustmentValue value) => staged == null ? value : staged!.apply(value);

  /// Whether a conversion changed the values.
  bool _unit(NumericalAdjustment before, NumericalAdjustment after) {
    if (before.unit == after.unit || _entries.isEmpty) return false;
    final from = before.unit;
    final to = after.unit;
    if (from is KnownUnit && to is KnownUnit && from.quantity == to.quantity) {
      final choice = _add(
        key: 'unit',
        kind: MigrationIssueKind.unitConversion,
        affected: _entries,
        allowed: const [MigrationChoice.convert, MigrationChoice.keep],
        fallback: MigrationChoice.convert,
        stepFor: (choice) => choice == MigrationChoice.convert ? ConvertUnitStep(from, to) : null,
      );
      return choice == MigrationChoice.convert;
    }
    _add(
      key: 'unit',
      kind: MigrationIssueKind.incompatibleUnit,
      affected: _entries,
      allowed: const [MigrationChoice.keep, MigrationChoice.clear],
      fallback: MigrationChoice.keep,
      stepFor: (choice) => choice == MigrationChoice.clear ? const ClearAllStep() : null,
    );
    return false;
  }

  void _range() {
    _add(
      key: 'range',
      kind: MigrationIssueKind.outOfRange,
      affected: _entries.where((e) => e.value.matches(after.type) && !after.isValidValue(e.value)).toList(),
      allowed: const [MigrationChoice.clamp, MigrationChoice.clear],
      fallback: MigrationChoice.clamp,
      stepFor: (choice) => choice == MigrationChoice.clear ? ClearInvalidStep(after) : ClampToRangeStep(after),
    );
  }

  void _categorical(CategoricalAdjustment before, CategoricalAdjustment after) {
    String? originOf(String option) =>
        optionOrigins.containsKey(option) ? optionOrigins[option] : (before.options.contains(option) ? option : null);

    final origins = {for (final option in after.options) ?originOf(option)};
    final renames = <String, String>{
      for (final option in after.options)
        if (originOf(option) case final origin? when origin != option && before.options.contains(origin)) origin: option,
    };
    // A row removed and re-added with the same text keeps its values.
    final deleted = before.options.where((o) => !origins.contains(o) && !after.options.contains(o)).toList();

    // Renames and deletions map at once, so swapping two options works; each
    // issue below previews its own part on the values the earlier ones leave.
    final mapping = <String, String?>{...renames};
    if (renames.isNotEmpty) {
      _add(
        key: 'rename',
        kind: MigrationIssueKind.renamedOptions,
        affected: _withOptions(renames.keys),
        allowed: const [MigrationChoice.automatic],
        fallback: MigrationChoice.automatic,
        stepFor: (_) => MapOptionsStep(renames),
      );
    }
    for (final option in deleted) {
      final remaining = after.options.toList();
      final choice = _add(
        key: 'delete:$option',
        kind: MigrationIssueKind.deletedOption,
        options: [option],
        affected: _withOptions([option]),
        allowed: [for (final target in remaining) MigrationChoice.mapTo(target), MigrationChoice.clear],
        fallback: remaining.isEmpty ? MigrationChoice.clear : MigrationChoice.mapTo(remaining.first),
        stepFor: (choice) => MapOptionsStep({option: choice.option}),
      );
      mapping[option] = choice.option;
    }
    if (mapping.isNotEmpty) steps.add(MapOptionsStep(mapping));
    if (!after.counted && (before.counted || mapping.isNotEmpty)) {
      _add(
        key: 'dedupe',
        kind: MigrationIssueKind.duplicateOptions,
        affected: _entries.where((e) => e.value is CategoricalValue && _hasDuplicates(e.value as CategoricalValue)).toList(),
        allowed: const [MigrationChoice.automatic],
        fallback: MigrationChoice.automatic,
        stepFor: (_) => const DedupeOptionsStep(),
      );
    }
    if (before.multiSelect && !after.multiSelect) _combinations(after);
  }

  void _combinations(CategoricalAdjustment after) {
    final groups = <String, List<_Entry>>{};
    final optionsOf = <String, List<String>>{};
    for (final entry in _entries) {
      final value = entry.value;
      if (value is! CategoricalValue) continue;
      final distinct = value.options.toSet().toList();
      if (distinct.length < 2) continue;
      final key = 'combo:${(distinct.toList()..sort()).join('\u0001')}';
      (groups[key] ??= []).add(entry);
      optionsOf.putIfAbsent(key, () => distinct);
    }

    final mapping = <Set<String>, String?>{};
    for (final MapEntry(:key, value: affected) in groups.entries) {
      final options = optionsOf[key]!;
      final fallbackTarget = options.firstWhereOrNull(after.options.contains);
      final choice = _add(
        key: key,
        kind: MigrationIssueKind.combination,
        options: options,
        affected: affected,
        allowed: [for (final target in after.options) MigrationChoice.mapTo(target), MigrationChoice.clear],
        fallback: fallbackTarget == null ? MigrationChoice.clear : MigrationChoice.mapTo(fallbackTarget),
        stepFor: (choice) => MapCombinationsStep({options.toSet(): choice.option}),
      );
      mapping[options.toSet()] = choice.option;
    }
    if (mapping.isNotEmpty) steps.add(MapCombinationsStep(mapping));
  }

  List<_Entry> _withOptions(Iterable<String> options) => _entries
      .where((e) => e.value is CategoricalValue && (e.value as CategoricalValue).options.any(options.contains))
      .toList();

  static bool _hasDuplicates(CategoricalValue value) => value.options.toSet().length != value.options.length;

  /// Adds an issue for [affected] when there are any, applies its chosen step
  /// to the working values, and returns the choice.
  MigrationChoice _add({
    required String key,
    required MigrationIssueKind kind,
    List<String> options = const [],
    required List<_Entry> affected,
    required List<MigrationChoice> allowed,
    required MigrationChoice fallback,
    required ValueMigrationStep? Function(MigrationChoice choice) stepFor,
  }) {
    final requested = choices[key];
    final choice = requested != null && allowed.contains(requested) ? requested : fallback;
    if (affected.isEmpty) return choice;

    final step = stepFor(choice);
    final example = _example(affected);
    issues.add(
      MigrationIssue(
        key: key,
        kind: kind,
        options: options,
        liveRecords: [for (final e in affected) if (!e.record.isDeleted) e.record],
        deletedRecords: [for (final e in affected) if (e.record.isDeleted) e.record],
        choices: allowed,
        choice: choice,
        example: example.record,
        exampleBefore: example.value,
        exampleAfter: step == null ? example.value : step.apply(example.value),
      ),
    );

    if (step != null) {
      // The categorical maps are collected into one step by the caller.
      if (step is! MapOptionsStep && step is! MapCombinationsStep) steps.add(step);
      _entries = [
        for (final entry in _entries)
          if (step.apply(entry.value) case final value?) _Entry(entry.record, value),
      ];
    }
    return choice;
  }

  static _Entry _example(List<_Entry> affected) {
    int newestFirst(_Entry a, _Entry b) => b.record.dateTimeLocal.compareTo(a.record.dateTimeLocal);
    final live = affected.where((e) => !e.record.isDeleted).toList()..sort(newestFirst);
    if (live.isNotEmpty) return live.first;
    return (affected.toList()..sort(newestFirst)).first;
  }
}
