import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';
import '../l10n/enum_labels.dart';
import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import 'component_hierarchy_resolver.dart';

/// The position a component fills on a bike: its own type plus the type of
/// its direct parent (`null` when mounted directly on the bike).
@immutable
class ComponentSlot {
  final ComponentType type;
  final ComponentType? parentType;

  const ComponentSlot({required this.type, this.parentType});

  String label(AppLocalizations l10n) =>
      parentType == null ? type.label(l10n) : '${type.label(l10n)} (${parentType!.label(l10n)})';

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

/// The slot of [component] on [bikeId] at [atUTC], or `null` when it was not
/// on that bike then (e.g. a setup value it no longer belongs to).
ComponentSlot? slotOnBikeAt(
  ComponentHierarchyResolver hierarchy,
  Component component, {
  required String bikeId,
  required DateTime atUTC,
}) {
  if (hierarchy.bikeAt(component.id, atUTC) != bikeId) return null;
  return slotAt(hierarchy, component, atUTC);
}

int compareSlots(ComponentSlot a, ComponentSlot b) {
  final byType = a.type.index.compareTo(b.type.index);
  if (byType != 0) return byType;
  return (a.parentType?.index ?? -1).compareTo(b.parentType?.index ?? -1);
}
