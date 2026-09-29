import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import '../models/component/installation.dart';
import '../services/component_hierarchy_resolver.dart';

/// A period in which a component is effectively on one bike through the same
/// direct parent. [parentComponentId] is null when it sits directly on the
/// bike; open-ended periods have no end.
class TimelineInterval {
  final String componentId;
  final DateTime startUTC;
  final DateTime startLocal;
  final DateTime? endUTC;
  final DateTime? endLocal;
  final String? parentComponentId;

  const TimelineInterval({
    required this.componentId,
    required this.startUTC,
    required this.startLocal,
    this.endUTC,
    this.endLocal,
    this.parentComponentId,
  });

  bool get isNested => parentComponentId != null;
}

/// Every component's effective intervals on [bikeId], split whenever the
/// direct parent changes. Components never on the bike are omitted.
Map<String, List<TimelineInterval>> effectiveBikeIntervals(
  ComponentHierarchyResolver resolver,
  Iterable<Component> components,
  String bikeId,
) {
  final result = <String, List<TimelineInterval>>{};
  for (final component in components) {
    final intervals = _intervalsFor(resolver, component, bikeId);
    if (intervals.isNotEmpty) result[component.id] = intervals;
  }
  return result;
}

List<TimelineInterval> _intervalsFor(
  ComponentHierarchyResolver resolver,
  Component component,
  String bikeId,
) {
  // Own events first, so a same-instant ancestor event can't override the
  // component's own local time.
  final localByUTC = <DateTime, DateTime>{};
  for (final installation in [
    ...component.installations,
    for (final ancestorId in _historicalAncestorIds(resolver, component))
      ...?resolver.components[ancestorId]?.installations,
  ]) {
    localByUTC.putIfAbsent(installation.dateTimeUTC, () => installation.dateTimeLocal);
  }
  final times = localByUTC.keys.toList()..sort();

  final intervals = <TimelineInterval>[];
  ({DateTime startUTC, DateTime startLocal, String? parentId})? open;
  for (final atUTC in times) {
    final onBike = resolver.bikeAt(component.id, atUTC) == bikeId;
    final parentId = onBike
        ? switch (resolver.ancestorsAt(component.id, atUTC).firstOrNull) {
            ParentComponentAncestor(component: final parent) => parent.id,
            _ => null,
          }
        : null;
    if (open != null && onBike && open.parentId == parentId) continue;

    if (open != null) {
      intervals.add(
        TimelineInterval(
          componentId: component.id,
          startUTC: open.startUTC,
          startLocal: open.startLocal,
          endUTC: atUTC,
          endLocal: localByUTC[atUTC],
          parentComponentId: open.parentId,
        ),
      );
    }
    open = onBike ? (startUTC: atUTC, startLocal: localByUTC[atUTC]!, parentId: parentId) : null;
  }
  if (open != null) {
    intervals.add(
      TimelineInterval(
        componentId: component.id,
        startUTC: open.startUTC,
        startLocal: open.startLocal,
        parentComponentId: open.parentId,
      ),
    );
  }
  return intervals;
}

/// Every component [component] has ever been installed on, directly or
/// through one of those parents.
Set<String> _historicalAncestorIds(
  ComponentHierarchyResolver resolver,
  Component component,
) {
  final ancestorIds = <String>{};
  final frontier = [
    for (final installation in component.installations)
      if (installation is ComponentInstallation) installation.parentComponentId,
  ];
  while (frontier.isNotEmpty) {
    final id = frontier.removeLast();
    if (id == component.id || !ancestorIds.add(id)) continue;
    for (final installation in resolver.components[id]?.installations ?? const <Installation>[]) {
      if (installation is ComponentInstallation) frontier.add(installation.parentComponentId);
    }
  }
  return ancestorIds;
}
