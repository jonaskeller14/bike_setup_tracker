import 'adjustment/adjustment.dart';
import 'component.dart';

enum SetupComparisonGroupKind { component, person }

enum SetupComparisonValueProvenance {
  explicit,
  inherited,
  unavailable,
}

enum SetupComparisonOwnerState { installedOrLinked, absent }

class SetupComparison {
  final List<SetupComparisonGroup> groups;

  SetupComparison({required Iterable<SetupComparisonGroup> groups}) : groups = List.unmodifiable(groups);

  int get differenceCount => groups.fold(0, (count, group) => count + group.differenceCount);
}

class SetupComparisonGroup {
  final SetupComparisonGroupKind kind;
  final String ownerId;
  final SetupComparisonOwnerState ownerStateA;
  final SetupComparisonOwnerState ownerStateB;
  final String label;
  final Component? componentA;
  final Component? componentB;
  final List<SetupAdjustmentComparison> rows;
  final List<SetupAdjustmentComparison> independentRowsA;
  final List<SetupAdjustmentComparison> independentRowsB;
  final bool isInferredComponentPair;

  SetupComparisonGroup({
    required this.kind,
    required this.ownerId,
    required this.ownerStateA,
    required this.ownerStateB,
    required this.label,
    this.componentA,
    this.componentB,
    required Iterable<SetupAdjustmentComparison> rows,
    Iterable<SetupAdjustmentComparison> independentRowsA = const [],
    Iterable<SetupAdjustmentComparison> independentRowsB = const [],
    this.isInferredComponentPair = false,
  }) : rows = List.unmodifiable(rows),
       independentRowsA = List.unmodifiable(independentRowsA),
       independentRowsB = List.unmodifiable(independentRowsB);

  bool get isStructuralDifference => isInferredComponentPair || (rows.isEmpty && ownerStateA != ownerStateB);

  bool get isComponentInstallationDifference =>
      kind == SetupComparisonGroupKind.component && (isInferredComponentPair || ownerStateA != ownerStateB);

  bool get isAdjustmentlessOneSidedComponent =>
      isComponentInstallationDifference && !isInferredComponentPair && rows.isEmpty;

  bool get isDifferent => isStructuralDifference || rows.any((row) => row.isDifferent);

  int get differenceCount {
    if (isInferredComponentPair) return 1;
    if (rows.isEmpty) return isStructuralDifference ? 1 : 0;
    return rows.where((row) => row.isDifferent).length;
  }

  List<SetupAdjustmentComparison> visibleRows({required bool differencesOnly}) {
    if (!differencesOnly) return rows;
    return rows.where((row) => row.isDifferent).toList(growable: false);
  }
}

class SetupAdjustmentComparison {
  final Adjustment? adjustmentA;
  final Adjustment? adjustmentB;
  final SetupComparisonSideValue valueA;
  final SetupComparisonSideValue valueB;
  final bool isDifferent;

  SetupAdjustmentComparison({
    required this.adjustmentA,
    required this.adjustmentB,
    required this.valueA,
    required this.valueB,
    required this.isDifferent,
  });

  Adjustment get adjustment => adjustmentA ?? adjustmentB!;
  String get id => adjustment.id;
  String get label => adjustment.name;
}

class SetupComparisonSideValue {
  final dynamic value;
  final SetupComparisonValueProvenance provenance;

  const SetupComparisonSideValue({
    required this.value,
    required this.provenance,
  });
}
