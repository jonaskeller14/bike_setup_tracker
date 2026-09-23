import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../services/component_hierarchy_resolver.dart';

bool isComplexInstallationTimeline(List<Installation> installations) =>
    installations.length > 1 ||
    installations.any((i) => i is ComponentInstallation) ||
    (installations.isNotEmpty && installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);

bool shouldUseInstallationTimeline({
  required bool featureEnabled,
  required List<Installation> installations,
}) =>
    featureEnabled || isComplexInstallationTimeline(installations);

class InstallationTimelineIssue {
  final String message;
  final Set<int> dateTimeIndices;
  final Set<int> parentIndices;

  const InstallationTimelineIssue({
    required this.message,
    this.dateTimeIndices = const {},
    this.parentIndices = const {},
  });
}

InstallationTimelineIssue? installationTimelineIssue(
  List<Installation> installations, {
  String? componentId,
  Map<String, Component>? components,
  Map<String, Bike>? bikes,
}) {
  if (installations.isEmpty) {
    return const InstallationTimelineIssue(message: 'At least one entry is required');
  }

  final order = List<int>.generate(installations.length, (i) => i)
    ..sort((a, b) => installations[a].dateTimeUTC.compareTo(installations[b].dateTimeUTC));

  for (int i = 0; i < order.length - 1; i++) {
    final current = installations[order[i]];
    final next = installations[order[i + 1]];

    if (current is Archival) {
      return InstallationTimelineIssue(
        message: 'Archival can only be the last entry in the timeline',
        parentIndices: {order[i]},
      );
    }
    if (current is Uninstallation && next is Uninstallation) {
      return InstallationTimelineIssue(
        message: 'Cannot have consecutive uninstallations',
        parentIndices: {order[i], order[i + 1]},
      );
    }
    if (current is BikeInstallation && next is BikeInstallation && current.bikeId == next.bikeId) {
      return InstallationTimelineIssue(
        message: 'Cannot have consecutive installations on the same bike',
        parentIndices: {order[i], order[i + 1]},
      );
    }
    if (current is ComponentInstallation &&
        next is ComponentInstallation &&
        current.parentComponentId == next.parentComponentId) {
      return InstallationTimelineIssue(
        message: 'Cannot have consecutive installations on the same component',
        parentIndices: {order[i], order[i + 1]},
      );
    }
  }

  final fromBeginning =
      order.where((i) => installations[i].dateTimeUTC.millisecondsSinceEpoch == 0).toSet();
  if (fromBeginning.length > 1) {
    return InstallationTimelineIssue(
      message: 'Multiple "From beginning" entries are not allowed',
      dateTimeIndices: fromBeginning,
    );
  }

  for (int i = 0; i < order.length - 1; i++) {
    final at = installations[order[i]].dateTimeUTC;
    if (at == installations[order[i + 1]].dateTimeUTC) {
      return InstallationTimelineIssue(
        message: 'Two entries cannot have the same date & time',
        dateTimeIndices: order.where((j) => installations[j].dateTimeUTC == at).toSet(),
      );
    }
  }

  if (bikes != null) {
    for (int index = 0; index < installations.length; index++) {
      final installation = installations[index];
      if (installation is BikeInstallation && !bikes.containsKey(installation.bikeId)) {
        return InstallationTimelineIssue(
          message: 'This entry is installed on a bike that no longer exists',
          parentIndices: {index},
        );
      }
    }
  }

  if (componentId != null && components != null) {
    return _hierarchyIssue(installations, componentId, components);
  }

  return null;
}

/// Checks the links that need the other components to resolve.
///
/// A component that does not exist yet cannot be anyone's parent, so callers
/// editing a new component pass no id and skip this entirely.
InstallationTimelineIssue? _hierarchyIssue(
  List<Installation> installations,
  String componentId,
  Map<String, Component> components,
) {
  final resolver = ComponentHierarchyResolver(components);

  for (int index = 0; index < installations.length; index++) {
    final installation = installations[index];
    if (installation is! ComponentInstallation) continue;

    if (installation.parentComponentId == componentId) {
      return InstallationTimelineIssue(
        message: 'A component cannot be installed on itself',
        parentIndices: {index},
      );
    }

    // Walk the ancestors as they stand at this row's instant; arriving back at
    // the edited component closes a loop. The visited set also terminates on a
    // loop further up that this component is not part of.
    final visited = <String>{};
    var currentId = installation.parentComponentId;
    while (visited.add(currentId)) {
      if (currentId == componentId) {
        return InstallationTimelineIssue(
          message: 'This installation creates a loop of components',
          parentIndices: {index},
        );
      }
      final parent = components[currentId];
      // An unknown parent is kept as off-bike history, not rejected.
      if (parent == null) break;
      final parentInstallation = resolver.installationAt(parent, installation.dateTimeUTC);
      if (parentInstallation is! ComponentInstallation) break;
      currentId = parentInstallation.parentComponentId;
    }
  }

  return null;
}

/// The instant to stamp on a newly recorded event: [now] (default:
/// `DateTime.now()`) truncated to the minute, pushed forward to the next free
/// minute when [installations] already occupies it. Entries sharing an instant
/// are rejected by [installationTimelineIssue], and a drag-and-drop landing
/// in the same minute as the previous event should not open a sheet that is
/// already invalid.
({DateTime utc, DateTime local}) stampInstallationNow(
  List<Installation> installations, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final utc = Installation.truncateToMinute(at.toUtc());
  final local = Installation.truncateToMinute(at);

  final taken = installations.map((e) => e.dateTimeUTC).toSet();
  int offset = 0;
  while (taken.contains(utc.add(Duration(minutes: offset)))) {
    offset++;
  }
  if (offset == 0) return (utc: utc, local: local);

  return (
    utc: utc.add(Duration(minutes: offset)),
    // Shift the floating local face value by the same number of minutes without
    // going through absolute time, which a DST jump would distort.
    local: DateTime(local.year, local.month, local.day, local.hour, local.minute + offset),
  );
}

bool isValidInstallationTimeline(List<Installation> installations) =>
    installationTimelineIssue(installations) == null;
