import 'package:flutter/foundation.dart';

enum TimelineLayer { setups, activities, tasks, installations, feedback }

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

  Map<String, Object?> toJson() => {'hidden': [for (final layer in hidden) layer.name]};

  /// Skips layer names this version does not know.
  factory LayerFilter.fromJson(Map<String, Object?> json) {
    final names = (json['hidden'] as List<Object?>? ?? const []).toSet();
    return LayerFilter(hidden: TimelineLayer.values.where((layer) => names.contains(layer.name)).toSet());
  }

  LayerFilter copyWith({Set<TimelineLayer>? hidden}) => LayerFilter(hidden: hidden ?? this.hidden);

  @override
  bool operator ==(Object other) => identical(this, other) || other is LayerFilter && setEquals(hidden, other.hidden);

  @override
  int get hashCode => Object.hashAllUnordered(hidden);
}
