import '../models/bike.dart';
import '../models/component_ancestor.dart';
import '../services/component_hierarchy_resolver.dart';
import '../widgets/component_ancestor_display.dart';

enum InstallationIssue { missingBike, missingParent }

extension InstallationIssueDisplay on InstallationIssue {
  String get label => switch (this) {
    InstallationIssue.missingBike => 'Bike not found',
    InstallationIssue.missingParent => 'Parent component not found',
  };
}

InstallationIssue? installationIssueOf(
  String componentId, {
  required ComponentHierarchyResolver hierarchy,
  required Map<String, Bike> bikes,
}) {
  final ancestors = hierarchy.currentAncestors(componentId);
  if (ancestors.isEmpty) return null;

  final nearest = ancestors.first;
  if (!nearest.isMissing(bikes)) return null;

  return nearest is BikeAncestor ? InstallationIssue.missingBike : InstallationIssue.missingParent;
}
