import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/component/component_ancestor.dart';
import '../models/component/installation.dart';
import '../models/task/task_entry.dart';
import '../services/component_hierarchy_resolver.dart';
import 'component_ancestor_display.dart';
import 'component_ancestors_column.dart';
import 'sheets/task_rule_sheet.dart';

class DisplayInstallationTimeline extends StatelessWidget {
  final Component component;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;
  final Iterable<TaskEntry> taskEntries;
  final ComponentHierarchyResolver? hierarchy;

  const DisplayInstallationTimeline({
    super.key,
    required this.component,
    required this.bikes,
    required this.components,
    this.taskEntries = const [],
    this.hierarchy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final appSettings = context.watch<AppSettings>();

    final hierarchy = this.hierarchy;
    int tieOrder(_TimelineItem item) => switch (item) {
          _InstallationItem() => 0,
          _DerivedPlacementItem() => 1,
          _TaskItem() => 2,
        };
    final items = <_TimelineItem>[
      ...component.installations.map((i) => _InstallationItem(i)),
      if (hierarchy != null) ...hierarchy.inheritedRootChanges(component.id).map((c) => _DerivedPlacementItem(c)),
      ...taskEntries.map((te) => _TaskItem(te)),
    ]..sort((a, b) {
        final byDate = a.dateTimeUTC.compareTo(b.dateTimeUTC);
        if (byDate != 0) return byDate;
        // On ties, apply installation state transitions before task markers.
        return tieOrder(a).compareTo(tieOrder(b));
      });

    // Precompute the prevailing installation state of the segment *after* each
    // node: solid while installed, dashed while uninstalled. Installation
    // nodes update the running state; task nodes inherit it.
    String? currentParent;
    final installedAfter = <bool>[];
    for (final item in items) {
      if (item is _InstallationItem) currentParent = item.installation.parent;
      installedAfter.add(
        hierarchy != null ? hierarchy.bikeAt(component.id, item.dateTimeUTC) != null : currentParent != null,
      );
    }

    // Pre-blended: translucent dashes double up where neighbouring connectors' square caps overlap.
    final connectorColor = Color.alphaBlend(colorScheme.secondary.withValues(alpha: 0.6), colorScheme.surface);

    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        // Paints the indicator above the connectors so dash caps can't bleed over the dot.
        nodeItemOverlap: true,
        indicatorTheme: IndicatorThemeData(
          size: 15.0,
          color: colorScheme.secondary,
        ),
        connectorTheme: ConnectorThemeData(
          thickness: 3.0,
          color: connectorColor,
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
                components: components,
                ancestors: hierarchy != null && item.installation is ComponentInstallation
                    ? hierarchy.ancestorsAt(component.id, item.installation.dateTimeUTC).skip(1).toList()
                    : const [],
              ),
            _DerivedPlacementItem() => _DerivedPlacementContents(
                change: item.change,
                appSettings: appSettings,
                bikes: bikes,
                components: components,
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
                  ComponentInstallation() => null,
                  Uninstallation() => Icon(Icons.close, size: 10, color: colorScheme.secondary),
                  Archival() => Icon(Icons.close, size: 10, color: colorScheme.secondary),
                },
              ),
            _DerivedPlacementItem() => OutlinedDotIndicator(
                borderWidth: 2.5,
                color: connectorColor,
                backgroundColor: colorScheme.surface,
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
  final Map<String, Component> components;
  final List<ComponentAncestor> ancestors;

  const _InstallationContents({
    required this.installation,
    required this.appSettings,
    required this.bikes,
    required this.components,
    this.ancestors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bikeName = switch (installation) {
      BikeInstallation() => bikes[installation.parent]?.name ?? 'BIKE NOT FOUND',
      ComponentInstallation(:final parentComponentId) =>
        components[parentComponentId]?.name ?? 'COMPONENT NOT FOUND',
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
          _DateLabel(dateStr),
          Text(
            bikeName,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: installation.parent != null ? FontWeight.bold : FontWeight.normal,
              color: switch (installation) {
                BikeInstallation() => bikes[installation.parent]?.name == null
                    ? colorScheme.error
                    : colorScheme.onSurface,
                ComponentInstallation(:final parentComponentId) =>
                  components[parentComponentId] == null
                      ? colorScheme.error
                      : colorScheme.onSurface,
                Uninstallation() || Archival() => colorScheme.onSurfaceVariant,
              },
            ),
          ),
          if (ancestors.isNotEmpty) ComponentAncestorsColumn(ancestors: ancestors, bikes: bikes),
        ],
      ),
    );
  }
}

class _DerivedPlacementContents extends StatelessWidget {
  final InheritedRootChange change;
  final AppSettings appSettings;
  final Map<String, Bike> bikes;
  final Map<String, Component> components;

  const _DerivedPlacementContents({
    required this.change,
    required this.appSettings,
    required this.bikes,
    required this.components,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final root = change.root;
    final color = root.isMissing(bikes) ? colorScheme.error : colorScheme.onSurfaceVariant;
    final parentName = components[change.viaParentId]?.name ?? 'COMPONENT NOT FOUND';
    final dateTimeLocal = change.cause.dateTimeLocal;
    final dateStr =
        "${DateFormat(appSettings.dateFormat).format(dateTimeLocal)} • ${DateFormat(appSettings.timeFormat).format(dateTimeLocal)}";

    return Container(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DateLabel(dateStr),
          Row(
            spacing: 4,
            children: [
              Icon(root.iconData, size: 16, color: color),
              Flexible(
                child: Text(
                  root.label(bikes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
          Text(
            "via $parentName",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
            _DateLabel(dateStr),
            Text(
              entry.name,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final String text;

  const _DateLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
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

class _DerivedPlacementItem extends _TimelineItem {
  final InheritedRootChange change;
  _DerivedPlacementItem(this.change) : super(change.cause.dateTimeUTC);
}

class _TaskItem extends _TimelineItem {
  final TaskEntry taskEntry;
  _TaskItem(this.taskEntry) : super(taskEntry.dateTimeUTC);
}
