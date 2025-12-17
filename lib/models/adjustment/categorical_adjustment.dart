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
  bool isValidValue(String value) {
    return options.contains(value);
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
