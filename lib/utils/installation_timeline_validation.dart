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

  for (int i = 0; i < sorted.length - 1; i++) {
    if (sorted[i].dateTimeUTC == sorted[i + 1].dateTimeUTC) {
      return 'Two entries cannot have the same date & time';
    }
  }

  return null;
}

/// The instant to stamp on a newly recorded event: [now] (default:
/// `DateTime.now()`) truncated to the minute, pushed forward to the next free
/// minute when [installations] already occupies it. Entries sharing an instant
/// are rejected by [validateInstallationTimeline], and a drag-and-drop landing
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
    validateInstallationTimeline(installations) == null;
