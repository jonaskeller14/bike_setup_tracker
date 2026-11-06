import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';

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

  String label(Map<String, Bike> bikes, AppLocalizations l10n) => switch (this) {
    ParentComponentAncestor(:final component) => component.name,
    MissingParentAncestor() => l10n.componentNotFound,
    BikeAncestor(:final bikeId) => bikes[bikeId]?.name ?? l10n.bikeNotFound,
    ArchivedAncestor() => l10n.timelineArchived,
    UninstalledAncestor() => l10n.timelineNotInstalled,
  };
}
