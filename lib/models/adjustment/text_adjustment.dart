part of 'adjustment.dart';

class TextAdjustment extends Adjustment<String> {
  TextAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
  });

  @override
  TextAdjustment deepCopy() {
    return TextAdjustment(
      name: name,
      notes: notes,
      unit: unit,
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
  };

  factory TextAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return TextAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
        );
      default: throw Exception("Json Version $version of TextAdjustment incompatible.");
    }
  }

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
