import 'package:flutter/material.dart';

import '../../l10n/feedback_text.dart';
import '../../l10n/l10n.dart';
import '../../models/feedback/custom_issue.dart';
import '../../services/feedback_open_issues_service.dart';
import '../../theme.dart';

/// Flagged problems as small pills ("Front: Harsh"), or a single "Dialled in"
/// pill when [issues] is empty.
class OpenIssuesChips extends StatelessWidget {
  final List<FeedbackIssue> issues;

  const OpenIssuesChips({super.key, required this.issues});

  OpenIssuesChips.of(OpenIssues openIssues, {Key? key}) : this(key: key, issues: openIssues.issues);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FeedbackOutcomeColors>()!;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: issues.isEmpty
          ? [_pill(color: colors.better, icon: Icons.check_circle, label: context.l10n.feedbackDialledIn)]
          : [
              for (final issue in issues)
                if (issue.hintText(context.l10n) case final hint?)
                  Tooltip(message: hint, child: _pill(color: colors.worse, label: issue.labelText(context.l10n)))
                else
                  _pill(color: colors.worse, label: issue.labelText(context.l10n)),
            ],
    );
  }

  Widget _pill({required Color color, required String label, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (icon != null) Icon(icon, size: 12, color: color),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
