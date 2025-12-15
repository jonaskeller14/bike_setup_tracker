import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';
import '../icons/bike_icons.dart';

enum ComponentType {
  frame('Frame'),
  fork('Fork'),
  shock('Shock'),
  wheelFront('Front Wheel'),
  wheelRear('Rear Wheel'),
  motor('Motor'),
  equipment('Equipment'),
  other('Other');

  final String value;
  const ComponentType(this.value);
}

class Component {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final ComponentType componentType; 
  final List<Adjustment> adjustments;
  final String bike;

  Component({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    required this.bike,
    required this.componentType,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified ?? DateTime.now();
    
  Component deepCopy() {
    return Component(
      name: name,
      bike: bike,
      componentType: componentType,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }

  static Icon getIcon(ComponentType componentType, {double? size, Color? color}) {
    switch (componentType) {
      case ComponentType.frame:
        return Icon(BikeIcons.frame, size: size, color: color);
      case ComponentType.fork:
        return Icon(BikeIcons.fork, size: size, color: color);
      case ComponentType.shock:
        return Icon(BikeIcons.shock, size: size, color: color);
      case ComponentType.wheelFront:
        return Icon(BikeIcons.wheelFront, size: size, color: color);
      case ComponentType.wheelRear:
        return Icon(BikeIcons.wheelRear, size: size, color: color);
      case ComponentType.motor:
        return Icon(BikeIcons.motor, size: size, color: color);
      case ComponentType.equipment:
        return Icon(BikeIcons.equipment, size: size, color: color);
      default:
        return Icon(BikeIcons.other, size: size, color: color);
    }   
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toIso8601String(),
    'name': name,
    'componentType': componentType.toString(),
    'bike': bike,
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
  };

  factory Component.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return Component(
          id: json["id"],
          isDeleted: json["isDeleted"],
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'],
          componentType: ComponentType.values.firstWhere(
            (e) => e.toString() == json['componentType'],
            orElse: () => ComponentType.other,
          ),
          bike: json["bike"],
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson))
            .toList()
            ?? <Adjustment>[],
        );
      default: throw Exception("Json Version $version of Component incompatible."); 
    }
  }
}
