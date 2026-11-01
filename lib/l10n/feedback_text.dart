import '../models/feedback/custom_issue.dart';
import '../models/feedback/feedback_comparison.dart';
import '../models/feedback/feedback_key.dart';
import '../models/feedback/feedback_summary.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/setup.dart';
import 'app_localizations.dart';
import 'entity_names.dart';
import 'enum_labels.dart';

extension FeedbackIssueText on FeedbackIssue {
  /// "Front: Harsh", or the rider's own label.
  String labelText(AppLocalizations l10n) => switch (aspect) {
    EndAspect(:final end, :final attribute) => '${end.label(l10n)}: ${attribute.problemLabel(l10n)}',
    _ => customLabel ?? aspect.raw,
  };

  String? hintText(AppLocalizations l10n) => switch (aspect) {
    EndAspect(:final attribute) => attribute.hint(l10n),
    _ => null,
  };
}

extension RideFeedbackText on RideFeedback {
  /// "Slightly better than S5", from the overall comparison.
  String? verdict(Map<String, Setup> setups, AppLocalizations l10n) {
    final comparison = overallComparison;
    return comparison == null ? null : _verdictOf(comparison, setups, l10n);
  }

  /// One verdict per overall comparison, the most recent reference first.
  List<String> verdicts(Map<String, Setup> setups, AppLocalizations l10n) =>
      [for (final comparison in overallComparisons(setups)) _verdictOf(comparison, setups, l10n)];

  /// "Front: Harsh · Rear: Low grip · Wet roots", or "Dialled in".
  String? issuesSummaryText(AppLocalizations l10n) {
    if (nothingStoodOut) return l10n.feedbackDialledIn;
    final ordered = orderedIssues;
    if (ordered.isEmpty) return null;
    return ordered.map((issue) => issue.labelText(l10n)).join(' · ');
  }
}

String _verdictOf(FeedbackComparison comparison, Map<String, Setup> setups, AppLocalizations l10n) {
  final reference = setups[comparison.referenceSetupId]?.label(l10n) ?? l10n.feedbackDeletedSetup;
  return switch (comparison.outcome) {
    -2 => l10n.feedbackVerdictWorse(reference),
    -1 => l10n.feedbackVerdictSlightlyWorse(reference),
    0 => l10n.feedbackVerdictSame(reference),
    1 => l10n.feedbackVerdictSlightlyBetter(reference),
    2 => l10n.feedbackVerdictBetter(reference),
    _ => throw ArgumentError.value(comparison.outcome, 'outcome'),
  };
}
