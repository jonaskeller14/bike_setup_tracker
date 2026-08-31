import '../models/installation.dart';

bool isComplexInstallationTimeline(List<Installation> installations) =>
    installations.length > 1 ||
    (installations.isNotEmpty && installations.first.dateTimeUTC.millisecondsSinceEpoch > 0);

bool shouldUseInstallationTimeline({
  required bool featureEnabled,
  required List<Installation> installations,
}) =>
    featureEnabled || isComplexInstallationTimeline(installations);

String? validateInstallationTimeline(List<Installation> installations) {
  if (installations.isEmpty) {
    return 'At least one entry is required';
  }

  final sorted = List<Installation>.from(installations)
    ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

  for (int i = 0; i < sorted.length; i++) {
    final current = sorted[i];

    if (i < sorted.length - 1) {
      if (current is Archival) {
        return 'Archival can only be the last entry in the timeline';
      }
      final next = sorted[i + 1];
      if (current is Uninstallation && next is Uninstallation) {
        return 'Cannot have consecutive uninstallations';
      }
      if (current is BikeInstallation && next is BikeInstallation && current.bikeId == next.bikeId) {
        return 'Cannot have consecutive installations on the same bike';
      }
    }
  }

  final fromBeginningCount = sorted.where((e) => e.dateTimeUTC.millisecondsSinceEpoch == 0).length;
  if (fromBeginningCount > 1) {
    return 'Multiple "From beginning" entries are not allowed';
  }

  return null;
}

bool isValidInstallationTimeline(List<Installation> installations) =>
    validateInstallationTimeline(installations) == null;
