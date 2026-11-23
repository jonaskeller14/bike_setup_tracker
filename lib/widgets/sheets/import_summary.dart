import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/import_preview.dart';
import '../../models/selected_data.dart';
import '../../services/data_selection_dependencies.dart';
import '../../utils/file_import.dart';
import '../items/import_summary_row.dart';
import 'sheet_header.dart';
import 'sheet_progress_content.dart';

/// The import step after the method choice: what importing [remoteData] with
/// [method] does to each item on this device, before anything is written.
class ImportSummarySheetContent extends StatefulWidget {
  final SelectedData remoteData;
  final ImportSourceOptions source;
  final ImportMethod method;

  /// Reads the data on this device. Called once, when the step opens.
  final Future<SelectedData> Function() loadLocalData;

  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const ImportSummarySheetContent({
    super.key,
    required this.remoteData,
    required this.source,
    required this.method,
    required this.loadLocalData,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  State<ImportSummarySheetContent> createState() => _ImportSummarySheetContentState();
}

class _ImportSummarySheetContentState extends State<ImportSummarySheetContent> {
  /// The group order of the "Choose items" sheet.
  static const _kinds = [
    DataKind.bike,
    DataKind.component,
    DataKind.setup,
    DataKind.person,
    DataKind.taskRule,
    DataKind.taskEntry,
    DataKind.feedback,
    DataKind.testSession,
  ];

  /// The row order within a group: what the import removes first, what it leaves alone last.
  static const _outcomeOrder = [
    ImportOutcome.trashed,
    ImportOutcome.updated,
    ImportOutcome.added,
    ImportOutcome.unchanged,
  ];

  late final Future<ImportPreview> _preview = widget.loadLocalData().then(
    (localData) => FileImport.preview(remoteData: widget.remoteData, localData: localData, method: widget.method),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImportPreview>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(context, snapshot.error!);
        if (!snapshot.hasData) {
          return SheetProgressContent(
            title: context.l10n.importSummaryTitle,
            message: context.l10n.importSummaryLoading,
          );
        }
        return _content(context, snapshot.data!);
      },
    );
  }

  Widget _error(BuildContext context, Object error) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.importSummaryTitle, onBack: widget.onBack),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            title: SelectableText(context.l10n.importSummaryLoadError(error.toString())),
            dense: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ImportPreview preview) {
    final kinds = _kinds.where((kind) => preview.entriesOf(kind).isNotEmpty);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: context.l10n.importSummaryTitle, onBack: widget.onBack),
          const SizedBox(height: 8),
          _intro(context),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview.isEmpty)
                    ListTile(
                      leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      title: Text(context.l10n.importSummaryEmpty),
                    ),
                  for (final kind in kinds) _group(context, kind, preview),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: FilledButton(onPressed: widget.onConfirm, child: Text(context.l10n.importSummaryConfirm)),
          ),
        ],
      ),
    );
  }

  /// The chosen method, what this step is for, and what the method does.
  Widget _intro(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final source = widget.source.name;
    final (icon, method, explanation) = switch (widget.method) {
      ImportMethod.overwrite => (
        Icons.published_with_changes,
        l10n.importMethodOverwrite,
        l10n.importSummaryExplainOverwrite(source),
      ),
      ImportMethod.merge => (Icons.merge, l10n.importMethodMerge, l10n.importSummaryExplainMerge(source)),
      ImportMethod.replace => (Icons.find_replace, l10n.importMethodReplace, l10n.importSummaryExplainReplace(source)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              Flexible(
                child: Text(method, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text(
            '${l10n.importSummaryIntro}\n$explanation',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// The non-zero counts joined with " · ", the trashed one in the error colour.
  List<InlineSpan> _counts(BuildContext context, int Function(ImportOutcome outcome) countOf) {
    final l10n = context.l10n;
    final error = Theme.of(context).colorScheme.error;
    final parts = [
      for (final (outcome, label) in [
        (ImportOutcome.added, l10n.importSummaryAdded),
        (ImportOutcome.updated, l10n.importSummaryUpdated),
        (ImportOutcome.unchanged, l10n.importSummaryUnchanged),
        (ImportOutcome.trashed, l10n.importSummaryTrashed),
      ])
        if (countOf(outcome) > 0)
          TextSpan(
            text: label(countOf(outcome)),
            style: outcome == ImportOutcome.trashed ? TextStyle(color: error) : null,
          ),
    ];
    return [
      for (final (index, part) in parts.indexed) ...[
        if (index > 0) const TextSpan(text: ' · '),
        part,
      ],
    ];
  }

  Widget _group(BuildContext context, DataKind kind, ImportPreview preview) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = preview.entriesOf(kind);
    final columnStyle = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ExpansionTile(
      title: Text(
        _kindLabel(context, kind),
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text.rich(TextSpan(children: _counts(context, (outcome) => preview.count(kind, outcome)))),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      controlAffinity: ListTileControlAffinity.leading,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.importSummarySource(widget.source.name), style: columnStyle)),
            const SizedBox(width: ImportSummaryRow.arrowWidth),
            Expanded(child: Text(l10n.importSummaryDevice, style: columnStyle)),
          ],
        ),
        const SizedBox(height: 4),
        for (final outcome in _outcomeOrder)
          for (final entry in entries)
            if (entry.outcome == outcome)
              ImportSummaryRow(
                entry: entry,
                source: widget.source,
                showEdited: widget.method == ImportMethod.merge,
              ),
      ],
    );
  }

  String _kindLabel(BuildContext context, DataKind kind) => switch (kind) {
    DataKind.person => context.l10n.importSummaryRiders,
    DataKind.bike => context.l10n.importSummaryBikes,
    DataKind.component => context.l10n.importSummaryComponents,
    DataKind.setup => context.l10n.importSummarySetups,
    DataKind.taskRule => context.l10n.importSummaryTasks,
    DataKind.taskEntry => context.l10n.importSummaryTaskEntries,
    DataKind.feedback => context.l10n.importSummaryFeedback,
    DataKind.testSession => context.l10n.importSummaryTestSessions,
  };
}
