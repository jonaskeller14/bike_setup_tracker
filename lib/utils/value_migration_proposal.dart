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
  outOfRange;

  bool get isUnitChange => this == unitConversion || this == incompatibleUnit;
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

  /// A representative affected record: the most common value this issue
  /// changes, live records before deleted ones, then the newest.
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
  AffectedRecords get affected => AffectedRecords.of(records);
}

/// How many distinct records something touches.
@immutable
class AffectedRecords {
  final int live;
  final int deleted;

  const AffectedRecords(this.live, this.deleted);

  factory AffectedRecords.of(Iterable<RecordedValue> records) {
    final byId = <String, RecordedValue>{};
    for (final record in records) {
      byId.putIfAbsent(record.recordId, () => record);
    }
    return AffectedRecords(
      byId.values.where((r) => !r.isDeleted).length,
      byId.values.where((r) => r.isDeleted).length,
    );
  }

  /// Whether the count names a single record, for verb agreement.
  bool get isSingular => (live == 0 ? deleted : live) == 1;
}

/// One example value followed through the migration: [values] is where it
/// starts, then what it is after each of the [issueKeys] in turn. A `null`
/// value is cleared.
@immutable
class MigrationPreview {
  final List<String> issueKeys;
  final RecordedValue record;
  final List<AdjustmentValue?> values;

  const MigrationPreview({required this.issueKeys, required this.record, required this.values});
}

/// What saving an edited adjustment or metric would do to its recorded values,
/// and the choices that decide it. Empty when no recorded value is affected.
///
/// It always describes the net change from the saved definition, so a further
/// edit of the same adjustment [rebuild]s it instead of adding to it.
@immutable
class MigrationProposal {
  /// The saved definition.
  final Adjustment before;
  final Adjustment after;

  /// Each new option text mapped to the saved text its row descends from;
  /// `null` for an added row. An option without an entry counts as unchanged.
  final Map<String, String?> optionOrigins;

  /// Saved options an earlier edit renamed, mapped to the name the rider last
  /// saw, so a renamed option that is deleted later is shown by that name.
  final Map<String, String> optionLabels;

  /// Every recorded value of the adjustment, as stored.
  final List<RecordedValue> recorded;
  final Map<String, MigrationChoice> choices;
  final List<MigrationIssue> issues;

  /// The examples to show: one chain for a value that runs through every
  /// issue, or one before / after pair per issue for a categorical.
  final List<MigrationPreview> previews;
  final List<ValueMigrationStep> steps;

  const MigrationProposal._({
    required this.before,
    required this.after,
    required this.optionOrigins,
    required this.optionLabels,
    required this.recorded,
    required this.choices,
    required this.issues,
    required this.previews,
    required this.steps,
  });

  /// A [choices] entry that does not fit its issue falls back to the issue's
  /// default.
  factory MigrationProposal.build({
    required Adjustment before,
    required Adjustment after,
    Map<String, String?> optionOrigins = const {},
    Map<String, String> optionLabels = const {},
    required List<RecordedValue> recorded,
    Map<String, MigrationChoice> choices = const {},
  }) {
    final builder = _ProposalBuilder(
      before: before,
      after: after,
      optionOrigins: optionOrigins,
      recorded: recorded,
      choices: choices,
    )..run();
    return MigrationProposal._(
      before: before,
      after: after,
      optionOrigins: optionOrigins,
      optionLabels: optionLabels,
      recorded: recorded,
      choices: choices,
      issues: List.unmodifiable(builder.issues),
      previews: List.unmodifiable(builder.previews),
      steps: List.unmodifiable(builder.steps),
    );
  }

  /// Whether the edit could affect recorded values at all. A page checks this
  /// before it looks the recorded values up.
  static bool mayAffectValues({
    required Adjustment before,
    required Adjustment after,
    Map<String, String?> optionOrigins = const {},
  }) => switch ((before, after)) {
    (final NumericalAdjustment before, final NumericalAdjustment after) =>
      before.unit != after.unit || before.min != after.min || before.max != after.max,
    (final StepAdjustment before, final StepAdjustment after) =>
      before.min != after.min || before.max != after.max || before.step != after.step,
    (final DurationAdjustment before, final DurationAdjustment after) =>
      before.min != after.min || before.max != after.max,
    (final CategoricalAdjustment before, final CategoricalAdjustment after) =>
      (before.counted && !after.counted) ||
          (before.multiSelect && !after.multiSelect) ||
          _hasOptionChanges(before, after, optionOrigins),
    _ => false,
  };

  bool get isEmpty => issues.isEmpty;

  /// The distinct records the issues touch.
  AffectedRecords get affected => AffectedRecords.of(issues.expand((issue) => issue.records));

  /// Whether a choice removes recorded values or options from them.
  bool get clearsValues => issues.any((issue) => issue.choice.kind == MigrationChoiceKind.clear);

  /// The distinct records the migration leaves without a value. A deleted
  /// option removed from a selection that keeps other options is not counted.
  AffectedRecords get cleared {
    final migration = toMigration();
    return AffectedRecords.of([
      for (final record in recorded)
        if (migration.apply(record.value) == null) record,
    ]);
  }

  /// The name to show for a saved [option].
  String optionLabel(String option) => optionLabels[option] ?? option;

  /// This proposal with [choice] picked for the issue [key], and every later
  /// issue worked out from the values that choice leaves.
  MigrationProposal withChoice(String key, MigrationChoice choice) => MigrationProposal.build(
    before: before,
    after: after,
    optionOrigins: optionOrigins,
    optionLabels: optionLabels,
    recorded: recorded,
    choices: {...choices, key: choice},
  );

  /// The proposal for a further edit of the same adjustment, still from the
  /// saved [before] and with the choices made so far. [after] is the newest
  /// definition; [pageOrigins] maps its options to the text their rows had in
  /// this proposal's [after], where that edit started.
  MigrationProposal rebuild({
    required Adjustment after,
    Map<String, String?> pageOrigins = const {},
    List<RecordedValue>? recorded,
  }) {
    final previous = this.after;
    final labels = {...optionLabels};
    if (previous is CategoricalAdjustment) {
      for (final option in previous.options) {
        if (_originOf(before, optionOrigins, option) case final saved?) labels[saved] = option;
      }
      labels.removeWhere((saved, label) => saved == label);
    }
    return MigrationProposal.build(
      before: before,
      after: after,
      optionOrigins: savedOriginsFor(after, pageOrigins),
      optionLabels: labels,
      recorded: recorded ?? this.recorded,
      choices: choices,
    );
  }

  /// The [pageOrigins] of a further edit (option of [after] to its text in this
  /// proposal's [after]) traced back to the saved options.
  Map<String, String?> savedOriginsFor(Adjustment after, Map<String, String?> pageOrigins) {
    final previous = this.after;
    if (after is! CategoricalAdjustment || previous is! CategoricalAdjustment) return const {};
    return {
      for (final option in after.options)
        option: switch (_originOf(previous, pageOrigins, option)) {
          final origin? => _originOf(before, optionOrigins, origin),
          null => null,
        },
    };
  }

  /// The migration for the current choices.
  ValueMigration toMigration() => ValueMigration(after.id, steps);
}

/// The text in [before] that [option] descends from, per [origins]; an option
/// without an entry descends from itself when [before] has it.
String? _originOf(Adjustment before, Map<String, String?> origins, String option) {
  if (origins.containsKey(option)) return origins[option];
  return before is CategoricalAdjustment && before.options.contains(option) ? option : null;
}

/// The options an edit renamed (old text to new text) and deleted. Values
/// follow their option row, so [optionOrigins] says which original text each
/// new option started from; an option without an entry counts as unchanged.
({Map<String, String> renames, List<String> deleted}) _optionChanges(
  CategoricalAdjustment before,
  CategoricalAdjustment after,
  Map<String, String?> optionOrigins,
) {
  String? originOf(String option) => _originOf(before, optionOrigins, option);

  final origins = {for (final option in after.options) ?originOf(option)};
  final renames = <String, String>{
    for (final option in after.options)
      if (originOf(option) case final origin? when origin != option && before.options.contains(origin)) origin: option,
  };
  // A row removed and re-added with the same text keeps its values; a text
  // that another row was renamed to does not.
  final deleted = before.options
      .where((o) => !origins.contains(o) && !(after.options.contains(o) && originOf(o) == null))
      .toList();
  return (renames: renames, deleted: deleted);
}

bool _hasOptionChanges(
  CategoricalAdjustment before,
  CategoricalAdjustment after,
  Map<String, String?> optionOrigins,
) {
  final (:renames, :deleted) = _optionChanges(before, after, optionOrigins);
  return renames.isNotEmpty || deleted.isNotEmpty;
}

class _Entry {
  final RecordedValue record;
  final AdjustmentValue start;

  /// The value after each issue so far; `null` once cleared.
  final List<AdjustmentValue?> trail = [];
  AdjustmentValue? current;

  _Entry(this.record, this.start) : current = start;

  AdjustmentValue get value => current!;
}

class _ProposalBuilder {
  final Adjustment before;
  final Adjustment after;
  final Map<String, String?> optionOrigins;
  final List<RecordedValue> recorded;
  final Map<String, MigrationChoice> choices;

  final issues = <MigrationIssue>[];
  final steps = <ValueMigrationStep>[];
  final previews = <MigrationPreview>[];
  late List<_Entry> _all;

  /// The entries that still hold a value.
  late List<_Entry> _entries;

  _ProposalBuilder({
    required this.before,
    required this.after,
    required this.optionOrigins,
    required this.recorded,
    required this.choices,
  });

  void run() {
    _all = [for (final record in recorded) _Entry(record, record.value)];
    _entries = _all;
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
    _buildPreviews();
  }

  void _buildPreviews() {
    if (issues.isEmpty) return;
    if (after is CategoricalAdjustment) {
      for (final issue in issues) {
        previews.add(
          MigrationPreview(
            issueKeys: [issue.key],
            record: issue.example,
            values: [issue.exampleBefore, issue.exampleAfter],
          ),
        );
      }
      return;
    }

    // One value runs through every issue: show the one that the most issues
    // change, so a value that stays as it is (a 0 whose unit changes) is not
    // picked to illustrate the change.
    int changes(_Entry entry) {
      var count = 0;
      AdjustmentValue? previous = entry.start;
      for (final (i, next) in entry.trail.indexed) {
        final relabelled = issues[i].kind.isUnitChange && issues[i].choice == MigrationChoice.keep;
        if (next != previous || relabelled) count++;
        previous = next;
      }
      return count;
    }

    final frequency = <String, int>{};
    for (final entry in _all) {
      frequency.update(entry.start.encode(), (n) => n + 1, ifAbsent: () => 1);
    }
    final best = _all.sorted((a, b) {
      final byChanges = changes(b).compareTo(changes(a));
      if (byChanges != 0) return byChanges;
      final byFrequency = frequency[b.start.encode()]!.compareTo(frequency[a.start.encode()]!);
      if (byFrequency != 0) return byFrequency;
      if (a.record.isDeleted != b.record.isDeleted) return a.record.isDeleted ? 1 : -1;
      return b.record.dateTimeLocal.compareTo(a.record.dateTimeLocal);
    }).first;
    previews.add(
      MigrationPreview(
        issueKeys: [for (final issue in issues) issue.key],
        record: best.record,
        values: [best.start, ...best.trail],
      ),
    );
  }

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
    final range = switch (after) {
      final NumericalAdjustment a => a.range,
      final StepAdjustment a => a.range,
      final DurationAdjustment a => a.range,
      _ => null,
    };
    if (range == null) return;
    _add(
      key: 'range',
      kind: MigrationIssueKind.outOfRange,
      affected: _entries.where((e) => range.appliesTo(e.value) && !range.contains(e.value)).toList(),
      allowed: const [MigrationChoice.clamp, MigrationChoice.clear],
      fallback: MigrationChoice.clamp,
      stepFor: (choice) => choice == MigrationChoice.clear ? ClearOutOfRangeStep(range) : ClampToRangeStep(range),
    );
  }

  void _categorical(CategoricalAdjustment before, CategoricalAdjustment after) {
    final (:renames, :deleted) = _optionChanges(before, after, optionOrigins);

    // Renames and deletions map at once, so swapping two options works, and
    // each of their issues counts and previews the values as stored: a deleted
    // option's text may be the one another option was renamed to.
    final mapping = <String, String?>{...renames};
    if (renames.isNotEmpty) {
      _add(
        key: 'rename',
        kind: MigrationIssueKind.renamedOptions,
        affected: _withOptions(renames.keys),
        allowed: const [MigrationChoice.automatic],
        fallback: MigrationChoice.automatic,
        stepFor: (_) => MapOptionsStep(renames),
        appliesStep: false,
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
        // A text that another row was renamed to merges into that row by default.
        fallback: remaining.contains(option)
            ? MigrationChoice.mapTo(option)
            : remaining.isEmpty
            ? MigrationChoice.clear
            : MigrationChoice.mapTo(remaining.first),
        stepFor: (choice) => MapOptionsStep({option: choice.option}),
        appliesStep: false,
      );
      mapping[option] = choice.option;
    }
    if (mapping.isNotEmpty) {
      final step = MapOptionsStep(mapping);
      steps.add(step);
      _apply(step);
    }
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
  /// to the working values unless the caller applies it with others
  /// ([appliesStep] false), and returns the choice.
  MigrationChoice _add({
    required String key,
    required MigrationIssueKind kind,
    List<String> options = const [],
    required List<_Entry> affected,
    required List<MigrationChoice> allowed,
    required MigrationChoice fallback,
    required ValueMigrationStep? Function(MigrationChoice choice) stepFor,
    bool appliesStep = true,
  }) {
    final requested = choices[key];
    final choice = requested != null && allowed.contains(requested) ? requested : fallback;
    if (affected.isEmpty) return choice;

    final step = stepFor(choice);
    final example = _example(affected, step);
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
    }
    for (final entry in _all) {
      entry.trail.add(entry.current);
    }
    if (appliesStep && step != null) _apply(step);
    return choice;
  }

  /// Runs [step] over the working values, also as the last stage of the trail.
  void _apply(ValueMigrationStep step) {
    for (final entry in _all) {
      final value = entry.current;
      if (value == null) continue;
      entry.current = step.apply(value);
      if (entry.trail.isNotEmpty) entry.trail.last = entry.current;
    }
    _entries = _all.where((e) => e.current != null).toList();
  }

  /// The most common value [step] changes (any value when it changes none),
  /// live records before deleted ones, then the newest, so the example stands
  /// for as many records as possible.
  static _Entry _example(List<_Entry> affected, ValueMigrationStep? step) {
    final changed = step == null ? affected : affected.where((e) => step.apply(e.value) != e.value).toList();
    final candidates = changed.isEmpty ? affected : changed;
    final frequency = <String, int>{};
    for (final entry in candidates) {
      frequency.update(entry.value.encode(), (n) => n + 1, ifAbsent: () => 1);
    }
    return candidates.sorted((a, b) {
      final byFrequency = frequency[b.value.encode()]!.compareTo(frequency[a.value.encode()]!);
      if (byFrequency != 0) return byFrequency;
      if (a.record.isDeleted != b.record.isDeleted) return a.record.isDeleted ? 1 : -1;
      return b.record.dateTimeLocal.compareTo(a.record.dateTimeLocal);
    }).first;
  }
}
