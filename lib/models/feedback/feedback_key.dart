import 'package:flutter/foundation.dart';

import 'feedback_vocabulary.dart';

/// Semantic key of a feedback observation. Keys are a stored contract: keys
/// this version doesn't know parse as [UnknownFeedbackKey] and are kept.
@immutable
sealed class FeedbackKey {
  const FeedbackKey();

  String get raw;

  static const String _issuePrefix = 'issue.';

  static FeedbackKey parse(String raw) {
    if (raw == NoIssueKey._raw) return const NoIssueKey();
    if (raw.startsWith(_issuePrefix)) {
      final aspect = FeedbackAspect.parse(raw.substring(_issuePrefix.length));
      if (aspect is EndAspect) return IssueKey(aspect.end, aspect.attribute);
      if (aspect is CustomAspect) return CustomIssueKey(aspect.slug);
    }
    return UnknownFeedbackKey(raw);
  }

  @override
  bool operator ==(Object other) => other is FeedbackKey && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  @override
  String toString() => raw;
}

/// A problem felt at one end of the bike: `issue.<end>.<attribute>`.
final class IssueKey extends FeedbackKey {
  final FeedbackEnd end;
  final FeedbackAttribute attribute;

  const IssueKey(this.end, this.attribute);

  EndAspect get aspect => EndAspect(end, attribute);

  @override
  String get raw => '${FeedbackKey._issuePrefix}${aspect.raw}';
}

/// A rider-defined problem: `issue.custom:<slug>`, its label in the
/// observation's text value.
final class CustomIssueKey extends FeedbackKey {
  final String slug;

  const CustomIssueKey(this.slug);

  CustomAspect get aspect => CustomAspect(slug);

  @override
  String get raw => '${FeedbackKey._issuePrefix}${aspect.raw}';
}

/// "Nothing stood out": tells "felt right" apart from "didn't answer".
final class NoIssueKey extends FeedbackKey {
  static const String _raw = 'issue.none';

  const NoIssueKey();

  @override
  String get raw => _raw;
}

final class UnknownFeedbackKey extends FeedbackKey {
  @override
  final String raw;

  const UnknownFeedbackKey(this.raw);
}

/// What a comparison or session goal refers to: [OverallAspect], an
/// end + attribute ([EndAspect]) or a rider-defined [CustomAspect]. Unknown
/// aspects parse as [UnknownAspect].
@immutable
sealed class FeedbackAspect {
  const FeedbackAspect();

  String get raw;

  /// Allowed comparison outcomes; `null` when this version doesn't know them.
  ({int min, int max})? get outcomeRange;

  bool isValidOutcome(int outcome) => switch (outcomeRange) {
    (:final min, :final max) => outcome >= min && outcome <= max,
    null => true,
  };

  static FeedbackAspect parse(String raw) {
    if (raw == OverallAspect._raw) return const OverallAspect();
    if (raw.startsWith(CustomAspect._prefix) && raw.length > CustomAspect._prefix.length) {
      return CustomAspect(raw.substring(CustomAspect._prefix.length));
    }
    final parts = raw.split('.');
    if (parts.length == 2) {
      final end = FeedbackEnd.values.asNameMap()[parts[0]];
      final attribute = FeedbackAttribute.values.asNameMap()[parts[1]];
      if (end != null && attribute != null) return EndAspect(end, attribute);
    }
    return UnknownAspect(raw);
  }

  @override
  bool operator ==(Object other) => other is FeedbackAspect && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  @override
  String toString() => raw;
}

final class OverallAspect extends FeedbackAspect {
  static const String _raw = 'overall';

  const OverallAspect();

  @override
  String get raw => _raw;

  @override
  ({int min, int max}) get outcomeRange => (min: -2, max: 2);
}

final class EndAspect extends FeedbackAspect {
  final FeedbackEnd end;
  final FeedbackAttribute attribute;

  const EndAspect(this.end, this.attribute);

  /// All ten aspects, front before rear, in attribute order.
  static final List<EndAspect> values = List.unmodifiable([
    for (final end in FeedbackEnd.values)
      for (final attribute in FeedbackAttribute.values) EndAspect(end, attribute),
  ]);

  IssueKey get issueKey => IssueKey(end, attribute);

  @override
  String get raw => '${end.name}.${attribute.name}';

  @override
  ({int min, int max}) get outcomeRange => (min: -1, max: 1);
}

/// A rider-defined problem, `custom:<slug>`. It has no front or rear end.
final class CustomAspect extends FeedbackAspect {
  static const String _prefix = 'custom:';

  final String slug;

  const CustomAspect(this.slug);

  CustomIssueKey get issueKey => CustomIssueKey(slug);

  @override
  String get raw => '$_prefix$slug';

  @override
  ({int min, int max}) get outcomeRange => (min: -1, max: 1);
}

final class UnknownAspect extends FeedbackAspect {
  @override
  final String raw;

  const UnknownAspect(this.raw);

  @override
  ({int min, int max})? get outcomeRange => null;
}
