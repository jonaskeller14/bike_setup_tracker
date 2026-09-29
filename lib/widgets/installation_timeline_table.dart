import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../models/app_settings.dart';
import '../models/component/component.dart';
import '../models/component/installation.dart';
import '../models/component/resolved_installation.dart';
import '../pages/details/component_details_page.dart';
import '../services/component_hierarchy_resolver.dart';
import '../utils/installation_timeline_intervals.dart';
import '../utils/installation_timeline_layout.dart';
import 'empty_state_placeholder.dart';
import 'sheets/component_type_filter.dart';
import 'sheets/installation_sheet.dart';
import 'text/section_title.dart';

class InstallationTimelineTable extends StatefulWidget {
  final String bikeId;
  final ComponentHierarchyResolver componentHierarchy;

  const InstallationTimelineTable({
    super.key,
    required this.bikeId,
    required this.componentHierarchy,
  });

  @override
  State<InstallationTimelineTable> createState() => _InstallationTimelineTableState();
}

class _InstallationTimelineTableState extends State<InstallationTimelineTable> {
  static const int _defaultVisibleComponentTypeCount = 3;
  static const double _minRowHeight = 44.0;
  static const double _rowHeaderWidth = 132.0;
  static const double _minHeaderHeight = 60.0;
  static const double _cellPadding = 4.0;
  static const double _blockMargin = 2.0;
  static const double _captionIconSize = 12.0;

  final Set<ComponentType> _hiddenComponentTypes = {};
  bool _hiddenComponentTypesInitialized = false;

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    final components = widget.componentHierarchy.components;
    final intervals = effectiveBikeIntervals(widget.componentHierarchy, components.values, widget.bikeId);

    final activeComponentTypes = intervals.keys.map((id) => components[id]!.componentType).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (!_hiddenComponentTypesInitialized) {
      _hiddenComponentTypesInitialized = true;
      if (activeComponentTypes.length > _defaultVisibleComponentTypeCount) {
        _hiddenComponentTypes.addAll(activeComponentTypes.skip(_defaultVisibleComponentTypeCount));
      }
    }

    final visibleComponentTypes = activeComponentTypes.where((type) => !_hiddenComponentTypes.contains(type)).toList();

    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final dateStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    final timeStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final nameStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
    final captionStyle = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    double lineHeight(TextStyle? style) => textScaler.scale(style?.fontSize ?? 11.0) * (style?.height ?? 1.2);
    final blockHeight = 2 * (_blockMargin + _cellPadding) + 2 * lineHeight(nameStyle);
    final layout = buildTimelineLayout(
      intervals: intervals,
      components: components,
      visibleTypes: visibleComponentTypes,
      minRowHeight: _minRowHeight,
      blockHeight: blockHeight,
      nestedBlockHeight: blockHeight + math.max(lineHeight(captionStyle), _captionIconSize),
    );
    final headerDecoration = BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
    );
    final rowDecoration = BoxDecoration(
      border: Border(
        bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
      ),
    );
    final headerHeight = math.max(_minHeaderHeight, 4 * _cellPadding + 24.0 + lineHeight(headerStyle));

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
            onDeleted: _hiddenComponentTypes.isNotEmpty ? () => setState(() => _hiddenComponentTypes.clear()) : null,
          ),
        ),
        const SizedBox(height: 8),
        if (intervals.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.history_rounded,
            title: "No installation history",
            subtitle: "Install components on this bike to see the timeline",
          )
        else if (visibleComponentTypes.isEmpty)
          const EmptyStatePlaceholder(
            icon: Icons.view_column_outlined,
            title: "No component types selected",
            subtitle: "Select a component type to display the table",
          )
        else
          Padding(
            // No right inset: cut-off columns at the screen edge signal horizontal scroll.
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              height: headerHeight + layout.totalHeight,
              child: TableView.builder(
                primary: false,
                verticalDetails: const ScrollableDetails.vertical(physics: NeverScrollableScrollPhysics()),
                pinnedRowCount: 1,
                pinnedColumnCount: 1,
                rowCount: layout.rows.length + 1,
                columnCount: layout.columns.length + 1,
                rowBuilder: (index) =>
                    TableSpan(extent: FixedTableSpanExtent(index == 0 ? headerHeight : layout.rows[index - 1].height)),
                columnBuilder: (index) => _buildColumnSpan(theme, layout, index),
                // Grid lines live on the cells rather than the row spans, so they
                // stop at the last column instead of crossing its trailing padding.
                cellBuilder: (context, vicinity) {
                  final row = vicinity.row - 1;
                  final column = vicinity.column - 1;
                  if (row < 0 && column < 0) {
                    return TableViewCell(
                      child: DecoratedBox(
                        decoration: headerDecoration,
                        child: Padding(
                          padding: const EdgeInsets.all(2 * _cellPadding),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Timeline", style: headerStyle),
                          ),
                        ),
                      ),
                    );
                  }
                  if (row < 0) {
                    final timelineColumn = layout.columns[column];
                    return TableViewCell(
                      columnMergeStart: vicinity.column - timelineColumn.slotIndex,
                      columnMergeSpan: timelineColumn.slotCount,
                      child: DecoratedBox(
                        decoration: headerDecoration,
                        child: _TypeHeader(type: timelineColumn.type, style: headerStyle),
                      ),
                    );
                  }
                  if (column < 0) {
                    return TableViewCell(
                      child: DecoratedBox(
                        decoration: rowDecoration,
                        child: _RowLabel(
                          row: layout.rows[row],
                          appSettings: appSettings,
                          dateStyle: dateStyle,
                          timeStyle: timeStyle,
                        ),
                      ),
                    );
                  }
                  final block = layout.blockAt(row, column);
                  if (block == null) return TableViewCell(child: DecoratedBox(decoration: rowDecoration));
                  final parentId = block.parentComponentId;
                  return TableViewCell(
                    rowMergeStart: block.rowFrom + 1,
                    rowMergeSpan: block.rowSpan,
                    child: CustomPaint(
                      painter: _RowLinesPainter(
                        rowHeights: [for (var r = block.rowFrom; r <= block.rowTo; r++) layout.rows[r].height],
                        side: rowDecoration.border!.bottom,
                      ),
                      child: _TimelineBlock(
                        component: components[block.componentId]!,
                        startUTC: block.startUTC,
                        endUTC: block.endUTC,
                        parentName: parentId == null ? null : components[parentId]!.name,
                        nameStyle: nameStyle,
                        captionStyle: captionStyle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  TableSpan _buildColumnSpan(ThemeData theme, TimelineLayout layout, int index) {
    final column = index == 0 ? null : layout.columns[index - 1];
    final isTypeEnd = column == null || column.slotIndex == column.slotCount - 1;
    final isLast = index == layout.columns.length;
    return TableSpan(
      extent: FixedTableSpanExtent(column?.width ?? _rowHeaderWidth),
      // The table runs to the screen edge; this gap only shows once scrolled to the end.
      padding: isLast ? const TableSpanPadding(trailing: 16) : null,
      backgroundDecoration: TableSpanDecoration(
        consumeSpanPadding: false,
        border: isTypeEnd
            ? TableSpanBorder(
                trailing: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
              )
            : null,
      ),
    );
  }
}

class _TypeHeader extends StatelessWidget {
  final ComponentType type;
  final TextStyle? style;

  const _TypeHeader({required this.type, required this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: type.label,
      child: Padding(
        padding: const EdgeInsets.all(_InstallationTimelineTableState._cellPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.getIconData(), size: 20),
            const SizedBox(height: 4),
            Text(type.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// Date and time as two columns: the times line up on the right, the date
/// appears only on the first row of a local day.
class _RowLabel extends StatelessWidget {
  final TimelineRow row;
  final AppSettings appSettings;
  final TextStyle? dateStyle;
  final TextStyle? timeStyle;

  const _RowLabel({
    required this.row,
    required this.appSettings,
    required this.dateStyle,
    required this.timeStyle,
  });

  @override
  Widget build(BuildContext context) {
    const padding = _InstallationTimelineTableState._cellPadding;
    if (row.isInitialSetup) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2 * padding, vertical: padding),
        child: Text("From beginning", style: dateStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2 * padding, vertical: padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: row.showDate
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(DateFormat(appSettings.dateFormat).format(row.start), style: dateStyle),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 2 * padding),
          Text(DateFormat(appSettings.timeFormat).format(row.start), style: timeStyle, maxLines: 1),
        ],
      ),
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final Component component;
  final DateTime startUTC;
  final DateTime? endUTC;
  final String? parentName;
  final TextStyle? nameStyle;
  final TextStyle? captionStyle;

  const _TimelineBlock({
    required this.component,
    required this.startUTC,
    required this.endUTC,
    required this.parentName,
    required this.nameStyle,
    required this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2 * _InstallationTimelineTableState._blockMargin,
        vertical: _InstallationTimelineTableState._blockMargin,
      ),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapUp: (details) => unawaited(_showMenu(context, details.globalPosition)),
          child: Padding(
            padding: const EdgeInsets.all(_InstallationTimelineTableState._cellPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    component.name,
                    style: nameStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (parentName != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: _InstallationTimelineTableState._captionIconSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      Flexible(
                        child: Text(
                          parentName!,
                          style: captionStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, Offset globalPosition) async {
    final sorted = [...component.installations]..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
    // The start event can predate [startUTC] when the block starts because a
    // parent was installed.
    final startIndex = sorted.lastIndexWhere((installation) => !installation.dateTimeUTC.isAfter(startUTC));
    // Only the component's own event can be edited here; an end caused by a
    // parent's event belongs to that parent.
    final endIndex = endUTC == null ? -1 : sorted.indexWhere((installation) => installation.dateTimeUTC == endUTC);
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(globalPosition & Size.zero, Offset.zero & overlay.size),
      items: [
        _menuItem(
          icon: component.componentType.getIconData(),
          label: 'Component details',
          value: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (context) => ComponentDetailsPage(componentId: component.id)),
          ),
        ),
        if (startIndex >= 0)
          _menuItem(
            icon: Icons.edit,
            label: 'Edit installation',
            value: () => showEditInstallationSheet(
              context,
              component: component,
              editEntry: _resolve(sorted, startIndex),
              editEnd: endIndex >= 0 ? sorted[endIndex] : null,
            ),
          ),
      ],
    );
    if (!context.mounted) return;
    selected?.call();
  }

  ResolvedInstallation _resolve(List<Installation> sorted, int index) {
    final previous = index > 0 ? sorted[index - 1] : null;
    return ResolvedInstallation(
      component: component,
      installation: sorted[index],
      originParent: previous?.parent,
      originParentType: previous?.parentType,
      isInitial: index == 0,
    );
  }

  static PopupMenuItem<VoidCallback> _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback value,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        spacing: 10,
        children: [
          Icon(icon),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Draws the bottom line of every row a merged block covers, so the row grid
/// stays continuous in the margins beside the block.
class _RowLinesPainter extends CustomPainter {
  final List<double> rowHeights;
  final BorderSide side;

  const _RowLinesPainter({required this.rowHeights, required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = side.toPaint();
    var y = 0.0;
    for (final height in rowHeights) {
      y += height;
      final lineY = y - side.width / 2;
      canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), paint);
    }
  }

  @override
  bool shouldRepaint(_RowLinesPainter oldDelegate) =>
      !listEquals(oldDelegate.rowHeights, rowHeights) || oldDelegate.side != side;
}
