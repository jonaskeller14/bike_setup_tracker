import 'package:flutter/foundation.dart';

import '../models/component_installation.dart';
import '../models/installation.dart';
import '../models/strava/strava_activity.dart';
import '../models/timeline_entry.dart';

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

sealed class EntryRow extends TimelineRow {
  StravaContext? stravaContext;
  DateTime get anchorDateLocal;
}

class SingleEntryRow extends EntryRow {
  final TimelineEntry entry;
  SingleEntryRow(this.entry);

  @override
  Key get key => ValueKey('single:${entry.id}');

  @override
  DateTime get anchorDateLocal => entry.dateLocal;
}

class SetupGroupRow extends EntryRow {
  final List<SetupEntry> setups;
  SetupGroupRow(this.setups);

  @override
  Key get key => ValueKey('group:${setups.map((e) => e.setup.id).join('|')}');

  @override
  DateTime get anchorDateLocal => setups.first.setup.datetimeLocal;
}

class ReplacementRow extends EntryRow {
  final ComponentInstallation removed;
  final ComponentInstallation installed;
  ReplacementRow({required this.removed, required this.installed});

  @override
  Key get key =>
      ValueKey('repl:${removed.installation.id}:${installed.installation.id}');

  Installation get anchorInstallation =>
      removed.installation.dateTimeUTC.isAfter(
        installed.installation.dateTimeUTC,
      )
      ? installed.installation
      : removed.installation;

  @override
  DateTime get anchorDateLocal => anchorInstallation.dateTimeLocal;
}
