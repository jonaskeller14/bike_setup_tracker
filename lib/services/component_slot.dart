import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import 'component_hierarchy_resolver.dart';

/// The position a component fills on a bike: its own type plus the type of
/// its direct parent (`null` when mounted directly on the bike).
class ComponentSlot {
  final ComponentType type;
  final ComponentType? parentType;

  const ComponentSlot({required this.type, this.parentType});

  String get label => parentType == null ? type.label : '${type.label} (${parentType!.label})';

  @override
  bool operator ==(Object other) => other is ComponentSlot && other.type == type && other.parentType == parentType;

  @override
  int get hashCode => Object.hash(type, parentType);
}

/// The slot of [component] at [atUTC], or `null` if it is uninstalled or
/// archived at that time. The parent is resolved at [atUTC] because a parent
/// can move (e.g. tire rotation) without the component's own record changing.
ComponentSlot? slotAt(ComponentHierarchyResolver hierarchy, Component component, DateTime atUTC) {
  return switch (hierarchy.ancestorsAt(component.id, atUTC).firstOrNull) {
    ParentComponentAncestor(component: final parent) => ComponentSlot(
      type: component.componentType,
      parentType: parent.componentType,
    ),
    UninstalledAncestor() || ArchivedAncestor() => null,
    BikeAncestor() || MissingParentAncestor() || null => ComponentSlot(type: component.componentType),
  };
}
