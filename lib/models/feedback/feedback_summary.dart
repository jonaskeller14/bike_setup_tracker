import 'package:collection/collection.dart';

import '../setup.dart';
import 'feedback_comparison.dart';
import 'feedback_key.dart';
import 'feedback_vocabulary.dart';
import 'ride_feedback.dart';

extension RideFeedbackSummary on RideFeedback {
  FeedbackComparison? get overallComparison =>
      comparisons.firstWhereOrNull((c) => c.aspect is OverallAspect && c.isValid);

  /// "Slightly better than S5", from the overall comparison.
  String? verdict(Map<String, Setup> setups) {
    final comparison = overallComparison;
    if (comparison == null) return null;
    final reference = setups[comparison.referenceSetupId]?.displayName ?? 'a deleted setup';
    final label = FeedbackVocabulary.overallOutcomeLabels[comparison.outcome]!;
    return comparison.outcome == 0 ? '$label as $reference' : '$label than $reference';
  }

  /// The flagged problems, front before rear, in vocabulary order.
  List<IssueKey> get orderedIssues {
    final flagged = issues;
    return [
      for (final aspect in EndAspect.values)
        if (flagged.contains(aspect.issueKey)) aspect.issueKey,
    ];
  }

  /// "Front: Harsh · Rear: Low grip", or "Dialled in".
  String? get issuesSummary {
    if (nothingStoodOut) return FeedbackVocabulary.dialledIn;
    final ordered = orderedIssues;
    if (ordered.isEmpty) return null;
    return ordered.map(issueLabel).join(' · ');
  }

  /// The setup active on the bike at the feedback's time among [setups], for
  /// exports that only hold a selection rather than the repository.
  Setup? ratedSetupIn(Map<String, Setup> setups) => setups.values
      .where((s) => s.bike == bike && !s.isDeleted && !s.datetime.isAfter(dateTimeUTC))
      .sorted((a, b) => a.datetime.compareTo(b.datetime))
      .lastOrNull;
}

/// "Front: Harsh".
String issueLabel(IssueKey key) => '${key.end.label}: ${key.attribute.problemLabel}';
