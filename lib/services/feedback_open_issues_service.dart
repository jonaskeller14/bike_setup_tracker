import 'package:flutter/foundation.dart';

import '../models/feedback/custom_issue.dart';
import '../models/feedback/feedback_summary.dart';
import '../models/feedback/ride_feedback.dart';

/// What still felt off on a setup, from the latest feedback that answered
/// "Anything stand out?".
@immutable
class OpenIssues {
  /// Built-in ones front before rear in vocabulary order, then custom ones by
  /// label. Empty means "Dialled in".
  final List<FeedbackIssue> issues;

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
    List<FeedbackIssue> latestIssues = const [];
    for (final feedback in feedbacks) {
      if (feedback.isDeleted) continue;
      if (latest != null && !feedback.dateTimeUTC.isAfter(latest.dateTimeUTC)) continue;
      final issues = feedback.orderedIssues;
      if (issues.isEmpty && !feedback.nothingStoodOut) continue;
      (latest, latestIssues) = (feedback, issues);
    }
    if (latest == null) return null;

    return OpenIssues(issues: latestIssues, feedbackId: latest.id);
  }
}
