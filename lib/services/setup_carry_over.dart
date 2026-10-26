import 'package:flutter/foundation.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/setup.dart';
import '../models/setup_history.dart';
import 'bike_adjustment_column_service.dart';
import 'component_hierarchy_resolver.dart';

enum CarryOverIssue {
  /// No component sits in the old component's position on the bike any more.
  componentGone,

  /// The component there now has no adjustment like the old one.
  noMatchingAdjustment,

  /// The old value is outside the range or options of the new adjustment.
  valueNotAllowed,
}

/// One value of a setup recorded on a component that is no longer in that
/// position, and where it would go. [issue] is null when it fits.
@immutable
class CarryOverEntry {
  final Component fromComponent;
  final Adjustment from;
  final AdjustmentValue value;
  final Component? toComponent;
  final Adjustment? to;
  final CarryOverIssue? issue;

  const CarryOverEntry({
    required this.fromComponent,
    required this.from,
    required this.value,
    this.toComponent,
    this.to,
    this.issue,
  });

  bool get isApplicable => issue == null;
}

/// What using an old setup today means for its values: those recorded on
/// replaced components can move to the adjustment in the same column of the
/// bike details table, as long as the new adjustment accepts them.
@immutable
class SetupCarryOver {
  /// Applicable entries first.
  final List<CarryOverEntry> entries;

  const SetupCarryOver(this.entries);

  Iterable<CarryOverEntry> get applicable => entries.where((entry) => entry.isApplicable);
  Iterable<CarryOverEntry> get skipped => entries.where((entry) => !entry.isApplicable);
  bool get isEmpty => entries.isEmpty;

  /// [values] with the applicable entries moved to their new adjustment.
  Map<String, AdjustmentValue> applyTo(Map<String, AdjustmentValue> values) {
    final moved = {for (final entry in applicable) entry.from.id: entry};
    return {
      for (final MapEntry(:key, :value) in values.entries)
        if (!moved.containsKey(key)) key: value,
      for (final entry in moved.values) entry.to!.id: entry.value,
    };
  }

  /// Compares [setup] with what sits on its bike at [now]. The columns come
  /// from [setups] plus a blank setup stamped [now], so a component installed
  /// since the last setup already has its place.
  static SetupCarryOver forSetup({
    required Setup setup,
    required Iterable<Setup> setups,
    required Iterable<Component> components,
    required ComponentHierarchyResolver hierarchy,
    required SetupHistory history,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    final today = Setup(
      datetime: stamp.toUtc(),
      datetimeLocal: stamp,
      tags: const {},
      bike: setup.bike,
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
    );
    final projection = BikeAdjustmentColumnService.build(
      bikeId: setup.bike,
      setups: [...setups, today],
      components: components,
      hierarchy: hierarchy,
      history: history,
    );

    final entries = <CarryOverEntry>[];
    for (final column in projection.columns) {
      final source = projection.resolve(setup, column);
      if (source == null || source.isDangling) continue;
      final value = setup.bikeAdjustmentValues[source.adjustment.id];
      if (value == null) continue;

      final target = projection.resolve(today, column);
      if (target?.adjustment.id == source.adjustment.id) continue;
      if (target != null && setup.bikeAdjustmentValues.containsKey(target.adjustment.id)) continue;

      // The component in this lane today, which may lack the adjustment.
      final laneComponent = projection
          .laneOf(column)
          ?.members
          .where((member) => member.setupIds.contains(today.id))
          .map((member) => member.component)
          .firstOrNull;
      entries.add(
        CarryOverEntry(
          fromComponent: source.component,
          from: source.adjustment,
          value: value,
          toComponent: target?.component ?? laneComponent,
          to: target?.adjustment,
          issue: switch (target) {
            null when laneComponent == null => CarryOverIssue.componentGone,
            null => CarryOverIssue.noMatchingAdjustment,
            final cell when cell.adjustment.isValidValue(value) => null,
            _ => CarryOverIssue.valueNotAllowed,
          },
        ),
      );
    }
    return SetupCarryOver([
      ...entries.where((entry) => entry.isApplicable),
      ...entries.where((entry) => !entry.isApplicable),
    ]);
  }
}
