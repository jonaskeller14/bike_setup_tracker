import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../models/task/task_entry.dart';
import 'sheets/task_rule_sheet.dart';

class DisplayInstallationTimeline extends StatelessWidget {
  final Component component;
  final Map<String, Bike> bikes;
  final Iterable<TaskEntry> taskEntries;

  const DisplayInstallationTimeline({
    super.key,
    required this.component,
    required this.bikes,
    this.taskEntries = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final appSettings = context.watch<AppSettings>();

    final items = <_TimelineItem>[
      ...component.installations.map((i) => _InstallationItem(i)),
      ...taskEntries.map((te) => _TaskItem(te)),
    ]..sort((a, b) {
        final byDate = a.dateTimeUTC.compareTo(b.dateTimeUTC);
        if (byDate != 0) return byDate;
        // On ties, apply installation state transitions before task markers.
        return (a is _InstallationItem ? 0 : 1).compareTo(b is _InstallationItem ? 0 : 1);
      });

    // Precompute the prevailing installation state of the segment *after* each
    // node: solid while installed, dashed while uninstalled. Installation
    // nodes update the running state; task nodes inherit it.
    String? currentParent;
    final installedAfter = <bool>[];
    for (final item in items) {
      if (item is _InstallationItem) currentParent = item.installation.parent;
      installedAfter.add(currentParent != null);
    }

    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        indicatorTheme: IndicatorThemeData(
          size: 15.0,
          color: colorScheme.secondary,
        ),
        connectorTheme: ConnectorThemeData(
          thickness: 3.0,
          color: colorScheme.secondary.withValues(alpha: 0.6),
        ),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.after,
        itemCount: items.length,
        contentsBuilder: (context, index) {
          final item = items[index];
          return switch (item) {
            _InstallationItem() => _InstallationContents(
                installation: item.installation,
                appSettings: appSettings,
                bikes: bikes,
              ),
            _TaskItem() => _TaskEntryContents(
                entry: item.taskEntry,
                appSettings: appSettings,
              ),
          };
        },
        indicatorBuilder: (context, index) {
          final item = items[index];
          return switch (item) {
            _InstallationItem() => OutlinedDotIndicator(
                borderWidth: 2.5,
                color: colorScheme.secondary,
                backgroundColor: colorScheme.surface,
                child: switch (item.installation) {
                  BikeInstallation() => null,
                  Uninstallation() => Icon(Icons.close, size: 10, color: colorScheme.secondary),
                  Archival() => Icon(Icons.close, size: 10, color: colorScheme.secondary),
                },
              ),
            _TaskItem() => SizedBox(
                width: 15,
                height: 15,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(Icons.check, size: 11, color: colorScheme.onTertiary),
                ),
              ),
          };
        },
        connectorBuilder: (context, index, type) {
          return installedAfter[index]
              ? const SolidLineConnector()
              : const DashedLineConnector();
        },
      ),
    );
  }
}

class _InstallationContents extends StatelessWidget {
  final Installation installation;
  final AppSettings appSettings;
  final Map<String, Bike> bikes;

  const _InstallationContents({
    required this.installation,
    required this.appSettings,
    required this.bikes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bikeName = switch (installation) {
      BikeInstallation() => bikes[installation.parent]?.name ?? 'BIKE NOT FOUND',
      Uninstallation() => 'Uninstalled',
      Archival() => 'Archived',
    };
    final dateStr = installation.dateTimeUTC.millisecondsSinceEpoch == 0
        ? 'From beginning'
        : "${DateFormat(appSettings.dateFormat).format(installation.dateTimeLocal)} • ${DateFormat(appSettings.timeFormat).format(installation.dateTimeLocal)}";

    return Container(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bikeName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: installation is BikeInstallation ? FontWeight.bold : FontWeight.normal,
              color: switch (installation) {
                BikeInstallation() => bikes[installation.parent]?.name == null
                    ? colorScheme.error
                    : colorScheme.onSurface,
                Uninstallation() || Archival() => colorScheme.onSurfaceVariant,
              },
            ),
          ),
          Text(
            dateStr,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
          ),
        ],
      ),
    );
  }
}

class _TaskEntryContents extends StatelessWidget {
  final TaskEntry entry;
  final AppSettings appSettings;

  const _TaskEntryContents({required this.entry, required this.appSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dateStr =
        "${DateFormat(appSettings.dateFormat).format(entry.dateTimeLocal)} • ${DateFormat(appSettings.timeFormat).format(entry.dateTimeLocal)}";

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await showTaskRuleSheet(
          context,
          taskRuleId: entry.taskRule,
          highlightTaskEntryId: entry.id,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.name,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              dateStr,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _TimelineItem {
  final DateTime dateTimeUTC;
  const _TimelineItem(this.dateTimeUTC);
}

class _InstallationItem extends _TimelineItem {
  final Installation installation;
  _InstallationItem(this.installation) : super(installation.dateTimeUTC);
}

class _TaskItem extends _TimelineItem {
  final TaskEntry taskEntry;
  _TaskItem(this.taskEntry) : super(taskEntry.dateTimeUTC);
}
