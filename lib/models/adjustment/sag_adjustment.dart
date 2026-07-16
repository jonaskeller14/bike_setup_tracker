part of 'adjustment.dart';

const String adjustmentSubtypeKey = 'subtype';
const String _sagSubtype = 'sag';

class SagAdjustment extends NumericalAdjustment {
  final double? referenceTravelMm;

  static const IconData iconData = NumericalAdjustment.iconData;
  static const IconData badgeIconData = Icons.height;
  static const IconData travelIconData = Icons.unfold_more;

  static const AdjustmentUnit percentUnit = CustomUnit('%');
  static const double minPercent = 0;
  static const double maxPercent = 100;

  SagAdjustment({
    super.id,
    required super.name,
    required super.notes,
    this.referenceTravelMm,
  }) : super(unit: percentUnit, min: minPercent, max: maxPercent);

  @override
  SagAdjustment deepCopy() {
    return SagAdjustment(
      name: name,
      notes: notes,
      referenceTravelMm: referenceTravelMm,
    );
  }

  /// `SagAdjustment` can never silently downgrade it to a plain numerical.
  @override
  SagAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? min = const _Sentinel(),
    Object? max = const _Sentinel(),
    Object? referenceTravelMm = const _Sentinel(),
  }) {
    assert(unit is _Sentinel, 'SagAdjustment is always stored in %');
    assert(min is _Sentinel && max is _Sentinel, 'SagAdjustment is always bounded 0..100 %');
    return SagAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      referenceTravelMm: referenceTravelMm is _Sentinel
          ? this.referenceTravelMm
          : (referenceTravelMm as double?),
    );
  }

  double? toMillimeters(double percent) {
    final travel = referenceTravelMm;
    if (travel == null || travel <= 0) return null;
    return percent / 100 * travel;
  }

  double? fromMillimeters(double millimeters) {
    final travel = referenceTravelMm;
    if (travel == null || travel <= 0) return null;
    return millimeters / travel * 100;
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    adjustmentSubtypeKey: _sagSubtype,
    'referenceTravelMm': referenceTravelMm,
  };

  factory SagAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      // Must accept every version NumericalAdjustment stamps: toJson() inherits
      // `version` from it, so a bump there without one here makes sag payloads
      // fail to decode their own output.
      case null || 1 || 2:
        return SagAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          referenceTravelMm: (json['referenceTravelMm'] as num?)?.toDouble(),
        );
      default: throw Exception("Json Version $version of SagAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => SagAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SagAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        referenceTravelMm == other.referenceTravelMm;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, referenceTravelMm);
  }
}
