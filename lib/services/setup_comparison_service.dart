import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/person.dart';
import '../models/setup.dart';
import '../models/setup_comparison.dart';
import 'dangling_adjustment_service.dart';

sealed class SetupComparisonTargetResolution {
  const SetupComparisonTargetResolution();
}

class SetupComparisonTargets extends SetupComparisonTargetResolution {
  final Setup setupA;
  final Setup setupB;

  const SetupComparisonTargets({required this.setupA, required this.setupB});
}

class SetupComparisonTargetsUnavailable extends SetupComparisonTargetResolution {
  const SetupComparisonTargetsUnavailable();
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

    for (final candidate in setups) {
      if (candidate.id != setupB.id && candidate.bike == setupB.bike && candidate.isCurrent) {
        return SetupComparisonTargets(setupA: candidate, setupB: setupB);
      }
    }
    return const SetupComparisonTargetsUnavailable();
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
  }) {
    final componentsA = ownersA.cast<_ComponentOwnerData>();
    final componentsB = ownersB.cast<_ComponentOwnerData>();
    final byIdB = _byOwnerId(componentsB);
    final exactIds = componentsA.map((owner) => owner.id).where(byIdB.containsKey).toSet();
    final onlyA = componentsA.where((owner) => !exactIds.contains(owner.id)).toList();
    final onlyB = componentsB.where((owner) => !exactIds.contains(owner.id)).toList();
    final inferredByA = _matchReplacementComponents(onlyA, onlyB);
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
  ) {
    final result = <String, _ComponentOwnerData>{};
    for (final type in ComponentType.values) {
      final candidatesA = onlyA.where((owner) => owner.component.componentType == type).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final candidatesB = onlyB.where((owner) => owner.component.componentType == type).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (candidatesA.isEmpty || candidatesB.isEmpty) continue;

      if (candidatesA.length <= candidatesB.length) {
        final assignment = _maximumScoreAssignment(
          candidatesA,
          candidatesB,
          _componentSimilarity,
        );
        for (var index = 0; index < candidatesA.length; index++) {
          result[candidatesA[index].id] = candidatesB[assignment[index]];
        }
      } else {
        final assignment = _maximumScoreAssignment(
          candidatesB,
          candidatesA,
          _componentSimilarity,
        );
        for (var index = 0; index < candidatesB.length; index++) {
          result[candidatesA[assignment[index]].id] = candidatesB[index];
        }
      }
    }
    return result;
  }

  /// Returns the index of the assigned [right] item for every [left] item.
  /// The Hungarian assignment keeps matching deterministic and order-independent.
  static List<int> _maximumScoreAssignment<T>(
    List<T> left,
    List<T> right,
    double Function(T left, T right) score,
  ) {
    assert(left.length <= right.length);
    final rowCount = left.length;
    final columnCount = right.length;
    final rowPotential = List<double>.filled(rowCount + 1, 0);
    final columnPotential = List<double>.filled(columnCount + 1, 0);
    final rowForColumn = List<int>.filled(columnCount + 1, 0);
    final previousColumn = List<int>.filled(columnCount + 1, 0);

    for (var row = 1; row <= rowCount; row++) {
      rowForColumn[0] = row;
      var column = 0;
      final minimum = List<double>.filled(columnCount + 1, double.infinity);
      final used = List<bool>.filled(columnCount + 1, false);
      do {
        used[column] = true;
        final currentRow = rowForColumn[column];
        var delta = double.infinity;
        var nextColumn = 0;
        for (var candidateColumn = 1; candidateColumn <= columnCount; candidateColumn++) {
          if (used[candidateColumn]) continue;
          final cost =
              -score(left[currentRow - 1], right[candidateColumn - 1]) -
              rowPotential[currentRow] -
              columnPotential[candidateColumn];
          if (cost < minimum[candidateColumn]) {
            minimum[candidateColumn] = cost;
            previousColumn[candidateColumn] = column;
          }
          if (minimum[candidateColumn] < delta) {
            delta = minimum[candidateColumn];
            nextColumn = candidateColumn;
          }
        }
        for (var candidateColumn = 0; candidateColumn <= columnCount; candidateColumn++) {
          if (used[candidateColumn]) {
            rowPotential[rowForColumn[candidateColumn]] += delta;
            columnPotential[candidateColumn] -= delta;
          } else {
            minimum[candidateColumn] -= delta;
          }
        }
        column = nextColumn;
      } while (rowForColumn[column] != 0);

      do {
        final nextColumn = previousColumn[column];
        rowForColumn[column] = rowForColumn[nextColumn];
        column = nextColumn;
      } while (column != 0);
    }

    final result = List<int>.filled(rowCount, 0);
    for (var column = 1; column <= columnCount; column++) {
      final row = rowForColumn[column];
      if (row != 0) result[row - 1] = column - 1;
    }
    return result;
  }

  static double _componentSimilarity(
    _ComponentOwnerData a,
    _ComponentOwnerData b,
  ) {
    final nameSimilarity = _nameSimilarity(a.label, b.label);
    final adjustmentSimilarity = _setOverlap(
      a.adjustments.map((adjustment) => _normalize(adjustment.name)).toSet(),
      b.adjustments.map((adjustment) => _normalize(adjustment.name)).toSet(),
    );
    return nameSimilarity * 0.7 + adjustmentSimilarity * 0.3;
  }

  static double _nameSimilarity(String a, String b) {
    final normalizedA = _normalize(a);
    final normalizedB = _normalize(b);
    if (normalizedA.isEmpty || normalizedB.isEmpty) return 0;
    final tokenSimilarity = _setOverlap(
      normalizedA.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet(),
      normalizedB.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet(),
    );
    final bigramSimilarity = _setOverlap(
      _bigrams(normalizedA.replaceAll(' ', '')),
      _bigrams(normalizedB.replaceAll(' ', '')),
    );
    return tokenSimilarity * 0.6 + bigramSimilarity * 0.4;
  }

  static Set<String> _bigrams(String value) {
    if (value.isEmpty) return const {};
    if (value.length == 1) return {value};
    return {
      for (var index = 0; index < value.length - 1; index++) value.substring(index, index + 2),
    };
  }

  static double _setOverlap(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return 2 * a.intersection(b).length / (a.length + b.length);
  }

  static String _normalize(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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
    return !adjustmentValuesEqual(valueA.value, valueB.value);
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
  final Map<String, dynamic> currentValues;
  final Map<String, dynamic> previousValues;

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
