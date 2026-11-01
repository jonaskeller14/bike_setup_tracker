import 'package:collection/collection.dart';

import '../setup.dart';
import 'custom_issue.dart';
import 'feedback_comparison.dart';
import 'feedback_key.dart';
import 'ride_feedback.dart';

extension RideFeedbackSummary on RideFeedback {
  FeedbackComparison? get overallComparison =>
      comparisons.firstWhereOrNull((c) => c.aspect is OverallAspect && c.isValid);

  /// The valid overall comparisons, the most recent reference first.
  List<FeedbackComparison> overallComparisons(Map<String, Setup> setups) => comparisons
      .where((c) => c.aspect is OverallAspect && c.isValid)
      .sortedBy<DateTime>(
        (c) => setups[c.referenceSetupId]?.datetime ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      )
      .reversed
      .toList();

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

  /// The setup active on the bike at the feedback's time among [setups], for
  /// exports that only hold a selection rather than the repository.
  Setup? ratedSetupIn(Map<String, Setup> setups) => setups.values
      .where((s) => s.bike == bike && !s.isDeleted && !s.datetime.isAfter(dateTimeUTC))
      .sorted((a, b) => a.datetime.compareTo(b.datetime))
      .lastOrNull;
}
