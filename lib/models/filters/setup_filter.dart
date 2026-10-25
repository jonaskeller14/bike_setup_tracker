import 'package:flutter/foundation.dart';

import '../feedback/test_session.dart';
import '../setup.dart';

/// The setup criteria besides the bike scope, which is held separately so views
/// that are already scoped to one bike can apply just these.
@immutable
class SetupFilter {
  final Set<String> tags;
  final bool bookmarkedOnly;
  final Set<String> testSessionNames;

  const SetupFilter({this.tags = const {}, this.bookmarkedOnly = false, this.testSessionNames = const {}});

  bool get isActive => tags.isNotEmpty || bookmarkedOnly || testSessionNames.isNotEmpty;

  bool matches(Setup setup, {Map<String, TestSession> testSessions = const {}}) =>
      setup.tags.containsAll(tags) &&
      (!bookmarkedOnly || setup.isBookmarked) &&
      (testSessionNames.isEmpty || testSessionNames.contains(testSessions[setup.testSessionId]?.displayName));

  Map<String, Object?> toJson() => {
    'tags': tags.toList(),
    'bookmarkedOnly': bookmarkedOnly,
    'testSessionNames': testSessionNames.toList(),
  };

  factory SetupFilter.fromJson(Map<String, Object?> json) => SetupFilter(
    tags: (json['tags'] as List<Object?>? ?? const []).whereType<String>().toSet(),
    bookmarkedOnly: json['bookmarkedOnly'] as bool? ?? false,
    testSessionNames: (json['testSessionNames'] as List<Object?>? ?? const []).whereType<String>().toSet(),
  );

  SetupFilter copyWith({Set<String>? tags, bool? bookmarkedOnly, Set<String>? testSessionNames}) => SetupFilter(
    tags: tags ?? this.tags,
    bookmarkedOnly: bookmarkedOnly ?? this.bookmarkedOnly,
    testSessionNames: testSessionNames ?? this.testSessionNames,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupFilter &&
          setEquals(tags, other.tags) &&
          bookmarkedOnly == other.bookmarkedOnly &&
          setEquals(testSessionNames, other.testSessionNames);

  @override
  int get hashCode =>
      Object.hash(Object.hashAllUnordered(tags), bookmarkedOnly, Object.hashAllUnordered(testSessionNames));
}
