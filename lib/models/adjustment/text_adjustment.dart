part of 'adjustment.dart';

class TextAdjustment extends Adjustment<String> {
  bool prefill = false;

  TextAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required this.prefill,
  });

  @override
  TextAdjustment deepCopy() {
    return TextAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      prefill: prefill,
    );
  }
  
  @override
  bool isValidValue(dynamic value) {
    return value is String;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'text',
    'valueType': valueType.toString(),
    'unit': unit,
    'prefill': prefill,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return getIconStatic(size: size, color: color);
  }

  static Icon getIconStatic({double? size, Color? color}) {
    return Icon(Icons.text_snippet, size: size, color: color,);
  }

  @override
  String getProperties() {
    return "Text";
  }
}
