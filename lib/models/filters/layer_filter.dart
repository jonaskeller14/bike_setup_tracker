import 'package:flutter/foundation.dart';

enum TimelineLayer { setups, activities, tasks, installations, ratingEntries }

/// The layers the user has hidden. Whether a layer's feature is enabled at all
/// stays with the caller.
@immutable
class LayerFilter {
  final Set<TimelineLayer> hidden;

  const LayerFilter({this.hidden = const {}});

  bool shows(TimelineLayer layer) => !hidden.contains(layer);

  /// Whether one of the [available] layers is hidden. A hidden layer whose
  /// feature is off is not offered to the user, so it does not count as a filter.
  bool isActiveFor(Set<TimelineLayer> available) => hidden.any(available.contains);

  LayerFilter copyWith({Set<TimelineLayer>? hidden}) => LayerFilter(hidden: hidden ?? this.hidden);

  @override
  bool operator ==(Object other) => identical(this, other) || other is LayerFilter && setEquals(hidden, other.hidden);

  @override
  int get hashCode => Object.hashAllUnordered(hidden);
}
