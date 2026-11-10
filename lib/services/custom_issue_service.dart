import 'package:flutter/foundation.dart';

import '../models/feedback/custom_issue.dart';
import '../models/feedback/ride_feedback.dart';

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
}
