import '../models/component.dart';
import '../models/component_ancestor.dart';
import '../models/installation.dart';

class ComponentHierarchyValidationException implements Exception {
  final String message;
  final Set<String> componentIds;
  final DateTime? dateTimeUTC;

  const ComponentHierarchyValidationException(
    this.message, {
    this.componentIds = const {},
    this.dateTimeUTC,
  });

  @override
  String toString() => message;
}

class ComponentPlacement {
  final String? bikeId;
  final DateTime? effectiveSinceUTC;
  final bool isArchived;
  final bool isDeleted;
  final bool isDangling;
  final bool isCyclic;

  const ComponentPlacement({
    this.bikeId,
    this.effectiveSinceUTC,
    this.isArchived = false,
    this.isDeleted = false,
    this.isDangling = false,
    this.isCyclic = false,
  });

  ComponentPlacement withEffectiveSince(DateTime? value) => ComponentPlacement(
        bikeId: bikeId,
        effectiveSinceUTC: value,
        isArchived: isArchived,
        isDeleted: isDeleted,
        isDangling: isDangling,
        isCyclic: isCyclic,
      );
}

/// Resolves a component's effective placement through component parents.
///
/// Installation records remain the single source of truth: moving a parent
/// changes every descendant's effective bike without writing child events.
class ComponentHierarchyResolver {
  final Map<String, Component> components;
  final Set<String> deletedComponentIds;
  final DateTime currentTimeUTC;
  final Map<(String, int), ComponentPlacement> _placementCache = {};
  final Map<String, List<Installation>> _sortedInstallations = {};
  final Map<int, Map<String, Set<String>>> _childrenAtCache = {};
  Map<String, Set<String>>? _historicalChildren;

  ComponentHierarchyResolver(
    this.components, {
    this.deletedComponentIds = const {},
    DateTime? currentTimeUTC,
  }) : currentTimeUTC = (currentTimeUTC ?? DateTime.now()).toUtc();

  ComponentPlacement resolveAt(String componentId, DateTime atUTC) {
    final utc = atUTC.toUtc();
    return _resolveAt(componentId, utc, <String>{});
  }

  ComponentPlacement _resolveAt(
    String componentId,
    DateTime atUTC,
    Set<String> visiting,
  ) {
    final key = (componentId, atUTC.microsecondsSinceEpoch);
    final cached = _placementCache[key];
    if (cached != null) return cached;
    if (!visiting.add(componentId)) {
      return const ComponentPlacement(isCyclic: true);
    }

    late final ComponentPlacement result;
    if (deletedComponentIds.contains(componentId)) {
      result = const ComponentPlacement(isDeleted: true);
    } else {
      final component = components[componentId];
      if (component == null) {
        result = const ComponentPlacement(isDangling: true);
      } else {
        final installation = installationAt(component, atUTC);
        result = switch (installation) {
          null || Uninstallation() => const ComponentPlacement(),
          BikeInstallation(:final bikeId) => ComponentPlacement(
              bikeId: bikeId,
              effectiveSinceUTC: installation.dateTimeUTC,
            ),
          Archival() => ComponentPlacement(
              effectiveSinceUTC: installation.dateTimeUTC,
              isArchived: true,
            ),
          ComponentInstallation(:final parentComponentId) => () {
              final parentPlacement = _resolveAt(parentComponentId, atUTC, visiting);
              final parentSince = parentPlacement.effectiveSinceUTC;
              final effectiveSince = parentSince == null ||
                      installation.dateTimeUTC.isAfter(parentSince)
                  ? installation.dateTimeUTC
                  : parentSince;
              return parentPlacement.withEffectiveSince(effectiveSince);
            }(),
        };
      }
    }

    visiting.remove(componentId);
    _placementCache[key] = result;
    return result;
  }

  ComponentPlacement resolveCurrent(String componentId) =>
      resolveAt(componentId, currentTimeUTC);

  String? bikeAt(String componentId, DateTime atUTC) =>
      resolveAt(componentId, atUTC).bikeId;

  String? currentBike(String componentId) => resolveCurrent(componentId).bikeId;

  List<ComponentAncestor> ancestorsAt(String componentId, DateTime atUTC) {
    final utc = atUTC.toUtc();
    final ancestors = <ComponentAncestor>[];
    final visited = {componentId};
    var current = components[componentId];
    while (current != null) {
      switch (installationAt(current, utc)) {
        case ComponentInstallation(:final parentComponentId):
          final parent = deletedComponentIds.contains(parentComponentId) ? null : components[parentComponentId];
          if (parent == null) return ancestors..add(MissingParentAncestor(parentComponentId));
          if (!visited.add(parent.id)) return ancestors;
          ancestors.add(ParentComponentAncestor(parent));
          current = parent;
        case BikeInstallation(:final bikeId):
          return ancestors..add(BikeAncestor(bikeId));
        case Archival():
          return ancestors..add(const ArchivedAncestor());
        case Uninstallation() || null:
          return ancestors..add(const UninstalledAncestor());
      }
    }
    return ancestors;
  }

  List<ComponentAncestor> currentAncestors(String componentId) =>
      ancestorsAt(componentId, currentTimeUTC);

  /// The top of the hierarchy: the bike, or whatever ends the chain when the
  /// component is not on one. Never a [ParentComponentAncestor].
  ComponentAncestor rootAt(String componentId, DateTime atUTC) =>
      ancestorsAt(componentId, atUTC).lastWhere(
        (ancestor) => ancestor is! ParentComponentAncestor,
        orElse: () => const UninstalledAncestor(),
      );

  ComponentAncestor currentRoot(String componentId) =>
      rootAt(componentId, currentTimeUTC);

  DateTime? effectiveBikeSinceAt(String componentId, DateTime atUTC) =>
      switch (resolveAt(componentId, atUTC)) {
        ComponentPlacement(:final bikeId, :final effectiveSinceUTC)
            when bikeId != null => effectiveSinceUTC,
        _ => null,
      };

  bool isEffectivelyArchived(String componentId, {DateTime? atUTC}) =>
      resolveAt(componentId, atUTC ?? currentTimeUTC).isArchived;

  bool isEffectivelyDeleted(String componentId) =>
      resolveCurrent(componentId).isDeleted;

  Installation? installationAt(Component component, DateTime atUTC) {
    final sorted = _sortedInstallations.putIfAbsent(
      component.id,
      () => List<Installation>.from(component.installations)
        ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC)),
    );
    var low = 0;
    var high = sorted.length - 1;
    Installation? result;
    while (low <= high) {
      final middle = (low + high) >> 1;
      final candidate = sorted[middle];
      if (candidate.dateTimeUTC.isAfter(atUTC)) {
        high = middle - 1;
      } else {
        result = candidate;
        low = middle + 1;
      }
    }
    return result;
  }

  Set<String> descendantsOf(String parentComponentId, {DateTime? atUTC}) {
    final when = (atUTC ?? currentTimeUTC).toUtc();
    final children = _childrenAtCache.putIfAbsent(
      when.microsecondsSinceEpoch,
      () => _childrenAt(when),
    );
    return _descendantsFrom(parentComponentId, children);
  }

  Map<String, Set<String>> _childrenAt(DateTime atUTC) {
    final children = <String, Set<String>>{};
    for (final component in components.values) {
      final installation = installationAt(component, atUTC);
      if (installation is ComponentInstallation) {
        (children[installation.parentComponentId] ??= <String>{}).add(component.id);
      }
    }
    return children;
  }

  Set<String> _descendantsFrom(
    String parentComponentId,
    Map<String, Set<String>> children,
  ) {
    final descendants = <String>{};
    var frontier = <String>{parentComponentId};
    while (frontier.isNotEmpty) {
      final next = <String>{};
      for (final current in frontier) {
        for (final child in children[current] ?? const <String>{}) {
          if (child != parentComponentId && descendants.add(child)) {
            next.add(child);
          }
        }
      }
      frontier = next;
    }
    return descendants;
  }

  Set<String> historicalDescendantsOf(String parentComponentId) {
    final children = _historicalChildren ??= () {
      final result = <String, Set<String>>{};
      for (final component in components.values) {
        for (final installation in component.installations) {
          if (installation is ComponentInstallation) {
            (result[installation.parentComponentId] ??= <String>{}).add(component.id);
          }
        }
      }
      return result;
    }();
    return _descendantsFrom(parentComponentId, children);
  }

  void validate() {
    final boundaries = <DateTime>{};
    for (final component in components.values) {
      final timestamps = <DateTime>{};
      for (final installation in component.installations) {
        if (!timestamps.add(installation.dateTimeUTC)) {
          throw ComponentHierarchyValidationException(
            'Component ${component.id} has multiple installation events at the same time.',
            componentIds: {component.id},
            dateTimeUTC: installation.dateTimeUTC,
          );
        }
        boundaries.add(installation.dateTimeUTC);
      }
    }

    for (final boundary in boundaries) {
      for (final component in components.values) {
        final path = <String>[];
        final positions = <String, int>{};
        var currentId = component.id;
        while (true) {
          final previousPosition = positions[currentId];
          if (previousPosition != null) {
            final cycle = path.sublist(previousPosition).toSet()..add(currentId);
            throw ComponentHierarchyValidationException(
              'Component installation cycle detected.',
              componentIds: cycle,
              dateTimeUTC: boundary,
            );
          }
          positions[currentId] = path.length;
          path.add(currentId);

          final current = components[currentId];
          if (current == null) break;
          final installation = installationAt(current, boundary);
          if (installation is! ComponentInstallation) break;
          currentId = installation.parentComponentId;
        }
      }
    }
  }
}
