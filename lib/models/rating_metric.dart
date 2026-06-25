import 'adjustment/adjustment.dart';

class RatingMetric {
  final Adjustment adjustment;
  final double weight;

  String get id => adjustment.id;

  const RatingMetric({
    required this.adjustment,
    this.weight = 1.0,
  });

  bool get isScored => switch (adjustment) {
    StepAdjustment() ||
    NumericalAdjustment() ||
    DurationAdjustment() ||
    BooleanAdjustment() => true,
    TextAdjustment() ||
    CategoricalAdjustment() => false,
  };

  RatingMetric deepCopy() {
    return RatingMetric(adjustment: adjustment.deepCopy(), weight: weight);
  }

  RatingMetric copyWith({
    Adjustment? adjustment,
    double? weight,
  }) {
    return RatingMetric(
      adjustment: adjustment ?? this.adjustment,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'weight': weight,
    'adjustment': adjustment.toJson(),
  };

  factory RatingMetric.fromJson(Map<String, dynamic> json) {
    final int? version = json['version'];
    switch (version) {
      case null || 1:
        return RatingMetric(
          adjustment: Adjustment.fromJson(
            json['adjustment'] as Map<String, dynamic>,
          ),
          weight: (json['weight'] as num).toDouble(),
        );
      default:
        throw Exception('Json Version $version of RatingMetric incompatible.');
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RatingMetric &&
        runtimeType == other.runtimeType &&
        adjustment == other.adjustment &&
        weight == other.weight;
  }

  @override
  int get hashCode => Object.hash(adjustment, weight);
}
