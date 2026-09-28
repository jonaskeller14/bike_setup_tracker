import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/setup_comparison.dart';
import 'component_hierarchy_resolver.dart';
import 'component_similarity.dart';
import 'component_slot.dart';
import 'dangling_adjustment_service.dart';

sealed class SetupComparisonTargetResolution {
  const SetupComparisonTargetResolution();
}

class SetupComparisonTargets extends SetupComparisonTargetResolution {
  final Setup setupA;
  final Setup setupB;

  const SetupComparisonTargets({required this.setupA, required this.setupB});
}

class SetupComparisonTargetsEqualInput extends SetupComparisonTargetResolution {
  const SetupComparisonTargetsEqualInput();
}

class SetupComparisonService {
  static SetupComparisonTargetResolution resolveTargets({
    Setup? setupA,
    required Setup setupB,
    required Iterable<Setup> setups,
  }) {
    if (setupA != null) {
      return setupA.id == setupB.id
          ? const SetupComparisonTargetsEqualInput()
          : SetupComparisonTargets(setupA: setupA, setupB: setupB);
    }

    Setup? latestOther;
    for (final candidate in setups) {
      if (candidate.id == setupB.id || candidate.bike != setupB.bike) continue;
      if (candidate.isCurrent) return SetupComparisonTargets(setupA: candidate, setupB: setupB);
      if (latestOther == null || candidate.datetime.isAfter(latestOther.datetime)) latestOther = candidate;
    }
    // setupB is the current setup: compare against the next most recent one, or itself if it is the only setup.
    return SetupComparisonTargets(setupA: latestOther ?? setupB, setupB: setupB);
  }

  static SetupComparison build({
    required Setup setupA,
    required Setup setupB,
    required Iterable<Component> components,
    required Iterable<Person> persons,
  }) {
    final allComponents = List<Component>.of(components);
    final allPersons = List<Person>.of(persons);
    final breakdownA = DanglingAdjustmentService.analyzeSetup(
      setup: setupA,
      components: allComponents,
      persons: allPersons,
    );
    final breakdownB = DanglingAdjustmentService.analyzeSetup(
      setup: setupB,
      components: allComponents,
      persons: allPersons,
    );

    final componentOwnersA = _componentOwners(breakdownA, setupA);
    final componentOwnersB = _componentOwners(breakdownB, setupB);
    final personOwnersA = _personOwners(breakdownA, setupA);
    final personOwnersB = _personOwners(breakdownB, setupB);

    return SetupComparison(
      groups: [
        ..._buildComponentGroups(
          ownersA: componentOwnersA,
          ownersB: componentOwnersB,
          setupA: setupA,
          setupB: setupB,
          hierarchy: ComponentHierarchyResolver({for (final component in allComponents) component.id: component}),
        ),
        ..._buildOwnerGroups(
          ownersA: personOwnersA,
          ownersB: personOwnersB,
        ),
      ],
    );
  }

  static List<_OwnerData> _componentOwners(SetupAdjustmentBreakdown breakdown, Setup setup) {
    return [
      for (final component in breakdown.components)
        _ComponentOwnerData(
          component: component,
          currentValues: setup.bikeAdjustmentValues,
          previousValues: setup.previousBikeAdjustmentValues,
        ),
    ];
  }

  static List<SetupComparisonGroup> _buildComponentGroups({
    required List<_OwnerData> ownersA,
    required List<_OwnerData> ownersB,
    required Setup setupA,
    required Setup setupB,
    required ComponentHierarchyResolver hierarchy,
  }) {
    final componentsA = ownersA.cast<_ComponentOwnerData>();
    final componentsB = ownersB.cast<_ComponentOwnerData>();
    final byIdB = _byOwnerId(componentsB);
    final exactIds = componentsA.map((owner) => owner.id).where(byIdB.containsKey).toSet();
    final onlyA = componentsA.where((owner) => !exactIds.contains(owner.id)).toList();
    final onlyB = componentsB.where((owner) => !exactIds.contains(owner.id)).toList();
    final inferredByA = _matchReplacementComponents(onlyA, onlyB, setupA, setupB, hierarchy);
    final inferredBIds = inferredByA.values.map((owner) => owner.id).toSet();

    return [
      for (final ownerA in componentsA)
        if (exactIds.contains(ownerA.id))
          _buildOwnerGroup(ownerA: ownerA, ownerB: byIdB[ownerA.id])
        else if (inferredByA[ownerA.id] case final ownerB?)
          _buildInferredComponentGroup(ownerA: ownerA, ownerB: ownerB)
        else
          _buildOwnerGroup(ownerA: ownerA, ownerB: null),
      for (final ownerB in onlyB)
        if (!inferredBIds.contains(ownerB.id)) _buildOwnerGroup(ownerA: null, ownerB: ownerB),
    ];
  }

  static Map<String, _ComponentOwnerData> _matchReplacementComponents(
    List<_ComponentOwnerData> onlyA,
    List<_ComponentOwnerData> onlyB,
    Setup setupA,
    Setup setupB,
    ComponentHierarchyResolver hierarchy,
  ) {
    final slotsA = _groupBySlot(onlyA, hierarchy, setupA);
    final slotsB = _groupBySlot(onlyB, hierarchy, setupB);
    final result = <String, _ComponentOwnerData>{};
    for (final MapEntry(key: slot, value: candidatesA) in slotsA.entries) {
      final candidatesB = slotsB[slot];
      if (candidatesB == null) continue;
      candidatesA.sort((a, b) => a.id.compareTo(b.id));
      candidatesB.sort((a, b) => a.id.compareTo(b.id));

      if (candidatesA.length <= candidatesB.length) {
        final assignment = maximumScoreAssignment(
          candidatesA,
          candidatesB,
          (a, b) => componentSimilarity(a.component, b.component),
        );
        for (var index = 0; index < candidatesA.length; index++) {
          result[candidatesA[index].id] = candidatesB[assignment[index]];
        }
      } else {
        final assignment = maximumScoreAssignment(
          candidatesB,
          candidatesA,
          (a, b) => componentSimilarity(a.component, b.component),
        );
        for (var index = 0; index < candidatesB.length; index++) {
          result[candidatesA[assignment[index]].id] = candidatesB[index];
        }
      }
    }
    return result;
  }

  static Map<ComponentSlot, List<_ComponentOwnerData>> _groupBySlot(
    List<_ComponentOwnerData> owners,
    ComponentHierarchyResolver hierarchy,
    Setup setup,
  ) {
    final result = <ComponentSlot, List<_ComponentOwnerData>>{};
    for (final owner in owners) {
      final slot = slotAt(hierarchy, owner.component, setup.datetimeLocal.toUtc());
      if (slot != null) (result[slot] ??= []).add(owner);
    }
    return result;
  }

  static List<_OwnerData> _personOwners(SetupAdjustmentBreakdown breakdown, Setup setup) {
    return [
      if (breakdown.person != null)
        _PersonOwnerData(
          person: breakdown.person!,
          currentValues: setup.personAdjustmentValues,
          previousValues: setup.previousPersonAdjustmentValues,
        ),
    ];
  }

  static List<SetupComparisonGroup> _buildOwnerGroups({
    required List<_OwnerData> ownersA,
    required List<_OwnerData> ownersB,
  }) {
    final byIdA = _byOwnerId(ownersA);
    final byIdB = _byOwnerId(ownersB);
    final orderedIds = _orderedUnion(byIdA.keys, byIdB.keys);

    return [
      for (final id in orderedIds) _buildOwnerGroup(ownerA: byIdA[id], ownerB: byIdB[id]),
    ];
  }

  static Map<String, _OwnerData> _byOwnerId(Iterable<_OwnerData> owners) {
    final result = <String, _OwnerData>{};
    for (final owner in owners) {
      result.putIfAbsent(owner.id, () => owner);
    }
    return result;
  }

  static SetupComparisonGroup _buildOwnerGroup({
    required _OwnerData? ownerA,
    required _OwnerData? ownerB,
  }) {
    final owner = ownerA ?? ownerB!;
    final adjustmentA = _byAdjustmentId(ownerA?.adjustments ?? const []);
    final adjustmentB = _byAdjustmentId(ownerB?.adjustments ?? const []);
    final adjustmentIds = _orderedUnion(adjustmentA.keys, adjustmentB.keys);
    final stateA = ownerA == null ? SetupComparisonOwnerState.absent : SetupComparisonOwnerState.installedOrLinked;
    final stateB = ownerB == null ? SetupComparisonOwnerState.absent : SetupComparisonOwnerState.installedOrLinked;

    return SetupComparisonGroup(
      kind: owner.kind,
      ownerId: owner.id,
      ownerStateA: stateA,
      ownerStateB: stateB,
      label: owner.label,
      componentA: ownerA is _ComponentOwnerData ? ownerA.component : null,
      componentB: ownerB is _ComponentOwnerData ? ownerB.component : null,
      rows: [
        for (final id in adjustmentIds)
          _buildAdjustmentRow(
            id: id,
            adjustmentA: adjustmentA[id],
            adjustmentB: adjustmentB[id],
            ownerA: ownerA,
            ownerB: ownerB,
            ownerStateA: stateA,
            ownerStateB: stateB,
          ),
      ],
    );
  }

  static SetupComparisonGroup _buildInferredComponentGroup({
    required _ComponentOwnerData ownerA,
    required _ComponentOwnerData ownerB,
  }) {
    return SetupComparisonGroup(
      kind: SetupComparisonGroupKind.component,
      ownerId: '${ownerA.id}--${ownerB.id}',
      ownerStateA: SetupComparisonOwnerState.installedOrLinked,
      ownerStateB: SetupComparisonOwnerState.installedOrLinked,
      label: '${ownerA.label} / ${ownerB.label}',
      componentA: ownerA.component,
      componentB: ownerB.component,
      rows: const [],
      independentRowsA: [
        for (final adjustment in ownerA.adjustments)
          SetupAdjustmentComparison(
            adjustmentA: adjustment,
            adjustmentB: null,
            valueA: _resolveValue(ownerA, adjustment),
            valueB: const SetupComparisonSideValue(
              value: null,
              provenance: SetupComparisonValueProvenance.unavailable,
            ),
            isDifferent: false,
          ),
      ],
      independentRowsB: [
        for (final adjustment in ownerB.adjustments)
          SetupAdjustmentComparison(
            adjustmentA: null,
            adjustmentB: adjustment,
            valueA: const SetupComparisonSideValue(
              value: null,
              provenance: SetupComparisonValueProvenance.unavailable,
            ),
            valueB: _resolveValue(ownerB, adjustment),
            isDifferent: false,
          ),
      ],
      isInferredComponentPair: true,
    );
  }

  static Map<String, Adjustment> _byAdjustmentId(Iterable<Adjustment> adjustments) {
    final result = <String, Adjustment>{};
    for (final adjustment in adjustments) {
      result.putIfAbsent(adjustment.id, () => adjustment);
    }
    return result;
  }

  static SetupAdjustmentComparison _buildAdjustmentRow({
    required String id,
    required Adjustment? adjustmentA,
    required Adjustment? adjustmentB,
    required _OwnerData? ownerA,
    required _OwnerData? ownerB,
    required SetupComparisonOwnerState ownerStateA,
    required SetupComparisonOwnerState ownerStateB,
  }) {
    final valueA = _resolveValue(ownerA, adjustmentA);
    final valueB = _resolveValue(ownerB, adjustmentB);
    return SetupAdjustmentComparison(
      adjustmentA: adjustmentA,
      adjustmentB: adjustmentB,
      valueA: valueA,
      valueB: valueB,
      isDifferent:
          adjustmentA == null ||
          adjustmentB == null ||
          _valuesDiffer(
            valueA: valueA,
            valueB: valueB,
            ownerStateA: ownerStateA,
            ownerStateB: ownerStateB,
          ),
    );
  }

  static SetupComparisonSideValue _resolveValue(_OwnerData? owner, Adjustment? adjustment) {
    if (owner == null || adjustment == null) {
      return const SetupComparisonSideValue(
        value: null,
        provenance: SetupComparisonValueProvenance.unavailable,
      );
    }
    if (owner.currentValues.containsKey(adjustment.id)) {
      return SetupComparisonSideValue(
        value: owner.currentValues[adjustment.id],
        provenance: SetupComparisonValueProvenance.explicit,
      );
    }
    if (owner.previousValues.containsKey(adjustment.id)) {
      return SetupComparisonSideValue(
        value: owner.previousValues[adjustment.id],
        provenance: SetupComparisonValueProvenance.inherited,
      );
    }
    return const SetupComparisonSideValue(
      value: null,
      provenance: SetupComparisonValueProvenance.unavailable,
    );
  }

  static bool _valuesDiffer({
    required SetupComparisonSideValue valueA,
    required SetupComparisonSideValue valueB,
    required SetupComparisonOwnerState ownerStateA,
    required SetupComparisonOwnerState ownerStateB,
  }) {
    if (ownerStateA != ownerStateB) {
      return true;
    }
    final unavailableA = valueA.provenance == SetupComparisonValueProvenance.unavailable;
    final unavailableB = valueB.provenance == SetupComparisonValueProvenance.unavailable;
    if (unavailableA != unavailableB) return true;
    if (unavailableA) return false;
    return valueA.value != valueB.value;
  }

  static List<String> _orderedUnion(Iterable<String> a, Iterable<String> b) {
    final result = <String>[];
    final seen = <String>{};
    for (final id in [...a, ...b]) {
      if (seen.add(id)) result.add(id);
    }
    return result;
  }
}

sealed class _OwnerData {
  final Map<String, AdjustmentValue> currentValues;
  final Map<String, AdjustmentValue> previousValues;

  const _OwnerData({
    required this.currentValues,
    required this.previousValues,
  });

  String get id;
  String get label;
  List<Adjustment> get adjustments;
  SetupComparisonGroupKind get kind;
}

final class _ComponentOwnerData extends _OwnerData {
  final Component component;

  const _ComponentOwnerData({
    required this.component,
    required super.currentValues,
    required super.previousValues,
  });

  @override
  String get id => component.id;

  @override
  String get label => component.name;

  @override
  List<Adjustment> get adjustments => component.adjustments;

  @override
  SetupComparisonGroupKind get kind => SetupComparisonGroupKind.component;
}

final class _PersonOwnerData extends _OwnerData {
  final Person person;

  const _PersonOwnerData({
    required this.person,
    required super.currentValues,
    required super.previousValues,
  });

  @override
  String get id => person.id;

  @override
  String get label => person.name;

  @override
  List<Adjustment> get adjustments => person.adjustments;

  @override
  SetupComparisonGroupKind get kind => SetupComparisonGroupKind.person;
}
