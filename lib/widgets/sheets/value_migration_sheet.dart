import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/recorded_value.dart';
import '../../utils/value_migration_proposal.dart';
import '../value_transition_preview.dart';
import 'sheet_header.dart';

/// Tells the rider which recorded values an edit of [adjustmentName] affects
/// and lets them decide what happens to them. Returns the confirmed migration,
/// or `null` when dismissed.
Future<ValueMigration?> showValueMigrationSheet(
  BuildContext context, {
  required String adjustmentName,
  required MigrationProposal proposal,
}) {
  return showModalBottomSheet<ValueMigration>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ValueMigrationSheet(adjustmentName: adjustmentName, proposal: proposal),
  );
}

class _ValueMigrationSheet extends StatefulWidget {
  final String adjustmentName;
  final MigrationProposal proposal;

  const _ValueMigrationSheet({required this.adjustmentName, required this.proposal});

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
    Navigator.pop(context, _proposal.toMigration());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = _AffectedRecords.of(_proposal);
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
                    "Your change to '${widget.adjustmentName}' affects values recorded in "
                    '${_countLabel(records)}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  ValueTransitionPreview(rows: _rows(_proposal)),
                  for (final issue in _proposal.issues)
                    if (!issue.isAutomatic)
                      _ChoiceSection(
                        key: ValueKey(issue.key),
                        issue: issue,
                        proposal: _proposal,
                        onChoose: (choice) => _choose(issue, choice),
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
                  child: FilledButton(onPressed: _confirm, child: const Text('Update values')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The distinct records the issues touch.
class _AffectedRecords {
  final int live;
  final int deleted;
  final RecordedValueSource? source;

  const _AffectedRecords(this.live, this.deleted, this.source);

  factory _AffectedRecords.of(MigrationProposal proposal) {
    final byId = <String, RecordedValue>{};
    for (final record in proposal.issues.expand((issue) => issue.records)) {
      byId.putIfAbsent(record.recordId, () => record);
    }
    return _AffectedRecords(
      byId.values.where((r) => !r.isDeleted).length,
      byId.values.where((r) => r.isDeleted).length,
      byId.values.firstOrNull?.source,
    );
  }
}

/// Values of a person attribute are recorded in setups too, so only rating
/// metrics speak of rating entries.
String _nounFor(RecordedValueSource? source, int count) => switch (source) {
  RecordedValueSource.ratingEntry => count == 1 ? 'rating entry' : 'rating entries',
  _ => count == 1 ? 'setup' : 'setups',
};

/// "4 setups (+3 deleted)", or "3 deleted setups" without live ones.
String _countLabel(_AffectedRecords records) {
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

String _valueText(AdjustmentValue value, String? unit) =>
    unit != null && (value is NumericalValue || value is StepValue) ? '${value.display} $unit' : value.display;

String _unitName(AdjustmentUnit? unit) => unit?.label ?? 'no unit';

String _issueTitle(MigrationIssue issue, MigrationProposal proposal) => switch (issue.kind) {
  MigrationIssueKind.unitConversion ||
  MigrationIssueKind.incompatibleUnit =>
    'Unit changed from ${_unitName(proposal.before.unit)} to ${_unitName(proposal.after.unit)}',
  MigrationIssueKind.renamedOptions => 'Renamed options',
  MigrationIssueKind.deletedOption => "Deleted option '${issue.options.first}'",
  MigrationIssueKind.duplicateOptions => 'Repeated options',
  MigrationIssueKind.combination => '${issue.options.join(' + ')} together',
  MigrationIssueKind.outOfRange =>
    proposal.after is StepAdjustment ? 'Values off the new steps or range' : 'Values outside the new range',
};

String _choiceLabel(MigrationChoice choice, MigrationProposal proposal) => switch (choice.kind) {
  MigrationChoiceKind.convert => 'Convert',
  MigrationChoiceKind.keep => 'Keep numbers',
  MigrationChoiceKind.clamp => proposal.after is StepAdjustment ? 'Snap' : 'Clamp',
  MigrationChoiceKind.clear => 'Clear',
  MigrationChoiceKind.mapTo => choice.option!,
  MigrationChoiceKind.automatic => '',
};

String _choiceHint(MigrationIssue issue, MigrationProposal proposal) => switch (issue.choice.kind) {
  MigrationChoiceKind.convert => 'Recorded numbers are converted to ${_unitName(proposal.after.unit)}.',
  MigrationChoiceKind.keep => 'The numbers stay and are read in ${_unitName(proposal.after.unit)}.',
  MigrationChoiceKind.clamp =>
    proposal.after is StepAdjustment
        ? 'Values move to the nearest allowed step.'
        : 'Values outside the range move to the nearest limit.',
  MigrationChoiceKind.clear => 'The recorded values are removed.',
  MigrationChoiceKind.mapTo || MigrationChoiceKind.automatic => '',
};

class _ChoiceSection extends StatelessWidget {
  final MigrationIssue issue;
  final MigrationProposal proposal;
  final ValueChanged<MigrationChoice> onChoose;

  const _ChoiceSection({super.key, required this.issue, required this.proposal, required this.onChoose});

  bool get _picksOption => issue.choices.any((choice) => choice.kind == MigrationChoiceKind.mapTo);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _choiceHint(issue, proposal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(_issueTitle(issue, proposal), style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (_picksOption)
          DropdownButtonFormField<MigrationChoice>(
            key: ValueKey(issue.choice),
            initialValue: issue.choice,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Change to', border: OutlineInputBorder(), isDense: true),
            items: [
              for (final choice in issue.choices)
                DropdownMenuItem(
                  value: choice,
                  child: Text(
                    choice.kind == MigrationChoiceKind.clear ? 'Clear selection' : choice.option!,
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
          Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
