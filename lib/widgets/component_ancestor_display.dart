import 'package:flutter/material.dart';

import '../models/bike.dart';
import '../models/component.dart';
import '../models/component_ancestor.dart';

extension ComponentAncestorDisplay on ComponentAncestor {
  bool isMissing(Map<String, Bike> bikes) => switch (this) {
    MissingParentAncestor() => true,
    BikeAncestor(:final bikeId) => !bikes.containsKey(bikeId),
    _ => false,
  };

  IconData get iconData => switch (this) {
    ParentComponentAncestor(:final component) => component.componentType.getIconData(),
    MissingParentAncestor() => Component.iconData,
    BikeAncestor() => Bike.iconData,
    ArchivedAncestor() => Icons.inventory_2_outlined,
    UninstalledAncestor() => Icons.shelves,
  };

  String label(Map<String, Bike> bikes) => switch (this) {
    ParentComponentAncestor(:final component) => component.name,
    MissingParentAncestor() => 'COMPONENT NOT FOUND',
    BikeAncestor(:final bikeId) => bikes[bikeId]?.name ?? 'BIKE NOT FOUND',
    ArchivedAncestor() => 'Archived',
    UninstalledAncestor() => 'Not installed',
  };
}
