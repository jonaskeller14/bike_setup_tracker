class Adjustment<T> {
  final String name;
  final T value;

  Adjustment({required this.name, required this.value});
}

class CategoricalAdjustment extends Adjustment<String> {
  final List<String> options;

  CategoricalAdjustment({
    required super.name,
    required super.value,
    required this.options,
  });
}

class StepAdjustment extends Adjustment<int> {
  final int step;
  final int min;
  final int max;

  StepAdjustment({
    required super.name,
    required super.value,
    required this.step,
    required this.min,
    required this.max,
  });
}

class NumericalAdjustment extends Adjustment<double> {
  final double min;
  final double max;

  NumericalAdjustment({
    required super.name,
    required super.value,
    required this.min,
    required this.max,
  });
}
class BooleanAdjustment extends Adjustment<bool> {
  BooleanAdjustment({
    required super.name,
    required super.value,
  });
}
