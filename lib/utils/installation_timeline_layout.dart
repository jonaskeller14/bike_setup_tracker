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
  final intervalsByType = <ComponentType, Map<String, List<TimelineInterval>>>{};
  for (final MapEntry(key: componentId, value: componentIntervals) in intervals.entries) {
    final type = components[componentId]?.componentType;
    if (type == null || !visibleTypes.contains(type)) continue;
    (intervalsByType[type] ??= {})[componentId] = componentIntervals;
  }

  final boundaries = <DateTime>{
    for (final byComponent in intervalsByType.values)
      for (final componentIntervals in byComponent.values)
        for (final interval in componentIntervals) ...[
          interval.startLocal,
          if (interval.endLocal != null) interval.endLocal!,
        ],
  }.toList()..sort();
  final rowOf = {for (final (index, boundary) in boundaries.indexed) boundary: index};

  final columns = <TimelineColumn>[];
  final blocks = <TimelineBlock>[];
  for (final type in visibleTypes) {
    final byComponent = intervalsByType[type];
    if (byComponent == null) continue;
    final slots = _packSlots(byComponent);
    for (final (slotIndex, componentIds) in slots.indexed) {
      final columnIndex = columns.length;
      columns.add(TimelineColumn(type: type, slotIndex: slotIndex, slotCount: slots.length));
      for (final componentId in componentIds) {
        for (final interval in byComponent[componentId]!) {
          final rowFrom = rowOf[interval.startLocal]!;
          final rowTo = interval.endLocal == null ? boundaries.length - 1 : rowOf[interval.endLocal]! - 1;
          // Distinct UTC instants can share (or invert) local times; such an
          // interval covers no row.
          if (rowTo < rowFrom) continue;
          blocks.add(
            TimelineBlock(
              componentId: componentId,
              parentComponentId: interval.parentComponentId,
              columnIndex: columnIndex,
              rowFrom: rowFrom,
              rowTo: rowTo,
              isOpen: interval.endLocal == null,
            ),
          );
        }
      }
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

/// Greedy slot packing: components sorted by first start (then id) go into
/// the first slot where none of their intervals overlap.
List<List<String>> _packSlots(Map<String, List<TimelineInterval>> intervalsByComponent) {
  DateTime firstStart(String id) =>
      intervalsByComponent[id]!.map((interval) => interval.startLocal).reduce((a, b) => b.isBefore(a) ? b : a);

  final componentIds = intervalsByComponent.keys.toList()
    ..sort((a, b) {
      final byStart = firstStart(a).compareTo(firstStart(b));
      return byStart != 0 ? byStart : a.compareTo(b);
    });

  final slots = <List<String>>[];
  for (final id in componentIds) {
    final slot = slots
        .where((slot) => !slot.any((other) => _overlap(intervalsByComponent[id]!, intervalsByComponent[other]!)))
        .firstOrNull;
    if (slot == null) {
      slots.add([id]);
    } else {
      slot.add(id);
    }
  }
  return slots;
}

bool _overlap(List<TimelineInterval> a, List<TimelineInterval> b) => a.any(
  (x) => b.any(
    (y) =>
        (y.endLocal == null || x.startLocal.isBefore(y.endLocal!)) &&
        (x.endLocal == null || y.startLocal.isBefore(x.endLocal!)),
  ),
);

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
