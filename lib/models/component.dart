import 'package:flutter/foundation.dart';
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
  cockpit('Cockpit'),
  motor('Motor'),
  equipment('Equipment'),
  other('Other');

  final String value;
  const ComponentType(this.value);
  IconData getIconData() {
    switch (this) {
      case frame: return BikeIcons.frame;
      case fork: return BikeIcons.fork;
      case shock: return BikeIcons.shock;
      case wheelFront: return BikeIcons.wheelFront;
      case wheelRear: return BikeIcons.wheelRear;
      case cockpit: return BikeIcons.cockpit;
      case motor: return BikeIcons.motor;
      case equipment: return BikeIcons.equipment;
      case other: return BikeIcons.other;
    }
  }
}

class Component {
  final String id;
  bool isDeleted;
  DateTime lastModified;
  final String name;
  final ComponentType componentType; 
  final List<Adjustment> adjustments;
  final String? bike;
  final String? notes;

  static const IconData iconData = Icons.grid_view_sharp;

  Component({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    required this.bike,
    required this.componentType,
    this.notes,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();
    
  Component deepCopy() {
    return Component(
      name: name,
      bike: bike,
      componentType: componentType,
      notes: notes,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }

  Component copyWith({
    Object? id = const _Sentinel(),
    Object? isDeleted= const _Sentinel(),
    Object? lastModified = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? componentType = const _Sentinel(),
    Object? adjustments = const _Sentinel(),
    Object? bike = const _Sentinel(),
  }) {
    return Component(
      id: id is _Sentinel
          ? this.id
          : (id as String),
      isDeleted: isDeleted is _Sentinel
          ? this.isDeleted
          : (isDeleted as bool),
      lastModified: lastModified is _Sentinel
          ? this.lastModified
          : (lastModified as DateTime),
      name: name is _Sentinel
          ? this.name
          : (notes as String), 
      notes: name is _Sentinel
          ? this.name
          : (notes as String?),
      componentType: componentType is _Sentinel
          ? this.componentType
          : (componentType as ComponentType),
      adjustments: adjustments is _Sentinel
          ? this.adjustments
          : (adjustments as List<Adjustment>),
      bike: bike is _Sentinel
          ? this.bike
          : (bike as String?),  
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'componentType': componentType.toString(),
    'bike': bike,
    'notes': notes,
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
  };

  factory Component.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return Component(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'] as String,
          componentType: ComponentType.values.firstWhere(
            (e) => e.toString() == json['componentType'],
            orElse: () => ComponentType.other,
          ),
          bike: json["bike"] as String?,
          notes: json["notes"] as String?,
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson, defaultCategory: AdjustmentCategory.component))
            .toList()
            ?? <Adjustment>[],
        );
      default: throw Exception("Json Version $version of Component incompatible."); 
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Component &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        isDeleted == other.isDeleted &&
        lastModified == other.lastModified &&
        name == other.name &&
        componentType == other.componentType &&
        bike == other.bike &&
        notes == other.notes &&
        listEquals(adjustments, other.adjustments);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      isDeleted,
      lastModified,
      name,
      componentType,
      bike,
      notes,
      Object.hashAll(adjustments),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
