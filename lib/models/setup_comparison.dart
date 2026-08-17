import 'adjustment/adjustment.dart';
import 'component.dart';
import 'person.dart';

enum SetupComparisonGroupKind { component, person, deletedValues, context, ratings }

enum SetupComparisonRowKind {
  adjustment,
  deletedAdjustment,
  bike,
  person,
  notes,
  tags,
  images,
  location,
  conditions,
  context,
  rating,
}

enum SetupComparisonValueProvenance {
  explicit,
  inherited,
  unavailable,
  dangling,
  deleted,
}

enum SetupComparisonOwnerState { installedOrLinked, dangling, absent }

class SetupComparison {
  final String setupAId;
  final String setupBId;
  final List<SetupComparisonGroup> groups;

  SetupComparison({
    required this.setupAId,
    required this.setupBId,
    required Iterable<SetupComparisonGroup> groups,
  }) : groups = List.unmodifiable(groups);

  int get differenceCount => groups.fold(0, (count, group) => count + group.differenceCount);

  List<SetupComparisonGroup> visibleGroups({required bool differencesOnly}) {
    if (!differencesOnly) return groups;
    return groups.where((group) => group.isDifferent).toList(growable: false);
  }
}

class SetupComparisonGroup {
  final SetupComparisonGroupKind kind;
  final String ownerId;
  final SetupComparisonOwnerState ownerStateA;
  final SetupComparisonOwnerState ownerStateB;
  final String label;
  final String? labelA;
  final String? labelB;
  final Component? componentA;
  final Component? componentB;
  final Person? personA;
  final Person? personB;
  final List<SetupComparisonRow> rows;

  SetupComparisonGroup({
    required this.kind,
    required this.ownerId,
    required this.ownerStateA,
    required this.ownerStateB,
    required this.label,
    this.labelA,
    this.labelB,
    this.componentA,
    this.componentB,
    this.personA,
    this.personB,
    required Iterable<SetupComparisonRow> rows,
  }) : rows = List.unmodifiable(rows);

  bool get isStructuralDifference => rows.isEmpty && ownerStateA != ownerStateB;

  bool get isDifferent => isStructuralDifference || rows.any((row) => row.isDifferent);

  int get differenceCount {
    if (rows.isEmpty) return isStructuralDifference ? 1 : 0;
    return rows.fold(0, (count, row) => count + row.differenceCount);
  }

  List<SetupComparisonRow> visibleRows({required bool differencesOnly}) {
    if (!differencesOnly) return rows;
    return rows.where((row) => row.isDifferent).toList(growable: false);
  }
}

class SetupComparisonRow {
  final String id;
  final String label;
  final SetupComparisonRowKind kind;
  final SetupComparisonSideValue valueA;
  final SetupComparisonSideValue valueB;
  final bool isDifferent;
  final List<SetupComparisonRow> children;

  SetupComparisonRow({
    required this.id,
    required this.label,
    required this.kind,
    required this.valueA,
    required this.valueB,
    required this.isDifferent,
    Iterable<SetupComparisonRow> children = const [],
  }) : children = List.unmodifiable(children);

  int get differenceCount =>
      children.isEmpty ? (isDifferent ? 1 : 0) : children.fold(0, (count, child) => count + child.differenceCount);

  Adjustment? get adjustmentA => valueA.definition;
  Adjustment? get adjustmentB => valueB.definition;
}

class SetupComparisonSideValue {
  final dynamic value;
  final SetupComparisonValueProvenance provenance;
  final Adjustment? definition;

  const SetupComparisonSideValue({
    required this.value,
    required this.provenance,
    required this.definition,
  });

  bool get isRecorded => provenance != SetupComparisonValueProvenance.unavailable;
}

class SetupComparisonReference {
  final String id;
  final String label;
  final bool isMissing;

  const SetupComparisonReference({
    required this.id,
    required this.label,
    this.isMissing = false,
  });
}
