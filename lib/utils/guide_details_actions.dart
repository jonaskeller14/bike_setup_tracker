import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/catalog_labels.dart';
import '../l10n/l10n.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/sheets/guide_details_sheet.dart';
import '../widgets/sheets/preset_merge_sheet.dart';
import 'guide_details_change.dart';
import 'preset_merge.dart';
import 'setup_guide_actions.dart';

/// Asks for the catalog details [axisIds] that [guided]'s setup guide lacks
/// and saves them to the component right away, as they describe the part, not
/// this setup. A value that brings adjusters goes through the merge sheet;
/// otherwise only the preset map and a SAG's travel change, and can be undone.
Future<void> completeGuideDetails(BuildContext context, GuidedComponent guided, List<String> axisIds) async {
  final component = guided.component;
  final chosen = await showGuideDetailsSheet(
    context,
    componentName: component.name,
    preset: guided.preset,
    axisIds: axisIds,
  );
  if (chosen == null || !context.mounted) return;

  final l10n = context.l10n;
  final repository = context.read<AppRepository>();
  final change = planGuideDetailsChange(component.adjustments, guided.preset, chosen, l10n);
  var adjustments = change.adjustments;
  if (change.added.isNotEmpty) {
    final merge = await showPresetMergeSheet(
      context,
      productName: change.productName,
      existing: adjustments,
      proposal: proposePresetMerge(adjustments, change.added),
      recordedValues: repository.recordedAdjustmentValues({for (final a in adjustments) a.id}),
      unknownMaxKeys: change.unknownMaxKeys,
      allowReplace: false,
    );
    if (merge == null || !context.mounted) return;
    adjustments = merge.adjustments;
  }

  final messenger = ScaffoldMessenger.of(context);
  await repository.editComponents([component.copyWith(preset: change.preset, adjustments: adjustments)]);
  if (!context.mounted) return;
  unawaited(HapticFeedback.selectionClick());
  final details = [
    for (final axis in chosen.axes)
      if (axisIds.contains(axis.id))
        if (chosen.selections[axis.id] case final value?) '${axis.key.name(l10n)} ${value.label}',
  ].join(', ');
  messenger.showSnackBar(
    AppSnackBar.success(
      context,
      l10n.guideDetailsSaved(component.name, details),
      // Adjusters the merge added may already hold values applied on this setup.
      action: change.added.isEmpty
          ? AppSnackBarAction(label: l10n.undo, onPressed: () => unawaited(repository.editComponents([component])))
          : null,
    ),
  );
}
