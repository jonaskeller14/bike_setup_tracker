import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment.dart';
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

  static Icon getIcon(ComponentType componentType) {
    switch (componentType) {
      case ComponentType.frame:
        return const Icon(BikeIcons.frame);
      case ComponentType.fork:
        return const Icon(BikeIcons.fork);
      case ComponentType.shock:
        return const Icon(BikeIcons.shock);
      case ComponentType.wheelFront:
        return const Icon(BikeIcons.wheelFront);
      case ComponentType.wheelRear:
        return const Icon(BikeIcons.wheelRear);
      case ComponentType.motor:
        return const Icon(BikeIcons.motor);
      case ComponentType.equipment:
        return const Icon(BikeIcons.equipment);
      default:
        return const Icon(BikeIcons.other);
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
    final adjustments = (json["adjustments"] as List<dynamic>?)
        ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson))
        .toList()
        ?? <Adjustment>[];
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
      adjustments: adjustments,
    );
  }
}
