import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/component.dart';
import '../models/installation.dart';
import '../pages/details/component_details_page.dart';
import 'sheets/component_type_filter.dart';
import 'text/section_title.dart';

class _ComponentActivePeriod {
  final DateTime instStart;
  final DateTime? instEnd;
  const _ComponentActivePeriod({required this.instStart, this.instEnd});
}

class InstallationTimelineTable extends StatefulWidget {
  final String bikeId;
  final List<Component> allComponents;

  const InstallationTimelineTable({
    super.key,
    required this.bikeId,
    required this.allComponents,
  });

  @override
  State<InstallationTimelineTable> createState() => _InstallationTimelineTableState();
}

class _InstallationTimelineTableState extends State<InstallationTimelineTable> {
  final Set<ComponentType> _hiddenComponentTypes = {};

  List<({DateTime start, DateTime? end})> _getComponentActiveIntervals(Component comp) {
    final List<({DateTime start, DateTime? end})> res = [];
    final sortedInsts = List<Installation>.from(comp.installations)
      ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

    for (int i = 0; i < sortedInsts.length; i++) {
      final inst = sortedInsts[i];
      if (inst.parent == widget.bikeId) {
        final start = inst.dateTimeLocal;
        final end = (i + 1 < sortedInsts.length)
            ? sortedInsts[i + 1].dateTimeLocal
            : null;
        res.add((start: start, end: end));
      }
    }
    return res;
  }

  bool _intervalsOverlap(DateTime s1, DateTime? e1, DateTime s2, DateTime? e2) {
    final s1BeforeE2 = (e2 == null) || s1.isBefore(e2);
    final s2BeforeE1 = (e1 == null) || s2.isBefore(e1);
    return s1BeforeE2 && s2BeforeE1;
  }

  bool _componentsOverlap(Component c1, Component c2) {
    final ints1 = _getComponentActiveIntervals(c1);
    final ints2 = _getComponentActiveIntervals(c2);
    for (final i1 in ints1) {
      for (final i2 in ints2) {
        if (_intervalsOverlap(i1.start, i1.end, i2.start, i2.end)) {
          return true;
        }
      }
    }
    return false;
  }

  List<List<Component>> _getSlotsForComponents(List<Component> comps) {
    final sortedComps = List<Component>.from(comps);
    sortedComps.sort((a, b) {
      final intsA = _getComponentActiveIntervals(a);
      final intsB = _getComponentActiveIntervals(b);
      if (intsA.isEmpty && intsB.isEmpty) return a.id.compareTo(b.id);
      if (intsA.isEmpty) return 1;
      if (intsB.isEmpty) return -1;

      final minStartA = intsA.map((e) => e.start).reduce((min, val) => val.isBefore(min) ? val : min);
      final minStartB = intsB.map((e) => e.start).reduce((min, val) => val.isBefore(min) ? val : min);
      return minStartA.compareTo(minStartB);
    });

    final List<List<Component>> slots = [];
    for (final comp in sortedComps) {
      int assignedSlot = -1;
      for (int s = 0; s < slots.length; s++) {
        bool overlaps = false;
        for (final existing in slots[s]) {
          if (_componentsOverlap(comp, existing)) {
            overlaps = true;
            break;
          }
        }
        if (!overlaps) {
          assignedSlot = s;
          break;
        }
      }
      if (assignedSlot == -1) {
        slots.add([comp]);
      } else {
        slots[assignedSlot].add(comp);
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();

    final installedComponents = widget.allComponents.where((c) {
      return c.installations.any((i) => i.parent == widget.bikeId);
    }).toList();

    if (installedComponents.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeComponentTypes = installedComponents
        .map((c) => c.componentType)
        .toSet()
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final Map<ComponentType, List<Component>> componentsByType = {};
    for (final component in installedComponents) {
      componentsByType.putIfAbsent(component.componentType, () => []).add(component);
    }
    for (final list in componentsByType.values) {
      list.sort((a, b) => a.id.compareTo(b.id));
    }

    final uniqueDatetimesSet = <DateTime>{};
    for (final component in installedComponents) {
      final sortedInsts = List<Installation>.from(component.installations)
        ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

      for (int i = 0; i < sortedInsts.length; i++) {
        final inst = sortedInsts[i];
        if (inst.parent == widget.bikeId) {
          uniqueDatetimesSet.add(inst.dateTimeLocal);
          if (i + 1 < sortedInsts.length) {
            uniqueDatetimesSet.add(sortedInsts[i + 1].dateTimeLocal);
          }
        }
      }
    }
    final sortedDatetimes = uniqueDatetimesSet.toList()..sort();

    if (sortedDatetimes.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<MapEntry<DateTime, DateTime?>> intervals = [];
    for (int j = 0; j < sortedDatetimes.length - 1; j++) {
      intervals.add(MapEntry(sortedDatetimes[j], sortedDatetimes[j + 1]));
    }
    intervals.add(MapEntry(sortedDatetimes.last, null));

    final visibleComponentTypes = activeComponentTypes
        .where((type) => !_hiddenComponentTypes.contains(type))
        .toList();

    const double rowHeight = 70.0;
    const double headerHeight = 60.0;

    double getColumnWidth(int componentCount) {
      if (componentCount <= 1) return 120.0;
      return 80.0 * componentCount;
    }

    final Map<int, TableColumnWidth> columnWidths = {};
    columnWidths[0] = const FixedColumnWidth(110.0);
    for (int col = 0; col < visibleComponentTypes.length; col++) {
      final type = visibleComponentTypes[col];
      final comps = componentsByType[type] ?? [];
      final slots = _getSlotsForComponents(comps);
      columnWidths[col + 1] = FixedColumnWidth(getColumnWidth(slots.length));
    }

    String formatDateTime(DateTime dt) {
      if (dt.millisecondsSinceEpoch == 0) {
        return "Initial Setup";
      }
      final dateStr = DateFormat(appSettings.dateFormat).format(dt);
      final timeStr = DateFormat(appSettings.timeFormat).format(dt);
      return "$dateStr\n$timeStr";
    }

    _ComponentActivePeriod? getPeriod(Component comp, DateTime rowStart) {
      final sortedInsts = List<Installation>.from(comp.installations)
        ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));

      for (int i = 0; i < sortedInsts.length; i++) {
        final inst = sortedInsts[i];
        if (inst.parent == widget.bikeId) {
          final instStart = inst.dateTimeLocal;
          final instEnd = (i + 1 < sortedInsts.length)
              ? sortedInsts[i + 1].dateTimeLocal
              : null;

          final startMatch = instStart.isBefore(rowStart) || instStart.isAtSameMomentAs(rowStart);
          final endMatch = (instEnd == null) || instEnd.isAfter(rowStart);

          if (startMatch && endMatch) {
            return _ComponentActivePeriod(instStart: instStart, instEnd: instEnd);
          }
        }
      }
      return null;
    }

    final tableRows = <TableRow>[];

    tableRows.add(
      TableRow(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        children: [
          Container(
            height: headerHeight,
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
                right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
              ),
            ),
            child: Text(
              "Timeline",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...visibleComponentTypes.map((type) {
            return Container(
              height: headerHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
                  right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                ),
              ),
              child: Tooltip(
                message: type.label,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(type.getIconData(), size: 20),
                    const SizedBox(height: 4),
                    Text(
                      type.label,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );

    for (final interval in intervals) {
      final rowStart = interval.key;
      final rowEnd = interval.value;

      tableRows.add(
        TableRow(
          children: [
            Container(
              height: rowHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                  right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                ),
              ),
              child: Text(
                formatDateTime(rowStart),
                style: const TextStyle(fontSize: 10, height: 1.2),
              ),
            ),
            ...visibleComponentTypes.map((type) {
              final comps = componentsByType[type] ?? [];
              final slots = _getSlotsForComponents(comps);
              return Container(
                height: rowHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                    right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                  ),
                ),
                child: Row(
                  children: slots.map<Widget>((compList) {
                    Component? activeComp;
                    _ComponentActivePeriod? period;
                    for (final comp in compList) {
                      final p = getPeriod(comp, rowStart);
                      if (p != null) {
                        activeComp = comp;
                        period = p;
                        break;
                      }
                    }

                    if (activeComp == null || period == null) {
                      return const Expanded(child: SizedBox.shrink());
                    }

                    final isStart = period.instStart.isAtSameMomentAs(rowStart);
                    final isEnd = (rowEnd == null)
                        ? (period.instEnd == null)
                        : (period.instEnd != null && period.instEnd!.isAtSameMomentAs(rowEnd));

                    final borderColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);

                    final dateStyle = TextStyle(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    );

                    final Widget startText = isStart
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              period.instStart.millisecondsSinceEpoch == 0
                                  ? "Beginning"
                                  : "${DateFormat(appSettings.dateFormat).format(period.instStart)}\n${DateFormat(appSettings.timeFormat).format(period.instStart)}",
                              style: dateStyle,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink();

                    final Widget endText = isEnd
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              period.instEnd == null
                                  ? "Present"
                                  : "${DateFormat(appSettings.dateFormat).format(period.instEnd!)}\n${DateFormat(appSettings.timeFormat).format(period.instEnd!)}",
                              style: dateStyle,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink();

                    final comp = activeComp;
                    Widget content;
                    if (isStart) {
                      content = Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          startText,
                          Expanded(
                            child: Center(
                              child: Text(
                                comp.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          endText,
                        ],
                      );
                    } else {
                      content = Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 12),
                          Expanded(
                            child: Center(
                              child: Icon(
                                Icons.arrow_downward,
                                size: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          endText,
                        ],
                      );
                    }

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          unawaited(Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ComponentDetailsPage(componentId: comp.id),
                            ),
                          ));
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            top: isStart ? 4.0 : 0.0,
                            bottom: isEnd ? 4.0 : 0.0,
                            left: 4.0,
                            right: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            border: Border(
                              top: isStart ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none,
                              bottom: isEnd ? BorderSide(color: borderColor, width: 1.5) : BorderSide.none,
                              left: BorderSide(color: borderColor, width: 1.5),
                              right: BorderSide(color: borderColor, width: 1.5),
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: isStart ? const Radius.circular(8.0) : Radius.zero,
                              topRight: isStart ? const Radius.circular(8.0) : Radius.zero,
                              bottomLeft: isEnd ? const Radius.circular(8.0) : Radius.zero,
                              bottomRight: isEnd ? const Radius.circular(8.0) : Radius.zero,
                            ),
                          ),
                          child: content,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: "Installation Timeline",
          infoText: "Visualizes component setup history, including overlaps and periods with no active components.",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilterChip(
            avatar: const Icon(Icons.view_column_outlined, size: 16),
            showCheckmark: false,
            label: Text(
              _hiddenComponentTypes.isEmpty
                  ? "All Component Types"
                  : "Component Types ${visibleComponentTypes.length}/${activeComponentTypes.length}",
            ),
            selected: _hiddenComponentTypes.isNotEmpty,
            onSelected: (bool _) async {
              await showComponentTypeFilterSheet(
                context: context,
                availableComponentTypes: activeComponentTypes,
                hiddenComponentTypes: _hiddenComponentTypes,
                onChanged: () => setState(() {}),
              );
            },
            onDeleted: _hiddenComponentTypes.isNotEmpty
                ? () => setState(() => _hiddenComponentTypes.clear())
                : null,
          ),
        ),
        const SizedBox(height: 8),
        if (visibleComponentTypes.isEmpty)
          _noComponentTypesPlaceholder(context)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: columnWidths,
              children: tableRows,
            ),
          ),
      ],
    );
  }

  Widget _noComponentTypesPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(
              Icons.view_column_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            Text(
              'Select a component type to display the table',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
