import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
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
    final l10n = context.l10n;

    final label = await showRenameDialog(context, title: l10n.customIssueRenameTitle, name: issue.label);
    final renamed = label == null ? null : CustomIssue.fromLabel(label);
    if (renamed == null) return null;

    final merges = renamed.slug != issue.slug && appRepository.customIssues.contains(renamed.slug);
    await appRepository.renameCustomIssue(issue.slug, renamed.label);

    unawaited(HapticFeedback.mediumImpact());
    if (!context.mounted) return renamed;
    messenger.showSnackBar(
      AppSnackBar.success(context, merges ? l10n.customIssueMerged(renamed.label) : l10n.customIssueRenamed),
    );
    return renamed;
  }

  /// Strips the issue from every feedback after a confirmation. Returns
  /// whether it was removed.
  static Future<bool> remove(BuildContext context, {required CustomIssue issue}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.customIssueRemoveTitle(issue.label),
      content: l10n.customIssueRemoveBody,
      trueText: l10n.remove,
      isDestructive: true,
    );
    if (!confirmed) return false;

    await appRepository.removeCustomIssue(issue.slug);

    unawaited(HapticFeedback.heavyImpact());
    if (!context.mounted) return true;
    messenger.showSnackBar(AppSnackBar.success(context, l10n.customIssueRemoved));
    return true;
  }
}
