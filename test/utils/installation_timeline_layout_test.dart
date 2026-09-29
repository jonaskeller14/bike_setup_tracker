import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/utils/installation_timeline_intervals.dart';
import 'package:bike_setup_tracker/utils/installation_timeline_layout.dart';
import 'package:flutter_test/flutter_test.dart';

const double minRowHeight = 32;
const double blockHeight = 48;
const double nestedBlockHeight = 64;

Component component(String id, ComponentType type) =>
    Component(id: id, name: id, installations: const [], componentType: type);

DateTime local(int day, [int hour = 0]) => DateTime(2026, 1, day, hour);

TimelineInterval interval(String id, DateTime start, [DateTime? end, String? parentId]) => TimelineInterval(
  componentId: id,
  startUTC: start.toUtc(),
  startLocal: start,
  endUTC: end?.toUtc(),
  endLocal: end,
  parentComponentId: parentId,
);

TimelineLayout layoutFor(
  List<Component> components,
  List<TimelineInterval> intervals, {
  List<ComponentType>? visibleTypes,
}) {
  final byComponent = <String, List<TimelineInterval>>{};
  for (final i in intervals) {
    (byComponent[i.componentId] ??= []).add(i);
  }
  return buildTimelineLayout(
    intervals: byComponent,
    components: {for (final c in components) c.id: c},
    visibleTypes: visibleTypes ?? {for (final c in components) c.componentType}.toList(),
    minRowHeight: minRowHeight,
    blockHeight: blockHeight,
    nestedBlockHeight: nestedBlockHeight,
  );
}

void main() {
  group('buildTimelineLayout', () {
    test('rows come only from intervals of visible types, last row open-ended', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [
          interval('fork', local(1), local(5)),
          interval('shock', local(3)),
        ],
        visibleTypes: [ComponentType.fork],
      );

      expect(layout.rows.map((r) => (r.start, r.end)), [
        (local(1), local(5)),
        (local(5), null),
      ]);
      expect(layout.columns.map((c) => c.type), [ComponentType.fork]);
      expect(layout.blocks.single.componentId, 'fork');
    });

    test('columns follow the order of the visible types', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [interval('fork', local(1)), interval('shock', local(1))],
        visibleTypes: [ComponentType.shock, ComponentType.fork],
      );

      expect(layout.columns.map((c) => c.type), [ComponentType.shock, ComponentType.fork]);
    });

    test('groups rows by local day and flags the initial setup', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      final layout = layoutFor(
        [component('a', ComponentType.other), component('b', ComponentType.other)],
        [
          interval('a', epoch, local(2, 8)),
          interval('b', local(2, 8), local(2, 14)),
          interval('a', local(2, 14), local(3, 9)),
        ],
      );

      expect(layout.rows.map((r) => (r.start, r.showDate, r.isInitialSetup)), [
        (epoch, true, true),
        (local(2, 8), true, false),
        (local(2, 14), false, false),
        (local(3, 9), true, false),
      ]);
    });

    test('non-overlapping components share a slot', () {
      final layout = layoutFor(
        [component('tireA', ComponentType.tire), component('tireB', ComponentType.tire)],
        [interval('tireA', local(1), local(3)), interval('tireB', local(3))],
      );

      expect(layout.columns, hasLength(1));
      expect(layout.columns.single.slotCount, 1);
      expect(layout.columns.single.width, TimelineColumn.singleSlotWidth);
      expect(layout.blocks.map((b) => b.columnIndex), [0, 0]);
    });

    test('overlapping components get separate slots ordered by first start', () {
      final layout = layoutFor(
        [
          component('late', ComponentType.tire),
          component('early', ComponentType.tire),
          component('after', ComponentType.tire),
        ],
        [
          interval('late', local(2)),
          interval('early', local(1), local(4)),
          interval('after', local(4)),
        ],
      );

      expect(layout.columns.map((c) => (c.slotIndex, c.slotCount, c.width)), [
        (0, 2, TimelineColumn.multiSlotWidth),
        (1, 2, TimelineColumn.multiSlotWidth),
      ]);
      final columnOf = {for (final b in layout.blocks) b.componentId: b.columnIndex};
      expect(columnOf, {'early': 0, 'late': 1, 'after': 0});
    });

    test('packs per interval, so a returning component does not force an extra slot', () {
      final layout = layoutFor(
        [
          component('A', ComponentType.tire),
          component('B', ComponentType.tire),
          component('C', ComponentType.tire),
        ],
        [
          interval('A', local(1), local(3)),
          interval('B', local(1), local(6)),
          interval('C', local(3), local(9)),
          interval('A', local(6), local(9)),
        ],
      );

      expect(layout.columns, hasLength(2));
      expect(layout.blocks.map((b) => (b.componentId, b.rowFrom, b.columnIndex)), [
        ('A', 0, 0),
        ('B', 0, 1),
        ('C', 1, 0),
        ('A', 2, 1),
      ]);
    });

    test('an interval keeps its component slot when free, even if a lower slot is free', () {
      final layout = layoutFor(
        [component('front', ComponentType.tire), component('rear', ComponentType.tire)],
        [
          interval('front', local(1), local(2)),
          interval('rear', local(1), local(4), 'wheelA'),
          interval('rear', local(4), null, 'wheelB'),
        ],
      );

      expect(layout.blocks.map((b) => (b.componentId, b.parentComponentId, b.columnIndex)), [
        ('front', null, 0),
        ('rear', 'wheelA', 1),
        ('rear', 'wheelB', 1),
      ]);
    });

    test('blockAt returns the same block for every covered cell and null for gaps', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [
          interval('fork', local(1), local(4)),
          interval('shock', local(2), local(3)),
        ],
      );

      final fork = layout.blocks.firstWhere((b) => b.componentId == 'fork');
      expect((fork.rowFrom, fork.rowTo, fork.rowSpan, fork.isOpen), (0, 2, 3, false));
      for (var row = 0; row <= 2; row++) {
        expect(identical(layout.blockAt(row, 0), fork), isTrue);
      }
      expect(layout.blockAt(3, 0), isNull);

      expect(layout.blockAt(0, 1), isNull);
      expect(layout.blockAt(1, 1)?.componentId, 'shock');
      expect(layout.blockAt(2, 1), isNull);
    });

    test('an open-ended block covers the last row', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [interval('fork', local(1)), interval('shock', local(2), local(3))],
      );

      final fork = layout.blocks.firstWhere((b) => b.componentId == 'fork');
      expect(fork.isOpen, isTrue);
      expect(fork.rowTo, layout.rows.length - 1);
    });

    test('a parent change splits into two blocks in the same column (D1)', () {
      final layout = layoutFor(
        [component('tire', ComponentType.tire)],
        [
          interval('tire', local(2), local(5), 'wheelA'),
          interval('tire', local(5), null, 'wheelB'),
        ],
      );

      expect(layout.blocks.map((b) => (b.columnIndex, b.rowFrom, b.rowTo, b.parentComponentId)), [
        (0, 0, 0, 'wheelA'),
        (0, 1, 1, 'wheelB'),
      ]);
      expect(layout.blocks.every((b) => b.isNested), isTrue);
    });

    test('only rows too short for their block grow, by the missing height', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [
          interval('fork', local(1), local(4)),
          interval('shock', local(4), local(5)),
        ],
      );

      // Rows start on days 1, 4 and 5; each block covers a single row.
      expect(layout.rows.map((r) => r.height), [blockHeight, blockHeight, minRowHeight]);
    });

    test('a block spanning several rows needs no growth', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [
          interval('fork', local(1), local(4)),
          interval('shock', local(2), local(3)),
        ],
      );

      // Fork spans rows 0..2 (3 × 32 ≥ 48); only the shock's single row grows.
      expect(layout.rows.map((r) => r.height), [minRowHeight, blockHeight, minRowHeight, minRowHeight]);
    });

    test('a growth for one block counts toward a longer block ending on the same row', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('tire', ComponentType.tire)],
        [
          interval('fork', local(1), local(3)),
          interval('tire', local(2), local(3), 'wheel'),
        ],
      );

      // Tire needs 64 on row 1; fork then has 32 + 64 ≥ 48 across rows 0..1.
      expect(layout.rows.map((r) => r.height), [minRowHeight, nestedBlockHeight, minRowHeight]);
    });

    test('a nested block needs more height than a name-only one', () {
      final direct = layoutFor(
        [component('wheel', ComponentType.wheelFront)],
        [interval('wheel', local(1), local(2))],
      );
      final nested = layoutFor(
        [component('tire', ComponentType.tire)],
        [interval('tire', local(1), local(2), 'wheel')],
      );

      expect(direct.rows.first.height, blockHeight);
      expect(nested.rows.first.height, nestedBlockHeight);
    });

    test('totalHeight sums all row heights', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [
          interval('fork', local(1), local(4)),
          interval('shock', local(2), local(3)),
        ],
      );

      expect(layout.totalHeight, 3 * minRowHeight + blockHeight);
    });

    test('an interval whose local end is not after its start covers no row', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork), component('shock', ComponentType.shock)],
        [
          interval('fork', local(2), local(2)),
          interval('shock', local(1), local(3)),
        ],
      );

      expect(layout.blocks.map((b) => b.componentId), ['shock']);
    });

    test('no visible intervals yield an empty layout', () {
      final layout = layoutFor(
        [component('fork', ComponentType.fork)],
        [interval('fork', local(1))],
        visibleTypes: const [],
      );

      expect(layout.rows, isEmpty);
      expect(layout.columns, isEmpty);
      expect(layout.blocks, isEmpty);
      expect(layout.totalHeight, 0);
    });
  });
}
