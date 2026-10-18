import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/recorded_value.dart';
import '../../utils/value_migration_proposal.dart';
import '../value_transition_preview.dart';
import 'sheet_header.dart';

/// Tells the rider which recorded values an edit of [adjustmentName] affects
/// and lets them decide what happens to them. Returns the confirmed proposal,
/// or `null` when dismissed. [replacesEarlier] says that the proposal replaces
/// one the rider confirmed in an earlier edit.
Future<MigrationProposal?> showValueMigrationSheet(
  BuildContext context, {
  required String adjustmentName,
  required MigrationProposal proposal,
  bool replacesEarlier = false,
}) {
  return showModalBottomSheet<MigrationProposal>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ValueMigrationSheet(
      adjustmentName: adjustmentName,
      proposal: proposal,
      replacesEarlier: replacesEarlier,
    ),
  );
}

class _ValueMigrationSheet extends StatefulWidget {
  final String adjustmentName;
  final MigrationProposal proposal;
  final bool replacesEarlier;

  const _ValueMigrationSheet({required this.adjustmentName, required this.proposal, required this.replacesEarlier});

  @override
  State<_ValueMigrationSheet> createState() => _ValueMigrationSheetState();
}

class _ValueMigrationSheetState extends State<_ValueMigrationSheet> {
  late MigrationProposal _proposal = widget.proposal;

  void _choose(MigrationIssue issue, MigrationChoice choice) {
    setState(() => _proposal = _proposal.withChoice(issue.key, choice));
  }

  void _confirm() {
    unawaited(HapticFeedback.mediumImpact());
    Navigator.pop(context, _proposal);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decisions = _proposal.issues.where((issue) => !issue.isAutomatic).toList();
    final clearsValues = _proposal.clearsValues;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Update recorded values'),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Text(
                    "Your change to '${widget.adjustmentName}' affects ${affectedRecordsLabel(_proposal.affected)}."
                    '${decisions.isEmpty ? '' : ' Choose what happens to their values.'}'
                    '${widget.replacesEarlier ? ' This replaces the change you confirmed earlier.' : ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  ValueTransitionPreview(rows: _rows(_proposal)),
                  for (final (index, issue) in decisions.indexed)
                    _ChoiceSection(
                      key: ValueKey(issue.key),
                      issue: issue,
                      proposal: _proposal,
                      step: decisions.length > 1 ? index + 1 : null,
                      onChoose: (choice) => _choose(issue, choice),
                    ),
                  if (decisions.isNotEmpty)
                    Text(
                      'Need different values in different ${_nounFor(_proposal.affected.source, 2)}? '
                      'Cancel, change those ${_nounFor(_proposal.affected.source, 2)} first, then make this edit.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
                Expanded(
                  child: FilledButton(
                    key: const Key('value-migration-confirm'),
                    onPressed: _confirm,
                    // Clearing deletes recorded values for good once the parent form is saved.
                    style: clearsValues
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          )
                        : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_confirmLabel(_proposal.affected)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _nounFor(RecordedValueSource? source, int count) => switch (source) {
  RecordedValueSource.ratingEntry => count == 1 ? 'rating entry' : 'rating entries',
  _ => count == 1 ? 'setup' : 'setups',
};

/// "Update 4 setups"; deleted records count only when there are no live ones.
String _confirmLabel(AffectedRecords records) => records.live == 0
    ? 'Update ${records.deleted} deleted ${_nounFor(records.source, records.deleted)}'
    : 'Update ${records.live} ${_nounFor(records.source, records.live)}';

/// "4 setups (+3 deleted)", or "3 deleted setups" without live ones.
String affectedRecordsLabel(AffectedRecords records) {
  if (records.live == 0) return '${records.deleted} deleted ${_nounFor(records.source, records.deleted)}';
  final base = '${records.live} ${_nounFor(records.source, records.live)}';
  return records.deleted == 0 ? base : '$base (+${records.deleted} deleted)';
}

List<ValueTransitionRow> _rows(MigrationProposal proposal) {
  final byKey = {for (final issue in proposal.issues) issue.key: issue};
  final isCategorical = proposal.after is CategoricalAdjustment;
  return [
    for (final preview in proposal.previews)
      ValueTransitionRow(
        caption: isCategorical ? _issueTitle(byKey[preview.issueKeys.single]!, proposal) : null,
        stages: _stages(preview, proposal),
      ),
  ];
}

/// The preview's values as text, without repeating a stage that did not
/// change; a cleared value ends the chain.
List<String?> _stages(MigrationPreview preview, MigrationProposal proposal) {
  final stages = <String?>[];
  for (final (i, value) in preview.values.indexed) {
    if (value == null) {
      stages.add(null);
      break;
    }
    // Only the first stage is still in the unit the adjustment had.
    final text = _valueText(value, (i == 0 ? proposal.before.unit : proposal.after.unit)?.label);
    if (stages.isEmpty || stages.last != text) stages.add(text);
  }
  return stages;
}

String _valueText(AdjustmentValue value, String? unit) {
  final text = value is NumericalValue ? _rounded(value.value) : value.display;
  return unit != null && (value is NumericalValue || value is StepValue) ? '$text $unit' : text;
}

/// A converted number like 5.72265 shows as "≈ 5.72": two decimals, or three
/// significant digits below 1. The stored value stays exact.
String _rounded(double value) {
  final magnitude = value == 0 ? 0 : (log(value.abs()) / ln10).floor();
  final rounded = NumberFormat('0.${'#' * max(2, 2 - magnitude)}', 'en_US').format(value);
  final exact = NumericalValue(value).display;
  return rounded == exact ? exact : '≈ $rounded';
}

String _unitName(AdjustmentUnit? unit) => unit?.label ?? 'no unit';

String _issueTitle(MigrationIssue issue, MigrationProposal proposal) => switch (issue.kind) {
  MigrationIssueKind.unitConversion ||
  MigrationIssueKind.incompatibleUnit =>
    'Unit changed from ${_unitName(proposal.before.unit)} to ${_unitName(proposal.after.unit)}',
  MigrationIssueKind.renamedOptions => 'Renamed options',
  MigrationIssueKind.deletedOption => "'${proposal.optionLabel(issue.options.first)}' was deleted",
  MigrationIssueKind.duplicateOptions => 'Each option can be picked only once now',
  MigrationIssueKind.combination => "Only one option can be picked now: ${_combination(issue)}",
  MigrationIssueKind.outOfRange =>
    proposal.after is StepAdjustment ? 'Values off the new steps or range' : 'Values outside the new range',
};

/// "'Soft' + 'Firm'".
String _combination(MigrationIssue issue) => issue.options.map((option) => "'$option'").join(' + ');

/// Whether a deleted option is removed from a selection that can hold other
/// options, rather than leaving the record without a value.
bool _removesFromSelection(MigrationIssue issue, MigrationProposal proposal) =>
    issue.kind == MigrationIssueKind.deletedOption &&
    switch (proposal.before) {
      CategoricalAdjustment(:final multiSelect) => multiSelect,
      _ => false,
    };

/// The dropdown label: what the picked option replaces.
String _replaceLabel(MigrationIssue issue, MigrationProposal proposal) => switch (issue.kind) {
  MigrationIssueKind.deletedOption => "Replace '${proposal.optionLabel(issue.options.first)}' with",
  _ => 'Replace ${_combination(issue)} with',
};

/// The dropdown entry for clearing, worded like the "No value" of the example.
String _clearEntry(MigrationIssue issue, MigrationProposal proposal) => _removesFromSelection(issue, proposal)
    ? "Remove '${proposal.optionLabel(issue.options.first)}' from the selection"
    : 'No value';

String _choiceLabel(MigrationChoice choice, MigrationProposal proposal) => switch (choice.kind) {
  MigrationChoiceKind.convert => 'Convert',
  MigrationChoiceKind.keep => 'Keep numbers',
  MigrationChoiceKind.clamp => proposal.after is StepAdjustment ? 'Snap' : 'Clamp',
  MigrationChoiceKind.clear => 'Clear',
  MigrationChoiceKind.mapTo => choice.option!,
  MigrationChoiceKind.automatic => '',
};

/// What the selected choice does to the records [issue] touches.
String _choiceHint(MigrationIssue issue, MigrationProposal proposal) {
  final records = issue.affected;
  final count = affectedRecordsLabel(records);
  final one = records.isSingular;
  final unit = proposal.after.unit;
  final deletedOption = issue.kind == MigrationIssueKind.deletedOption ? proposal.optionLabel(issue.options.first) : null;
  // Another row was renamed to the deleted option's text.
  final renamedFrom = issue.kind == MigrationIssueKind.deletedOption && issue.choice.option == issue.options.first
      ? proposal.optionOrigins[issue.options.first]
      : null;
  return switch (issue.choice.kind) {
    MigrationChoiceKind.convert => '$count ${one ? 'is' : 'are'} converted to ${_unitName(unit)}.',
    MigrationChoiceKind.keep =>
      '$count ${one ? 'keeps its' : 'keep their'} numbers, '
          '${unit == null ? 'now without a unit' : 'now read in ${unit.label}'}.',
    MigrationChoiceKind.clamp =>
      proposal.after is StepAdjustment
          ? '$count ${one ? 'snaps' : 'snap'} to the nearest step.'
          : '$count ${one ? 'moves' : 'move'} to the nearest limit.',
    MigrationChoiceKind.mapTo when renamedFrom != null =>
      "$count ${one ? 'keeps' : 'keep'} '$deletedOption', now the option renamed from '$renamedFrom'.",
    MigrationChoiceKind.clear when deletedOption != null && _removesFromSelection(issue, proposal) =>
      "'$deletedOption' is removed from $count.",
    MigrationChoiceKind.clear => '$count ${one ? 'loses its' : 'lose their'} value.',
    MigrationChoiceKind.mapTo when deletedOption != null =>
      "'$deletedOption' becomes '${issue.choice.option}' in $count.",
    MigrationChoiceKind.mapTo => "$count ${one ? 'changes' : 'change'} to '${issue.choice.option}'.",
    MigrationChoiceKind.automatic => '',
  };
}

class _ChoiceSection extends StatelessWidget {
  final MigrationIssue issue;
  final MigrationProposal proposal;
  final int? step;
  final ValueChanged<MigrationChoice> onChoose;

  const _ChoiceSection({super.key, required this.issue, required this.proposal, this.step, required this.onChoose});

  bool get _picksOption => issue.choices.any((choice) => choice.kind == MigrationChoiceKind.mapTo);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _choiceHint(issue, proposal);
    final title = _issueTitle(issue, proposal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          step == null ? title : '$step: $title',
          style: theme.textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (_picksOption)
          DropdownButtonFormField<MigrationChoice>(
            key: ValueKey(issue.choice),
            initialValue: issue.choice,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: _replaceLabel(issue, proposal),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final choice in issue.choices)
                DropdownMenuItem(
                  value: choice,
                  child: Text(
                    choice.kind == MigrationChoiceKind.clear ? _clearEntry(issue, proposal) : choice.option!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (choice) {
              if (choice != null) onChoose(choice);
            },
          )
        else
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<MigrationChoice>(
              showSelectedIcon: false,
              segments: [
                for (final choice in issue.choices)
                  ButtonSegment(
                    value: choice,
                    label: Text(_choiceLabel(choice, proposal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              selected: {issue.choice},
              onSelectionChanged: (selection) => onChoose(selection.first),
            ),
          ),
        if (hint.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: Text(
              hint,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
