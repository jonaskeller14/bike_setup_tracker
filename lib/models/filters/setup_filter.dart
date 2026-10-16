import 'package:flutter/foundation.dart';

import '../setup.dart';

/// The setup criteria besides the bike scope, which is held separately so views
/// that are already scoped to one bike can apply just these.
@immutable
class SetupFilter {
  final Set<String> tags;
  final bool bookmarkedOnly;

  const SetupFilter({this.tags = const {}, this.bookmarkedOnly = false});

  bool get isActive => tags.isNotEmpty || bookmarkedOnly;

  bool matches(Setup setup) => setup.tags.containsAll(tags) && (!bookmarkedOnly || setup.isBookmarked);

  Map<String, Object?> toJson() => {'tags': tags.toList(), 'bookmarkedOnly': bookmarkedOnly};

  factory SetupFilter.fromJson(Map<String, Object?> json) => SetupFilter(
    tags: (json['tags'] as List<Object?>? ?? const []).whereType<String>().toSet(),
    bookmarkedOnly: json['bookmarkedOnly'] as bool? ?? false,
  );

  SetupFilter copyWith({Set<String>? tags, bool? bookmarkedOnly}) =>
      SetupFilter(tags: tags ?? this.tags, bookmarkedOnly: bookmarkedOnly ?? this.bookmarkedOnly);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetupFilter && setEquals(tags, other.tags) && bookmarkedOnly == other.bookmarkedOnly;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(tags), bookmarkedOnly);
}
