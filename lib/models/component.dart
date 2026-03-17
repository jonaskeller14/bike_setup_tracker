import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'adjustment/adjustment.dart';
import '../icons/bike_icons.dart';
import 'installation.dart';

part 'component_type.dart';

class Component {
  final String id;
  final bool isDeleted;
  final DateTime lastModified;
  final String name;
  final ComponentType componentType; 
  final List<Adjustment> adjustments;
  final List<Installation> installations;
  final String? notes;
  final int orderIndex;

  String? get bike => bikeAt(DateTime.now().toUtc());

  String? bikeAt(DateTime timeUTC) {
    if (installations.isEmpty) return null;
    
    // Sort installations by dateTimeUTC to ensure chronological order
    final sorted = List<Installation>.from(installations)
      ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC));
      
    // Find the last installation that happened at or before the given time
    Installation? result;
    for (final installation in sorted) {
      if (installation.dateTimeUTC.isAfter(timeUTC)) break;
      result = installation;
    }
    
    return result?.parent;
  }

  static const IconData iconData = Icons.grid_view_sharp;

  Component({
    String? id,
    bool? isDeleted,
    DateTime? lastModified,
    required this.name,
    required this.installations,
    required this.componentType,
    this.notes,
    this.orderIndex = 0,
    List<Adjustment>? adjustments,
  }) : adjustments = adjustments ?? [],
       id = id ?? const Uuid().v4(),
       isDeleted = isDeleted ?? false,
       lastModified = lastModified?.toUtc() ?? DateTime.now().toUtc();
    
  Component deepCopy() {
    return Component(
      name: name,
      installations: installations.map((i) => i.copyWith()).toList(),
      componentType: componentType,
      notes: notes,
      adjustments: adjustments.map((a) => a.deepCopy()).toList(),
    );
  }

  Component copyWithNewInstallation(String? newBike) {
    return copyWith(
      installations: [
        Installation.sinceBeginning(parent: newBike)
      ],
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
    Object? installations = const _Sentinel(),
    Object? orderIndex = const _Sentinel(),
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
          : (name as String), 
      notes: notes is _Sentinel
          ? this.notes
          : (notes as String?),
      componentType: componentType is _Sentinel
          ? this.componentType
          : (componentType as ComponentType),
      adjustments: adjustments is _Sentinel
          ? this.adjustments
          : (adjustments as List<Adjustment>),
      installations: installations is _Sentinel
          ? this.installations
          : (installations as List<Installation>),  
      orderIndex: orderIndex is _Sentinel
          ? this.orderIndex
          : (orderIndex as int),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 3,
    'id': id,
    "isDeleted": isDeleted,
    "lastModified": lastModified.toUtc().toIso8601String(),
    'name': name,
    'componentType': componentType.toString(),
    'installations': installations.map((i) => i.toJson()).toList(),
    'notes': notes,
    'orderIndex': orderIndex,
    'adjustments': adjustments.map((a) => a.toJson()).toList(),
  };

  factory Component.fromJson({required Map<String, dynamic> json}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        final bike = json["bike"] as String?;
        return Component(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'] as String,
          componentType: ComponentType.values.firstWhere(
            (e) => e.toString() == json['componentType'],
            orElse: () => ComponentType.other,
          ),
          installations: [
            Installation.sinceBeginning(parent: bike)
          ],
          notes: json["notes"] as String?,
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson, defaultCategory: AdjustmentCategory.component))
            .toList()
            ?? <Adjustment>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
        );
      case 2 || 3:
        return Component(
          id: json["id"] as String,
          isDeleted: json["isDeleted"] as bool,
          lastModified: DateTime.tryParse(json["lastModified"] ?? ""),
          name: json['name'] as String,
          componentType: ComponentType.values.firstWhere(
            (e) => e.toString() == json['componentType'],
            orElse: () => ComponentType.other,
          ),
          installations: (json["installations"] as List<dynamic>?)
            ?.map((i) => Installation.fromJson(i))
            .toList() ?? [],
          notes: json["notes"] as String?,
          adjustments: (json["adjustments"] as List<dynamic>?)
            ?.map((adjustmentJson) => Adjustment.fromJson(adjustmentJson, defaultCategory: AdjustmentCategory.component))
            .toList()
            ?? <Adjustment>[],
          orderIndex: json["orderIndex"] as int? ?? 0,
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
        listEquals(installations, other.installations) &&
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
      Object.hashAll(installations),
      notes,
      Object.hashAll(adjustments),
    );
  }
}

class _Sentinel {
  const _Sentinel();
}
