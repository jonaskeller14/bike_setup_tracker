import 'package:flutter/foundation.dart';

import 'feedback_key.dart';
import 'feedback_observation.dart';

/// A rider-defined problem. There is no table: it exists while a live feedback
/// carries `issue.custom:<slug>`, with [label] stored as that observation's text.
@immutable
class CustomIssue {
  static const int maxSlugLength = 40;

  final String slug;
  final String label;

  const CustomIssue(this.slug, this.label);

  /// Null when [label] is blank.
  static CustomIssue? fromLabel(String label) {
    final trimmed = label.trim();
    final slug = slugOf(trimmed);
    return slug.isEmpty ? null : CustomIssue(slug, trimmed);
  }

  /// Trimmed, whitespace collapsed, lowercase, at most [maxSlugLength] characters.
  static String slugOf(String label) {
    final collapsed = label.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (collapsed.length <= maxSlugLength) return collapsed;
    return collapsed.substring(0, maxSlugLength).trimRight();
  }

  CustomIssueKey get key => CustomIssueKey(slug);

  CustomAspect get aspect => CustomAspect(slug);

  FeedbackObservation toObservation() => FeedbackObservation(key: key, value: 1, textValue: label);

  @override
  bool operator ==(Object other) => other is CustomIssue && other.slug == slug && other.label == label;

  @override
  int get hashCode => Object.hash(slug, label);

  @override
  String toString() => 'CustomIssue($slug, $label)';
}

/// By label ignoring case, then slug, so the order is stable.
int compareCustomIssues(CustomIssue a, CustomIssue b) {
  final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
  return byLabel != 0 ? byLabel : a.slug.compareTo(b.slug);
}

/// A flagged problem to show: a built-in end + attribute or a [CustomIssue].
@immutable
class FeedbackIssue {
  /// [EndAspect] or [CustomAspect].
  final FeedbackAspect aspect;
  final String label;
  final String? hint;

  const FeedbackIssue._(this.aspect, this.label, this.hint);

  /// "Front: Harsh".
  FeedbackIssue.end(EndAspect aspect)
    : this._(aspect, '${aspect.end.label}: ${aspect.attribute.problemLabel}', aspect.attribute.hint);

  FeedbackIssue.custom(CustomIssue issue) : this._(issue.aspect, issue.label, null);

  @override
  bool operator ==(Object other) =>
      other is FeedbackIssue && other.aspect == aspect && other.label == label && other.hint == hint;

  @override
  int get hashCode => Object.hash(aspect, label, hint);

  @override
  String toString() => 'FeedbackIssue($aspect, $label)';
}
