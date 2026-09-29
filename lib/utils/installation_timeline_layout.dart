import '../models/component/component.dart';
import 'installation_timeline_intervals.dart';

/// One timeline row, running from one block boundary to the next. The last
/// row is open-ended.
class TimelineRow {
  final DateTime start;
  final DateTime? end;

  /// First row of its local day: label with date + time, otherwise time only.
  final bool showDate;
  final double height;

  const TimelineRow({
    required this.start,
    this.end,
    required this.showDate,
    required this.height,
  });

  bool get isInitialSetup => start.millisecondsSinceEpoch == 0;
}

/// One slot of a component type. A type whose components overlap in time
/// spreads over several slot columns.
class TimelineColumn {
  static const double singleSlotWidth = 120.0;
  static const double multiSlotWidth = 80.0;

  final ComponentType type;
  final int slotIndex;
  final int slotCount;

  const TimelineColumn({
    required this.type,
    required this.slotIndex,
    required this.slotCount,
  });

  double get width => slotCount <= 1 ? singleSlotWidth : multiSlotWidth;
}

/// One interval rendered as a single cell spanning rows [rowFrom]..[rowTo].
class TimelineBlock {
  final String componentId;
  final String? parentComponentId;
  final int columnIndex;
  final int rowFrom;
  final int rowTo;
  final bool isOpen;

  const TimelineBlock({
    required this.componentId,
    this.parentComponentId,
    required this.columnIndex,
    required this.rowFrom,
    required this.rowTo,
    required this.isOpen,
  });

  bool get isNested => parentComponentId != null;
  int get rowSpan => rowTo - rowFrom + 1;
}

class TimelineLayout {
  final List<TimelineRow> rows;
  final List<TimelineColumn> columns;
  final List<TimelineBlock> blocks;

  /// Indexed `[column][row]`; every cell a block covers holds that block.
  final List<List<TimelineBlock?>> _cells;

  const TimelineLayout._(this.rows, this.columns, this.blocks, this._cells);

  TimelineBlock? blockAt(int row, int column) => _cells[column][row];

  double get totalHeight => rows.fold(0.0, (sum, row) => sum + row.height);
}

/// Lays out the [intervals] of components whose type is in [visibleTypes]
/// (in that column order). Rows start at [minRowHeight]; a block whose rows
/// are shorter than its content ([blockHeight], or [nestedBlockHeight] with a
/// parent caption) grows its last row by the difference.
TimelineLayout buildTimelineLayout({
  required Map<String, List<TimelineInterval>> intervals,
  required Map<String, Component> components,
  required List<ComponentType> visibleTypes,
  required double minRowHeight,
  required double blockHeight,
  required double nestedBlockHeight,
}) {
  final intervalsByType = <ComponentType, List<TimelineInterval>>{};
  for (final MapEntry(key: componentId, value: componentIntervals) in intervals.entries) {
    final type = components[componentId]?.componentType;
    if (type == null || !visibleTypes.contains(type)) continue;
    (intervalsByType[type] ??= []).addAll(componentIntervals);
  }

  final boundaries = <DateTime>{
    for (final typeIntervals in intervalsByType.values)
      for (final interval in typeIntervals) ...[
        interval.startLocal,
        if (interval.endLocal != null) interval.endLocal!,
      ],
  }.toList()..sort();
  final rowOf = {for (final (index, boundary) in boundaries.indexed) boundary: index};

  final columns = <TimelineColumn>[];
  final blocks = <TimelineBlock>[];
  for (final type in visibleTypes) {
    final typeIntervals = intervalsByType[type];
    if (typeIntervals == null) continue;
    final spans = [
      for (final interval in typeIntervals)
        (
          interval: interval,
          rowFrom: rowOf[interval.startLocal]!,
          rowTo: interval.endLocal == null ? boundaries.length - 1 : rowOf[interval.endLocal]! - 1,
        ),
    ];
    // Distinct UTC instants can share (or invert) local times; such an
    // interval covers no row.
    spans.removeWhere((span) => span.rowTo < span.rowFrom);
    final (slots, slotCount) = _packSlots(spans);

    final firstColumn = columns.length;
    for (var slotIndex = 0; slotIndex < slotCount; slotIndex++) {
      columns.add(TimelineColumn(type: type, slotIndex: slotIndex, slotCount: slotCount));
    }
    for (final (span, slot) in slots) {
      blocks.add(
        TimelineBlock(
          componentId: span.interval.componentId,
          parentComponentId: span.interval.parentComponentId,
          columnIndex: firstColumn + slot,
          rowFrom: span.rowFrom,
          rowTo: span.rowTo,
          isOpen: span.interval.endLocal == null,
        ),
      );
    }
  }

  final heights = List.filled(boundaries.length, minRowHeight);
  for (final block in [...blocks]..sort((a, b) => a.rowTo.compareTo(b.rowTo))) {
    final needed = block.isNested ? nestedBlockHeight : blockHeight;
    var available = 0.0;
    for (var row = block.rowFrom; row <= block.rowTo; row++) {
      available += heights[row];
    }
    if (available < needed) heights[block.rowTo] += needed - available;
  }

  final rows = [
    for (final (index, start) in boundaries.indexed)
      TimelineRow(
        start: start,
        end: index + 1 < boundaries.length ? boundaries[index + 1] : null,
        showDate: index == 0 || !_isSameDay(boundaries[index - 1], start),
        height: heights[index],
      ),
  ];

  final cells = [
    for (var i = 0; i < columns.length; i++) List<TimelineBlock?>.filled(rows.length, null),
  ];
  for (final block in blocks) {
    for (var row = block.rowFrom; row <= block.rowTo; row++) {
      cells[block.columnIndex][row] = block;
    }
  }

  return TimelineLayout._(rows, columns, blocks, cells);
}

typedef _Span = ({TimelineInterval interval, int rowFrom, int rowTo});

/// Greedy per-interval slot packing in start order. An interval reuses its
/// component's previous slot when that slot is free, otherwise the first free
/// one. Since every free-slot choice is valid, the slot count stays at the
/// most intervals active at once.
(List<(_Span, int)>, int) _packSlots(List<_Span> spans) {
  spans.sort((a, b) {
    final byRow = a.rowFrom.compareTo(b.rowFrom);
    return byRow != 0 ? byRow : a.interval.componentId.compareTo(b.interval.componentId);
  });

  final slotLastRow = <int>[];
  final previousSlotOf = <String, int>{};
  final placed = <(_Span, int)>[];
  for (final span in spans) {
    final previous = previousSlotOf[span.interval.componentId];
    var slot = previous != null && slotLastRow[previous] < span.rowFrom
        ? previous
        : slotLastRow.indexWhere((lastRow) => lastRow < span.rowFrom);
    if (slot == -1) {
      slot = slotLastRow.length;
      slotLastRow.add(span.rowTo);
    } else {
      slotLastRow[slot] = span.rowTo;
    }
    previousSlotOf[span.interval.componentId] = slot;
    placed.add((span, slot));
  }
  return (placed, slotLastRow.length);
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
