import 'package:flutter/foundation.dart';

import '../models/feedback/feedback_key.dart';
import '../models/feedback/ride_feedback.dart';

/// What still felt off on a setup, from the latest feedback that answered
/// "Anything stand out?".
@immutable
class OpenIssues {
  /// Front before rear, in vocabulary order. Empty means "Dialled in".
  final List<IssueKey> issues;

  /// The feedback the issues come from.
  final String feedbackId;

  const OpenIssues({required this.issues, required this.feedbackId});

  bool get isDialledIn => issues.isEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenIssues && listEquals(issues, other.issues) && feedbackId == other.feedbackId;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(issues), feedbackId);

  @override
  String toString() => 'OpenIssues($issues, $feedbackId)';
}

class FeedbackOpenIssuesService {
  const FeedbackOpenIssuesService._();

  /// The open issues of the setup that [feedbacks] resolve to, or null when
  /// none of them flagged a problem or "Nothing stood out". A feedback that
  /// answered neither doesn't clear earlier issues.
  static OpenIssues? openIssues(Iterable<RideFeedback> feedbacks) {
    RideFeedback? latest;
    for (final feedback in feedbacks) {
      if (feedback.isDeleted || (feedback.issues.isEmpty && !feedback.nothingStoodOut)) continue;
      if (latest == null || feedback.dateTimeUTC.isAfter(latest.dateTimeUTC)) latest = feedback;
    }
    if (latest == null) return null;

    final flagged = latest.issues.map((key) => key.aspect).toSet();
    return OpenIssues(
      issues: [
        for (final aspect in EndAspect.values)
          if (flagged.contains(aspect)) aspect.issueKey,
      ],
      feedbackId: latest.id,
    );
  }
}
