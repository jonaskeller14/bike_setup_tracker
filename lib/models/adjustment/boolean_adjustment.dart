part of 'adjustment.dart';

class BooleanAdjustment extends Adjustment<bool> {
  BooleanAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
  });

  @override
  BooleanAdjustment deepCopy() {
    return BooleanAdjustment(name: name, notes: notes, unit: unit);
  }
  
  @override
  bool isValidValue(dynamic value) {
    return value is bool;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'boolean',
    'valueType': valueType.toString(),
    'unit': unit,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return getIconStatic(size: size, color: color);
  }

  static Icon getIconStatic({double? size, Color? color}) {
    return Icon(Icons.toggle_on, size: size, color: color,);
  }

  @override
  String getProperties() {
    return "On/Off";
  }
}
