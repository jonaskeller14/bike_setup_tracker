import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../models/feedback/custom_issue.dart';
import '../models/feedback/feedback_comparison.dart';
import '../models/feedback/feedback_key.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';

/// A [CustomIssue] with how often and how recently live feedbacks used it.
@immutable
class CustomIssueUsage {
  final CustomIssue issue;
  final int useCount;
  final DateTime lastUsedUTC;

  const CustomIssueUsage({required this.issue, required this.useCount, required this.lastUsedUTC});

  String get slug => issue.slug;
  String get label => issue.label;
}

/// The custom issues the live feedbacks use, most used first.
class CustomIssueIndex {
  final List<CustomIssueUsage> usages;
  final Map<String, CustomIssueUsage> _bySlug;

  CustomIssueIndex(List<CustomIssueUsage> usages)
    : usages = List.unmodifiable(usages),
      _bySlug = {for (final usage in usages) usage.slug: usage};

  static final CustomIssueIndex empty = CustomIssueIndex(const []);

  bool contains(String slug) => _bySlug.containsKey(slug);

  /// The latest label, or the slug when no live feedback uses it any more.
  String labelOf(String slug) => _bySlug[slug]?.label ?? slug;

  /// Issues whose label contains [query], most used first.
  List<CustomIssueUsage> matching(String query) {
    final needle = CustomIssue.slugOf(query);
    if (needle.isEmpty) return usages;
    return usages.where((usage) => usage.slug.contains(needle)).toList();
  }
}

class CustomIssueService {
  const CustomIssueService._();

  /// Slug → latest label (by feedback date), use count and last use. Feedbacks
  /// in the trash don't keep an issue alive.
  static CustomIssueIndex index(Iterable<RideFeedback> feedbacks) {
    final latest = <String, ({RideFeedback feedback, CustomIssue issue})>{};
    final counts = <String, int>{};
    for (final feedback in feedbacks) {
      if (feedback.isDeleted) continue;
      for (final issue in feedback.customIssues) {
        counts[issue.slug] = (counts[issue.slug] ?? 0) + 1;
        final current = latest[issue.slug];
        if (current == null || feedback.dateTimeUTC.isAfter(current.feedback.dateTimeUTC)) {
          latest[issue.slug] = (feedback: feedback, issue: issue);
        }
      }
    }
    final usages = [
      for (final MapEntry(key: slug, value: entry) in latest.entries)
        CustomIssueUsage(issue: entry.issue, useCount: counts[slug]!, lastUsedUTC: entry.feedback.dateTimeUTC),
    ];
    usages.sort((a, b) {
      final byCount = b.useCount.compareTo(a.useCount);
      if (byCount != 0) return byCount;
      final byLastUse = b.lastUsedUTC.compareTo(a.lastUsedUTC);
      return byLastUse != 0 ? byLastUse : compareCustomIssues(a.issue, b.issue);
    });
    return CustomIssueIndex(usages);
  }

  /// [feedback] with the issue [fromSlug] rewritten to [to], or null when
  /// nothing changes. When the feedback already has [to], the two merge; a
  /// comparison the merge would double keeps the existing answer.
  static RideFeedback? rename(RideFeedback feedback, String fromSlug, CustomIssue to) {
    bool isEither(FeedbackKey key) => key is CustomIssueKey && (key.slug == fromSlug || key.slug == to.slug);

    final observations = feedback.observations.any((o) => isEither(o.key))
        ? {...feedback.observations.whereNot((o) => isEither(o.key)), to.toObservation()}
        : feedback.observations;

    final from = CustomAspect(fromSlug);
    final comparisons = <FeedbackComparison>{};
    for (final comparison in feedback.comparisons) {
      if (comparison.aspect != from || fromSlug == to.slug) {
        comparisons.add(comparison);
      } else if (!feedback.comparisons.any(
        (other) => other.referenceSetupId == comparison.referenceSetupId && other.aspect == to.aspect,
      )) {
        comparisons.add(comparison.copyWith(aspect: to.aspect));
      }
    }

    if (setEquals(observations, feedback.observations) && setEquals(comparisons, feedback.comparisons)) return null;
    return feedback.copyWith(observations: observations, comparisons: comparisons);
  }

  /// [feedback] without the issue [slug], or null when it doesn't use it.
  static RideFeedback? remove(RideFeedback feedback, String slug) {
    final aspect = CustomAspect(slug);
    final observations = feedback.observations.where((o) => o.key != CustomIssueKey(slug)).toSet();
    final comparisons = feedback.comparisons.where((c) => c.aspect != aspect).toSet();
    if (observations.length == feedback.observations.length && comparisons.length == feedback.comparisons.length) {
      return null;
    }
    return feedback.copyWith(observations: observations, comparisons: comparisons);
  }

  /// [session] with the goal [fromSlug] rewritten to [to], or null when it
  /// isn't a goal. A goal that already names [to] isn't doubled.
  static TestSession? renameGoal(TestSession session, String fromSlug, CustomIssue to) {
    final from = CustomAspect(fromSlug);
    if (!session.goal.contains(from)) return null;
    return session.copyWith(goal: session.goal.map((aspect) => aspect == from ? to.aspect : aspect).toSet().toList());
  }

  /// [session] without the goal [slug], or null when it isn't a goal.
  static TestSession? removeGoal(TestSession session, String slug) {
    final aspect = CustomAspect(slug);
    if (!session.goal.contains(aspect)) return null;
    return session.copyWith(goal: session.goal.where((goal) => goal != aspect).toList());
  }
}
