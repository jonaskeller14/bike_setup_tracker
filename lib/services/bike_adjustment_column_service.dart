import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/setup.dart';
import '../models/setup_history.dart';
import 'component_hierarchy_resolver.dart';
import 'component_similarity.dart';
import 'component_slot.dart';

typedef SlotLaneKey = ({ComponentSlot slot, int index});

/// Adjustments of different components share a column only when all three
/// parts match; there is no unit conversion.
typedef LaneAdjustmentKey = ({String name, Type type, AdjustmentUnit? unit});

typedef BikeAdjustmentColumnKey = ({SlotLaneKey lane, LaneAdjustmentKey adjustment});

typedef BikeAdjustmentCell = ({Component component, Adjustment adjustment, bool isDangling});

LaneAdjustmentKey laneAdjustmentKey(Adjustment adjustment) =>
    (name: normalize(adjustment.name), type: adjustment.runtimeType, unit: adjustment.unit);

class SlotLaneMember {
  final Component component;
  final Set<String> setupIds;

  const SlotLaneMember({required this.component, required this.setupIds});
}

/// A chain of components that followed each other in the same [slot]. No two
/// members are present at the same setup.
class SlotLane {
  final ComponentSlot slot;
  final int index;
  final String label;

  /// Ordered by their first setup.
  final List<SlotLaneMember> members;

  const SlotLane({required this.slot, required this.index, required this.label, required this.members});

  SlotLaneKey get key => (slot: slot, index: index);
}

class BikeAdjustmentProjection {
  final List<SlotLane> lanes;
  final List<BikeAdjustmentColumnKey> columns;
  final Map<SlotLaneKey, SlotLane> _lanesByKey;
  final Map<BikeAdjustmentColumnKey, Adjustment> _representatives;
  final Map<String, Map<BikeAdjustmentColumnKey, BikeAdjustmentCell>> _cellsBySetupId;
  final SetupHistory _history;

  BikeAdjustmentProjection._(this.lanes, this.columns, this._representatives, this._cellsBySetupId, this._history)
    : _lanesByKey = {for (final lane in lanes) lane.key: lane};

  SlotLane? laneOf(BikeAdjustmentColumnKey column) => _lanesByKey[column.lane];

  /// The adjustment of the lane's latest component with this key. All
  /// adjustments of a column share class and unit, so any of them describes it.
  Adjustment? adjustmentFor(BikeAdjustmentColumnKey column) => _representatives[column];

  String columnLabel(BikeAdjustmentColumnKey column) =>
      '${adjustmentFor(column)?.name ?? column.adjustment.name} · ${laneOf(column)?.label ?? column.lane.slot.label}';

  BikeAdjustmentCell? resolve(Setup setup, BikeAdjustmentColumnKey column) => _cellsBySetupId[setup.id]?[column];

  AdjustmentValue? valueFor(Setup setup, BikeAdjustmentColumnKey column) =>
      setup.bikeAdjustmentValues[resolve(setup, column)?.adjustment.id];

  /// Reads the setup's own adjustment ID, so the first value of a replacement
  /// component has no previous value.
  AdjustmentValue? previousValueFor(Setup setup, BikeAdjustmentColumnKey column) =>
      _history.previousBikeValuesOf(setup.id)[resolve(setup, column)?.adjustment.id];

  bool isDangling(Setup setup, BikeAdjustmentColumnKey column) => resolve(setup, column)?.isDangling ?? false;

  /// Whether the explicit or inherited value differs between any two
  /// consecutive [setups] (in time order) that have one.
  bool hasChanges(BikeAdjustmentColumnKey column, Iterable<Setup> setups) {
    AdjustmentValue? last;
    for (final setup in _sortedByTime(setups)) {
      final value = valueFor(setup, column) ?? previousValueFor(setup, column);
      if (value == null) continue;
      if (last != null && last != value) return true;
      last = value;
    }
    return false;
  }
}

class BikeAdjustmentColumnService {
  static BikeAdjustmentProjection build({
    required String bikeId,
    required Iterable<Setup> setups,
    required Iterable<Component> components,
    required ComponentHierarchyResolver hierarchy,
    required SetupHistory history,
  }) {
    final bikeSetups = _sortedByTime(setups.where((setup) => setup.bike == bikeId));
    final componentList = components.toList();

    // Setup indices at which each component occupies a slot on the bike.
    final occurrences = <ComponentSlot, Map<Component, List<int>>>{};
    for (final (index, setup) in bikeSetups.indexed) {
      final atUTC = setup.datetimeLocal.toUtc();
      for (final component in componentList) {
        if (hierarchy.bikeAt(component.id, atUTC) != bikeId) continue;
        final slot = slotAt(hierarchy, component, atUTC);
        if (slot == null) continue;
        ((occurrences[slot] ??= {})[component] ??= []).add(index);
      }
    }

    final lanes = <SlotLane>[];
    final laneAtSetup = <(String componentId, int setupIndex), SlotLane>{};
    for (final slot in occurrences.keys.toList()..sort(_compareSlots)) {
      final slotLanes = _assignLanes(occurrences[slot]!);
      for (final (index, members) in slotLanes.indexed) {
        final lane = SlotLane(
          slot: slot,
          index: index,
          label: slotLanes.length == 1 ? slot.label : '${slot.label} ${index + 1}',
          members: [
            for (final (component, setupIndices) in members)
              SlotLaneMember(
                component: component,
                setupIds: {for (final i in setupIndices) bikeSetups[i].id},
              ),
          ],
        );
        lanes.add(lane);
        for (final (component, setupIndices) in members) {
          for (final i in setupIndices) {
            laneAtSetup[(component.id, i)] = lane;
          }
        }
      }
    }

    final columns = <BikeAdjustmentColumnKey>[];
    final representatives = <BikeAdjustmentColumnKey, Adjustment>{};
    for (final lane in lanes) {
      for (final member in lane.members.reversed) {
        for (final adjustment in member.component.adjustments) {
          final column = (lane: lane.key, adjustment: laneAdjustmentKey(adjustment));
          if (representatives.containsKey(column)) continue;
          representatives[column] = adjustment;
          columns.add(column);
        }
      }
    }

    final laneComponentIds = {for (final lane in lanes) ...lane.members.map((member) => member.component.id)};
    final cellsBySetupId = <String, Map<BikeAdjustmentColumnKey, BikeAdjustmentCell>>{};
    for (final (index, setup) in bikeSetups.indexed) {
      final cells = cellsBySetupId[setup.id] = {};
      for (final component in componentList) {
        if (!laneComponentIds.contains(component.id)) continue;
        final presentLane = laneAtSetup[(component.id, index)];
        for (final adjustment in component.adjustments) {
          final lane =
              presentLane ??
              (setup.bikeAdjustmentValues.containsKey(adjustment.id)
                  ? _nearestLane(laneAtSetup, component.id, index, bikeSetups.length)
                  : null);
          if (lane == null) continue;
          final column = (lane: lane.key, adjustment: laneAdjustmentKey(adjustment));
          final existing = cells[column];
          // A present component always wins over a dangling value in the same lane.
          if (existing != null && (presentLane == null || !existing.isDangling)) continue;
          cells[column] = (component: component, adjustment: adjustment, isDangling: presentLane == null);
        }
      }
    }

    return BikeAdjustmentProjection._(lanes, columns, representatives, cellsBySetupId, history);
  }

  /// Greedy assignment in order of first presence: a component joins the first
  /// free lane, or on ties the lane whose last component is most similar.
  static List<List<(Component, List<int>)>> _assignLanes(Map<Component, List<int>> occurrences) {
    final entries = occurrences.entries.map((entry) => (entry.key, entry.value)).toList()
      ..sort((a, b) {
        final byFirstSetup = a.$2.first.compareTo(b.$2.first);
        return byFirstSetup != 0 ? byFirstSetup : a.$1.id.compareTo(b.$1.id);
      });

    final lanes = <List<(Component, List<int>)>>[];
    final occupied = <Set<int>>[];
    for (final entry in entries) {
      final (component, setupIndices) = entry;
      int? bestLane;
      var bestScore = double.negativeInfinity;
      for (var lane = 0; lane < lanes.length; lane++) {
        if (setupIndices.any(occupied[lane].contains)) continue;
        final score = componentSimilarity(lanes[lane].last.$1, component);
        if (score > bestScore) {
          bestLane = lane;
          bestScore = score;
        }
      }
      if (bestLane == null) {
        lanes.add([]);
        occupied.add({});
        bestLane = lanes.length - 1;
      }
      lanes[bestLane].add(entry);
      occupied[bestLane].addAll(setupIndices);
    }
    return lanes;
  }

  /// The lane a component occupied at its latest setup up to [setupIndex], or
  /// at its earliest setup after it.
  static SlotLane? _nearestLane(
    Map<(String, int), SlotLane> laneAtSetup,
    String componentId,
    int setupIndex,
    int setupCount,
  ) {
    for (var i = setupIndex; i >= 0; i--) {
      if (laneAtSetup[(componentId, i)] case final lane?) return lane;
    }
    for (var i = setupIndex + 1; i < setupCount; i++) {
      if (laneAtSetup[(componentId, i)] case final lane?) return lane;
    }
    return null;
  }

  static int _compareSlots(ComponentSlot a, ComponentSlot b) {
    final byType = a.type.index.compareTo(b.type.index);
    if (byType != 0) return byType;
    return (a.parentType?.index ?? -1).compareTo(b.parentType?.index ?? -1);
  }
}

List<Setup> _sortedByTime(Iterable<Setup> setups) => setups.toList()
  ..sort((a, b) {
    final byTime = a.datetime.compareTo(b.datetime);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
