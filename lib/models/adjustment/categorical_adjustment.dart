part of 'adjustment.dart';

class CategoricalAdjustment extends Adjustment<String> {
  List<String> options;

  CategoricalAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required this.options,
  });

  @override
  CategoricalAdjustment deepCopy() {
    return CategoricalAdjustment(name: name, notes: notes, unit: unit, options: options);
  }

  @override
  bool isValidValue(dynamic value) {
    return value is String && options.contains(value);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'categorical',
    'valueType': valueType.toString(),
    'unit': unit,
    'options': options,
  };

  factory CategoricalAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          options: List<String>.from(json['options']),
        );
      default: throw Exception("Json Version $version of CategoricalAdjustment incompatible.");
    }
  }

  @override
  Icon getIcon({double? size, Color? color}) {
    return getIconStatic(size: size, color: color,);
  }

  static Icon getIconStatic({double? size, Color? color}) {
    return Icon(Icons.category, size: size, color: color,);
  }

  @override
  String getProperties() {
    return options.join('/');
  }
}
