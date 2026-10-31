import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/adjustment/adjustment.dart';
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
          SheetHeader(title: context.l10n.valueMigrationTitle),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Text(
                    context.l10n.valueMigrationIntro(
                      widget.adjustmentName,
                      affectedRecordsLabel(_proposal.affected, context.l10n),
                      '${decisions.isNotEmpty}',
                      '${widget.replacesEarlier}',
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  ValueTransitionPreview(rows: _rows(_proposal, context.l10n)),
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
                      context.l10n.valueMigrationNeedDifferent,
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
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
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
                      child: Text(_confirmLabel(_proposal.affected, context.l10n)),
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

/// "Update 4 setups"; deleted records count only when there are no live ones.
String _confirmLabel(AffectedRecords records, AppLocalizations l10n) =>
    records.live == 0 ? l10n.valueMigrationUpdateDeleted(records.deleted) : l10n.valueMigrationUpdate(records.live);

/// "4 setups (+3 deleted)", or "3 deleted setups" without live ones.
String affectedRecordsLabel(AffectedRecords records, AppLocalizations l10n) {
  if (records.live == 0) return l10n.affectedDeletedSetups(records.deleted);
  return records.deleted == 0
      ? l10n.affectedSetups(records.live)
      : l10n.affectedSetupsWithDeleted(records.live, records.deleted);
}

List<ValueTransitionRow> _rows(MigrationProposal proposal, AppLocalizations l10n) {
  final byKey = {for (final issue in proposal.issues) issue.key: issue};
  final isCategorical = proposal.after is CategoricalAdjustment;
  return [
    for (final preview in proposal.previews)
      ValueTransitionRow(
        caption: isCategorical ? _issueTitle(byKey[preview.issueKeys.single]!, proposal, l10n) : null,
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
  final rounded = NumberFormat('0.${'#' * max(2, 2 - magnitude)}').format(value);
  final exact = NumericalValue(value).display;
  return rounded == exact ? exact : '≈ $rounded';
}

String _unitName(AdjustmentUnit? unit, AppLocalizations l10n) => unit?.label ?? l10n.valueMigrationNoUnit;

String _issueTitle(MigrationIssue issue, MigrationProposal proposal, AppLocalizations l10n) => switch (issue.kind) {
  MigrationIssueKind.unitConversion || MigrationIssueKind.incompatibleUnit => l10n.valueMigrationUnitChanged(
    _unitName(proposal.before.unit, l10n),
    _unitName(proposal.after.unit, l10n),
  ),
  MigrationIssueKind.renamedOptions => l10n.valueMigrationRenamedOptions,
  MigrationIssueKind.deletedOption => l10n.valueMigrationDeletedOption(proposal.optionLabel(issue.options.first)),
  MigrationIssueKind.duplicateOptions => l10n.valueMigrationDuplicateOptions,
  MigrationIssueKind.combination => l10n.valueMigrationCombination(_combination(issue)),
  MigrationIssueKind.outOfRange =>
    proposal.after is StepAdjustment ? l10n.valueMigrationOutOfStep : l10n.valueMigrationOutOfRange,
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
String _replaceLabel(MigrationIssue issue, MigrationProposal proposal, AppLocalizations l10n) =>
    switch (issue.kind) {
      MigrationIssueKind.deletedOption => l10n.valueMigrationReplaceDeleted(proposal.optionLabel(issue.options.first)),
      _ => l10n.valueMigrationReplaceCombination(_combination(issue)),
    };

/// The dropdown entry for clearing, worded like the "No value" of the example.
String _clearEntry(MigrationIssue issue, MigrationProposal proposal, AppLocalizations l10n) =>
    _removesFromSelection(issue, proposal)
    ? l10n.valueMigrationRemoveFromSelection(proposal.optionLabel(issue.options.first))
    : l10n.valueTransitionCleared;

String _choiceLabel(MigrationChoice choice, MigrationProposal proposal, AppLocalizations l10n) => switch (choice.kind) {
  MigrationChoiceKind.convert => l10n.valueMigrationConvert,
  MigrationChoiceKind.keep => l10n.valueMigrationKeepNumbers,
  MigrationChoiceKind.clamp => proposal.after is StepAdjustment ? l10n.valueMigrationSnap : l10n.valueMigrationClamp,
  MigrationChoiceKind.clear => l10n.valueMigrationClear,
  MigrationChoiceKind.mapTo => choice.option!,
  MigrationChoiceKind.automatic => '',
};

/// What the selected choice does to the records [issue] touches.
String _choiceHint(MigrationIssue issue, MigrationProposal proposal, AppLocalizations l10n) {
  final records = issue.affected;
  final count = affectedRecordsLabel(records, l10n);
  final one = '${records.isSingular}';
  final unit = proposal.after.unit;
  final deletedOption = issue.kind == MigrationIssueKind.deletedOption ? proposal.optionLabel(issue.options.first) : null;
  // Another row was renamed to the deleted option's text.
  final renamedFrom = issue.kind == MigrationIssueKind.deletedOption && issue.choice.option == issue.options.first
      ? proposal.optionOrigins[issue.options.first]
      : null;
  return switch (issue.choice.kind) {
    MigrationChoiceKind.convert => l10n.valueMigrationHintConvert(count, one, _unitName(unit, l10n)),
    MigrationChoiceKind.keep =>
      unit == null
          ? l10n.valueMigrationHintKeepNoUnit(count, one)
          : l10n.valueMigrationHintKeepUnit(count, one, unit.label),
    MigrationChoiceKind.clamp =>
      proposal.after is StepAdjustment
          ? l10n.valueMigrationHintSnap(count, one)
          : l10n.valueMigrationHintClamp(count, one),
    MigrationChoiceKind.mapTo when renamedFrom != null =>
      l10n.valueMigrationHintKeepRenamed(count, one, '$deletedOption', renamedFrom),
    MigrationChoiceKind.clear when deletedOption != null && _removesFromSelection(issue, proposal) =>
      l10n.valueMigrationHintRemoveOption(deletedOption, count),
    MigrationChoiceKind.clear => l10n.valueMigrationHintClear(count, one),
    MigrationChoiceKind.mapTo when deletedOption != null =>
      l10n.valueMigrationHintBecomes(deletedOption, '${issue.choice.option}', count),
    MigrationChoiceKind.mapTo => l10n.valueMigrationHintChanges(count, one, '${issue.choice.option}'),
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
    final hint = _choiceHint(issue, proposal, context.l10n);
    final title = _issueTitle(issue, proposal, context.l10n);
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
              labelText: _replaceLabel(issue, proposal, context.l10n),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final choice in issue.choices)
                DropdownMenuItem(
                  value: choice,
                  child: Text(
                    choice.kind == MigrationChoiceKind.clear ? _clearEntry(issue, proposal, context.l10n) : choice.option!,
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
                    label: Text(_choiceLabel(choice, proposal, context.l10n), maxLines: 1, overflow: TextOverflow.ellipsis),
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
