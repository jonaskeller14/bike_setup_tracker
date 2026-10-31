import 'package:collection/collection.dart';

import '../../l10n/l10n.dart';
import '../setup.dart';
import 'custom_issue.dart';
import 'feedback_comparison.dart';
import 'feedback_key.dart';
import 'ride_feedback.dart';

extension RideFeedbackSummary on RideFeedback {
  FeedbackComparison? get overallComparison =>
      comparisons.firstWhereOrNull((c) => c.aspect is OverallAspect && c.isValid);

  /// "Slightly better than S5", from the overall comparison.
  String? verdict(Map<String, Setup> setups) {
    final comparison = overallComparison;
    if (comparison == null) return null;
    return _verdictOf(comparison, setups);
  }

  /// One verdict per overall comparison, the most recent reference first.
  List<String> verdicts(Map<String, Setup> setups) => comparisons
      .where((c) => c.aspect is OverallAspect && c.isValid)
      .sortedBy<DateTime>(
        (c) => setups[c.referenceSetupId]?.datetime ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      )
      .reversed
      .map((c) => _verdictOf(c, setups))
      .toList();

  static String _verdictOf(FeedbackComparison comparison, Map<String, Setup> setups) {
    final l10n = currentL10n;
    final reference = setups[comparison.referenceSetupId]?.displayName ?? l10n.feedbackDeletedSetup;
    return switch (comparison.outcome) {
      -2 => l10n.feedbackVerdictWorse(reference),
      -1 => l10n.feedbackVerdictSlightlyWorse(reference),
      0 => l10n.feedbackVerdictSame(reference),
      1 => l10n.feedbackVerdictSlightlyBetter(reference),
      2 => l10n.feedbackVerdictBetter(reference),
      _ => throw ArgumentError.value(comparison.outcome, 'outcome'),
    };
  }

  /// The flagged problems: built-in ones front before rear in vocabulary
  /// order, then custom ones by label.
  List<FeedbackIssue> get orderedIssues {
    final flagged = issues;
    return [
      for (final aspect in EndAspect.values)
        if (flagged.contains(aspect.issueKey)) FeedbackIssue.end(aspect),
      for (final issue in customIssues) FeedbackIssue.custom(issue),
    ];
  }

  /// "Front: Harsh · Rear: Low grip · Wet roots", or "Dialled in".
  String? get issuesSummary {
    if (nothingStoodOut) return currentL10n.feedbackDialledIn;
    final ordered = orderedIssues;
    if (ordered.isEmpty) return null;
    return ordered.map((issue) => issue.label).join(' · ');
  }

  /// The setup active on the bike at the feedback's time among [setups], for
  /// exports that only hold a selection rather than the repository.
  Setup? ratedSetupIn(Map<String, Setup> setups) => setups.values
      .where((s) => s.bike == bike && !s.isDeleted && !s.datetime.isAfter(dateTimeUTC))
      .sorted((a, b) => a.datetime.compareTo(b.datetime))
      .lastOrNull;
}
