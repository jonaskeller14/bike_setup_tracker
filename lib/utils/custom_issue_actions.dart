import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/feedback/custom_issue.dart';
import '../repositories/app_repository.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/dialogs/rename_dialog.dart';

class CustomIssueActions {
  /// Asks for a new label and rewrites the issue in every feedback. Returns
  /// the issue as it is called now, or null when nothing changed.
  static Future<CustomIssue?> rename(BuildContext context, {required CustomIssue issue}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final label = await showRenameDialog(context, title: 'Rename issue', name: issue.label);
    final renamed = label == null ? null : CustomIssue.fromLabel(label);
    if (renamed == null) return null;

    final merges = renamed.slug != issue.slug && appRepository.customIssues.contains(renamed.slug);
    await appRepository.renameCustomIssue(issue.slug, renamed.label);

    unawaited(HapticFeedback.mediumImpact());
    if (!context.mounted) return renamed;
    messenger.showSnackBar(
      AppSnackBar.success(context, merges ? 'Merged into "${renamed.label}".' : 'Issue renamed.'),
    );
    return renamed;
  }

  /// Strips the issue from every feedback after a confirmation. Returns
  /// whether it was removed.
  static Future<bool> remove(BuildContext context, {required CustomIssue issue}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'Remove "${issue.label}"?',
      content: 'It is removed from every feedback and test session goal, including the trash. This cannot be undone.',
      trueText: 'Remove',
      isDestructive: true,
    );
    if (!confirmed) return false;

    await appRepository.removeCustomIssue(issue.slug);

    unawaited(HapticFeedback.heavyImpact());
    if (!context.mounted) return true;
    messenger.showSnackBar(AppSnackBar.success(context, 'Issue removed.'));
    return true;
  }
}
