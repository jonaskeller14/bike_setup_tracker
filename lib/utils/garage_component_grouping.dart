import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import '../models/component/installation.dart';
import '../services/component_hierarchy_resolver.dart';

class GarageComponentGroupData {
  final Component parent;
  final List<Component> children;  // flattened depth-first

  const GarageComponentGroupData({
    required this.parent,
    this.children = const [],
  });

  bool get isGroup => children.isNotEmpty;

  List<Component> get components => [parent, ...children];
}

List<GarageComponentGroupData> garageGroupsFor(
  Iterable<Component> sectionComponents, {
  required ComponentHierarchyResolver hierarchy,
}) {
  final section = <String, Component>{for (final component in sectionComponents) component.id: component};
  if (section.isEmpty) return const [];

  final childrenOf = <String, List<Component>>{};
  final roots = <Component>[];
  for (final component in section.values) {
    final parentId = _sectionParentIdOf(
      component,
      section: section,
      hierarchy: hierarchy,
    );
    if (parentId == null) {
      roots.add(component);
    } else {
      (childrenOf[parentId] ??= []).add(component);
    }
  }

  _sortByOrderIndex(roots);
  for (final children in childrenOf.values) {
    _sortByOrderIndex(children);
  }

  final groups = <GarageComponentGroupData>[];
  final visited = <String>{};
  for (final root in roots) {
    if (!visited.add(root.id)) continue;
    final descendants = <Component>[];
    _flattenInto(root, childrenOf, visited, descendants);
    groups.add(GarageComponentGroupData(parent: root, children: descendants));
  }
  return groups;
}

Component? currentParentComponentOf(
  String componentId, {
  required ComponentHierarchyResolver hierarchy,
}) {
  final ancestors = hierarchy.currentAncestors(componentId);
  if (ancestors.isEmpty) return null;
  final nearest = ancestors.first;
  return nearest is ParentComponentAncestor ? nearest.component : null;
}

String? _sectionParentIdOf(
  Component component, {
  required Map<String, Component> section,
  required ComponentHierarchyResolver hierarchy,
}) {
  final installation = hierarchy.installationAt(component, hierarchy.currentTimeUTC);
  if (installation is! ComponentInstallation) return null;
  final parentId = installation.parentComponentId;
  if (!section.containsKey(parentId)) return null;
  // Legacy and imported data can contain installation cycles; such a component
  // roots its own group rather than looping the display.
  if (hierarchy.resolveCurrent(component.id).isCyclic) return null;
  return parentId;
}

void _flattenInto(
  Component parent,
  Map<String, List<Component>> childrenOf,
  Set<String> visited,
  List<Component> out,
) {
  for (final child in childrenOf[parent.id] ?? const <Component>[]) {
    if (!visited.add(child.id)) continue;
    out.add(child);
    _flattenInto(child, childrenOf, visited, out);
  }
}

void _sortByOrderIndex(List<Component> components) => components.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
