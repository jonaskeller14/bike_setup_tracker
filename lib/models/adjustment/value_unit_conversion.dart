import 'adjustment_unit.dart';

class ValueUnitConversion {
  final String adjustmentId;
  final KnownUnit from;
  final KnownUnit to;

  const ValueUnitConversion({
    required this.adjustmentId,
    required this.from,
    required this.to,
  });

  bool get isNoOp => from == to;

  ValueUnitConversion composeWith(ValueUnitConversion next) =>
      ValueUnitConversion(adjustmentId: adjustmentId, from: from, to: next.to);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValueUnitConversion &&
          adjustmentId == other.adjustmentId &&
          from == other.from &&
          to == other.to);

  @override
  int get hashCode => Object.hash(adjustmentId, from, to);

  @override
  String toString() =>
      'ValueUnitConversion($adjustmentId: ${from.encode()} -> ${to.encode()})';
}

class EditResult<T> {
  final T value;
  final List<ValueUnitConversion> conversions;

  const EditResult(this.value, {this.conversions = const []});
}
