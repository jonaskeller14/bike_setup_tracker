import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/rating/rating_entry.dart';
import '../../models/recorded_value.dart';
import '../../models/setup.dart';
import '../../utils/value_migration_proposal.dart';
import '../value_transition_preview.dart';
import 'radio_option_card.dart';
import 'sheet_header.dart';

/// Tells the rider which recorded values an edit of [adjustmentName] affects
/// and lets them decide what happens to each. Returns the confirmed migration,
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
  bool _showRecords = false;

  void _choose(MigrationIssue issue, MigrationChoice choice) {
    setState(() => _proposal = _proposal.withChoice(issue.key, choice));
  }

  void _confirm() {
    unawaited(HapticFeedback.mediumImpact());
    Navigator.pop(context, _proposal.toMigration());
  }

  @override
  Widget build(BuildContext context) {
    final records = _AffectedRecords.of(_proposal);
    return PopScope(
      canPop: !_showRecords,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _showRecords = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showRecords
            ? _RecordsSlide(
                key: const ValueKey('records'),
                records: records,
                onBack: () => setState(() => _showRecords = false),
              )
            : _SummarySlide(
                key: const ValueKey('summary'),
                adjustmentName: widget.adjustmentName,
                proposal: _proposal,
                records: records,
                onChoose: _choose,
                onShowRecords: () => setState(() => _showRecords = true),
                onConfirm: _confirm,
              ),
      ),
    );
  }
}

/// The distinct records the issues touch.
class _AffectedRecords {
  final List<RecordedValue> live;
  final List<RecordedValue> deleted;

  const _AffectedRecords(this.live, this.deleted);

  factory _AffectedRecords.of(MigrationProposal proposal) {
    final byId = <String, RecordedValue>{};
    for (final record in proposal.issues.expand((issue) => issue.records)) {
      byId.putIfAbsent(record.recordId, () => record);
    }
    int newestFirst(RecordedValue a, RecordedValue b) => b.dateTimeLocal.compareTo(a.dateTimeLocal);
    return _AffectedRecords(
      byId.values.where((r) => !r.isDeleted).toList()..sort(newestFirst),
      byId.values.where((r) => r.isDeleted).toList()..sort(newestFirst),
    );
  }

  RecordedValueSource? get source => (live.isNotEmpty ? live : deleted).firstOrNull?.source;
}

String _nounFor(RecordedValueSource? source, int count) => switch (source) {
  RecordedValueSource.ratingEntry => count == 1 ? 'rating entry' : 'rating entries',
  _ => count == 1 ? 'setup' : 'setups',
};

/// "4 setups (+3 deleted)", or "3 deleted setups" without live ones.
String _countLabel(RecordedValueSource? source, int live, int deleted) {
  if (live == 0) return '$deleted deleted ${_nounFor(source, deleted)}';
  final base = '$live ${_nounFor(source, live)}';
  return deleted == 0 ? base : '$base (+$deleted deleted)';
}

class _SummarySlide extends StatelessWidget {
  final String adjustmentName;
  final MigrationProposal proposal;
  final _AffectedRecords records;
  final void Function(MigrationIssue issue, MigrationChoice choice) onChoose;
  final VoidCallback onShowRecords;
  final VoidCallback onConfirm;

  const _SummarySlide({
    super.key,
    required this.adjustmentName,
    required this.proposal,
    required this.records,
    required this.onChoose,
    required this.onShowRecords,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = records.source;
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
                children: [
                  Text(
                    "Your change to '$adjustmentName' affects "
                    '${_countLabel(source, records.live.length, records.deleted.length)}.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  for (final issue in proposal.issues) ...[
                    const SizedBox(height: 24),
                    _IssueSection(
                      key: ValueKey(issue.key),
                      issue: issue,
                      proposal: proposal,
                      onChoose: (choice) => onChoose(issue, choice),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      source == RecordedValueSource.ratingEntry ? RatingEntry.iconData : Setup.iconData,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text('Show affected ${_nounFor(source, 2)}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: onShowRecords,
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
                  child: FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueSection extends StatelessWidget {
  final MigrationIssue issue;
  final MigrationProposal proposal;
  final ValueChanged<MigrationChoice> onChoose;

  const _IssueSection({super.key, required this.issue, required this.proposal, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat(context.read<AppSettings>().dateFormat);
    final isUnitIssue =
        issue.kind == MigrationIssueKind.unitConversion || issue.kind == MigrationIssueKind.incompatibleUnit;
    final beforeUnit = (isUnitIssue ? proposal.before.unit : proposal.after.unit)?.label;
    final afterUnit = proposal.after.unit?.label;
    final example = issue.example;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _issueTitle(issue, proposal),
          style: theme.textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _countLabel(example.source, issue.liveRecords.length, issue.deletedRecords.length),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ValueTransitionPreview(
          icon: example.source == RecordedValueSource.ratingEntry ? RatingEntry.iconData : Setup.iconData,
          beforeValue: _valueText(issue.exampleBefore, beforeUnit),
          beforeCaption: 'Recorded · ${example.label}, ${dateFormat.format(example.dateTimeLocal)}',
          afterValue: issue.exampleAfter == null ? null : _valueText(issue.exampleAfter!, afterUnit),
          afterCaption: _afterCaption(issue, proposal),
        ),
        const SizedBox(height: 8),
        if (issue.isAutomatic)
          Text(
            'Applied automatically',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          )
        else
          Column(
            spacing: 8,
            children: [
              for (final choice in issue.choices)
                RadioOptionCard(
                  compact: true,
                  selected: issue.choice == choice,
                  onTap: () => onChoose(choice),
                  title: _choiceTitle(issue, choice, proposal),
                  subtitle: _choiceSubtitle(issue, choice, proposal),
                ),
            ],
          ),
      ],
    );
  }
}

String _valueText(AdjustmentValue value, String? unit) =>
    unit != null && (value is NumericalValue || value is StepValue) ? '${value.display} $unit' : value.display;

String _unitName(AdjustmentUnit? unit) => unit?.label ?? 'no unit';

String _issueTitle(MigrationIssue issue, MigrationProposal proposal) => switch (issue.kind) {
  MigrationIssueKind.unitConversion ||
  MigrationIssueKind.incompatibleUnit =>
    'Unit changed from ${_unitName(proposal.before.unit)} to ${_unitName(proposal.after.unit)}',
  MigrationIssueKind.renamedOptions => 'Options renamed',
  MigrationIssueKind.deletedOption => "Option '${issue.options.first}' deleted",
  MigrationIssueKind.duplicateOptions => 'Repeated options removed',
  MigrationIssueKind.combination => '${issue.options.join(' + ')} can no longer be selected together',
  MigrationIssueKind.outOfRange =>
    proposal.after is StepAdjustment ? 'Values off the new steps or range' : 'Values outside the new range',
};

String _afterCaption(MigrationIssue issue, MigrationProposal proposal) => switch (issue.choice.kind) {
  MigrationChoiceKind.convert => 'Converted',
  MigrationChoiceKind.keep => 'Kept',
  MigrationChoiceKind.clamp => proposal.after is StepAdjustment ? 'Snapped' : 'Clamped',
  MigrationChoiceKind.clear => 'Cleared',
  MigrationChoiceKind.mapTo => 'Changed',
  MigrationChoiceKind.automatic => switch (issue.kind) {
    MigrationIssueKind.renamedOptions => 'Renamed',
    MigrationIssueKind.duplicateOptions => 'Repeats removed',
    _ => 'Updated',
  },
};

String _choiceTitle(MigrationIssue issue, MigrationChoice choice, MigrationProposal proposal) => switch (choice.kind) {
  MigrationChoiceKind.convert => 'Convert values',
  MigrationChoiceKind.keep => 'Keep numbers',
  MigrationChoiceKind.clamp => proposal.after is StepAdjustment ? 'Snap to nearest step' : 'Clamp to range',
  MigrationChoiceKind.clear => 'Clear values',
  MigrationChoiceKind.mapTo => choice.option!,
  MigrationChoiceKind.automatic => '',
};

String _choiceSubtitle(MigrationIssue issue, MigrationChoice choice, MigrationProposal proposal) =>
    switch (choice.kind) {
      MigrationChoiceKind.convert => 'Recorded numbers become ${_unitName(proposal.after.unit)}.',
      MigrationChoiceKind.keep => 'The numbers stay and are read in ${_unitName(proposal.after.unit)}.',
      MigrationChoiceKind.clamp => proposal.after is StepAdjustment
          ? 'Values move to the nearest allowed step.'
          : 'Values outside the range move to the nearest limit.',
      MigrationChoiceKind.clear => 'The recorded values are removed.',
      MigrationChoiceKind.mapTo => switch (issue.kind) {
        MigrationIssueKind.deletedOption => "Selections of '${issue.options.first}' become '${choice.option}'.",
        _ => '${issue.options.join(' + ')} becomes just this option.',
      },
      MigrationChoiceKind.automatic => '',
    };

class _RecordsSlide extends StatelessWidget {
  final _AffectedRecords records;
  final VoidCallback onBack;

  const _RecordsSlide({super.key, required this.records, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = records.source;
    final dateFormat = DateFormat(context.read<AppSettings>().dateFormat);
    final icon = source == RecordedValueSource.ratingEntry ? RatingEntry.iconData : Setup.iconData;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: 'Affected ${_nounFor(source, 2)}', onBack: onBack, showClose: false),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final record in records.live)
                  ListTile(
                    leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                    title: Text(record.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(dateFormat.format(record.dateTimeLocal)),
                  ),
                if (records.deleted.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: theme.colorScheme.onSurfaceVariant),
                    title: Text(
                      '+${records.deleted.length} deleted ${_nounFor(source, records.deleted.length)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
