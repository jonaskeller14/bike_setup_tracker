import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/component_installation.dart';
import '../models/installation.dart';
import '../models/strava/strava_activity.dart';
import '../models/timeline_entry.dart';

const Duration kReplacementWindow = Duration(minutes: 5);
const Duration kSetupGroupWindow = Duration(hours: 2);

class StravaContext {
  final StravaActivity activity;
  final bool isFirst;
  final bool isLast;

  const StravaContext({
    required this.activity,
    this.isFirst = false,
    this.isLast = false,
  });
}

sealed class TimelineRow {
  /// Stable identity used to key the display widget, so element/State (e.g. a
  /// card's expand state, a Strava context wrapper) tracks the logical entry
  /// across the reordering an edit can cause — not the list index.
  Key get key;
}

class DayHeaderRow extends TimelineRow {
  final DateTime day;
  DayHeaderRow(this.day);

  @override
  Key get key => ValueKey('day:${day.millisecondsSinceEpoch}');
}

/// Base for rows that render timeline content (everything except headers).
sealed class EntryRow extends TimelineRow {
  /// Set by the annotation pass in [buildTimelineRows]; null when the row is
  /// not inside any loaded Strava activity's window.
  StravaContext? stravaContext;

  /// Local datetime used for day-header insertion. Grouped/replacement rows
  /// anchor to one representative event so they get exactly one header even
  /// when they straddle midnight.
  DateTime get anchorDateLocal;
}

class SingleEntryRow extends EntryRow {
  final TimelineEntry entry;
  SingleEntryRow(this.entry);

  @override
  Key get key => ValueKey('single:${timelineEntryId(entry)}');

  @override
  DateTime get anchorDateLocal => timelineEntryLocalDate(entry);
}

/// A run of adjacent same-bike setups recorded close together. [setups] keeps
/// display order (matching the surrounding sort direction).
class SetupGroupRow extends EntryRow {
  final List<SetupEntry> setups;
  SetupGroupRow(this.setups);

  @override
  Key get key => ValueKey('group:${setups.map((e) => e.setup.id).join('|')}');

  @override
  DateTime get anchorDateLocal => setups.first.setup.datetimeLocal;
}

/// A component replacement: [removed] (a [Uninstallation] or [Archival] that
/// came off the bike) and [installed] (a [BikeInstallation]) of the same
/// component type on the same bike within the replacement window.
class ReplacementRow extends EntryRow {
  final ComponentInstallation removed;
  final ComponentInstallation installed;
  ReplacementRow({required this.removed, required this.installed});

  @override
  Key get key =>
      ValueKey('repl:${removed.installation.id}:${installed.installation.id}');

  /// The earlier of the two events (matches the row's slot in the timeline).
  Installation get anchorInstallation =>
      removed.installation.dateTimeUTC.isAfter(
        installed.installation.dateTimeUTC,
      )
      ? installed.installation
      : removed.installation;

  @override
  DateTime get anchorDateLocal => anchorInstallation.dateTimeLocal;
}

bool _sameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Stable identity of a timeline entry, used to key its display row.
String timelineEntryId(TimelineEntry entry) => switch (entry) {
  SetupEntry(:final setup) => 'setup:${setup.id}',
  StravaEntry(:final activity) => 'strava:${activity.id}',
  TaskTimeLineEntry(:final taskEntry) => 'task:${taskEntry.id}',
  InstallationEntry(:final componentInstallation) =>
    'inst:${componentInstallation.installation.id}',
  RatingEntryTimelineEntry(:final ratingEntry) => 'rating:${ratingEntry.id}',
};

/// Local datetime of a timeline entry (for day grouping; sorting stays UTC).
DateTime timelineEntryLocalDate(TimelineEntry entry) => switch (entry) {
  SetupEntry(:final setup) => setup.datetimeLocal,
  StravaEntry(:final activity) => activity.startDateLocal,
  TaskTimeLineEntry(:final taskEntry) => taskEntry.dateTimeLocal,
  InstallationEntry(:final componentInstallation) =>
    componentInstallation.installation.dateTimeLocal,
  RatingEntryTimelineEntry(:final ratingEntry) => ratingEntry.dateTimeLocal,
};

/// Sorted index answering "which activity's window contains this instant" in
/// O(log n) instead of a scan over every loaded activity — the lookup runs per
/// timeline row, so with 1k+ loaded activities linear scans made list builds
/// quadratic.
class StravaActivityIndex {
  final List<StravaActivity> _byStart;

  /// Running max of window end over `_byStart[0..i]`; lets the backwards walk
  /// in [containing] stop as soon as no earlier activity can still reach the
  /// queried instant.
  final List<DateTime> _maxEndPrefix;

  StravaActivityIndex._(this._byStart, this._maxEndPrefix);

  factory StravaActivityIndex(Iterable<StravaActivity> activities) {
    final sorted = activities.toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final maxEnds = <DateTime>[];
    DateTime? runningMax;
    for (final activity in sorted) {
      final end = activity.startDate.add(activity.elapsedTime);
      if (runningMax == null || end.isAfter(runningMax)) runningMax = end;
      maxEnds.add(runningMax);
    }
    return StravaActivityIndex._(sorted, maxEnds);
  }

  /// The activity whose window `[startDate, startDate + elapsedTime]` contains
  /// [utc]. With overlapping activities the one starting latest (innermost)
  /// wins. Returns null when no activity contains [utc].
  StravaActivity? containing(DateTime utc) {
    // Last index with startDate <= utc.
    int lo = 0, hi = _byStart.length - 1, idx = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_byStart[mid].startDate.isAfter(utc)) {
        hi = mid - 1;
      } else {
        idx = mid;
        lo = mid + 1;
      }
    }
    // Walk towards earlier starts; the first hit is the innermost.
    for (var i = idx; i >= 0; i--) {
      if (_maxEndPrefix[i].isBefore(utc)) break;
      final activity = _byStart[i];
      if (!activity.startDate.add(activity.elapsedTime).isBefore(utc)) {
        return activity;
      }
    }
    return null;
  }
}

class ReplacementPair {
  final ComponentInstallation removed;
  final ComponentInstallation installed;
  const ReplacementPair({required this.removed, required this.installed});
}

class ReplacementPairing {
  /// Pairs keyed by the installation id of the *earlier* of the two events —
  /// the slot where the combined row is emitted.
  final Map<String, ReplacementPair> pairsByAnchorId;

  /// Installation ids of all paired events (both halves).
  final Set<String> consumedIds;

  const ReplacementPairing({
    required this.pairsByAnchorId,
    required this.consumedIds,
  });

  const ReplacementPairing.empty()
    : pairsByAnchorId = const {},
      consumedIds = const {};
}

/// Pairs each removal — a [Uninstallation] or an [Archival] that came off a
/// bike — with the nearest unconsumed [BikeInstallation] of the same component
/// type onto that same bike (different component) within [window]. The install
/// half may be a component's initial ("Added") install, so replacing with a
/// freshly created component whose only event is that bike install is detected.
/// Greedy over removals in chronological order, so the result is deterministic
/// and independent of display sort direction.
///
/// Never participates: since-beginning events, same-component moves, and an
/// initial install as the *removed* half (it has no bike to come off of).
ReplacementPairing pairReplacements(
  List<TimelineEntry> entries, {
  required Duration window,
}) {
  final installations =
      entries
          .whereType<InstallationEntry>()
          .map((e) => e.componentInstallation)
          .where((ci) => !ci.installation.isFromBeginning)
          .toList()
        ..sort(
          (a, b) =>
              a.installation.dateTimeUTC.compareTo(b.installation.dateTimeUTC),
        );

  final consumed = <String>{};
  final pairs = <String, ReplacementPair>{};

  for (final removed in installations) {
    // The old component leaves the bike either by deinstall or by archival;
    // a re-install onto a bike is never the removed half.
    if (removed.installation is BikeInstallation) continue;
    if (consumed.contains(removed.installation.id)) continue;
    // A replacement needs a bike the old component came off of.
    if (removed.originParentType != InstallationParentType.bike ||
        removed.originParent == null) {
      continue;
    }

    ComponentInstallation? best;
    Duration? bestDelta;
    for (final candidate in installations) {
      if (candidate.installation is! BikeInstallation) continue;
      if (consumed.contains(candidate.installation.id)) continue;
      // Same component going elsewhere is a move, not a replacement.
      if (candidate.component.id == removed.component.id) continue;
      if (candidate.component.componentType != removed.component.componentType) continue;
      if (candidate.installation.parent != removed.originParent) continue;
      final delta = candidate.installation.dateTimeUTC
          .difference(removed.installation.dateTimeUTC)
          .abs();
      if (delta > window) continue;
      if (best == null ||
          delta < bestDelta! ||
          (delta == bestDelta &&
              candidate.installation.id.compareTo(best.installation.id) < 0)) {
        best = candidate;
        bestDelta = delta;
      }
    }
    if (best == null) continue;

    consumed
      ..add(removed.installation.id)
      ..add(best.installation.id);
    final pair = ReplacementPair(removed: removed, installed: best);
    final anchorId =
        removed.installation.dateTimeUTC.isAfter(best.installation.dateTimeUTC)
        ? best.installation.id
        : removed.installation.id;
    pairs[anchorId] = pair;
  }
  return ReplacementPairing(pairsByAnchorId: pairs, consumedIds: consumed);
}

/// The Strava activities used as grouping context, empty when the feature is off.
StravaActivityIndex _contextIndex(
  List<TimelineEntry> entries,
  AppSettings appSettings,
) => StravaActivityIndex(
  appSettings.enableTimelineStravaContext
      ? entries.whereType<StravaEntry>().map((e) => e.activity)
      : const <StravaActivity>[],
);

StravaActivity? _contextOf(
  StravaActivityIndex activities,
  TimelineEntry entry,
) => entry is StravaEntry ? null : activities.containing(entry.date);

/// The activity a built row sits inside, mirroring how the row was formed.
/// A [ReplacementRow] only counts as during a ride when both of its halves
/// fall inside the same activity.
StravaActivity? _rowActivity(StravaActivityIndex activities, EntryRow row) {
  switch (row) {
    case SingleEntryRow(:final entry):
      return _contextOf(activities, entry);
    case SetupGroupRow(:final setups):
      return _contextOf(activities, setups.first);
    case ReplacementRow(:final removed, :final installed):
      final removedContext = activities.containing(
        removed.installation.dateTimeUTC,
      );
      final installedContext = activities.containing(
        installed.installation.dateTimeUTC,
      );
      return (removedContext != null && removedContext == installedContext)
          ? removedContext
          : null;
  }
}

/// Collapses [sortedEntries] into display rows: replacement pairs, runs of
/// setups, and singles for everything else. Shared by the timeline list and
/// the calendar — it neither sets [EntryRow.stravaContext] nor emits
/// [DayHeaderRow]s, which are list-only passes in [buildTimelineRows].
List<EntryRow> collapseIntoRows(
  List<TimelineEntry> sortedEntries, {
  required AppSettings appSettings,
}) {
  final activities = _contextIndex(sortedEntries, appSettings);
  StravaActivity? contextOf(TimelineEntry entry) =>
      _contextOf(activities, entry);

  final pairing = appSettings.enableTimelineReplacementDetection
      ? pairReplacements(sortedEntries, window: kReplacementWindow)
      : const ReplacementPairing.empty();

  // Base rows in display order. Replacement rows are emitted at the earlier
  // event's slot; the later half is skipped.
  final rows = <EntryRow>[];
  int i = 0;
  while (i < sortedEntries.length) {
    final entry = sortedEntries[i];

    if (entry is InstallationEntry &&
        pairing.consumedIds.contains(
          entry.componentInstallation.installation.id,
        )) {
      final pair =
          pairing.pairsByAnchorId[entry.componentInstallation.installation.id];
      if (pair != null) {
        rows.add(
          ReplacementRow(removed: pair.removed, installed: pair.installed),
        );
      }
      i++;
      continue;
    }

    if (appSettings.enableTimelineSetupGrouping && entry is SetupEntry) {
      final run = <SetupEntry>[entry];
      var j = i + 1;
      while (j < sortedEntries.length) {
        final next = sortedEntries[j];
        if (next is! SetupEntry) break;
        if (next.setup.bike != entry.setup.bike) break;
        // The group header shows one day + a time range, so members must
        // share the local day.
        if (!_sameLocalDay(next.setup.datetimeLocal, entry.setup.datetimeLocal)) break;
        // Merging across different ride contexts would misrepresent both.
        if (contextOf(next) != contextOf(run.last)) break;
        if (next.date.difference(run.last.date).abs() > kSetupGroupWindow) break;
        run.add(next);
        j++;
      }
      if (run.length >= 2) {
        rows.add(SetupGroupRow(run));
        i = j;
        continue;
      }
    }

    rows.add(SingleEntryRow(entry));
    i++;
  }

  return rows;
}

List<TimelineRow> buildTimelineRows(
  List<TimelineEntry> sortedEntries, {
  required bool sortAscending,
  required AppSettings appSettings,
}) {
  final rows = collapseIntoRows(sortedEntries, appSettings: appSettings);

  if (appSettings.enableTimelineStravaContext) {
    // Recomputed from the built rows rather than carried out of the grouping
    // core: only this list-only pass needs it, the calendar takes plain rows.
    final activities = _contextIndex(sortedEntries, appSettings);
    final duringActivity = <EntryRow, StravaActivity?>{
      for (final row in rows) row: _rowActivity(activities, row),
    };

    // Every activity tile anchors its own ride block.
    final activityRowIds = <int>{};
    for (final row in rows) {
      if (row case SingleEntryRow(entry: StravaEntry(:final activity))) {
        duringActivity[row] = activity;
        activityRowIds.add(activity.id);
      }
    }

    // Block regrouping: rows inside an activity's window are pulled adjacent
    // to that activity's tile (after it in ASC, before it in DESC), so a ride
    // block stays contiguous even when activities overlap. With no overlap
    // the chronological order already satisfies this and nothing moves.
    final attributed = <int, List<EntryRow>>{};
    for (final row in rows) {
      final activity = duringActivity[row];
      if (activity == null) continue;
      if (row case SingleEntryRow(entry: StravaEntry())) continue;
      if (!activityRowIds.contains(activity.id)) continue;
      attributed.putIfAbsent(activity.id, () => []).add(row);
    }
    if (attributed.isNotEmpty) {
      final moved = attributed.values.expand((rows) => rows).toSet();
      final reordered = <EntryRow>[];
      for (final row in rows) {
        if (row case SingleEntryRow(entry: StravaEntry(:final activity))) {
          final members = attributed[activity.id] ?? const <EntryRow>[];
          if (sortAscending) {
            reordered
              ..add(row)
              ..addAll(members);
          } else {
            reordered
              ..addAll(members)
              ..add(row);
          }
        } else if (!moved.contains(row)) {
          reordered.add(row);
        }
      }
      rows
        ..clear()
        ..addAll(reordered);
    }

    // Mark first/last of each contiguous same-activity run (display order).
    // Runs of different activities never merge: at the boundary both bars get
    // rounded/inset ends, so back-to-back rides read as separate blocks.
    for (var k = 0; k < rows.length; k++) {
      final activity = duringActivity[rows[k]];
      if (activity == null) continue;
      final previous = k > 0 ? duringActivity[rows[k - 1]] : null;
      final next = k < rows.length - 1 ? duringActivity[rows[k + 1]] : null;
      rows[k].stravaContext = StravaContext(
        activity: activity,
        isFirst: previous?.id != activity.id,
        isLast: next?.id != activity.id,
      );
    }
  }

  if (!appSettings.enableTimelineDayHeaders) return List<TimelineRow>.from(rows);

  final result = <TimelineRow>[];
  DateTime? currentDay;
  for (final row in rows) {
    final local = row.anchorDateLocal;
    final day = DateTime(local.year, local.month, local.day);
    if (day != currentDay) {
      result.add(DayHeaderRow(day));
      currentDay = day;
    }
    result.add(row);
  }
  return result;
}
